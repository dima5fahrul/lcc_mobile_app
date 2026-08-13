#!/usr/bin/env python3
"""Derive the Tier 1 oracles for `/news`, `/news/:slug` and `/help` at 62f8a529.

Third in the series after `derive_oracles.py` (B2a, `/service`) and
`derive_home_oracle.py` (B2b, `/`). Same contract, same caveat about scope:
§ 3.1's B2c column lists `lib/features/{news,help}/**`, four shared files and
`test/features/{news,help}/**` — it does NOT list
`docs/fidelity-baseline/.../oracle/**`. Yet B2-AC-8 makes Tier 1 blocking for
every sub-batch and Tier 1 runs against a versioned oracle per route per locale
(§ 6.5.3). Landing three is therefore a required deviation from the file list,
reported as such rather than performed quietly — exactly as B2b reported the
same deviation for `home.{en,lo}.json`.

WHAT IS DERIVABLE HERE THAT WAS NOT FOR HOME
============================================

B2b could not derive `news.data` or `faq.data` because B2a had recorded only
`/services` and `/service-categories`. **B2c recorded the missing payloads** —
all seven content endpoints, live from staging through the same reverse-proxy
rig, at the same commit — so the row-bearing views ARE derivable here:

    oracle/api/news.json                              6 articles
    oracle/api/news-categories.json                   4 categories
    oracle/api/news-article-<slug>.json               1 article, with body
    oracle/api/help-categories.json                   4 topics
    oracle/api/help-faqs.json                        10 of 11 questions (page 1)
    oracle/api/help-articles.json                     2 guides
    oracle/api/help-article-<slug>.json               1 guide, with body
    oracle/api/help-channels.json                     4 channels

THE DATES ARE NOT DERIVED FROM THE DART PORT
============================================

`test/fidelity/README.md`'s known limit 3 flags a page with a date formatter as
the case this instrument cannot derive, and names B2c's news page as the one to
check. Checked: it IS derivable, because the formatter is
`toLocaleDateString(lang === "lo" ? "lo-LA" : "en-GB", {day:"2-digit",
month:"short", year:"numeric"})` — pure ICU with no relative component.

So this script shells out to **node's own Intl**, not to a table copied from
`news_formatting.dart`. That matters: a table-derived oracle would compare the
Dart port against a transcription of itself. Going through ICU makes the month
names an independent expectation — and it is what caught that en-GB's
September abbreviation is the four-letter `Sept`, not `Sep`.

USAGE
=====

    python3 test/fidelity/derive_content_oracles.py

Requires `node` on PATH (for Intl only — no network, no npm). Does not run
during `flutter test`, by design: a gate that regenerates its own expectation
each run cannot fail.
"""

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(os.path.dirname(HERE))
PROJECT = os.path.dirname(os.path.dirname(PKG))
WEB = os.path.join(PROJECT, "sources", "lcc-app")
ORACLE = os.path.join(PROJECT, "docs", "fidelity-baseline", "2026-08-13", "oracle")

WEB_COMMIT = "62f8a529aaa024a8b35b0af50a8fbd4850a63962"
LOCALES = ("en", "lo")

# The article slot 15 was captured against, and the guide whose body is
# recorded.
DETAIL_SLUG = "lao-citizen-center-goes-live"
GUIDE_SLUG = "how-to-apply-residence-certificate"


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


def read_web(*parts):
    with open(os.path.join(WEB, *parts), encoding="utf-8") as f:
        return f.read()


def api(name):
    with open(os.path.join(ORACLE, "api", f"{name}.json"), encoding="utf-8") as f:
        return json.load(f)


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
    for m in __import__("re").finditer(r'(\w+)\s*:\s*"((?:[^"\\]|\\.)*)"', body):
        # Unescaped by hand rather than via `unicode_escape`, which round-trips
        # through latin-1 and turns every Lao code point into mojibake.
        out[m.group(1)] = __import__("re").sub(
            r"\\(.)",
            lambda mm: {"n": "\n", "t": "\t"}.get(mm.group(1), mm.group(1)),
            m.group(2),
        )
    return out


