/// **C-2 — one availability predicate, one place** (SSD § 13.2, specs.md § 6.4).
///
/// "Can the citizen actually go somewhere by tapping this service?" is asked in
/// exactly two places in the whole app: the catalogue card's tap handler
/// (B2a, below) and Home's "Apply now" (B2b). Before this class the answer was
/// inlined in the React page as `if (s.tab) onTabChange(s.tab)` — one
/// expression, one call site, no problem. Two call sites in two features with
/// the same expression copied is how the answers drift, so it is a value object
/// with a test rather than a line of code written twice.
///
/// ## What it must NOT be (C-3, and this is the whole point)
///
/// > **Never gate on `route_path != null` or `form_schema.published`.**
///
/// Measured on staging: **6 of 43** services carry a `route_path`. Both
/// readings of `route_path` are wrong as a gate —
///
/// * as "has a destination" it promises whatever the API says, whether or not
///   this build has the page, and the tap either crashes or lands on a 404;
/// * as "is a real service" it hides 37 services the web renders in full.
///
/// The authority is the **client route registry**: a destination exists iff
/// this build has a route mounted at it. `route_path` supplies the *name* of
/// the destination and nothing else — the same role it plays as the fidelity
/// harness's page-pairing seed (§ II.R-E).
///
/// ## Today's answer, after B12
///
/// `AppNameRoutes` mounts **all six** certificate paths, so [destinationFor]
/// answers **six of the 43** — `resident`, `birth`, `death`, `marriage`,
/// `divorce`, `family-book`, each with its own `route_path` — and **null for
/// the other 37**, whose taps stay silent no-ops. That is C-4 unchanged, not a
/// new asymmetry: the card renders fully styled and the tap does nothing,
/// exactly as `ServicePage.tsx:502-505` behaves for the rows with no `tab`
/// (`onClick={() => { if (s.tab) onTabChange(s.tab); }}` — note the absent
/// `else`). **No row in the catalogue now names a destination this build fails
/// to mount**, which is the invariant `B12-AC-30` states as a set equality: the
/// rows with a non-empty `route_path` and the rows that resolve are the same set.
///
/// ## B12 flipped that answer with ZERO code changes in this file
///
/// An earlier revision of this paragraph predicted it: *"When F1 mounts
/// `/service/resident-certificate`, that service starts navigating and the
/// other 42 do not, with no change to this file."* B12 is the event that
/// paragraph anticipated, arriving from a different batch than it expected and
/// carrying all six at once. [destinationFor], [isAvailable], [tabOf] and
/// [forApp] are byte-identical before and after; the only edit was six members
/// added to `AppNameRoutes.registered`. That property **is** what C-2 and C-3
/// were designed to buy, and it is why a predicate change here would be the
/// exact thing C-2 exists to prevent.
///
/// ## The recommendation this class deliberately does not implement
///
/// SSD § 13.3 recommends replacing the dead tap with a visibly disabled card
/// carrying the already-translated `service.comingSoon` string. It is a better
/// product; it is also **a user decision plus an ADR** (FU-7), and B2 must not
/// quietly implement it. [isAvailable] exists so that when the decision is
/// taken the card can consult it — the seam is here, the behaviour is not.
library;

import '../../../utils/routes/app_name_routes.dart';
import 'entities/service.dart';

/// Resolves a catalogue row to a client destination, or to nothing.
class ServiceAvailability {
  const ServiceAvailability({required this.registeredRoutes});

  /// The paths this build actually mounts. Injected rather than read from
  /// [AppNameRoutes] directly so a test can prove both branches — a registry
  /// that mounts a given certificate path and one that does not — against the
  /// same catalogue rows, which is what makes C-3 falsifiable rather than
  /// merely stated.
  final Set<String> registeredRoutes;

  /// The predicate as the app is built right now.
  static const ServiceAvailability forApp =
      ServiceAvailability(registeredRoutes: AppNameRoutes.registered);

  /// `"/service/resident-certificate"` → `"resident-certificate"`.
  ///
  /// Port of `routeToTab` (`ServicePage.tsx:118-122`), including its treatment
  /// of an empty last segment as "no tab".
  static String? tabOf(String routePath) {
    if (routePath.isEmpty) return null;
    final List<String> parts =
        routePath.split('/').where((String s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.last;
  }

  /// The client path to navigate to when [service] is tapped, or null when
  /// this build has nowhere to send the citizen.
  String? destinationFor(Service service) {
    final String? tab = tabOf(service.routePath);
    if (tab == null) return null;

    // The web's `TAB_TO_PATH` puts every certificate tab under `/service/`, and
    // `AppNameRoutes` mirrors that shape — as six full literal path constants
    // whose *values* live under `/service/`, not as route children of
    // `AppRoutes.service`. B12 § 6.3 RULING 2: all six mount OUTSIDE the shell,
    // because none of their tabs is in the source's `MAIN_TABS`. The path shape
    // and the route parentage are independent, and only the path shape is what
    // this composition depends on.
    final String candidate = '${AppNameRoutes.service}/$tab';
    return registeredRoutes.contains(candidate) ? candidate : null;
  }

  /// True when tapping [service] goes somewhere. The complement is a no-op,
  /// never an error — an unrouted service is ordinary catalogue data.
  bool isAvailable(Service service) => destinationFor(service) != null;
}
