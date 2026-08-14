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
      ReferenceSelectView view(ReferenceFieldState state) => ReferenceSelectView(
            label: const Text('Nationality'),
            source: state,
            value: '',
            placeholder: 'Select…',
            onChanged: (_) {},
          );

      testWidgets('LOADING — the loading sentence in the placeholder slot',
          (WidgetTester tester) async {
        await pump(
          tester,
          view(const ReferenceFieldState(loading: true)),
          locale: locale,
        );
        expect(find.text(s['loading']!), findsOneWidget);
      });

      testWidgets('DATA', (WidgetTester tester) async {
        await pump(
          tester,
          view(const ReferenceFieldState(options: kThree)),
          locale: locale,
        );
        expect(find.text('Select…'), findsOneWidget);
      });

      testWidgets('EMPTY — NOTHING_YET as a row UNDER the control, not inside '
          'a dropdown', (WidgetTester tester) async {
        await pump(
          tester,
          view(const ReferenceFieldState()),
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
          view(ReferenceFieldState(failed: true, retry: () {})),
          locale: locale,
        );
        expect(find.text(s['loadFailed']!), findsOneWidget);
        expect(find.text(s['retry']!), findsOneWidget);
        expect(find.text(s['nothingYet']!), findsNothing);
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
    };

    for (final MapEntry<String, Widget> e in subjects.entries) {
      testWidgets('${e.key} renders with no container', (WidgetTester tester) async {
        await pump(tester, e.value);
        expect(tester.takeException(), isNull);
      });
    }

    test('…and the count is the seven fetching-adjacent widgets', () {
      expect(subjects, hasLength(7));
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
