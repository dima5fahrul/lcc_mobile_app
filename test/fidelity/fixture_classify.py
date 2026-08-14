#!/usr/bin/env python3
"""`F0-AC-108` and `F0-AC-109` — § 6.5.3 item 7's reachability precondition.

    python3 test/fidelity/fixture_classify.py --write   # derive `_classification`
    python3 test/fidelity/fixture_classify.py           # check (the gate)
    python3 test/fidelity/fixture_classify.py --control=pod-country
    python3 test/fidelity/fixture_classify.py --control=divorce-mutual
    python3 test/fidelity/fixture_classify.py --control=betrothal-existing
    python3 test/fidelity/fixture_classify.py --control=delete-contested

`F0-AC-108` — every key in every file under `fixtures/tier0/**` carries exactly
one of `driven` / `constant`, never `unreachable`: a fixture may not declare an
unreachable key at all (§ 6.5.3 item 7's third row). Per key:

  * a `driven` key's cited `file:line` must exist in the pinned source AND that
    line must render a control that writes the field — the check looks for an
    `onChange` reaching a `patch*`/`set*` write of that name, not merely for
    the name appearing somewhere;
  * a `constant` key's fixture value must be BYTE-EQUAL to the initialiser
    literal at its cited line.

`F0-AC-109` — the arm check. For each multi-arm page the fixture matrix's
declared states are read against the page's own `canProceed()`:

  (i)   every arm from which `canProceed()` can return true appears in at least
        one fixture;
  (ii)  every arm that cannot appears in `oracle_coverage.yaml`;
  (iii) no fixture declares content from two mutually exclusive arms.

## Why the controls are the point

A check that passes on the tree as it stood at v1.3 is inert, and `F0-AC-108`
says so in terms. All three of Finding M's instances are replanted here, in
memory, and each must FAIL:

  `--control=pod-country`         `podCountry: "LA"`   — a `constant` key whose
                                  value differs from its initialiser.
  `--control=divorce-mutual`      `divorceType: "mutual"` — an arm `canProceed()`
                                  can never admit.
  `--control=betrothal-existing`  `betrothalMode: "existing"` with
                                  `linkedRecord: null` — likewise.
  `--control=delete-contested`    `F0-AC-109`'s own control: removing the
                                  `contested` variant must fail (i) NAMING the
                                  uncovered arm, not merely reducing a count.

Nothing here writes to `$PROJ/sources/lcc-app`, and the controls mutate only
in-memory copies of the fixtures.
"""
from __future__ import annotations

import functools
import json
import os
import re
import sys

import constant_scan as cs

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURES = os.path.join(HERE, "fixtures", "tier0")
REGISTER = os.path.join(HERE, "oracle_coverage.yaml")

META = {"_note", "_locale", "_reference_no", "_locations", "_classification"}

PAGE_OF = {
    "resident": "ResidentCertificatePage.tsx",
    "birth": "BirthDeclarationPage.tsx",
    "death": "DeathDeclarationPage.tsx",
    "marriage": "MarriageCertificatePage.tsx",
    "divorce": "DivorceCertificatePage.tsx",
}


# ─────────────────────────────────────────────────────────────────────────────
# Key enumeration
# ─────────────────────────────────────────────────────────────────────────────

def leaf_keys(node, prefix=""):
    """Every LEAF path in a fixture, metadata excluded.

    `_locations` is excluded as metadata rather than classified: it is not page
    state at all, it is the rig's record of which registry rows the fixture's
    ids resolve to, and § 6.5.3 item 5 is what puts it in the file.
    """
    out = []
    if isinstance(node, dict):
        for k, v in node.items():
            if not prefix and k in META:
                continue
            out.extend(leaf_keys(v, f"{prefix}.{k}" if prefix else k))
        return out
    return [prefix]


def value_at(fx, path):
    cur = fx
    for part in path.split("."):
        cur = cur[part]
    return cur


# ─────────────────────────────────────────────────────────────────────────────
# Where a field is written, read off the page
# ─────────────────────────────────────────────────────────────────────────────

