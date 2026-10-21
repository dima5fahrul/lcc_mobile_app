/// API endpoint path constants.
///
/// The base URL is resolved at compile time via `--dart-define=LCC_API_URL`
/// (falling back to the staging HTTPS backend) — see [ApiEndpoint.baseUrl].
///
/// Every path constant below is a *relative* segment (no host); the Dio
/// `BaseOptions.baseUrl` supplies the host prefix so the path strings stay
/// environment-agnostic.
///
/// Paths are ported verbatim from the web client `lcc-app/src/app/api/endpoints.ts`
/// so a change to the API surface shows up here as a compile error rather than
/// a 404 at runtime.
class ApiEndpoint {
  ApiEndpoint._();

  /// Resolved from `--dart-define=LCC_API_URL` (trimmed, trailing `/` stripped),
  /// falling back to `https://api.staging.linkit360.la/api/v1` when the define
  /// is absent or empty. The default is HTTPS-only (V-6): a cleartext
  /// `http://` default would ship an insecure backend to release builds.
  static const String _rawBase = String.fromEnvironment(
    'LCC_API_URL',
    defaultValue: 'https://api.staging.linkit360.la/api/v1',
  );

  // V-6 enforcement: release builds must talk to an HTTPS backend. If a release
  // build is compiled with `--dart-define=LCC_API_URL=http://...` the app must
  // fail loudly at startup rather than silently ship cleartext traffic. `assert`
  // alone is stripped in release, so this release-only `StateError` is the real
  // gate. The guard runs on first access of [baseUrl] — i.e. when the Dio client
  // reads `BaseOptions.baseUrl` at app bootstrap.
  static final String baseUrl = (() {
    final String trimmed = _rawBase.trim().replaceAll(RegExp(r'/+$'), '');
    final bool isRelease = const bool.fromEnvironment('dart.vm.product');
    if (isRelease && !trimmed.startsWith('https://')) {
      throw StateError(
        'ApiEndpoint.baseUrl must be HTTPS in release builds, got: "$trimmed". '
        'Compile with --dart-define=LCC_API_URL=https://... or omit the define '
        'to use the HTTPS staging default.',
      );
    }
    return trimmed;
  })();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String authRegister = '/auth/citizen/register';
  static const String authRequestOtp = '/auth/citizen/request-otp';
  static const String authVerifyOtp = '/auth/citizen/verify-otp';
  static const String authLogin = '/auth/citizen/login';
  static const String authLoginEid = '/auth/citizen/login/eid';
  static const String authForgotPassword = '/auth/citizen/forgot-password';
  static const String authResetPassword = '/auth/citizen/reset-password';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';
  static const String authChangePassword = '/auth/change-password';
  static const String authRefresh = '/auth/refresh';

  // ── The signed-in citizen ──────────────────────────────────────────────────
  static const String meProfile = '/me/profile';

  // `endpoints.ts:113,120`'s `me.digitalID` / `me.homeSummary`. Both are
  // authenticated — neither is `anonymous: true` in the source — and both are
  // fired by `HomePage.tsx` with `enabled: Boolean(isAuthenticated)`, so a
  // signed-out citizen never requests them (§ 6.6, manifest F-4). Additive
  // only (SSD § 6.5) — nothing above changed.
  static const String meHomeSummary = '/me/home-summary';
  static const String meDigitalId = '/me/digital-id';

  // ── Service catalogue (public, anonymous) ─────────────────────────────────
  // `endpoints.ts:167-171`'s `catalog.categories` / `catalog.services`. Both
  // are `anonymous: true` in the source and stay so here: the catalogue is
  // readable signed-out, which is what makes a signed-out citizen able to
  // browse all 43 services. Additive only (SSD § 6.5) — nothing above changed.
  static const String serviceCategories = '/service-categories';
  static const String services = '/services';

  // ── Content (public, anonymous, paged) ─────────────────────────────────────
  // `endpoints.ts:368,374`'s `content.news` / `content.faqs`. Both are
  // `anonymous: true` and both are **paged** — the envelope carries `meta`
  // beside the rows, so callers go through `ApiClient.requestPaged`.
  //
  // These two are shared between B2b and B2c: § 2.2 Finding B's table records
  // `/news` as `NewsPage.tsx:45` + `HomePage.tsx:173` and `/help/faqs` as
  // `HelpCenterPage.tsx:109` + `HomePage.tsx:178`. § 3.1's B2b column names
  // only the two `/me/*` paths and its B2c column claims all seven content
  // paths, which leaves the two Home also calls unattributed to the batch that
  // needs them first. Landed here by B2b because B2b cannot render without
  // them; B2c's remaining five paths (`/news/categories`, `/news/:slug`,
  // `/help/categories`, `/help/articles`, `/help/articles/:slug`, and the FAQ
  // feedback POST) are still its own to append. Recorded as a spec gap, not
  // resolved unilaterally.
  static const String news = '/news';
  static const String helpFaqs = '/help/faqs';

  // ── Content, the rest (public, anonymous) — B2c ────────────────────────────
  //
  // `endpoints.ts:369-380`'s remaining `content.*` members. Additive only
  // (SSD § 6.5, B2-AC-19): nothing above changed, `baseUrl` and the release
  // HTTPS guard are byte-identical.
  //
  // **§ 3.1's B2c column says "7 paths" and is right; the B2b comment above,
  // which enumerates what B2c still owes, says "five" and lists six while
  // omitting `/help/channels` entirely.** The seven are: `/news/categories`,
  // `/news/:slug`, `/help/categories`, `/help/articles`,
  // `/help/articles/:slug`, `/help/channels`, and the FAQ feedback POST.
  // Recorded as a spec/comment discrepancy rather than silently reconciled.

