/// Home's six use cases.
///
/// ## Why one file and not six
///
/// The auth feature files them one per class because each carries a `Params`
/// value object with its own validation. Five of these six take [NoParams] and
/// forward one call; the sixth takes a query string. Six files of four lines
/// each would spread one idea over six places and make the *set* — which is
/// the thing a reader needs, because it is the page's whole data surface —
/// invisible. The table in `HomeRepository`'s doc is the map; this is the
/// mechanism.
///
/// The classes are still separate types, so DI registers six lazy singletons
/// (DI-2) and `HomeBloc`'s constructor names exactly what it depends on. That
/// is the property the one-file-per-class convention exists to protect, and it
/// is preserved.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../service/domain/entities/service.dart';
import '../entities/digital_id_card.dart';
import '../entities/home_faq_item.dart';
import '../entities/home_news_item.dart';
import '../entities/home_summary.dart';
import '../repositories/home_repository.dart';

/// `GET /me/home-summary` — the four tiles and the action banner.
class GetHomeSummary implements UseCase<HomeSummary, NoParams> {
  const GetHomeSummary({required this.repository});

  final HomeRepository repository;

  @override
  Future<Either<Failure, HomeSummary>> call(NoParams params) =>
      repository.getSummary();
}

/// `GET /me/digital-id` — the UIN and photo the LaoID card prints.
class GetDigitalId implements UseCase<DigitalIdCard, NoParams> {
  const GetDigitalId({required this.repository});

  final HomeRepository repository;

  @override
  Future<Either<Failure, DigitalIdCard>> call(NoParams params) =>
      repository.getDigitalId();
}

/// `GET /services?phase1=true` — the quick-actions grid.
class GetPhase1Services implements UseCase<List<Service>, NoParams> {
  const GetPhase1Services({required this.repository});

  final HomeRepository repository;

  @override
  Future<Either<Failure, List<Service>>> call(NoParams params) =>
      repository.getPhase1Services();
}

/// The query a citizen typed into the hero's search field.
///
/// Trimmed at construction and empty-normalised to `''`, for the same reason
/// `GetServicesParams` does it: `search: ' '` and `search: ''` must not be two
/// spellings of one request that only happen to behave alike.
class SearchServicesParams extends Equatable {
  SearchServicesParams(String query) : query = query.trim();

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// `GET /services?search=<query>` — see [HomeRepository.searchServices] for
/// why this is a request and not a client-side filter.
class SearchServices implements UseCase<List<Service>, SearchServicesParams> {
  const SearchServices({required this.repository});

  final HomeRepository repository;

  @override
  Future<Either<Failure, List<Service>>> call(SearchServicesParams params) =>
      repository.searchServices(params.query);
}

/// `GET /news?per_page=3&featured=true`.
class GetFeaturedNews implements UseCase<List<HomeNewsItem>, NoParams> {
  const GetFeaturedNews({required this.repository});

  final HomeRepository repository;

  @override
  Future<Either<Failure, List<HomeNewsItem>>> call(NoParams params) =>
      repository.getFeaturedNews();
}

/// `GET /help/faqs?per_page=5`.
class GetHomeFaqs implements UseCase<List<HomeFaqItem>, NoParams> {
  const GetHomeFaqs({required this.repository});

  final HomeRepository repository;

  @override
  Future<Either<Failure, List<HomeFaqItem>>> call(NoParams params) =>
      repository.getFaqs();
}
