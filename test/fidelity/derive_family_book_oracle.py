#!/usr/bin/env python3
"""Derive the Tier 1 oracle for `#/service/family-book` at 62f8a529 — F4.

Fourth in the series after `derive_oracles.py` (B2a, `/service`),
`derive_home_oracle.py` (B2b, `/`) and `derive_content_oracles.py`
(B2c, `/news`, `/news/:slug`, `/help`). Same contract, same shared i18n
scanner (`i18n_parse`, F0a's — do not write a second one), same declared
deviation: `GOR-245-f4-family-book/specs.md` § 3.1 row 11 authorises writing
`oracle/tier1/family-book.{en,lo}.json` and **only** those two files, and says
so out loud rather than performing the write quietly.

WHY THIS ORACLE IS PARTITIONED, AND WHAT THE PARTITION COSTS
============================================================

`specs.md` § 6.4 is the ruling this script implements. FamilyBook has **eight**
render states (§ 6.3). Four of them — loading, signed out, error, empty —
are built entirely from strings that exist in the pinned source: the `familyBook`
namespace's `title`/`subtitle` and the component-local `COPY` table at
`FamilyBookPage.tsx:40-63`. Those four are derivable and this file carries them.

The other four — success, step 1, step 2, step 3 — render `book.head_name`,
`m.uin`, `submitted.reference_no`, `text(submitted.status_label)` and the rest:
**raw server fields**. `GET /me/family-book` answers
`404 {"success":false,"message":"family book not found","code":"NOT_FOUND"}` on
the only account this programme has (`manifest-authenticated.md`:229), there is
no recorded `/me/family-book` payload anywhere in the repository, and inventing
one would make the oracle a function of the rig rather than of the app —
`oracle_coverage.yaml`'s own words on the `/prerequisite-records` row:
*"an oracle whose value came from the test harness is not an oracle."*

So this file carries **exactly four views** and `F4-AC-61` makes a fifth an
automatic FAIL. States 5-8 are `F4-NV-2`, NOT EVALUATED, named in
`qa-report.md`. That ceiling is the honest one; a five-view oracle would be a
green gate over values we wrote.

THE ERROR VIEW'S THIRD NODE IS NOT A STRING WE KNOW
===================================================

`FamilyBookPage.tsx:311` renders `{error.message}` — the backend's own sentence.
It has no source-derivable value at a pinned commit, but it does have a
source-derivable **position**: between `COPY.errorTitle` (`:310`) and
`COPY.retry` (`:319`). It is emitted with `role: "server-text"` and
`tier1_family_book_test.dart` compares it for presence and position only, never
for content (`F4-AC-62`). Dropping the node instead would let a port that
renders no message line at all pass — which is a real divergence this project
has already recorded twice (`chat.panel.error.message`,
`notifications.menu.error.message`).

WHAT IS DELIBERATELY ABSENT FROM EVERY VIEW
===========================================

* **The step indicator.** `:262` is `{book && <StepIndicator …>}`; `book` is
  falsy in all four derivable states, so it renders nothing. A port that showed
  it would surface here as an EXTRA node.
* **The bottom CTA.** `frame(body)` is called with one argument in all four
  states (`:278`, `:296`, `:306`, `:327`), so `{cta && …}` is false. Same.
* **Every icon.** `ChevronLeft`, `Loader2`, `BookX`, `AlertCircle`, `RotateCcw`
  are glyphs, and Tier 1 compares rendered *text* (`test/fidelity/text_dump.dart`).
  Their absence here is structural, not an omission — and it is why the three
  of them with no bundled Flutter glyph are a Tier 2/Tier 3 finding rather than
  a Tier 1 one.
* **The three loading skeletons** (`:283-289`) carry no text.

USAGE
=====

    python3 test/fidelity/derive_family_book_oracle.py

No network, no node, no npm — unlike `derive_content_oracles.py`, this page has
no date formatter and needs no ICU. Does not run during `flutter test`, by
design: a gate that regenerates its own expectation each run cannot fail.
"""

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