  /// `endpoints.ts:369` — `content.newsCategories`.
  static const String newsCategories = '/news/categories';

  /// `endpoints.ts:373` — `content.helpCategories`.
  static const String helpCategories = '/help/categories';

  /// `endpoints.ts:376` — `content.helpArticles`.
  static const String helpArticles = '/help/articles';

  /// `endpoints.ts:379` — `content.supportChannels`.
  static const String helpChannels = '/help/channels';

  // ── Parameterised content paths ────────────────────────────────────────────
  //
  // Functions, not constants, because the segment is a runtime value. The
  // alternative — a `'/news'` constant plus string concatenation at each call
  // site — is how a path template drifts from the one the web uses.
  //
  // The segment is percent-encoded. Slugs are `[a-z0-9-]` on staging today and
  // need no encoding, but `newsArticle` is reachable from a **route
  // parameter**, and an unencoded `/` or `?` in one would silently retarget the
  // request at a different endpoint.

  /// `endpoints.ts:370` — `content.newsArticle(slug)`.
  static String newsArticle(String slug) =>
      '/news/${Uri.encodeComponent(slug)}';

  /// `endpoints.ts:377` — `content.helpArticle(slug)`.
  static String helpArticle(String slug) =>
      '/help/articles/${Uri.encodeComponent(slug)}';

  /// `endpoints.ts:375` — `content.faqFeedback(id, helpful)`. **The one
  /// non-anonymous content call**: it is the only `content.*` member that omits
  /// `anonymous: true`, and B2's only POST (§ 6.5.1, Tier 0 NOT APPLICABLE).
  static String helpFaqFeedback(String id) =>
      '/help/faqs/${Uri.encodeComponent(id)}/feedback';

  // ── Notifications (authenticated) — B9a ────────────────────────────────────
  //
  // `endpoints.ts:136-139`'s four live `me.*` notification members. Additive
  // only (SSD § 6.5, B9-AC-13): nothing above changed, `baseUrl` and the
  // release HTTPS guard are byte-identical.
  //
  // **None carries `anonymous: true`** — they are `me.*` reads and writes, so
  // they go out with whatever token the interceptor chain attaches, and a
  // signed-out citizen never issues one (`enabled: isAuthenticated`,
  // `Layout.tsx:115,119`).
  //
  // **`DELETE /me/notifications/{id}` is deliberately absent.**
  // `endpoints.ts:140` defines `deleteNotification` and
  // `grep -rn "deleteNotification" lcc-app/src` returns that definition and
  // nothing else — no component calls it and the bell menu has no delete
  // affordance (`Layout.tsx:253-281`). Under ADR-0001 an endpoint the shipped
  // app never calls has an empty oracle in all four fidelity tiers, so it is
  // out of B9's scope (specs.md § 2.2 Finding D, FU-1). Adding a constant for
  // it here would be the first half of porting a behaviour the source does not
  // have.

  /// `endpoints.ts:136` — `me.notifications`. **Paged** (`api.paged`), called
  /// with `per_page: 8` (`Layout.tsx:117`).
  static const String meNotifications = '/me/notifications';

  /// `endpoints.ts:137` — `me.unreadCount`. Answers the **object**
  /// `{"unread": <int>}`, not an array; see `notification_wire.dart`.
  static const String meNotificationsUnreadCount =
      '/me/notifications/unread-count';

  /// `endpoints.ts:139` — `me.readAllNotifications`. A POST with **no body**.
  static const String meNotificationsReadAll = '/me/notifications/read-all';

  /// `endpoints.ts:138` — `me.readNotification(id)`. A POST with **no body**.
  ///
  /// A function with the segment percent-encoded, per the convention
  /// `newsArticle` / `helpArticle` establish above: the id is server-supplied
  /// rather than route-supplied, so it is unlikely to need encoding — but one
  /// rule for parameterised paths is cheaper than a documented exception.
  static String meNotificationRead(String id) =>
      '/me/notifications/${Uri.encodeComponent(id)}/read';

  // ── Customer-service chat (authenticated) — B9b ────────────────────────────
  //
  // `endpoints.ts:155-161`'s six `me.*` chat members, over **four** paths:
  // `/me/chat/threads` serves both the GET and the create POST (`:155,156`),
  // and `/me/chat/threads/<id>/messages` serves both the paged GET and the send
  // POST (`:157,158`). Additive only (SSD § 6.5, B9-AC-13): nothing above
  // changed, `baseUrl` and the release HTTPS guard are byte-identical.
  //
  // **§ 3.1's B9b row says "5 chat paths"; § 5's table enumerates four, and the
  // four are correct.** Recorded as a spec discrepancy rather than resolved by
  // inventing a fifth — the same disposition the B2b/B2c comment above takes
  // for its own "five that lists six".
  //
  // **None carries `anonymous: true`.** All six are `/me/*`, so they go out
  // with whatever token the interceptor chain attaches, and a signed-out
  // citizen never issues one (`enabled: isAuthenticated`,
  // `CustomerServiceChat.tsx:56,84`).
  //
  // **`/help/channels` is deliberately absent from this block.** The chat reads
  // it (`:47`) but B2c already landed `helpChannels` above, and B9b consumes it
  // through `features/help/domain`'s `GetSupportChannels` rather than adding a
  // second constant and a second wire mapping (specs.md § 6.6, B9-AC-43).