@functools.lru_cache(maxsize=None)
def write_sites(src: str, field: str) -> list:
    """Lines that WRITE `field` into page state, as 1-based line numbers.

    Three measured shapes, and each is a control's `onChange` reaching a
    setter:

      `onChange={(v) => patchDeceased({ podProvince: v })}`   static key
      `onChange={(v) => set("citizenName", v)}`               generic setter
      `onChange={(address) => onChange({ address })}`         ES shorthand

    Read off the BLANKED source so a field name inside a placeholder string or
    a comment is not mistaken for a write.
    """
    b = cs.blanked(src)
    hits = []
    for lo, hi in cs.setter_windows(b):
        window = b[lo:hi]
        if (re.search(r"[{,]\s*" + re.escape(field) + r"\s*:", window)
                or re.search(r"[{,]\s*" + re.escape(field) + r"\s*[},]",
                             window)):
            hits.append(b.count("\n", 0, lo) + 1)
    # The generic setter takes its key as a literal argument, which the blanked
    # source has erased — so this one shape is matched on the RAW text.
    for m in re.finditer(r"(?<![\w$.])set\s*\(\s*\"" + re.escape(field)
                         + r"\"", src):
        hits.append(src.count("\n", 0, m.start()) + 1)

    # A PROP CALLBACK. `SpouseSection`, `ParentSection`, `AddressFields` and
    # `LocationFields` are passed an `onChange` and call it with a patch object
    # — `onChange({ dob: v })`, `onChange({ address })`. The setter it is wired
    # to lives at the call site, so the write never appears inside a
    # `patch*(…)`/`set*(…)` span and the window scan above cannot see it. This
    # is the majority shape on both nested pages: without it every one of
    # `SpouseSection`'s thirteen controls reads as unwritten.
    # Matched as a SPAN rather than a flat regex, because the patch object is
    # routinely built with nested conditional spreads —
    # `onChange({ ...(p.village !== undefined ? { addrVillage: p.village } : {}) })`
    # (`DeathDeclarationPage.tsx:439-442`) — and a brace-free pattern cannot
    # reach past the first `{`.
    for call in re.finditer(r"(?<![\w$.])on[A-Z][\w$]*\s*\(", b):
        window, _ = cs.span_from(b, call.end() - 1)
        if re.search(r"[{,]\s*" + re.escape(field) + r"\s*[:},]", window):
            hits.append(b.count("\n", 0, call.start()) + 1)

    # A TOP-LEVEL state variable, set whole rather than patched:
    # `setBetrothalMode("new")`, `setHasChildren((v) => !v)`,
    # `setLinkedRecord(record)`. The field IS the state name, so there is no
    # `field:` key to find.
    setter = "set" + field[0].upper() + field[1:]
    for m in re.finditer(r"(?<![\w$.])" + re.escape(setter) + r"\s*\(", b):
        hits.append(b.count("\n", 0, m.start()) + 1)

    # AN OPAQUE PATCH SPREAD. `DeathDeclarationPage.tsx:1101` and
    # `BirthDeclarationPage.tsx`'s twin write
    # `onChange={(p) => setHeader((h) => ({ ...h, ...p }))}` — the field name
    # appears nowhere, so every scan above is blind to it. The keys the write
    # can carry are the keys `p` can carry, and those ARE declared, in the
    # supplying component's `onChange` prop type:
    # `onChange: (patch: { province?: string; district?: string;
    # village?: string }) => void` (`formFields.tsx:387`). That declaration is
    # the citation — it is the shared component saying, in the pinned source,
    # exactly which fields its control writes. A spread whose supplier declares
    # no such type stays unresolved rather than being assumed.
    for m in re.finditer(r"(?<![\w$.])set[A-Z][\w$]*\s*\(\s*\([\w$]+\)\s*=>\s*"
                         r"\(\s*\{\s*\.\.\.[\w$]+\s*,\s*\.\.\.([\w$]+)\s*\}",
                         b):
        line = b.count("\n", 0, m.start()) + 1
        if field in _spread_supplier_keys(src, line):
            hits.append(line)

    # A COMPUTED key, resolved through the `as const` literals that feed it —
    # `patchReg({ [w.kn]: v })` with `kn: "w1Name" as const`
    # (`MarriageCertificatePage.tsx:1489-1493`). `constant_scan` already
    # enumerates the resolvable target set and REFUSES on a shape it cannot
    # follow, so reusing it here inherits that refusal rather than guessing.
    try:
        if field in cs.computed_key_targets(src):
            for m in re.finditer(r"\[\s*[A-Za-z_$][\w$]*\.[A-Za-z_$][\w$]*"
                                 r"\s*\]\s*:", b):
                hits.append(b.count("\n", 0, m.start()) + 1)
    except cs.Uncertifiable:
        pass
    return tuple(sorted(set(hits)))


