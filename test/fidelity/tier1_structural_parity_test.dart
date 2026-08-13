/// **Tier 1 — structural parity. B2-AC-8, and P-2's proof.**
///
/// § 6.5.1 rules Tier 1 *"APPLICABLE, blocking, 100 %. This is B2's principal
/// gate. Per page per locale: every element the web presents (headings, labels,
/// card copy, chips, button text, empty/loading/error strings) exists in the
/// Flutter page with the same text in both locales."*
///
/// ## No browser in the loop
///
/// § 6.5.3's ruling, and the reason for it: the capture rig fails in three
/// documented, *silent* ways, and a blocking gate that has to stand it up on
/// every run is a gate that will be skipped. So the expectation is a static,
/// versioned oracle derived once from `62f8a529`
/// (`docs/fidelity-baseline/2026-08-13/oracle/tier1/`) and this test is a plain
/// `flutter test` that reads it.
///
/// ## Nine views, not one
///
/// Tier 1 over a page's happy path would say nothing about the state § 6.6
/// makes mandatory and B2-AC-16 tests separately. The oracle carries every
/// state of both views — `categories.{loading,data,empty,error}` and
/// `list.{loading,data,error,empty.category,empty.search}` — so the error
/// sentences and the empty-state copy are gated at the same 100 % as the card
/// titles. That is why `noCategories`, `errorHint` and `browseOther` cannot be
/// silently dropped or paraphrased.
///
/// ## Both locales, always
///
/// § 6.5.6: the baseline measures Lao **taller** than English on this route
/// (1491 vs 1404), there is no canonical page height, and every comparison
/// pairs against the locale-matching artefact. Here that means each view runs
/// twice and the Lao run is not a smoke test — it is where a missing `lo` key
/// or an English string leaking through a fallback shows up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service_category.dart';
import 'package:lcc_mobile_app/features/service/presentation/bloc/service_bloc.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';

import '../helpers/service_test_helper.dart';
import 'oracle.dart';
import 'text_dump.dart';

/// The category the list-view oracles drill into. Must match
/// `derive_oracles.py`'s `LIST_CATEGORY`.
const String kListCategory = 'civil';

/// The query the empty-search oracle uses. Must match `EMPTY_QUERY`.
const String kEmptyQuery = 'zzzz';

const List<Locale> kLocales = <Locale>[Locale('en'), Locale('lo')];

/// Compares [actual] against the oracle's [view], node for node, in order.
void expectParity(
  Map<String, dynamic> oracle,
  String view,
  List<DumpNode> actual, {
  required String locale,
}) {
  final List<OracleNode> expected = tier1View(oracle, view);
  final List<String> problems = <String>[];

  for (int i = 0; i < expected.length; i++) {
    final OracleNode want = expected[i];

    if (i >= actual.length) {
      problems.add(
        '[$i] MISSING "${want.text}" (${want.role}, from ${want.source})',
      );
      continue;
    }

    final DumpNode got = actual[i];

    if (got.text != want.text) {
      problems.add(
        '[$i] TEXT  web "${want.text}" vs flutter "${got.text}"'
        '  <- ${want.source}',
      );
      continue;
    }
    if (!rolesAreComparable(want.role, got.role)) {
      problems.add(
        '[$i] ROLE  "${want.text}" is ${want.role} on the web but '
        '${got.role} here  <- ${want.source}',
      );
      continue;
    }
    if (want.role == 'heading' && !got.heading) {
      problems.add(
        '[$i] HEADING "${want.text}" is an <h${want.level}> on the web and '
        'carries no Semantics(header: true) here  <- ${want.source}',
      );
    }
  }

  for (int i = expected.length; i < actual.length; i++) {
    problems.add('[$i] EXTRA "${actual[i].text}" (${actual[i].role}) — the '
        'web presents nothing here');
  }

  expect(
    problems,
    isEmpty,
    reason: 'Tier 1 is blocking at 100 % (B2-AC-8). Route /service, locale '
        '$locale, view `$view`.\n'
        '  web     (${expected.length}): '
        '${expected.map((OracleNode n) => n.text).toList()}\n'
        '  flutter (${actual.length}): '
        '${actual.map((DumpNode n) => n.text).toList()}\n'
        'Problems:\n  ${problems.join('\n  ')}',
  );
}

List<DumpNode> _dump(WidgetTester tester) =>
    dumpText(tester, find.byType(ServicePage));

