/// The help centre's repository contract — six calls, one screen.
///
/// | Source | Method | Endpoint |
/// |---|---|---|
/// | `HelpCenterPage.tsx:104` | [getCategories] | `GET /help/categories` |
/// | `:107` | [getFaqs] | `GET /help/faqs` (paged) |
/// | `:116` | [getGuides] | `GET /help/articles` |
/// | `:117` | [getGuide] | `GET /help/articles/<slug>` |
/// | `:120` | [getChannels] | `GET /help/channels` |
/// | `:122` | [sendFaqFeedback] | `POST /help/faqs/<id>/feedback` |
///
/// The five reads are `anonymous: true` in `endpoints.ts:373-380`. **The POST
/// is not** — `faqFeedback` is the one call in this feature that omits the flag
/// (`:375`), so it carries whatever token the interceptor attaches. That
/// asymmetry is the source's and is reproduced rather than tidied.
///
/// ## The one POST, and why it is Tier 0 NOT APPLICABLE
///
/// specs.md § 6.5.1 rules Tier 0 (form-payload equality) out on the merits for
/// all of B2, naming this exact call: *"B2 … issues exactly one POST
/// (`/help/faqs/:id/feedback`, body `{helpful: bool}` — a two-value payload
/// with no user-entered content)."* Recorded here so the ruling is visible from
/// the code it is about.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/help_entities.dart';
import 'help_faq_page.dart';

abstract class HelpRepository {
  /// `GET /help/categories`.
  Future<Either<Failure, List<FaqCategory>>> getCategories();

  /// `GET /help/faqs?page=&per_page=[&category=][&search=]`.
  ///
  /// Both filters are omitted rather than empty when unset:
  /// `category: cat === "all" ? undefined : cat` and
  /// `search: search || undefined` (`:110`).
  Future<Either<Failure, HelpFaqPage>> getFaqs({
    required int page,
    required int perPage,
    String? category,
    String? search,
  });

  /// `GET /help/articles` — titles only, no bodies.
  Future<Either<Failure, List<HelpArticle>>> getGuides();

  /// `GET /help/articles/<slug>` — the one read that carries `body`.
  Future<Either<Failure, HelpArticle>> getGuide(String slug);

  /// `GET /help/channels`.
  Future<Either<Failure, List<SupportChannel>>> getChannels();

  /// `POST /help/faqs/<id>/feedback`, body `{"helpful": bool}`.
  ///
  /// Returns `Right(unit)` on success. The **caller ignores a failure on
  /// purpose** — the source's `catch {}` at `:142-145` carries the reason:
  /// *"A failed vote is not worth interrupting the reader; leave the thanks in
  /// place rather than flipping the row back under their finger."* The
  /// `Either` is still returned rather than swallowed here, so the decision to
  /// ignore it is made at the call site where it is visible and testable.
  Future<Either<Failure, Unit>> sendFaqFeedback({
    required String id,
    required bool helpful,
  });
}
