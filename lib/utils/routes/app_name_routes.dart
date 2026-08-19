/// Named path constants for the LCC citizen portal.
///
/// Ported from `lcc-app/src/app/routes.ts` (`TAB_TO_PATH`). Every primary
/// tab has a real path so the bottom nav can render as real anchors and deep
/// links resolve without a server-side rewrite.
///
/// **B12 mounts the six certificate sub-routes** (`/service/resident-certificate`,
/// `/service/birth-declaration`, `/service/death-declaration`,
/// `/service/marriage-certificate`, `/service/divorce-certificate`,
/// `/service/family-book`). They are declared below as **separate top-level
/// constants** and mounted by [AppRoutes] as **top-level `GoRoute`s outside the
/// `ShellRoute`** — not as children of `AppRoutes.service`, which is what an
/// earlier revision of this paragraph predicted.
///
/// That prediction was measured wrong (`specs.md` § 2.2 Finding D): none of the
/// six certificate tabs is in the source's `MAIN_TABS` (`Layout.tsx:46-52`), so
/// `isSubPage` is true for all six (`:300`) and the source renders each with the
/// bottom nav translated off screen and the chat launcher suppressed
/// (`:385-386`). A `GoRoute` child of `AppRoutes.service` inherits `AppShell`,
/// which would put a brand bar, a five-destination bottom nav and a chat FAB on
/// every frame of a seven-step form the source renders full-frame. B12 § 6.3
/// RULING 2 overturns it; `B12-AC-19` and `B12-AC-20` are what keep it overturned.
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

  /// `/news/:slug` — the app's **first parameterised route** (B2c).
  ///
  /// The template, not a location: `context.go` is called with
  /// `'$news/${article.slug}'`, and this constant is the `GoRoute.name` so the
  /// route table keeps N-4's "the name is the path" convention with no second
  /// surface to drift.
  ///
  /// Deliberately **not** in [registered]: that set is `ServiceAvailability`'s
  /// client route registry (SSD § 13.2 C-2), which answers "does this service
  /// have a page" by exact match against a service's `route_path`. A template
  /// containing `:slug` can never equal one, and adding it would put a string
  /// in the registry that no lookup can ever hit — a member that means nothing
  /// is worse than an absent one.
  static const String newsDetail = '/news/:slug';

  // ── Certificate sub-routes (B12, port of `TAB_TO_PATH`'s last six) ──────
  //
  // Byte-identical to `lcc-app/src/app/routes.ts:21-26`, **in that file's
  // order**, so the two lists diff line for line. Declared as full literals
  // rather than as `'$service/resident-certificate'` compositions: the string
  // is a frozen wire-visible path (`GOR-245` § 4.2) and a composition hides a
  // typo in the segment behind a constant that still reads correctly.
  //
  // **The constant name is the TAB ID in lowerCamelCase, not the page class
  // name** — `birthDeclaration`, not `birthCertificate`, because
  // `ServiceAvailability.destinationFor` composes `/service/${tabOf(route_path)}`
  // and compares by membership against [registered]. A name that drifts from
  // the tab id produces a mounted route no catalogue row can ever reach, and
  // nothing fails: the tap stays a silent no-op, which is indistinguishable
  // from C-4's intended behaviour for the 37 unrouted rows.

  /// `routes.ts:21`. F1's page (`ResidentCertificatePage`).
  static const String residentCertificate = '/service/resident-certificate';

  /// `routes.ts:22`. F2's (`BirthDeclarationPage`).
  static const String birthDeclaration = '/service/birth-declaration';

  /// `routes.ts:23`. F2's (`DeathDeclarationPage`).
  static const String deathDeclaration = '/service/death-declaration';

  /// `routes.ts:24`. F3's (`MarriageCertificatePage`).
  static const String marriageCertificate = '/service/marriage-certificate';

  /// `routes.ts:25`. F3's (`DivorceCertificatePage`).
  static const String divorceCertificate = '/service/divorce-certificate';

  /// `routes.ts:26`. F4's (`FamilyBookPage`).
  static const String familyBook = '/service/family-book';

  // ── Debug-only route (boilerplate parity) ───────────────────────────────
  /// Only mounted in debug builds — see the `if (kDebugMode)` guard in
  /// [AppRoutes]. Backed by the debug HTTP inspector screen.
  static const String debug = '/debug';

  // ── The registry (SSD § 13.2 C-2) ───────────────────────────────────────
  /// Every path this build mounts.
  ///
  /// This is the **authority** `ServiceAvailability` consults: a catalogue row
  /// is tappable iff its destination is in here. C-3 forbids gating on the
  /// API's `route_path`, so something client-side has to answer "does this
  /// build have that page?", and a set that sits beside the constants it
  /// mirrors is the cheapest thing that cannot go stale unnoticed — a test
  /// asserts it holds every constant declared above.
  ///
  /// [debug] is included: it is a real mounted route in the builds that have
  /// it, and excluding it would make this set mean "release routes", which is
  /// a second, subtler thing to keep in step.
  ///
  /// **B12 added the six `/service/*` certificate paths**, and that is the
  /// largest citizen-visible change in that batch — made here, in a `const Set`,
  /// with no edit to `ServiceAvailability` at all (B12 § 6.7, RULING 5).
  ///
  /// Before B12 this set held nine paths, none of them a certificate route, so
  /// `destinationFor` answered null for all 43 catalogue rows and **every tap
  /// was a no-op**. After B12 the six rows that carry a `route_path` navigate
  /// and the other 37 still do not — which is C-4 unchanged, not a new
  /// asymmetry: `ServicePage.tsx:502-505` is `onClick={() => { if (s.tab)
  /// onTabChange(s.tab); }}`, note the absent `else`. No row in the catalogue
  /// now names a destination this build fails to mount.
  ///
  /// **Membership and the constant are two independent edits, and both are
  /// required.** A constant with no membership mounts a route the catalogue
  /// cannot see; a membership with no route makes `destinationFor` promise a
  /// destination that fails to match. `B12-AC-37` is the control that proves
  /// they are independent — it removes [familyBook] from this set while leaving
  /// its `GoRoute` mounted, and records that the route stays reachable by URL
  /// while the catalogue goes blind to it.
  static const Set<String> registered = <String>{
    home,
    signin,
    service,
    history,
    wallet,
    account,
    help,
    news,
    debug,
    // B12 — the six, in `routes.ts:21-26` order.
    residentCertificate,
    birthDeclaration,
    deathDeclaration,
    marriageCertificate,
    divorceCertificate,
    familyBook,
  };
}
