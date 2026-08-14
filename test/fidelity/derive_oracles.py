#!/usr/bin/env python3
"""Derive the Tier 1 and Tier 2 oracles from the pinned web commit.

specs.md § 6.5.3 rules that B2a derives static Tier 1 and Tier 2 oracles
**once**, from `62f8a529`, and versions them under
`docs/fidelity-baseline/2026-08-13/oracle/`.

  Run:  python3 test/fidelity/derive_oracles.py
        (from the Flutter package root; writes into ../../docs/…)

This script is NOT part of `flutter test` and is never executed by it. It is
here, versioned beside the tests that consume its output, so the oracle is
auditable and re-derivable rather than a hand-typed table nobody can check.

Why a derivation and not a capture
----------------------------------
§ 6.5.3 records that the screenshot rig fails in three documented, *silent*
ways (manifest F-3, F-6, F-7) — a misconfigured base URL, a `fullPage` no-op
and an intermittent route bounce, each producing a plausible-looking wrong
artefact with no error. Making a blocking gate depend on standing that rig up
on every run is the thing the ruling exists to prevent. So the oracle is read
from the three things that actually determine what the page presents:

  1. the port source at 62f8a529 — `ServicePage.tsx` (which strings render, in
     what order, under which branch) and its `CATEGORIES` seed table;
  2. the i18n dictionaries at 62f8a529 — `src/app/i18n/ns/{service,home}.ts`;
  3. the recorded staging payloads in `oracle/api/` — the 43 services and 8
     categories the page draws.

All three are pinned to the same commit as the screenshots, so this is not a
re-baseline: the manifest's "captured once" rule is respected. An oracle
regenerated from a **different** web commit IS a re-baseline and requires an
explicit logged act plus architect approval.

What it cannot see
------------------
Stated so nobody mistakes its silence for a pass. The derivation reads the
source's *branches*, so it knows which strings render together; it does not
execute React, so it cannot catch a string the source computes at runtime from
something other than these three inputs. `ServicePage.tsx` has none — every
visible string is a dictionary lookup, a seed-table lookup, an API field, or a
number formatted from an API field — and that property is what makes this page
derivable at all. A page that fails it (a date formatter, a relative "2h ago")
would need a different instrument, and B2c's news page is the one to check.
"""

from __future__ import annotations

import json
import os
import re
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import i18n_parse  # noqa: E402 — needs the path bootstrap above

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.abspath(os.path.join(HERE, "..", ".."))          # …/lcc_mobile_app
COMPONENT = os.path.abspath(os.path.join(PKG, "..", ".."))     # …/lcc-mobile-app
WEB = os.path.join(COMPONENT, "sources", "lcc-app")
ORACLE = os.path.join(
    COMPONENT, "docs", "fidelity-baseline", "2026-08-13", "oracle"
)

WEB_COMMIT = "62f8a529aaa024a8b35b0af50a8fbd4850a63962"
LOCALES = ("en", "lo")

# The drill-down the list-view oracles use. `civil` is first in server order and
# holds 13 of the 43 services, so it exercises a multi-row grid rather than the
# one-card edge case a smaller category would give.
LIST_CATEGORY = "civil"

# The query the "no results" oracle searches for. Deliberately not a word: the
# empty state cannot be reached against real staging data (43 rows, 8
# categories, nothing returns zero), so it is reached with a stubbed empty
# response and this is the string the header echoes back.
EMPTY_QUERY = "zzzz"


# ── reading the pinned source ────────────────────────────────────────────────

