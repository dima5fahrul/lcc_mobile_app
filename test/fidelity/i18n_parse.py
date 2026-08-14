#!/usr/bin/env python3
"""The one i18n dictionary scanner every fidelity derivation shares.

Owner:   qa-lcc-mobile-app-greenfield (agentId agent-1786630209903-djc1y5)
Batch:   F0a — GOR-245-f0-form-kernel, § 6.7 RULING 6 (ADOPT, VERIFY, OWN, COMMIT)
Adopted: 2026-08-13

Verification record — § 6.7.2's four clauses, each checked against this file
rather than re-derived (F0-AC-42). The executable form of this record is
`i18n_parse_test.py`, which fails if any clause regresses:

  1. brace-matched locale block, so a multi-line value survives  -> `locale_body`
  2. both quote styles, escape-aware, linear (alternation not a
     backreference)                                              -> `_ENTRY`
  3. hand-unescaped, never `unicode_escape` (which round-trips
     through latin-1 and mojibakes every Lao code point)         -> `_unescape`
  4. one shared module, all three derivations delegate to it     -> `parse_ns`
     wrappers at derive_oracles.py:88, derive_home_oracle.py:95,
     derive_content_oracles.py:106 — those wrappers are call-site adapters,
     are CORRECT, and stay (§ 6.7.2).

Two behaviours beyond what § 6.7.2 asked for are kept deliberately: an empty
locale block and a duplicate key each raise rather than returning quietly.

**Do not create `ns_parser.py`.** A second shared parser is the exact
multi-copy condition this module exists to end, and § 6.7 makes it an
automatic FAIL (F0-AC-42).

Why this module exists
----------------------
Three separate scanners existed, each wrong in a different direction, and both
failure modes were **silent** — a dropped entry produced a smaller oracle, never
an error:

  * `derive_oracles.py` matched entries LINE-ANCHORED, requiring the value to
    sit on the key's own line and end in a comma. It dropped every multi-line
    entry — 84 across `ns/*.ts`, including `birth.ts legalBasisText`, which is
    not display text but a Tier 0 **wire value**
    (`BirthDeclarationPage.tsx:761` -> `"header.legal_basis"`).

  * `derive_home_oracle.py` and `derive_content_oracles.py` brace-matched the
    locale block, so multi-line was fine, but matched DOUBLE-QUOTED values
    only. They dropped `service.ts resultsFor`, which is single-quoted for a
    reason that will recur: its value *contains* double quotes —
    `'{count} result(s) for "{q}"'`.

`service.ts` is the single namespace with no multi-line entries. That is the
only reason the shipped service oracle was correct and the line-anchored bug
went unseen: the instrument had only ever been run against the one dictionary
immune to its own defect.

So a scanner must be correct on BOTH axes — multi-line and both quote styles.
That is necessary but not sufficient. The harm here was silence, not the
missing entries: a parser that loses 84 values and says nothing is worse than
one that loses them and stops. Hence `parse_locale` asserts its own
completeness and raises rather than returning a short dictionary.

What this does not handle, deliberately
---------------------------------------
Template literals (backticks), string concatenation across `+`, computed keys
and nested objects. None occurs in `ns/*.ts` today — verified — and each would
be caught loudly by the completeness assertion rather than silently dropped,
which is the property that matters. Add support when a dictionary needs it; do
not weaken the assertion to accommodate one.
"""

from __future__ import annotations

import re
from collections import Counter, OrderedDict

__all__ = ["locale_body", "declared_keys", "parse_locale", "I18nParseError"]


class I18nParseError(Exception):
    """Raised when a dictionary cannot be parsed completely."""


def locale_body(source: str, lang: str) -> str:
    """Return the interior of one `lang: { … }` block, brace-matched.

    Brace-matching rather than a line scan is what makes multi-line entries
    work at all.
    """
    marker = f"{lang}: {{"
    start = source.find(marker)
    if start < 0:
        raise I18nParseError(f"no `{lang}: {{` block found")
    i = source.index("{", start)
    begin, depth = i, 0
    while i < len(source):
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                return source[begin + 1:i]
        i += 1
    raise I18nParseError(f"`{lang}` block is not brace-balanced")