  /// `endpoints.ts:155,156` — `me.chatThreads` (GET, a **plain array**, not
  /// paged) and `me.startChatThread` (POST `{subject, topic, message}`).
  static const String meChatThreads = '/me/chat/threads';

  /// `endpoints.ts:157,158` — `me.chatMessages` (GET, **paged**, called with
  /// `per_page: 100` at `:82`) and `me.sendChatMessage` (POST `{body}`).
  ///
  /// A function with the segment percent-encoded, per the convention
  /// `newsArticle` / `helpArticle` establish above.
  static String meChatMessages(String threadId) =>
      '/me/chat/threads/${Uri.encodeComponent(threadId)}/messages';

  /// `endpoints.ts:160` — `me.readChatThread`. A POST with **no body**.
  static String meChatThreadRead(String threadId) =>
      '/me/chat/threads/${Uri.encodeComponent(threadId)}/read';

  /// `endpoints.ts:161` — `me.closeChatThread`. A POST with `{rating}`.
  static String meChatThreadClose(String threadId) =>
      '/me/chat/threads/${Uri.encodeComponent(threadId)}/close';

  // ── Account & profile (authenticated) — B8a ────────────────────────────────
  //
  // `endpoints.ts:122-123`'s `me.preferences` / `me.savePreferences` and
  // `:115`'s `me.documents`. Additive only (SSD § 6.5, B8-AC-63): nothing above
  // changed, `baseUrl` and the release HTTPS guard are byte-identical.
  //
  // **`meProfile` (`:58`) and `authChangePassword` (`:54`) already exist** and
  // are NOT re-declared — specs.md § 2.2 Finding I measured that and it holds.
  //
  // **`DELETE /me/account` is deliberately absent, and this is the load-bearing
  // omission of the batch.** `endpoints.ts:125` defines `me.deactivate` and
  // `grep -rn "deactivate" lcc-app/src` returns that definition and nothing
  // else — no component, no route, no button, no confirmation dialog, because
  // there is no feature. Under ADR-0001 an endpoint the shipped app never calls
  // has an empty oracle in all four fidelity tiers; adding a constant for it
  // here would be the first half of porting an **irreversible account
  // deletion** that exists only in the port, into an application whose APK is
  // unrecallable under ADR-0002 (specs.md § 6.1, FU-4). Re-adding it is a
  // product decision against the *web app* first, never an implementer's.
  //
  // **`GET /me/documents/{id}` is also absent, and that is a deviation from
  // § 3.1 rather than an oversight.** § 3.1's B8a row asks for `meDocument(id)`
  // alongside the two below, but `me.document(id)` (`endpoints.ts:116`) has
  // exactly one call site in the whole web tree — `DocumentViewer.tsx:45` — and
  // § 6.6 defers `DocumentViewer` to FU-2. A constant whose only consumer is
  // deferred is a constant nothing calls, which is the same shape B9a refused
  // for `deleteNotification`. It lands with FU-2's owner.

  /// `endpoints.ts:122,123` — `me.preferences` (GET) and `me.savePreferences`
  /// (**PUT**, not PATCH: the body is the whole `CitizenPreferences` object,
  /// see specs.md § 6.9 leaf 2 and `account_wire.dart`).
  static const String mePreferences = '/me/preferences';

  /// `endpoints.ts:115` — `me.documents`. A **plain array**, not paged.
  static const String meDocuments = '/me/documents';

  // ── Avatar upload (authenticated, multipart) — B8b ─────────────────────────
  //
  // `endpoints.ts:107-111`'s `me.uploadAvatar`. Additive only (SSD § 6.5,
  // B8-AC-63): nothing above changed, `baseUrl` and the release HTTPS guard are
  // byte-identical.
  //
  // **The send direction has the host constraint the render direction lacks.**
  // This POST goes through [baseUrl] and its release HTTPS guard (`:31-42`);
  // the `avatar_url` that comes back is fetched by `Image.network` with no host
  // constraint and no `Authorization` header (`account_header.dart:261`,
  // B8a `security-review.md` MEDIUM-2). `security-review-b8b.md` § 6 names that
  // asymmetry, and FU-12 owns it — it is not closed here.

  /// `endpoints.ts:110` — `me.uploadAvatar`.
  ///
  /// Multipart, one part named exactly `file`, and the caller sets **no**
  /// `Content-Type` so Dio owns the boundary — `api_client.dart:253-257`, the
  /// mirror of `client.ts:236`'s *"the browser sets the multipart boundary
  /// itself"*. B8-AC-56.
  static const String meAvatar = '/me/avatar';

