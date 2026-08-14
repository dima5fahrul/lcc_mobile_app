#!/usr/bin/env python3
"""F0-AC-88 — the mechanical cross-reference guard over this batch's specs.md.

    python3 test/fidelity/ac_reference_check.py [path/to/specs.md]
    exit 0 = every citation resolves and the two governing lists agree

Why this exists
---------------
v1.0's § 6.12 exit contract — the artefact F1 inherits and is gated by — cited
the WRONG acceptance criteria in three of nine rows, while § 8.1 cited
correctly. Two governing lists disagreeing is precisely what lets a reviewer
verify the wrong thing and record PASS in good faith. This makes that class
mechanical rather than a matter of proofreading.

Assertions:
  1. Every `F0-AC-n` cited anywhere OUTSIDE § 7 resolves to a row defined IN § 7.
  2. No cited id exceeds the highest defined id.
  3. Every id in 1..max is defined exactly once — no gaps, no duplicates.
  4. § 6.12 vs § 8.1 — see the note below.
  5. Every `FU-n` cited resolves to a row in § 8.4.
  6. § 7's declared criterion count equals the rows actually present.

A note on clause 4, because F0-AC-88 words it as *"§ 6.12's and § 8.1's citation
sets are consistent with each other"* and that is not mechanically well-defined.
The two sections have different scopes: § 8.1 is **F0a's exit gate**, § 6.12 is
**everything F1 inherits, from F0a and F0b together**. Neither is a subset of
the other and neither should be — § 8.1 legitimately holds `F0-AC-3` (a process
gate F1 inherits nothing from) and § 6.12 legitimately holds `F0-AC-25`…`27`
(F0b kernel states that are not in F0a's exit gate). Asserting containment in
either direction fails on a correct document.

So the difference is printed as **evidence** for a human, and the hard assertion
is the well-posed half: **every criterion § 8.1 gates F0a on must be
F0a-applicable**, read from § 7's own "Applies to" column. That catches a real
and fatal error — an exit gate that gates F0a on something only F0b can satisfy
would make F0a unpassable by construction — which is the same shape as the v1.0
defect this criterion was written for. Reported to the architect.
"""
from __future__ import annotations

import os
import re
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(os.path.dirname(HERE))
PROJECT = os.path.dirname(os.path.dirname(PKG))
DEFAULT_SPEC = os.path.join(
    PROJECT, "docs", "greenfield", "GOR-245-f0-form-kernel", "specs.md")

AC = re.compile(r"F0-AC-(\d+)")
FU = re.compile(r"\bFU-(\d+)\b")
# A definition row: the id in bold, as the first cell of a table row.
AC_DEF = re.compile(r"^\|\s*\*\*F0-AC-(\d+)\*\*\s*\|", re.M)
FU_DEF = re.compile(r"^\|\s*\*\*FU-(\d+)\*\*", re.M)

failures: list[str] = []


def check(label: str, ok: bool, evidence: str = "", detail: str = "") -> None:
    if not ok:
        failures.append(label)
    print(f"  {'PASS' if ok else 'FAIL'}  {label}")
    if evidence:
        print(f"        {evidence}")
    if not ok and detail:
        print(f"        {detail}")


# `F0-AC-97`…`F0-AC-101` is an inclusive RANGE, not two citations. § 6.12 and
# § 8.4 write ranges; § 8.1 writes its ids out individually. A checker that does
# not expand them reports the middle of every range as an unresolved citation —
# which is a bug in the checker, not in the spec.
RANGE = re.compile(r"F0-AC-(\d+)\s*(?:…|\.\.\.|—)\s*`?F0-AC-(\d+)")


def cited_ids(chunk: str) -> set[int]:
    ids = {int(m.group(1)) for m in AC.finditer(chunk)}
    for m in RANGE.finditer(chunk):
        lo, hi = int(m.group(1)), int(m.group(2))
        if lo <= hi:
            ids.update(range(lo, hi + 1))
    return ids


def fmt(ids) -> str:
    return ", ".join(f"F0-AC-{i}" for i in sorted(ids)) or "(none)"


def applies_to(body7: str) -> dict[int, str]:
    """The 'Applies to' cell of each § 7 row — the last cell before the row end."""
    out: dict[int, str] = {}
    for line in body7.splitlines():
        m = re.match(r"^\|\s*\*\*F0-AC-(\d+)\*\*\s*\|(.*)\|\s*$", line)
        if m:
            out[int(m.group(1))] = m.group(2).rsplit("|", 1)[-1].strip()
    return out