sys.path.insert(0, HERE)
import i18n_parse  # noqa: E402 — needs the path bootstrap above

PKG = os.path.dirname(os.path.dirname(HERE))
PROJECT = os.path.dirname(os.path.dirname(PKG))
WEB = os.path.join(PROJECT, "sources", "lcc-app")
ORACLE = os.path.join(PROJECT, "docs", "fidelity-baseline", "2026-08-13", "oracle")

WEB_COMMIT = "62f8a529aaa024a8b35b0af50a8fbd4850a63962"
BASELINE = "docs/fidelity-baseline/2026-08-13"
DERIVED_BY = "test/fidelity/derive_family_book_oracle.py"

LOCALES = ("en", "lo")


def assert_pinned() -> None:
    """§ 8.3: an oracle derived from a different web commit is a re-baseline."""
    head = subprocess.check_output(
        ["git", "-C", WEB, "rev-parse", "HEAD"], text=True
    ).strip()
    if head != WEB_COMMIT:
        raise SystemExit(
            f"$WEB is at {head}, not the pinned {WEB_COMMIT}. Every oracle and "
            "every baseline PNG is pinned to that commit; deriving from another "
            "one is a re-baseline and F4 may not perform one (specs.md § 8.3)."
        )
    dirty = subprocess.check_output(
        ["git", "-C", WEB, "status", "--porcelain"], text=True
    ).strip()
    if dirty:
        raise SystemExit(
            "$WEB's worktree is dirty. The pin is a commit, so an uncommitted "
            "edit makes every string below unattributable (specs.md § 8.3)."
        )


def read_web(*parts: str) -> str:
    with open(os.path.join(WEB, *parts), encoding="utf-8") as f:
        return f.read()


def parse_copy(source: str) -> dict:
    """`const COPY = { key: { en: "…", lo: "…" } } as const;` — `:40-63`.

    Parsed rather than transcribed for `field_sentences.dart`'s reason: a
    hand-copied Lao string is invisibly wrong to every reviewer who does not
    read Lao. The block is brace-matched from `const COPY = {` so a value
    containing a `}` cannot truncate it.
    """
    start = source.index("const COPY = {")
    open_brace = source.index("{", start)
    depth, i = 0, open_brace
    while True:
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                break
        i += 1
    body = source[open_brace + 1 : i]

    # `i18n_parse` scans `ns({en:{…},lo:{…}})` — one locale block holding many
    # keys. COPY is the transpose: many keys, each holding an `en`/`lo` pair, so
    # the shared scanner does not fit and [_side] reads one pair. It keeps the
    # scanner's two load-bearing properties — escape-aware, and hand-unescaped
    # rather than `unicode_escape`, which round-trips through latin-1 and
    # mojibakes every Lao code point (`i18n_parse.py`'s clause 3).
    entries = {lang: {} for lang in LOCALES}
    for key, block in _entries(body):
        for lang in LOCALES:
            entries[lang][key] = _side(block, lang, key)
    return entries