void main() {
  group('the oracle is the versioned one (B2-AC-29)', () {
    test('both locales exist and are pinned to the baseline commit', () {
      for (final Locale locale in kLocales) {
        final Map<String, dynamic> oracle =
            loadTier1('service', locale.languageCode);
        final Map<String, dynamic> provenance =
            oracle['provenance'] as Map<String, dynamic>;

        expect(oracle['route'], '/service');
        expect(oracle['locale'], locale.languageCode);
        expect(provenance['web_commit'], kWebCommit,
            reason: '§ 8.3: an oracle derived from a different web commit is '
                'a re-baseline, and B2a may not perform one.');
        expect(provenance['derived_by'], 'test/fidelity/derive_oracles.py');
      }
    });

    test('the api snapshot behind it is the measured catalogue', () {
      // § 6.4 C-1: 43 services, all active. If the recording ever shrinks to 6
      // — the number the static seed table holds — the oracle would agree with
      // a page that renders 6, which is the exact Tier 1 failure C-1 names.
      expect(recordedServices(), hasLength(43));
      expect(recordedCategories(), hasLength(8));
      expect(recordedServices().every((Service s) => s.active), isTrue);
      expect(recordedServicesIn(kListCategory), hasLength(13));
    });
  });

  for (final Locale locale in kLocales) {
    final String code = locale.languageCode;

    group('Tier 1 — /service — $code', () {
      late Map<String, dynamic> oracle;

      setUp(() => oracle = loadTier1('service', code));

      /// Builds the repository double and its BLoC **inside the test body**.
      ///
      /// Not in `setUp`, and that is not style. `app_test_harness.dart`'s
      /// hazard 3: a `Bloc` constructed in `setUp` lives outside
      /// `testWidgets`' `FakeAsync` zone, so no amount of pumping ever flushes
      /// its microtasks — the event is accepted and never handled, the state
      /// sits on `loading` for the whole test, and every assertion fails while
      /// the framework reports no error. This cost a debugging round; the
      /// closure is the fix and this comment is the reason it exists.
      ({FakeServiceRepository repository, ServiceBloc bloc}) build() {
        final FakeServiceRepository repository = FakeServiceRepository();
        final ServiceBloc bloc = serviceBlocOver(repository);
        addTearDown(bloc.close);
        return (repository: repository, bloc: bloc);
      }

      testWidgets('categories.loading', (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        // Hold the answer so the skeleton is observable at all — see
        // `FakeServiceRepository.latency`.
        repository.latency = kStubLatency;
        bloc.add(const ServiceStarted());
        // One frame only: the futures have not completed, so this IS the
        // loading state. Settling here would time out on the skeleton pulse.
        await pumpServicePage(tester, bloc, locale: locale);

        expectParity(oracle, 'categories.loading', _dump(tester),
            locale: code);

        // Drain the held answer. `FakeServiceRepository.latency` is a real
        // FakeAsync timer, and `flutter_test` fails a test that leaves one
        // outstanding — a failure whose message is a stack trace about
        // "Pending timers", not about fidelity, and which then wedges the rest
        // of the file.
        await tester.pump(kStubLatency);
      });

      testWidgets('categories.data — all 8, server order (C-1, B2-AC-35)',
          (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        expectParity(oracle, 'categories.data', _dump(tester), locale: code);
      });

      testWidgets('categories.empty — stubbed, because staging never is',
          (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        repository.succeed(categories: const <ServiceCategory>[]);
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        expectParity(oracle, 'categories.empty', _dump(tester), locale: code);
      });

      testWidgets('categories.error — with its retry',
          (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        repository.failCategories();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        expectParity(oracle, 'categories.error', _dump(tester), locale: code);
      });

      testWidgets('list.loading', (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        repository.latency = kStubLatency;
        bloc.add(const ServiceCategorySelected(kListCategory));
        // Two frames, not one: `Bloc` delivers an event through its own stream,
        // so the first pump flushes the delivery and the second renders the
        // `listStatus: loading` the handler emitted. One pump lands between
        // them and would assert against the category grid.
        await tester.pump();
        await tester.pump();

        expectParity(oracle, 'list.loading', _dump(tester), locale: code);

        // See the note in `categories.loading`.
        await tester.pump(kStubLatency);
      });

      testWidgets('list.data — 13 cards in `civil`',
          (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        repository.nextServices = recordedServicesIn(kListCategory);
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        bloc.add(const ServiceCategorySelected(kListCategory));
        await settleCatalogue(tester);

        expectParity(oracle, 'list.data', _dump(tester), locale: code);
      });

      testWidgets('list.error — with its retry', (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        repository.failServices();
        bloc.add(const ServiceCategorySelected(kListCategory));
        await settleCatalogue(tester);

        expectParity(oracle, 'list.error', _dump(tester), locale: code);
      });

      testWidgets('list.empty.category — offers a way back out',
          (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        repository.nextServices = const <Service>[];
        bloc.add(const ServiceCategorySelected(kListCategory));
        await settleCatalogue(tester);

        expectParity(oracle, 'list.empty.category', _dump(tester),
            locale: code);
      });

      testWidgets('list.empty.search — echoes the query, offers no way back',
          (WidgetTester tester) async {
        final (:FakeServiceRepository repository, :ServiceBloc bloc) = build();
        bloc.add(const ServiceStarted());
        await pumpServicePage(tester, bloc, locale: locale);
        await settleCatalogue(tester);

        repository.nextServices = const <Service>[];
        await tester.enterText(find.byType(TextField), kEmptyQuery);
        await settleCatalogue(tester);

        expectParity(oracle, 'list.empty.search', _dump(tester), locale: code);
      });
    });
  }
}
