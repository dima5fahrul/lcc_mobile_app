/// The verify feature's three route paths — the frozen literals, declared
/// HERE rather than inline in `app_name_routes.dart` for the same reason
/// `api_endpoint.dart` declares `verifyByCode` here-beside: the
/// `documents_scope_test.dart` B5-AC-8 guard bounds every `/verify` literal
/// to `lib/features/verify/**` + the endpoint file, and route paths ARE
/// `/verify` literals. Declaring them in the feature keeps the guard's
/// bounded-prefix claim true with zero edits to it.
///
/// ## The three shapes the guide names (§ QR codes and deep links)
///
/// * `/verify` — the typed entry page (the retype affordance, Task 5's
///   scanner target).
/// * `/verify/:code` — the older-certificates deep-link form
///   (`https://<api-host>/verify/<code>`), last segment is the code.
/// * `/v/:code` — the portal's current form
///   (`https://<portal-host>/v/<code>`). Task 7's PDF-check page joins them
///   as `/verify/file-check` — a *literal sibling* of `:code`'s parent, not a
///   match of it. **Corrected 2026-10-22, fix round 2:** go_router does NOT
///   automatically prefer a literal segment over a parameterised sibling —
///   its matcher walks a route's children in LIST ORDER and stops at the
///   first match (`match.dart`'s `_matchByNavigatorKeyForGoRoute`). The two
///   cannot collide only because `app_routes.dart` declares `file-check`
///   BEFORE `:code` in `/verify`'s `routes:` list; that order is itself
///   load-bearing and is asserted end-to-end by
///   `test/utils/routes/verify_routes_test.dart`, which drives the real
///   table rather than a hand-built stub router.
///
/// All three are **public**: the endpoints are anonymous ("Two endpoints
/// work without login", § Public verification endpoints), so none may join
/// `AppRoutes._protectedPaths` — a signed-out citizen verifying a
/// certificate is the guide's own first use case.
library;

/// The typed entry page.
const String kVerifyEntryPath = '/verify';

/// `/verify/:code` — the result page by code, the older deep-link form.
const String kVerifyResultPath = '/verify/:code';

/// `/v/:code` — the result page by code, the portal's current form.
const String kVerifyShortResultPath = '/v/:code';

/// `/verify/file-check` — the on-device PDF check (Task 7 implements the
/// page; Task 4 mounts the route so the result page's gate button can be
/// wired now).
const String kVerifyFileCheckPath = '/verify/file-check';

/// The query-param key carrying the `verify_code` being viewed into
/// `/verify/file-check` — `app_routes.dart`'s `kFromQueryParam`
/// encode-on-write/decode-on-read pairing, on a one-write-one-read scale:
/// `VerifyResultPage`'s button writes it with `Uri.encodeComponent`, this
/// route's own builder reads it back with `state.uri.queryParameters`
/// (which decodes it), and `VerifyFileCheckPage` takes the decoded string as
/// a plain constructor argument, never resolving a router itself. A query
/// param rather than a path segment because `/verify/file-check` is declared
/// as a path LITERAL sibling of `/verify/:code` (see this file's own doc) —
/// adding a second path segment would turn it back into a parameterised
/// route and reopen the exact collision this file exists to avoid.
const String kVerifyFileCheckCodeParam = 'code';