_SHARED = os.path.join(cs.COMPONENTS, "formFields.tsx")


@functools.lru_cache(maxsize=None)
def _spread_supplier_keys(src: str, line: int) -> set:
    """The keys the JSX element enclosing `line` declares its `onChange` sends.

    Walks up from the `onChange={…}` line to the element's opening tag, then
    reads that component's `onChange` prop TYPE out of `formFields.tsx`. Only
    the shared components are consulted: a page-local component's patch type is
    already visible to the scans above.
    """
    lines = src.splitlines()
    name = None
    for i in range(line - 1, max(0, line - 30), -1):
        tag = re.match(r"\s*<([A-Z][\w$]*)", lines[i - 1])
        if tag:
            name = tag.group(1)
            break
    if name is None:
        return set()
    try:
        with open(_SHARED, encoding="utf-8") as fh:
            shared = fh.read()
    except OSError:
        return set()
    decl = re.search(r"export function " + re.escape(name) + r"\b", shared)
    if not decl:
        return set()
    window = shared[decl.end():decl.end() + 2000]
    prop = re.search(r"onChange:\s*\(\s*\w+\s*:\s*(?:Partial<)?\{([^}]*)\}",
                     window)
    if not prop:
        return set()
    return set(re.findall(r"([A-Za-z_$][\w$]*)\s*\??\s*:", prop.group(1)))


@functools.lru_cache(maxsize=None)
def renders_a_control(src: str, line: int) -> bool:
    """The cited line sits inside a control's `onChange`, not in a plain
    assignment. Twelve lines of context, because a `LocationFields` handler
    spans a JSX prop and its arrow body."""
    lines = src.splitlines()
    lo = max(0, line - 12)
    window = "\n".join(lines[lo:line + 4])
    return "onChange" in window or "onToggle" in window or "onClick" in window


@functools.lru_cache(maxsize=None)
def initialiser_site(src: str, field: str):
    """`(line, literal)` for `field: <literal>` in a blank record, or None."""
    b = cs.blanked(src)
    for m in re.finditer(r"(?:^|[{,\s])" + re.escape(field)
                         + r"\s*:\s*([^,}\n]+)", b):
        line = b.count("\n", 0, m.start()) + 1
        raw = src.splitlines()[line - 1]
        lit = re.search(re.escape(field) + r'\s*:\s*("(?:[^"\\]|\\.)*"'
                        r"|null|true|false)", raw)
        if not lit:
            continue
        text = lit.group(1)
        if text.startswith('"'):
            return line, json.loads(text)
        return line, {"null": None, "true": True, "false": False}[text]
    return None


# ─────────────────────────────────────────────────────────────────────────────
# Derivation and checking
# ─────────────────────────────────────────────────────────────────────────────

def classify(form: str, fx: dict) -> dict:
    """`{key: "driven Page.tsx:N" | "constant Page.tsx:N"}`, derived."""
    src = cs.read_pages()[PAGE_OF[form]]
    constants = {row["field"] for row in cs.derive({PAGE_OF[form]: src})}
    out = {}
    for key in leaf_keys(fx):
        field = key.split(".")[-1]
        if field in constants:
            site = initialiser_site(src, field)
            out[key] = f"constant {PAGE_OF[form]}:{site[0]}" if site else "?"
            continue
        sites = write_sites(src, field)
        # The citation must be the CONTROL, not merely the earliest write.
        # Several fields are also written by a non-UI path — Resident's OCR
        # prefill (`:403`) and Marriage's `selectExisting` (`:811`) both patch
        # state with no control on screen — and citing one of those would prove
        # the field is writable while saying nothing about whether a fixture
        # can drive it, which is the Capability Rule violation § 6.5.3 item 7
        # is written against. A field with ONLY non-control writers keeps the
        # earliest site and FAILS the check, loudly.
        control = [n for n in sites if renders_a_control(src, n)]
        chosen = (control or sites)
        out[key] = (f"driven {PAGE_OF[form]}:{chosen[0]}" if chosen else "?")
    return out


