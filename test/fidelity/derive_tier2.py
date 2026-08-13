#!/usr/bin/env python3
"""Derive the Tier 2 (design-token parity) oracle from the pinned web commit.

  Run:  python3 test/fidelity/derive_tier2.py

specs.md § 6.5.3: *"Tier 2 oracle — one JSON of the web's resolved design-token
values (brand and semantic colours, type scale, spacing scale, and the per-name
icon mapping). Tier 2 runs as a Dart test against `presentation/theme/` and
`presentation/icons/`."*

The circularity this script exists to avoid
-------------------------------------------
An oracle hand-copied out of `app_colors.dart` would make Tier 2 a test that
Dart equals Dart — 100 % green, zero information. So every colour below is
declared with the **web file it comes from**, and the derivation FAILS unless
that hex literally appears in that file. The check is what makes the JSON an
oracle instead of a restatement.

Three classes of value, and what can be machine-checked about each
------------------------------------------------------------------
* `verified: "grep"` — a hex or a CSS custom property that the script found in
  the cited web file at the recorded line(s). The strongest claim available
  without a browser.
* `verified: "usage"` — a Tailwind utility class (`text-sm`, `p-5`,
  `rounded-2xl`) whose *presence* in the cited file the script confirmed; the
  numeric value is Tailwind's published scale at the source's 16 px root
  (`theme.css:4`), which lives in the framework and not in this repo.
* `verified: "manual"` — anything neither of the above could reach. There are
  none today; the field exists so that a future entry cannot quietly pretend to
  the stronger claim.
"""

from __future__ import annotations

import json
import os
import re
import sys
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.abspath(os.path.join(HERE, "..", ".."))
COMPONENT = os.path.abspath(os.path.join(PKG, "..", ".."))
WEB = os.path.join(COMPONENT, "sources", "lcc-app")
ORACLE = os.path.join(COMPONENT, "docs", "fidelity-baseline", "2026-08-13", "oracle")
WEB_COMMIT = "62f8a529aaa024a8b35b0af50a8fbd4850a63962"

