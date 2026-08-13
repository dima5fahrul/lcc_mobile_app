#!/usr/bin/env python3
"""Derive the Tier 1 oracle for `/` (Home) from the port source at 62f8a529.

Companion to `derive_oracles.py`, which did the same for `/service` in B2a.
§ 3.1's B2b column does not list `docs/fidelity-baseline/.../oracle/**` — it
lists only `lib/features/home/**`, four shared files and `test/features/home/**`
— yet B2-AC-8 makes Tier 1 blocking for **every** sub-batch and Tier 1 runs
against a versioned oracle per route per locale (§ 6.5.3). There is no oracle
for `/`. Landing one is therefore a required deviation from the file list, and
it is reported as such rather than performed quietly.

WHAT THIS DERIVES, AND WHAT IT CANNOT
=====================================

Derivable, and emitted below — every string is a dictionary lookup, a
compile-time table or a field of a recorded payload:

  hero            the greeting, the LaoID card's labels, the masked specimen,
                  the sign-in hint, the search placeholder
  services.header the section title, its blurb, and the two chips
  services.data   the six phase-1 cards from the RECORDED /services payload,
                  plus the More tile
  services.empty  · services.error   · search.empty
  categories.header · news.header · faq.header
  news.empty · news.error · faq.empty · faq.error
  categories.slide.<code>  the eight compile-time slides

NOT derivable, and deliberately absent:

  news.data   `/news?per_page=3&featured=true` was never recorded. B2a captured
              two endpoints (`/services`, `/service-categories`) and this is
              not one of them. The card also prints `formatDate(...)`, which
              `test/fidelity/README.md`'s known limit 3 already flags as the
              case this instrument cannot derive: "a page with a date formatter
              or a relative timestamp is not [derivable]".
  faq.data    `/help/faqs?per_page=5` was likewise never recorded.
  summary.*   `/me/home-summary` and `/me/digital-id` need an authenticated
              staging identity, which is F0's blocking question (§ 6.5.2(b)).

Those four are reported **NOT EVALUATED for Tier 1** with this reason, by name.
Inventing a payload and calling the result an oracle would be worse than the
gap: it would compare the page against the fixture the same author wrote.

USAGE
=====

    python3 test/fidelity/derive_home_oracle.py

Reads the port source, its i18n dictionaries and `oracle/api/`, all pinned to
62f8a529 — the same commit as the screenshots, so this is a *derivation* and
not a re-baseline. It does not run during `flutter test`, by design: a gate
that regenerates its own expectation each run cannot fail.
"""

import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))   # …/lcc_mobile_app/test/fidelity
PKG = os.path.dirname(os.path.dirname(HERE))        # …/sources/lcc_mobile_app
PROJECT = os.path.dirname(os.path.dirname(PKG))     # …/projects/lcc-mobile-app
WEB = os.path.join(PROJECT, "sources", "lcc-app")
ORACLE = os.path.join(PROJECT, "docs", "fidelity-baseline", "2026-08-13", "oracle")

WEB_COMMIT = "62f8a529aaa024a8b35b0af50a8fbd4850a63962"
LOCALES = ("en", "lo")


def check_commit():
    """§ 8.3: an oracle spanning two web commits is unattributable."""
    head = subprocess.check_output(
        ["git", "-C", WEB, "rev-parse", "HEAD"], text=True
    ).strip()
    if head != WEB_COMMIT:
        sys.exit(
            f"STOP AND ESCALATE: sources/lcc-app is at {head}, not "
            f"{WEB_COMMIT}. Re-deriving from a different web commit is a "
            f"re-baseline (§ 6.5.3) and needs an explicit logged act plus "
            f"architect approval."
        )


def read(*parts):
    with open(os.path.join(WEB, *parts), encoding="utf-8") as f:
        return f.read()


# ── i18n ─────────────────────────────────────────────────────────────────────

