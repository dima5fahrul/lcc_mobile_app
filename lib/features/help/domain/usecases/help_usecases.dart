/// The help centre's six use cases.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/help_entities.dart';
import '../repositories/help_faq_page.dart';
import '../repositories/help_repository.dart';

/// `HelpCenterPage.tsx:30` — `const PER_PAGE = 10`.
const int kHelpPerPage = 10;

/// `HelpCenterPage.tsx:96` — the topic filter's initial and "no filter" value.
const String kHelpAllTopics = 'all';

/// `useDebounced(query.trim(), 350)` — `HelpCenterPage.tsx:102`.
const Duration kHelpSearchDebounce = Duration(milliseconds: 350);

/// `GET /help/categories`.
class GetHelpCategories implements UseCase<List<FaqCategory>, NoParams> {
  const GetHelpCategories({required this.repository});

  final HelpRepository repository;

  @override
  Future<Either<Failure, List<FaqCategory>>> call(NoParams params) =>
      repository.getCategories();
}

/// The question list's query: page, topic, search term.
///
/// The two "unset" normalisations live here rather than at the call site so
/// `cat === "all" ? undefined : cat` and `search || undefined` (`:110`) exist
/// once each. A BLoC that forgot either would send `?category=all` or
/// `?search=` and get a result set that looks like a real empty.
class GetHelpFaqsParams extends Equatable {
  GetHelpFaqsParams({
    required this.page,
    this.perPage = kHelpPerPage,
    this.category = kHelpAllTopics,
    String search = '',
  }) : search = search.trim();

  final int page;
  final int perPage;
  final String category;
  final String search;

  String? get wireCategory =>
      category == kHelpAllTopics || category.isEmpty ? null : category;

  String? get wireSearch => search.isEmpty ? null : search;

  @override
  List<Object?> get props => <Object?>[page, perPage, category, search];
}

/// `GET /help/faqs` — one page.
class GetHelpFaqs implements UseCase<HelpFaqPage, GetHelpFaqsParams> {
  const GetHelpFaqs({required this.repository});

  final HelpRepository repository;

  @override
  Future<Either<Failure, HelpFaqPage>> call(GetHelpFaqsParams params) =>
      repository.getFaqs(
        page: params.page,
        perPage: params.perPage,
        category: params.wireCategory,
        search: params.wireSearch,
      );
}

/// `GET /help/articles`.
class GetHelpGuides implements UseCase<List<HelpArticle>, NoParams> {
  const GetHelpGuides({required this.repository});

  final HelpRepository repository;

  @override
  Future<Either<Failure, List<HelpArticle>>> call(NoParams params) =>
      repository.getGuides();
}

/// The slug of the guide the citizen expanded.
class GetHelpGuideParams extends Equatable {
  GetHelpGuideParams(String slug) : slug = slug.trim();

  final String slug;

  @override
  List<Object?> get props => <Object?>[slug];
}

/// `GET /help/articles/<slug>` — fetched lazily, on expand
/// (`enabled: Boolean(openGuide)`, `:117-119`).
class GetHelpGuide implements UseCase<HelpArticle, GetHelpGuideParams> {
  const GetHelpGuide({required this.repository});

  final HelpRepository repository;

  @override
  Future<Either<Failure, HelpArticle>> call(GetHelpGuideParams params) =>
      repository.getGuide(params.slug);
}

/// `GET /help/channels`.
class GetSupportChannels implements UseCase<List<SupportChannel>, NoParams> {
  const GetSupportChannels({required this.repository});

  final HelpRepository repository;

  @override
  Future<Either<Failure, List<SupportChannel>>> call(NoParams params) =>
      repository.getChannels();
}

/// One thumbs-up / thumbs-down.
class SendFaqFeedbackParams extends Equatable {
  const SendFaqFeedbackParams({required this.id, required this.helpful});

  final String id;
  final bool helpful;

  @override
  List<Object?> get props => <Object?>[id, helpful];
}

/// `POST /help/faqs/<id>/feedback`.
class SendFaqFeedback implements UseCase<Unit, SendFaqFeedbackParams> {
  const SendFaqFeedback({required this.repository});

  final HelpRepository repository;

  @override
  Future<Either<Failure, Unit>> call(SendFaqFeedbackParams params) =>
      repository.sendFaqFeedback(id: params.id, helpful: params.helpful);
}

/// `catMeta(code)` — `HelpCenterPage.tsx:132-136`.
///
/// The position of a question's category in the category list, which is what
/// picks its swatch (`swatch(topic.index)`, `AppColors.helpSwatch`) and its
/// icon. **An unknown code resolves to index 0**, not to "no swatch": the
/// source writes `index < 0 ? 0 : index`, so a question whose category is not
/// in the list wears the first topic's colour rather than disappearing.
///
/// In `domain/` because it is a rule about the data, and because index-0
/// clamping is exactly the boundary a widget test would not think to cover.
({int index, String icon}) helpCategoryMeta(
  List<FaqCategory> categories,
  String code,
) {
  final int found = categories.indexWhere((FaqCategory c) => c.code == code);
  final int index = found < 0 ? 0 : found;
  // `icon(list[index]?.icon)` — note it reads the icon at the RAW index, so an
  // unknown code (found == -1) yields `list[-1]` → `undefined` → the FileText
  // fallback, while still using index 0 for the swatch. The two differ, and the
  // asymmetry is the source's.
  final String icon =
      found < 0 || found >= categories.length ? '' : categories[found].icon;
  return (index: index, icon: icon);
}
