/// The kernel's controls, per control per state, both locales —
/// `F0-AC-25`, `F0-AC-26`, `F0-AC-27` (the consumer-shaped half), `F0-AC-77`.
///
/// **Not one of these tests calls `DependencyInjection.init()`, and that is the
/// point** (`F0-AC-77`, § 6.3.8 item 3). Every widget below is pumped with
/// parameters only. A widget that needed a locator would throw here, so this
/// file is worth more than any grep for `sl<` — a grep proves the source text
/// has no locator read, this proves the widget does not need one.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/field_error.dart';
import 'package:lcc_mobile_app/presentation/forms/validation/validation_scope.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/date_field.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/field_label.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/load_failure.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/location_fields_view.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/option.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/reference_field_state.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/reference_select_view.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/searchable_select.dart';

import '../../helpers/app_test_harness.dart';

/// `formFields.tsx:30-38`'s three sentences, in both locales, as the assets
/// hold them. Asserted equal to the source constants by
/// `field_sentences_test.dart`; used here to name what a state must and must
/// not present.
const Map<String, Map<String, String>> kSentence =
    <String, Map<String, String>>{
  'en': <String, String>{
    'loadFailed': 'Could not load this list.',
    'retry': 'Retry',
    'nothingYet': 'Nothing to choose from here yet.',
    'loading': 'Loading…',
    'noResults': 'No results',
  },
  'lo': <String, String>{
    'loadFailed': 'ບໍ່ສາມາດໂຫຼດລາຍການນີ້ໄດ້.',
    'retry': 'ລອງໃໝ່',
    'nothingYet': 'ຍັງບໍ່ມີໃຫ້ເລືອກເທື່ອ.',
    'loading': 'ກຳລັງໂຫຼດ…',
    'noResults': 'ບໍ່ພົບຜົນການຄົ້ນຫາ',
  },
};

const List<Option> kThree = <Option>[
  Option(value: 'a', label: 'Alpha', sub: 'ອາລະຟາ'),
  Option(value: 'b', label: 'Bravo', sub: 'ບຣາໂວ'),
  Option(value: 'c', label: 'Charlie', sub: 'Charlie'),
];

Future<void> pump(
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
  await settle(tester);
}

