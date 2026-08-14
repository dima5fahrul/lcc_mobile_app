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


# ---------------------------------------------------------------------------
# The `forms` group — F0-AC-94's ENUMERATED denominator (specs.md § 6.10.1)
# ---------------------------------------------------------------------------
#
# v1.0's F0-AC-59 claimed "Tier 2: PASS, 100 %" over an unnamed set, and named
# two colours that already existed and therefore asserted nothing. F0-AC-94
# replaces the claim with a denominator: **every distinct colour, radius,
# spacing and type value appearing in `formFields.tsx` and `formValidation.tsx`**
# — the whole two files, not just `fieldBase` and `fieldErrorRing`.
#
# Two mechanisms make the number mean something:
#
# 1. **Whole-token verification, not substring grep.** `gap-1` is a substring of
#    `gap-1.5`, `w-3` of `w-3.5`, `py-2` of `py-2.5`, and `text-gray-400` of
#    `placeholder:text-gray-400`. A substring grep would let four of the entries
#    below "verify" against a line that does not contain them. Every entry is
#    located by splitting the file's string literals into class tokens and
#    matching one **exactly** (`token_lines`).
#
# 2. **An INDEPENDENT scan sets the cardinality.** `scan_form_utilities()`
#    re-derives the utility set from the two files with a Tailwind grammar that
#    knows nothing about the list below, and the derivation FAILS on any
#    difference in either direction. A curated list can be short by an entry;
#    a curated list checked against an independent scan cannot be short by one
#    silently. (Both directions matter: the first draft of that scanner missed
#    `focus:border-[#344EAD]` and `focus:ring-2`, which is precisely the class
#    of miss this check exists to surface.)
FORMS_FILES = {
    "FF": "src/app/components/formFields.tsx",
    "FV": "src/app/components/formValidation.tsx",
}

