/// Divorce's page behaviour, driven on **rendered widgets**.
///
/// `F3-AC-16`, `F3-AC-20`, `F3-AC-49`, `F3-AC-50`, `F3-AC-52`, `F3-AC-53`,
/// `F3-AC-58`, `F3-AC-66`, `F3-AC-68`, `F3-AC-73`.
///
/// **`F3-AC-52` is the reason this file exists.** The criterion says it in as
/// many words: *"Asserted by pumping the widget, not by reading code."* The
/// payload test proved the two branch booleans are false and `canProceed` is
/// false; only a pumped widget can prove that the header cascade, the mediation
/// block and the court block are all **absent** and that nothing throws.
library;

import 'package:dartz/dartz.dart' hide Option;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_doc_upload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_select_field.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_payload.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/prerequisite_record.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';
import 'package:lcc_mobile_app/presentation/payment/draft_payment_section.dart';

import '../../../../helpers/app_test_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

/// The `divorce-type` list, **seeded with a third code**.
///
/// `fsd.md` § 5.5 probed the live list as exactly `{voluntary, contested}`, so
/// the terminal state is not reachable in the running app today (`F3-NV-6`) —
/// it is a latent hazard the moment a third code is added server-side. F0a's
/// rig seeds `mutual` into its own list for the same reason
/// (`execute_forms_oracle.mjs:309`), and this test does the same so the
/// behaviour is pinned before the server can add one.
const List<String> _divorceTypeCodes = <String>['voluntary', 'contested', 'mutual'];

class _Ports {
  _Ports({this.records});

  final Either<Failure, PrerequisiteRecordPage>? records;
  final List<String> lookups = <String>[];