def dictionaries():
    return {
        lang: {
            "news": parse_ns(read_web("src/app/i18n/ns/news.ts"), lang),
            "help": parse_ns(read_web("src/app/i18n/ns/help.ts"), lang),
            "common": parse_ns(read_web("src/app/i18n/ns/common.ts"), lang),
        }
        for lang in LOCALES
    }


# ── The strings the components inline rather than looking up ─────────────────
#
# `const L = (lang, en, lo) => lang === "lo" ? lo : en`. Transcribed from the
# call sites, with the line each came from, because they are copy the
# dictionaries do not carry.
INLINE = {
    "retry": ("Try again", "ລອງໃໝ່", "NewsPage.tsx:147 / HelpCenterPage.tsx:79"),
    "previousPage": ("Previous page", "ໜ້າກ່ອນ", "NewsPage.tsx:210"),
    "nextPage": ("Next page", "ໜ້າຕໍ່ໄປ", "NewsPage.tsx:221"),
    "guidesTitle": (
        "Step-by-step guides",
        "ຄູ່ມືເທື່ອລະຂັ້ນຕອນ",
        "HelpCenterPage.tsx:393",
    ),
    "guidesEmpty": (
        "No guides have been published yet.",
        "ຍັງບໍ່ມີຄູ່ມືທີ່ເຜີຍແຜ່.",
        "HelpCenterPage.tsx:407",
    ),
    "helpfulPrompt": (
        "Was this helpful?",
        "ຄຳຕອບນີ້ຊ່ວຍໄດ້ບໍ?",
        "HelpCenterPage.tsx:335",
    ),
    "feedbackThanks": (
        "Thanks for the feedback",
        "ຂອບໃຈສຳລັບຄຳຄິດເຫັນ",
        "HelpCenterPage.tsx:354",
    ),
}


def inline(key, lang):
    en, lo, _ = INLINE[key]
    return lo if lang == "lo" else en


def inline_src(key):
    return INLINE[key][2]


# ── Dates, through node's ICU ────────────────────────────────────────────────


def icu_dates(values):
    """`{value: {en: …, lo: …}}` via `toLocaleDateString`, not via a table."""
    script = """
    const vs = JSON.parse(process.argv[1]);
    const out = {};
    for (const v of vs) {
      if (!v) { out[v] = { en: "", lo: "" }; continue; }
      const d = new Date(v);
      if (Number.isNaN(d.getTime())) { out[v] = { en: v, lo: v }; continue; }
      const o = { day: "2-digit", month: "short", year: "numeric" };
      out[v] = {
        en: d.toLocaleDateString("en-GB", o),
        lo: d.toLocaleDateString("lo-LA", o),
      };
    }
    process.stdout.write(JSON.stringify(out));
    """
    raw = subprocess.check_output(
        ["node", "-e", script, json.dumps(sorted(set(values)))], text=True
    )
    return json.loads(raw)


# ── text(value, lang) — types.ts:17-22 ───────────────────────────────────────


def text(value, lang):
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    wanted = value.get("lo" if lang == "lo" else "en") or ""
    return wanted or value.get("en") or value.get("lo") or ""


def node(role, txt, source, level=None):
    n = {"role": role, "text": txt, "source": source}
    if level is not None:
        n["level"] = level
    return n


# ── /news ────────────────────────────────────────────────────────────────────


