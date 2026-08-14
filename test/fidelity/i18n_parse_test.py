#!/usr/bin/env python3
"""Regression proof for the shared i18n parser — F0-AC-43, F0-AC-45, F0-AC-47.

    python3 test/fidelity/i18n_parse_test.py        # from the package root
    exit 0 = all proofs pass, exit 1 = a proof failed

Why this file exists, and why it runs git
-----------------------------------------
Parsing MORE keys than before is evidence of *change*, not of correctness. The
proof that the fix is a capability rather than a wiring change is that the same
assertion FAILS against the parser it replaced — and that parser no longer
exists in the working tree. It survives only as a git blob
(`git show HEAD:test/fidelity/derive_oracles.py`), which is why § 3.2 permits
read-only git plumbing and why this file shells out (§ 6.7.5).

**Both directions are proven, and that is the point.** The two pre-fix parsers
were incomplete in OPPOSITE directions:

  * `derive_oracles.py`      line-anchored  -> drops every MULTI-LINE entry
  * `derive_home_oracle.py`  double-quote   -> drops every SINGLE-QUOTED entry

A regression suite proving only one direction licenses copying the other one
forward, which is how this defect class survived B2.
"""
from __future__ import annotations

import ast
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(os.path.dirname(HERE))
PROJECT = os.path.dirname(os.path.dirname(PKG))
NS_DIR = os.path.join(PROJECT, "sources", "lcc-app", "src", "app", "i18n", "ns")

sys.path.insert(0, HERE)
import i18n_parse  # noqa: E402

# § 2.2 Finding G / § 6.7.5 — the measured per-namespace drop counts of the
# LINE-ANCHORED parser, en + lo summed. `service` = 0 is the load-bearing row:
# it is why ServicePage passed B2's Tier 1 and nobody saw this.
EXPECTED_LINE_ANCHORED_DROPS = {
    "marriage": 18, "divorce": 18, "tutorial": 12, "birth": 7, "death": 6,
    "onboarding": 6, "home": 4, "familyBook": 4, "history": 3, "resident": 2,
    "payment": 2, "chat": 2, "service": 0,
}

failures: list[str] = []
passes: list[str] = []


def check(label: str, ok: bool, detail: str = "", evidence: str = "") -> None:
    """`detail` explains a FAILURE and is printed only on failure — printing it
    under a PASS reads as a contradiction. `evidence` is the measured value and
    is printed either way, because a passing assertion with no number is the
    thing this whole batch exists to stop."""
    (passes if ok else failures).append(label)
    print(f"  {'PASS' if ok else 'FAIL'}  {label}")
    if evidence:
        print(f"        {evidence}")
    if not ok and detail:
        print(f"        {detail}")


def namespaces() -> list[str]:
    return sorted(f[:-3] for f in os.listdir(NS_DIR) if f.endswith(".ts"))


def head_blob(rel: str) -> str:
    """The pre-fix parser, from git. It is not in the working tree any more."""
    r = subprocess.run(["git", "show", f"HEAD:{rel}"], cwd=PKG,
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"cannot read HEAD blob {rel}: {r.stderr.strip()}")
    return r.stdout


# ── the two pre-fix parsers, reconstructed from their HEAD blobs ─────────────

def prefix_line_anchored(src: str, lang: str) -> dict:
    """`git show HEAD:test/fidelity/derive_oracles.py` :104, verbatim."""
    blob = head_blob("test/fidelity/derive_oracles.py")
    pattern = re.search(r'entry = re\.match\(r"""(.+?)""", line\)', blob)
    if not pattern:
        raise SystemExit("HEAD derive_oracles.py no longer holds the line-anchored regex "
                         "— the premise of F0-AC-43 has changed; escalate, do not edit this test")
    entry_re = re.compile(pattern.group(1))
    out, locale = {}, None
    for line in src.splitlines():
        head = re.match(r"\s*(en|lo)\s*:\s*\{\s*$", line)
        if head:
            locale = head.group(1)
            continue
        if locale is None:
            continue
        m = entry_re.match(line)
        if m:
            if locale == lang:
                out[m.group(1)] = m.group(3)
            continue
        if re.match(r"\s*\}\s*,?\s*$", line):
            locale = None
    return out