  Future<Either<Failure, List<LookupOption>>> lookup(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async {
    lookups.add('${key.id}|$parentId|$paging');
    if (key is ReferenceListKey && key.type == 'divorce-type') {
      return Right<Failure, List<LookupOption>>(<LookupOption>[
        for (final String c in _divorceTypeCodes)
          LookupOption(id: c, code: c, label: Bilingual(en: c, lo: c)),
      ]);
    }
    return Right<Failure, List<LookupOption>>(<LookupOption>[
      LookupOption(
        id: 'lao',
        code: 'lao',
        label: const Bilingual(en: 'Lao', lo: 'ລາວ'),
      ),
    ]);
  }
}

DivorceFormCubit _cubit(_Ports ports) => DivorceFormCubit(
      clock: SubmissionClock.fixed(DateTime(2026, 8, 14, 2)),
      getLookupOptions: ports.lookup,
      createApplication: (Map<String, Object?> _) async =>
          throw StateError('create must not run in this test'),
      updateApplication: (String _, Map<String, Object?> __) async =>
          throw StateError('update must not run in this test'),
      addAttachment: (
        String _,
        PickedAttachment __, {
        required String slot,
        required String kind,
        required String label,
      }) async =>
          throw StateError('addAttachment must not run in this test'),
      submitApplication: (String _) async =>
          throw StateError('submit must not run in this test'),
      lang: Lang.en,
      loadRecords:
          ports.records == null ? null : (String _) async => ports.records!,
    );

Future<void> _pumpPage(
  WidgetTester tester,
  DivorceFormCubit cubit, {
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: Locale(locale),
      Builder(
        builder: (BuildContext context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: DivorceCertificatePage(
            cubit: cubit,
            onBack: () {},
            formatLak: (int? n) => n == null ? '—' : '$n LAK',
            pickFile: () async => null,
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

void main() {
  group('F3-AC-52 / F3-AC-53 — THE TERMINAL CODE, pumped', () {
    testWidgets('a third divorce_type renders ONLY the type select — no '
        'cascade, no mediation block, no court block, and nothing throws',
        (WidgetTester tester) async {
      final DivorceFormCubit cubit = _cubit(_Ports());
      addTearDown(cubit.close);
      await cubit.load();
      await _pumpPage(tester, cubit);

      // Drive it the way a citizen would: through the select's own callback.
      cubit.setDivorceType('mutual');
      await _settle(tester);

      // Nothing threw.
      expect(tester.takeException(), isNull,
          reason: 'the port must reproduce a dead end, not crash in one');

      // The select is still there — the POSITIVE control, without which the
      // absences below would pass on a page that rendered nothing at all.
      expect(find.byKey(const Key('divorce.typeSelect')), findsOneWidget);

      // …and nothing else from either arm.
      expect(find.byType(CertificateLocationFields), findsNothing,
          reason: ':1224 and :1339 are INSIDE the two branches, so a third '
              'code mounts no header cascade');
      expect(find.byType(DivorceTextAreaField), findsNothing,
          reason: 'no mediation block');
      expect(find.byType(CertificateDocUpload), findsNothing,
          reason: 'no court-decision upload');
      expect(
        find.text('divorce.courtName'.tr().toUpperCase()),
        findsNothing,
      );
      expect(find.text('divorce.mediationSelectExisting'.tr()), findsNothing);

      // Exactly ONE select on the step — the type. A second would mean an arm
      // leaked through.
      expect(find.byType(CertificateSelectField), findsOneWidget);
    });

    testWidgets('F3-AC-53 no default arm renders a message, panel or '
        'placeholder', (WidgetTester tester) async {
      final DivorceFormCubit cubit = _cubit(_Ports());
      addTearDown(cubit.close);
      await cubit.load();
      await _pumpPage(tester, cubit);
      cubit.setDivorceType('mutual');
      await _settle(tester);

      // The blank-type intro note must ALSO be absent: `!basis.divorceType` is
      // false for a third code, so the source shows nothing there either. A
      // port that reused the intro note as a fallback would fail here.
      expect(find.text('divorce.basisTypeNote'.tr()), findsNothing,
          reason: 'the intro note belongs to the BLANK state (:1046), not to '
              'the terminal one — the two are different states');
      expect(find.byType(DivorceNote), findsNothing,
          reason: 'no note of any tone — an invented "unsupported type" panel '
              'is the divergence F3-AC-53 forbids');
    });

    testWidgets('the CTA cannot advance out of the terminal state, however '
        'many times it is tapped', (WidgetTester tester) async {
      final DivorceFormCubit cubit = _cubit(_Ports());
      addTearDown(cubit.close);
      await cubit.load();
      await _pumpPage(tester, cubit);
      cubit.setDivorceType('mutual');
      await _settle(tester);

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('divorce.cta')));
        await _settle(tester);
      }
      expect(cubit.state.step, 1,
          reason: 'canProceed() falls through to the contested arm at :765 and '
              'demands a court decision that this state never renders — the '
              'step cannot advance for any sequence of clicks');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the BLANK state is a DIFFERENT state and DOES show the note',
        (WidgetTester tester) async {
      // The bounded half of the ban. Without this, "no note in the terminal
      // state" could be satisfied by never rendering the note at all.
      final DivorceFormCubit cubit = _cubit(_Ports());
      addTearDown(cubit.close);
      await cubit.load();
      await _pumpPage(tester, cubit);

      expect(cubit.state.form.basis.divorceType, isEmpty);
      expect(find.text('divorce.basisTypeNote'.tr()), findsOneWidget);
    });

    testWidgets('a KNOWN code does mount its arm — the other bounded half',
        (WidgetTester tester) async {
      final DivorceFormCubit cubit = _cubit(_Ports());
      addTearDown(cubit.close);
      await cubit.load();
      await _pumpPage(tester, cubit);

      cubit.setDivorceType('contested');
      await _settle(tester);

      expect(find.byType(CertificateLocationFields), findsOneWidget,
          reason: 'the contested arm DOES mount the header cascade (:1339)');
      expect(find.byType(CertificateDocUpload), findsOneWidget,
          reason: 'and the court-decision upload');
      // FIELD LABELS render UPPERCASED — `formFields.tsx:41` carries the CSS
      // `uppercase` and `FieldLabel._Uppercase` reproduces it. Asserting the
      // raw key's value would assert a string the citizen never sees.
      expect(
        find.text('divorce.courtName'.tr().toUpperCase()),
        findsOneWidget,
      );
    });
  });

  testWidgets('F3-AC-68 no gender control renders on either spouse step',
      (WidgetTester tester) async {
    final DivorceFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);

    for (final int step in <int>[2, 3]) {
      cubit.emit(cubit.state.copyWith(step: step));
      await _settle(tester);

      final Iterable<CertificateSelectField> selects =
          tester.widgetList<CertificateSelectField>(
        find.byType(CertificateSelectField),
      );
      expect(
        selects.any((CertificateSelectField s) =>
            s.options.any((o) => o.value == 'female' || o.value == 'male')),
        isFalse,
        reason: 'step $step: DivorceSpouseInfo has no gender field, so no '
            'control can bind to one. Marriage has one in this exact slot.',
      );
      expect(find.text('divorce.gender'), findsNothing);
      // The positive control: the spouse step really did render. Uppercased,
      // for the reason above.
      expect(
        find.text('divorce.fullName'.tr().toUpperCase()),
        findsOneWidget,
      );
    }
  });

  testWidgets('F3-AC-73 the review step renders NO fee card',
      (WidgetTester tester) async {
    // Marriage's review has one; Divorce's does not, and `divorce.ts` has no
    // `feeSectionTitle` key at all — the independent confirmation. Both halves
    // are asserted: the key's absence AND the render's.
    final DivorceFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);
    cubit.emit(cubit.state.copyWith(step: 5));
    await _settle(tester);

    // easy_localization returns the KEY itself when it is missing, so a
    // resolved-to-key result IS the absence.
    expect('divorce.feeSectionTitle'.tr(), 'divorce.feeSectionTitle',
        reason: 'the key does not exist in the divorce namespace');
    expect(find.textContaining('feeSectionTitle'), findsNothing);
    expect(find.text('FEES'), findsNothing);

    // The positive control: the review step really did render its other cards.
    expect(find.text('divorce.reviewBasis'.tr().toUpperCase()), findsOneWidget);
  });

  testWidgets('F3-AC-58 step 4 renders the three uploads in DOM order, which '
      'is NOT the POST order', (WidgetTester tester) async {
    final DivorceFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);
    cubit.emit(cubit.state.copyWith(step: 4));
    await _settle(tester);

    final List<String> rendered = tester
        .widgetList<CertificateDocUpload>(find.byType(CertificateDocUpload))
        .map((CertificateDocUpload u) => u.label)
        .toList();

    expect(rendered, <String>[
      'divorce.householdBook'.tr(),
      'divorce.guaranteeCert'.tr(),
      'divorce.photos3x4'.tr(),
    ], reason: 'render order — :1442, :1448, :1455');

    // The POST list starts with the court decision, which does NOT render here
    // at all. Two different lists, both asserted (`F3-AC-58`).
    expect(divorceStep4DomOrder.length, 3);
    expect(divorceStep4DomOrder.first, 'supporting.household_book');
    expect(rendered.length, isNot(equals(4)),
        reason: 'basis.court_decision is first on the POST list and renders on '
            'STEP 1, not here');
  });

  testWidgets('F3-AC-16 step 6 mounts the draft-mode payment surface',
      (WidgetTester tester) async {
    final DivorceFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await _pumpPage(tester, cubit);
    cubit.emit(cubit.state.copyWith(step: 6));
    await _settle(tester);

    expect(find.byType(DraftPaymentSection), findsOneWidget);
  });

  testWidgets('F3-AC-49 the mediation picker\'s EMPTY state renders the '
      'page-local sentence', (WidgetTester tester) async {
    final DivorceFormCubit cubit = _cubit(
      _Ports(
        records: const Right<Failure, PrerequisiteRecordPage>(
          PrerequisiteRecordPage.empty,
        ),
      ),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);

    cubit.setDivorceType('voluntary');
    await _settle(tester);
    await tester.tap(find.byKey(const Key('divorce.chooseExisting')));
    await _settle(tester);

    expect(find.text(kDivorceCopy['recordsEmpty']!['en']!), findsOneWidget,
        reason: 'the MEDIATION sentence, not Marriage\'s betrothal one — the '
            'two COPY tables differ in six of eight entries');
    expect(find.text(kMarriageRecordsEmptyProbe), findsNothing);
  });

  testWidgets('F3-AC-66 no /payment-methods read across the whole lifecycle',
      (WidgetTester tester) async {
    final _Ports ports = _Ports();
    final DivorceFormCubit cubit = _cubit(ports);
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);
    for (int step = 1; step <= 6; step++) {
      cubit.emit(cubit.state.copyWith(step: step));
      await _settle(tester);
    }
    expect(ports.lookups.where((String l) => l.contains('payment')), isEmpty);
  });

  testWidgets('D-N through the UI: contested -> voluntary clears the court '
      'block the citizen already filled', (WidgetTester tester) async {
    final DivorceFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);

    cubit.setDivorceType('contested');
    await _settle(tester);
    cubit.patchCourt((DivorceCourt c) =>
        c.copyWith(name: "Test People's Court", decisionDate: '2026-06-30'));
    await _settle(tester);
    expect(cubit.state.form.court.name, isNotEmpty);

    // The switch runs `resetMediation()` from the type onChange (`:1041`),
    // which carries D-N's fix.
    cubit.setDivorceType('voluntary');
    await _settle(tester);

    expect(cubit.state.form.court.name, isEmpty);
    expect(cubit.state.form.court.decisionDate, isEmpty);
    expect(cubit.state.form.courtDecision, isNull,
        reason: 'contested -> voluntary must not submit a voluntary divorce '
            'carrying a court decree (fsd.md D-N, FIX upheld)');
  });
}

/// Marriage's empty sentence, spelled here so the cross-page assertion above
/// does not import `marriage/` into a `divorce/` test.
const String kMarriageRecordsEmptyProbe =
    'No betrothal record is linked to you yet. Create one first, or ask your '
    'village office to record it.';
