#!/usr/bin/env python3
"""`F0-AC-107` — the `constant:` register is DERIVED FROM THE SOURCE, both ways.

    python3 test/fidelity/constant_scan.py            # scan + assert
    python3 test/fidelity/constant_scan.py --json     # the derived set only
    python3 test/fidelity/constant_scan.py --control=planted-writer
    python3 test/fidelity/constant_scan.py --control=planted-row

RULING 12(b) refused the offered exemption — "declare the leaf driver-inert and
exempt it from `F0-AC-104`" — and put the leaf in a `constant:` section of
`oracle_coverage.yaml` instead. The difference between those two is entirely
this file. An exemption is asserted once and catches nothing afterwards; a
register whose membership is RECOMPUTED from the pinned source every run goes
red the moment a leaf stops qualifying.

## What "constant" means here, stated as a decision procedure

A page-state field is `constant` when all four hold:

  1. **declared** — it is a member of a state group's TypeScript interface, or
     of the blank record that initialises it;
  2. **initialised** — the blank record gives it a literal;
  3. **read into a payload** — `buildFormData` reads `<group>.<field>`;
  4. **written by nothing** — no `patch*` / `set*` call carries it as a static
     key, no component `onChange` writes it, and no computed (`[expr]:`) key
     can resolve to it.

Clause 4 is the whole content and the only one that is hard. This file does not
try to prove absence by reasoning about React; it proves it by enumerating
every occurrence of the identifier in the page and requiring each one to be a
site that cannot write:

  * a type-member declaration   `podCountry: string;`
  * an initialiser member       `podCountry: "Laos",`   (inside the blank record)
  * a member READ               `deceased.podCountry`

Anything else — an occurrence inside a `patch*(...)`/`set*(...)` argument, an
ES shorthand `{ podCountry }`, a JSX prop — disqualifies the field. So does a
computed key this file cannot resolve: `MarriageCertificatePage.tsx:1501` and
`:1509` write `patchReg({ [w.kn]: v })`, and the scanner resolves `w.kn`
through the `as const` literals in the same array rather than waving at it.
An UNRESOLVABLE computed write makes the whole page `UNCERTIFIABLE`, which
fails the assertion — a scanner that cannot see a writer must not report the
absence of one.

## The two negative controls, one per direction

`--control=planted-writer` copies `DeathDeclarationPage.tsx` into a scratch
buffer with a `patchDeceased({ podCountry: v })` writer added, re-derives, and
requires `podCountry` to DROP OUT and the equality to FAIL.
`--control=planted-row` adds a `constant:` row with no scan support and
requires the equality to FAIL the other way.

Neither control writes to `$PROJ/sources/lcc-app`. § 4.1 makes any write under
that tree an automatic FAIL (`F0-AC-66`); the planted page exists only as a
string in memory.
"""
from __future__ import annotations

import functools
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(os.path.dirname(HERE))
PROJECT = os.path.dirname(os.path.dirname(PKG))
WEB = os.path.join(PROJECT, "sources", "lcc-app")
COMPONENTS = os.path.join(WEB, "src", "app", "components")
REGISTER = os.path.join(HERE, "oracle_coverage.yaml")

# The five pinned pages § 6.5.7 measures over. FamilyBook has no `form_data`
# and no state group feeding one, so it carries no candidate.
PAGES = [
    "ResidentCertificatePage.tsx",
    "BirthDeclarationPage.tsx",
    "DeathDeclarationPage.tsx",
    "MarriageCertificatePage.tsx",
    "DivorceCertificatePage.tsx",
]

_STR = re.compile(r'"(?:\\.|[^"\\])*"' r"|'(?:\\.|[^'\\])*'" r"|`(?:\\.|[^`\\])*`")


def _spaces_like(text: str) -> str:
    """Same length, same newlines, everything else a space."""
    return "".join("\n" if c == "\n" else " " for c in text)


