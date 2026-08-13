/// Home's repository contract — the five reads `HomePage.tsx` fires.
///
/// | Source | Method | Auth |
/// |---|---|---|
/// | `HomePage.tsx:163` `me.homeSummary` | [getSummary] | signed in only |
/// | `HomePage.tsx:168` `me.digitalID` | [getDigitalId] | signed in only |
/// | `HomePage.tsx:171` `catalog.services({phase1:true})` | [getPhase1Services] | anonymous |
/// | `HomePage.tsx:172` `content.news({per_page:3, featured:true})` | [getFeaturedNews] | anonymous |
/// | `HomePage.tsx:178` `content.faqs({per_page:5})` | [getFaqs] | anonymous |
///
/// Plus one the web performs client-side and this app hands to the server —
/// see [searchServices].
///
/// The two authenticated reads are **not** gated here. `enabled:
/// Boolean(isAuthenticated)` is a *call-site* condition in the source
/// (`useQuery`'s option), and it stays one here: `HomeBloc` decides whether to
/// ask, and the repository answers when asked. A repository that returned
/// `Left(Failure('not signed in'))` would turn "we did not ask" into an error
/// state, which is precisely the rendering § 6.6 and manifest F-4 forbid — a
/// signed-out home shows the masked card and "Sign in to activate", **not** a
/// spinner and **not** an error.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../service/domain/entities/service.dart';
import '../entities/digital_id_card.dart';
import '../entities/home_faq_item.dart';
import '../entities/home_news_item.dart';
import '../entities/home_summary.dart';

abstract class HomeRepository {
  /// `GET /me/home-summary`.
  Future<Either<Failure, HomeSummary>> getSummary();

  /// `GET /me/digital-id`.
  Future<Either<Failure, DigitalIdCard>> getDigitalId();

  /// `GET /services?phase1=true` — the quick-actions grid.
  ///
  /// Returns the **shared** `Service` entity from `features/service/domain/`,
  /// not a home-local copy. That import is the sanctioned Cross-Feature
  /// Isolation edge (G-L3 permits `domain/`) and it is required rather than
  /// convenient: SSD § 13 **C-2** names Home's "Apply now" as one of exactly
  /// two call sites of `ServiceAvailability`, whose predicate takes a
  /// `Service`. A parallel `HomeService` would either duplicate the predicate —
  /// the drift C-2 exists to prevent — or need a lossy conversion at the one
  /// place the answer must be identical.
  Future<Either<Failure, List<Service>>> getPhase1Services();

  /// `GET /services?search=<query>` — the search results grid.
  ///
  /// **A deliberate mechanism divergence, recorded rather than discovered.**
  /// `HomePage.tsx:264-272` filters the *static* `SERVICES` table
  /// (`ServicePage.tsx:158+`, 40 hand-seeded rows) with a client-side
  /// `toLowerCase().includes()`. This asks the API instead, for three reasons:
  ///
  /// 1. **The static table is legacy in the source itself.**
  ///    `ServicePage.tsx:141-144` says so: *"The static tables below are no
  ///    longer what this page renders — the catalogue comes from
  ///    /service-categories and /services."* They survive only because Home had
  ///    not been migrated. Porting them would ship 40 hardcoded bilingual names
  ///    and 40 hardcoded fees that go stale on the first catalogue edit — the
  ///    trade B2a already refused for the identical table
  ///    (`Service`'s doc, "The fee is read off the row").
  /// 2. **The server is already the search authority for this app.**
  ///    `ServiceRepository.getServices`' own doc: *"a client-side `contains`
  ///    would match different rows than the API's matcher and the two surfaces
  ///    would disagree about what 'cert' finds."* Two Flutter pages searching
  ///    one catalogue by two different rules is the exact defect that reasoning
  ///    rejects.
  /// 3. **The corpus is bigger and current.** The web searches 40 seeded rows;
  ///    this searches all 43 live ones, which is what SSD § 13 **C-1** requires
  ///    the app to treat as the catalogue.
  ///
  /// The divergence is in *mechanism*; the observable output — type, get up to
  /// seven matching service cards — is the source's. It is flagged in the
  /// hand-back as needing a ruling, because it is a judgement call, not a
  /// derivation.
  Future<Either<Failure, List<Service>>> searchServices(String query);

  /// `GET /news?per_page=3&featured=true`.
  Future<Either<Failure, List<HomeNewsItem>>> getFeaturedNews();

  /// `GET /help/faqs?per_page=5`.
  Future<Either<Failure, List<HomeFaqItem>>> getFaqs();
}
