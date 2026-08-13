/// `HelpRepositoryImpl` — the fold.
///
/// Unlike `NewsRepositoryImpl` there is **no 404 special case**, and that is a
/// decision rather than an omission: no help surface has a "this thing does not
/// exist" render. A guide the citizen can expand came from the list a moment
/// earlier, so a 404 on its body is a broken deployment and belongs in the
/// error-with-retry state like every other failure.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/help/data/datasources/help_remote_datasource.dart';
import 'package:lcc_mobile_app/features/help/data/repositories/help_repository_impl.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_faq_page.dart';

import '../../../helpers/help_test_helper.dart';

class _Datasource implements HelpRemoteDatasource {
  _Datasource({this.error});

  final Object? error;
  final List<({String id, bool helpful})> posted =
      <({String id, bool helpful})>[];

  Future<T> _answer<T>(T ok) async {
    if (error != null) throw error!;
    return ok;
  }

  @override
  Future<List<FaqCategory>> getCategories() => _answer(recordedTopics());

  @override
  Future<HelpFaqPage> getFaqs({
    required int page,
    required int perPage,
    String? category,
    String? search,
  }) =>
      _answer(recordedFaqPage());

  @override
  Future<List<HelpArticle>> getGuides() => _answer(recordedGuides());

  @override
  Future<HelpArticle> getGuide(String slug) => _answer(recordedGuideBody());

  @override
  Future<List<SupportChannel>> getChannels() => _answer(recordedChannels());

  @override
  Future<void> sendFaqFeedback({
    required String id,
    required bool helpful,
  }) async {
    if (error != null) throw error!;
    posted.add((id: id, helpful: helpful));
  }
}

void main() {
  group('the happy path', () {
    test('all six calls come back Right', () async {
      final HelpRepositoryImpl repository =
          HelpRepositoryImpl(remote: _Datasource());

      expect((await repository.getCategories()).isRight(), isTrue);
      expect(
        (await repository.getFaqs(page: 1, perPage: 10)).isRight(),
        isTrue,
      );
      expect((await repository.getGuides()).isRight(), isTrue);
      expect((await repository.getGuide('x')).isRight(), isTrue);
      expect((await repository.getChannels()).isRight(), isTrue);
      expect(
        (await repository.sendFaqFeedback(id: 'a', helpful: true)).isRight(),
        isTrue,
      );
    });

    test('the POST forwards its two values', () async {
      final _Datasource remote = _Datasource();
      final HelpRepositoryImpl repository = HelpRepositoryImpl(remote: remote);

      await repository.sendFaqFeedback(id: 'faq-9', helpful: false);

      expect(remote.posted, <({String id, bool helpful})>[
        (id: 'faq-9', helpful: false),
      ]);
    });

    test('a successful vote returns Right(unit), not Right(null)', () async {
      final Either<Failure, Unit> result = await HelpRepositoryImpl(
        remote: _Datasource(),
      ).sendFaqFeedback(id: 'a', helpful: true);

      result.fold((_) => fail('expected a Right'), (Unit u) => expect(u, unit));
    });
  });

  group('every throw folds to a plain Failure — including a 404', () {
    final List<({String name, Object error})> cases =
        <({String name, Object error})>[
      (
        name: 'a transport failure',
        error: ApiException(
          status: 0,
          code: ApiCode.networkError,
          message: 'offline',
        ),
      ),
      (
        name: 'a 404',
        error: ApiException(
          status: 404,
          code: ApiCode.notFound,
          message: 'gone',
        ),
      ),
      (
        name: 'a 500',
        error: ApiException(
          status: 500,
          code: ApiCode.internalError,
          message: 'boom',
        ),
      ),
      (name: 'a parse error', error: const FormatException('bad body')),
    ];

    for (final ({String name, Object error}) c in cases) {
      test('${c.name} on getGuide', () async {
        final Either<Failure, HelpArticle> result =
            await HelpRepositoryImpl(remote: _Datasource(error: c.error))
                .getGuide('x');

        expect(result.isLeft(), isTrue);
        result.fold(
          (Failure f) => expect(f.runtimeType, Failure,
              reason: 'help has no not-found render, so no failure subtype — '
                  'see the library doc'),
          (_) => fail('expected a Left'),
        );
      });
    }

    test('a failed POST is a Left the CALLER is free to ignore', () async {
      // The repository does not swallow it: the decision to ignore lives at the
      // call site, where it is visible and testable (`HelpBloc._onFaqVoted`).
      final Either<Failure, Unit> result = await HelpRepositoryImpl(
        remote: _Datasource(error: const FormatException('boom')),
      ).sendFaqFeedback(id: 'a', helpful: true);

      expect(result.isLeft(), isTrue);
    });

    test('the failure message carries the exception text for logs', () async {
      final Either<Failure, List<SupportChannel>> result =
          await HelpRepositoryImpl(
        remote: _Datasource(error: StateError('diagnostic detail')),
      ).getChannels();

      result.fold(
        (Failure f) => expect(f.message, contains('diagnostic detail')),
        (_) => fail('expected a Left'),
      );
    });
  });
}
