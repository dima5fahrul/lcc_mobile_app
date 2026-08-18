/// The submit orchestration, driven against spies — `F3-AC-31`, `F3-AC-57`,
/// `F3-AC-60`, `F3-AC-61`, `F3-AC-62`.
///
/// ## Why these needed a spy rather than a reading
///
/// Each one is a claim about **how many times something happened, and in what
/// order** — the class of property that is invisible in a payload and invisible
/// in the source text of the cubit. "`create` is skipped on retry" is a field
/// read in one branch; only a counted call proves the branch is taken.
///
/// The D-I criteria in particular were reported PARTIAL until this file
/// existed, because "the flag is invalidated when a file's identity changes" is
/// exactly the shape that reads correct and behaves wrong.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'dart:typed_data';

import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_payload.dart';

import '../../../application/application_write_fakes.dart';
import 'marriage_tier0_subject.dart';

/// A file whose **identity** is its name plus its byte length — the two things
/// `marriageAttachmentIdentity` keys on.
PickedAttachment _file(String name, int size) => PickedAttachment(
      name: name,
      bytes: Uint8List(size),
    );

/// Records every call the submit path makes, in order.
class _Spy {
  final List<String> calls = <String>[];
  final List<String> attachmentIdentities = <String>[];
  int creates = 0;
  int updates = 0;
  int submits = 0;
  int pays = 0;

  /// Set to make `submit` fail once, so a retry can be observed.
  bool failSubmitOnce = false;
  bool _failed = false;

  /// The shared fixture — `application_write_fakes.dart` owns the 20-field
  /// `ApplicationRow` so a change to it lands in one place.
  ApplicationDetail get _detail => applicationDetailFixture(
        reference: 'MC-2026-000321',
        feeLak: 200000,
      );