def _blank_string_contents(body: str) -> str:
    """Blank out the CONTENT of every string literal, preserving length and
    newlines.

    This is what lets the key scan below be structural: after blanking, a `:`
    or `{` appearing inside a translated sentence can no longer be mistaken for
    syntax.
    """
    out = list(body)
    i, n = 0, len(body)
    while i < n:
        ch = body[i]
        if ch in "\"'`":
            quote, j = ch, i + 1
            while j < n:
                if body[j] == "\\":
                    j += 2
                    continue
                if body[j] == quote:
                    break
                j += 1
            for k in range(i + 1, min(j, n)):
                if out[k] != "\n":
                    out[k] = " "
            i = j + 1
            continue
        i += 1
    return "".join(out)


def declared_keys(body: str) -> list[str]:
    """Every key declared at depth 0 of a locale body, in source order.

    This is the INDEPENDENT half of the completeness check. It never looks at a
    value — only at `identifier :` outside of any string and outside any nested
    object — so it cannot be fooled by the quoting or line-splitting of the
    value, which is precisely what broke the two previous scanners.
    """
    skeleton = _blank_string_contents(body)
    keys: list[str] = []
    depth = 0
    for m in re.finditer(r"\{|\}|([A-Za-z_$][\w$]*)\s*:", skeleton):
        token = m.group(0)
        if token == "{":
            depth += 1
        elif token == "}":
            depth -= 1
        elif depth == 0 and m.group(1):
            keys.append(m.group(1))
    return keys


# Both quote styles; `[^"\\]` / `[^'\\]` match newlines, so a value on the line
# after its key parses. Alternation rather than a backreference keeps this
# linear — no catastrophic backtracking on a long dictionary.
_ENTRY = re.compile(
    r"""([A-Za-z_$][\w$]*)\s*:\s*(?:"((?:\\.|[^"\\])*)"|'((?:\\.|[^'\\])*)')""",
    re.S,
)


def _unescape(text: str) -> str:
    """Resolve backslash escapes.

    By hand rather than via `unicode_escape`, which round-trips through latin-1
    and turns every Lao code point into mojibake.
    """
    return re.sub(
        r"\\(.)",
        lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)),
        text,
    )


def parse_locale(source: str, lang: str, origin: str = "<i18n>") -> "OrderedDict[str, str]":
    """Parse one locale block into {key: value}, or raise.

    Completeness is asserted against `declared_keys`, computed by a separate
    pass that reads structure only. Per FACTORY-RULES.md's Capability Rule, an
    assertion that would pass on an empty dictionary is not evidence — so a
    locale block that declares nothing is itself a failure, not a vacuous pass.
    """
    body = locale_body(source, lang)
    declared = declared_keys(body)

    entries: "OrderedDict[str, str]" = OrderedDict()
    for m in _ENTRY.finditer(body):
        raw = m.group(2) if m.group(2) is not None else m.group(3)
        entries[m.group(1)] = _unescape(raw)

    where = f"{origin}:{lang}"

    if not declared:
        raise I18nParseError(
            f"{where}: the locale block declares no keys. Refusing to treat an "
            f"empty dictionary as a successful parse."
        )

    repeated = sorted(k for k, n in Counter(declared).items() if n > 1)
    if repeated:
        raise I18nParseError(
            f"{where}: duplicate key(s) {repeated} in the source dictionary — "
            f"the later value silently wins in JS, so the oracle would encode "
            f"one of two different strings. Fix the dictionary."
        )

    missing = [k for k in declared if k not in entries]
    unexpected = [k for k in entries if k not in set(declared)]
    if missing or unexpected:
        detail = []
        if missing:
            detail.append(
                f"{len(missing)} declared key(s) the value scanner did not "
                f"recover: {missing}"
            )
        if unexpected:
            detail.append(
                f"{len(unexpected)} parsed key(s) not declared at depth 0: "
                f"{unexpected}"
            )
        raise I18nParseError(
            f"{where}: parsed {len(entries)} of {len(declared)} declared "
            f"entries. " + "; ".join(detail) + ". This is the failure the "
            f"module docstring describes: an incomplete parse must stop the "
            f"derivation, never quietly shrink the oracle."
        )

    return entries


def parse_namespace(source: str, locales=("en", "lo"), origin: str = "<i18n>") -> dict:
    """`{locale: {key: value}}` for several locales, each completeness-checked."""
    return {lang: parse_locale(source, lang, origin) for lang in locales}
