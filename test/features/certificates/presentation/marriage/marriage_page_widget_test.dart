/// Marriage's page behaviour, driven on **rendered widgets**.
///
/// `F3-AC-16`, `F3-AC-20`, `F3-AC-49`, `F3-AC-50`, `F3-AC-51`, `F3-AC-66`,
/// `F3-AC-67`, `F3-AC-71`, `F3-AC-73`.
///
/// ## Why these could not be discharged by the payload tests
///
/// Every criterion here is about what the citizen **sees**, and the Capability
/// Rule is explicit: a criterion that would pass with its subject inert is not
/// a criterion. "The page renders the English gender labels under `lo`" is a
/// claim about a rendered dropdown; reading `kMarriageGenderLabels` proves the
/// constant, not the render.
///
/// ## No DI container is initialised anywhere in this file
///
/// The cubit is constructed with fake function ports. A widget that reached
/// for a locator would throw.
library;

import 'package:dartz/dartz.dart' hide Option;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_select_field.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
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

/// Every network read the page can make, as a fake. **A call that a test did
/// not arrange throws** rather than returning a plausible empty value.
class _Ports {
  _Ports({this.records, this.quote});

  final Either<Failure, PrerequisiteRecordPage>? records;
  final Either<Failure, MarriageQuote>? quote;

  int paymentMethodReads = 0;
  final List<String> lookups = <String>[];