# Tailwind's published scale at the source's 16 px root (`theme.css:4`):
# a numeric suffix n renders 4n px.
#
# (utility, category, file key, value, dart token or None)
#   colour values are "#RRGGBB", ("#RRGGBB", alpha) for a `/nn` suffix, or
#   "transparent"; radius/spacing values are px; type values are px or a weight.
FORMS = [
    # ---- colour (19) -----------------------------------------------------
    ("bg-[#EEF2FF]", "colour", "FF", "#EEF2FF", "primarySoft"),
    ("bg-gray-100", "colour", "FF", "#F3F4F6", "gray100"),
    ("bg-gray-50", "colour", "FF", "#F9FAFB", "gray50"),
    ("bg-transparent", "colour", "FF", "transparent", "transparent"),
    ("bg-white", "colour", "FF", "#FFFFFF", "white"),
    ("border-gray-100", "colour", "FF", "#F3F4F6", "gray100"),
    ("border-gray-200", "colour", "FV", "#E5E7EB", "gray200"),
    ("border-red-300", "colour", "FV", "#FCA5A5", "dangerBorder"),
    ("focus:border-[#344EAD]", "colour", "FV", "#344EAD", "primary"),
    ("focus:border-red-400", "colour", "FV", "#F87171", None),
    ("focus:ring-[#344EAD]/20", "colour", "FV", ("#344EAD", 0.2), "primary@0.2"),
    ("focus:ring-red-500/20", "colour", "FV", ("#EF4444", 0.2), "dangerStrong@0.2"),
    ("hover:bg-gray-50", "colour", "FF", "#F9FAFB", "gray50"),
    ("placeholder:text-gray-400", "colour", "FF", "#9CA3AF", "gray400Inline"),
    ("text-gray-400", "colour", "FF", "#9CA3AF", "gray400Inline"),
    ("text-gray-500", "colour", "FF", "#6B7280", "muted"),
    ("text-gray-800", "colour", "FF", "#1F2937", "gray800"),
    ("text-red-400", "colour", "FF", "#F87171", None),
    ("text-red-500", "colour", "FF", "#EF4444", "dangerStrong"),
    # ---- radius (2) ------------------------------------------------------
    ("rounded-xl", "radius", "FF", 12, "radiusXl"),
    ("rounded-2xl", "radius", "FF", 16, "radius2xl"),
    # ---- spacing (27) ----------------------------------------------------
    ("focus:ring-2", "spacing", "FV", 2, "gap2"),
    ("gap-1", "spacing", "FF", 4, "gap4"),
    ("gap-1.5", "spacing", "FF", 6, "gap6"),
    ("gap-2", "spacing", "FF", 8, "gap8"),
    ("gap-3", "spacing", "FF", 12, "gap12"),
    ("h-3", "spacing", "FF", 12, "gap12"),
    ("h-3.5", "spacing", "FF", 14, "gap14"),
    ("h-4", "spacing", "FF", 16, "gap16"),
    ("max-h-60", "spacing", "FF", 240, None),
    ("mb-1.5", "spacing", "FF", 6, "gap6"),
    ("min-w-0", "spacing", "FF", 0, None),
    ("ml-0.5", "spacing", "FF", 2, "gap2"),
    ("mt-1.5", "spacing", "FF", 6, "gap6"),
    ("mt-2", "spacing", "FF", 8, "gap8"),
    ("p-2", "spacing", "FF", 8, "gap8"),
    ("pr-10", "spacing", "FF", 40, "gap40"),
    ("px-3", "spacing", "FF", 12, "gap12"),
    ("px-4", "spacing", "FF", 16, "gap16"),
    ("py-1", "spacing", "FF", 4, "gap4"),
    ("py-2", "spacing", "FF", 8, "gap8"),
    ("py-2.5", "spacing", "FF", 10, "gap10"),
    ("py-3.5", "spacing", "FF", 14, "gap14"),
    ("py-6", "spacing", "FF", 24, "gap24"),
    ("right-4", "spacing", "FF", 16, "gap16"),
    ("w-3", "spacing", "FF", 12, "gap12"),
    ("w-3.5", "spacing", "FF", 14, "gap14"),
    ("w-4", "spacing", "FF", 16, "gap16"),
    # ---- type (4) --------------------------------------------------------
    ("text-[11px]", "type", "FF", 11, "size11"),
    ("text-xs", "type", "FF", 12, "size12"),
    ("text-sm", "type", "FF", 14, "size14"),
    ("font-semibold", "type", "FF", 600, "semiBold"),
]

# The entries above with `token: None`, each with the measured reason there is
# nothing in `presentation/theme/` to compare them against. Carried as a CLOSED
# register rather than dropped: an entry silently missing from the group is
# indistinguishable from an oversight, and the Dart side asserts this register's
# exact contents so it cannot grow without a reviewer seeing it.
FORMS_UNTOKENISED = {
    "focus:border-red-400": {
        "value": "#F87171",
        "reason":
            "Tailwind `red-400`. Measured: `grep -rn F87171 "
            "lib/presentation/theme/` returns NOTHING — the value has no token. "
            "Adding one means editing `lib/presentation/theme/app_colors.dart`, "
            "which is NOT in specs.md § 3.1's F0b table and IS named in § 4.1's "
            "out-of-scope list, so editing it is an automatic F0-AC-66 FAIL; "
            "writing `Color(0xFFF87171)` at the use site instead is an automatic "
            "F0-AC-59 / B2-AC-11 FAIL. `field_error_ring.dart:87` therefore "
            "holds `AppColors.dangerBorder` (red-300) for the FOCUSED error "
            "border as well as the resting one.",
        "consequence":
            "A REGISTERED DIVERGENCE FROM THE WEB, not a resolution: on the web "
            "a focused errored field darkens its border one step (red-300 -> "
            "red-400) and the port does not. Reported as FAIL, not rounded to "
            "PASS.",
        "owner": "F1, or whichever batch is authorised to add the token",
    },
    "text-red-400": {
        "value": "#F87171",
        "reason":
            "Same value, same absent token, different site: `formFields.tsx:44`'s "
            "required-marker asterisk. Listed separately because the denominator "
            "counts distinct UTILITIES, and collapsing the two would make the "
            "cardinality check disagree with the independent scan.",
        "consequence":
            "`field_label.dart` draws the asterisk in the nearest token it may "
            "use. Same FAIL, same owner.",
        "owner": "F1, or whichever batch is authorised to add the token",
    },
    "max-h-60": {
        "value": 240,
        "reason":
            "`AppSpacing` tops out at `gap40` (40) / `tile56` (56); 240 px is a "
            "dropdown max-height, not a spacing step, and inventing `gap240` "
            "would put a one-use layout constant in the shared scale.",
        "consequence":
            "`searchable_select.dart` carries it as a local constant. Not a "
            "divergence — the VALUE is correct; it simply has no shared token to "
            "be compared against.",
        "owner": "none — recorded so the denominator stays honest",
    },
    "min-w-0": {
        "value": 0,
        "reason":
            "Tailwind's flex-shrink escape hatch. Zero is not a design token in "
            "any scale, and Flutter expresses the same thing structurally "
            "(`Expanded`/`Flexible`) rather than as a measurement.",
        "consequence":
            "No Flutter value to compare. Recorded, not compared.",
        "owner": "none — recorded so the denominator stays honest",
    },
}


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


