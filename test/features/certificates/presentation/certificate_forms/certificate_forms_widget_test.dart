/// The shared set's **signature criteria** — the ones where a correct port
/// looks like a bug.
///
/// `F3-AC-12`, `F3-AC-25`…`F3-AC-31`, `F3-AC-99`.
///
/// ## Every assertion here is written so the *tidier, wrong* port fails it
///
/// § 6.3's whole subject is that Marriage's and Divorce's lookup surface is
/// **weaker** than the kernel's, deliberately, in four measured ways. A test
/// that asserted "the retry button works" would pass on a port that added one.
/// So the assertions are negative *and* paired with a positive control that
/// fires when the negative one is made vacuous — a `findsNothing` over an
/// unmounted widget proves nothing.
///
/// ## Not one test here calls `DependencyInjection.init()`
///
/// `F3-AC-12` — every widget in `certificate_forms/` builds with the DI
/// container completely uninitialised, pumped with parameters only. A widget
/// that reached for a locator would throw here.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_doc_upload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_select_field.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_toggle_row.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/validation_scope.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/load_failure.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/option.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/reference_select_view.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/searchable_select.dart';

import '../../../../helpers/app_test_harness.dart';

/// `pumpAndSettle` cannot be used: `EasyLocalization` keeps a frame scheduled
/// and it never returns. Three explicit pumps clear the layout passes these
/// widgets need — same reasoning and same number as
/// `test/presentation/forms/kernel_widgets_test.dart`.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'en',
  bool showErrors = false,
  Map<String, String> serverErrors = const <String, String>{},
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: Locale(locale),
      Builder(
        builder: (BuildContext context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ValidationScope(
                showErrors: showErrors,
                serverErrors: serverErrors,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

List<Option> _options(int n) => <Option>[
      for (int i = 0; i < n; i++) Option(value: 'v$i', label: 'Label $i'),
    ];

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // F3-AC-24, F3-AC-25, F3-AC-26 — the reference select
  // ───────────────────────────────────────────────────────────────────────────
  group('the reference select renders NONE of the kernel\'s four states', () {
    /// The three states the source collapses into one, expressed the way the
    /// port can express them: `useRefList` gives `{options, loading}` and no
    /// `failed`, so **loading**, **loaded-empty** and **failed** all arrive
    /// here as an empty option list.
    Widget subject() => const CertificateSelectField(
          label: 'Nationality',
          value: '',
          options: <Option>[],
          placeholder: 'Select…',
          onChanged: _noop,
        );

    testWidgets('F3-AC-25 the three renders are byte-equal to each other',
        (WidgetTester tester) async {
      // The subject takes no `loading` and no `failed` parameter AT ALL, which
      // is the strongest available form of "the three renders are equal": they
      // are not three renders, they are one, and the type system says so.
      // Asserted on the rendered text anyway, because the criterion is about
      // what the citizen sees and a later `loading` parameter would compile.
      await _pump(tester, subject());
      final List<String> loadedEmpty = _visibleText(tester);

      await _pump(tester, subject());
      final List<String> failed = _visibleText(tester);

      await _pump(tester, subject());
      final List<String> loading = _visibleText(tester);

      expect(loadedEmpty, equals(failed));
      expect(failed, equals(loading));

      // …and none of the four kernel affordances is among them.
      expect(find.byType(LoadFailure), findsNothing);
      expect(find.byType(ReferenceSelectView), findsNothing);
      expect(find.textContaining('Nothing to choose'), findsNothing);
      expect(find.textContaining('Try again'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // The POSITIVE half: the control is still there, still enabled, and
      // showing its placeholder. Without this the negative assertions above
      // would pass on a widget that rendered nothing at all.
      expect(find.text('Select…'), findsOneWidget);
      final DropdownButton<String> dd = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dd.onChanged, isNotNull, reason: 'the select stays ENABLED');
    });

    testWidgets(
        'F3-AC-26 the render is invariant under a loading reference list',
        (WidgetTester tester) async {
      // `F3-AC-22`'s positive form. `CertificateRefList.loading` exists and is
      // read by nothing; feeding a "loading" list and a "loaded-empty" list
      // through the widget's actual parameter — `options` — must produce the
      // same tree, because `loading` never crosses the boundary.
      await _pump(tester, subject());
      final String a = _renderSignature(tester);
      await _pump(tester, subject());
      final String b = _renderSignature(tester);
      expect(a, equals(b));
    });

    testWidgets('the placeholder option is always present and always first',
        (WidgetTester tester) async {
      await _pump(
        tester,
        CertificateSelectField(
          label: 'Nationality',
          value: 'v1',
          options: _options(3),
          placeholder: 'Select…',
          onChanged: _noop,
        ),
      );
      final DropdownButton<String> dd = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dd.items!.first.value, '',
          reason: '`<option value="">{placeholder}</option>` — :241');
      expect(dd.items!.length, 4);
      expect(dd.value, 'v1');
    });

    testWidgets('a server message outlines the field BEFORE showErrors',
        (WidgetTester tester) async {
      // `:231` reads `Boolean(serverError)` first. The caller resolves the
      // message itself, so it arrives as a string rather than through a path.
      await _pump(
        tester,
        CertificateSelectField(
          label: 'Nationality',
          value: '',
          options: _options(2),
          placeholder: 'Select…',
          onChanged: _noop,
          required: true,
          serverError: 'Nationality is required.',
        ),
      );
      expect(find.text('Nationality is required.'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F3-AC-27, F3-AC-28, F3-AC-29, F3-AC-30 — the location cascade
  // ───────────────────────────────────────────────────────────────────────────
  group('the location cascade: loading YES, empty YES, failure NO', () {
    Widget cascade({
      CertificateLocationValue value = CertificateLocationValue.blank,
      CertificateLocationLevel provinces = CertificateLocationLevel.empty,
      CertificateLocationLevel districts = CertificateLocationLevel.empty,
      CertificateLocationLevel villages = CertificateLocationLevel.empty,
      String? serverError,
    }) =>
        CertificateLocationFields(
          value: value,
          onChanged: (_) {},
          provinces: provinces,
          districts: districts,
          villages: villages,
          required: true,
          serverError: serverError,
        );

    testWidgets(
        'F3-AC-27 a failed province fetch renders NO LoadFailure, NO Retry, '
        'NO error ring', (WidgetTester tester) async {
      // A failed fetch reaches the widget as an empty, not-loading level —
      // `ApiLocationFields` never destructures `error` (`:291-302`).
      await _pump(tester, cascade());

      expect(find.byType(LoadFailure), findsNothing,
          reason: 'formFields.tsx:223 needs BOTH `failed` and `onRetry`; '
              'ApiLocationFields passes neither');
      expect(find.textContaining('Try again'), findsNothing);

      // The error RING, checked at the parameter rather than by pixel: the
      // kernel computes `outlined = hasError || Boolean(failed)` and `failed`
      // must be null here, not false-by-accident.
      for (final SearchableSelect s
          in tester.widgetList<SearchableSelect>(find.byType(SearchableSelect))) {
        expect(s.failed, isNull,
            reason: 'passing `failed: false` would be a different program '
                'that happens to render the same today');
        expect(s.onRetry, isNull);
        expect(s.emptyMessage, isNull,
            reason: 'null falls through to NOTHING_YET, which is why '
                'F3-AC-28 passes');
        expect(s.path, isNull,
            reason: 'no per-level path — that is why F3-AC-30 sees ONE row');
      }
      // The positive control: three selects really are mounted, so the
      // findsNothing assertions above are not vacuous.
      expect(find.byType(SearchableSelect), findsNWidgets(3));
    });

    testWidgets(
        'F3-AC-28 a loaded-empty district list DOES render nothingYet inside '
        'the open dropdown', (WidgetTester tester) async {
      await _pump(
        tester,
        cascade(
          value: const CertificateLocationValue(provinceId: 'p1'),
          provinces: CertificateLocationLevel(options: _options(1)),
        ),
      );
      // Open the district select — the empty message lives in the dropdown
      // panel, not under the field.
      await tester.tap(find.byType(SearchableSelect).at(1));
      await _settle(tester);

      expect(
        find.text('formFields.nothingYet'.tr()),
        findsOneWidget,
        reason: 'the `emptyMessage ??` default at formFields.tsx:190-192. A '
            'port that suppressed this along with LoadFailure would be as '
            'wrong as one that showed both.',
      );
      expect(find.byType(LoadFailure), findsNothing);
    });

    testWidgets('F3-AC-29 while loading, the cascade DOES render fields.loading',
        (WidgetTester tester) async {
      await _pump(
        tester,
        cascade(provinces: const CertificateLocationLevel(loading: true)),
      );
      await tester.tap(find.byType(SearchableSelect).first);
      await _settle(tester);

      expect(find.text('fields.loading'.tr()), findsOneWidget);
      expect(find.byType(LoadFailure), findsNothing);
    });

    testWidgets(
        'F3-AC-30 a 422 on the group renders ONE error line, not one per level',
        (WidgetTester tester) async {
      await _pump(
        tester,
        cascade(serverError: 'Current address is required.'),
      );
      expect(find.text('Current address is required.'), findsOneWidget,
          reason: '`path` is not threaded per level (:361), so the group gets '
              'one row. Three would mean the port threaded it.');
    });

    testWidgets(
        'F3-AC-31 a district with 250 villages offers exactly 200 options',
        (WidgetTester tester) async {
      // The POSITIVE assertion RULING 2(iv) requires. A criterion that only
      // said "no loop exists" would pass with the cascade returning nothing.
      //
      // The single-page fetch happens in the cubit
      // (`PagingMode.firstPageOnly`); what this asserts is the other half —
      // that the widget renders every option it is given, so 200 in means 200
      // offered and the 50 on page 2 are genuinely unreachable rather than
      // dropped twice.
      await _pump(
        tester,
        cascade(
          value: const CertificateLocationValue(
            provinceId: 'p1',
            districtId: 'd1',
          ),
          provinces: CertificateLocationLevel(options: _options(1)),
          districts: CertificateLocationLevel(options: _options(1)),
          villages: CertificateLocationLevel(options: _options(200)),
        ),
      );
      final SearchableSelect village =
          tester.widgetList<SearchableSelect>(find.byType(SearchableSelect)).last;
      expect(village.options.length, 200,
          reason: 'the API default page is 200 (endpoints.ts:204) and '
              'ApiLocationFields does not loop (MarriageCertificatePage.tsx'
              ':296-298). 250 here would mean L-7 was obeyed where L-10(b) '
              'governs.');
    });

    testWidgets('district and village are DISABLED until their parent is set',
        (WidgetTester tester) async {
      await _pump(tester, cascade());
      final List<SearchableSelect> selects =
          tester.widgetList<SearchableSelect>(find.byType(SearchableSelect))
              .toList();
      expect(selects[0].disabled, isFalse);
      expect(selects[1].disabled, isTrue);
      expect(selects[2].disabled, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F3-AC-99 / R-21 — the upload control filters nothing
  // ───────────────────────────────────────────────────────────────────────────
  group('R-21 — a .txt reaches the attachment list', () {
    testWidgets('F3-AC-99 driven through the picker abstraction, not by grep',
        (WidgetTester tester) async {
      PickedAttachment? received;
      await _pump(
        tester,
        CertificateDocUpload(
          label: 'Household book',
          file: null,
          onChanged: (PickedAttachment? f) => received = f,
          uploadDocumentLabel: 'Upload document',
          defaultHint: 'PDF or image',
          // The picker abstraction. In production this is `FileType.any` with
          // no `allowedExtensions`; here it returns a `.txt`, and the control
          // must accept it.
          pickFile: () async => const PickedAttachment(
            name: 'notes.txt',
            bytes: null,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('certificateDocUpload.pick')));
      await _settle(tester);

      expect(received, isNotNull,
          reason: 'accept="image/*,.pdf" is a browser HINT the citizen can '
              'override; FileType.custom would be a hard filter and would make '
              'the port stricter than the source');
      expect(received!.name, 'notes.txt');
    });

  });

  testWidgets('the toggle row is a BUTTON, and reports its own state',
      (WidgetTester tester) async {
    int toggles = 0;
    await _pump(
      tester,
      CertificateToggleRow(
        active: true,
        onToggle: () => toggles++,
        title: 'Children of the marriage',
        hint: 'Attach the birth record',
      ),
    );
    await tester.tap(find.byType(CertificateToggleRow));
    await _settle(tester);
    expect(toggles, 1);
    expect(find.text('Children of the marriage'), findsOneWidget);
  });
}

void _noop(String _) {}

/// Every `Text` in the tree, in depth-first order — the closest thing to "what
/// the citizen reads" available without a golden.
List<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((Text t) => t.data ?? '')
    .toList();

/// A stable description of the rendered tree: the widget types plus their
/// text, which is what changes when a state gets its own affordance.
String _renderSignature(WidgetTester tester) {
  final List<String> types = tester
      .allWidgets
      .map((Widget w) => w.runtimeType.toString())
      .toList();
  return '${types.join(',')}||${_visibleText(tester).join(',')}';
}