def span(text: str, start_pat: str, end_pat: str) -> tuple[int, int]:
    s = re.search(start_pat, text, re.M)
    if not s:
        raise SystemExit(f"cannot locate section start {start_pat!r}")
    e = re.search(end_pat, text[s.end():], re.M)
    return s.start(), (s.end() + e.start()) if e else len(text)


def main(path: str) -> int:
    text = open(path, encoding="utf-8").read()
    print(f"spec: {path}  ({len(text.splitlines())} lines)\n")

    s7, e7 = span(text, r"^## 7\. Acceptance criteria", r"^## 8\. ")
    body7 = text[s7:e7]
    outside7 = text[:s7] + text[e7:]

    defined = [int(m.group(1)) for m in AC_DEF.finditer(body7)]
    counts = Counter(defined)
    hi = max(defined) if defined else 0

    print("assertion 3 — every id 1..max defined exactly once, in § 7")
    dupes = sorted(i for i, n in counts.items() if n > 1)
    gaps = [i for i in range(1, hi + 1) if i not in counts]
    check(f"{len(defined)} rows define ids 1..{hi}",
          not dupes and not gaps,
          evidence=f"defined={len(defined)} distinct={len(counts)} max={hi}",
          detail=f"duplicates={dupes} gaps={gaps}")

    print("\nassertion 1+2 — every F0-AC-n cited outside § 7 resolves, and none exceeds max")
    cited = sorted(cited_ids(outside7))
    unresolved = [i for i in cited if i not in counts]
    over = [i for i in cited if i > hi]
    check(f"{len(cited)} distinct ids cited outside § 7, all resolve",
          not unresolved,
          evidence=f"cited={len(cited)} highest_cited={max(cited) if cited else 0} highest_defined={hi}",
          detail=f"unresolved: {unresolved}")
    check("no cited id exceeds the highest defined id", not over,
          detail=f"over-range: {over}")

    print("\nassertion 4 — § 6.12 and § 8.1, and the gate's own applicability")
    s612, e612 = span(text, r"^### 6\.12 ", r"^## 7\. ")
    s81, e81 = span(text, r"^### 8\.1 ", r"^### 8\.2 ")
    in612 = cited_ids(text[s612:e612])
    in81 = cited_ids(text[s81:e81])

    # Set containment is NOT the right relation and the spec does not claim it:
    # § 8.1 is F0a's exit gate, § 6.12 is everything F1 inherits from F0a AND
    # F0b. Each legitimately holds ids the other does not (§ 8.1 has F0-AC-3,
    # a process gate F1 inherits nothing from; § 6.12 has F0-AC-25..27, F0b
    # kernel states that are not in F0a's exit gate). Reported as evidence.
    print(f"        §6.12 cites {len(in612)}  §8.1 cites {len(in81)}  "
          f"overlap {len(in612 & in81)}")
    print(f"        only in §8.1 : {fmt(in81 - in612)}")
    print(f"        only in §6.12: {fmt(in612 - in81)}")

    # The well-posed half, and the one that catches a real failure: F0a's exit
    # gate must not gate on a criterion only F0b can satisfy, which would make
    # F0a unpassable by construction.
    applies = applies_to(body7)
    misapplied = sorted(i for i in in81
                        if "F0a" not in applies.get(i, "") and "both" not in applies.get(i, ""))
    check("every criterion § 8.1 gates F0a on is F0a-applicable",
          not misapplied,
          evidence=f"{len(in81)} gated ids, all with F0a/both in their § 7 'Applies to'",
          detail="; ".join(f"F0-AC-{i} applies to {applies.get(i)!r}" for i in misapplied))

    print("\nassertion 5 — every FU-n cited resolves to a row in § 8.4")
    s84, e84 = span(text, r"^### 8\.4 ", r"^### 8\.5 ")
    fu_def = {int(m.group(1)) for m in FU_DEF.finditer(text[s84:e84])}
    fu_cited = {int(m.group(1)) for m in FU.finditer(text)}
    fu_missing = sorted(fu_cited - fu_def)
    check(f"{len(fu_cited)} FU ids cited, {len(fu_def)} defined in § 8.4",
          not fu_missing,
          evidence=f"defined={sorted(fu_def)}",
          detail=f"cited but not defined: {sorted('FU-%d' % i for i in fu_missing)}")

    print("\nassertion 6 — the stated criterion count matches the rows present")
    claimed = re.search(r"\*\*(\d+) criteria\.\*\*", body7)
    n_claimed = int(claimed.group(1)) if claimed else -1
    check("§ 7's declared criterion count equals the number of defined rows",
          n_claimed == len(counts),
          evidence=f"declared={n_claimed} defined={len(counts)}")

    print("\n" + "=" * 70)
    print(f"failures: {len(failures)}")
    for f in failures:
        print(f"  FAILED: {f}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SPEC))