def _entries(body: str):
    """`(key, inner)` for every `key: { … }` at the top level of COPY."""
    i, n = 0, len(body)
    while i < n:
        colon = body.find(":", i)
        if colon == -1:
            return
        key = body[i:colon].strip().strip(",").strip()
        brace = body.find("{", colon)
        if brace == -1:
            return
        depth, j = 0, brace
        while j < n:
            if body[j] == "{":
                depth += 1
            elif body[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        if key:
            yield key, body[brace + 1 : j]
        i = j + 1


def _side(block: str, lang: str, key: str) -> str:
    """The `en:`/`lo:` string of one COPY entry, escape-aware."""
    marker = f"{lang}:"
    at = block.index(marker) + len(marker)
    while block[at] in " \n\r\t":
        at += 1
    if block[at] != '"':
        raise SystemExit(f"COPY.{key}.{lang} is not a double-quoted literal")
    out, at = [], at + 1
    while block[at] != '"':
        if block[at] == "\\":
            out.append(json.loads('"\\' + block[at + 1] + '"'))
            at += 2
            continue
        out.append(block[at])
        at += 1
    return "".join(out)


def node(role: str, text: str, source: str) -> dict:
    return {"role": role, "text": text, "source": source}


def views_for(lang: str, ns: dict, copy: dict) -> dict:
    """The four derivable views, node for node, in render order.

    Every node is `frame`'s or the state body's, read top to bottom:
    `frame` emits the header's title (`:255`) then its subtitle (`:256`), the
    step indicator only when `book` is truthy (`:262` — never here), the body,
    then the CTA only when one was passed (`:268` — never here).
    """
    t = ns[lang]
    c = copy[lang]
    chrome = [
        node("paragraph", t["title"], "FamilyBookPage.tsx:255 -> t(\"title\")"),
        node("paragraph", t["subtitle"], "FamilyBookPage.tsx:256 -> t(\"subtitle\")"),
    ]
    return {
        # `:277-292`. The `Loader2` glyph and the three skeleton cards carry no
        # text, so the sentence is the whole body.
        "loading": chrome
        + [node("paragraph", c["loading"], "FamilyBookPage.tsx:281 -> COPY.loading")],
        # `:295-302`. Checked AFTER loading (`:277`) — see specs.md § 6.3 and
        # `F4-AC-35`: `useQuery`'s `loading` initialises to `enabled`, so a
        # signed-out mount never passes through the skeleton.
        "signedOut": chrome
        + [node("paragraph", c["signedOut"], "FamilyBookPage.tsx:299 -> COPY.signedOut")],
        # `:305-323`. A 404 does NOT land here — `&& !error.isNotFound` routes
        # it to `empty` (`client.ts:92-94`), which is the only branch the
        # baseline exercises.
        "error": chrome
        + [
            node("paragraph", c["errorTitle"], "FamilyBookPage.tsx:310 -> COPY.errorTitle"),
            node(
                "server-text",
                "",
                "FamilyBookPage.tsx:311 -> {error.message}. The BACKEND's sentence: "
                "no source-derivable value at a pinned commit, but a "
                "source-derivable POSITION. Compared for presence and position "
                "only, never content (F4-AC-62). `text` is empty because any "
                "value here would be invented.",
            ),
            node("button", c["retry"], "FamilyBookPage.tsx:319 -> COPY.retry"),
        ],
        # `:326-336`. Slot 47's render, both locales — the one pairable Tier 3
        # reference this page has (specs.md § 2.2 Finding B).
        "empty": chrome
        + [
            node("paragraph", c["emptyTitle"], "FamilyBookPage.tsx:331 -> COPY.emptyTitle"),
            node("paragraph", c["emptyBody"], "FamilyBookPage.tsx:332 -> COPY.emptyBody"),
        ],
    }


def main() -> int:
    assert_pinned()

    ns = i18n_parse.parse_namespace(
        read_web("src", "app", "i18n", "ns", "familyBook.ts"),
        locales=LOCALES,
        origin="i18n/ns/familyBook.ts",
    )
    copy = parse_copy(read_web("src", "app", "components", "FamilyBookPage.tsx"))

    for lang in LOCALES:
        if len(ns[lang]) != 83:
            raise SystemExit(f"familyBook.{lang} parsed {len(ns[lang])} keys, expected 83")
        if len(copy[lang]) != 10:
            raise SystemExit(
                f"COPY.{lang} parsed {len(copy[lang])} entries, expected 10: "
                f"{sorted(copy[lang])}"
            )

    out_dir = os.path.join(ORACLE, "tier1")
    os.makedirs(out_dir, exist_ok=True)

    for lang in LOCALES:
        doc = {
            "schema": "tier1/1",
            "locale": lang,
            "route": "#/service/family-book",
            "provenance": {
                "web_commit": WEB_COMMIT,
                "baseline": BASELINE,
                "derived_by": DERIVED_BY,
                "method": (
                    "MECHANICAL. `title`/`subtitle` are parsed out of "
                    "src/app/i18n/ns/familyBook.ts by i18n_parse (F0a's shared "
                    "scanner); the six COPY sentences are parsed out of the "
                    "brace-matched `const COPY` block at "
                    "src/app/components/FamilyBookPage.tsx:40-63. No string in "
                    "this file was transcribed by hand, and "
                    "tier1_family_book_test.dart re-proves the derivation at run "
                    "time by reading both web files itself — so a hand-edit of "
                    "this file cannot pass unnoticed."
                ),
                "partition": (
                    "FOUR views of EIGHT states, by ruling (specs.md § 6.4). The "
                    "four here are the ones whose every string is derivable from "
                    "source + i18n. success / step1 / step2 / step3 render raw "
                    "server fields and are NOT EVALUATED (F4-NV-2) — a fifth view "
                    "in this file is an automatic FAIL (F4-AC-61), because its "
                    "values would be the rig's invention."
                ),
                "fixture": (
                    "NONE, and that is the point. There is no /me/family-book "
                    "payload anywhere in this repository — test/fidelity/fixtures/api/ "
                    "holds 30+ files and not one matches `family` or `household`. "
                    "The four views below need no fixture: `book` is falsy in all "
                    "four, which is why they are the derivable ones."
                ),
                "not_evaluated": {
                    "family-book.success": (
                        "book.head_name, submitted.reference_no, "
                        "text(submitted.status_label) and peopleSummary's three "
                        "counts are all server-derived (:355-377). F4-NV-2."
                    ),
                    "family-book.step1": (
                        "Nine of ten values on the cover are raw server fields "
                        "(:397-434). F4-NV-2."
                    ),
                    "family-book.step2": (
                        "Every member value is a raw server field (:438-502). "
                        "F4-NV-2."
                    ),
                    "family-book.step3": (
                        "The review rows plus the /services fee (:505-567). "
                        "F4-NV-2, and the fee additionally F4-NV-5."
                    ),
                    "blocking_reason": (
                        "GET /me/family-book answers 404 "
                        '{"success":false,"message":"family book not found",'
                        '"code":"NOT_FOUND"} on the only available account '
                        "(manifest-authenticated.md:229). Steps 2-3 are "
                        "STRUCTURALLY ABSENT from the DOM without a household "
                        "(:262, :326), not merely hard to reach. FU-7 — a seeded "
                        "staging account — is the only thing that closes this, and "
                        "it is a programme decision, not a batch one."
                    ),
                },
                "tier3": (
                    "Slot 47 (`47-family-book-step1`) is this page's ONE pairable "
                    "reference and it is the `empty` view below, both locales, "
                    "390x844, state_conditional under ADR-0006. Slot 14 "
                    "(`14-family-book`) is the SIGNIN page reached by the "
                    "signed-out redirect and is formally excluded by "
                    "page_pairs.yaml:44-53 — pairing it is an automatic FAIL "
                    "(F4-AC-66)."
                ),
                "chrome_absent_by_measurement": (
                    "No view carries a step-indicator node or a CTA node. `:262` "
                    "gates the indicator on `book`, which is falsy in all four; "
                    "`frame(body)` is called with ONE argument in all four "
                    "(:278, :296, :306, :327) so `{cta && …}` is false. "
                    "expectParity fails on an EXTRA node, so a port that rendered "
                    "either fails here and nowhere else in Tier 1."
                ),
            },
            "views": views_for(lang, ns, copy),
        }

        path = os.path.join(out_dir, f"family-book.{lang}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(doc, f, ensure_ascii=False, indent=2)
            f.write("\n")

        total = sum(len(v) for v in doc["views"].values())
        print(
            f"{os.path.basename(path)}: {len(doc['views'])} views, {total} nodes "
            f"({', '.join(f'{k}={len(v)}' for k, v in doc['views'].items())})"
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