@functools.lru_cache(maxsize=32)
def blanked(text: str) -> str:
    """Comments and string bodies replaced by spaces, LENGTH AND LINE COUNT
    PRESERVED, so brace counting and identifier scanning cannot be fooled by a
    `{` or a word inside a Lao sentence.

    Both halves are load-bearing and the FIRST one is not obvious.
    MEASURED: `MarriageCertificatePage.tsx:255` is the comment
    `/** … this adds the server's. */`. That lone apostrophe opens a
    single-quoted string as far as a naive string matcher is concerned, and the
    match then runs to the next apostrophe hundreds of lines later — blanking
    the whole of `SpouseSection`, including the thirteen `onChange({ field: v })`
    writes this file exists to find. The first version of this scanner reported
    `spouseA.residenceCertRef` and `spouseA.address` as CONSTANT for exactly
    that reason: fields written by a control on every run, certified as written
    by nothing. Comments are therefore stripped BEFORE strings are blanked.

    Preserving newlines is the second half: the original replacement collapsed
    the swallowed span's newlines to spaces, so every line number this file
    cited after that point was wrong by hundreds — and a `constant:` row's
    whole value is its citation.

    It is ONE left-to-right pass and not two regex substitutions, because the
    two halves are mutually entangled and either order is wrong. Strings first
    leaves `the server's` (`:255`, in a comment) opening a string. Comments
    first leaves `accept="image/*"` (`ResidentCertificatePage.tsx:226`, in a
    string) opening a block comment — which swallowed everything down to the
    next `*/` and left the whole of `province` / `district` / `villageName`
    invisible, so all three were reported CONSTANT while `:871-873` writes them
    on every location pick. A lexer has no order to get wrong.
    """
    out = list(text)
    i, n = 0, len(text)
    mode = None          # None | "//" | "/*" | "'" | '"' | "`"

    def blank(at):
        if out[at] != "\n":
            out[at] = " "

    while i < n:
        c = text[i]
        if mode is None:
            if c == "/" and i + 1 < n and text[i + 1] == "/":
                mode, i = "//", i + 2
                continue
            if c == "/" and i + 1 < n and text[i + 1] == "*":
                blank(i), blank(i + 1)
                mode, i = "/*", i + 2
                continue
            if c in "'\"`":
                mode, i = c, i + 1
                continue
            i += 1
            continue
        if mode == "//":
            if c == "\n":
                mode = None
            else:
                blank(i)
            i += 1
            continue
        if mode == "/*":
            if c == "*" and i + 1 < n and text[i + 1] == "/":
                blank(i), blank(i + 1)
                mode, i = None, i + 2
                continue
            blank(i)
            i += 1
            continue
        # inside a string of kind `mode`
        if c == "\\":
            blank(i)
            if i + 1 < n:
                blank(i + 1)
            i += 2
            continue
        if c == mode:
            mode = None
            i += 1
            continue
        blank(i)
        i += 1
    return "".join(out)


def span_from(src: str, start: int) -> tuple:
    """`(text, end)` for the bracket group opening at `start`."""
    depth = 0
    b = blanked(src)
    for i in range(start, len(src)):
        if b[i] in "([{":
            depth += 1
        elif b[i] in ")]}":
            depth -= 1
            if depth == 0:
                return src[start:i + 1], i + 1
    return src[start:], len(src)


def setter_windows(b: str) -> list:
    """`(start, end)` of every `set*(…)` / `patch*(…)` argument list.

    Takes the BLANKED source so a call spelled inside a string or a comment
    does not open a window. Shared with `fixture_classify.py`, which needs the
    same notion of "somewhere a write can happen" for `F0-AC-108`.
    """
    windows = []
    for call in re.finditer(r"(?<![\w$.])(?:set|patch)[A-Z][\w$]*\s*\(", b):
        _, end = span_from(b, call.end() - 1)
        windows.append((call.end() - 1, end))
    return windows