  // ── Reference lists and locations (public, anonymous) — F0b ────────────────
  //
  // `endpoints.ts:185-186`'s `catalog.referenceList` and `:215-252`'s three
  // `locations.*` reads. Additive only (SSD § 6.5, `F0-AC-12`): nothing above
  // changed, `baseUrl` and the release HTTPS guard are byte-identical.
  //
  // **All four carry `anonymous: true` in the source** and are read anonymously
  // here. That is the security posture the reference layer is scoped to, and
  // `F0-AC-70` clause (1) re-confirms it: the lookup layer sends no bearer and
  // logs no PII.
  //
  // **`/reference-lists` (the bare index at `endpoints.ts:189`) is deliberately
  // absent.** It answers `Array<{type, count}>` — a catalogue of which lists
  // exist — and `grep -rn "referenceTypes" lcc-app/src` returns its definition
  // and nothing else. Under `ADR-0001` an endpoint the shipped app never calls
  // has an empty oracle in all four tiers; adding a constant for it is the
  // first half of porting a behaviour the source does not have. Same
  // disposition B9a took for `deleteNotification` and B8a for `me.deactivate`.
  //
  // **`/locations/districts` and `/locations/villages` (the FLAT forms at
  // `:236` and `:264`) are also absent, and for a different reason:** they are
  // real, but `formFields.tsx` uses only the nested forms — `locations.districts`
  // at `:416` and `villagesInDistrict` at `:439`. The flat forms exist for a
  // search not scoped to a parent, which no certificate form performs.
  //
  // **`/prerequisite-records` is not part of this feature** (`ssd.md` § 11.4).
  // `betrothal` / `mediation` / the two `*_certificate_ref` keys are the FR-11
  // record-picker sub-flow that only Marriage and Divorce have — a different
  // endpoint, a different interaction and a different owner. F3's.
  //
  // **F3 claimed it.** The two constants below are that sub-flow's, added under
  // `GOR-245-f3-marriage-divorce/specs.md` § 3.1 row 7 ("additive only — only
  // `/prerequisite-records` and `/prerequisite-records/{no}` … **if absent**").
  // They were absent. `/applications/{id}/pay` is still NOT here and is still
  // reserved to B6b by name below.

  /// `endpoints.ts:194-195` — `catalog.prerequisiteRecords({kind, search,
  /// per_page})`, a **paged** read.
  ///
  /// The query is the caller's: Marriage sends `kind: "betrothal"`
  /// (`MarriageCertificatePage.tsx:754`), Divorce `kind: "mediation"`
  /// (`DivorceCertificatePage.tsx:660`), both with `per_page: 20`. The third
  /// wire kind, `"marriage-certificate"`, has no caller on either page.
  ///
  /// **It answers `data: [] total: 0` on every account this programme has**
  /// (`manifest-authenticated.md`:230-232), so the empty state is the only
  /// reachable one — which is why the port renders it correctly and unit-tests
  /// the other two against fakes rather than claiming execution evidence.
  static const String prerequisiteRecords = '/prerequisite-records';

  /// `endpoints.ts:197-198` — `catalog.prerequisiteRecord(recordNo)`.
  ///
  /// A function, per the `referenceList` / `newsArticle` convention: the
  /// segment is a runtime value and is percent-encoded, so a `record_no`
  /// carrying a `/` cannot silently retarget the request.
  static String prerequisiteRecord(String recordNo) =>
      '/prerequisite-records/${Uri.encodeComponent(recordNo)}';

  /// `endpoints.ts:185-186` — `catalog.referenceList(type)`. The `type` is the
  /// field's `lookup_key` from the form schema.
  ///
  /// A function, per the convention `newsArticle` / `helpArticle` establish:
  /// the segment is a runtime value and is percent-encoded, so a `lookup_key`
  /// carrying a `/` cannot silently retarget the request.
  ///
  /// Answers `{type, count, items}` on the live API; the datasource also
  /// tolerates a bare array, because `formFields.tsx:237` does (FR-LOOK-2).
  static String referenceList(String type) =>
      '/reference-lists/${Uri.encodeComponent(type)}';

  /// `endpoints.ts:216` — `locations.provinces`. A **plain array**, not paged.
  static const String locationProvinces = '/locations/provinces';

  /// `endpoints.ts:223` — `locations.districts(provinceId)`. A **plain array**.
  static String locationDistricts(String provinceId) =>
      '/locations/provinces/${Uri.encodeComponent(provinceId)}/districts';

  /// `endpoints.ts:248` — `locations.villages(districtId)`. **Paged**, and the
  /// API's own default page size is 200 (`:204`).
  ///
  /// The kernel path follows `meta.total_pages` to the end (L-7,
  /// `endpoints.ts:284-292`) — see `LocationRemoteDatasource.villages`.
  static String locationVillages(String districtId) =>
      '/locations/districts/${Uri.encodeComponent(districtId)}/villages';

  // ── The citizen's money (B6a) ──────────────────────────────────────────────
  //
  // `endpoints.ts:142-151`'s four `me.*` money members plus `:362`'s public
  // `payments.methods`. Additive only (SSD § 6.5, `B6-AC-13`): nothing above
  // changed, `baseUrl` and the release HTTPS guard are byte-identical.
  //
  // **Five of the six are authenticated `/me/*` reads and one write; the sixth
  // is the batch's only `anonymous: true` endpoint.** `/payment-methods` is
  // marked anonymous at `endpoints.ts:362` and was verified against live
  // staging for specs.md § 2.2 Finding H with a plain unauthenticated `curl` —
  // 200, seven rows. That matters beyond tidiness: the top-up sheet's method
  // list must populate for a citizen whose token has expired, and sending a
  // stale bearer to a public catalogue triggers a refresh round trip on a
  // request that never needed one.
  //
  // **`/applications` and `/applications/{id}/pay` are deliberately absent.**
  // They are B6b's two paths (specs.md § 5.1), and B6b is gated on B7a's
  // `features/application/` read slice. Adding them here would be the first
  // half of porting the pay path into a batch that § 2.3 rules does not own it.