def build_news(lang, d, articles, categories, dates):
    t = d[lang]["news"]
    views = {}

    views["header"] = [
        node("heading", t["title"], "NewsPage.tsx:78", 1),
        node("paragraph", t["subtitle"], "NewsPage.tsx:79"),
    ]

    views["chips.data"] = [node("button", t["allCategories"], "NewsPage.tsx:101")] + [
        node("button", text(c["name"], lang), "NewsPage.tsx:117")
        for c in categories
    ]

    views["chips.empty"] = [
        node("button", t["allCategories"], "NewsPage.tsx:101"),
    ]

    # NOT in the source: `:103` renders `(categories.data ?? []).map(...)` with
    # no error branch at all. § 6.6 / B2-AC-16 make error-with-retry mandatory
    # per network-backed surface, so B2c adds one — recorded here as an
    # addition rather than smuggled into the diff.
    views["chips.error"] = [
        node("button", t["allCategories"], "NewsPage.tsx:101"),
        node("panelMessage", CHIP_ERROR[lang], "ADDED by B2c — § 6.6 / B2-AC-16"),
        node("button", inline("retry", lang), "ADDED by B2c — § 6.6 / B2-AC-16"),
    ]

    cards = []
    for a in articles:
        cards.append(node("chip", text(a["category_name"], lang), "NewsPage.tsx:181"))
        cards.append(
            node(
                "cardMeta",
                dates[a.get("published_date") or a.get("published_at") or ""][lang],
                "NewsPage.tsx:183 (via Intl, not a transcribed month table)",
            )
        )
        cards.append(node("cardTitle", text(a["title"], lang), "NewsPage.tsx:186"))
        cards.append(node("cardBody", text(a["excerpt"], lang), "NewsPage.tsx:189"))
        cards.append(node("chip", t["readMore"], "NewsPage.tsx:195"))
    views["list.data"] = cards

    views["list.empty"] = [node("panelMessage", t["empty"], "NewsPage.tsx:151")]

    views["list.error"] = [
        # The source prints `list.error.message`, the BACKEND's sentence
        # (`:141`). The port shows a fixed bilingual one instead —
        # `ServicePage.tsx:227-232`'s behaviour, the branch B2a already ported —
        # because a server string on a citizen-facing page leaks backend detail.
        node("panelMessage", LIST_ERROR[lang], "NewsPage.tsx:141 (fixed copy, not error.message)"),
        node("button", inline("retry", lang), "NewsPage.tsx:147"),
    ]

    return views


# ── /news/:slug ──────────────────────────────────────────────────────────────


def build_news_detail(lang, d, article, catalogue, dates):
    t = d[lang]["news"]
    views = {}

    views["chrome"] = [node("cardTitle", t["title"], "NewsDetailPage.tsx:183")]

    meta = [
        node("chip", text(article["category_name"], lang), "NewsDetailPage.tsx:206"),
        node(
            "cardMeta",
            dates[article.get("published_date") or ""][lang],
            "NewsDetailPage.tsx:209 (via Intl)",
        ),
    ]
    if article.get("read_minutes", 0) > 0:
        n = article["read_minutes"]
        meta.append(
            node(
                "cardMeta",
                f"ອ່ານ {n} ນາທີ" if lang == "lo" else f"{n} min read",
                "NewsDetailPage.tsx:214",
            )
        )
    if article.get("view_count", 0) > 0:
        meta.append(
            node("cardMeta", str(article["view_count"]), "NewsDetailPage.tsx:220")
        )

    body = text(article.get("body"), lang)
    paragraphs = [p.strip() for p in body.split("\n") if p.strip()]
    if not paragraphs:
        paragraphs = [text(article["excerpt"], lang)]

    article_view = (
        [node("cardTitle", t["title"], "NewsDetailPage.tsx:183")]
        + meta
        + [node("heading", text(article["title"], lang), "NewsDetailPage.tsx:226", 1)]
        + [node("paragraph", p, "NewsDetailPage.tsx:229") for p in paragraphs]
    )

    # `tags.find(tag => tag in TAB_TO_PATH) ?? (category === "service" ?
    #  "service" : undefined)` — :165-167.
    tabs = set(parse_tab_to_path())
    related = next((tag for tag in article.get("tags", []) if tag in tabs), None)
    if related is None and article.get("category") == "service":
        related = "service"
    if related is not None:
        article_view += [
            node("label", t["relatedTitle"].upper(), "NewsDetailPage.tsx:239"),
            node("paragraph", t["relatedDesc"], "NewsDetailPage.tsx:241"),
            node("button", t["openService"], "NewsDetailPage.tsx:247"),
        ]

    more = [a for a in catalogue if a["slug"] != article["slug"]][:3]
    if more:
        article_view.append(
            node("heading", t["moreNews"], "NewsDetailPage.tsx:256", 2)
        )
        for a in more:
            article_view.append(
                node("chip", text(a["category_name"], lang), "NewsDetailPage.tsx:280")
            )
            article_view.append(
                node("cardTitle", text(a["title"], lang), "NewsDetailPage.tsx:282")
            )

    views["detail.data"] = article_view

    views["detail.missing"] = [
        node("panelMessage", t["empty"], "NewsDetailPage.tsx:144"),
        node("button", t["backToNews"], "NewsDetailPage.tsx:151"),
    ]

    views["detail.error"] = [
        node(
            "panelMessage",
            DETAIL_ERROR[lang],
            "NewsDetailPage.tsx:120 (fixed copy, not error.message)",
        ),
        node("button", inline("retry", lang), "NewsDetailPage.tsx:126"),
        node("button", t["backToNews"], "NewsDetailPage.tsx:134"),
    ]

    views["detail.loading"] = [
        node("cardTitle", t["title"], "NewsDetailPage.tsx:100"),
    ]

    return views


