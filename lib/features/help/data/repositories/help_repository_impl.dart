/// `HelpRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// Follows `HomeRepositoryImpl` and `ServiceRepositoryImpl` exactly, including
/// their deviation from the session feature: no `ApiException` rethrow. Every
/// mode the help centre has — offline, 500, a malformed row, a 404 on a guide —
/// collapses to the same user-visible outcome: that region's error-with-retry
/// state (§ 6.6). Unlike `NewsRepositoryImpl` there is no 404 special case,
/// because no help surface has a "this thing does not exist" render: a guide
/// the citizen can expand came from the list a moment earlier.
///
/// [Failure.message] carries the exception text for logs and is **not** what
/// the page renders — `HelpCenterPage.tsx:269` prints `faqs.error.message`, the
/// backend's own sentence, and the Flutter page shows the fixed bilingual copy
/// instead (`ServicePage.tsx:227-232`'s behaviour, the one B2a ported).
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/help_entities.dart';
import '../../domain/repositories/help_faq_page.dart';
import '../../domain/repositories/help_repository.dart';
import '../datasources/help_remote_datasource.dart';

class HelpRepositoryImpl implements HelpRepository {
  const HelpRepositoryImpl({required this.remote});

  final HelpRemoteDatasource remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FaqCategory>>> getCategories() =>
      _guard(remote.getCategories);

  @override
  Future<Either<Failure, HelpFaqPage>> getFaqs({
    required int page,
    required int perPage,
    String? category,
    String? search,
  }) =>
      _guard(() => remote.getFaqs(
            page: page,
            perPage: perPage,
            category: category,
            search: search,
          ));

  @override
  Future<Either<Failure, List<HelpArticle>>> getGuides() =>
      _guard(remote.getGuides);

  @override
  Future<Either<Failure, HelpArticle>> getGuide(String slug) =>
      _guard(() => remote.getGuide(slug));

  @override
  Future<Either<Failure, List<SupportChannel>>> getChannels() =>
      _guard(remote.getChannels);

  @override
  Future<Either<Failure, Unit>> sendFaqFeedback({
    required String id,
    required bool helpful,
  }) =>
      _guard(() async {
        await remote.sendFaqFeedback(id: id, helpful: helpful);
        return unit;
      });
}
