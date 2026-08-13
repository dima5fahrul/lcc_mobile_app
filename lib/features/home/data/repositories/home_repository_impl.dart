/// `HomeRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// Follows `ServiceRepositoryImpl` exactly, including its deviation *from* the
/// session feature: no `ApiException` rethrow. `SessionBloc` has to branch on
/// 401/403 to clear tokens; Home does not. Its two authenticated reads are
/// fired only when the session already says the citizen is signed in, and a
/// token that expires mid-request is the `RefreshInterceptor`'s problem — by
/// the time a failure reaches here, every mode Home has (offline, 500, 401
/// after a failed refresh, a malformed row) collapses to the same user-visible
/// outcome: that region's error-with-retry state (§ 6.6).
///
/// [Failure.message] carries the exception text for logs. It is **not** what
/// the page renders. The source is explicit about this and it is a security
/// property as well as a fidelity one: `HomePage.tsx:329` writes
/// `{summary.error.message || c("summaryError")}` — but the messages
/// `ApiClient` produces are the *backend's*, and printing a server sentence on
/// a page that also renders a citizen's UIN is how backend detail leaks onto an
/// authenticated surface. The Flutter page shows the fixed bilingual sentence
/// only, which is `ServicePage.tsx:227-232`'s behaviour and the one B2a already
/// ported.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../service/domain/entities/service.dart';
import '../../domain/entities/digital_id_card.dart';
import '../../domain/entities/home_faq_item.dart';
import '../../domain/entities/home_news_item.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({required this.remote});

  final HomeRemoteDatasource remote;

  /// One `try`/`catch`, six call sites. Written once rather than six times so a
  /// later reader cannot find five that fold and one that throws.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HomeSummary>> getSummary() =>
      _guard(remote.getSummary);

  @override
  Future<Either<Failure, DigitalIdCard>> getDigitalId() =>
      _guard(remote.getDigitalId);

  @override
  Future<Either<Failure, List<Service>>> getPhase1Services() =>
      _guard(remote.getPhase1Services);

  @override
  Future<Either<Failure, List<Service>>> searchServices(String query) =>
      _guard(() => remote.searchServices(query));

  @override
  Future<Either<Failure, List<HomeNewsItem>>> getFeaturedNews() =>
      _guard(remote.getFeaturedNews);

  @override
  Future<Either<Failure, List<HomeFaqItem>>> getFaqs() =>
      _guard(remote.getFaqs);
}