def check_fixture(form: str, name: str, fx: dict, problems: list):
    src = cs.read_pages()[PAGE_OF[form]]
    table = fx.get("_classification")
    if not table:
        problems.append(f"{form}/{name}: no `_classification` block — "
                        f"F0-AC-108 requires every key classified IN the file")
        return
    keys = leaf_keys(fx)
    for key in keys:
        entry = table.get(key)
        if not entry:
            problems.append(f"{form}/{name}: key {key!r} is UNCLASSIFIED")
            continue
        parts = entry.split()
        if len(parts) != 2 or parts[0] not in ("driven", "constant"):
            problems.append(f"{form}/{name}: {key!r} bad classification "
                            f"{entry!r} — exactly one of driven/constant plus "
                            f"a file:line, and never `unreachable`")
            continue
        klass, cite = parts
        page, _, line_s = cite.rpartition(":")
        line = int(line_s)
        field = key.split(".")[-1]
        if line < 1 or line > len(src.splitlines()):
            problems.append(f"{form}/{name}: {key!r} cites {cite}, which is "
                            f"not a line of the pinned source")
            continue
        if klass == "constant":
            site = initialiser_site(src, field)
            if site is None or site[0] != line:
                problems.append(f"{form}/{name}: {key!r} is `constant` but "
                                f"{cite} is not its initialiser")
                continue
            declared = value_at(fx, key)
            if declared != site[1]:
                problems.append(
                    f"{form}/{name}: {key!r} is `constant` and declares "
                    f"{declared!r}, but the initialiser at {cite} is "
                    f"{site[1]!r}. A constant key whose value differs from its "
                    f"initialiser is a defect by definition (§ 6.5.3 item 7), "
                    f"not a disagreement to escalate.")
        else:
            if line not in write_sites(src, field):
                problems.append(f"{form}/{name}: {key!r} is `driven` but "
                                f"{cite} writes no such field")
                continue
            if not renders_a_control(src, line):
                problems.append(f"{form}/{name}: {key!r} is `driven` and "
                                f"{cite} writes the field but renders no "
                                f"control — the capability, not the wiring")
    for key in table:
        if key not in keys:
            problems.append(f"{form}/{name}: `_classification` carries "
                            f"{key!r}, which no longer exists in the fixture")


# ─────────────────────────────────────────────────────────────────────────────
# F0-AC-109 — the arm check
# ─────────────────────────────────────────────────────────────────────────────

# Read off `canProceed()`. Both pages gate their `existing` arm on
# `linkedRecord`, written only from a `/prerequisite-records` row, and that
# endpoint answers `data: []` for every `kind` on every account this programme
# has (manifest-authenticated.md:230-232).
ARMS = {
    "divorce": {
        "key": "basis.divorceType",
        "mode_key": "mediationMode",
        "reachable": ["voluntary+new", "contested"],
        "unreachable": ["voluntary+existing"],
        "cite": "DivorceCertificatePage.tsx:749-766",
        "exclusive": [("mediation", "court")],
    },
    "marriage": {
        "key": "betrothalMode",
        "mode_key": None,
        "reachable": ["new"],
        "unreachable": ["existing"],
        "cite": "MarriageCertificatePage.tsx:851-857",
        "exclusive": [],
    },
}


def arm_of(form: str, fx: dict):
    if form == "divorce":
        code = fx["basis"]["divorceType"]
        if code == "contested":
            return "contested"
        return f"{code}+{fx.get('mediationMode', '<undeclared>')}"
    return fx.get("betrothalMode", "<undeclared>")