  Future<Either<Failure, List<LookupOption>>> lookup(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async {
    // The whole point of `F3-AC-31`: the PAGING MODE is recorded, per call.
    calls.add('lookup:${key.id}:parent=$parentId:paging=${paging.name}');
    return Right<Failure, List<LookupOption>>(<LookupOption>[
      for (int i = 0; i < 200; i++)
        LookupOption(
          id: 'v$i',
          code: 'v$i',
          label: Bilingual(en: 'Village $i', lo: 'ບ້ານ $i'),
        ),
    ]);
  }

  Future<Either<Failure, ApplicationDetail>> create(
    Map<String, Object?> body,
  ) async {
    creates++;
    calls.add('create');
    return Right<Failure, ApplicationDetail>(_detail);
  }

  Future<Either<Failure, ApplicationDetail>> update(
    String id,
    Map<String, Object?> body,
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
    calls.add('attach:$slot:$label:${file.name}');
    attachmentIdentities.add('$slot|$label|${file.name}');
    return const Right<Failure, Object?>(null);
  }

  Future<Either<Failure, ApplicationDetail>> submitCase(String id) async {
    submits++;
    calls.add('submit');
    if (failSubmitOnce && !_failed) {
      _failed = true;
      return const Left<Failure, ApplicationDetail>(
        Failure('The service is unavailable.'),
      );
    }
    return Right<Failure, ApplicationDetail>(_detail);
  }

  Future<Either<Failure, Object?>> pay(
    String id, {
    required String methodCode,
  }) async {
    pays++;
    calls.add('pay:$methodCode');
    return const Right<Failure, Object?>(<String, Object?>{
      'receipt_no': 'RCPT-1',
    });
  }
}

MarriageFormCubit _cubit(_Spy spy) => MarriageFormCubit(
      clock: SubmissionClock.fixed(kMarriageRegisterInstant),
      getLookupOptions: spy.lookup,
      createApplication: spy.create,
      updateApplication: spy.update,
      addAttachment: spy.attach,
      submitApplication: spy.submitCase,
      pay: spy.pay,
      lang: Lang.en,
    );

MarriageFormData _formWithFiles() {
  final MarriageFormData f = marriageFormFromFixture(
    readMarriageJson('$kMarriageFixtureDir/asymmetric.en.json'),
  );
  return f.copyWith(
    spouseA: f.spouseA.copyWith(singleStatusCert: _file('a-single.pdf', 10)),
    spouseB: f.spouseB.copyWith(singleStatusCert: _file('b-single.pdf', 11)),
    householdBook: _file('book.pdf', 12),
    photos: _file('photo.jpg', 13),
  );
}

void main() {
  group('F3-AC-31 — the village read is FIRST PAGE ONLY', () {
    test('one villages request, and it carries firstPageOnly', () async {
      final _Spy spy = _Spy();
      final MarriageFormCubit cubit = _cubit(spy);
      addTearDown(cubit.close);

      // Pick a province, then a district — the second is what triggers the
      // village read.
      cubit.setHeader(const CertificateLocationValue(provinceId: 'p-1'));
      await Future<void>.delayed(Duration.zero);
      cubit.setHeader(
        const CertificateLocationValue(provinceId: 'p-1', districtId: 'd-1'),
      );
      await Future<void>.delayed(Duration.zero);

      final List<String> villageCalls = spy.calls
          .where((String c) => c.contains('locations:villages'))
          .toList();

      expect(villageCalls, hasLength(1),
          reason: 'EXACTLY ONE request. The kernel LocationFields loops to '
              'total_pages (L-7); ApiLocationFields fetches one page '
              '(MarriageCertificatePage.tsx:296-298), and porting the loop '
              'would be L-10(b)');
      expect(villageCalls.single, contains('paging=firstPageOnly'),
          reason: 'the parameter F0 put in the lookup contract for exactly '
              'this call site');

      // The positive half: 200 options really did arrive, so "one request" is
      // not one request that returned nothing.
      expect(
        cubit.state.cascade(MarriageCascade.header).villages.options,
        hasLength(200),
      );
    });

    test('the DISTRICT read is NOT firstPageOnly — the bound on the other side',
        () async {
      final _Spy spy = _Spy();
      final MarriageFormCubit cubit = _cubit(spy);
      addTearDown(cubit.close);

      cubit.setHeader(const CertificateLocationValue(provinceId: 'p-1'));
      await Future<void>.delayed(Duration.zero);

      final String districtCall = spy.calls
          .firstWhere((String c) => c.contains('locations:districts'));
      expect(districtCall, contains('paging=all'),
          reason: 'districts are not paged; only villages carry the '
              'divergence, and a blanket firstPageOnly would be a second '
              'defect');
    });
  });

  group('the submit sequence — F3-AC-57, F3-AC-61', () {
    test('create -> attach -> update -> submit -> pay, in THAT order', () async {
      // Note the order: the NESTED family attaches BEFORE it updates. The flat
      // family updates first (`submission_plan.dart:250-256`).
      final _Spy spy = _Spy();
      final MarriageFormCubit cubit = _cubit(spy);
      addTearDown(cubit.close);
      cubit.emit(cubit.state.copyWith(form: _formWithFiles()));

      await cubit.submit();

      final List<String> phases = spy.calls
          .where((String c) => !c.startsWith('lookup'))
          .map((String c) => c.split(':').first)
          .toList();
      expect(phases, <String>[
        'create',
        'attach', 'attach', 'attach', 'attach',
        'update',
        'submit',
        'pay',
      ]);
    });

    test('F3-AC-57 uploads are SEQUENTIAL and in uploads() order', () async {
      final _Spy spy = _Spy();
      final MarriageFormCubit cubit = _cubit(spy);
      addTearDown(cubit.close);
      cubit.emit(cubit.state.copyWith(form: _formWithFiles()));

      await cubit.submit();

      expect(
        spy.calls.where((String c) => c.startsWith('attach')).toList(),
        <String>[
          'attach:spouses.single_status_certificate:Spouse A:a-single.pdf',
          'attach:spouses.single_status_certificate:Spouse B:b-single.pdf',
          'attach:supporting.household_book:Household book:book.pdf',
          'attach:supporting.photos_3x4:3x4 photographs:photo.jpg',
        ],
        reason: 'the DUPLICATED slot appears twice, A then B, and the order is '
            'uploads() order. `Future.wait` would not preserve it.',
      );
    });

    test('F3-AC-61 a retry SKIPS create and runs update EVERY time', () async {
      final _Spy spy = _Spy()..failSubmitOnce = true;
      final MarriageFormCubit cubit = _cubit(spy);
      addTearDown(cubit.close);
      cubit.emit(cubit.state.copyWith(form: _formWithFiles()));

      await cubit.submit(); // fails at submit, draft now exists
      expect(spy.creates, 1);
      expect(cubit.state.draftId, 'case-1');

      await cubit.submit(); // retry

      expect(spy.creates, 1,
          reason: '`:956` `if (!id)` — a retry must never duplicate the case');
      expect(spy.updates, 2,
          reason: '`:980` is outside any guard: update runs every time');
      expect(spy.submits, 2);
    });
  });

  group('D-I — F3-AC-60, F3-AC-62', () {
    test('F3-AC-60 replacing a file after a failed submit DOES re-upload it',
        () async {
      final _Spy spy = _Spy()..failSubmitOnce = true;
      final MarriageFormCubit cubit = _cubit(spy);
      addTearDown(cubit.close);
      cubit.emit(cubit.state.copyWith(form: _formWithFiles()));

      await cubit.submit();
      final int firstRound = spy.attachmentIdentities.length;
      expect(firstRound, 4);
      expect(cubit.state.attachmentsSent, isTrue);

      // The citizen swaps the household book for a different scan and retries.
      cubit.setHouseholdBook(_file('book-v2.pdf', 99));
      await cubit.submit();

      expect(spy.attachmentIdentities.length, firstRound + 4,
          reason: 'the single flag was INVALIDATED by the identity change, so '
              'the whole set went again — `attachment_guard.dart:32-35`\'s '
              'contract is "key on file identity, not on slot"');
      expect(
        spy.attachmentIdentities.last,
        contains('photo.jpg'),
      );
      expect(
        spy.attachmentIdentities.any((String i) => i.contains('book-v2.pdf')),
        isTrue,
        reason: 'the REPLACED file reached the wire. Without D-I\'s fix the '
            'citizen\'s new document is silently never uploaded.',
      );
    });

    test('an UNCHANGED file set does NOT re-upload — the bound on the fix',
        () async {
      // Without this, `F3-AC-60` would pass on a port that simply dropped the
      // guard and re-uploaded everything every time, which is a different
      // defect (duplicate attachments on every retry).
      final _Spy spy = _Spy()..failSubmitOnce = true;
      final MarriageFormCubit cubit = _cubit(spy);
      addTearDown(cubit.close);
      cubit.emit(cubit.state.copyWith(form: _formWithFiles()));

      await cubit.submit();
      expect(spy.attachmentIdentities, hasLength(4));

      await cubit.submit(); // retry, nothing changed

      expect(spy.attachmentIdentities, hasLength(4),
          reason: 'the flag still holds when no identity moved — the guard is '
              'invalidated by CHANGE, not disabled');
    });

    test('F3-AC-62 the D-I fix moves no form_data byte', () async {
      // The fix lives entirely in the attachment guard; it cannot touch the
      // payload. Asserted by building the bodies either side of a file swap.
      final MarriageFormData before = _formWithFiles();
      final MarriageFormData after = before.copyWith(
        householdBook: _file('book-v2.pdf', 99),
      );
      final SubmissionClock clock =
          SubmissionClock.fixed(kMarriageRegisterInstant);

      expect(
        marriageSubmissionBodies(before, clock, 'MC-1').create.toString(),
        marriageSubmissionBodies(after, clock, 'MC-1').create.toString(),
        reason: 'attachments are not in form_data, so swapping one is '
            'Tier-0-invisible on all twelve documents',
      );
    });
  });

  test('F3-AC-65 the pay call carries the STATIC map\'s code', () async {
    final _Spy spy = _Spy();
    final MarriageFormCubit cubit = _cubit(spy);
    addTearDown(cubit.close);
    cubit.emit(cubit.state.copyWith(form: _formWithFiles()));

    await cubit.submit();

    expect(spy.calls.last, 'pay:laoqr',
        reason: 'METHOD_CODE[qr] — the hardcoded map at :140-144, with no '
            '/payment-methods read anywhere in the sequence');
    expect(spy.calls.where((String c) => c.contains('payment-methods')), isEmpty);
  });
}
