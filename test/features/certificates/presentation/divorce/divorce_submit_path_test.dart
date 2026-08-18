/// Divorce's submit orchestration and cascade, driven against spies.
///
/// The counterpart to `marriage_submit_path_test.dart`. It exists because
/// coverage measurement caught the asymmetry: Marriage's cubit was driven end
/// to end and Divorce's was not, so Divorce's submit sequence, its retry
/// semantics and its `firstPageOnly` village read were all **implemented and
/// never executed** — the shape the Capability Rule exists to catch, found by
/// the `F3-AC-5` floor rather than by reading.
///
/// Divorce's sequence is not a copy of Marriage's. It has one fewer step, a
/// quote that fires **once** with no inputs, and D-N's fix on the type change.
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/prerequisite_record.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../../../application/application_write_fakes.dart';
import 'divorce_tier0_subject.dart';

PickedAttachment _file(String name, int size) =>
    PickedAttachment(name: name, bytes: Uint8List(size));

class _Spy {
  final List<String> calls = <String>[];
  final List<String> attached = <String>[];
  int creates = 0;
  int updates = 0;
  int quotes = 0;
  bool failSubmitOnce = false;
  bool _failed = false;

  ApplicationDetail get _detail =>
      applicationDetailFixture(reference: 'DC-2026-000654', feeLak: 150000);

  Future<Either<Failure, List<LookupOption>>> lookup(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async {
    calls.add('lookup:${key.id}:paging=${paging.name}');
    return Right<Failure, List<LookupOption>>(<LookupOption>[
      for (int i = 0; i < 200; i++)
        LookupOption(
          id: 'v$i',
          code: 'v$i',
          label: Bilingual(en: 'V$i', lo: 'V$i'),
        ),
    ]);
  }

  Future<Either<Failure, ApplicationDetail>> create(
    Map<String, Object?> b,
  ) async {
    creates++;
    calls.add('create');
    return Right<Failure, ApplicationDetail>(_detail);
  }

  Future<Either<Failure, ApplicationDetail>> update(
    String id,
    Map<String, Object?> b,
  ) async {
    updates++;
    calls.add('update');
    return Right<Failure, ApplicationDetail>(_detail);
  }

  Future<Either<Failure, Object?>> attach(
    String id,
    PickedAttachment file, {
    required String slot,
    required String kind,
    required String label,
  }) async {
    calls.add('attach:$slot');
    attached.add('$slot|${file.name}');
    return const Right<Failure, Object?>(null);
  }

  Future<Either<Failure, ApplicationDetail>> submitCase(String id) async {
    calls.add('submit');
    if (failSubmitOnce && !_failed) {
      _failed = true;
      return const Left<Failure, ApplicationDetail>(Failure('unavailable'));
    }
    return Right<Failure, ApplicationDetail>(_detail);
  }

  Future<Either<Failure, Object?>> pay(
    String id, {
    required String methodCode,
  }) async {
    calls.add('pay:$methodCode');
    return const Right<Failure, Object?>(<String, Object?>{
      'receipt_no': 'RCPT-D',
    });
  }

  Future<Either<Failure, DivorceQuote>> quote() async {
    quotes++;
    calls.add('quote');
    return const Right<Failure, DivorceQuote>(
      DivorceQuote(feeLak: 150000, lines: <DivorceQuoteLine>[]),
    );
  }

  Future<Either<Failure, PrerequisiteRecordPage>> records(String q) async {
    calls.add('records:$q');
    return const Right<Failure, PrerequisiteRecordPage>(
      PrerequisiteRecordPage.empty,
    );
  }

  Future<Either<Failure, PrerequisiteRecord>> openRecord(String no) async {
    calls.add('openRecord:$no');
    return Right<Failure, PrerequisiteRecord>(
      PrerequisiteRecord(
        id: 'r1',
        recordNo: no,
        kind: 'mediation',
        serviceCode: 'divorce',
        partyAName: 'H',
        partyBName: 'W',
        recordedAt: '2026-05-02T00:00:00Z',
        recordedBy: 'Village',
        status: 'recorded',
        feeLak: 0,
        payload: const <String, Object?>{'province_id': 'p-9'},
      ),
    );
  }
}

DivorceFormCubit _cubit(_Spy spy) => DivorceFormCubit(
      clock: SubmissionClock.fixed(kDivorceRegisterInstant),
      getLookupOptions: spy.lookup,
      createApplication: spy.create,
      updateApplication: spy.update,
      addAttachment: spy.attach,
      submitApplication: spy.submitCase,
      pay: spy.pay,
      loadQuote: spy.quote,
      loadRecords: spy.records,
      openRecord: spy.openRecord,
      lang: Lang.en,
    );

DivorceFormData _contestedWithFiles() {
  final DivorceFormData f = divorceFormFromFixture(
    readDivorceJson('$kDivorceFixtureDir/contested.en.json'),
  );
  return f.copyWith(
    courtDecision: _file('decree.pdf', 10),
    householdBook: _file('book.pdf', 11),
    guaranteeCert: _file('guarantee.pdf', 12),
    photos: _file('photo.jpg', 13),
  );
}

void main() {
  test('the quote is loaded ONCE, takes no inputs, and the fee never moves',
      () async {
    final _Spy spy = _Spy();
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);

    await cubit.load();
    expect(spy.quotes, 1);
    expect(cubit.state.quote.data!.feeLak, 150000);

    // Changing what WOULD have moved Marriage's quote in the source moves
    // nothing here: this page has no `anyForeign` and no
    // `includeBetrothalFee`. (Since `blocked.md` § 1 option (b) it moves
    // nothing on Marriage either — but there it is a concession, and here it
    // is fidelity. `:667` is `useQuery(() => catalog.quote("divorce", {}), [])`
    // with an empty dependency array.)
    cubit.patchHusband((DivorceSpouseInfo s) => s.copyWith(nationality: 'thai'));
    cubit.setDivorceType('contested');
    cubit.patchWife((DivorceSpouseInfo s) => s.copyWith(nationality: 'thai'));
    await Future<void>.delayed(Duration.zero);

    expect(spy.quotes, 1,
        reason: 'a second read is a second `GET /services` for a fee that '
            'cannot have changed');
    expect(cubit.state.quote.data!.feeLak, 150000,
        reason: 'the call count alone would still pass if something else in '
            'the cubit recomputed the fee from form state');
  });