def check_arms(loaded: dict, registered: str, problems: list):
    for form, spec in ARMS.items():
        seen = {arm_of(form, fx) for name, fx in loaded.get(form, {}).items()}
        for arm in spec["reachable"]:
            if arm not in seen:
                problems.append(
                    f"F0-AC-109(i) {form}: the arm {arm!r} is REACHABLE per "
                    f"{spec['cite']} and no fixture drives it. One of the two "
                    f"payload groups this page partitions is then only ever "
                    f"\"\", and a port that hardcoded \"\" there passes Tier 0 "
                    f"(F0-AC-86). Arms seen: {sorted(seen)}")
        for arm in spec["unreachable"]:
            if arm in seen:
                # Declared by a fixture AND unreachable — only legitimate when
                # the register carries it (F0-AC-81 clause iii).
                if form not in registered:
                    problems.append(
                        f"F0-AC-109(ii) {form}: a fixture declares the "
                        f"unreachable arm {arm!r} and oracle_coverage.yaml "
                        f"does not register it")
            elif form not in registered:
                problems.append(
                    f"F0-AC-109(ii) {form}: the arm {arm!r} cannot be driven "
                    f"and is not registered in oracle_coverage.yaml")
        for name, fx in loaded.get(form, {}).items():
            for a, b in spec["exclusive"]:
                if a in fx and b in fx:
                    problems.append(
                        f"F0-AC-109(iii) {form}/{name}: declares content from "
                        f"BOTH {a!r} and {b!r}, which {spec['cite']} makes "
                        f"mutually exclusive (§ 6.5.3 item 7b)")


def load_all() -> dict:
    out = {}
    for form in sorted(os.listdir(FIXTURES)):
        d = os.path.join(FIXTURES, form)
        if not os.path.isdir(d):
            continue
        out[form] = {}
        for name in sorted(os.listdir(d)):
            if name.endswith(".json"):
                with open(os.path.join(d, name), encoding="utf-8") as fh:
                    out[form][name] = json.load(fh)
    return out


def registered_forms() -> str:
    with open(REGISTER, encoding="utf-8") as fh:
        return fh.read()


def main() -> int:
    control = ""
    write = False
    for arg in sys.argv[1:]:
        if arg.startswith("--control="):
            control = arg.split("=", 1)[1]
        elif arg == "--write":
            write = True

    if write:
        for form, files in load_all().items():
            if form not in PAGE_OF:
                continue
            for name, fx in files.items():
                fx["_classification"] = classify(form, fx)
                path = os.path.join(FIXTURES, form, name)
                with open(path, "w", encoding="utf-8") as fh:
                    json.dump(fx, fh, ensure_ascii=False, indent=2)
                    fh.write("\n")
                unknown = [k for k, v in fx["_classification"].items()
                           if v == "?"]
                print(f"{form}/{name}: {len(fx['_classification'])} keys"
                      + (f"  UNRESOLVED {unknown}" if unknown else ""))
        return 0

    loaded = load_all()
    register = registered_forms()

    # ── the four planted controls, in memory only ────────────────────────────
    if control == "pod-country":
        for name in loaded["death"]:
            loaded["death"][name]["deceased"]["podCountry"] = "LA"
    elif control == "divorce-mutual":
        for name in loaded["divorce"]:
            loaded["divorce"][name]["basis"]["divorceType"] = "mutual"
    elif control == "betrothal-existing":
        for name in loaded["marriage"]:
            loaded["marriage"][name]["betrothalMode"] = "existing"
            loaded["marriage"][name]["linkedRecord"] = None
        register = register.replace("betrothalMode", "xx-neutralised-xx")
    elif control == "delete-contested":
        for name in [n for n in loaded["divorce"] if n.startswith("contested")]:
            del loaded["divorce"][name]

    problems = []
    for form, files in loaded.items():
        if form not in PAGE_OF:
            continue
        for name, fx in files.items():
            check_fixture(form, name, fx, problems)
    check_arms(loaded, register, problems)

    total = sum(len(leaf_keys(fx)) for form, files in loaded.items()
                if form in PAGE_OF for fx in files.values())
    print(f"F0-AC-108: {total} fixture keys classified and checked across "
          f"{sum(len(f) for k, f in loaded.items() if k in PAGE_OF)} files")
    for p in problems:
        print(f"  {p}")

    if control:
        if not problems:
            print(f"F0-AC-108/109 CONTROL FAIL — --control={control} left the "
                  f"check GREEN. The check is inert against that defect, and "
                  f"a check that passes on the tree as it stood at v1.3 is "
                  f"exactly what F0-AC-108 rejects.")
            return 1
        print(f"control --control={control}: the check FAILED as required, "
              f"with {len(problems)} finding(s).")
        return 0

    print("F0-AC-108, F0-AC-109: PASS" if not problems
          else f"F0-AC-108/109: FAIL — {len(problems)} finding(s)")
    return 0 if not problems else 1


if __name__ == "__main__":
    raise SystemExit(main())