class Uncertifiable(Exception):
    """A writer this scanner cannot see. Never downgraded to "no writer"."""


def state_groups(src: str) -> dict:
    """`{ident: (initialiser_text, line)}` for every `useState` group."""
    out = {}
    for m in re.finditer(
            r"const\s+\[\s*([A-Za-z_$][\w$]*)\s*,\s*set[\w$]+\s*\]\s*"
            r"=\s*useState\s*(?:<[^>]*>)?\s*\(", src):
        text, _ = span_from(src, m.end() - 1)
        out[m.group(1)] = (text[1:-1].strip(),
                           src.count("\n", 0, m.start()) + 1)
    return out


def blank_record(src: str, ident: str) -> str:
    """`const blankX: T = { … }` — the record a `useState(blankX)` points at."""
    m = re.search(r"const\s+" + re.escape(ident) + r"\s*(?::[^=]*)?=\s*\{", src)
    if not m:
        return ""
    text, _ = span_from(src, m.end() - 1)
    return text


def payload_reads(src: str) -> set:
    """`(group, field)` pairs `buildFormData` reads."""
    m = re.search(r"const buildFormData = ", src)
    if not m:
        return set()
    start = src.index("{", m.end())
    text, _ = span_from(src, start)
    # Over the BLANKED text. Death and Birth are the flat family and spell
    # their wire keys as string literals — `"header.district_id": …` — which a
    # raw scan reads as a member access on a state group called `header` and
    # then hunts for a `district_id` field that does not exist in page state.
    return set(re.findall(r"\b([a-z][\w$]*)\.([a-zA-Z_$][\w$]*)\b",
                          blanked(text)))


def initialiser_of(record: str, field: str):
    """The literal `field` is initialised to inside a blank record, or None."""
    m = re.search(r"(?:^|[{,\s])" + re.escape(field) + r"\s*:\s*([^,}]+)",
                  record)
    if not m:
        return None
    return m.group(1).strip()


def computed_key_targets(src: str) -> set:
    """Every field name a computed (`[expr]:`) write could resolve to.

    MEASURED, the one shape in these five pages is Marriage's witness table:
    `{ kn: "w1Name" as const, ki: "w1Id" as const }` consumed as
    `patchReg({ [w.kn]: v })` (`:1501`, `:1509`). Those resolve. Any OTHER
    computed key raises `Uncertifiable` — the scanner refuses to certify a page
    whose writes it cannot follow.
    """
    targets = set()
    # Only computed keys inside a STATE SETTER call can write state. Scanning
    # the whole file instead reports two shapes that write nothing of the kind:
    # a ternary's array arm (`? [{ … }] :`, `MarriageCertificatePage.tsx:1053`)
    # and `parentData`'s payload key (``[`${prefix}.name`]:``,
    # `BirthDeclarationPage.tsx:466`), which builds the WIRE object, not the
    # page's state.
    b = blanked(src)
    windows = setter_windows(b)
    for m in re.finditer(r"\[\s*([^\]\n{}]+?)\s*\]\s*:", b):
        if not any(lo <= m.start() < hi for lo, hi in windows):
            continue
        head = b[:m.start()].rstrip()
        if not head.endswith(("{", ",")):
            continue
        expr = src[m.start(1):m.end(1)].strip()
        if re.fullmatch(r'"[^"]*"', expr):
            targets.add(expr[1:-1])
            continue
        chain = re.fullmatch(r"[A-Za-z_$][\w$]*\.([A-Za-z_$][\w$]*)", expr)
        if chain:
            prop = chain.group(1)
            lits = re.findall(re.escape(prop) + r'\s*:\s*"([^"]*)"\s*as const',
                              src)
            if not lits:
                raise Uncertifiable(
                    f"computed key `[{expr}]:` — no `{prop}: \"…\" as const` "
                    f"literals to resolve it against")
            targets.update(lits)
            continue
        if re.fullmatch(r"[A-Za-z_$][\w$]*", expr):
            # The generic setter shape. MEASURED, one instance:
            # `ResidentCertificatePage.tsx:378-379`,
            # `const set = <K extends keyof FormData>(key: K, value: …) =>
            #    setForm((f) => ({ ...f, [key]: value }))`.
            # The key is not in this expression at all — it is at every CALL
            # SITE, as a string literal (`set("citizenName", v)`). So the
            # writable set is the set of those literals, and a call whose first
            # argument is not a literal makes the page uncertifiable.
            targets.update(_generic_setter_targets(src, expr, m.start()))
            continue
        raise Uncertifiable(f"computed key `[{expr}]:` — unresolvable shape")
    return targets


