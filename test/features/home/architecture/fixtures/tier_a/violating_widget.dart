/// **The negative control for B2-AC-31.** A deliberately violating call site.
///
/// This file is never compiled into the app and never imported by a test — it
/// is *read as text* by `tier_a_asset_test.dart`, which points the production
/// scanner at this directory and asserts it reports exactly the two lines
/// below and nothing else.
///
/// Its whole purpose is to answer the question "would the guard actually fail
/// if the discipline were violated?" with a run rather than an assurance. The
/// rule that reopened AC-24 states the standard: *a criterion is not discharged
/// by proving a configuration value propagated; it must assert the capability
/// that value was configured to obtain. If the test would pass with the
/// resource empty, it is evidence for the wiring, not the criterion.* A scan
/// that only ever sees a clean tree passes just as happily when its regex is
/// wrong, when the comment stripper eats the call, or when the balanced-paren
/// reader stops at the first nested `)`. This file makes each of those fail.
///
/// Four call sites, chosen to exercise the four ways the scan could be wrong:
///
/// 1. `Image.asset` on a Tier A asset, no `cacheWidth`  → **must be reported**
/// 2. `AssetImage` on a Tier A asset, no `cacheWidth`   → **must be reported**
/// 3. `Image.asset` on a Tier A asset **with** a `cacheWidth` whose value
///    contains a nested call — must NOT be reported, and it is what proves the
///    argument reader is balanced rather than stopping at the first `)`
/// 4. `Image.asset` on a **Tier B** asset with no `cacheWidth` — must NOT be
///    reported, because B1b § 6.4 exempts the tier with a density ladder
// ignore_for_file: unused_element, avoid_unused_constructor_parameters
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Violating extends StatelessWidget {
  const _Violating();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // (1) VIOLATION — a category slide decoded at 864x1152 into a 281x360
        //     box, which is the 4 MB-per-slide waste B1b § 6.4 named.
        Image.asset('assets/images/civil-population.webp'),

        // (2) VIOLATION — same asset family, the other constructor.
        const Image(image: AssetImage('assets/images/hero-bg.webp')),

        // (3) COMPLIANT, and deliberately awkward: the `cacheWidth` value is a
        //     nested call. A scanner that read to the first `)` would see
        //     `math.min(864` and conclude there was no `cacheWidth`.
        Image.asset(
          'assets/images/bg-id.webp',
          cacheWidth: math.min(1000, (350 * 3).ceil()),
        ),

        // (4) COMPLIANT by exemption — Tier B ships 1x/2.0x/3.0x, so Flutter
        //     resolves and decodes the right rung unaided.
        Image.asset('assets/images/moha-sm.webp', height: 28, width: 28),
      ],
    );
  }
}