def parse_tab_to_path():
    src = read_web("src/app/routes.ts")
    block = src[src.index("TAB_TO_PATH") : src.index("const PATH_TO_TAB")]
    return __import__("re").findall(r'"?([\w-]+)"?\s*:\s*"/', block)


# ── /help ────────────────────────────────────────────────────────────────────


def build_help(lang, d, categories, faqs, faq_meta, guides, guide, channels):
    t = d[lang]["help"]
    c = d[lang]["common"]
    views = {}

    views["header"] = [
        node("heading", t["title"], "HelpCenterPage.tsx:175", 1),
        node("paragraph", t["subtitle"], "HelpCenterPage.tsx:176"),
        node("placeholder", t["searchPlaceholder"], "HelpCenterPage.tsx:189"),
    ]
    # `tc("back")` — the COMMON namespace, not help's. Only reachable as an
    # aria-label, so it is recorded for completeness rather than dumped.
    views["header.backLabel"] = [
        node("label", c["back"], "HelpCenterPage.tsx:164"),
    ]

    views["topics.data"] = [
        node("button", t["allTopics"], "HelpCenterPage.tsx:224")
    ] + [
        node("button", text(cat["name"], lang), "HelpCenterPage.tsx:245")
        for cat in categories
    ]

    views["topics.error"] = [
        node("button", t["allTopics"], "HelpCenterPage.tsx:224"),
        node("panelMessage", TOPIC_ERROR[lang], "ADDED by B2c — § 6.6 / B2-AC-16"),
        node("button", inline("retry", lang), "ADDED by B2c — § 6.6 / B2-AC-16"),
    ]

    total = faq_meta["total"]
    views["results.count"] = [
        node(
            "paragraph",
            t["resultsOne"]
            if total == 1
            else t["resultsMany"].replace("{count}", str(total)),
            "HelpCenterPage.tsx:254",
        )
    ]

    rows = []
    for a in faqs:
        rows.append(node("cardTitle", text(a["question"], lang), "HelpCenterPage.tsx:300"))
        # `a.helpful >= 5 && !searching` — :302.
        if a.get("helpful", 0) >= 5:
            rows.append(node("chip", t["popular"], "HelpCenterPage.tsx:305"))
    views["faqs.data"] = rows

    # One question expanded — the answer, the optional deep link, and the vote
    # prompt. Derived for the FIRST row so the view is deterministic.
    first = faqs[0]
    expanded = [
        node("cardTitle", text(first["question"], lang), "HelpCenterPage.tsx:300"),
    ]
    if first.get("helpful", 0) >= 5:
        expanded.append(node("chip", t["popular"], "HelpCenterPage.tsx:305"))
    expanded.append(
        node("cardBody", text(first["answer"], lang), "HelpCenterPage.tsx:319")
    )
    if first.get("category") in CATEGORY_TAB:
        expanded.append(
            node("button", t["relatedService"], "HelpCenterPage.tsx:326")
        )
    expanded.append(
        node("label", inline("helpfulPrompt", lang), inline_src("helpfulPrompt"))
    )
    views["faqs.expanded"] = expanded

    views["faqs.voted"] = [
        node("label", inline("feedbackThanks", lang), inline_src("feedbackThanks")),
    ]

    views["faqs.empty"] = [
        node("panelMessage", t["noResults"], "HelpCenterPage.tsx:272"),
        node("panelHint", t["noResultsDesc"], "HelpCenterPage.tsx:273"),
    ]

    views["faqs.error"] = [
        node(
            "panelMessage",
            FAQ_ERROR[lang],
            "HelpCenterPage.tsx:269 (fixed copy, not error.message)",
        ),
        node("button", inline("retry", lang), "HelpCenterPage.tsx:79"),
    ]

    views["pager"] = [
        node(
            "cardMeta",
            f"{faq_meta['page']} / {faq_meta['total_pages']}",
            "HelpCenterPage.tsx:378",
        )
    ]

    views["guides.header"] = [
        node("heading", inline("guidesTitle", lang), inline_src("guidesTitle"), 2)
    ]
    views["guides.data"] = [
        node("cardTitle", text(g["title"], lang), "HelpCenterPage.tsx:428")
        for g in guides
    ]
    views["guides.empty"] = [
        node("panelMessage", inline("guidesEmpty", lang), inline_src("guidesEmpty"))
    ]
    views["guides.error"] = [
        node("panelMessage", GUIDE_ERROR[lang], "HelpCenterPage.tsx:404"),
        node("button", inline("retry", lang), "HelpCenterPage.tsx:79"),
    ]
    views["guides.expanded"] = [
        node("cardTitle", text(guide["title"], lang), "HelpCenterPage.tsx:428"),
        node("cardBody", text(guide["body"], lang), "HelpCenterPage.tsx:445"),
    ]

    views["stillStuck"] = [
        node("cardTitle", t["stillStuck"], "HelpCenterPage.tsx:465"),
        node("paragraph", t["stillStuckDesc"], "HelpCenterPage.tsx:467"),
    ]

    tiles = []
    for ch in channels:
        tiles.append(node("cardTitle", text(ch["label"], lang), "HelpCenterPage.tsx:507"))
        tiles.append(node("cardBody", ch["value"], "HelpCenterPage.tsx:509"))
        tiles.append(node("cardMeta", text(ch["hours"], lang), "HelpCenterPage.tsx:510"))
    views["channels.data"] = tiles

    views["channels.empty"] = [
        node("button", t["contactSupport"], "HelpCenterPage.tsx:484"),
    ]
    views["channels.error"] = [
        node("panelMessage", CHANNEL_ERROR[lang], "HelpCenterPage.tsx:477"),
        node("button", inline("retry", lang), "HelpCenterPage.tsx:79"),
    ]

    return views