  /// `endpoints.ts:147` — `me.wallet`. One object (`WalletOverview`), not paged.
  static const String meWallet = '/me/wallet';

  /// `endpoints.ts:148-149` — `me.walletEntries`. **Paged** (`api.paged`),
  /// called with `{page: N, per_page: 10}` (`WalletPage.tsx:117`).
  static const String meWalletEntries = '/me/wallet/entries';

  /// `endpoints.ts:150-151` — `me.topUpWallet`. A POST with the body
  /// `{amount_lak, method_code}` — **exactly two keys** (`B6-AC-33`).
  ///
  /// **This endpoint credits a real staging balance.** specs.md § 4.4 forbids
  /// executing it against any host, with no "small test amount" exemption. It
  /// is exercised only against a mock transport (`B6-AC-33`, `B6-AC-34`).
  static const String meWalletTopUp = '/me/wallet/topup';

  /// `endpoints.ts:142-143` — `me.transactions`. **Paged**, called with
  /// `{page: 1, per_page: 10}` (`WalletPage.tsx:111`).
  static const String meTransactions = '/me/transactions';

  /// `endpoints.ts:362` — `payments.methods`. **`anonymous: true`**, and a
  /// **plain array**, not paged.
  static const String paymentMethods = '/payment-methods';

  /// `endpoints.ts:144-145` — `me.transaction(receiptNo)`.
  ///
  /// **Transport only: no UI, no usecase, no BLoC event, no route**
  /// (specs.md § 6.4, `B6-AC-15`). `grep -rn "me.transaction\b" lcc-app/src/app`
  /// finds the definition and no consumer, so the shipped web app never calls
  /// it — the same measurement that removed `deleteNotification` (B9a) and
  /// `me.deactivate` (B8a) from their batches.
  ///
  /// B6 rules the other way *for the transport layer only*, on three grounds
  /// § 6.4 states: roadmap § B6 enumerates the endpoint by name, a receipt
  /// lookup by number has exactly one possible semantic so nothing is being
  /// invented, and B7 is its likely first consumer. What B9a refused was
  /// porting *UI* that does not exist; there is none here to refuse.
  ///
  /// A function with the segment percent-encoded, per the convention
  /// `newsArticle` / `helpArticle` establish above.
  static String meTransaction(String receiptNo) =>
      '/me/transactions/${Uri.encodeComponent(receiptNo)}';

  // ── Applications, the read half (B7a) ──────────────────────────────────────

  /// `endpoints.ts:321` — `applications.list`. **Paged**, Bearer.
  ///
  /// **No trailing slash.** `roadmap.md:378` and B7's dispatch both write
  /// `/applications/`; the source is
  /// `api.paged<ApplicationRow>("/applications", …)`. Both forms answer `401`
  /// unauthenticated, so the difference is not observable from outside — which
  /// is exactly why it has to be taken from `endpoints.ts` rather than probed
  /// (specs.md § 5.1).
  ///
  /// Two consumers with different parameters: `HistoryPage.tsx:85` (`per_page`
  /// 10, plus `status`/`search`) and `:103` (`per_page` 1, four count queries),
  /// and later `WalletPage.tsx:105` (`per_page` 50) — B6b.
  static const String applications = '/applications';

  /// `endpoints.ts:192` — `catalog.statusCatalogue`. **`anonymous: true`**.
  ///
  /// The one B7 endpoint fully exercisable without credentials, and therefore
  /// the one B7 fixture that is a real recording rather than a declared
  /// synthetic (specs.md § 6.12). Only `pipeline_order` is read; the nine-entry
  /// `statuses[]` is written and never consumed on the web (§ 6.9).
  static const String statusCatalogue = '/status-catalogue';