def read(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def parse_ns(name: str) -> dict:
    """Parse `src/app/i18n/ns/<name>.ts` into {locale: {key: value}}.

    Delegates to `i18n_parse`, shared with the other derivations, which asserts
    that it recovered every declared key and raises instead of returning a
    short dictionary.

    The scanner this replaced was LINE-ANCHORED: it required each value to sit
    on its key's own line and end in a comma, so it silently dropped every
    multi-line entry — 84 across `ns/*.ts`. This script reads `service.ts` and
    `home.ts`; `service.ts` has no multi-line entries, which is the only reason
    the shipped service oracle was correct and the defect went unseen. `home.ts`
    was losing `actionRequiredDesc` and `dismissDesc` — neither of which this
    script consumes (it takes only `applyNow`), so the output was unaffected,
    but nothing said so. See `i18n_parse.py`'s docstring.
    """
    src = read(os.path.join(WEB, "src", "app", "i18n", "ns", f"{name}.ts"))
    try:
        return i18n_parse.parse_namespace(src, LOCALES, origin=f"ns/{name}.ts")
    except i18n_parse.I18nParseError as exc:
        raise SystemExit(str(exc)) from exc


def parse_category_seeds() -> dict:
    """`CATEGORIES` in ServicePage.tsx → {code: {desc, descLo}}."""
    src = read(
        os.path.join(WEB, "src", "app", "components", "ServicePage.tsx")
    )
    block = re.search(
        r"export const CATEGORIES: Category\[\] = \[(.*?)\n\];", src, re.S
    )
    if not block:
        raise SystemExit("ServicePage.tsx: CATEGORIES table not found")

    seeds = OrderedDict()
    for row in re.finditer(
        r'\{\s*id:\s*"(?P<id>[^"]+)".*?desc:\s*"(?P<desc>[^"]*)".*?'
        r'descLo:\s*"(?P<descLo>[^"]*)"',
        block.group(1),
        re.S,
    ):
        seeds[row.group("id")] = {
            "en": row.group("desc"),
            "lo": row.group("descLo"),
        }
    if len(seeds) != 8:
        raise SystemExit(f"expected 8 CATEGORIES rows, parsed {len(seeds)}")
    return seeds


def load_api(name: str) -> list:
    with open(os.path.join(ORACLE, "api", f"{name}.json"), encoding="utf-8") as h:
        return json.load(h)["data"]


# ── the source's own formatting rules ────────────────────────────────────────

def bilingual(value: dict | None, locale: str) -> str:
    """`text(value, lang)` — types.ts:17-22, fallback chain included."""
    if not value:
        return ""
    wanted = value.get("lo" if locale == "lo" else "en") or ""
    return wanted or value.get("en") or value.get("lo") or ""


def group_thousands(n: int) -> str:
    """`n.toLocaleString("en-US")` — pinned to en-US in the source itself."""
    return f"{n:,}"


def format_fee(row: dict, locale: str) -> str:
    """`formatFee(cfg, lang)` — serviceConfig.ts:46-53, over the wire row."""
    fee = row.get("fee_lak", 0)
    fee_max = row.get("fee_max_lak", 0)
    ranged = row.get("fee_is_range", False) and fee_max > fee
    unit = "ກີບ" if locale == "lo" else "LAK"

    if ranged:
        # U+2013 EN DASH, as written in the source.
        return f"{group_thousands(fee)}–{group_thousands(fee_max)} {unit}"
    if fee == 0:
        return "ຟຣີ" if locale == "lo" else "Free"
    return f"{group_thousands(fee)} {unit}"


def interpolate(template: str, **args) -> str:
    out = template
    for key, value in args.items():
        out = out.replace("{" + key + "}", str(value))
    return out


# ── node builders ────────────────────────────────────────────────────────────

def node(role: str, text: str, source: str, level: int | None = None) -> dict:
    entry = OrderedDict()
    entry["role"] = role
    if level is not None:
        entry["level"] = level
    entry["text"] = text
    entry["source"] = source
    return entry


def header_nodes(service_ns, seeds, categories, locale, category_code=None,
                 query=None):
    """`ServicePage.tsx:359-412` — back link, h1, subtitle, search field."""
    t = service_ns[locale]
    nodes = []

    if category_code is not None:
        nodes.append(node(
            "button", t["allCategories"],
            "ServicePage.tsx:369-375 -> i18n/ns/service.ts allCategories",
        ))
        row = next(c for c in categories if c["code"] == category_code)
        nodes.append(node(
            "heading", bilingual(row["name"], locale),
            "ServicePage.tsx:377-383 -> /service-categories name", level=1,
        ))
        nodes.append(node(
            "paragraph", seeds[category_code][locale],
            "ServicePage.tsx:384-390 -> ServicePage.tsx CATEGORIES desc",
        ))
    else:
        nodes.append(node(
            "heading", t["allServices"],
            "ServicePage.tsx:377-383 -> i18n/ns/service.ts allServices",
            level=1,
        ))
        nodes.append(node(
            "paragraph", t["subtitle"],
            "ServicePage.tsx:384-390 -> i18n/ns/service.ts subtitle",
        ))

    if query is None:
        nodes.append(node(
            "placeholder", t["searchPlaceholder"],
            "ServicePage.tsx:397 -> i18n/ns/service.ts searchPlaceholder",
        ))
    else:
        # A field with a value shows the value, not the placeholder — and the
        # source reveals a "Clear" affordance beside it, keyed on the RAW
        # `searchQuery` (`ServicePage.tsx:402-409`).
        nodes.append(node(
            "input", query,
            "ServicePage.tsx:395-401 -> the citizen's own text",
        ))
        nodes.append(node(
            "button", t["clear"],
            "ServicePage.tsx:402-409 -> i18n/ns/service.ts clear",
        ))
    return nodes


def category_label(service_ns, locale):
    """`<p className="… uppercase …">{t("categories")}</p>` — :418-420.

    `text-transform: uppercase` is a RENDERING transform: the DOM text is
    "Categories" and what the citizen sees is "CATEGORIES". Tier 1 compares
    what the page presents, so the oracle records the transformed form. Lao has
    no case, so `.toUpperCase()` is the identity there — which is why the two
    locales differ in shape here and that is correct, not a bug.
    """
    raw = service_ns[locale]["categories"]
    return node(
        "label", raw.upper(),
        "ServicePage.tsx:418-420 (CSS uppercase) -> i18n/ns/service.ts categories",
    )


def build(service_ns, home_ns, seeds, categories, services, locale):
    t = service_ns[locale]
    counts: dict = {}
    for row in services:
        counts[row["category_code"]] = counts.get(row["category_code"], 0) + 1

    views = OrderedDict()

    # ── category view, four states ───────────────────────────────────────────
    base = header_nodes(service_ns, seeds, categories, locale)

    views["categories.loading"] = (
        base + [category_label(service_ns, locale)]
    )

    data = base + [category_label(service_ns, locale)]
    for row in categories:
        code = row["code"]
        count = counts.get(code, 0)
        data.append(node(
            "cardTitle", bilingual(row["name"], locale),
            "ServicePage.tsx:457-459 -> /service-categories name",
        ))
        data.append(node(
            "cardBody", seeds.get(code, {}).get(locale, ""),
            "ServicePage.tsx:460-462 -> ServicePage.tsx CATEGORIES desc",
        ))
        data.append(node(
            "cardMeta",
            interpolate(t["serviceCount"], count=count) if count > 0
            else t["comingSoon"],
            "ServicePage.tsx:463-470 -> i18n/ns/service.ts "
            "serviceCount|comingSoon",
        ))
    views["categories.data"] = data

    views["categories.empty"] = base + [
        category_label(service_ns, locale),
        node("panelMessage", COPY[locale]["noCategories"],
             "ServicePage.tsx:433-441 -> COPY.noCategories"),
    ]

    views["categories.error"] = base + [
        category_label(service_ns, locale),
        node("panelMessage", COPY[locale]["categoriesError"],
             "ServicePage.tsx:425-432 -> COPY.categoriesError"),
        node("panelHint", COPY[locale]["errorHint"],
             "ServicePage.tsx:272 -> COPY.errorHint"),
        node("button", COPY[locale]["retry"],
             "ServicePage.tsx:273-280 -> COPY.retry"),
    ]

    # ── list view, four states ───────────────────────────────────────────────
    drill = header_nodes(
        service_ns, seeds, categories, locale, category_code=LIST_CATEGORY
    )

    views["list.loading"] = list(drill)

    rows = [s for s in services if s["category_code"] == LIST_CATEGORY]
    cards = list(drill)
    for row in rows:
        cards.append(node(
            "cardTitle", bilingual(row["name"], locale),
            "ServiceCard.tsx:63-68 -> /services name",
        ))
        cards.append(node(
            "cardBody", bilingual(row["description"], locale),
            "ServiceCard.tsx:69-74 -> /services description",
        ))
        cards.append(node(
            "cardMeta", format_fee(row, locale),
            "ServiceCard.tsx:80-96 -> serviceConfig.ts formatFee(/services "
            "fee_lak, fee_max_lak, fee_is_range)",
        ))
        cards.append(node(
            "chip", home_ns[locale]["applyNow"],
            "ServiceCard.tsx:97-106 -> i18n/ns/home.ts applyNow "
            "(the HOME namespace, per useT(\"home\") at :18)",
        ))
    views["list.data"] = cards

    views["list.error"] = drill + [
        node("panelMessage", COPY[locale]["servicesError"],
             "ServicePage.tsx:490-496 -> COPY.servicesError"),
        node("panelHint", COPY[locale]["errorHint"],
             "ServicePage.tsx:272 -> COPY.errorHint"),
        node("button", COPY[locale]["retry"],
             "ServicePage.tsx:273-280 -> COPY.retry"),
    ]

    views["list.empty.category"] = drill + [
        node("panelMessage", t["emptyTitle"],
             "ServicePage.tsx:514-516 -> i18n/ns/service.ts emptyTitle"),
        node("panelHint", t["emptyDesc"],
             "ServicePage.tsx:517-519 -> i18n/ns/service.ts emptyDesc"),
        node("button", t["browseOther"],
             "ServicePage.tsx:520-528 -> i18n/ns/service.ts browseOther "
             "(rendered only while a category is active)"),
    ]

    # Searched, no category: the header stays on "All Services", a result-count
    # line appears, and there is no "browse other categories" pill because
    # there is no category to leave.
    searched = header_nodes(
        service_ns, seeds, categories, locale, query=EMPTY_QUERY
    )
    views["list.empty.search"] = searched + [
        node("label",
             interpolate(t["resultsFor"], count=0, q=EMPTY_QUERY),
             "ServicePage.tsx:479-486 -> i18n/ns/service.ts resultsFor"),
        node("panelMessage", t["emptyTitle"],
             "ServicePage.tsx:514-516 -> i18n/ns/service.ts emptyTitle"),
        node("panelHint", t["emptyDesc"],
             "ServicePage.tsx:517-519 -> i18n/ns/service.ts emptyDesc"),
    ]

    return views


# `COPY` — ServicePage.tsx:226-235, the five sentences the source keeps inline
# rather than in the `service` dictionary. Transcribed here rather than parsed
# because the object is nested two deep and a scanner for it would be longer
# than the table.
COPY = {
    "en": {
        "categoriesError": "Could not load the categories.",
        "servicesError": "Could not load the services.",
        "errorHint": "Check your connection and try again.",
        "retry": "Retry",
        "noCategories": "No categories are published yet.",
    },
    "lo": {
        "categoriesError": "ບໍ່ສາມາດໂຫຼດໝວດໝູ່ໄດ້.",
        "servicesError": "ບໍ່ສາມາດໂຫຼດບໍລິການໄດ້.",
        "errorHint": "ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ ແລະ ລອງໃໝ່ອີກຄັ້ງ.",
        "retry": "ລອງໃໝ່",
        "noCategories": "ຍັງບໍ່ມີໝວດໝູ່ທີ່ເຜີຍແຜ່ເທື່ອ.",
    },
}


def main() -> int:
    service_ns = parse_ns("service")
    home_ns = parse_ns("home")
    seeds = parse_category_seeds()
    categories = load_api("service-categories")
    services = load_api("services")

    provenance = OrderedDict()
    provenance["web_commit"] = WEB_COMMIT
    provenance["baseline"] = "docs/fidelity-baseline/2026-08-13"
    provenance["derived_by"] = "test/fidelity/derive_oracles.py"
    provenance["method"] = (
        "Static derivation from the port source, its i18n dictionaries and the "
        "recorded staging payloads in oracle/api/ — all three pinned to "
        "web_commit. No browser, no capture rig (specs.md § 6.5.3)."
    )
    provenance["api_snapshot"] = OrderedDict(
        [
            ("service-categories", f"{len(categories)} rows"),
            ("services", f"{len(services)} rows"),
        ]
    )

    for locale in LOCALES:
        doc = OrderedDict()
        doc["schema"] = "tier1/1"
        doc["provenance"] = provenance
        doc["route"] = "/service"
        doc["locale"] = locale
        doc["note"] = (
            "`views` maps a page state to the ORDERED list of text the web "
            "presents in it. Tier 1 passes when the Flutter page in the same "
            "state presents the same strings in the same order."
        )
        doc["views"] = build(
            service_ns, home_ns, seeds, categories, services, locale
        )

        path = os.path.join(ORACLE, "tier1", f"service.{locale}.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(doc, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        total = sum(len(v) for v in doc["views"].values())
        print(f"wrote {path}  ({len(doc['views'])} views, {total} nodes)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
