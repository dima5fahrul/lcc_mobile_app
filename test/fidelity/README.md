# The fidelity harness

The instrument § II.R-E defines and specs.md § 6.5 rules on for B2. B2b, B2c
and every later batch consume this; it is the artefact, not the page.

## Run it

```sh
cd projects/lcc-mobile-app/sources/lcc_mobile_app
flutter test test/fidelity/
```

That is the whole command — **B2-AC-10's "documented command"**. No browser, no
dev server, no reverse proxy, no `VITE_API_URL`, no capture rig. A second agent
with a clean checkout runs that line and reproduces the same tier results,
because every expectation is a versioned file and every input is a recorded
payload.

| Tier | Test | Verdict source |
|---|---|---|
| 0 | — | **NOT APPLICABLE** (B2-AC-28). B2 ports no form, no field, no `form_data`; its single POST is `{helpful: bool}`. Ruled out on the merits in § 6.5.1, recorded rather than omitted. It binds F0–F4. |
| 1 | `tier1_structural_parity_test.dart` | `oracle/tier1/service.{en,lo}.json` |
| 2 | `tier2_token_parity_test.dart` | `oracle/tier2/tokens.json` |
| 3 | `tier3_capture_test.dart` produces the image; a **human** produces the verdict | `disparity-report-iteration-N.md` |
| — | `mask_register_test.dart` | `masks.yaml`, `page_pairs.yaml` |

## Where the oracles live, and why they are not here

```
docs/fidelity-baseline/2026-08-13/oracle/
├── api/                       the recorded staging payloads the page is fed
│   ├── service-categories.json    8 rows
│   └── services.json             43 rows
├── tier1/service.{en,lo}.json     9 views x 125 nodes, ordered
└── tier2/tokens.json              38 colours, 7 type steps, 12 spacing steps, 54+12 icons
```

Outside the Flutter package, beside the screenshots, because they belong to the
**baseline** rather than to the app. A copy under `test/` would be a second one
to keep in step, and the first thing to drift.

## What Tier 1 actually compares

For one route, one locale, one page state: the **ordered list of text the web
presents** against a depth-first pre-order dump of the Flutter widget tree.

Nine states, not one — `categories.{loading,data,empty,error}` and
`list.{loading,data,error,empty.category,empty.search}` — so the § 6.6 four-state
contract's error sentences and empty-state copy are gated at the same 100 % as
the card titles. Both locales, always: § 6.5.6 rules that heights are not
canonical and every comparison pairs against the locale-matching artefact, and
the Lao run is where a missing `lo` key or a leaked English fallback surfaces.

Order is the point. A set comparison would pass a page that renders every right
string in the wrong place.

It does **not** compare colour, size, weight or position. Those are Tier 2's and
Tier 3's, and a Tier 1 that failed for them would fail for reasons it is not the
gate for.

## What Tier 2 actually compares

Values, never pixels — § II.R-E rejected pixel-diff as the gate. Each assertion
is an equality between a number or an ARGB integer from the oracle and the same
thing read out of `lib/presentation/theme/` and `lib/presentation/icons/`:
38 colours, the type scale plus the four weights plus the `h1` rule, 12 spacing
and radius steps, and both icon scopes with their `FileText` fallback.

**It is not Dart-equals-Dart.** `derive_tier2.py` builds the oracle by grepping
each hex out of the web file it is attributed to and **failing if the hex is not
there**, so a token with bad provenance cannot reach the test as a passing
entry. That check is what caught `AppColors.authGradientEnd`, whose cited
`#1A2A5E` gradient exists nowhere in the web source; it is excluded by name,
with a reason and an owner, in the oracle's `excluded` block.

## Regenerating the oracles — read this first

```sh
python3 test/fidelity/derive_oracles.py    # Tier 1
python3 test/fidelity/derive_tier2.py      # Tier 2
```

Both read the port source, its i18n dictionaries and `oracle/api/`, all pinned
to `62f8a529` — the same commit as the screenshots, so this is a *derivation*,
not a re-baseline, and the manifest's "captured once" rule is respected.

> **An oracle regenerated from a different web commit IS a re-baseline** and
> requires an explicit logged act plus architect approval (§ 6.5.3). If
> `sources/lcc-app` has moved off `62f8a529`, **stop and escalate** (§ 8.3) —
> a baseline spanning two web commits is unattributable.

Neither script runs during `flutter test`, by design: a gate that regenerates
its own expectation each run cannot fail.

## The registers

`masks.yaml` records permission to hide evidence from a reviewer, so its own
invariants are asserted by `mask_register_test.dart` — exactly one entry, with a
reason, a derivation date, and a per-locale rectangle small enough to be a
captcha rather than a disparity. `page_pairs.yaml` records which baseline slot
pairs with which page, and excludes the eight slots that are the signin form
wearing another route's filename.

## Known limits of this instrument

Stated so nobody reads its silence as a pass.

1. ~~**Tier 3's Latin half does not render headlessly.**~~ **Fixed, 2026-08-13.**
   The bundled `NotoSansLao` faces really are Lao-only subsets (0/26 A–Z, 0/10
   ASCII digits, verified at the `cmap`), but they are no longer the whole
   stack: `AppTypography.fontFamilyFallback` declares `Roboto` behind them, and
   `loadAppFonts()` registers it in the harness from
   `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/`. Both locales render
   fully. **Use `loadAppFonts()`, never a single-family `FontLoader`** — a
   capture taken with only the Lao face looks plausible and is not.
2. ~~**Headless layout does not reproduce the per-locale wrap difference.**~~
   **Withdrawn — this was never true of the harness.** It was two defects
   misread as a limitation: the missing Latin face above, *and* a locale loop
   that reused the root element so its second iteration silently re-rendered the
   first locale. See `disparity-report-iteration-1.md`. Headless layout does
   reproduce the difference (grid 922 `en` vs 964 `lo`).

   The disposition is nonetheless unchanged, for a better reason: the two
   locales resolve through **different faces with different metrics**, so
   "locale X is taller" is a typography question settled against the
   locale-matching PNG, not a layout number a widget test should assert.

   **If you loop locales inside one `testWidgets` body, tear the tree down
   between them** (`pumpWidget(SizedBox())`) **and assert the expected locale's
   copy is on screen before measuring.** `pumpWidget` reuses the root element
   when the widget type is unchanged, so `EasyLocalization.initState` never
   re-runs and `startLocale` is silently ignored. Every other assertion in such
   a loop passes just as happily against the wrong locale.
3. **Tier 1 reads the source's branches, not a running React app.** Every
   visible string on `/service` is a dictionary lookup, a seed-table lookup, an
   API field, or a number formatted from one — which is what makes the page
   derivable. A page with a date formatter or a relative timestamp is not, and
   **B2c's news page is the one to check** before assuming this generalises.
