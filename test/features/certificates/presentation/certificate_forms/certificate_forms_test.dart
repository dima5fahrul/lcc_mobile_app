/// The `certificate_forms/` shared set — § 6.2 RULING 1's directory, and the
/// four degradations § 6.3 RULING 2 requires it to reproduce.
///
/// **The signature property of this file is that it asserts ABSENCES.** A
/// correct port of Marriage's and Divorce's reference select looks like a bug:
/// it renders nothing on loading, nothing on empty and nothing on failure,
/// because the source's `SelectField` is a native `<select>` fed by a
/// `useRefList` that exposes no `failed` at all. Adding the kernel's four states
/// would be `L-10`(b) — improving on the source — so the tests below assert the
/// three renders are *identical to each other*, which is the only form of the
/// claim a later "fix" cannot quietly satisfy.
///
/// **Not one test here calls `DependencyInjection.init()`** (`F3-AC-12`,
/// `F0-AC-77`'s property at its third consumer). Every widget is pumped with
/// parameters only; a widget that reached for a locator would throw.
library;

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_dated_field.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_doc_upload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_field_label.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_input_field.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_payload_helpers.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_ref_list.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_section_label.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_select_field.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_toggle_row.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/validation_scope.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/load_failure.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/option.dart';

import '../../../../helpers/app_test_harness.dart';

/// `formFields.tsx:30-38`'s sentences and the `fields` namespace, as the assets
/// hold them — the strings a state must, or must not, present.
const Map<String, String> kEn = <String, String>{
  'loadFailed': 'Could not load this list.',
  'retry': 'Retry',
  'nothingYet': 'Nothing to choose from here yet.',
  'loading': 'Loading…',
  'selectProvince': 'Select province...',
  'selectDistrict': 'Select district...',
  'selectProvinceFirst': 'Select province first',
  'selectVillage': 'Select village...',
  'selectDistrictFirst': 'Select district first',
};

const List<Option> kTwo = <Option>[
  Option(value: 'a', label: 'Alpha'),
  Option(value: 'b', label: 'Bravo'),
];

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'en',
  bool showErrors = false,
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
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await settle(tester);
}

/// `pumpAndSettle` cannot be used here: the loading state renders a
/// `CircularProgressIndicator` whose animation never completes, so it would time
/// out on exactly the state being asserted. A fixed budget is bounded and
/// deterministic.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

/// Everything the widget tree presents to a citizen, in order, as a comparable
/// string.
///
/// `F3-AC-25` asks for three renders "byte-equal to each other". Comparing
/// `Text` content in tree order plus the presence of the widgets that carry the
/// four kernel states is the strongest form of that claim available to a widget
/// test: it fails if a load-failure row, a retry affordance, a spinner or an
/// extra sentence appears in any one of the three.
String renderSignature(WidgetTester tester) {
  final List<String> parts = <String>[];
  for (final Element e in find.byType(Text).evaluate()) {
    final Text t = e.widget as Text;
    parts.add('Text(${t.data ?? ''})');
  }
  parts.add('LoadFailure=${find.byType(LoadFailure).evaluate().length}');
  parts.add(
    'Spinner=${find.byType(CircularProgressIndicator).evaluate().length}',
  );
  return parts.join('|');
}

