/// Named path constants for the LCC citizen portal.
///
/// Ported from `lcc-app/src/app/routes.ts` (`TAB_TO_PATH`). Every primary
/// tab has a real path so the bottom nav can render as real anchors and deep
/// links resolve without a server-side rewrite.
///
/// P0-3 surface only — the certificate sub-routes
/// (`/service/resident-certificate`, `/service/birth-declaration`, ...) are
/// batched into the next P0 stage and deliberately omitted here. When those
/// land they will be added as `GoRoute` children under `AppRoutes.service`,
/// not as separate top-level constants.
///
/// Mirrors the flutter-boilerplate `app_name_routes.dart` layout: a single
/// class of `static const String` path constants consumed by both the
/// `GoRouter` config ([AppRoutes]) and call sites that need a path or name.
library;

class AppNameRoutes {
  AppNameRoutes._();

  // ── Primary tabs (port of `TAB_TO_PATH`) ────────────────────────────────
  /// Home tab. Alias of the root path.
  static const String home = '/';

  /// Sign-in / auth tab. Whole-frame page, no bottom nav.
  static const String signin = '/signin';

  static const String service = '/service';
  static const String history = '/history';
  static const String wallet = '/wallet';
  static const String account = '/account';
  static const String help = '/help';
  static const String news = '/news';

  // ── Debug-only route (boilerplate parity) ───────────────────────────────
  /// Only mounted in debug builds — see the `if (kDebugMode)` guard in
  /// [AppRoutes]. Backed by the debug HTTP inspector screen.
  static const String debug = '/debug';
}
