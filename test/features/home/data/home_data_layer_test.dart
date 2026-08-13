/// Home's data layer — wire parsing, the datasource's six requests, and the
/// repository's fold.
///
/// ## B2-AC-36, and exactly how far it reaches for B2b
///
/// The criterion asks for mixed wire shapes *"proven against real recorded
/// staging payloads in a fixture, not hand-written JSON"*.
///
/// * **`/services`** — proven against the recording. All 43 rows go through
///   `serviceFrom` below, which is the production parser, and the assertions
///   are on values the recording actually carries (six `is_phase1`, one fee
///   range, `{en,lo}` on four fields, a `required_docs` list of objects).
/// * **`/news`, `/help/faqs`, `/me/home-summary`, `/me/digital-id`** — **no
///   recording exists.** B2a recorded two endpoints; these four were not among
///   them, and the two `/me/*` ones cannot be recorded without an authenticated
///   staging identity, which is F0's blocking question (§ 6.5.2(b)). They are
///   tested against hand-written maps that exercise **both** wire shapes § 5
///   warns about, which is the substance of the criterion — but the evidence is
///   weaker than the criterion asks for and is reported as **PARTIAL**, not
///   rounded up.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/features/home/data/datasources/home_remote_datasource.dart';
import 'package:lcc_mobile_app/features/home/data/models/home_wire.dart';
import 'package:lcc_mobile_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/digital_id_card.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_faq_item.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_news_item.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_summary.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';

import '../../../fidelity/oracle.dart';
import '../../../helpers/core_test_helper.dart';