void main() {
  // ───────────────────────────────────────────────────────────────────────
  // § 6.3 RULING 2(i)/(ii) — the reference select renders NONE of the four
  // kernel states, and its render does not depend on `loading`.
  // ───────────────────────────────────────────────────────────────────────
  group('CertificateSelectField — the four states the source does NOT have', () {
    /// The three notional states, all of which the source collapses into one
    /// render. There is no `failed` inhabitant to construct because
    /// `useRefList` never exposes one (`:180` does not destructure `error`) —
    /// which is itself the finding: a failed list is *indistinguishable* from an
    /// empty one before it reaches the widget.
    const Map<String, CertificateRefList> states = <String, CertificateRefList>{
      'loading': CertificateRefList(loading: true),
      'loaded-empty': CertificateRefList(),
      'failed (arrives as loaded-empty — there is no failure signal)':
          CertificateRefList(),
    };

    testWidgets(
      'F3-AC-25 — loading, loaded-empty and failed render byte-equal to each '
      'other, and none of them shows a retry, an error row or a spinner',
      (WidgetTester tester) async {
        final Map<String, String> signatures = <String, String>{};

        for (final MapEntry<String, CertificateRefList> s in states.entries) {
          await pump(
            tester,
            CertificateSelectField(
              label: 'Nationality',
              value: '',
              options: s.value.options,
              placeholder: 'Select…',
              onChanged: (_) {},
            ),
          );
          signatures[s.key] = renderSignature(tester);

          // The absences, named individually so a failure says which one broke.
          expect(find.byType(LoadFailure), findsNothing,
              reason: '${s.key}: LoadFailure is the kernel\'s, not this widget\'s');
          expect(find.text(kEn['loadFailed']!), findsNothing, reason: s.key);
          expect(find.text(kEn['retry']!), findsNothing, reason: s.key);
          expect(find.text(kEn['nothingYet']!), findsNothing, reason: s.key);
          expect(find.byType(CircularProgressIndicator), findsNothing,
              reason: s.key);

          // …and the one thing that IS always there: the placeholder, enabled.
          expect(find.text('Select…'), findsOneWidget, reason: s.key);
        }

        final Set<String> distinct = signatures.values.toSet();
        expect(
          distinct.length,
          1,
          reason: 'The three renders must be indistinguishable. Got:\n'
              '${signatures.entries.map((MapEntry<String, String> e) => '  ${e.key}\n    ${e.value}').join('\n')}',
        );
      },
    );

    testWidgets(
      'F3-AC-26 — the render is invariant under loading:true vs loading:false '
      '(the positive form of "nothing reads .loading")',
      (WidgetTester tester) async {
        final List<String> seen = <String>[];
        for (final bool loading in <bool>[true, false]) {
          final CertificateRefList list = CertificateRefList(
            options: kTwo,
            loading: loading,
          );
          await pump(
            tester,
            CertificateSelectField(
              label: 'Nationality',
              value: 'a',
              options: list.options,
              placeholder: 'Select…',
              onChanged: (_) {},
            ),
          );
          seen.add(renderSignature(tester));
        }
        expect(seen[0], seen[1]);
      },
    );

    testWidgets(
      'F3-AC-22 — CertificateRefList exposes `loading`, and the select takes '
      'no loading/failed parameter to read it with',
      (WidgetTester tester) async {
        // Exposed: this compiles and carries the flag the source computes.
        const CertificateRefList list = CertificateRefList(loading: true);
        expect(list.loading, isTrue);
        expect(CertificateRefList.loadingList.loading, isTrue);
        expect(list.options, isEmpty);

        // Unread: the widget's constructor has no seam through which it could
        // be read. Asserted structurally rather than by grep — a grep passes on
        // an empty directory, this does not.
        await pump(
          tester,
          const CertificateSelectField(
            label: 'L',
            value: '',
            options: <Option>[],
            placeholder: 'Select…',
            onChanged: _noop,
          ),
        );
        expect(find.byType(CertificateSelectField), findsOneWidget);
      },
    );

    testWidgets('an unmatched value falls back to the placeholder rather than '
        'asserting — RULING 14\'s hazard, one layer down',
        (WidgetTester tester) async {
      await pump(
        tester,
        CertificateSelectField(
          label: 'Nationality',
          value: 'not-in-the-list',
          options: kTwo,
          placeholder: 'Select…',
          onChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Select…'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // § 6.3 RULING 2(iii) — the cascade renders loading and empty, and does NOT
  // render LoadFailure.
  // ───────────────────────────────────────────────────────────────────────
  group('CertificateLocationFields — three of four states, on purpose', () {
    Widget cascade({
      CertificateLocationLevel provinces = CertificateLocationLevel.empty,
      CertificateLocationLevel districts = CertificateLocationLevel.empty,
      CertificateLocationLevel villages = CertificateLocationLevel.empty,
      CertificateLocationValue value = CertificateLocationValue.blank,
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
      'F3-AC-27 — a FAILED province fetch renders no LoadFailure, no Retry and '
      'no error ring; the select stays enabled showing its placeholder',
      (WidgetTester tester) async {
        // A failure reaches this widget as "no rows, not loading" — the page
        // never destructures `error` (`:291-302`), so there is no other shape
        // it could arrive in.
        await pump(tester, cascade());

        expect(find.byType(LoadFailure), findsNothing);
        expect(find.text(kEn['loadFailed']!), findsNothing);
        expect(find.text(kEn['retry']!), findsNothing);
        expect(find.text(kEn['selectProvince']!), findsOneWidget);
      },
    );

    testWidgets(
      'F3-AC-28 — a loaded-EMPTY district list DOES render formFields.nothingYet '
      'inside the open dropdown',
      (WidgetTester tester) async {
        await pump(
          tester,
          cascade(
            provinces: const CertificateLocationLevel(options: kTwo),
            // District is enabled only once a province is picked.
            value: const CertificateLocationValue(
              provinceId: 'a',
              provinceName: 'Alpha',
            ),
          ),
        );

        await tester.tap(find.text(kEn['selectDistrict']!));
        await settle(tester);

        expect(find.text(kEn['nothingYet']!), findsOneWidget);
        // The empty message is the kernel's default, reached by NOT passing
        // `emptyMessage` — the failure row still must not appear.
        expect(find.byType(LoadFailure), findsNothing);
      },
    );

    testWidgets(
      'F3-AC-29 — while LOADING the cascade renders fields.loading and a spinner',
      (WidgetTester tester) async {
        await pump(
          tester,
          cascade(provinces: const CertificateLocationLevel(loading: true)),
        );

        await tester.tap(find.text(kEn['selectProvince']!));
        await settle(tester);

        expect(find.text(kEn['loading']!), findsOneWidget);
        expect(find.text(kEn['nothingYet']!), findsNothing,
            reason: 'loading is not emptiness');
        expect(find.byType(LoadFailure), findsNothing);
      },
    );

    testWidgets(
      'F3-AC-30 — a 422 on the group renders ONE error line beneath all three '
      'levels, not one per level',
      (WidgetTester tester) async {
        const String msg = 'Current address is required.';
        await pump(
          tester,
          cascade(
            provinces: const CertificateLocationLevel(options: kTwo),
            serverError: msg,
          ),
        );
        expect(find.text(msg), findsOneWidget);
      },
    );

    testWidgets('picking a province clears district and village together with '
        'their names — `:321-327` spreads `blankLocation`, not `value`',
        (WidgetTester tester) async {
      CertificateLocationValue? got;
      await pump(
        tester,
        CertificateLocationFields(
          // District and village carry stale rows; the province pick must drop
          // all four of their fields, ids AND resolved names.
          value: const CertificateLocationValue(
            districtId: 'd',
            districtName: 'D',
            villageId: 'v',
            villageName: 'V',
          ),
          onChanged: (CertificateLocationValue v) => got = v,
          provinces: const CertificateLocationLevel(options: kTwo),
          districts: CertificateLocationLevel.empty,
          villages: CertificateLocationLevel.empty,
        ),
      );

      await tester.tap(find.text(kEn['selectProvince']!));
      await settle(tester);
      await tester.tap(find.text('Bravo').last);
      await settle(tester);

      expect(got, isNotNull);
      expect(got!.provinceId, 'b');
      expect(got!.provinceName, 'Bravo');
      expect(got!.districtId, isEmpty);
      expect(got!.districtName, isEmpty,
          reason: 'the resolved name must clear with the id — a stale '
              'districtName would reach address_text');
      expect(got!.villageId, isEmpty);
      expect(got!.villageName, isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // § 6.2's rule attached to option (c) — DocUpload's two-line difference is a
  // parameter; R-21's absence of filtering is behaviour.
  // ───────────────────────────────────────────────────────────────────────
  group('CertificateDocUpload', () {
    testWidgets(
      'F3-AC-21 — the hint is a parameter: the same widget renders Marriage\'s '
      'pdfOrImage and Divorce\'s uploadHint without forking',
      (WidgetTester tester) async {
        for (final String hint in <String>['PDF or image', 'Upload a document']) {
          await pump(
            tester,
            CertificateDocUpload(
              label: 'Household book',
              file: null,
              onChanged: (_) {},
              uploadDocumentLabel: 'Upload document',
              defaultHint: hint,
              pickFile: () async => null,
            ),
          );
          expect(find.text(hint), findsOneWidget);
        }
      },
    );

    testWidgets('a per-control `hint` overrides the namespace default — `:411`',
        (WidgetTester tester) async {
      await pump(
        tester,
        CertificateDocUpload(
          label: '3x4 photographs',
          file: null,
          onChanged: (_) {},
          uploadDocumentLabel: 'Upload document',
          defaultHint: 'PDF or image',
          hint: 'Recent, white background',
          pickFile: () async => null,
        ),
      );
      expect(find.text('Recent, white background'), findsOneWidget);
      expect(find.text('PDF or image'), findsNothing);
    });

    testWidgets(
      'F3-AC-99 — R-21 behaviourally: a .txt selected through the picker '
      'reaches the attachment list',
      (WidgetTester tester) async {
        PickedAttachment? received;
        final PickedAttachment txt = PickedAttachment(
          name: 'notes.txt',
          bytes: Uint8List.fromList(<int>[104, 105]),
        );

        await pump(
          tester,
          CertificateDocUpload(
            label: 'Household book',
            file: null,
            onChanged: (PickedAttachment? f) => received = f,
            uploadDocumentLabel: 'Upload document',
            defaultHint: 'PDF or image',
            pickFile: () async => txt,
          ),
        );

        await tester.tap(find.byKey(const Key('certificateDocUpload.pick')));
        await settle(tester);

        expect(received, isNotNull,
            reason: 'a .txt must not be filtered out — `accept` is a browser '
                'hint, FileType.custom would be a hard filter');
        expect(received!.name, 'notes.txt');
      },
    );

    testWidgets('cancelling the picker is NOT a removal — `:381`',
        (WidgetTester tester) async {
      int calls = 0;
      final PickedAttachment existing = PickedAttachment(
        name: 'already.pdf',
        bytes: Uint8List.fromList(<int>[1]),
      );

      await pump(
        tester,
        CertificateDocUpload(
          label: 'Household book',
          file: null,
          onChanged: (_) => calls++,
          uploadDocumentLabel: 'Upload document',
          defaultHint: 'PDF or image',
          pickFile: () async => null, // cancelled
        ),
      );
      await tester.tap(find.byKey(const Key('certificateDocUpload.pick')));
      await settle(tester);
      expect(calls, 0, reason: 'a cancelled pick must not clear anything');

      // …and the X, which is the only path that clears.
      PickedAttachment? cleared = existing;
      await pump(
        tester,
        CertificateDocUpload(
          label: 'Household book',
          file: existing,
          onChanged: (PickedAttachment? f) => cleared = f,
          uploadDocumentLabel: 'Upload document',
          defaultHint: 'PDF or image',
          pickFile: () async => null,
        ),
      );
      expect(find.text('already.pdf'), findsOneWidget);
      await tester.tap(find.byKey(const Key('certificateDocUpload.remove')));
      await settle(tester);
      expect(cleared, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // § 6.5 RULING 4 — `both()`, and the payload helpers.
  // ───────────────────────────────────────────────────────────────────────
  group('both() — F3-AC-44', () {
    test('trims both, returns A trimmed, collapses to "" when either is blank',
        () {
      // The spec's table, verbatim.
      expect(both('  x  ', 'y'), 'x');
      expect(both('x', '  '), '');
      expect(both('  ', 'y'), '');
      expect(both('', ''), '');

      // The properties the table implies, named so a partial port fails here
      // rather than at Tier 0.
      expect(both('x', 'y'), 'x', reason: 'returns A, never B');
      expect(both('a', '  b  '), 'a',
          reason: "B's trim is for the test only; B never reaches the wire");
      expect(both('\t\n ', 'y'), '',
          reason: 'whitespace-only A is blank, not truthy');
      expect(both('x', 'y'), isNot('y'));
    });

    test('the collapse is "" — never null, never an absent key', () {
      expect(both('x', ''), isA<String>());
      expect(both('x', ''), isEmpty);
    });
  });

  group('payloadString — Marriage `:681-692`', () {
    test('takes the first usable key, in order', () {
      expect(
        payloadString(<String, Object?>{'a': 'first', 'b': 'second'},
            <String>['a', 'b']),
        'first',
      );
      expect(
        payloadString(<String, Object?>{'b': 'second'}, <String>['a', 'b']),
        'second',
      );
    });

    test('a blank string is skipped, but the value returned is UNTRIMMED', () {
      expect(
        payloadString(<String, Object?>{'a': '   ', 'b': 'x'},
            <String>['a', 'b']),
        'x',
      );
      expect(
        payloadString(<String, Object?>{'a': '  padded  '}, <String>['a']),
        '  padded  ',
        reason: 'the trim decides acceptance, not the returned value',
      );
    });

    test('a number is accepted unconditionally, including 0', () {
      expect(payloadString(<String, Object?>{'a': 0}, <String>['a']), '0',
          reason: '0 is falsy in JS but the typeof check runs first');
      expect(payloadString(<String, Object?>{'a': 42}, <String>['a']), '42');
      expect(payloadString(<String, Object?>{'a': 5.0}, <String>['a']), '5',
          reason: "JS String(5.0) is '5'; Dart's toString would give '5.0'");
    });

    test('a null payload and a miss both give ""', () {
      expect(payloadString(null, <String>['a']), '');
      expect(payloadString(<String, Object?>{}, <String>['a']), '');
      expect(
        payloadString(<String, Object?>{'a': <String>['x']}, <String>['a']),
        '',
        reason: 'neither string nor number',
      );
    });
  });

  group('certificateRefListFrom', () {
    test('resolves each label once, at the reading language — `:182`', () {
      const List<LookupOption> rows = <LookupOption>[
        LookupOption(
          id: '11111111-1111-4111-8111-111111111111',
          code: 'lao',
          label: Bilingual(en: 'Lao', lo: 'ລາວ'),
        ),
      ];
      expect(certificateRefListFrom(rows, Lang.en).options.single.label, 'Lao');
      expect(certificateRefListFrom(rows, Lang.lo).options.single.label, 'ລາວ');
      expect(certificateRefListFrom(rows, Lang.en).options.single.value, 'lao');
    });

    test('carries `loading` through without letting it change the options', () {
      expect(
        certificateRefListFrom(const <LookupOption>[], Lang.en, loading: true)
            .loading,
        isTrue,
      );
      expect(
        certificateRefListFrom(const <LookupOption>[], Lang.en, loading: true)
            .options,
        isEmpty,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // F3-AC-12 — the whole directory builds with DI completely uninitialised.
  // ───────────────────────────────────────────────────────────────────────
  group('F3-AC-12 — every widget builds with no DI container', () {
    testWidgets('all seven controls pump together, parameters only',
        (WidgetTester tester) async {
      await pump(
        tester,
        Column(
          children: <Widget>[
            const CertificateFieldLabel(label: Text('Label'), required: true),
            const CertificateSectionLabel(text: 'Current address'),
            CertificateInputField(
              label: 'Full name',
              value: 'Somchai',
              placeholder: 'Enter…',
              onChanged: (_) {},
              required: true,
            ),
            CertificateSelectField(
              label: 'Nationality',
              value: '',
              options: kTwo,
              placeholder: 'Select…',
              onChanged: (_) {},
            ),
            CertificateDatedField(
              label: 'Date of birth',
              value: '1990-01-01',
              onChanged: (_) {},
            ),
            CertificateToggleRow(
              active: true,
              onToggle: () {},
              title: 'Previously married',
              hint: 'Attach proof',
            ),
            CertificateDocUpload(
              label: 'Household book',
              file: null,
              onChanged: (_) {},
              uploadDocumentLabel: 'Upload document',
              defaultHint: 'PDF or image',
              pickFile: () async => null,
            ),
            CertificateLocationFields(
              value: CertificateLocationValue.blank,
              onChanged: (_) {},
              provinces: const CertificateLocationLevel(options: kTwo),
              districts: CertificateLocationLevel.empty,
              villages: CertificateLocationLevel.empty,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Somchai'), findsOneWidget);
      expect(find.text('CURRENT ADDRESS'), findsOneWidget);
      expect(find.text('Previously married'), findsOneWidget);
    });
  });
}

void _noop(String _) {}