def parse_ns(source, lang):
    """Pull `{ key: "value", … }` out of one `ns({ en: {...}, lo: {...} })`."""
    start = source.index(f"{lang}: {{")
    depth, i = 0, source.index("{", start)
    begin = i
    while True:
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                break
        i += 1
    body = source[begin + 1 : i]

    out = {}
    for m in re.finditer(r'(\w+)\s*:\s*"((?:[^"\\]|\\.)*)"', body):
        # Unescape by hand rather than via `unicode_escape`: these files hold
        # literal UTF-8 Lao, and `unicode_escape` round-trips through latin-1,
        # which turns every Lao code point into mojibake. The only escapes the
        # dictionaries actually use are `\"` and `\'`.
        out[m.group(1)] = re.sub(
            r"\\(.)",
            lambda mm: {"n": "\n", "t": "\t"}.get(mm.group(1), mm.group(1)),
            m.group(2),
        )
    return out


def dictionaries():
    d = {}
    for lang in LOCALES:
        d[lang] = {
            "home": parse_ns(read("src/app/i18n/ns/home.ts"), lang),
            "hero": parse_ns(read("src/app/i18n/ns/hero.ts"), lang),
            "common": parse_ns(read("src/app/i18n/ns/common.ts"), lang),
        }
    return d


# ── HomePage.tsx's inline COPY block (:59-93) ────────────────────────────────

def parse_copy():
    src = read("src/app/components/HomePage.tsx")
    block = src[src.index("const COPY = {") : src.index("} as const;")]
    out = {"en": {}, "lo": {}}
    for m in re.finditer(
        r'(\w+):\s*\{\s*en:\s*"((?:[^"\\]|\\.)*)",\s*lo:\s*"((?:[^"\\]|\\.)*)"',
        block,
        re.S,
    ):
        out["en"][m.group(1)] = m.group(2)
        out["lo"][m.group(1)] = m.group(3)
    return out


# ── CATEGORY_SLIDES x CATEGORIES ─────────────────────────────────────────────

def parse_slides():
    home = read("src/app/components/HomePage.tsx")
    block = home[home.index("const CATEGORY_SLIDES = [") : home.index("] as const;")]
    slides = {}
    for m in re.finditer(
        r'\{\s*id:\s*"([\w-]+)",\s*img:\s*\w+,\s*en:\s*"([^"]*)",\s*lo:\s*"([^"]*)"',
        block,
    ):
        slides[m.group(1)] = {"en": m.group(2), "lo": m.group(3)}

    svc = read("src/app/components/ServicePage.tsx")
    cats = svc[svc.index("export const CATEGORIES") : svc.index("export const SERVICES")]
    labels = {}
    for m in re.finditer(
        r'\{\s*id:\s*"([\w-]+)",\s*label:\s*"([^"]*)",\s*labelLo:\s*"([^"]*)"',
        cats,
    ):
        labels[m.group(1)] = {"en": m.group(2), "lo": m.group(3)}

    order = list(slides)
    return [
        {
            "code": code,
            "label": labels[code],
            "blurb": slides[code],
        }
        for code in order
        if code in labels
    ]


# ── The recorded catalogue ───────────────────────────────────────────────────

def phase1_services():
    with open(os.path.join(ORACLE, "api", "services.json"), encoding="utf-8") as f:
        rows = json.load(f)["data"]
    return [r for r in rows if r.get("is_phase1")]


def group_thousands(n):
    return f"{n:,}"


def format_fee(row, lang):
    """`formatFee` — serviceConfig.ts:46-53, against the wire row."""
    fee, fee_max = row.get("fee_lak", 0), row.get("fee_max_lak", 0)
    is_range = row.get("fee_is_range") and fee_max > fee
    if is_range:
        pair = f"{group_thousands(fee)}–{group_thousands(fee_max)}"
        return f"{pair} ກີບ" if lang == "lo" else f"{pair} LAK"
    if fee == 0:
        return "ຟຣີ" if lang == "lo" else "Free"
    return (
        f"{group_thousands(fee)} ກີບ"
        if lang == "lo"
        else f"{group_thousands(fee)} LAK"
    )