  // ── Applications, the detail half (B7b) ────────────────────────────────────
  //
  // Two paths, both Bearer, both `GET`, both **additive** — zero deletions and
  // no edit to any constant above, so B6b's pay path below and B8/B10 still
  // merge (specs.md § 3.3).
  //
  // **`DELETE /applications/{id}` is deliberately absent**, and it is the
  // fourth dead endpoint measured in this project rather than inferred:
  // `applications.cancel` is declared at `endpoints.ts:340` and
  // `grep -rn "applications.cancel" lcc-app/src` finds only that declaration —
  // no web component calls it. `application_repository.dart` records the same
  // for `removeAttachment`, and `ssd.md` § 5.1 rules that **B4** decides both
  // with a stated reason and that no earlier batch builds them speculatively.
  // B7b does not, even though the path sits inside its own feature's surface.
  //
  // ── B4 DECIDED: NOT PORTED ─────────────────────────────────────────────────
  //
  // The paragraph above reserved the question to B4. **B4 ran, and the answer
  // is that neither endpoint is ported in any form** — no constant here, no
  // `ApplicationRemoteDatasource` method, no repository method, no use case, no
  // UI (`GOR-245-b4-application-consolidation/specs.md` § 6.4, RULING 3,
  // adopted as the programme's decision at that document's § 10). It is a
  // refusal, not a deferral, and nothing above this line changed to say so —
  // `B6-AC-13` and `B8-AC-63` require this file's diff to be **additive**, so
  // the decision is appended rather than written over the question.
  //
  // B9's precedent (drop it) applies rather than B6's (keep the transport for a
  // named downstream consumer), on the two grounds B6's carve-out turned on and
  // neither of these clears:
  //
  //   * **`cancel` has more than one possible semantic.** `types.ts:476-483`
  //     models cancellation as a *guarded transition* carrying
  //     `requires_reason`, `requires_signature` and `requires_paid_fee`, on
  //     `ApplicationDetail.allowed_actions?` (`:489`) — a field **no component
  //     reads**. `applications.cancel(id)` takes an id and nothing else, so the
  //     client method cannot express the action the API models. Porting it
  //     ships a destructive, unguarded `DELETE` against a citizen's
  //     civil-registry case, which is a strictly worse artefact present than
  //     absent.
  //   * **There is no downstream consumer.** B4 is the *last* batch
  //     (`ssd.md:698`), so a constant added here is dead on the day it is
  //     written.
  //
  // `application_repository.dart` carries the same decision on the interface
  // side, including `removeAttachment`'s stronger ground — it is *uncallable*,
  // because no code path on either side ever holds an `Attachment.id`
  // (`addAttachment` discards its response at `ResidentCertificatePage.tsx:528`
  // and returns `Unit` in the port).
  //
  // **What would reopen it** (FU-3, so the reopening is a decision rather than
  // a rediscovery): a batch that ports a cancel affordance the web has since
  // grown, or one that reads `allowed_actions`.
  // `test/features/application/application_scope_test.dart` fails if a
  // constant, an interface member, or an `/attachments/{aid}` path reappears —
  // and carries the mutants that prove those guards can fire.

  /// `endpoints.ts:323` — `applications.get(id)`. One `ApplicationDetail`
  /// object, not paged, Bearer.
  ///
  /// A function with the segment percent-encoded, the convention `newsArticle`
  /// / `helpArticle` / `meTransaction` already establish. The id is a server
  /// identifier the citizen never types, so encoding it is defence against a
  /// value the backend chose rather than against user input — which is the
  /// case where a missing encode survives every test and fails in production.
  ///
  /// **404 is a rendered state, not an error state** (`HistoryDetailPage.tsx:201`,
  /// `B7-AC-54`): the detail page prints *"This application could not be
  /// found."* for a 404 and the API's own sentence for anything else. See
  /// `application_failures.dart`.
  static String application(String id) =>
      '/applications/${Uri.encodeComponent(id)}';

  /// `endpoints.ts:342` — `applications.timeline(id)`. One `CaseTimeline`
  /// object, Bearer.
  ///
  /// **Shared with B4** (`ssd.md` § 5.1). Noted here as well as on the
  /// repository method so the overlap is visible from the endpoint table, which
  /// is where a later batch looks first.
  static String applicationTimeline(String id) =>
      '/applications/${Uri.encodeComponent(id)}/timeline';

  // ── The pay path (B6b) ─────────────────────────────────────────────────────
  //
  // **One path, not the two specs.md § 5.1 lists for B6b.** That table was
  // written when `features/application/` did not exist; B7a has since landed
  // [applications] above, so B6b appends only the charge. Recorded here rather
  // than left to a reader's arithmetic — and it is also why the B6a block's
  // line *"`/applications` and `/applications/{id}/pay` are deliberately
  // absent"* is now half-stale. It is left byte-identical on purpose:
  // `B6-AC-13` requires **zero deletions** in this file's diff, and correcting
  // a comment would spend that budget on prose.

  /// `endpoints.ts:356` — `applications.pay(id, {method_code})`.
  ///
  /// **This endpoint debits a real balance against a real case.** specs.md
  /// § 4.4 forbids executing it against **any** host, absolutely, and forbids
  /// the loophole too: creating an application so that there is something to
  /// pay for is named as the one thing most forbidden (§ 4.4, security item 6).
  /// Every test of this path runs against `http_mock_adapter`.
  ///
  /// The body is **exactly one key** — `{"method_code": "<code>"}` (`B6-AC-36`)
  /// — and it is the method's `code`, never its id, its label or its kind.
  ///
  /// The segment is percent-encoded per the convention `newsArticle`,
  /// `helpArticle` and [meTransaction] already establish above.
  static String applicationPay(String id) =>
      '/applications/${Uri.encodeComponent(id)}/pay';

  // ── Applications, the write half (F1) ──────────────────────────────────────
  //
  // **Two additions, not four.** `create` is `POST` on [applications] and
  // `update` is `PATCH` on [application], both of which B7a and B7b already
  // landed above — a verb is not an endpoint, so adding `applicationCreate`
  // and `applicationUpdate` constants would be two names for two strings that
  // already exist and two places for a later reader to disagree with himself.
  //
  // **`/applications/{id}/pay` is NOT added here**, and its absence is a
  // ruling rather than an omission: `specs.md` § 6.2 gives B6b the pay
  // capability outright and `F1-AC-25` checks that F1 did not take it. It is
  // above, written by B6b, and F1 reads it through nothing at all — the pay
  // call reaches F1 as an injected function it does not implement.
  //
  // `cancel` (`endpoints.ts:340`) and `removeAttachment` (`:353`) stay absent
  // for the reason the B7b block above already records: `roadmap.md`:399
  // reserves both to **B4** with a written decision and forbids any earlier
  // batch building them speculatively (`F1-AC-19`, `F1-AC-20`).

