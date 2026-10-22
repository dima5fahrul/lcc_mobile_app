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
///   match of it: go_router prefers the exact segment over the parameter, and
///   `file-check` is not a certificate-code shape, so the two cannot collide.
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
