/// **D-3 — the capability, not the configuration** (B10 § 7.3,
/// `B10-AC-15 … B10-AC-20`).
///
/// The defect: changing the language repaints nothing until the next
/// navigation. Every assertion below is written against the *capability* —
/// "this string now reads its Lao value" — and never against the mechanism
/// that obtains it. An AC that passes with its subject inert is not an AC
/// (FACTORY-RULES' Capability Rule), and this batch exists partly because two
/// shipped ACs (`B2-AC-17`, B9's `specs.md`:962) asserted "no `const` subtree
/// contains a `.tr()`" — a property that neither prevents nor causes D-3 —
/// and passed while the defect stayed open.
///
/// ## Why the brand pair gets its own assertion
///
/// `layout.brand` and `layout.brandSub` **swap** values between locales:
///
/// | key | en | lo |
/// |---|---|---|
/// | `layout.brand` | `LAO CITIZEN CENTER` | `ສູນພົນລະເມືອງລາວ` |
/// | `layout.brandSub` | `ສູນພົນລະເມືອງລາວ` | `LAO CITIZEN CENTER` |
///
/// Both strings are on screen in *both* locales, so `find.text(...)` returns
/// one match either way and a membership assertion is green whether the fix
/// works or not. Only their **order** distinguishes the locales, so the test
/// reads the two `Text` widgets positionally (`B10-AC-16`).
///
/// ## Why "no navigation occurred" is asserted
///
/// The pre-existing behaviour is *"refreshes on the next navigation"*. A test
/// that toggled and then navigated would pass on the defect. `B10-AC-19`
/// pins the router's location either side of the toggle so the repaint is
/// attributable to the toggle alone.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/presentation/shell/language_toggle.dart';
import 'package:lcc_mobile_app/presentation/shell/shell_tabs.dart';

import '../../helpers/app_test_harness.dart';

/// The five bottom-nav labels, in `shellTabs` order.
const List<String> _navEn = <String>[
  'Home',
  'Service',
  'History',
  'Wallet',
  'Account',
];
const List<String> _navLo = <String>[
  'ໜ້າຫຼັກ',
  'ບໍລິການ',
  'ປະຫວັດ',
  'ກະເປົາເງິນ',
  'ບັນຊີ',
];

const String _brandEn = 'LAO CITIZEN CENTER';
const String _brandLo = 'ສູນພົນລະເມືອງລາວ';

const String _greetingEn = 'Good morning';
const String _greetingLo = 'ສະບາຍດີຕອນເຊົ້າ';

const String _searchEn = 'Search services, certificates...';
const String _searchLo = 'ຄົ້ນຫາການບໍລິການ, ໃບຢັ້ງຢືນ...';

String _locationOf(WidgetTester tester) => GoRouter.of(
      tester.element(find.byType(NavigationBar)),
    ).routerDelegate.currentConfiguration.uri.toString();

/// The two brand lines **in tree order** — see the library doc.
List<String> _brandLines(WidgetTester tester) {
  final Finder bar = find.byType(NavigationBar);
  expect(bar, findsOneWidget, reason: 'the shell must be mounted');

  return tester
      .widgetList<Text>(find.byType(Text))
      .map((Text t) => t.data)
      .whereType<String>()
      .where((String s) => s == _brandEn || s == _brandLo)
      .toList();
}