  /// `endpoints.ts:344-351` — `applications.addAttachment(id, file, slot, kind)`.
  /// **multipart/form-data**, Bearer.
  ///
  /// Four parts and no more: `file`, `slot`, `kind`, and `label` only when the
  /// caller supplies one (`F1-AC-22`). Resident sends the first three
  /// (`ResidentCertificatePage.tsx:528`).
  ///
  /// Uploads are **sequential** in `attachmentsToSend()`'s fixed order and an
  /// already-uploaded slot is skipped on a retry (`:526-530`) — that is the
  /// caller's loop, not this constant's, and it is asserted at `F1-AC-58`.
  static String applicationAttachments(String id) =>
      '/applications/${Uri.encodeComponent(id)}/attachments';

  /// `endpoints.ts:338` — `applications.submit(id)`. Bearer.
  ///
  /// The body is an **empty object**, `{}` — not null and not an omitted body
  /// (`F1-AC-23`). `client.ts:242` is a bare `JSON.stringify(options.body)`, so
  /// the three serialise to `"{}"`, `"null"` and no body at all: three
  /// different requests, one of which the API accepts.
  ///
  /// Answers the **decided** case, which is where `fee_lak` comes from — the
  /// value Resident's `if (decided.fee_lak > 0)` branch reads before it does or
  /// does not call pay (`:535`).
  static String applicationSubmit(String id) =>
      '/applications/${Uri.encodeComponent(id)}/submit';

  // ── Issued certificates (B5) ───────────────────────────────────────────────
  //
  // **Two constants, and eight endpoints deliberately absent.** B5's dispatch
  // named ten; specs.md § 6.0 adjudicated them row by row and two survived.
  // Additive only (SSD § 6.5, `B5-AC-13`): nothing above changed, `baseUrl` and
  // the release HTTPS guard are byte-identical.
  //
  // The eight, each with its ground — named by their `endpoints.ts` symbol
  // rather than by their path, because `B5-AC-6` … `B5-AC-11` are **greps over
  // `lib/`** and a comment quoting the path is a hit exactly like a constant
  // would be. specs.md § 2.2 carries the paths; this block carries the reasons.
  //
  // * **`me.documents` (`:115`)** — B8's, and already shipped as [meDocuments]
  //   above (specs.md Finding G). B5 adds nothing here.
  // * **`me.document(id)` (`:116`)** — dead, and the B8a block above already
  //   refused it. Its one call site (`DocumentViewer.tsx:45`) is gated
  //   `enabled: Boolean(documentId)` (`:47`) and **neither** mount site passes
  //   that prop: `AccountPage.tsx:740-746` passes a static URL,
  //   `HistoryDetailPage.tsx:649-656` passes a spec. That omission is
  //   **upheld, not reversed** (Finding D, `B5-AC-6`).
  // * **the QR sub-path (`:133`)** — defined and never called; the payload the
  //   card draws comes from the `Certificate` object itself
  //   (`types.ts:638-639`, rendered at `:483`). Finding B, `B5-AC-7`.
  // * **the two `verification.*` symbols (`:385-390`)** — the whole namespace
  //   has **zero importers**. Both answer `200` on the live server, and that is
  //   not reachability: `ADR-0001` puts the running web client first, so an
  //   endpoint only the API knows about has no client behaviour to mirror.
  //   Finding A, `B5-AC-8`, `B5-AC-9`.
  // * **the citizen-milestone list (`:118`)** — it and its type are defined and
  //   never consumed; there is no screen, card, row or list for them anywhere
  //   in the client. Finding C, `B5-AC-10`.
  // * **the household-register read and its copy request (`:127-129`)** —
  //   **F4's, whole.** The 596-line page at `:200`/`:204` of its own component
  //   is the only consumer of each, `roadmap.md`:344 and `fsd.md`:138 both give
  //   that page to F4, and splitting the POST from the single page that fires
  //   it would give two batches one wire call. Finding F, `B5-AC-11`.
  //
  // Same disposition this file already took for `DELETE /me/account`,
  // `deleteNotification`, `/reference-lists`, `/news/:slug` and
  // `DELETE /applications/{id}`.

  /// `endpoints.ts:131` — `me.certificates`. A **plain array**, not paged,
  /// Bearer.
  ///
  /// Consumed at `HistoryDetailPage.tsx:149`, and **not at mount**: the hook
  /// carries `enabled: Boolean(isIssued)` and `enabled` is in `useQuery`'s own
  /// dependency array (`hooks.ts:89`), so the request fires when the detail
  /// resolves and the case turns out to be issued (`B5-AC-35`, `B5-AC-36`).
  static const String meCertificates = '/me/certificates';

  /// `endpoints.ts:132` — `me.certificate(id)`. One `Certificate` object,
  /// Bearer.
  ///
  /// A function with the segment percent-encoded, the convention
  /// [meNotificationRead], `newsArticle`, `helpArticle` and [meTransaction]
  /// establish above. The id is `detail.certificate_id` — a server identifier
  /// the citizen never types, so encoding it defends against a value the
  /// backend chose rather than against user input, which is the case where a
  /// missing encode survives every test and fails in production.
  ///
  /// Fired only when **all four** of the source's conjuncts hold — issued, a
  /// `certificate_id` exists, the list did not already match, and the list is
  /// no longer in flight (`:158`, `B5-AC-39`).
  static String meCertificate(String id) =>
      '/me/certificates/${Uri.encodeComponent(id)}';