  test('the village read is firstPageOnly here too', () async {
    final _Spy spy = _Spy();
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);

    cubit.setHeader(const CertificateLocationValue(provinceId: 'p-1'));
    await Future<void>.delayed(Duration.zero);
    cubit.setHeader(
      const CertificateLocationValue(provinceId: 'p-1', districtId: 'd-1'),
    );
    await Future<void>.delayed(Duration.zero);

    final List<String> villages =
        spy.calls.where((String c) => c.contains('villages')).toList();
    expect(villages, hasLength(1));
    expect(villages.single, contains('paging=firstPageOnly'));
    expect(
      cubit.state.cascade(DivorceCascade.header).villages.options,
      hasLength(200),
    );
  });

  test('create -> attach -> update -> submit -> pay, four attachments',
      () async {
    final _Spy spy = _Spy();
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);
    cubit.emit(cubit.state.copyWith(form: _contestedWithFiles()));

    await cubit.submit();

    expect(
      spy.calls.map((String c) => c.split(':').first).toList(),
      <String>[
        'create',
        'attach', 'attach', 'attach', 'attach',
        'update',
        'submit',
        'pay',
      ],
    );
    // POST order — court decision FIRST, and it renders on step 1, not step 4.
    expect(spy.attached.map((String a) => a.split('|').first).toList(),
        <String>[
          'basis.court_decision',
          'supporting.household_book',
          'supporting.guarantee_certificate',
          'supporting.photos_3x4',
        ]);
    expect(spy.calls.last, 'pay:laoqr');
  });

  test('a retry skips create, re-runs update, and D-I re-uploads a swapped file',
      () async {
    final _Spy spy = _Spy()..failSubmitOnce = true;
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);
    cubit.emit(cubit.state.copyWith(form: _contestedWithFiles()));

    await cubit.submit();
    expect(spy.creates, 1);
    expect(spy.attached, hasLength(4));

    cubit.setPhotos(_file('photo-v2.jpg', 99));
    await cubit.submit();

    expect(spy.creates, 1, reason: ':852 `if (!id)`');
    expect(spy.updates, 2, reason: ':876 runs every attempt');
    expect(spy.attached, hasLength(8),
        reason: 'the identity change invalidated the single flag');
    expect(spy.attached.any((String a) => a.contains('photo-v2.jpg')), isTrue);
  });

  test('the mediation picker is wired: search, open, and the D-N reset',
      () async {
    final _Spy spy = _Spy();
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);
    await cubit.load();

    cubit.setDivorceType('voluntary');
    cubit.setMediationMode(DivorceMediationMode.existing);
    await Future<void>.delayed(Duration.zero);
    expect(spy.calls.any((String c) => c.startsWith('records:')), isTrue);
    expect(cubit.state.records.data?.data, isEmpty,
        reason: 'the only reachable state');

    await cubit.selectExisting('MR-1');
    expect(cubit.state.form.linkedRecord?.recordNo, 'MR-1');

    // A type change runs `resetMediation()` — which clears the link AND, per
    // D-N, the court block.
    cubit.setDivorceType('contested');
    expect(cubit.state.form.linkedRecord, isNull);
    expect(cubit.state.form.mediationMode, DivorceMediationMode.none);
  });

  test('step navigation: next advances, goBack retreats, and a refused step '
      'reveals errors', () async {
    final _Spy spy = _Spy();
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);
    cubit.emit(cubit.state.copyWith(form: _contestedWithFiles()));

    expect(cubit.state.step, 1);
    await cubit.next();
    expect(cubit.state.step, 2, reason: 'the contested arm is complete');

    cubit.goBack();
    expect(cubit.state.step, 1);

    // Now break it and try again.
    cubit.patchCourt((DivorceCourt c) => c.copyWith(name: ''));
    await cubit.next();
    expect(cubit.state.step, 1);
    expect(cubit.state.showErrors, isTrue);
  });

  test('a submit failure sets the banner and does not advance', () async {
    final _Spy spy = _Spy()..failSubmitOnce = true;
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);
    cubit.emit(cubit.state.copyWith(form: _contestedWithFiles(), step: 6));

    await cubit.submit();

    expect(cubit.state.submitPending, isFalse);
    expect(cubit.state.submitError, 'unavailable');
    expect(cubit.state.step, 6, reason: 'D-G — no step routing');
    expect(cubit.state.submitted, isNull);
  });

  test('a successful submit carries the receipt', () async {
    final _Spy spy = _Spy();
    final DivorceFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);
    cubit.emit(cubit.state.copyWith(form: _contestedWithFiles()));

    await cubit.submit();

    expect(cubit.state.submitted, isNotNull);
    expect(cubit.state.submitted!.receiptNo, 'RCPT-D',
        reason: '`receipt_no ?? transaction?.receipt_no` — :539\'s shape');
  });
}