def prefix_double_quote(src: str, lang: str) -> dict:
    """`git show HEAD:test/fidelity/derive_home_oracle.py` :92-118, verbatim."""
    blob = head_blob("test/fidelity/derive_home_oracle.py")
    pattern = re.search(r"re\.finditer\(r'(\(\\w\+\).+?)', body\)", blob)
    if not pattern:
        raise SystemExit("HEAD derive_home_oracle.py no longer holds the double-quote-only "
                         "regex — the premise of F0-AC-45 has changed; escalate")
    entry_re = re.compile(pattern.group(1))
    body = i18n_parse.locale_body(src, lang)
    return {m.group(1): m.group(2) for m in entry_re.finditer(body)}


def read_ns(name: str) -> str:
    with open(os.path.join(NS_DIR, f"{name}.ts"), encoding="utf-8") as fh:
        return fh.read()


# ── code-anchored detectors ──────────────────────────────────────────────────
#
# § 6.7.2 prescribes `grep -rln 'def locale_body\|depth += 1' *.py` for the
# duplicate-parser check. MEASURED: that grep FAILS on a correct tree as soon as
# this file exists — and § 3.1 requires this file to exist. It matches the regex
# LITERAL two lines below, which is a mention of the pattern, not a second
# implementation of it. That is the third instance of the defect class the spec
# already caught twice (v1.0's `grep -c valueMode`, and the reviewer's
# `'lang}: {{\|en: {'` grep, which matched two docstrings).
#
# A grep cannot tell an implementation from a mention. An AST can, so these two
# detectors parse the file instead. Reported to the architect as a spec defect;
# the INTENT of F0-AC-42 — one implementation, not one mention — is unchanged
# and is what is asserted here.

def implements_brace_matcher(path: str) -> bool:
    """True iff the file really defines `locale_body` or really increments a
    `depth` counter — not merely names either inside a string or a comment."""
    try:
        tree = ast.parse(open(path, encoding="utf-8").read())
    except SyntaxError:
        return False
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == "locale_body":
            return True
        if (isinstance(node, ast.AugAssign) and isinstance(node.op, ast.Add)
                and isinstance(node.target, ast.Name) and node.target.id == "depth"):
            return True
    return False


def calls_unicode_escape(path: str) -> bool:
    """True iff `unicode_escape` is passed to a call. § 6.7.2 clause 3 REQUIRES
    the docstring to name it as the thing not to use, so a plain text search
    reports a false positive on the correct file."""
    tree = ast.parse(open(path, encoding="utf-8").read())
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        for arg in list(node.args) + [kw.value for kw in node.keywords]:
            if isinstance(arg, ast.Constant) and isinstance(arg.value, str) \
                    and "unicode_escape" in arg.value:
                return True
    return False


# ── F0-AC-43 ─────────────────────────────────────────────────────────────────

print("\nF0-AC-43(a) — the shared parser drops NOTHING, 23 namespaces x 2 locales")
total_declared = total_parsed = 0
short = []
for ns in namespaces():
    src = read_ns(ns)
    for lang in ("en", "lo"):
        body = i18n_parse.locale_body(src, lang)
        declared = len(i18n_parse.declared_keys(body))
        parsed = len(i18n_parse.parse_locale(src, lang, f"ns/{ns}.ts"))
        total_declared += declared
        total_parsed += parsed
        if declared != parsed:
            short.append(f"{ns}.{lang}: {parsed}/{declared}")
check(f"zero drops across {len(namespaces())} namespaces x 2 locales "
      f"({total_parsed}/{total_declared} entries)",
      not short and total_parsed == total_declared and total_parsed > 0,
      detail="; ".join(short))

print("\nF0-AC-43(b) — the SAME assertion FAILS against the pre-fix line-anchored parser,")
print("              reproducing Finding G's per-namespace drop counts")
measured = {}
for ns in namespaces():
    src = read_ns(ns)
    dropped = 0
    for lang in ("en", "lo"):
        body = i18n_parse.locale_body(src, lang)
        dropped += len(i18n_parse.declared_keys(body)) - len(prefix_line_anchored(src, lang))
    if dropped:
        measured[ns] = dropped
measured.update({k: measured.get(k, 0) for k in EXPECTED_LINE_ANCHORED_DROPS})
mismatch = {k: (EXPECTED_LINE_ANCHORED_DROPS[k], measured.get(k, 0))
            for k in EXPECTED_LINE_ANCHORED_DROPS
            if measured.get(k, 0) != EXPECTED_LINE_ANCHORED_DROPS[k]}