_STRING_LITERAL = re.compile(r'"([^"\n]*)"|\'([^\'\n]*)\'|`([^`]*)`', re.S)

# The four Tailwind grammars. Deliberately written against the framework's
# shape — NOT against the FORMS list — so agreement between the two is evidence.
_VARIANT = re.compile(
    r"^(?:hover|focus|active|disabled|group-hover|peer-focus|focus-visible):")
_G_COLOUR = re.compile(
    r"^(?:bg|text|border|ring|divide|from|to|fill|stroke|placeholder:text)-"
    r"(?:\[#[0-9A-Fa-f]{3,8}\]"
    r"|(?:red|gray|green|blue|amber|slate|indigo|emerald|white|black|transparent)"
    r"(?:-\d{2,3})?)(?:/\d{1,3})?$")
_G_RADIUS = re.compile(r"^rounded(?:-(?:sm|md|lg|xl|[2-9]xl|full|none))?$")
_G_SPACING = re.compile(
    r"^(?:p|px|py|pt|pb|pl|pr|m|mx|my|mt|mb|ml|mr|gap|gap-x|gap-y|space-x"
    r"|space-y|w|h|min-w|min-h|max-w|max-h|inset|top|bottom|left|right|ring"
    r"|size|translate-x|translate-y)-(?:\[[0-9.]+(?:px|rem)\]|[0-9]+(?:\.[0-9]+)?)$")
_G_TYPE = re.compile(
    r"^(?:text-(?:xs|sm|base|lg|xl|[2-9]xl|\[[0-9.]+px\])"
    r"|font-(?:thin|light|normal|medium|semibold|bold|extrabold))$")


def class_tokens(rel: str) -> list[tuple[int, str]]:
    """Every whitespace-separated class token in every string literal, with its line.

    Class tokens are read from string literals rather than by grepping raw text
    because a raw grep cannot tell `gap-1` from the `gap-1` inside `gap-1.5`.

    Scanned over the whole file rather than line by line: the longest class
    strings in `formFields.tsx` are multi-line template literals, and a
    per-line regex never sees a literal whose backticks are on different lines.
    Measured — `pr-10` (:311) and `py-2.5` (:201) are both inside one, and a
    line-by-line reading silently loses them.
    """
    text = read(rel)
    out: list[tuple[int, str]] = []
    for match in _STRING_LITERAL.finditer(text):
        group = next(
            (i for i, g in enumerate(match.groups()) if g is not None), None)
        if group is None:
            continue
        body = match.group(group + 1)
        base_line = text.count("\n", 0, match.start(group + 1)) + 1
        offset = 0
        for raw in body.split(" "):
            token = raw.strip("\n\t\"'`{}(),;")
            if token:
                out.append((base_line + body.count("\n", 0, offset), token))
            offset += len(raw) + 1
    return out


def token_lines(rel: str, utility: str) -> list[int]:
    """Lines of `rel` carrying `utility` as a WHOLE class token."""
    return sorted({n for n, t in class_tokens(rel) if t == utility})