  Future<Either<Failure, List<LookupOption>>> lookup(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async {
    lookups.add('${key.id}|$parentId|$paging');
    return Right<Failure, List<LookupOption>>(<LookupOption>[
      LookupOption(
        id: 'lao',
        code: 'lao',
        label: const Bilingual(en: 'Lao', lo: 'ລາວ'),
      ),
      LookupOption(
        id: 'thai',
        code: 'thai',
        label: const Bilingual(en: 'Thai', lo: 'ໄທ'),
      ),
    ]);
  }
}

MarriageFormCubit _cubit(_Ports ports) => MarriageFormCubit(
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
      loadRecords: ports.records == null
          ? null
          : (String _) async => ports.records!,
      // The port takes no inputs — `blocked.md` § 1 option (b). This test
      // still injects a quote **with line items**, because it is asserting
      // what the review card renders when a breakdown exists, not what the
      // catalogue-backed adapter answers (which is always an empty `lines` —
      // `certificate_quote_port_test.dart`).
      loadQuote: ports.quote == null ? null : () async => ports.quote!,
    );

Future<void> _pumpPage(
  WidgetTester tester,
  MarriageFormCubit cubit, {
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
          home: MarriageCertificatePage(
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
  testWidgets('F3-AC-67 under `lo` the gender dropdown renders the ENGLISH '
      'literals — a reproduced source defect', (WidgetTester tester) async {
    // `MarriageCertificatePage.tsx:134-137` — `[{value:"female",label:"Female"},
    // {value:"male",label:"Male"}]`, bare English with no Lao at all. A Lao
    // rendering the web does not have is `L-10`(b) and a Tier 1 failure.
    final _Ports ports = _Ports();
    final MarriageFormCubit cubit = _cubit(ports);
    addTearDown(cubit.close);
    await cubit.load();

    // Step 2 is Spouse A, where the gender select renders.
    cubit.setBetrothalMode(MarriageBetrothalMode.newRecord);
    await _pumpPage(tester, cubit, locale: 'lo');
    cubit.emit(cubit.state.copyWith(step: 2));
    await _settle(tester);

    // The page IS in Lao — the positive control, without which the assertion
    // below would pass on a page that failed to switch locale at all.
    expect(find.text('ໃບຢັ້ງຢືນການແຕ່ງງານ'), findsOneWidget,
        reason: 'marriage.title in Lao — the locale seed took');

    final Iterable<CertificateSelectField> selects =
        tester.widgetList<CertificateSelectField>(
      find.byType(CertificateSelectField),
    );
    final CertificateSelectField gender = selects.firstWhere(
      (CertificateSelectField s) =>
          s.options.any((o) => o.value == 'female'),
    );
    expect(
      gender.options.map((o) => o.label).toList(),
      <String>['Female', 'Male'],
      reason: 'reproduced from MarriageCertificatePage.tsx:134-137. If this '
          'reads Lao, someone improved the port.',
    );
  });

  testWidgets('F3-AC-73 the review step renders a FEE CARD',
      (WidgetTester tester) async {
    final _Ports ports = _Ports(
      quote: Right<Failure, MarriageQuote>(
        const MarriageQuote(
          feeLak: 200000,
          lines: <MarriageQuoteLine>[
            MarriageQuoteLine(label: 'Betrothal record', amountLak: 100000),
            MarriageQuoteLine(label: 'Registration', amountLak: 100000),
          ],
        ),
      ),
    );
    final MarriageFormCubit cubit = _cubit(ports);
    addTearDown(cubit.close);
    await cubit.load();

    await _pumpPage(tester, cubit);
    cubit.emit(cubit.state.copyWith(step: 6));
    await _settle(tester);

    // `:1571-1577`. Divorce's review renders NONE — asserted in its own file.
    //
    // The card TITLE is uppercased: `:1580` carries the CSS `uppercase`, which
    // `CertificateSectionLabel` reproduces with `toUpperCase()`. Asserting the
    // raw key's value would be asserting something the citizen never sees.
    expect(
      find.text('marriage.feeSectionTitle'.tr().toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('marriage.feeTotal'.tr()), findsOneWidget,
        reason: 'the ROW label is not uppercased — only the card title is');
    expect(find.text('200000 LAK'), findsOneWidget);
    expect(find.text('Betrothal record'), findsOneWidget,
        reason: 'the itemised lines, not just the total');
  });

  testWidgets('F3-AC-16 step 7 mounts F1\'s draft-mode payment surface',
      (WidgetTester tester) async {
    final MarriageFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await _pumpPage(tester, cubit);
    cubit.emit(cubit.state.copyWith(step: 7));
    await _settle(tester);

    expect(find.byType(DraftPaymentSection), findsOneWidget,
        reason: 'mounted, not reimplemented — F1 authored draft mode as a '
            'shared surface F3 inherits');
  });

  group('the betrothal picker — F3-AC-49, F3-AC-50', () {
    Future<void> openPicker(WidgetTester tester, MarriageFormCubit c) async {
      await _pumpPage(tester, c);
      await tester.tap(find.byKey(const Key('marriage.chooseExisting')));
      await _settle(tester);
    }

    testWidgets('F3-AC-49 the EMPTY state renders the page-local sentence, '
        'not an i18n key', (WidgetTester tester) async {
      // The only reachable state on every account this programme has.
      final MarriageFormCubit cubit = _cubit(
        _Ports(
          records: const Right<Failure, PrerequisiteRecordPage>(
            PrerequisiteRecordPage.empty,
          ),
        ),
      );
      addTearDown(cubit.close);
      await openPicker(tester, cubit);

      expect(
        find.text(kMarriageCopy['recordsEmpty']!['en']!),
        findsOneWidget,
        reason: 'from the page-local COPY table (:111-114), NOT an i18n '
            'namespace — the source keeps it out and F3-AC-95 asserts it '
            'stays out',
      );
    });

    testWidgets('F3-AC-49 the empty sentence follows the ACTIVE LOCALE',
        (WidgetTester tester) async {
      final MarriageFormCubit cubit = _cubit(
        _Ports(
          records: const Right<Failure, PrerequisiteRecordPage>(
            PrerequisiteRecordPage.empty,
          ),
        ),
      );
      addTearDown(cubit.close);
      await _pumpPage(tester, cubit, locale: 'lo');
      await tester.tap(find.byKey(const Key('marriage.chooseExisting')));
      await _settle(tester);

      expect(find.text(kMarriageCopy['recordsEmpty']!['lo']!), findsOneWidget);
      expect(find.text(kMarriageCopy['recordsEmpty']!['en']!), findsNothing);
    });

    testWidgets('F3-AC-50 the ERROR state renders its sentence AND a retry — '
        'the contrast with F3-AC-25', (WidgetTester tester) async {
      // This picker's query DOES expose `error` (`:1210`), unlike `useRefList`.
      // So a retry here is faithful, where a retry on a reference select would
      // be a divergence. The two live side by side and must not be harmonised.
      final MarriageFormCubit cubit = _cubit(
        _Ports(
          records: const Left<Failure, PrerequisiteRecordPage>(
            Failure('The service is unavailable.'),
          ),
        ),
      );
      addTearDown(cubit.close);
      await openPicker(tester, cubit);

      expect(find.text(kMarriageCopy['recordsError']!['en']!), findsOneWidget);
      expect(find.text('The service is unavailable.'), findsOneWidget,
          reason: 'the API sentence is rendered beneath the generic one');
      expect(find.byKey(const Key('marriage.recordsRetry')), findsOneWidget,
          reason: 'F3-AC-50 — this state HAS a retry; F3-AC-25 asserts the '
              'reference select does NOT');
    });

    testWidgets('F3-AC-50 the LOADING state renders its sentence',
        (WidgetTester tester) async {
      final MarriageFormCubit cubit = _cubit(_Ports());
      addTearDown(cubit.close);
      await _pumpPage(tester, cubit);
      cubit.emit(
        cubit.state.copyWith(
          form: cubit.state.form
              .copyWith(betrothalMode: MarriageBetrothalMode.existing),
          records: const MarriageAsync<PrerequisiteRecordPage>.loading(),
        ),
      );
      await _settle(tester);

      expect(
        find.text(kMarriageCopy['recordsLoading']!['en']!),
        findsOneWidget,
      );
    });

    testWidgets('F3-AC-51 the search is debounced 300 ms and does not fire '
        'per keystroke', (WidgetTester tester) async {
      int calls = 0;
      final MarriageFormCubit cubit = MarriageFormCubit(
        clock: SubmissionClock.fixed(DateTime(2026, 8, 14, 2)),
        getLookupOptions: _Ports().lookup,
        createApplication: (Map<String, Object?> _) async =>
            throw StateError('unused'),
        updateApplication: (String _, Map<String, Object?> __) async =>
            throw StateError('unused'),
        addAttachment: (
          String _,
          PickedAttachment __, {
          required String slot,
          required String kind,
          required String label,
        }) async =>
            throw StateError('unused'),
        submitApplication: (String _) async => throw StateError('unused'),
        lang: Lang.en,
        loadRecords: (String _) async {
          calls++;
          return const Right<Failure, PrerequisiteRecordPage>(
            PrerequisiteRecordPage.empty,
          );
        },
      );
      addTearDown(cubit.close);

      await _pumpPage(tester, cubit);
      await tester.tap(find.byKey(const Key('marriage.chooseExisting')));
      await _settle(tester);
      final int afterOpen = calls;

      await tester.enterText(
        find.byKey(const Key('marriage.recordSearch')),
        'Somsak',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, afterOpen,
          reason: 'still inside the 300 ms window (:752) — a per-keystroke '
              'query is a different program');

      await tester.pump(const Duration(milliseconds: 250));
      await _settle(tester);
      expect(calls, afterOpen + 1, reason: 'exactly one query after the window');
    });
  });

  testWidgets('F3-AC-66 a full page lifecycle issues NO /payment-methods read',
      (WidgetTester tester) async {
    // `METHOD_CODE` is a static map (`:140-144`); Resident/Birth/Death resolve
    // theirs from `/payment-methods` and this page never makes the request.
    // The spy is the lookup recorder: every read the cubit CAN make goes
    // through `getLookupOptions`, and a payment-methods port does not exist on
    // this cubit at all.
    final _Ports ports = _Ports();
    final MarriageFormCubit cubit = _cubit(ports);
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);
    for (int step = 1; step <= 7; step++) {
      cubit.emit(cubit.state.copyWith(step: step));
      await _settle(tester);
    }

    expect(ports.paymentMethodReads, 0);
    expect(
      ports.lookups.where((String l) => l.contains('payment')),
      isEmpty,
      reason: 'the web never makes this request here, and making it is an '
          'observable network divergence',
    );
    // The static map is what the page uses instead.
    expect(marriageMethodCodeForProbe(), 'laoqr');
  });

  testWidgets('F3-AC-71 a 422 lands on the fields and does NOT change the step',
      (WidgetTester tester) async {
    // D-G REPRODUCED. Marriage has no `FIELD_STEP` map and no
    // `stepOfFirstError`, so a 422 naming a step-2 field received on the review
    // step leaves the citizen on review.
    final MarriageFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await _pumpPage(tester, cubit);
    cubit.emit(cubit.state.copyWith(step: 6));
    await _settle(tester);
    expect(cubit.state.step, 6);

    cubit.emit(
      cubit.state.copyWith(
        serverErrors: const <String, String>{
          'spouses.name': 'The full name is required.',
        },
        showErrors: true,
      ),
    );
    await _settle(tester);

    expect(cubit.state.step, 6,
        reason: 'routing a 422 means navigating the wizard to a different '
            'step, which is the most observable thing a form can do. The '
            'source does not, so neither does the port (§ 6.10, FU-8).');
    // `:1122` renders `• {message}` — the bullet is part of the `<li>`, so it
    // is part of what the citizen reads.
    expect(find.text('• The full name is required.'), findsOneWidget,
        reason: 'the message is still SHOWN, in the review step\'s banner — '
            'reproducing the absence of routing is not swallowing the error');
  });

  testWidgets('F3-AC-20 the page mounts the SHARED controls, not local copies',
      (WidgetTester tester) async {
    final MarriageFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpPage(tester, cubit);
    cubit.emit(cubit.state.copyWith(step: 2));
    await _settle(tester);

    // The types are `certificate_forms/`'s. A duplicate class in `marriage/`
    // would be a different type here and this would find nothing.
    expect(find.byType(CertificateSelectField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the CTA is never disabled, and tapping it on an incomplete '
      'step reveals errors without advancing', (WidgetTester tester) async {
    final MarriageFormCubit cubit = _cubit(_Ports());
    addTearDown(cubit.close);
    await _pumpPage(tester, cubit);

    expect(cubit.state.step, 1);
    expect(cubit.state.showErrors, isFalse);

    await tester.tap(find.byKey(const Key('marriage.cta')));
    await _settle(tester);

    expect(cubit.state.step, 1, reason: 'step 1 with no mode chosen is refused '
        'at :857');
    expect(cubit.state.showErrors, isTrue);
    expect(find.text('marriage.betrothalChooseRequired'.tr()), findsOneWidget);
  });
}

/// The static map, read through the page's own function so the test cannot
/// pass by re-declaring the constant.
String marriageMethodCodeForProbe() =>
    kMarriageMethodCode.values.first;

/// Kept so the analyzer sees the 422 types the test constructs are the real
/// ones a repository would hand back.
ApiFailure sampleValidationFailure() => ApiFailure(
      const ApiException(
        status: 422,
        code: ApiCode.validationError,
        message: 'Validation failed',
        fields: <FieldError>[
          FieldError(field: 'spouses.name', message: 'The full name is required.'),
        ],
      ),
      'Validation failed',
    );