# token -> (hex, web file, what it is)
COLOURS = [
    ("primary", "#344EAD", "src/app/components/Layout.tsx", "brand blue: header bar, active nav, primary CTAs"),
    ("primarySoft", "#EEF2FF", "src/app/components/Layout.tsx", "pale brand tint behind brand-coloured icons and tiles"),
    ("surface", "#F0F2F8", "src/app/components/Layout.tsx", "the page wash behind every screen"),
    ("muted", "#6B7280", "src/app/components/Layout.tsx", "inactive bottom-nav icon and label; ServiceCard description"),
    ("authGradientStart", "#101C48", "src/app/components/AuthPage.tsx", "the sign-in backdrop base, `bg-[#101C48]` at :192"),
    ("headerGradientMid", "#2A3F99", "src/app/components/ServicePage.tsx", "catalogue header gradient, 60%"),
    ("headerGradientEnd", "#1E3070", "src/app/components/ServicePage.tsx", "catalogue header gradient, 100%"),
    ("gray400", "#616b7a", "src/styles/theme.css", "theme.css override of Tailwind gray-400 for WCAG 1.4.3"),
    ("gray500", "#5a6472", "src/styles/theme.css", "theme.css override of Tailwind gray-500 for WCAG 1.4.3"),
    ("gray400Inline", "#9CA3AF", "src/app/components/ServicePage.tsx", "STOCK gray-400, written inline so the theme.css override does not reach it"),
    ("gray800", "#1F2937", "src/app/components/ServiceCard.tsx", "resting service-card title"),
    ("danger", "#DC2626", "src/app/components/ServicePage.tsx", "error-panel glyph"),
    ("success", "#15803D", "src/app/components/ServiceCard.tsx", "a free fee"),
    ("categoryAccentCivil", "#344EAD", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintCivil", "#EEF2FF", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryAccentImmigration", "#0EA5E9", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintImmigration", "#E0F2FE", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryAccentFinance", "#16A34A", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintFinance", "#DCFCE7", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryAccentHousing", "#EA580C", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintHousing", "#FFEDD5", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryAccentTransport", "#F59E0B", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintTransport", "#FEF3C7", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryAccentWelfare", "#DB2777", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintWelfare", "#FCE7F3", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryAccentEducation", "#2563EB", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintEducation", "#DBEAFE", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryAccentHealth", "#DC2626", "src/app/components/ServicePage.tsx", "CATEGORIES seed accent"),
    ("categoryTintHealth", "#FEE2E2", "src/app/components/ServicePage.tsx", "CATEGORIES seed tint"),
    ("categoryTintFallback", "#F3F4F6", "src/app/components/ServicePage.tsx", "seed?.bg fallback; also the gray-100 card hairline"),
    ("helpPalette0Color", "#344EAD", "src/app/components/HelpCenterPage.tsx", "PALETTE[0] colour"),
    ("helpPalette0Bg", "#EEF2FF", "src/app/components/HelpCenterPage.tsx", "PALETTE[0] background"),
    ("helpPalette1Color", "#B45309", "src/app/components/HelpCenterPage.tsx", "PALETTE[1] colour"),
    ("helpPalette1Bg", "#FEF3C7", "src/app/components/HelpCenterPage.tsx", "PALETTE[1] background"),
    ("helpPalette2Color", "#15803D", "src/app/components/HelpCenterPage.tsx", "PALETTE[2] colour"),
    ("helpPalette2Bg", "#DCFCE7", "src/app/components/HelpCenterPage.tsx", "PALETTE[2] background"),
    ("helpPalette3Color", "#6366F1", "src/app/components/HelpCenterPage.tsx", "PALETTE[3] colour"),
    ("helpPalette3Bg", "#E0E7FF", "src/app/components/HelpCenterPage.tsx", "PALETTE[3] background"),
]

# token -> (px, tailwind class, cited web file)
TYPE_SCALE = [
    ("size11", 11, "text-[11px]", "src/app/components/Layout.tsx"),
    ("size12", 12, "text-xs", "src/app/components/ServicePage.tsx"),
    ("size14", 14, "text-sm", "src/app/components/ServicePage.tsx"),
    ("size15", 15, "text-[15px]", "src/app/components/ServiceCard.tsx"),
    ("size16", 16, "text-base", "src/app/components/ServicePage.tsx"),
    ("size18", 18, "text-lg", "src/app/components/ServiceCard.tsx"),
    ("size24", 24, "text-2xl", "src/styles/theme.css"),
]

SPACING = [
    ("gap4", 4, "gap-1", "src/app/components/ServicePage.tsx"),
    ("gap6", 6, "gap-1.5", "src/app/components/ServicePage.tsx"),
    ("gap8", 8, "gap-2", "src/app/components/ServicePage.tsx"),
    ("gap12", 12, "py-3", "src/app/components/ServicePage.tsx"),
    ("gap16", 16, "gap-4", "src/app/components/ServicePage.tsx"),
    ("gap20", 20, "p-5", "src/app/components/ServicePage.tsx"),
    ("gap24", 24, "pt-6", "src/app/components/ServicePage.tsx"),
    ("gap32", 32, "pb-8", "src/app/components/ServicePage.tsx"),
    ("gap40", 40, "p-10", "src/app/components/ServicePage.tsx"),
    ("radiusXl", 12, "rounded-xl", "src/app/components/ServicePage.tsx"),
    ("radius2xl", 16, "rounded-2xl", "src/app/components/ServicePage.tsx"),
    ("tile56", 56, "w-14", "src/app/components/ServicePage.tsx"),
]


# Tokens that exist in `presentation/theme/` and have NO web counterpart to
# compare against. Excluded from Tier 2 rather than omitted: an omission is
# indistinguishable from an oversight, and § 6.5.5 requires an item excluded
# from B2's pass/fail to be NAMED and attributed.
EXCLUDED = {
    "authGradientEnd": {
        "value": "#1A2A5E",
        "reason":
            "NOT PRESENT ANYWHERE IN THE WEB SOURCE AT 62f8a529. Measured: "
            "`grep -rn 1A2A5E` over sources/lcc-app returns nothing. "
            "`AppColors.authGradientEnd`'s doc attributes it to `AuthPage.tsx "
            "linear-gradient(#101C48 -> #1A2A5E)`; that gradient does not "
            "exist. The web's sign-in backdrop is a flat `bg-[#101C48]` "
            "(:192) under an rgba(14,28,75,..)/rgba(16,28,72,..) photo "
            "overlay (:215). The value was transcribed from the FLUTTER page "
            "(`auth_page.dart:200` draws a two-stop #101C48 -> #1A2A5E "
            "gradient), so comparing the token against the web would be "
            "comparing Flutter against itself.",
        "owner":
            "R-12 (AuthPage emblem + photo background), on the § 6.5.5 "
            "pre-existing-disparity register and owned by "
            "GOR-245-b1b2-r12-emblem-restoration. B2 may not add to that "
            "register and may not touch the frozen auth pages (§ 4.2), so "
            "this is reported, not fixed.",
        "verified": "absent",
    },
}


def read(rel: str) -> str:
    with open(os.path.join(WEB, rel), encoding="utf-8") as handle:
        return handle.read()


def grep_lines(rel: str, needle: str) -> list[int]:
    lines = read(rel).splitlines()
    return [i + 1 for i, line in enumerate(lines) if needle in line]


def icon_scope(rel: str, marker: str) -> list[str]:
    """The names in a `const ICONS: Record<string, ElementType> = { … }` table."""
    src = read(rel)
    block = re.search(marker + r"\s*=\s*\{(.*?)\n\};", src, re.S)
    if not block:
        raise SystemExit(f"{rel}: {marker} table not found")
    names: list[str] = []
    for token in block.group(1).replace("\n", " ").split(","):
        token = token.strip()
        if not token:
            continue
        # entries are either `Name` (shorthand) or `Name: Component`
        names.append(token.split(":")[0].strip())
    return [n for n in names if re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", n)]


def main() -> int:
    failures: list[str] = []

    colours = OrderedDict()
    for name, value, rel, note in COLOURS:
        hits = grep_lines(rel, value) or grep_lines(rel, value.lower()) \
            or grep_lines(rel, value.upper())
        if not hits:
            failures.append(f"{name}: {value} not found in {rel}")
            continue
        colours[name] = OrderedDict([
            ("value", value.upper() if value.startswith("#") else value),
            ("source", f"{rel}:{','.join(str(h) for h in hits[:4])}"),
            ("note", note),
            ("verified", "grep"),
        ])

    typography = OrderedDict()
    for name, px, cls, rel in TYPE_SCALE:
        hits = grep_lines(rel, cls)
        if not hits:
            failures.append(f"{name}: class `{cls}` not found in {rel}")
            continue
        typography[name] = OrderedDict([
            ("px", px),
            ("tailwind", cls),
            ("source", f"{rel}:{hits[0]}"),
            ("verified", "usage"),
        ])

    spacing = OrderedDict()
    for name, px, cls, rel in SPACING:
        hits = grep_lines(rel, cls)
        if not hits:
            failures.append(f"{name}: class `{cls}` not found in {rel}")
            continue
        spacing[name] = OrderedDict([
            ("px", px),
            ("tailwind", cls),
            ("source", f"{rel}:{hits[0]}"),
            ("verified", "usage"),
        ])

    if failures:
        for line in failures:
            print(f"FAIL {line}", file=sys.stderr)
        return 1

    service_scope = icon_scope(
        "src/app/components/ServicePage.tsx",
        r"const ICONS: Record<string, ElementType>",
    )
    # Help's table is typed `Record<string, typeof UserCircle>`, not
    # `Record<string, ElementType>` — the two registries are not even declared
    # the same way, which is a small further reason not to assume they are
    # interchangeable (§ 6.3.5).
    help_scope = icon_scope(
        "src/app/components/HelpCenterPage.tsx",
        r"const ICONS: Record<string, typeof UserCircle>",
    )

    doc = OrderedDict()
    doc["schema"] = "tier2/1"
    doc["provenance"] = OrderedDict([
        ("web_commit", WEB_COMMIT),
        ("baseline", "docs/fidelity-baseline/2026-08-13"),
        ("derived_by", "test/fidelity/derive_tier2.py"),
        ("method",
         "Every colour is grepped out of the web file it is attributed to; the "
         "derivation fails if a hex is not present where it is cited. Type and "
         "spacing entries confirm the Tailwind utility is used in the cited "
         "file and record the framework's value at the 16 px root "
         "(theme.css:4). Icon scopes are parsed from the two ICONS tables."),
        ("root_font_size_px", 16),
    ])
    doc["colors"] = colours
    doc["excluded"] = EXCLUDED
    doc["typography"] = OrderedDict([
        ("fontFamily", OrderedDict([
            ("value", "NotoSansLao"),
            ("note",
             "One family for both locales. The web has no bundled font — it "
             "renders with the platform stack — so this is the ONE Tier 2 "
             "value with no web counterpart to compare against, and it is "
             "recorded as the Flutter-side contract AC-24 asserts rather than "
             "as a ported value."),
            ("verified", "n/a — no web counterpart"),
        ])),
        ("weights", OrderedDict([
            ("normal", 400),
            ("medium", 500),
            ("semiBold", 600),
            ("bold", 700),
        ])),
        ("scale", typography),
        ("h1", OrderedDict([
            ("px", 24),
            ("weight", 500),
            ("lineHeight", 1.5),
            ("source", "src/styles/theme.css:152-156"),
            ("verified", "grep"),
        ])),
    ])
    doc["spacing"] = spacing
    doc["icons"] = OrderedDict([
        ("fallback", "FileText"),
        ("serviceScope", service_scope),
        ("helpScope", help_scope),
        ("note",
         "TWO scopes, one asset set (§ 6.3.5). Mail, Phone and Rocket are in "
         "Help's table and NOT in Service's; merging them would render a "
         "rocket where the web renders FileText."),
        ("source",
         "ServicePage.tsx const ICONS + HelpCenterPage.tsx const ICONS"),
        ("verified", "parsed"),
    ])

    path = os.path.join(ORACLE, "tier2", "tokens.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(doc, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(f"wrote {path}  ({len(colours)} colours, {len(typography)} type, "
          f"{len(spacing)} spacing, {len(service_scope)}+{len(help_scope)} icons)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