def mask_value(value, keep=" "):
    """`maskValue` — Hero.tsx:25-38."""
    chars = list(value)
    first = last = -1
    for i, c in enumerate(chars):
        if c not in keep:
            if first == -1:
                first = i
            last = i
    return "".join(
        c if (c in keep or i == first or i == last) else "•"
        for i, c in enumerate(chars)
    )


SPECIMEN_UIN = "1-2540-08842-15"
SPECIMEN_NAME = {"en": "Bounmy Sisavath", "lo": "ບຸນມີ ສີສະຫວັດ"}


# ── Views ────────────────────────────────────────────────────────────────────

def node(role, text, source, level=None):
    n = {"role": role, "text": text, "source": source}
    if level is not None:
        n["level"] = level
    return n


def build(lang, d, copy, slides, services):
    home, hero = d[lang]["home"], d[lang]["hero"]
    c = copy[lang]
    views = {}

    # ── hero, signed out ─────────────────────────────────────────────────────
    views["hero.signedOut"] = [
        node("heading", home["greeting"], "Hero.tsx:94", 1),
        node("cardTitle", hero["idCardBrand"], "Hero.tsx:210"),
        node("cardMeta", hero["idCardSub"], "Hero.tsx:213"),
        node("chip", hero["idVerified"], "Hero.tsx:219"),
        # The portrait strip. Signed out, `authenticated` is false, so the
        # source takes the ELSE branch at :238 and draws the initial tile —
        # `displayName.trim().charAt(0).toUpperCase()` over the *unmasked*
        # specimen name. `charAt(0)` is one UTF-16 code unit, which for the Lao
        # specimen is the consonant alone ("ບ") and not the grapheme cluster
        # ("ບຸ"); the port matches `charAt`, so this does too.
        node("cardTitle", SPECIMEN_NAME[lang].strip()[0].upper(),
             "Hero.tsx:244"),
        node("label", hero["idName"].upper(), "Hero.tsx:250"),
        node("cardBody", mask_value(SPECIMEN_NAME[lang]), "Hero.tsx:253"),
        node("label", hero["idUin"].upper(), "Hero.tsx:258"),
        node("cardBody", mask_value(SPECIMEN_UIN, " -"), "Hero.tsx:261"),
        node(
            "cardMeta",
            f'{hero["idNationality"].upper()} {hero["idNationalityValue"]}',
            "Hero.tsx:277-284",
        ),
        node("button", hero["idSignIn"], "Hero.tsx:311"),
        node("placeholder", home["searchPlaceholder"], "HomePage.tsx:296"),
    ]

    # ── the services section's chrome ────────────────────────────────────────
    views["services.header"] = [
        node("heading", home["whatDoYouNeed"], "HomePage.tsx:430", 2),
        node("paragraph", home["whatDoYouNeedSub"], "HomePage.tsx:433"),
        node("button", home["customize"], "HomePage.tsx:443"),
        node("button", home["howItWorks"], "HomePage.tsx:451"),
    ]

    # ── the six quick actions, from the recording, plus the More tile ────────
    cards = []
    for row in services:
        cards.append(node("cardTitle", row["name"][lang], "ServiceCard.tsx:66"))
        cards.append(node("cardBody", row["description"][lang], "ServiceCard.tsx:72"))
        cards.append(node("cardMeta", format_fee(row, lang), "ServiceCard.tsx:88"))
        cards.append(node("chip", home["applyNow"], "ServiceCard.tsx:104"))
    cards.append(node("cardTitle", home["more"], "HomePage.tsx:516"))
    cards.append(node("cardBody", home["browseAll"], "HomePage.tsx:527"))
    views["services.data"] = cards

    views["services.empty"] = [
        node("panelMessage", c["servicesEmpty"], "HomePage.tsx:478"),
    ]
    views["services.error"] = [
        node("panelMessage", c["servicesError"], "HomePage.tsx:469"),
        node("button", c["retry"], "HomePage.tsx:472"),
    ]
    views["search.empty"] = [
        node("panelMessage", home["noServicesFound"], "HomePage.tsx:535"),
    ]

    # ── the three section headers ────────────────────────────────────────────
    views["categories.header"] = [
        node("heading", home["categoriesTitle"], "HomePage.tsx:543", 2),
        node("paragraph", home["categoriesSubtitle"], "HomePage.tsx:543"),
    ]
    views["news.header"] = [
        node("heading", home["latestUpdates"], "HomePage.tsx:616", 2),
        node("paragraph", home["latestUpdatesSub"], "HomePage.tsx:616"),
    ]
    views["faq.header"] = [
        node("heading", home["faqTitle"], "HomePage.tsx:739", 2),
        node("paragraph", home["faqSubtitle"], "HomePage.tsx:739"),
    ]

    # ── the eight compile-time slides ────────────────────────────────────────
    for slide in slides:
        views[f'categories.slide.{slide["code"]}'] = [
            node("heading", slide["label"][lang], "HomePage.tsx:579", 3),
            node("paragraph", slide["blurb"][lang], "HomePage.tsx:582"),
            node("chip", home["seeService"], "HomePage.tsx:585"),
        ]

    # ── news and FAQ: the states that do NOT need a recorded payload ─────────
    views["news.empty"] = [
        node("panelMessage", c["newsEmpty"], "HomePage.tsx:642"),
    ]
    views["news.error"] = [
        node("panelMessage", c["newsError"], "HomePage.tsx:633"),
        node("button", c["retry"], "HomePage.tsx:636"),
    ]
    views["news.viewAll"] = [
        node("button", home["newsViewAll"], "HomePage.tsx:731"),
    ]
    views["faq.empty"] = [
        node("panelMessage", c["faqEmpty"], "HomePage.tsx:747"),
    ]
    views["faq.error"] = [
        # The source has no retry control here; § 6.6 and B2-AC-16 require one,
        # so the Flutter page adds it and the oracle records the addition
        # rather than pretending the web has it.
        node("panelMessage", c["faqError"], "HomePage.tsx:747"),
        node("button", c["retry"], "ADDED by B2b — § 6.6 / B2-AC-16"),
    ]
    views["faq.browseAll"] = [
        node("button", home["faqBrowseAll"], "HomePage.tsx:781"),
    ]

    return views