extra = {k: v for k, v in measured.items() if k not in EXPECTED_LINE_ANCHORED_DROPS and v}
total_dropped = sum(v for v in measured.values())
check(f"pre-fix parser drops exactly Finding G's counts (total {total_dropped})",
      not mismatch and not extra,
      detail=f"expected-vs-measured mismatches: {mismatch}; unexpected: {extra}")
check("`service` drops 0 on the BROKEN parser — the reason nobody saw this",
      measured.get("service", None) == 0,
      evidence=f"service dropped {measured.get('service')}")
check("the pre-fix parser really does lose entries (the proof is not vacuous)",
      total_dropped > 0, evidence=f"total dropped = {total_dropped}")

print("\nF0-AC-44 — the Tier 0 wire value survives")
for ns in ("birth", "death"):
    src = read_ns(ns)
    for lang in ("en", "lo"):
        parsed = i18n_parse.parse_locale(src, lang, ns)
        pre = prefix_line_anchored(src, lang)
        check(f"{ns}.{lang} legalBasisText: parsed now, dropped before",
              "legalBasisText" in parsed and "legalBasisText" not in pre,
              evidence=f"now={'legalBasisText' in parsed} before={'legalBasisText' in pre}")

# ── F0-AC-45 — the OTHER direction ───────────────────────────────────────────

print("\nF0-AC-45 — single-quoted entries survive, proven in BOTH directions")
svc = read_ns("service")
for lang in ("en", "lo"):
    now = i18n_parse.parse_locale(svc, lang, "service")
    before = prefix_double_quote(svc, lang)
    check(f"service.{lang} resultsFor parsed by the shared parser",
          "resultsFor" in now, evidence=f"keys={len(now)}")
    check(f"service.{lang} resultsFor DROPPED by the pre-fix double-quote-only parser",
          "resultsFor" not in before, evidence=f"pre-fix keys={len(before)}")
check("the single-quoted value is intact, quotes and all",
      i18n_parse.parse_locale(svc, "en", "service")["resultsFor"]
      == '{count} result(s) for "{q}"',
      evidence=repr(i18n_parse.parse_locale(svc, "en", "service").get("resultsFor")))

# ── F0-AC-47 — UTF-8 Lao ─────────────────────────────────────────────────────

print("\nF0-AC-47 — UTF-8 Lao survives, no mojibake")
birth_src = read_ns("birth")
lo = i18n_parse.parse_locale(birth_src, "lo", "birth")
legal_lo = lo["legalBasisText"]
check("a parsed Lao value appears verbatim in the source bytes",
      legal_lo in birth_src and any("຀" <= ch <= "໿" for ch in legal_lo),
      evidence=repr(legal_lo[:48]))
check("no latin-1 mojibake markers in any parsed Lao value",
      not any("Ã" in v or "à¸" in v for v in lo.values()))
check("the parser never CALLS unicode_escape (prose mentions are required, "
      "§ 6.7.2 clause 3)",
      not calls_unicode_escape(os.path.join(HERE, "i18n_parse.py")),
      detail="found unicode_escape passed to a call, not merely named in a docstring")

# ── F0-AC-42 — one shared parser, and only one ───────────────────────────────

print("\nF0-AC-42 — ONE shared parser, and creating a second is an automatic FAIL")
check("ns_parser.py does NOT exist",
      not os.path.exists(os.path.join(HERE, "ns_parser.py")))
owners = [f for f in sorted(x for x in os.listdir(HERE) if x.endswith(".py"))
          if implements_brace_matcher(os.path.join(HERE, f))]
check("exactly one file IMPLEMENTS the brace matcher (AST-anchored, so a "
      "mention in a string or comment does not count)",
      owners == ["i18n_parse.py"], evidence=f"matched: {owners}")
delegating = []
for f in ("derive_oracles.py", "derive_home_oracle.py", "derive_content_oracles.py"):
    body = open(os.path.join(HERE, f), encoding="utf-8").read()
    if "import i18n_parse" in body and "def parse_ns" in body:
        delegating.append(f)
check("all three derivations import the shared module and keep their parse_ns adapter",
      len(delegating) == 3, evidence=f"delegating: {delegating}")

print("\n" + "=" * 70)
print(f"passed {len(passes)}   failed {len(failures)}")
for f in failures:
    print(f"  FAILED: {f}")
sys.exit(1 if failures else 0)
