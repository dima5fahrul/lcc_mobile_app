/// The **composition seam** for the splash — B9a's slot pattern, reused
/// verbatim (§ 6.9).
///
/// ## The constraint this exists to satisfy
///
/// `SplashScreens.tsx` imports two things from other pages:
///
/// * `:13` `import { LaoIdCard } from "./Hero"` — slide 3 renders the **real**
///   Home card, and the source says why in the same file (`:155`): *"so what
///   the slide promises is exactly what the user meets after signing in."*
///   Substituting a look-alike is a fidelity failure Tier 1 catches.
/// * `:14` `import slideBg from "../../imports/hero-bg.jpg"` — the shared
///   backdrop photograph, framed differently per slide.
///
/// Both live behind **G-L7** on the Flutter side:
///
/// * `lao_id_card.dart` is under `features/home/presentation/widgets/`, and
///   G-L7 forbids any `lib/presentation/**` file importing
///   `features/*/presentation/**` (`layering_rules.dart`:554-568). That is a
///   failing build, not a style objection.
/// * `hero-bg.webp` is a **Tier A** asset, and `tier_a_asset_test.dart` fails
///   the build if its path is written anywhere but inside `TierAImage` — which
///   is also under `features/home/presentation/widgets/`. Same wall, different
///   guard.
///
/// So `SplashScreens` names neither. It takes the two as parameters, and the
/// **route/composition layer** (`lib/utils/routes/app_routes.dart`) — which is
/// not under `lib/presentation/**`, and is already the one sanctioned place to
/// resolve from a container (CR-1) — assembles them. G-L7 stays green with a
/// **third** proven consumer after B9a's bell and chat launcher.
///
/// ## Why a builder and not a widget for the backdrop
///
/// `TierAImage` needs the **logical paint width** to size its decode
/// (B2-AC-31: eight 864×1152 photographs decoded at full size is 31.8 MB of
/// image cache). That width is only known inside the splash's own layout, so
/// the slot has to be a function of it rather than a pre-built widget. Passing
/// a pre-built one would mean guessing 390 px and re-introducing the decode
/// waste B2-AC-31 exists to prevent.
library;

import 'package:flutter/widgets.dart';

/// Builds slide *n*'s backdrop photograph, framed at [alignment] and decoded
/// for a box [paintWidth] logical pixels wide.
///
/// [alignment] is `object-position` translated: CSS `50% 42%` is the point of
/// the image that lands at the centre of the box, and Flutter's
/// [Alignment] maps `0%…100%` onto `-1…+1`, so `50% 42%` is
/// `Alignment(0.0, -0.16)`. [kSplashBackdropAlignments] holds the three the
/// source specifies, already converted.
typedef SplashBackdropBuilder = Widget Function(
  Alignment alignment,
  double paintWidth,
);

/// `object-position` → [Alignment] for the three slides, in slide order.
///
/// `SplashScreens.tsx`:172 `"50% 42%"`, `:183` `"22% 55%"`, `:194` `"78% 48%"`.
/// The conversion is `2 × p − 1` per axis, which is exact for all six values:
///
/// | source | x / y | Alignment |
/// |---|---|---|
/// | `50% 42%` | 0.50 / 0.42 | `(0.0, −0.16)` |
/// | `22% 55%` | 0.22 / 0.55 | `(−0.56, 0.10)` |
/// | `78% 48%` | 0.78 / 0.48 | `(0.56, −0.04)` |
///
/// Stated as a table because a reviewer checking the port against the `.tsx`
/// otherwise has to redo the arithmetic three times.
const List<Alignment> kSplashBackdropAlignments = <Alignment>[
  Alignment(0.0, -0.16),
  Alignment(-0.56, 0.10),
  Alignment(0.56, -0.04),
];