def main():
    check_commit()
    d, copy, slides, services = (
        dictionaries(),
        parse_copy(),
        parse_slides(),
        phase1_services(),
    )

    assert len(slides) == 8, f"expected 8 category slides, got {len(slides)}"
    assert len(services) == 6, f"expected 6 phase-1 services, got {len(services)}"

    out_dir = os.path.join(ORACLE, "tier1")
    os.makedirs(out_dir, exist_ok=True)

    for lang in LOCALES:
        doc = {
            "route": "/",
            "locale": lang,
            "provenance": {
                "web_commit": WEB_COMMIT,
                "baseline": "docs/fidelity-baseline/2026-08-13",
                "derived_by": "test/fidelity/derive_home_oracle.py",
                "not_evaluated": {
                    "news.data": "`/news?per_page=3&featured=true` was never "
                    "recorded (B2a captured /services and /service-categories "
                    "only), and the card prints formatDate() — README known "
                    "limit 3.",
                    "faq.data": "`/help/faqs?per_page=5` was never recorded either, so the five questions have no oracle to compare against; B2c owns that endpoint.",
                    "summary.tiles": "`/me/home-summary` is enabled: "
                    "isAuthenticated; the 2026-08-13 baseline was captured "
                    "signed out and recording it needs a test citizen "
                    "identity (F0, § 6.5.2(b)).",
                    "digitalId.card": "`/me/digital-id` is authenticated for the same reason and has no recording; the card LABELS are gated under hero.signedOut, only the issued values are not.",
                },
            },
            "views": build(lang, d, copy, slides, services),
        }
        path = os.path.join(out_dir, f"home.{lang}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(doc, f, ensure_ascii=False, indent=2, sort_keys=True)
            f.write("\n")
        total = sum(len(v) for v in doc["views"].values())
        print(f"{path}: {len(doc['views'])} views, {total} nodes")


if __name__ == "__main__":
    main()
