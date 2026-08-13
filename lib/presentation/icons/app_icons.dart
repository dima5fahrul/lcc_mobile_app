/// Icon-name resolution — **two scopes, one asset set** (specs.md § 6.3.5).
///
/// ## The rule this file exists to enforce
///
/// The web has **two** icon registries with different coverage and the same
/// fallback:
///
/// * `ServicePage.tsx:104` — 54 names, `serviceIcon()` falls back to `FileText`
/// * `HelpCenterPage.tsx:35` — 12 names, `icon()` falls back to `FileText`
///
/// Three names the API actually sends — `Mail`, `Phone`, `Rocket` — are in
/// Help's registry and **not** in Service's.
///
/// Merging them into one 86-name lookup is the obvious simplification and it is
/// wrong. The day `/services` returns `icon: "Rocket"`, the web renders
/// `FileText` and a merged Flutter registry renders a rocket — an observable
/// divergence, invisible today because it does not occur, and discovered later
/// as a fidelity failure nobody can explain. Scoping the tables costs nothing
/// (the SVG assets are shared through [lucideRegistry]) and is faithful by
/// construction.
///
/// ## The fallback
///
/// [fallback] is `FileText` — **the source's own** neutral placeholder, not a
/// bespoke one. § II.R-F(c) requires "a neutral placeholder — never a crash,
/// never a blank"; porting the source's satisfies that mandate *and* ADR-0001's
/// port-faithfulness at once, where substituting a different glyph would
/// satisfy the letter of the mandate and violate the ADR.
///
/// **It is not dead code.** Measured today: all 53 API-supplied names resolve
/// to a real glyph under their correct scope; zero hit the fallback. The
/// catalogue can add an icon at any time and an unbundled name is a *normal
/// runtime state, not an error* — which is why it is tested with a synthetic
/// name rather than assumed.
library;

import 'lucide_registry.g.dart';

/// The two resolver scopes. Never instantiated.
abstract final class AppIcons {
  /// `ServicePage.tsx:113` / `HelpCenterPage.tsx:51` — both registries' own
  /// unknown-name fallback.
  static const String fallback = 'FileText';

  /// `ServicePage.tsx:104`'s `ICONS`, transcribed in the source's declaration
  /// order (54 names). Consumed by the service catalogue and, from B2b, Home.
  static const Set<String> serviceScope = <String>{
    'Users', 'Plane', 'Wallet', 'HeartPulse', 'Bus', 'Building2',
    'GraduationCap', 'HandHeart',
    'Home', 'UserCircle', 'Shield', 'FileText', 'ClipboardList', 'Baby',
    'BookOpen', 'IdCard',
    'Users2', 'Tag', 'StickyNote', 'Globe2', 'Landmark', 'Receipt', 'Zap',
    'AlertOctagon', 'Coins',
    'HeartHandshake', 'Heart', 'HeartCrack', 'UserMinus', 'CalendarCheck',
    'Syringe',
    'Stethoscope', 'Car', 'CarFront', 'Route', 'Store', 'BadgeCheck',
    'Building', 'ScrollText',
    'MapPinned', 'Hammer', 'Map', 'Gavel', 'Siren', 'School', 'Award',
    'Tractor', 'PiggyBank',
    'HandCoins', 'Accessibility', 'MessageCircle', 'MapPin', 'Search',
    'ChevronRight',
  };

  /// `HelpCenterPage.tsx:35`'s `ICONS` (12 names). Consumed by the help centre.
  static const Set<String> helpScope = <String>{
    'Rocket',
    'FileText',
    'Wallet',
    'Shield',
    'ShieldCheck',
    'UserCircle',
    'Phone',
    'Mail',
    'MessageCircle',
    'MapPin',
    'BookOpen',
    'LifeBuoy',
  };

  /// Resolves an API-supplied icon name against the **service** registry.
  ///
  /// Returns the lucide name to render — the input when it is in scope, and
  /// [fallback] otherwise. Never throws, never returns null: an unrecognised
  /// name is ordinary runtime data, not an error condition.
  ///
  /// Port of `serviceIcon()` (`ServicePage.tsx:112-114`), including its
  /// treatment of `null`/empty as "unknown".
  static String service(String? name) => _resolve(name, serviceScope);

  /// Resolves an API-supplied icon name against the **help** registry.
  ///
  /// Port of `icon()` (`HelpCenterPage.tsx:51-53`). Note the source's second
  /// parameter (`fallback = FileText`) is never passed a different value at any
  /// call site, so it is not reproduced as a parameter here; [fallback] is the
  /// one answer.
  static String help(String? name) => _resolve(name, helpScope);

  /// `(name && ICONS[name]) || FileText` — the source's expression, with the
  /// extra guard that a name in scope must also be a name that was bundled.
  /// The two sets cannot drift apart silently (a test asserts every scope
  /// member is in [lucideRegistry]), but a resolver that can return a name with
  /// no asset behind it would turn a generation slip into a runtime blank.
  static String _resolve(String? name, Set<String> scope) {
    if (name == null || name.isEmpty) return fallback;
    if (!scope.contains(name)) return fallback;
    if (!lucideRegistry.containsKey(name)) return fallback;
    return name;
  }

  /// The bundled asset path for a lucide name, falling back the same way.
  ///
  /// The registry key, the SVG file name and the string the API sends are all
  /// the same token (§ 6.3.3), so this is a lookup and not a mapping.
  static String assetFor(String name) =>
      lucideRegistry[name] ?? lucideRegistry[fallback]!;
}