/// `pumpAndSettle` cannot be used anywhere in this file.
///
/// The loading state renders a `CircularProgressIndicator`, whose animation
/// never completes, so `pumpAndSettle` times out rather than settling — and it
/// would time out on the LOADING tests specifically, i.e. on exactly the state
/// `F0-AC-25` exists to assert. Pumping a fixed budget instead is bounded and
/// deterministic: 400 ms clears the 150 ms chevron rotation, the overlay insert
/// and one layout pass, with room to spare.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  for (final String locale in <String>['en', 'lo']) {
    final Map<String, String> s = kSentence[locale]!;

    group('F0-AC-25 — SearchableSelect, four control states [$locale]', () {
      testWidgets('LOADING — the spinner sentence, inside the open dropdown',
          (WidgetTester tester) async {
        await pump(
          tester,
          SearchableSelect(
            label: const Text('Province'),
            value: '',
            options: const <Option>[],
            placeholder: 'Select…',
            loading: true,
            onChanged: (_) {},
          ),
          locale: locale,
        );
        await tester.tap(find.text('Select…'));
        await settle(tester);

        expect(find.text(s['loading']!), findsOneWidget);
        expect(find.text(s['nothingYet']!), findsNothing,
            reason: 'a loading list is never also empty');
      });

      testWidgets('DATA — the rows render, with their secondary line',
          (WidgetTester tester) async {
        await pump(
          tester,
          SearchableSelect(
            label: const Text('Province'),
            value: 'b',
            options: kThree,
            placeholder: 'Select…',
            onChanged: (_) {},
          ),
          locale: locale,
        );
        // The button shows the SELECTED label, not the placeholder.
        expect(find.text('Bravo'), findsOneWidget);
        expect(find.text('Select…'), findsNothing);

        await tester.tap(find.text('Bravo'));
        await settle(tester);

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('ອາລະຟາ'), findsOneWidget);
        // `formFields.tsx:207` — the sub is hidden when it repeats the label.
        expect(find.text('Charlie'), findsOneWidget);
      });

      testWidgets('EMPTY (stubbed) — NOTHING_YET inside the dropdown',
          (WidgetTester tester) async {
        await pump(
          tester,
          SearchableSelect(
            label: const Text('Province'),
            value: '',
            options: const <Option>[],
            placeholder: 'Select…',
            onChanged: (_) {},
          ),
          locale: locale,
        );
        await tester.tap(find.text('Select…'));
        await settle(tester);

        expect(find.text(s['nothingYet']!), findsOneWidget);
      });

      testWidgets('ERROR-WITH-RETRY — LOAD_FAILED and RETRY, and no empty '
          'dropdown standing in for it (L-8)', (WidgetTester tester) async {
        int retries = 0;
        await pump(
          tester,
          SearchableSelect(
            label: const Text('Province'),
            value: '',
            options: const <Option>[],
            placeholder: 'Select…',
            failed: true,
            onRetry: () => retries++,
            onChanged: (_) {},
          ),
          locale: locale,
        );

        expect(find.text(s['loadFailed']!), findsOneWidget);
        expect(find.text(s['retry']!), findsOneWidget);
        expect(find.byType(LoadFailure), findsOneWidget);

        // …and the affordance really retries.
        await tester.tap(find.text(s['retry']!));
        await settle(tester);
        expect(retries, 1);
      });
    });

    group('F0-AC-25 — ReferenceSelectView, four control states [$locale]', () {
      // `F0-AC-110` — the helper takes a VALUE as well as a state. v1.5 fixed
      // it at `''` here, which is why a two-condition defect (value non-empty
      // AND options missing it) was unreachable from a matrix that named four
      // states: § 6.3.9's "a one-condition matrix cannot reach it however many
      // scenarios it names". The parameter is `required` rather than defaulted
      // so the hardcode cannot come back by omission.
      ReferenceSelectView view(
        ReferenceFieldState state, {
        required String value,
        ValueChanged<String>? onChanged,
      }) =>
          ReferenceSelectView(
            label: const Text('Nationality'),
            source: state,
            value: value,
            placeholder: 'Select…',
            onChanged: onChanged ?? (_) {},
          );

      testWidgets('LOADING — the loading sentence in the placeholder slot',
          (WidgetTester tester) async {
        await pump(
          tester,
          view(const ReferenceFieldState(loading: true), value: ''),
          locale: locale,
        );
        expect(find.text(s['loading']!), findsOneWidget);
      });

      testWidgets('DATA', (WidgetTester tester) async {
        await pump(
          tester,
          view(const ReferenceFieldState(options: kThree), value: ''),
          locale: locale,
        );
        expect(find.text('Select…'), findsOneWidget);
      });

      testWidgets('EMPTY — NOTHING_YET as a row UNDER the control, not inside '
          'a dropdown', (WidgetTester tester) async {
        await pump(
          tester,
          view(const ReferenceFieldState(), value: ''),
          locale: locale,
        );
        // `formFields.tsx:330-331`.
        expect(find.text(s['nothingYet']!), findsOneWidget);
        expect(find.byType(LoadFailure), findsNothing);
      });

      testWidgets('ERROR — LoadFailure, and NOT the empty row: a failed list '
          'is never also empty (formFields.tsx:301)',
          (WidgetTester tester) async {
        await pump(
          tester,
          view(ReferenceFieldState(failed: true, retry: () {}), value: ''),
          locale: locale,
        );
        expect(find.text(s['loadFailed']!), findsOneWidget);
        expect(find.text(s['retry']!), findsOneWidget);
        expect(find.text(s['nothingYet']!), findsNothing);
      });

      // ---- F0-AC-110 — the CROSS-PRODUCT, not a list of named scenarios ----
      //
      // Three values × the same four states. The four tests above are the
      // `value: ''` row of this matrix and keep their string assertions; these
      // cells assert only that nothing throws, which is the whole point:
      // `flutter analyze` cannot see a runtime assert, and `String` is `String`
      // whatever it holds (§ 6.3.9, "the test rule this exposes").
      final Map<String, ReferenceFieldState> states =
          <String, ReferenceFieldState>{
        'LOADING': const ReferenceFieldState(loading: true),
        'DATA': const ReferenceFieldState(options: kThree),
        'EMPTY': const ReferenceFieldState(),
        'ERROR-WITH-RETRY': ReferenceFieldState(failed: true, retry: () {}),
      };

      // `'a'` is carried by `kThree`; `'zzz'` is carried by nothing. In the
      // three states whose list is empty, both are unmatched — which is the
      // production shape (`resident_form_cubit.dart:604-607` sets `nationality`
      // from the ID card before the list returns).
      const Map<String, String> values = <String, String>{
        "'' (the blank row)": '',
        "'a' — a code the options carry": 'a',
        "'zzz' — a code they do not": 'zzz',
      };

      for (final MapEntry<String, ReferenceFieldState> st in states.entries) {
        for (final MapEntry<String, String> v in values.entries) {
          testWidgets('F0-AC-110 — ${st.key} × ${v.key} does not throw',
              (WidgetTester tester) async {
            await pump(tester, view(st.value, value: v.value), locale: locale);
            expect(tester.takeException(), isNull,
                reason: 'L-10: a framework assertion that turns the web\'s '
                    'benign degradation into a build-time throw is a MAJOR '
                    'fidelity defect, not a framework quirk');
          });
        }
      }
    });

    group('F0-AC-111 — an unmatched value renders what the SOURCE renders, '
        'and does not move the held value [$locale]', () {
      // Measured, not inferred (L-10 corollary (a)). `$WEB/package.json:82-83`
      // pins react-dom to 18.3.1 and
      // `$WEB/node_modules/react-dom/cjs/react-dom.development.js:2133-2155`
      // is `updateOptions`' single-select branch: on no match it selects the
      // first NON-DISABLED option (`:2148`, `:2154`) — `formFields.tsx:315`'s
      // blank row, never disabled. So the web shows the PLACEHOLDER, or the
      // loading sentence, and mutates the DOM directly, firing no `change`.
      testWidgets('not loading — the PLACEHOLDER, never the raw code, and '
          'onChanged is not invoked', (WidgetTester tester) async {
        int calls = 0;
        await pump(
          tester,
          ReferenceSelectView(
            label: const Text('Nationality'),
            source: const ReferenceFieldState(),
            value: 'lao',
            placeholder: 'Select…',
            onChanged: (_) => calls++,
          ),
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Select…'), findsOneWidget);
        // The rejected alternative — a synthetic item labelled with the raw
        // code — would render `lao` here, making the port MORE informative
        // than the source (L-10 corollary (b), § 6.3.9 "the two alternatives").
        expect(find.text('lao'), findsNothing);
        // A fix that cleared the field would green the clause above while
        // corrupting the Tier 0 payload. React fires no `change`; nor do we.
        expect(calls, 0,
            reason: 'the held value is the caller\'s and must not move');
      });

      testWidgets('loading — the LOADING SENTENCE in the same slot, still no '
          'callback', (WidgetTester tester) async {
        int calls = 0;
        await pump(
          tester,
          ReferenceSelectView(
            label: const Text('Nationality'),
            source: const ReferenceFieldState(loading: true),
            value: 'lao',
            placeholder: 'Select…',
            onChanged: (_) => calls++,
          ),
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        expect(find.text(s['loading']!), findsOneWidget);
        expect(find.text('Select…'), findsNothing,
            reason: '`:315` — the loading sentence REPLACES the placeholder '
                'in the blank row, it does not sit beside it');
        expect(calls, 0);
      });

      testWidgets('…and a value the list DOES carry still resolves to ITSELF — '
          'the resolution is not a blanket clear', (WidgetTester tester) async {
        // Capability Rule. Every other assertion in this group is satisfied by
        // a `_selectableValue` that returns `''` unconditionally: an inert
        // subject renders the placeholder, throws nothing and calls nothing,
        // which is what the unmatched cells check for. This is the cell that
        // separates the ruling's predicate from that stub — and it is asserted
        // on the resolved `DropdownButton.value` because both the blank row and
        // every option row are BUILT by the `IndexedStack`, so a text finder
        // cannot tell which one is selected.
        await pump(
          tester,
          ReferenceSelectView(
            label: const Text('Nationality'),
            source: const ReferenceFieldState(options: kThree),
            value: 'a',
            placeholder: 'Select…',
            onChanged: (_) {},
          ),
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          ).value,
          'a',
          reason: 'exactly one item carries it, so it is selectable and the '
              'citizen sees their own selection, not the placeholder',
        );
      });

      testWidgets('…while a value it does NOT carry resolves to the blank row',
          (WidgetTester tester) async {
        await pump(
          tester,
          ReferenceSelectView(
            label: const Text('Nationality'),
            source: const ReferenceFieldState(options: kThree),
            value: 'zzz',
            placeholder: 'Select…',
            onChanged: (_) {},
          ),
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          ).value,
          '',
          reason: '`formFields.tsx:315` as resolved by `updateOptions` — the '
              'first non-disabled option, which is the blank row',
        );
      });

      testWidgets('a DUPLICATE code in the list does not throw either — the '
          'assert\'s other arm', (WidgetTester tester) async {
        // `dropdown.dart:1028` fails on *zero or 2 or more* matches. A `value:`
        // resolution written as `isNotEmpty` would close only the zero arm;
        // `length == 1` mirrors the assert's own predicate and closes both.
        // React tolerates it too — `updateOptions` returns on the first match.
        await pump(
          tester,
          ReferenceSelectView(
            label: const Text('Nationality'),
            source: const ReferenceFieldState(
              options: <Option>[
                Option(value: 'dup', label: 'First'),
                Option(value: 'dup', label: 'Second'),
              ],
            ),
            value: 'dup',
            placeholder: 'Select…',
            onChanged: (_) {},
          ),
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('F0-AC-112 — PATH (b): the retry affordance is REACHABLE with a '
        'value set [$locale]', () {
      // The more serious half. A failed reference load leaves `options` empty
      // for the life of the page, so before RULING 14 every step-2 render with
      // a detected nationality threw in `build` — and the throw is at `:125`,
      // ABOVE the failure row at `:158-159` in the same `Column`, so the
      // citizen got neither a retry nor an empty dropdown. L-8 was not merely
      // violated, it was unreachable.
      testWidgets('LoadFailure renders, LOAD_FAILED and RETRY are both '
          'present, and tapping Retry invokes the callback',
          (WidgetTester tester) async {
        int retries = 0;
        await pump(
          tester,
          ReferenceSelectView(
            label: const Text('Nationality'),
            source: ReferenceFieldState(
              failed: true,
              retry: () => retries++,
            ),
            value: 'lao',
            placeholder: 'Select…',
            onChanged: (_) {},
          ),
          locale: locale,
        );

        expect(tester.takeException(), isNull,
            reason: 'the throw preceded the retry row; that is path (b)');
        expect(find.byType(LoadFailure), findsOneWidget);
        expect(find.text(s['loadFailed']!), findsOneWidget);
        expect(find.text(s['retry']!), findsOneWidget);

        await tester.tap(find.text(s['retry']!));
        await settle(tester);
        expect(retries, 1,
            reason: 'L-8 asserted at the state where it was unreachable');
      });
    });
  }

  group('F0-AC-26 / F0-AC-27 — the weaker surface is reachable BY OMISSION', () {
    testWidgets('with failed/onRetry/emptyMessage all null, an EMPTY select '
        'renders NOTHING_YET and no failure row', (WidgetTester tester) async {
      // § 6.3.4 row 4 — Marriage's `ApiLocationFields`. The subtle one: it
      // shows the kernel widget's own empty message while showing NO failure
      // row. A single "weaker surface" boolean gets this wrong in both
      // directions.
      await pump(
        tester,
        SearchableSelect(
          label: const Text('Province'),
          value: '',
          options: const <Option>[],
          placeholder: 'Select…',
          // failed:      omitted
          // onRetry:     omitted
          // emptyMessage: omitted
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Select…'));
      await settle(tester);

      // Expectation 1 — the empty message IS reached.
      expect(find.text(kSentence['en']!['nothingYet']!), findsOneWidget);
      // Expectation 2 — and no failure surface exists.
      expect(find.byType(LoadFailure), findsNothing);
      expect(find.text(kSentence['en']!['loadFailed']!), findsNothing);
      expect(find.text(kSentence['en']!['retry']!), findsNothing);
    });

    testWidgets('…and it stays that way when the list has actually FAILED, '
        'because the caller models no failure', (WidgetTester tester) async {
      // The whole of RULING 2 in one assertion: same widget, same empty
      // options, caller omits three parameters — and the strong surface is
      // unreachable. No fork, no variant flag, no second copy.
      await pump(
        tester,
        SearchableSelect(
          label: const Text('Province'),
          value: '',
          options: const <Option>[],
          placeholder: 'Select…',
          onChanged: (_) {},
        ),
      );
      expect(find.byType(LoadFailure), findsNothing);
    });

    testWidgets('`failed` WITHOUT `onRetry` still renders no failure row — '
        'formFields.tsx:223 needs BOTH', (WidgetTester tester) async {
      await pump(
        tester,
        SearchableSelect(
          label: const Text('Province'),
          value: '',
          options: const <Option>[],
          placeholder: 'Select…',
          failed: true,
          // onRetry omitted — the `&&` in `failed && onRetry ? …`
          onChanged: (_) {},
        ),
      );
      expect(find.byType(LoadFailure), findsNothing);
    });

    testWidgets('an explicit emptyMessage overrides NOTHING_YET',
        (WidgetTester tester) async {
      await pump(
        tester,
        SearchableSelect(
          label: const Text('Province'),
          value: '',
          options: const <Option>[],
          placeholder: 'Select…',
          emptyMessage: 'Pick a province first',
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Select…'));
      await settle(tester);

      expect(find.text('Pick a province first'), findsOneWidget);
      expect(find.text(kSentence['en']!['nothingYet']!), findsNothing);
    });
  });

  group('SearchableSelect — the three behaviours that look incidental', () {
    testWidgets('filtering matches label AND sub, and picking reports the '
        'value', (WidgetTester tester) async {
      String? picked;
      await pump(
        tester,
        SearchableSelect(
          label: const Text('X'),
          value: '',
          options: kThree,
          placeholder: 'Select…',
          onChanged: (String v) => picked = v,
        ),
      );
      await tester.tap(find.text('Select…'));
      await settle(tester);

      // A query that only matches the SUB (`formFields.tsx:143`).
      await tester.enterText(find.byType(TextField), 'ບຣາໂວ');
      await settle(tester);
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);

      await tester.tap(find.text('Bravo'));
      await settle(tester);
      expect(picked, 'b');
    });

    testWidgets('no match shows noResults, not NOTHING_YET',
        (WidgetTester tester) async {
      await pump(
        tester,
        SearchableSelect(
          label: const Text('X'),
          value: '',
          options: kThree,
          placeholder: 'Select…',
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Select…'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await settle(tester);

      expect(find.text(kSentence['en']!['noResults']!), findsOneWidget);
      expect(find.text(kSentence['en']!['nothingYet']!), findsNothing);
    });

    testWidgets('the list is capped at 100 and the refine hint appears at '
        'exactly 100', (WidgetTester tester) async {
      final List<Option> many = <Option>[
        for (int i = 0; i < 150; i++)
          Option(value: '$i', label: 'Row $i'),
      ];
      await pump(
        tester,
        SearchableSelect(
          label: const Text('X'),
          value: '',
          options: many,
          placeholder: 'Select…',
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Select…'));
      await settle(tester);

      expect(find.text('Refine your search to see more…'), findsOneWidget);
      expect(kSearchableSelectLimit, 100);
    });

    testWidgets('a disabled select does not open', (WidgetTester tester) async {
      await pump(
        tester,
        SearchableSelect(
          label: const Text('District'),
          value: '',
          options: kThree,
          placeholder: 'Select province first',
          disabled: true,
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Select province first'));
      await settle(tester);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('LocationFieldsView — L-5, L-6 and the stale-row rule', () {
    testWidgets('L-6 — dependants are disabled with a placeholder saying why',
        (WidgetTester tester) async {
      await pump(
        tester,
        LocationFieldsView(
          province: '',
          district: '',
          village: '',
          onChanged: (_) {},
        ),
      );
      expect(find.text('Select province first'), findsOneWidget);
      expect(find.text('Select district first'), findsOneWidget);
    });

    testWidgets('L-5 — a province change clears district AND village',
        (WidgetTester tester) async {
      LocationPatch? patch;
      await pump(
        tester,
        LocationFieldsView(
          province: '',
          district: '',
          village: '',
          provinces: const LocationLevel(rows: kThree),
          onChanged: (LocationPatch p) => patch = p,
        ),
      );
      await tester.tap(find.text('Select province...'));
      await settle(tester);
      await tester.tap(find.text('Alpha'));
      await settle(tester);

      expect(patch,
          const LocationPatch(province: 'a', district: '', village: ''));
    });

    testWidgets('L-5 — a district change clears village and LEAVES province '
        'alone', (WidgetTester tester) async {
      LocationPatch? patch;
      await pump(
        tester,
        LocationFieldsView(
          province: 'p',
          district: '',
          village: '',
          districts: const LocationLevel(rows: kThree),
          onChanged: (LocationPatch p) => patch = p,
        ),
      );
      await tester.tap(find.text('Select district...'));
      await settle(tester);
      await tester.tap(find.text('Bravo'));
      await settle(tester);

      expect(patch, const LocationPatch(district: 'b', village: ''));
      expect(patch!.province, isNull,
          reason: '"not mentioned" and "cleared" are different, and the patch '
              'has to carry both');
    });

    test('the stale-row rule is a pure selector, and it withholds', () {
      // `formFields.tsx:420-427`. The behaviour a port drops, asserted without
      // a widget so it survives any restructuring of the one above it.
      expect(
        visibleRows(parentId: 'p-1', busy: false, rows: kThree),
        kThree,
      );
      expect(
        visibleRows(parentId: 'p-1', busy: true, rows: kThree),
        isEmpty,
        reason: 'while a new province`s districts are in flight, the PREVIOUS '
            'province`s rows are still in `data` — showing them offers choices '
            'that do not belong to the province just picked',
      );
      expect(
        visibleRows(parentId: '', busy: false, rows: kThree),
        isEmpty,
      );
    });

    testWidgets('and the widget really applies it', (WidgetTester tester) async {
      await pump(
        tester,
        LocationFieldsView(
          province: 'p',
          district: '',
          village: '',
          districts: const LocationLevel(rows: kThree, busy: true),
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Select district...'));
      await settle(tester);

      // Busy ⇒ no stale rows, and the loading sentence instead.
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Loading…'), findsOneWidget);
    });
  });

  group('F0-AC-77 — every kernel widget builds with the DI container '
      'COMPLETELY UNINITIALISED', () {
    // `DependencyInjection.init()` is never called in this file. Each widget
    // below is pumped with parameters only; one that needed the locator throws
    // and the test fails.
    final Map<String, Widget> subjects = <String, Widget>{
      'FieldLabel': const FieldLabel(label: Text('L'), required: true),
      'DateField': DateField(
        label: const Text('DOB'),
        value: '2026-08-14',
        onChanged: (_) {},
      ),
      'SearchableSelect': SearchableSelect(
        label: const Text('P'),
        value: '',
        options: kThree,
        placeholder: 'Select…',
        onChanged: (_) {},
      ),
      'ReferenceSelectView': ReferenceSelectView(
        label: const Text('N'),
        source: const ReferenceFieldState(options: kThree),
        value: '',
        placeholder: 'Select…',
        onChanged: (_) {},
      ),
      'LocationFieldsView': LocationFieldsView(
        province: '',
        district: '',
        village: '',
        onChanged: (_) {},
      ),
      'LoadFailure': LoadFailure(onRetry: () {}),
      'FieldErrorText': const FieldErrorText(show: true),

      // ---- F0-AC-113 — a second entry per value-resolving widget, with the
      // value ABSENT from its list and the container still uninitialised.
      //
      // Two of these three are expected green on the unmodified files:
      // `searchable_select.dart:168-170` resolves with `.where(...).firstOrNull`
      // and falls through to `selected?.label ?? widget.placeholder` (`:220`),
      // and `LocationFieldsView` renders through it (`:190`, `:211`, `:232`).
      // That soundness was MEASURED, not built (§ 6.3.9 scope correction) — the
      // entries exist so a future edit cannot quietly remove it.
      'SearchableSelect (value absent from its list)': SearchableSelect(
        label: const Text('P'),
        value: 'zzz',
        options: kThree,
        placeholder: 'Select…',
        onChanged: (_) {},
      ),
      'ReferenceSelectView (value absent from its list)': ReferenceSelectView(
        label: const Text('N'),
        source: const ReferenceFieldState(options: kThree),
        value: 'zzz',
        placeholder: 'Select…',
        onChanged: (_) {},
      ),
      'LocationFieldsView (values absent from their lists)': LocationFieldsView(
        province: 'zzz-p',
        district: 'zzz-d',
        village: 'zzz-v',
        provinces: const LocationLevel(rows: kThree),
        onChanged: (_) {},
      ),
    };

    for (final MapEntry<String, Widget> e in subjects.entries) {
      testWidgets('${e.key} renders with no container', (WidgetTester tester) async {
        await pump(tester, e.value);
        expect(tester.takeException(), isNull);
      });
    }

    test('…and the count is the seven fetching-adjacent widgets plus the '
        'three unmatched-value entries of F0-AC-113', () {
      expect(subjects, hasLength(10));
    });
  });

  group('referenceFieldStateFrom — the pure half of useReferenceOptions', () {
    const List<LookupOption> rows = <LookupOption>[
      LookupOption(
        id: '1',
        code: 'lao',
        label: Bilingual(en: 'Lao', lo: 'ລາວ'),
      ),
      LookupOption(
        id: '2',
        code: 'tha',
        label: Bilingual(en: 'Thai', lo: 'ໄທ'),
      ),
    ];

    test('en: label is English, sub is Lao', () {
      final ReferenceFieldState s =
          referenceFieldStateFrom(rows, lang: Lang.en);
      expect(s.options.first.value, 'lao');
      expect(s.options.first.label, 'Lao');
      expect(s.options.first.sub, 'ລາວ');
    });

    test('lo: label is Lao, sub is English — the sides swap', () {
      final ReferenceFieldState s =
          referenceFieldStateFrom(rows, lang: Lang.lo);
      expect(s.options.first.label, 'ລາວ');
      expect(s.options.first.sub, 'Lao');
    });

    test('labelOf resolves a known code and FALLS BACK to the raw code', () {
      final ReferenceFieldState s =
          referenceFieldStateFrom(rows, lang: Lang.en);
      expect(s.labelOf('tha'), 'Thai');
      expect(s.labelOf('unknown-code'), 'unknown-code',
          reason: 'formFields.tsx:270 — `?? code`. A review screen reading a '
              'value back before the list loads prints the code, not a blank');
    });

    test('an empty list still answers labelOf with the code', () {
      final ReferenceFieldState s =
          referenceFieldStateFrom(const <LookupOption>[], lang: Lang.en);
      expect(s.labelOf('lao'), 'lao');
    });

    test('server order is preserved — the mapper re-sorts nothing', () {
      final ReferenceFieldState s =
          referenceFieldStateFrom(rows.reversed.toList(), lang: Lang.en);
      expect(s.options.map((Option o) => o.value).toList(),
          <String>['tha', 'lao']);
    });
  });

  group('LocationIds — the resolved value type (formFields.tsx:364-371)', () {
    // Added because F0-AC-96's lcov sweep caught this symbol DECLARED AND
    // NEVER EXERCISED: `location_fields_view.dart:54-85`, 12 executable lines,
    // all zero hits. It had no consumer anywhere in lib/ or test/ — exactly the
    // "23 empty stubs pass it" shape F0-AC-21's note describes, surviving
    // inside a batch whose other 22 exports were tested.
    //
    // What makes it load-bearing rather than decorative: F1 diffs a location
    // group's resolved value to decide whether a dependent level must clear
    // (F0-AC-57's cascade). That diff is `==`. With the operator removed the
    // class falls back to identity, every rebuild compares unequal, and the
    // cascade clears on every frame. So value equality IS the behaviour.

    const LocationIds full = LocationIds(
      provinceId: 'p-1',
      districtId: 'd-1',
      villageId: 'v-1',
      provinceName: 'Vientiane',
      districtName: 'Chanthabuly',
      villageName: 'Ban Phonsay',
    );

    test('every field defaults to the empty string, not null', () {
      // `formFields.tsx:364-371` types all six as a bare `string`, so the
      // resting value is "" and a payload built from it carries "" — never
      // "null". The submission contract depends on that (F0-AC-19).
      const LocationIds empty = LocationIds();
      expect(empty.provinceId, '');
      expect(empty.districtId, '');
      expect(empty.villageId, '');
      expect(empty.provinceName, '');
      expect(empty.districtName, '');
      expect(empty.villageName, '');
      expect(empty, const LocationIds());
    });

    test('two distinct instances with equal fields are equal', () {
      // Distinct instances, not the same const canonicalised twice: the
      // interpolation defeats const folding so this is a real == call.
      final LocationIds copy = LocationIds(
        provinceId: 'p-${1}',
        districtId: 'd-${1}',
        villageId: 'v-${1}',
        provinceName: 'Vientia${'ne'}',
        districtName: 'Chanthabu${'ly'}',
        villageName: 'Ban Phon${'say'}',
      );
      expect(identical(full, copy), isFalse);
      expect(copy, full);
      expect(copy.hashCode, full.hashCode);
    });

    test('ALL SIX fields participate — one at a time', () {
      // A `==` that forgot a field would still pass a single equal/unequal
      // pair. Six mutations, one per field, is what pins that down — and the
      // three *_name fields are the ones an implementer drops, since the API
      // only wants the ids.
      final List<LocationIds> mutants = <LocationIds>[
        const LocationIds(
            provinceId: 'X',
            districtId: 'd-1',
            villageId: 'v-1',
            provinceName: 'Vientiane',
            districtName: 'Chanthabuly',
            villageName: 'Ban Phonsay'),
        const LocationIds(
            provinceId: 'p-1',
            districtId: 'X',
            villageId: 'v-1',
            provinceName: 'Vientiane',
            districtName: 'Chanthabuly',
            villageName: 'Ban Phonsay'),
        const LocationIds(
            provinceId: 'p-1',
            districtId: 'd-1',
            villageId: 'X',
            provinceName: 'Vientiane',
            districtName: 'Chanthabuly',
            villageName: 'Ban Phonsay'),
        const LocationIds(
            provinceId: 'p-1',
            districtId: 'd-1',
            villageId: 'v-1',
            provinceName: 'X',
            districtName: 'Chanthabuly',
            villageName: 'Ban Phonsay'),
        const LocationIds(
            provinceId: 'p-1',
            districtId: 'd-1',
            villageId: 'v-1',
            provinceName: 'Vientiane',
            districtName: 'X',
            villageName: 'Ban Phonsay'),
        const LocationIds(
            provinceId: 'p-1',
            districtId: 'd-1',
            villageId: 'v-1',
            provinceName: 'Vientiane',
            districtName: 'Chanthabuly',
            villageName: 'X'),
      ];

      expect(mutants, hasLength(6));
      for (int i = 0; i < mutants.length; i++) {
        expect(mutants[i], isNot(full),
            reason: 'field $i does not participate in ==; a location change '
                'at that level would compare equal and the cascade would not '
                'clear');
      }
      // and they are all distinct from each other, so `hashCode` is not a
      // constant that happens to agree
      expect(mutants.toSet(), hasLength(6));
    });

    test('the ids and the names are independent — the API half can match '
        'while the display half does not', () {
      // The measured reason both halves exist (formFields.tsx:362-363): the
      // ids are what the API wants, the names are what a review screen prints
      // back. Collapsing equality onto the ids alone would let a stale name
      // survive a re-resolution.
      const LocationIds sameIdsOtherNames = LocationIds(
        provinceId: 'p-1',
        districtId: 'd-1',
        villageId: 'v-1',
        provinceName: 'ນະຄອນຫຼວງວຽງຈັນ',
        districtName: 'ຈັນທະບູລີ',
        villageName: 'ບ້ານໂພນສະຫວ່າງ',
      );
      expect(sameIdsOtherNames.provinceId, full.provinceId);
      expect(sameIdsOtherNames, isNot(full),
          reason: 'the same place in the other locale is not the same value');
    });
  });
}