def scan_form_utilities() -> dict[str, set[str]]:
    """Re-derive the kernel's Tier 2 surface from the two files, independently.

    Knows nothing about FORMS. This is F0-AC-94's *"independent scan of Tailwind
    colour/radius/spacing utilities over those two files"*, and it is what turns
    the group's cardinality from an assertion into a measurement.
    """
    found: dict[str, set[str]] = {
        "colour": set(), "radius": set(), "spacing": set(), "type": set(),
    }
    for rel in FORMS_FILES.values():
        for _, token in class_tokens(rel):
            base = _VARIANT.sub("", token)
            stripped = base[len("placeholder:"):] \
                if base.startswith("placeholder:") else base
            # type before colour: `text-sm` and `text-gray-800` share a prefix
            if _G_TYPE.match(stripped):
                found["type"].add(token)
            elif _G_RADIUS.match(stripped):
                found["radius"].add(token)
            elif _G_COLOUR.match(base):
                found["colour"].add(token)
            elif _G_SPACING.match(base):
                found["spacing"].add(token)
    return found


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

    # ---- the `forms` group (F0-AC-94) ------------------------------------
    forms = OrderedDict()
    curated: dict[str, set[str]] = {
        "colour": set(), "radius": set(), "spacing": set(), "type": set(),
    }
    for utility, category, key, value, token in FORMS:
        curated[category].add(utility)
        rel = FORMS_FILES[key]
        hits = token_lines(rel, utility)
        if not hits:
            failures.append(
                f"forms/{utility}: not present as a whole class token in {rel}")
            continue
        if isinstance(value, tuple):
            base, alpha = value
            recorded: object = OrderedDict([("base", base), ("alpha", alpha)])
            # the `/nn` forms carry their hex literally in the source
            verified = "grep" if base in read(rel) else "usage"
        elif isinstance(value, str) and value.startswith("#"):
            recorded = value
            verified = "grep" if value in read(rel) else "usage"
        else:
            recorded = value
            verified = "usage"
        forms[utility] = OrderedDict([
            ("category", category),
            ("value", recorded),
            ("token", token),
            ("source", f"{rel}:{','.join(str(h) for h in hits[:4])}"),
            ("verified", verified),
        ])

    # The cardinality check, both directions.
    scanned = scan_form_utilities()
    for category in ("colour", "radius", "spacing", "type"):
        missing = scanned[category] - curated[category]
        extra = curated[category] - scanned[category]
        if missing:
            failures.append(
                f"forms/{category}: the independent scan found "
                f"{len(missing)} utilit{'y' if len(missing) == 1 else 'ies'} "
                f"the group does not carry: {sorted(missing)}")
        if extra:
            failures.append(
                f"forms/{category}: the group carries "
                f"{len(extra)} utilit{'y' if len(extra) == 1 else 'ies'} "
                f"the independent scan does not find: {sorted(extra)}")

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
    doc["forms"] = OrderedDict([
        ("note",
         "F0-AC-94's enumerated denominator — every distinct colour, radius, "
         "spacing and type utility in formFields.tsx and formValidation.tsx. "
         "Each is located as a WHOLE class token (a substring grep cannot tell "
         "`gap-1` from `gap-1.5`), and the cardinality is set by "
         "scan_form_utilities(), which re-derives the set from a Tailwind "
         "grammar that does not read the curated list."),
        ("denominator", OrderedDict(
            [(c, len(curated[c])) for c in
             ("colour", "radius", "spacing", "type")]
            + [("total", sum(len(v) for v in curated.values()))])),
        ("root_font_size_px", 16),
        ("entries", forms),
        ("untokenised", FORMS_UNTOKENISED),
    ])
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
          f"{len(spacing)} spacing, {len(service_scope)}+{len(help_scope)} icons, "
          f"{len(forms)} forms utilities "
          f"[{len(FORMS_UNTOKENISED)} untokenised])")
    return 0


if __name__ == "__main__":
    sys.exit(main())