def _generic_setter_targets(src: str, param: str, at: int) -> set:
    """Every literal first argument passed to the setter that owns `[param]:`."""
    decl = None
    for m in re.finditer(r"const\s+([A-Za-z_$][\w$]*)\s*=\s*"
                         r"(?:<[^=]*?>)?\s*\(\s*" + re.escape(param)
                         + r"\s*[:,)]", src):
        if m.start() < at:
            decl = m
    if decl is None:
        raise Uncertifiable(
            f"computed key `[{param}]:` — no enclosing `const NAME = "
            f"({param}, …) =>` to resolve the call sites against")
    name = decl.group(1)
    calls = list(re.finditer(r"(?<![\w$.])" + re.escape(name) + r"\s*\(", src))
    literals, opaque = set(), 0
    for call in calls:
        if call.start() == decl.start():
            continue
        arg = src[call.end():call.end() + 200].lstrip()
        lit = re.match(r'"([^"]*)"', arg)
        if lit:
            literals.add(lit.group(1))
        elif not arg.startswith(("f)", "(f)", "prev", "p)")):
            opaque += 1
    if opaque:
        raise Uncertifiable(
            f"`{name}(…)` has {opaque} call site(s) whose first argument is "
            f"not a string literal — the writable key set is not enumerable, "
            f"so no field on this page can be certified as unwritten")
    if not literals:
        raise Uncertifiable(f"`{name}(…)` has no literal call sites to "
                            f"enumerate")
    return literals


def occurrences_are_all_inert(src: str, group: str, field: str,
                              record: str) -> bool:
    """Every occurrence of `field` is a declaration, an initialiser or a read.

    The read form is deliberately `<anything>.field`, not `<group>.field`: the
    same field is read through a local alias inside a helper (`s.gender`,
    `p.fullName`) and a stricter pattern would call a harmless read a writer.
    A WRITE never looks like that — it is `field:` or `{ field }`.
    """
    b = blanked(src)
    for m in re.finditer(r"\b" + re.escape(field) + r"\b", b):
        i, j = m.start(), m.end()
        before = b[max(0, i - 40):i]
        after = b[j:j + 40]
        if before.rstrip().endswith("."):
            continue                                   # a member read
        if re.match(r"\s*[?]?\s*:\s*(?:string|number|boolean|\w+\[\]|"
                    r"[A-Z][\w$]*)\s*;", after):
            continue                                   # a type member
        line_start = b.rfind("\n", 0, i) + 1
        line = src[line_start:src.find("\n", j)]
        if record and line.strip() in [ln.strip()
                                       for ln in record.splitlines()]:
            continue                                   # the initialiser
        return False
    return True


def derive(pages_src: dict) -> list:
    """The `constant` set, as `[{field, group, page, initialiser, cites}]`."""
    found = []
    for page, src in pages_src.items():
        targets = computed_key_targets(src)
        groups = state_groups(src)
        for group, field in sorted(payload_reads(src)):
            if group not in groups:
                continue
            init_text, init_line = groups[group]
            record = (blank_record(src, init_text)
                      if re.fullmatch(r"[A-Za-z_$][\w$]*", init_text)
                      else (init_text if init_text.startswith("{") else ""))
            if not record:
                continue
            literal = initialiser_of(record, field)
            if literal is None:
                continue
            if field in targets:
                continue
            if not occurrences_are_all_inert(src, group, field, record):
                continue
            lines = src.splitlines()
            cites = [i + 1 for i, ln in enumerate(lines)
                     if re.search(r"\b" + re.escape(field) + r"\b", ln)]
            found.append({
                "field": field, "group": group, "page": page,
                "initialiser": literal.strip().strip('"'),
                "cites": [f"{page}:{n}" for n in cites],
            })
    return found