CATEGORY_TAB = {"services": "service", "payments": "wallet", "account": "account"}

# The fixed error sentences the port shows in place of the backend's
# `error.message`. They live in `assets/i18n/{en,lo}.json` under `news.*` /
# `help.*`; recorded here so the oracle states the substitution instead of the
# widget test being the only place it exists.
LIST_ERROR = {"en": "We could not load the news.", "lo": "ພວກເຮົາໂຫຼດຂ່າວບໍ່ໄດ້."}
DETAIL_ERROR = {
    "en": "We could not load this article.",
    "lo": "ພວກເຮົາໂຫຼດບົດຄວາມນີ້ບໍ່ໄດ້.",
}
CHIP_ERROR = {
    "en": "We could not load the categories.",
    "lo": "ພວກເຮົາໂຫຼດໝວດໝູ່ບໍ່ໄດ້.",
}
TOPIC_ERROR = {"en": "We could not load the topics.", "lo": "ພວກເຮົາໂຫຼດຫົວຂໍ້ບໍ່ໄດ້."}
FAQ_ERROR = {"en": "We could not load the questions.", "lo": "ພວກເຮົາໂຫຼດຄຳຖາມບໍ່ໄດ້."}
GUIDE_ERROR = {"en": "We could not load the guides.", "lo": "ພວກເຮົາໂຫຼດຄູ່ມືບໍ່ໄດ້."}
CHANNEL_ERROR = {
    "en": "We could not load the support channels.",
    "lo": "ພວກເຮົາໂຫຼດຊ່ອງທາງຊ່ວຍເຫຼືອບໍ່ໄດ້.",
}