void main() {
  tearDown(resetHarness);

  testWidgets(
      'B10-AC-15/17/19 — toggling en → lo repaints the nav, the greeting and '
      'the search placeholder with no navigation', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    // Baseline: English, on /home.
    final String before = _locationOf(tester);
    for (final String label in _navEn) {
      expect(find.text(label), findsWidgets, reason: '$label should be on screen in en');
    }
    expect(find.text(_greetingEn), findsOneWidget);
    expect(find.text(_searchEn), findsOneWidget);

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    // B10-AC-19 — the repaint is the toggle's, not a navigation's.
    expect(
      _locationOf(tester),
      before,
      reason: 'B10-AC-19: no navigation may occur. Without this the test would '
          'pass on the pre-existing "refreshes on the next navigation" '
          'behaviour, which IS the defect.',
    );

    // B10-AC-15 — all five nav labels.
    for (final String label in _navLo) {
      expect(
        find.text(label),
        findsWidgets,
        reason: 'D-3: the bottom-nav label "$label" did not repaint on the '
            'language toggle.',
      );
    }
    for (final String label in _navEn) {
      expect(
        find.text(label),
        findsNothing,
        reason: 'D-3: the English nav label "$label" is still on screen after '
            'switching to Lao.',
      );
    }

    // B10-AC-17 — greeting + search placeholder.
    expect(find.text(_greetingLo), findsOneWidget,
        reason: 'D-3: home.greeting did not repaint.');
    expect(find.text(_greetingEn), findsNothing);
    expect(find.text(_searchLo), findsOneWidget,
        reason: 'D-3: home.searchPlaceholder did not repaint.');
    expect(find.text(_searchEn), findsNothing);
  });

  testWidgets(
      'B10-AC-16 — layout.brand and layout.brandSub SWAP, asserted positionally',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    expect(
      _brandLines(tester),
      <String>[_brandEn, _brandLo],
      reason: 'in en the top bar reads brand="LAO CITIZEN CENTER" then '
          'brandSub="ສູນພົນລະເມືອງລາວ".',
    );

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    expect(
      _brandLines(tester),
      <String>[_brandLo, _brandEn],
      reason: 'B10-AC-16: the two lines must have SWAPPED. A membership '
          'assertion cannot see this — both strings are present in both '
          'locales and only their order distinguishes them, which is why the '
          'naive test silently passes on the defect.',
    );
  });

  testWidgets('B10-AC-18 — the reverse toggle (lo → en) repaints too',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness, startLocale: const Locale('lo'));

    final String before = _locationOf(tester);
    for (final String label in _navLo) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    expect(_locationOf(tester), before);
    for (final String label in _navEn) {
      expect(
        find.text(label),
        findsWidgets,
        reason: 'D-3, reverse direction: "$label" did not repaint. A fix that '
            'only works one way passes B10-AC-15 alone.',
      );
    }
    expect(find.text(_greetingEn), findsOneWidget);
    expect(find.text(_searchEn), findsOneWidget);
    expect(_brandLines(tester), <String>[_brandEn, _brandLo]);
  });

  testWidgets('the RED side — the pre-fix `tab.labelKey.tr()` shape still goes '
      'stale, over the real shellTabs', (WidgetTester tester) async {
    // Paired with the first test in this file: same five labels, same widget,
    // same toggle. The only difference is `context:`.
    await tester.pumpWidget(wrapWithLocalization(const _BareNavProbe()));
    await tester.pumpAndSettle();

    for (final String label in _navEn) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.byKey(const Key('probe-toggle')));
    await tester.pumpAndSettle();

    for (final String label in _navEn) {
      expect(
        find.text(label),
        findsWidgets,
        reason: 'D-3, reproduced: with a bare `.tr()` the English label '
            '"$label" survives the switch to Lao. This is what the shipped '
            'bottom nav did before B10, and what B10-AC-15 asserts is now '
            'fixed. If THIS test starts failing, `.tr()` has changed '
            'behaviour and the fix above may be redundant — investigate, do '
            'not delete.',
      );
    }
    for (final String label in _navLo) {
      expect(find.text(label), findsNothing);
    }
  });

  group('B10-AC-20 — the mechanism, encoded so the const theory cannot come '
      'back', () {
    // § 6.6.3's refutation, as a regression test. `ssd.md`:775-778 asserts the
    // cause is `const` widget subtrees over `.tr()`; it is not. Both widgets
    // below are `const`. One refreshes and one does not, and the discriminator
    // is `context:`, not `const`.

    testWidgets('a CONST widget calling .tr(context: context) DOES refresh',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(const _ConstProbe(useContext: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.byKey(const Key('probe-toggle')));
      await tester.pumpAndSettle();

      expect(
        find.text('ໜ້າຫຼັກ'),
        findsOneWidget,
        reason: 'const is NOT the discriminator: an element that depends on '
            'the Localizations InheritedWidget is marked dirty directly and '
            'rebuilds regardless of const-canonicalisation.',
      );
    });

    testWidgets('a CONST widget calling bare .tr() does NOT refresh',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(const _ConstProbe(useContext: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.byKey(const Key('probe-toggle')));
      await tester.pumpAndSettle();

      expect(
        find.text('Home'),
        findsOneWidget,
        reason: 'bare .tr() reads Localization.instance — a global singleton — '
            'and registers no InheritedWidget dependency, so nothing below the '
            'unchanged `child` rebuilds. THIS is D-3.',
      );
      expect(find.text('ໜ້າຫຼັກ'), findsNothing);
    });
  });
}

/// The **pre-fix shape of `AppBottomNav`, reproduced**, so the red side of
/// this batch is observable without reverting anything.
///
/// FACTORY-RULES: *"a regression test that has never been red is not
/// evidence."* The straightforward way to satisfy that — revert
/// `app_bottom_nav.dart`, watch the suite fail, put it back — is forbidden in
/// this tree: a previous round of parallel agents mutated a shared `lib/` file
/// to prove a point and the restore ran late while two other agents were
/// editing it. So the *shape* is reproduced here instead, over the real
/// [shellTabs] and the real `NavigationBar`, and the assertion below is that it
/// **stays stale** — which is D-3, observed live, in a fixture this test owns.
///
/// The expression is byte-identical to what shipped before B10:
/// `tab.labelKey.tr()`. The only difference between this widget and today's
/// `AppBottomNav` is the four characters `context:`.
class _BareNavProbe extends StatelessWidget {
  const _BareNavProbe();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(
        body: TextButton(
          key: const Key('probe-toggle'),
          onPressed: () => context.setLocale(const Locale('lo')),
          child: const Text('switch'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: <Widget>[
            for (final ShellTab tab in shellTabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                // ← the pre-B10 line, verbatim
                label: tab.labelKey.tr(),
              ),
          ],
        ),
      ),
    );
  }
}

/// A deliberately `const` subtree under a locale switcher.
///
/// Lives in the test rather than in `lib/`: proving a defect must never mean
/// mutating a shared production file, which this tree has already paid for
/// once.
class _ConstProbe extends StatelessWidget {
  const _ConstProbe({required this.useContext});

  final bool useContext;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: const Key('probe-toggle'),
              onPressed: () => context.setLocale(const Locale('lo')),
              child: const Text('switch'),
            ),
            // Both branches are `const`. Only the argument differs.
            if (useContext)
              const _ConstContextTr()
            else
              const _ConstBareTr(),
          ],
        ),
      ),
    );
  }
}

class _ConstContextTr extends StatelessWidget {
  const _ConstContextTr();

  @override
  Widget build(BuildContext context) => Text('layout.home'.tr(context: context));
}

class _ConstBareTr extends StatelessWidget {
  const _ConstBareTr();

  @override
  Widget build(BuildContext context) => Text('layout.home'.tr());
}