def read_pages(override: dict = None) -> dict:
    out = {}
    for page in PAGES:
        with open(os.path.join(COMPONENTS, page), encoding="utf-8") as fh:
            out[page] = fh.read()
    for name, text in (override or {}).items():
        out[name] = text
    return out


def register_constants(extra_row: str = None) -> list:
    """`oracle_coverage.yaml`'s `constant:` section — `field` per row.

    Parsed with a five-line reader rather than a YAML dependency: the package
    has none, and adding one to satisfy a register check would put a new
    third-party parser between this assertion and its evidence.
    """
    with open(REGISTER, encoding="utf-8") as fh:
        text = fh.read()
    if extra_row:
        text = re.sub(r"(?m)^constant:\n",
                      f"constant:\n  - field: {extra_row}\n    page: "
                      f"NoSuchPage.tsx\n", text, count=1)
    m = re.search(r"(?m)^constant:\n", text)
    if not m:
        return []
    rows, i = [], m.end()
    for line in text[i:].splitlines():
        if line and not line.startswith((" ", "\t", "#")):
            break
        hit = re.match(r"\s*-\s*field:\s*(\S+)", line)
        if hit:
            rows.append(hit.group(1))
    return rows


PLANTED_WRITER = """
  const plantedWriter = (v: string) => patchDeceased({ podCountry: v });
"""


def main() -> int:
    control = ""
    for arg in sys.argv[1:]:
        if arg.startswith("--control="):
            control = arg.split("=", 1)[1]
        elif arg == "--json":
            print(json.dumps(derive(read_pages()), indent=2))
            return 0

    override, extra_row = {}, None
    if control == "planted-writer":
        # In memory only. Nothing is written under sources/lcc-app.
        src = read_pages()["DeathDeclarationPage.tsx"]
        anchor = "  const patchDeceased ="
        override["DeathDeclarationPage.tsx"] = src.replace(
            anchor, PLANTED_WRITER + anchor, 1)
        assert override["DeathDeclarationPage.tsx"] != src, \
            "the planted-writer control did not plant anything"
    elif control == "planted-row":
        extra_row = "notAFieldAnyPageHas"

    try:
        derived = derive(read_pages(override))
    except Uncertifiable as err:
        print(f"F0-AC-107 FAIL — UNCERTIFIABLE: {err}")
        return 1

    derived_fields = sorted({row["field"] for row in derived})
    registered = sorted(register_constants(extra_row))

    print(f"derived   ({len(derived_fields)}): {derived_fields}")
    print(f"registered({len(registered)}): {registered}")
    for row in derived:
        print(f"  {row['field']}  {row['group']}  init={row['initialiser']!r}"
              f"  {row['cites']}")

    missing = [f for f in derived_fields if f not in registered]
    extra = [f for f in registered if f not in derived_fields]
    ok = not missing and not extra
    if missing:
        print(f"F0-AC-107 FAIL — derived but NOT registered: {missing}")
    if extra:
        print(f"F0-AC-107 FAIL — registered with NO scan support: {extra}")

    if control:
        if ok:
            print(f"F0-AC-107 CONTROL FAIL — --control={control} left the "
                  f"equality GREEN. The assertion is inert in that direction.")
            return 1
        print(f"F0-AC-107 control --control={control}: the equality FAILED as "
              f"required.")
        return 0

    print("F0-AC-107: PASS — set equality, both directions." if ok
          else "F0-AC-107: FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
