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
}