  // ── Issued certificates, the v2 file & QR sub-paths (e-certificates) ───────
  //
  // **Supersedes this block's own B5-AC-7 adjudication above** (2026-10-21):
  // MOBILE-API-E-CERTIFICATES.md — the backend team's API guide of that date —
  // introduces `GET /me/certificates/{id}/file` and `GET
  // /me/certificates/{id}/qr` as real, bearer-authenticated citizen endpoints
  // (§ Citizen endpoints), where the old ruling refused the QR sub-path
  // because the shipped web client never called it. The endpoints now have a
  // contract, a consumer in this app (the documents datasource, same file the
  // two B5 constants above are read from) and a product requirement behind
  // them; the dead-end refusal does not survive a live endpoint.
  //
  // **Bearer by header, never by URL.** The guide is explicit — "Download
  // with the bearer header (no token in the URL)" (§ Citizen endpoints,
  // File). These paths therefore carry no token and no `Authorization`
  // anything: the `AuthInterceptor` attaches the header, and the query map
  // carries only `layout` and, for inline viewing, `disposition=inline`.
  //
  // Both are functions with the segment percent-encoded, the convention
  // [meCertificate] establishes immediately above.

  /// `GET /me/certificates/{id}/file` — the PDF bytes (raw, not the
  /// envelope; the one documented envelope exception). The layout choice
  /// (`card` | `booklet`) is a **query parameter** the caller passes to
  /// `ApiClient.getBytes`, never a path segment; `disposition=inline` is
  /// likewise appended as a query value when the caller wants to view rather
  /// than download. The `Content-Disposition` filename and `X-Content-SHA256`
  /// response headers are read off the answer by the datasource.
  static String meCertificateFile(String id) =>
      '/me/certificates/${Uri.encodeComponent(id)}/file';

  /// `GET /me/certificates/{id}/qr` — the QR payload the certificate itself
  /// prints, fixed at issue (§ Citizen endpoints, QR paragraph). Drawn on
  /// screen from `payload`; `verify_url` beside it is the same link built
  /// from the server's *current* setting and can differ for older issues.
  static String meCertificateQr(String id) =>
      '/me/certificates/${Uri.encodeComponent(id)}/qr';
  // ── The household record (F4) ──────────────────────────────────────────────
  //
  // **Two constants, and they are the only two this feature has.** FamilyBook
  // is the one certificate-route page that never touches `/applications`:
  // `FamilyBookPage.tsx:16` imports `me` and nothing else, and `fsd.md`:820
  // measures zero `/applications` calls, zero uploads and no draft. So none of
  // the write half above is reachable from it and none of it is reused.
  //
  // Both are authenticated `/me/*` reads-and-one-write — neither carries
  // `anonymous: true` at `endpoints.ts:128-129` — so both need step 2's
  // `ApiClient` instance for the Auth/Refresh interceptor chain.
  //
  // **`roadmap.md`:417 lists both of these under B5, and that line is stale.**
  // B5's component makes ZERO API calls (`roadmap.md`:50, `:621`), and a batch
  // whose component makes no API call cannot own an endpoint list; the two
  // paths are a leftover from the pre-F0…F4 roadmap. They are F4's
  // (`specs.md` § 2.2 Finding E), and the roadmap correction is FU-3, the
  // architect's. No criterion here depends on that correction landing.
  //
  // Neither is parameterised, so neither needs the percent-encoding convention
  // `newsArticle` / `helpArticle` / [meTransaction] establish above.

  /// `endpoints.ts:128` — `me.familyBook`. One object (`FamilyBook`), not
  /// paged, Bearer.
  ///
  /// **A 404 is a normal answer, not a fault.** `client.ts:92-94` sets
  /// `isNotFound` and `FamilyBookPage.tsx:305`'s `error && !error.isNotFound`
  /// routes it past the error card into *"No household on file"* (`:326`).
  /// Measured 2026-08-13 against the one available staging account:
  /// `404 {"success":false,"message":"family book not found","code":"NOT_FOUND"}`
  /// (`manifest-authenticated.md`:229). That is the only branch of this
  /// endpoint any reference in this repository exercises.
  static const String meFamilyBook = '/me/family-book';

  /// `endpoints.ts:128-129` — `me.requestFamilyBookCopy`. A POST whose body is
  /// **exactly one key**, `{"reason": "<string>"}` (`F4-AC-22`), answering the
  /// created case as an `ApplicationRow`.
  ///
  /// **The displayed fee is never charged here.** `FamilyBookPage.tsx:534`
  /// renders `formatLak(copyFee, lang)` on the review step from the `/services`
  /// catalogue, and the submit path calls nothing else — no
  /// `/applications/{id}/pay`, no wallet, no payment sheet (`fsd.md`:818).
  ///
  /// **Not reachable on any account this programme has.** `requestCopy` sits
  /// past the `!book` guard at `:326`, so with no household there is no CTA to
  /// press; `oracle_coverage.yaml`'s `unreachable:` row for the `/reason` leaf
  /// records it, and the Tier 0 leaf therefore stays Entry-B `transcribed`
  /// (`F4-NV-3`). It is exercised against a mock transport only.
  static const String meFamilyBookRequestCopy = '/me/family-book/request-copy';
}