NOT_EVALUATED = {
    "news.pager": (
        "`/news` returns 6 rows at per_page 6, so `meta.total_pages` is 1 and "
        "`NewsPage.tsx:205`'s pager never renders against the recorded "
        "payload. Its copy is identical to `/help`'s (byte-for-byte, both "
        "aria-labels included), which IS exercised — see help's `pager` view."
    ),
    "newsDetail.tier3.article": (
        "UNREACHABLE IN THE WEB AT 62f8a529, and this is an escalation, not a "
        "gap. `routes.ts:60` builds `new RegExp('^#' + NEWS_DETAIL.source)` "
        "where NEWS_DETAIL already starts with `^`, giving `^#^\\/news\\/…` — a "
        "pattern no string can match. So `newsIdFromHash()` always returns "
        "null, `App.tsx:183` passes `id={null}`, the detail query never fires, "
        "and every visit renders the not-found branch. Verified against the "
        "live rig: GET /news/<slug> is never issued. Baseline slot 15 therefore "
        "captures the NOT-FOUND render — the only one the web can show — and "
        "Tier 3 for the ARTICLE render is NOT EVALUATED. Tiers 1 and 2 are "
        "unaffected: they read the source, not a screenshot (§ 6.5.2(b)'s own "
        "reasoning)."
    ),
    "help.faqs.page2": (
        "`/help/faqs` has 11 rows and page 1 was recorded at per_page 10. Page "
        "2 (one row) was not recorded, so `faqs.data` is gated for page 1 only. "
        "The pager itself IS gated — `pager` view, `1 / 2`."
    ),
}


def main():
    check_commit()
    d = dictionaries()

    articles = api("news")["data"]
    news_meta = api("news")["meta"]
    categories = api("news-categories")["data"]
    detail = api(f"news-article-{DETAIL_SLUG}")["data"]
    help_categories = api("help-categories")["data"]
    faqs_doc = api("help-faqs")
    guides = api("help-articles")["data"]
    guide = api(f"help-article-{GUIDE_SLUG}")["data"]
    channels = api("help-channels")["data"]

    assert len(articles) == 6, len(articles)
    assert len(categories) == 4, len(categories)
    assert len(help_categories) == 4, len(help_categories)
    assert len(channels) == 4, len(channels)
    assert news_meta["total_pages"] == 1, news_meta
    assert faqs_doc["meta"]["total_pages"] == 2, faqs_doc["meta"]

    dates = icu_dates(
        [a.get("published_date") or a.get("published_at") or "" for a in articles]
        + [detail.get("published_date") or ""]
    )

    out_dir = os.path.join(ORACLE, "tier1")
    os.makedirs(out_dir, exist_ok=True)

    plans = [
        ("news", "/news", lambda lang: build_news(lang, d, articles, categories, dates)),
        (
            "news-detail",
            "/news/:slug",
            lambda lang: build_news_detail(lang, d, detail, articles, dates),
        ),
        (
            "help",
            "/help",
            lambda lang: build_help(
                lang,
                d,
                help_categories,
                faqs_doc["data"],
                faqs_doc["meta"],
                guides,
                guide,
                channels,
            ),
        ),
    ]

    for name, route, build in plans:
        for lang in LOCALES:
            doc = {
                "route": route,
                "locale": lang,
                "provenance": {
                    "web_commit": WEB_COMMIT,
                    "baseline": "docs/fidelity-baseline/2026-08-13",
                    "derived_by": "test/fidelity/derive_content_oracles.py",
                    "dates_from": "node Intl.DateTimeFormat (en-GB / lo-LA), "
                    "NOT a month table copied from the Dart port",
                    "not_evaluated": NOT_EVALUATED,
                },
                "views": build(lang),
            }
            path = os.path.join(out_dir, f"{name}.{lang}.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(doc, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write("\n")
            total = sum(len(v) for v in doc["views"].values())
            print(f"{os.path.basename(path)}: {len(doc['views'])} views, {total} nodes")


if __name__ == "__main__":
    main()