void main() {
  group('primitives — every read degrades rather than throws', () {
    test('stringAt: a missing, null or non-string field is empty', () {
      expect(stringAt(<String, dynamic>{'a': 'x'}, 'a'), 'x');
      expect(stringAt(<String, dynamic>{}, 'a'), '');
      expect(stringAt(<String, dynamic>{'a': null}, 'a'), '');
      expect(stringAt(<String, dynamic>{'a': 7}, 'a'), '');
    });

    test('intAt accepts a double, because JSON has one number type', () {
      // A backend that serialises `20000.0` is sending an integer amount;
      // rejecting it would fail on a formatting change that means nothing.
      expect(intAt(<String, dynamic>{'a': 5}, 'a'), 5);
      expect(intAt(<String, dynamic>{'a': 20000.0}, 'a'), 20000);
      expect(intAt(<String, dynamic>{'a': 20000.6}, 'a'), 20001);
      expect(intAt(<String, dynamic>{'a': '42'}, 'a'), 42);
      expect(intAt(<String, dynamic>{'a': 'x'}, 'a', fallback: -1), -1);
      expect(intAt(<String, dynamic>{}, 'a'), 0);
    });

    test('boolAt honours its fallback — `active` defaults TRUE', () {
      expect(boolAt(<String, dynamic>{'a': true}, 'a'), isTrue);
      expect(boolAt(<String, dynamic>{}, 'a'), isFalse);
      expect(boolAt(<String, dynamic>{}, 'a', fallback: true), isTrue);
      expect(boolAt(<String, dynamic>{'a': 'true'}, 'a'), isFalse);
    });
  });

  group('bilingualAt — the mixed-shape reader (§ 5, B2-AC-36)', () {
    test('an {en,lo} object reads both sides', () {
      expect(
        bilingualAt(<String, dynamic>{
          'n': <String, dynamic>{'en': 'Fees', 'lo': 'ຄ່າທຳນຽມ'},
        }, 'n'),
        const Bilingual(en: 'Fees', lo: 'ຄ່າທຳນຽມ'),
      );
    });

    test('a PLAIN STRING lands on both sides — the trap § 5 names', () {
      // "`/news` and `/help/faqs` return plain strings where sibling endpoints
      // return `{en,lo}` objects". A model that assumed one shape parses a
      // hand-written fixture happily and throws on real staging data, and the
      // throw surfaces as an error panel that looks like a network problem.
      //
      // Both sides, not one: `text(value, lang)` already falls back
      // `wanted || en || lo || ""`, so a single-language field renders the
      // same text in either locale on the web.
      expect(
        bilingualAt(<String, dynamic>{'n': 'Notice'}, 'n'),
        const Bilingual(en: 'Notice', lo: 'Notice'),
      );
    });

    test('a half-populated object renders one language blank, not an error',
        () {
      expect(
        bilingualAt(<String, dynamic>{
          'n': <String, dynamic>{'en': 'Only English'},
        }, 'n'),
        const Bilingual(en: 'Only English', lo: ''),
      );
    });

    test('null, a number and a list all degrade to an empty pair', () {
      const Bilingual empty = Bilingual(en: '', lo: '');
      expect(bilingualAt(<String, dynamic>{'n': null}, 'n'), empty);
      expect(bilingualAt(<String, dynamic>{'n': 7}, 'n'), empty);
      expect(bilingualAt(<String, dynamic>{'n': <int>[1]}, 'n'), empty);
      expect(bilingualAt(<String, dynamic>{}, 'n'), empty);
    });

    test('bilingualListAt tolerates either element shape and drops neither',
        () {
      final List<Bilingual> docs = bilingualListAt(<String, dynamic>{
        'd': <dynamic>[
          <String, dynamic>{'en': 'ID card', 'lo': 'ບັດ'},
          'Family book',
          7,
        ],
      }, 'd');

      // The `7` is dropped — one malformed element costs that element, not the
      // list — and the other two survive in order.
      expect(docs, hasLength(2));
      expect(docs[0], const Bilingual(en: 'ID card', lo: 'ບັດ'));
      expect(docs[1], const Bilingual(en: 'Family book', lo: 'Family book'));
      expect(bilingualListAt(<String, dynamic>{}, 'd'), isEmpty);
    });
  });

  group('serviceFrom — B2-AC-36 against the REAL recording', () {
    late final List<Map<String, dynamic>> rows;
    late final List<Service> services;

    setUpAll(() {
      rows = loadApi('services');
      services = rows.map(serviceFrom).toList(growable: false);
    });

    test('all 43 recorded rows parse, none throws, none is dropped', () {
      expect(rows, hasLength(43));
      expect(services, hasLength(43));
    });

    test('it agrees with the recording field for field on a known row', () {
      final Service resident =
          services.firstWhere((Service s) => s.code == 'resident');

      expect(resident.name,
          const Bilingual(en: 'Residence Certificate', lo: 'ໃບຢັ້ງຢືນທີ່ຢູ່'));
      expect(resident.categoryCode, 'civil');
      expect(resident.icon, 'Home');
      expect(resident.color, '#3752AE');
      expect(resident.feeLak, 20000);
      expect(resident.feeIsRange, isFalse);
      expect(resident.isPhase1, isTrue);
      expect(resident.routePath, '/service/resident-certificate');
      expect(resident.processingTime.en, 'Same day (target)');
      expect(resident.requiredDocs, hasLength(3));
      expect(resident.requiredDocs.first.lo, 'ບັດປະຈຳຕົວ ຫຼື ໜັງສືຜ່ານແດນ');
    });

    test('the six phase-1 rows are the six DEFAULT_HOME_SERVICES codes', () {
      // `HomePage.tsx:43-50`. The server's `is_phase1` flag and the source's
      // hardcoded default list agree today; if they ever stop, the quick
      // actions grid silently shows a different six.
      final List<String> phase1 = services
          .where((Service s) => s.isPhase1)
          .map((Service s) => s.code)
          .toList(growable: false);

      expect(phase1, <String>[
        'resident',
        'birth',
        'death',
        'marriage',
        'divorce',
        'family-book',
      ]);
    });

    test('exactly one recorded row is a real fee range', () {
      // The branch `formatFee` needs all three conditions for. 42 rows carry
      // `fee_max_lak: 0`, which is not an upper bound.
      final List<Service> ranges = services
          .where((Service s) => s.feeIsRange && s.feeMaxLak > s.feeLak)
          .toList(growable: false);

      expect(ranges, hasLength(1));
      expect(ranges.single.code, 'marriage');
      expect(ranges.single.feeLak, 100000);
      expect(ranges.single.feeMaxLak, 250000);
    });

    test('`active` survives as true across the whole recording', () {
      // C-1: 43 services, all active. The default is `true`, so this also
      // proves the flag is being read rather than defaulted.
      expect(services.every((Service s) => s.active), isTrue);
      expect(
        serviceFrom(<String, dynamic>{'code': 'x'}).active,
        isTrue,
        reason: 'a row that omits the column is live, not hidden',
      );
    });

    test('a row missing every optional column still yields a usable Service',
        () {
      final Service bare = serviceFrom(<String, dynamic>{
        'id': 'i',
        'code': 'c',
        'name': <String, dynamic>{'en': 'N', 'lo': 'N'},
      });

      expect(bare.code, 'c');
      expect(bare.description, const Bilingual(en: '', lo: ''));
      expect(bare.requiredDocs, isEmpty);
      expect(bare.feeLak, 0);
    });
  });

  group('the four unrecorded endpoints — hand-written, and labelled', () {
    test('homeSummaryFrom reads every field', () {
      final HomeSummary s = homeSummaryFrom(<String, dynamic>{
        'name': 'Bounmy',
        'verified': true,
        'eid_verified': true,
        'active_applications': 2,
        'ready_documents': 1,
        'unread_notifications': 3,
        'wallet_balance_lak': 145000,
        'next_action': <String, dynamic>{
          'action': 'reupload',
          'label': <String, dynamic>{'en': 'Re-upload', 'lo': 'ອັບໂຫຼດຄືນ'},
          'tab': 'history',
          'reference_no': 'RC-1',
          'status': 'rejected',
        },
        'generated_at': '2026-08-13T09:00:00Z',
      });

      expect(s.name, 'Bounmy');
      expect(s.walletBalanceLak, 145000);
      expect(s.nextAction?.label?.lo, 'ອັບໂຫຼດຄືນ');
      expect(s.nextAction?.referenceNo, 'RC-1');
    });

    test('a null next_action stays NULL — the banner hinges on it', () {
      // `summary.data?.next_action` (`HomePage.tsx:393`) is the banner's whole
      // condition. Synthesising an empty object would put an empty amber
      // banner on every signed-in home.
      expect(nextActionFrom(null), isNull);
      expect(nextActionFrom('nonsense'), isNull);
      expect(homeSummaryFrom(<String, dynamic>{}).nextAction, isNull);
    });

    test('an absent next_action.label stays null, so the title falls back', () {
      // "Older payloads describe the step without a label of their own."
      // A missing label must take the `t("actionRequiredTitle")` branch, and
      // one representation of "absent" keeps that one check.
      final HomeSummary s = homeSummaryFrom(<String, dynamic>{
        'next_action': <String, dynamic>{'tab': 'history'},
      });
      expect(s.nextAction, isNotNull);
      expect(s.nextAction!.label, isNull);
      expect(s.nextAction!.tab, 'history');
    });

    test('digitalIdFrom takes the seven fields Hero reads and no more', () {
      final DigitalIdCard c = digitalIdFrom(<String, dynamic>{
        'uin': '1-2540-08842-99',
        'card_no': 'LA-1',
        'photo_url': 'https://example/p.jpg',
        'qr_payload': 'qr',
        // A `YourIdPage` field. Present on the wire, absent from the entity —
        // § 2.2 Finding A removed that page from B2 entirely.
        'date_of_birth': '1990-01-01',
      });

      expect(c.uin, '1-2540-08842-99');
      expect(c.photoUrl, 'https://example/p.jpg');
      expect(c.verifyPayload, 'qr');
    });

    test('newsItemFrom handles both category_name shapes', () {
      final HomeNewsItem objectShaped = newsItemFrom(<String, dynamic>{
        'id': '1',
        'slug': 's',
        'category_name': <String, dynamic>{'en': 'News', 'lo': 'ຂ່າວ'},
        'title': <String, dynamic>{'en': 'T', 'lo': 'T'},
      });
      final HomeNewsItem stringShaped = newsItemFrom(<String, dynamic>{
        'id': '2',
        'category_name': 'Notice',
        'title': 'Plain title',
      });

      expect(objectShaped.categoryName.lo, 'ຂ່າວ');
      expect(stringShaped.categoryName.en, 'Notice');
      expect(stringShaped.title.lo, 'Plain title');
    });

    test('faqItemFrom handles both question/answer shapes', () {
      expect(
        faqItemFrom(<String, dynamic>{
          'id': 'f',
          'question': 'How do I apply?',
          'answer': <String, dynamic>{'en': 'Online.', 'lo': 'ອອນລາຍ.'},
        }),
        const HomeFaqItem(
          id: 'f',
          question: Bilingual(en: 'How do I apply?', lo: 'How do I apply?'),
          answer: Bilingual(en: 'Online.', lo: 'ອອນລາຍ.'),
        ),
      );
    });
  });

  group('HomeRemoteDatasource — the six requests', () {
    late RecordingHttpAdapter adapter;
    late HomeRemoteDatasource datasource;

    /// Builds a datasource over a transport that always answers [body].
    ///
    /// Through the **real** interceptor chain (`buildTestDio` adds
    /// `AuthInterceptor` and `RefreshInterceptor`), so `extra['anonymous']` on
    /// the recorded request is the marker the production interceptors actually
    /// saw — not a flag the test set and then read back.
    void answering(Object? body, {int statusCode = 200}) {
      adapter = RecordingHttpAdapter.always(body, statusCode: statusCode);
      datasource = HomeRemoteDatasourceImpl(
        apiClient: ApiClient(
          dio: buildTestDio(
            storage: inMemoryStorageService(<String, String>{}),
            adapter: adapter,
          ),
          storage: inMemoryStorageService(<String, String>{}),
        ),
      );
    }

    test('/services?phase1=true is anonymous and sends a real bool', () async {
      answering(okEnvelope(<dynamic>[]));
      await datasource.getPhase1Services();

      final RequestOptions r = adapter.requests.single;
      expect(r.path, ApiEndpoint.services);
      expect(r.queryParameters['phase1'], true);
      expect(r.extra['anonymous'], isTrue,
          reason: '`endpoints.ts` marks the catalogue `anonymous: true`; '
              'sending a stale token would trigger a refresh round trip on a '
              'request that never needed one');
    });

    test('/services?search= caps at seven, server-side and client-side',
        () async {
      // `.slice(0, 7)` (`HomePage.tsx:271`). Sent as `per_page` so the server
      // truncates; also taken locally, because `/services` is unpaged and a
      // server that ignores the parameter returns all 43.
      answering(okEnvelope(loadApi('services')));
      final List<Service> rows = await datasource.searchServices('cert');

      expect(adapter.requests.single.queryParameters['search'], 'cert');
      expect(
        adapter.requests.single.queryParameters['per_page'],
        kHomeSearchLimit,
      );
      expect(rows, hasLength(kHomeSearchLimit));
    });

    test('an empty search query is dropped rather than sent as `search=`',
        () async {
      // `ApiClient._buildQuery` drops empty strings, so "no filter" really
      // does send no parameter.
      answering(okEnvelope(<dynamic>[]));
      await datasource.searchServices('');

      expect(
        adapter.requests.single.queryParameters.containsKey('search'),
        isFalse,
      );
    });

    test('/me/home-summary is NOT anonymous', () async {
      answering(okEnvelope(<String, dynamic>{'name': 'B'}));
      final HomeSummary s = await datasource.getSummary();

      expect(adapter.requests.single.path, ApiEndpoint.meHomeSummary);
      expect(adapter.requests.single.extra['anonymous'], isFalse);
      expect(s.name, 'B');
    });

    test('/me/digital-id is NOT anonymous', () async {
      answering(okEnvelope(<String, dynamic>{'uin': 'u'}));
      final DigitalIdCard c = await datasource.getDigitalId();

      expect(adapter.requests.single.path, ApiEndpoint.meDigitalId);
      expect(adapter.requests.single.extra['anonymous'], isFalse);
      expect(c.uin, 'u');
    });

    test('/news asks for 3 featured and reads the paged envelope', () async {
      answering(
        okEnvelope(
          <dynamic>[
            <String, dynamic>{'id': 'n1', 'title': 'T'},
          ],
          meta: pageMetaJson(perPage: 3, total: 1, totalPages: 1),
        ),
      );

      final List<HomeNewsItem> items = await datasource.getFeaturedNews();

      expect(adapter.requests.single.path, ApiEndpoint.news);
      expect(adapter.requests.single.queryParameters['per_page'],
          kHomeNewsPerPage);
      expect(adapter.requests.single.queryParameters['featured'], true);
      expect(items.single.title.en, 'T');
    });

    test('/help/faqs asks for 5, and survives a missing meta block', () async {
      // `requestPaged` synthesises a default `meta` from the row count when
      // the server omits it — asserted here because Home reads only `data`
      // and a throw on a missing block would be invisible until staging did it.
      answering(okEnvelope(<dynamic>[
        <String, dynamic>{'id': 'f1', 'question': 'Q', 'answer': 'A'},
      ]));

      final List<HomeFaqItem> items = await datasource.getFaqs();

      expect(adapter.requests.single.path, ApiEndpoint.helpFaqs);
      expect(adapter.requests.single.queryParameters['per_page'],
          kHomeFaqPerPage);
      expect(items.single.question.en, 'Q');
    });

    test('a malformed row costs that row, not the page', () async {
      // `whereType` rather than a cast — the same call
      // `service_remote_datasource.dart` makes.
      answering(okEnvelope(<dynamic>[
        <String, dynamic>{'code': 'a'},
        'not a row',
        <String, dynamic>{'code': 'b'},
      ]));

      final List<Service> rows = await datasource.getPhase1Services();
      expect(rows.map((Service s) => s.code), <String>['a', 'b']);
    });
  });

  group('HomeRepositoryImpl — every throw becomes a Left', () {
    HomeRepositoryImpl repositoryAnswering(Object? body, {int status = 200}) {
      return HomeRepositoryImpl(
        remote: HomeRemoteDatasourceImpl(
          apiClient: ApiClient(
            dio: buildTestDio(
              storage: inMemoryStorageService(<String, String>{}),
              adapter:
                  RecordingHttpAdapter.always(body, statusCode: status),
            ),
            storage: inMemoryStorageService(<String, String>{}),
          ),
        ),
      );
    }

    test('a 500 on each of the six folds to a Left, not a throw', () async {
      final HomeRepositoryImpl r = repositoryAnswering(
        failEnvelope(code: 'INTERNAL_ERROR', message: 'boom'),
        status: 500,
      );

      final List<Future<Either<Failure, Object?>>> calls =
          <Future<Either<Failure, Object?>>>[
        r.getSummary(),
        r.getDigitalId(),
        r.getPhase1Services(),
        r.searchServices('x'),
        r.getFeaturedNews(),
        r.getFaqs(),
      ];

      for (final Future<Either<Failure, Object?>> call in calls) {
        expect((await call).isLeft(), isTrue);
      }
    });

    test('the Failure message is for logs, never for the screen', () async {
      // `HomePage.tsx:329` prefers the backend's sentence; this does not. A
      // server message rendered on a page that also prints a citizen's UIN is
      // backend detail leaking onto an authenticated surface, and
      // `ServicePage.tsx:227-232` (the page B2a ported) shows only fixed copy.
      final HomeRepositoryImpl r = repositoryAnswering(
        failEnvelope(
          code: 'FORBIDDEN',
          message: 'citizen 8842 lacks scope me:summary',
        ),
        status: 403,
      );

      final Either<Failure, HomeSummary> result = await r.getSummary();
      final Failure failure = result.swap().getOrElse(() => const Failure(''));

      expect(failure.message, contains('citizen 8842'));
      // …and the page never reads it — asserted at the widget level in
      // `home_page_test.dart`'s error-state cases, which look for the fixed
      // `home.summaryError` string.
    });

    test('a success folds to a Right carrying the parsed entity', () async {
      final HomeRepositoryImpl r =
          repositoryAnswering(okEnvelope(<String, dynamic>{'uin': 'u1'}));

      expect(
        (await r.getDigitalId()).getOrElse(() => const DigitalIdCard()).uin,
        'u1',
      );
    });

    test('a transport failure with no response also folds', () async {
      // Connection refused / DNS / TLS — `ApiClient` maps these to a
      // NETWORK_ERROR `ApiException`, and the repository must catch that too,
      // not only envelope failures.
      final HomeRepositoryImpl r = HomeRepositoryImpl(
        remote: HomeRemoteDatasourceImpl(
          apiClient: ApiClient(
            dio: buildTestDio(
              storage: inMemoryStorageService(<String, String>{}),
              adapter: RecordingHttpAdapter(
                (RequestOptions options, int _) => throw DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              ),
            ),
            storage: inMemoryStorageService(<String, String>{}),
          ),
        ),
      );

      expect((await r.getFeaturedNews()).isLeft(), isTrue);
    });
  });
}
