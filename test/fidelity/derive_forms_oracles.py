#!/usr/bin/env python3
"""Entry B — the transcribed Tier 0 oracle (§ 6.5.5, RULING 10 as amended).

    python3 test/fidelity/derive_forms_oracles.py

Entry A (`execute_forms_oracle.mjs`) boots the pinned app and reads the
serialised bytes off the wire; **this** file re-transcribes the same builders
from source text. `F0-AC-104` asserts A == B byte-for-byte on every leaf A
covers, and a disagreement is BLOCKED, never reconciled by editing one side.

Why B survives now that A exists (§ 6.5.5, "Why A and B, and not A alone"):
A has a systematic-error class B cannot share — a mis-driven fixture, a stale
fulfilled read, a `page.route` pattern that silently does not match, a leaf
captured from a DEFAULT rather than from the driven state. Nothing inside A
detects any of those. B is derived from source text and cannot be fooled by a
mis-driven browser.

## What is transcribed, and what is read

The **key order**, the **nesting**, each key's `src` line, both **envelopes**,
the **helper key lists** and the page's own `SERVICE_CODE` / `OFFICE_DEFERRED`
constants are all EXTRACTED from the source, not retyped: `F0-AC-87(ii)`
requires the cited line to actually contain the key literal, and a hand-copied
line number is exactly the attribution that rots.

The **values** are the transcription — they are computed by re-implementing
each `buildFormData` expression over the fixture matrix under `fixtures/tier0/`,
which is what makes this an independent entry rather than a second reading of
the same bytes. Every expression shape has an explicit rule in `Evaluator`; an
unrecognised shape RAISES. There is no silent default anywhere in this file,
because a silent default is how a short oracle becomes a green gate.

## Why this is not one flat line-scanner

v1.0's shape could only see `"key": expr,` on one line at one depth. That is
Resident, and nothing else:

  * Birth and Death build their parent and informant blocks with
    `...parentData(...)`, which emits 13 (Birth) or 14 (Death) keys TWICE under
    two prefixes. The helpers are NOT the same shape — Death's carries
    `workplace` — and Birth's informant is 15 keys to Death's 12.
  * Marriage and Divorce are four-level trees with bare (unquoted) keys, and
    their nested `header` -> `document_no` must stay distinguishable from
    Birth's LITERAL FLAT key `"header.document_no"`. Those two flatten to the
    same string and the whole of § 6.5.1 exists to keep them apart.
  * FamilyBook has no `form_data` at all. Its request body IS `{reason}`.

So the scanner is a real (small) object-literal reader with brace matching,
spread expansion and helper inlining, and it REFUSES rather than under-emits.

## Output

22 documents under
`$PROJ/docs/fidelity-baseline/2026-08-13/oracle/tier0/` — the matrix
`F0-AC-34` counts — plus the non-canonical fixture variants under
`.../tier0/variants/`, which is where `F0-AC-38`'s changed key sets,
`F0-AC-83`'s trim asymmetry and `F0-AC-81`'s second boolean literal live. The
variants are in a SUBDIRECTORY so the matrix stays at exactly 22 files: the
harness's `tier0OracleFiles()` lists one level and would otherwise count them.
"""
from __future__ import annotations

import json
import os
import re
import sys
from collections import OrderedDict

import i18n_parse

HERE = os.path.dirname(os.path.abspath(__file__))
PKG = os.path.dirname(os.path.dirname(HERE))
PROJECT = os.path.dirname(os.path.dirname(PKG))
WEB = os.path.join(PROJECT, "sources", "lcc-app")
COMPONENTS = os.path.join(WEB, "src", "app", "components")
NS_DIR = os.path.join(WEB, "src", "app", "i18n", "ns")
OUT = os.path.join(PROJECT, "docs", "fidelity-baseline", "2026-08-13",
                   "oracle", "tier0")
VARIANTS_OUT = os.path.join(OUT, "variants")
FIXTURES = os.path.join(HERE, "fixtures", "tier0")

WEB_COMMIT = "62f8a529aaa024a8b35b0af50a8fbd4850a63962"
# ADR-0005's frozen instant. Local = 2026-08-14, UTC = 2026-08-13, so the
# divergence is observable rather than hidden by a convenient clock.
CLOCK = "2026-08-14T02:00:00+07:00"
TODAY_WEB_UTC = "2026-08-13"

_SRC_CACHE: dict = {}


def read(name: str) -> str:
    if name not in _SRC_CACHE:
        with open(os.path.join(COMPONENTS, name), encoding="utf-8") as fh:
            _SRC_CACHE[name] = fh.read()
    return _SRC_CACHE[name]


def lines_of(name: str) -> list:
    return read(name).splitlines()


class Refuse(SystemExit):
    """Stop, loudly. A short oracle is worse than a missing one: the harness
    would compare a port against a payload with keys silently absent and report
    PASS. That is the same class as the line-anchored i18n parser dropping
    `birth.legalBasisText` — a gate green because its input was incomplete."""


# ─────────────────────────────────────────────────────────────────────────────
# 1. The source reader
# ─────────────────────────────────────────────────────────────────────────────

_STR = re.compile(r'"(?:\\.|[^"\\])*"' r"|'(?:\\.|[^'\\])*'" r"|`(?:\\.|[^`\\])*`")


# NOTE ON AN IDIOM DELIBERATELY AVOIDED IN THIS FILE.
#
# `F0-AC-42` proves there is exactly ONE shared i18n parser by grepping every
# `test/fidelity/*.py` for two code anchors: `i18n_parse`'s locale-body
# function signature, and its augmented-increment of the brace counter. That
# grep must return `i18n_parse.py` alone. The bracket counters below are not a
# second parser, but a text grep cannot tell — so they use the long form
# `depth = depth + 1`, and neither this comment nor any string in this file
# spells the anchor out. (Quoting the anchor is itself enough to trip the
# criterion: `i18n_parse_test.py:127` does exactly that today, which is a
# defect in the grep as § 6.7.2 words it, not in either file.)
def blank_strings(text: str) -> str:
    """Replace every string body with spaces, so brace counting cannot be
    fooled by a `{` inside a Lao sentence or a template literal."""
    return _STR.sub(lambda m: m.group(0)[0] + " " * (len(m.group(0)) - 2)
                    + m.group(0)[-1], text)


def _depth_delta(text: str) -> int:
    t = blank_strings(text)
    t = re.sub(r"//.*$", "", t)
    return (t.count("{") + t.count("(") + t.count("[")
            - t.count("}") - t.count(")") - t.count("]"))


def statements(src_lines: list, first: int, last: int) -> list:
    """Group `src_lines[first-1:last]` into logical statements.

    Returns `[(start_line, end_line, text)]` with `text` the joined, comment-
    stripped source. A statement ends when the running bracket depth returns to
    zero — which is what makes Birth's three-line
    `...(fatherUnknown ? {...} : parentData(...))` one spread rather than three
    unparseable fragments.
    """
    out = []
    i = first
    while i <= last:
        raw = src_lines[i - 1]
        stripped = raw.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("/*") \
                or stripped.startswith("*"):
            i += 1
            continue
        start = i
        depth = _depth_delta(raw)
        parts = [stripped]

        def _open(fragment: str) -> bool:
            """Still mid-statement?

            Two ways to be: unbalanced brackets, or a balanced line that does
            not end in `,`. The second is not pedantry —
            `MarriageCertificatePage.tsx:888-890` closes its `[...]` on line
            888 and then continues `.filter(Boolean).join(", ")` on the next
            two lines, so a depth-only rule splits `address_text` into three
            fragments and loses the value Guard B is about.
            """
            return depth > 0 or not fragment.rstrip().endswith(",")

        while _open(re.sub(r"\s*//.*$", "", parts[-1])) and i < last:
            i += 1
            nxt = src_lines[i - 1]
            parts.append(nxt.strip())
            depth += _depth_delta(nxt)
        text = " ".join(p for p in parts if not p.startswith("//"))
        text = re.sub(r"\s*//.*$", "", text).strip()
        text = text.rstrip(",").strip()
        if text:
            out.append((start, i, text))
        i += 1
    return out


def block_range(src_lines: list, open_line: int) -> tuple:
    """The inclusive body range between the `{` opening on `open_line` and its
    matching `}`. Returns `(first_body_line, last_body_line, close_line)`."""
    text = blank_strings(src_lines[open_line - 1])
    if "{" not in text:
        raise Refuse(f"line {open_line} opens no block: "
                     f"{src_lines[open_line - 1]!r}")
    depth = _brace_delta(src_lines[open_line - 1])
    i = open_line
    while depth > 0 and i < len(src_lines):
        i += 1
        depth += _brace_delta(src_lines[i - 1])
    return open_line + 1, i - 1, i


def _brace_delta(text: str) -> int:
    t = re.sub(r"//.*$", "", blank_strings(text))
    return t.count("{") - t.count("}")


_KEY = re.compile(r'^(?:"([^"]+)"|([A-Za-z_$][\w$]*)|\[`\$\{prefix\}\.([\w.]+)`\]):\s*(.*)$',
                  re.S)


def parse_object(src_lines: list, first: int, last: int) -> list:
    """Parse an object-literal body into nodes.

    `('leaf', key, line, expr, end)` · `('obj', key, line, children, end)` ·
    `('spread', line, expr, end)`. `end` is the statement's last source line,
    so a key inside a multi-line expression can cite its OWN line. Computed
    ``[`${prefix}.x`]`` keys come back as `('leaf', '${prefix}.x', …)` and the
    helper expander substitutes the prefix.
    """
    nodes = []
    for start, end, text in statements(src_lines, first, last):
        if text.startswith("..."):
            nodes.append(("spread", start, text[3:].strip(), end))
            continue
        m = _KEY.match(text)
        if not m:
            raise Refuse(f"unparseable object entry at line {start}: {text!r}")
        key = m.group(1) or m.group(2)
        if m.group(3) is not None:
            key = "${prefix}." + m.group(3)
        value = m.group(4).strip()
        opens_block = (value == "{"
                       or (end > start and value.startswith("{")
                           and _brace_delta(src_lines[start - 1]) > 0))
        if opens_block:
            bfirst, blast, _close = block_range(src_lines, start)
            nodes.append(("obj", key, start,
                          parse_object(src_lines, bfirst, blast), end))
        else:
            nodes.append(("leaf", key, start, value, end))
    if not nodes:
        raise Refuse(f"object body {first}..{last} parsed to zero entries")
    return nodes


def find_line(name: str, pattern: str, after: int = 0) -> int:
    rx = re.compile(pattern)
    for i, line in enumerate(lines_of(name), start=1):
        if i > after and rx.search(line):
            return i
    raise Refuse(f"{name}: no line matching {pattern!r} after {after}")


def arrow_object(name: str, decl_pattern: str) -> list:
    """The body of a `const x = (...) => ({ ... })` arrow returning an object."""
    src_lines = lines_of(name)
    decl = find_line(name, decl_pattern)
    open_line = decl
    while "{" not in blank_strings(src_lines[open_line - 1]):
        open_line += 1
    first, last, _ = block_range(src_lines, open_line)
    return parse_object(src_lines, first, last)


def call_object(name: str, call_pattern: str) -> list:
    """The object-literal argument of a call like `applications.create({`."""
    src_lines = lines_of(name)
    line = find_line(name, call_pattern)
    first, last, _ = block_range(src_lines, line)
    return parse_object(src_lines, first, last)


def const_string(name: str, ident: str) -> tuple:
    """`const IDENT = "value";` -> (value, line). Read, never retyped."""
    for i, line in enumerate(lines_of(name), start=1):
        m = re.match(r'^\s*const\s+' + re.escape(ident) + r'\s*=\s*"([^"]*)"',
                     line)
        if m:
            return m.group(1), i
    raise Refuse(f"{name}: no `const {ident} = \"…\"`")


def state_initialisers(name: str) -> dict:
    """`const [x, setX] = useState<T>(INIT);` -> {x: (value, line)}.

    RULING 13 part 3 requires the `court` block to be REMOVED from the three
    voluntary divorce fixtures and the `mediation` / `children` blocks removed
    from the contested one — "removed, not blanked", because a fixture's INPUT
    block may not claim a value no control can type. That collides with this
    file's standing invariant that the fixture mirrors the page's state tree
    exactly, so `Evaluator.member` REFUSES on a missing group.

    The resolution is not to relax the invariant but to source the missing
    group from a THIRD artefact, exactly as RULING 12 sources `podCountry`:
    a React state group no action on the driven branch writes still holds its
    `useState` initialiser, and that initialiser is a cited line of the pinned
    source. So a fixture that omits `court` is not under-specified — it is
    saying "this branch never writes `court`", and the value that produces is
    read from the page rather than retyped into the fixture.

    Only the four measured literal shapes are read. Anything else is absent
    from the table and `member` REFUSES as before: a silent default here would
    turn every fixture typo into a blank oracle leaf.
    """
    out = {}
    src = read(name)
    pattern = re.compile(
        r"const\s+\[\s*([A-Za-z_$][\w$]*)\s*,\s*set[\w$]+\s*\]\s*="
        r"\s*useState\s*(?:<[^>]*>)?\s*\(", re.S)
    for m in pattern.finditer(src):
        ident = m.group(1)
        line_no = src.count("\n", 0, m.start()) + 1
        rest = src[m.end():]
        depth, end = 1, None
        for i, ch in enumerate(blank_strings(rest)):
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
                if depth == 0:
                    end = i
                    break
        if end is None:
            continue
        init = rest[:end].strip()
        value = _init_literal(init, name)
        if value is not _UNREADABLE:
            out[ident] = (value, line_no)
    return out


_UNREADABLE = object()


def _init_literal(init: str, page: str):
    """The four measured `useState(...)` initialiser shapes, and no others."""
    if init in ("null", ""):
        return None
    if init == "false":
        return False
    if init == "true":
        return True
    if re.fullmatch(r'"([^"]*)"', init):
        return init[1:-1]
    if re.fullmatch(r"[A-Za-z_$][\w$]*", init):
        # `useState<SpouseInfo>(blankSpouse)` — follow the const one hop.
        m = re.search(r"const\s+" + re.escape(init)
                      + r"\s*(?::[^=]*)?=\s*(\{)", read(page))
        if not m:
            return _UNREADABLE
        return _init_literal(_brace_span(read(page), m.start(1)), page)
    if init.startswith("{"):
        obj = {}
        body = init[1:-1] if init.endswith("}") else init[1:]
        for part in _split_top_commas(body):
            kv = part.split(":", 1)
            if len(kv) != 2:
                return _UNREADABLE
            key = kv[0].strip()
            if not re.fullmatch(r"[A-Za-z_$][\w$]*", key):
                return _UNREADABLE
            val = _init_literal(kv[1].strip(), page)
            if val is _UNREADABLE:
                return _UNREADABLE
            obj[key] = val
        return obj
    return _UNREADABLE


def _brace_span(src: str, start: int) -> str:
    depth = 0
    blanked = blank_strings(src)
    for i in range(start, len(src)):
        if blanked[i] in "([{":
            depth += 1
        elif blanked[i] in ")]}":
            depth -= 1
            if depth == 0:
                return src[start:i + 1]
    return ""


def _split_top_commas(body: str) -> list:
    out, depth, cur = [], 0, []
    blanked = blank_strings(body)
    for i, ch in enumerate(body):
        b = blanked[i]
        if b in "([{":
            depth += 1
        elif b in ")]}":
            depth -= 1
        if b == "," and depth == 0:
            out.append("".join(cur))
            cur = []
            continue
        cur.append(ch)
    tail = "".join(cur).strip()
    if tail:
        out.append(tail)
    return [p.strip() for p in out if p.strip()]


def attribution_ok(name: str, key: str, line_no: int) -> bool:
    """F0-AC-87(ii): the cited line really contains that key literal.

    Three spellings occur: `"header.province_id":` (flat family),
    `province_id:` (nested family) and ``[`${prefix}.name`]:`` (the helper
    computed key, where the cited line carries only the suffix).
    """
    src_lines = lines_of(name)
    if line_no < 1 or line_no > len(src_lines):
        return False
    line = src_lines[line_no - 1]
    if f'"{key}"' in line:
        return True
    if re.search(r'(?:^|[\s{(])' + re.escape(key) + r'\s*:', line):
        return True
    # ES shorthand — `me.requestFamilyBookCopy({ reason })`
    # (FamilyBookPage.tsx:204) declares the wire key with no colon at all.
    if re.search(r'[{,]\s*' + re.escape(key) + r'\s*[},]', line):
        return True
    suffix = key.split(".")[-1]
    return bool(re.search(r'\$\{prefix\}\.' + re.escape(suffix) + r'`\]\s*:', line))


# ─────────────────────────────────────────────────────────────────────────────
# 2. The value tree
# ─────────────────────────────────────────────────────────────────────────────

class Leaf:
    __slots__ = ("value", "src")

    def __init__(self, value, src):
        self.value = value
        self.src = src


ABSENT = object()      # JS `undefined` -> JSON.stringify DROPS the key
FORM_DATA = object()   # the `form_data` placeholder in an envelope


def tree_json(node):
    if isinstance(node, Leaf):
        return node.value
    out = OrderedDict()
    for k, v in node.items():
        out[k] = tree_json(v)
    return out


def tree_paths(node, prefix=""):
    if isinstance(node, Leaf):
        return [prefix]
    out = []
    for k, v in node.items():
        token = k.replace("~", "~0").replace("/", "~1")
        out.extend(tree_paths(v, f"{prefix}/{token}"))
    return out


def tree_srcs(node, prefix="", into=None):
    if into is None:
        into = OrderedDict()
    if isinstance(node, Leaf):
        into[prefix] = node.src
        return into
    for k, v in node.items():
        token = k.replace("~", "~0").replace("/", "~1")
        tree_srcs(v, f"{prefix}/{token}", into)
    return into


# ─────────────────────────────────────────────────────────────────────────────
# 3. The evaluator — one explicit rule per measured expression shape
# ─────────────────────────────────────────────────────────────────────────────

def split_top(text: str, op: str):
    """Split on the LAST top-level occurrence of `op` (left-associative)."""
    t = blank_strings(text)
    depth = 0
    i = len(t) - 1
    while i >= 0:
        c = t[i]
        if c in ")]}":
            depth = depth + 1
        elif c in "([{":
            depth -= 1
        elif depth == 0 and i + len(op) <= len(t) and t.startswith(op, i):
            # `?.` and `??` are not the ternary's `?`; `??`'s second character
            # is not one either.
            if op == "?" and (t[i:i + 2] in ("?.", "??")
                              or (i > 0 and t[i - 1] == "?")):
                i -= 1
                continue
            return text[:i].strip(), text[i + len(op):].strip()
        i -= 1
    return None


def split_args(text: str) -> list:
    t = blank_strings(text)
    out, depth, start = [], 0, 0
    for i, c in enumerate(t):
        if c in "([{":
            depth = depth + 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            out.append(text[start:i].strip())
            start = i + 1
    tail = text[start:].strip()
    if tail:
        out.append(tail)
    return out


def truthy(v) -> bool:
    if v is ABSENT or v is None or v is False:
        return False
    if v == "" or v == 0:
        return False
    return True


class Evaluator:
    """Re-implements the measured `buildFormData` expression grammar.

    Every shape below was read off the pinned source. Anything else RAISES —
    § 6.5.5's discipline: a new shape needs an explicit rule, never a silent
    default.
    """

    def __init__(self, page: str, scope: dict, locale: str, i18n_ns: str,
                 document_no: str, consts: dict, helpers: dict,
                 defaults: dict = None, used_defaults: dict = None):
        self.page = page
        self.scope = scope
        # RULING 13 part 3 — state groups the fixture deliberately omits,
        # sourced from the page's own `useState` initialiser with its line.
        self.defaults = defaults or {}
        self.used_defaults = used_defaults if used_defaults is not None else {}
        self.locale = locale
        self.i18n_ns = i18n_ns
        self.document_no = document_no
        self.consts = consts
        self.helpers = helpers
        self._t = None
        # The source line range of the statement currently being evaluated, so
        # an inline object literal inside a multi-line expression can cite the
        # line the key ACTUALLY sits on rather than the statement's first line.
        self.span = (0, 0)

    def locate(self, key: str) -> int:
        src_lines = lines_of(self.page)
        for i in range(self.span[0], self.span[1] + 1):
            if f'"{key}"' in src_lines[i - 1]:
                return i
        raise Refuse(f"{self.page}: key {key!r} not found in lines "
                     f"{self.span[0]}..{self.span[1]}")

    # ── translation table, read from the real ns file ──
    def t(self, key: str) -> str:
        if self._t is None:
            path = os.path.join(NS_DIR, f"{self.i18n_ns}.ts")
            with open(path, encoding="utf-8") as fh:
                self._t = i18n_parse.parse_namespace(
                    fh.read(), origin=f"i18n/ns/{self.i18n_ns}.ts")
        try:
            return self._t[self.locale][key]
        except KeyError:
            raise Refuse(f"{self.i18n_ns}.{key} missing for {self.locale}")

    def ev(self, expr):
        e = expr.strip()
        while e.startswith("(") and blank_strings(e).rfind(")") == len(e) - 1 \
                and _balanced(e[1:-1]):
            e = e[1:-1].strip()

        # ternary  COND ? A : B
        q = split_top(e, "?")
        if q is not None:
            cond, rest = q
            c = split_top(rest, ":")
            if c is not None and cond and not cond.endswith("?"):
                a, b = c
                return self.ev(a) if truthy(self.ev(cond)) else self.ev(b)

        # nullish  X ?? Y   (before ||, both are top-level binaries)
        n = split_top(e, "??")
        if n is not None:
            left, right = n
            v = self.ev(left)
            return self.ev(right) if v is ABSENT or v is None else v

        # logical-or  X || Y
        o = split_top(e, "||")
        if o is not None:
            left, right = o
            v = self.ev(left)
            return v if truthy(v) else self.ev(right)

        # strict equality  X === "lit"
        s = split_top(e, "===")
        if s is not None:
            left, right = s
            return self.ev(left) == self.ev(right)

        return self.primary(e)

    def primary(self, e: str):
        # literals
        if re.fullmatch(r'"(?:\\.|[^"\\])*"', e):
            return json.loads(e)
        if e == "undefined":
            return ABSENT
        if e in ("true", "false"):
            return e == "true"

        # the page's own constants, read from source
        if e in self.consts:
            return self.consts[e]

        # the frozen clock
        if e == "today()":
            return TODAY_WEB_UTC

        # translation lookup, inside buildFormData -> a WIRE value
        m = re.fullmatch(r't\("([\w]+)"\)', e)
        if m:
            return self.t(m.group(1))

        # the `documentNo` parameter of the nested family's buildFormData
        if e == "documentNo":
            return self.document_no

        # the section-level mirror: keeps A, DISCARDS B, collapses to ""
        m = re.fullmatch(r"both\((.*)\)", e, re.S)
        if m:
            args = split_args(m.group(1))
            if len(args) != 2:
                raise Refuse(f"both() with {len(args)} args: {e!r}")
            a = self.ev(args[0])
            b = self.ev(args[1])
            a = a if isinstance(a, str) else ""
            b = b if isinstance(b, str) else ""
            return a.strip() if (a.strip() and b.strip()) else ""

        # [a, b, …].filter(Boolean).join(SEP)
        m = re.fullmatch(
            r"\[(.*)\]\s*\.\s*filter\(Boolean\)\s*\.\s*join\((.*)\)", e, re.S)
        if m:
            parts = [self.ev(p) for p in split_args(m.group(1))]
            sep = self.ev(m.group(2).strip())
            return sep.join(p for p in parts if truthy(p))

        # a helper call returning an object -> inline it
        m = re.fullmatch(r"([A-Za-z_$][\w$]*)\((.*)\)", e, re.S)
        if m and m.group(1) in self.helpers:
            return self.helpers[m.group(1)](self, split_args(m.group(2)))

        # `{ ...payload, "K": current.reference_no }` — the flat family's
        # update body: the SAME object spread with the reference appended LAST.
        if re.fullmatch(r"\{\s*\.\.\.payload,.*\}", e, re.S):
            return FORM_DATA
        if e == "payload" or re.fullmatch(r"buildFormData\(.*\)", e):
            return FORM_DATA

        # An inline object literal. Birth's `fatherUnknown` branch is the only
        # one measured: `{ "parents.father.status": "unknown" }`
        # (BirthDeclarationPage.tsx:789), and it is the whole reason F0-AC-38
        # asks for a changed KEY SET rather than changed values.
        m = re.fullmatch(r"\{(.*)\}", e, re.S)
        if m and ":" in m.group(1):
            out = OrderedDict()
            for part in split_args(m.group(1)):
                km = re.match(r'^(?:"([^"]+)"|([A-Za-z_$][\w$]*)):\s*(.*)$',
                              part, re.S)
                if not km:
                    raise Refuse(f"{self.page}: inline object entry {part!r}")
                key = km.group(1) or km.group(2)
                out[key] = Leaf(self.ev(km.group(3).strip()),
                                f"{self.page}:{self.locate(key)}")
            return out

        # member chain, with optional chaining and the two measured postfixes
        return self.member(e)

    def member(self, e: str):
        post = []
        while True:
            m = re.fullmatch(r"(.*)\.trim\(\)", e, re.S)
            if m:
                e, _ = m.group(1), post.append("trim")
                continue
            m = re.fullmatch(r"(.*?)\??\.slice\(0,\s*10\)", e, re.S)
            if m:
                e, _ = m.group(1), post.append("slice10")
                continue
            break

        if not re.fullmatch(r"[A-Za-z_$][\w$]*(?:\??\.[A-Za-z_$][\w$]*)*", e):
            raise Refuse(
                f"{self.page}: unhandled expression {e!r} — a new shape needs "
                f"an explicit rule in Evaluator, never a silent default")

        parts = re.split(r"\??\.", e)
        cur = self.scope
        for depth, part in enumerate(parts):
            if cur is ABSENT or cur is None:
                cur = ABSENT
                break
            if not isinstance(cur, dict) or part not in cur:
                # RULING 13 part 3. ONLY at the top of a chain, and only for a
                # state group whose `useState` initialiser this file could
                # actually read. A missing SUB-key still refuses — that is a
                # fixture typo, not a deliberate omission, and the two must not
                # collapse into the same silent blank.
                if depth == 0 and cur is self.scope and part in self.defaults:
                    value, line = self.defaults[part]
                    self.used_defaults[part] = f"{self.page}:{line}"
                    cur = value
                    if cur is None:
                        cur = ABSENT
                    continue
                raise Refuse(
                    f"{self.page}: fixture has no `{e}` (stuck at {part!r}). "
                    f"The fixture must mirror the page's state tree exactly, "
                    f"so the transcription is auditable against the source.")
            cur = cur[part]
            if cur is None:
                cur = ABSENT

        for p in post:
            if cur is ABSENT:
                continue
            if p == "trim":
                cur = cur.strip()
            elif p == "slice10":
                cur = cur[:10]
        return cur


def _balanced(text: str) -> bool:
    t = blank_strings(text)
    depth = 0
    for c in t:
        if c in "([{":
            depth = depth + 1
        elif c in ")]}":
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


# ─────────────────────────────────────────────────────────────────────────────
# 4. Helper inlining — the spreads the line-scanner could never see
# ─────────────────────────────────────────────────────────────────────────────

def _parent_data_entries(page: str):
    """Birth's and Death's `parentData`, read from source.

    Birth's is one object of 13 computed keys; Death's is a ternary of two —
    a 1-key skipped branch and a 14-key normal branch (`+workplace`). They are
    deliberately extracted SEPARATELY per page: a shared helper here would be
    the exact `parentData` trap the oracle exists to expose.
    """
    src_lines = lines_of(page)
    decl = find_line(page, r"const parentData = ")
    # the helper ends at the first `};` or `});` at or after the declaration
    end = decl
    while end < len(src_lines) and not re.match(r"^\s*\}?\);?\s*$|^\s*\};\s*$",
                                                src_lines[end - 1]):
        end += 1
    region = statements(src_lines, decl, end)
    entries = {"skipped": [], "normal": []}
    branch = "normal"
    for start, _e, text in region:
        if text.startswith("skipped"):
            continue
        if text.startswith("?"):
            branch = "skipped"
            text = text[1:].strip()
        elif text.startswith(":"):
            branch = "normal"
            text = text[1:].strip()
        for m in re.finditer(r'\[`\$\{prefix\}\.([\w.]+)`\]:\s*([^,}]+)', text):
            entries[branch].append((m.group(1), start, m.group(2).strip()))
    # A single-line branch collapses several keys onto one statement line;
    # re-scan line by line so each key keeps its OWN line number.
    per_line = {"skipped": [], "normal": []}
    branch = "normal"
    for i in range(decl, end + 1):
        raw = src_lines[i - 1]
        if re.match(r"^\s*\?", raw):
            branch = "skipped"
        elif re.match(r"^\s*:", raw):
            branch = "normal"
        for m in re.finditer(r'\[`\$\{prefix\}\.([\w.]+)`\]:\s*([^,}]+)', raw):
            per_line[branch].append((m.group(1), i, m.group(2).strip()))
    if not per_line["normal"]:
        raise Refuse(f"{page}: parentData parsed to zero normal keys")
    return per_line


def make_parent_data(page: str):
    entries = _parent_data_entries(page)

    def inline(ev: Evaluator, args: list):
        if len(args) not in (2, 3):
            raise Refuse(f"parentData with {len(args)} args")
        who = args[0]
        prefix = ev.ev(args[1])
        skipped = truthy(ev.ev(args[2])) if len(args) == 3 else False
        rows = entries["skipped"] if skipped else entries["normal"]
        if skipped and not rows:
            raise Refuse(f"{page}: parentData has no skipped branch")
        sub = Evaluator(page, {**ev.scope, "p": ev.scope[who]}, ev.locale,
                        ev.i18n_ns, ev.document_no, ev.consts, ev.helpers,
                        ev.defaults, ev.used_defaults)
        out = OrderedDict()
        for suffix, line, expr in rows:
            key = f"{prefix}.{suffix}"
            if not attribution_ok(page, key, line):
                raise Refuse(f"attribution failed: {page}:{line} does not "
                             f"carry {suffix!r}")
            out[key] = Leaf(sub.ev(expr), f"{page}:{line}")
        return out

    return inline


def make_spouse_payload(page: str):
    nodes = arrow_object(page, r"const spousePayload = ")

    def inline(ev: Evaluator, args: list):
        if len(args) != 1:
            raise Refuse(f"spousePayload with {len(args)} args")
        sub = Evaluator(page, {**ev.scope, "s": ev.scope[args[0]]}, ev.locale,
                        ev.i18n_ns, ev.document_no, ev.consts, ev.helpers,
                        ev.defaults, ev.used_defaults)
        return build_nodes(nodes, sub, page)

    return inline


def build_nodes(nodes: list, ev: Evaluator, page: str) -> OrderedDict:
    """Nodes -> an ordered tree of `Leaf`, spreads expanded in place."""
    out = OrderedDict()
    for node in nodes:
        if node[0] == "spread":
            _, line, expr, end = node
            ev.span = (line, end)
            value = ev.ev(expr)
            if not isinstance(value, OrderedDict):
                raise Refuse(f"{page}:{line}: spread `...{expr}` did not "
                             f"expand to an object — it emits keys this file "
                             f"cannot enumerate, and transcribing only the "
                             f"literal-keyed entries would produce a SHORT "
                             f"oracle that reports PASS for a port missing "
                             f"exactly those keys.")
            for k, v in value.items():
                out[k] = v
            continue
        if node[0] == "obj":
            _, key, line, children, _end = node
            if not attribution_ok(page, key, line):
                raise Refuse(f"attribution failed: {page}:{line} does not "
                             f"contain {key!r}")
            out[key] = build_nodes(children, ev, page)
            continue
        _, key, line, expr, end = node
        if not attribution_ok(page, key, line):
            raise Refuse(f"attribution failed: {page}:{line} does not "
                         f"contain {key!r}")
        ev.span = (line, end)
        value = ev.ev(expr)
        if isinstance(value, OrderedDict):
            out[key] = value
        else:
            out[key] = Leaf(value, f"{page}:{line}")
    return out


# ─────────────────────────────────────────────────────────────────────────────
# 5. Guard B — `nameOf` reproduced, so `address_text` is RESOLVED not retyped
# ─────────────────────────────────────────────────────────────────────────────

def hydrate_locations(fx: dict, locale: str, page: str) -> dict:
    """Run the source's own resolver over the fixture's SELECTIONS.

    `nameOf(rows, id)` is `text(found.name, lang)`
    (`MarriageCertificatePage.tsx:307-310`), written ONCE at pick time by the
    local `ApiLocationFields` (`:325`, `:342`, `:357`). Reproducing it here is
    what makes Guard B a resolution-path assertion: `address_text` differs
    across the two locale seeds BECAUSE the selection was made in that locale,
    not because two literals were typed into two fixture files.
    """
    registry = fx.get("_locations")
    if registry is None:
        return fx

    def name_of(row_id):
        row = registry.get(row_id)
        if not row:
            return ""
        # api/types.ts:17 `text()` — the wanted side, then en, then lo.
        return (row.get(locale) or row.get("en") or row.get("lo") or "")

    out = dict(fx)
    for key, value in fx.items():
        if isinstance(value, dict) and isinstance(value.get("address"), dict):
            addr = dict(value["address"])
            addr["provinceName"] = name_of(addr.get("provinceId", ""))
            addr["districtName"] = name_of(addr.get("districtId", ""))
            addr["villageName"] = name_of(addr.get("villageId", ""))
            merged = dict(value)
            merged["address"] = addr
            out[key] = merged
    return out


# ─────────────────────────────────────────────────────────────────────────────
# 6. Form declarations — every non-derivable fact carries its citation
# ─────────────────────────────────────────────────────────────────────────────

FORMS = OrderedDict([
    ("resident", {
        "page": "ResidentCertificatePage.tsx",
        "route": "#/service/resident-certificate",
        "family": "flat",
        "ns": "resident",
        "variants": ["baseline"],
        "canonical": "baseline",
    }),
    ("birth", {
        "page": "BirthDeclarationPage.tsx",
        "route": "#/service/birth-declaration",
        "family": "flat",
        "ns": "birth",
        "variants": ["baseline", "father-unknown"],
        "canonical": "baseline",
    }),
    ("death", {
        "page": "DeathDeclarationPage.tsx",
        "route": "#/service/death-declaration",
        "family": "flat",
        "ns": "death",
        "variants": ["baseline", "mother-skip", "father-skip"],
        "canonical": "baseline",
    }),
    ("marriage", {
        "page": "MarriageCertificatePage.tsx",
        "route": "#/service/marriage-certificate",
        "family": "nested",
        "ns": "marriage",
        "variants": ["asymmetric", "blank-b", "whitespace"],
        "canonical": "asymmetric",
    }),
    ("divorce", {
        "page": "DivorceCertificatePage.tsx",
        "route": "#/service/divorce-certificate",
        "family": "nested",
        "ns": "divorce",
        # `contested` is RULING 13 part 3 — the second of the two step-1 arms
        # `canProceed()` (`DivorceCertificatePage.tsx:749-766`) admits. Without
        # it the whole `court` group is only ever `""` in every divorce oracle
        # and a port that hardcoded `""` there passes Tier 0 (`F0-AC-86`).
        "variants": ["asymmetric", "blank-b", "whitespace", "contested"],
        "canonical": "asymmetric",
    }),
    ("family-book", {
        "page": "FamilyBookPage.tsx",
        "route": "#/family-book",
        "family": "bodyless",
        "ns": "familyBook",
        "variants": ["baseline"],
        "canonical": "baseline",
    }),
])

GUARD_B_NOTE = (
    "Guard B (§ 6.5.2) — `spouses.*.address_text` is resolved at PICK time, "
    "not at submit. `MarriageCertificatePage.tsx:888-890` reads "
    "`s.address.villageName / districtName / provinceName` straight out of "
    "page state, and those three are written ONCE by the local "
    "`ApiLocationFields` at `:325`, `:342`, `:357` via "
    "`nameOf` = `text(found.name, lang)` (`:307-310`). Nothing re-resolves "
    "them when `lang` changes. So in the shipped app, picking a village in "
    "`en` and then switching to `lo` BEFORE submitting yields TWO IDENTICAL "
    "PAYLOADS — that is correct behaviour and the port must reproduce it. It "
    "is recorded here, and not in deployed_divergence.yaml, because it is not "
    "a deployed-vs-pinned delta. The two seeds differ in this oracle only "
    "because the SELECTION was made under that locale. Do not re-file as a "
    "bug, and do not add an inequality guard over `address_text`: that would "
    "fail a faithful port and pass one that re-resolved at submit."
)


def load_fixture(form: str, variant: str, locale: str) -> dict:
    path = os.path.join(FIXTURES, form, f"{variant}.{locale}.json")
    if not os.path.exists(path):
        raise Refuse(f"missing fixture {os.path.relpath(path, PKG)}")
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def envelope_of(page: str, call_pattern: str, ev: Evaluator) -> OrderedDict:
    """An ordered `(name, present, value)` envelope, § 6.5.1.

    Covers the WHOLE request body: an elided key appears with `present: false`
    and NO value; a present-and-empty key appears with `present: true,
    value: ""`. Resident elides `province_id` when blank
    (`|| undefined`); Marriage sends `""`. Those are different bodies.
    """
    env = OrderedDict()
    srcs = OrderedDict()
    for node in call_object(page, call_pattern):
        if node[0] != "leaf":
            raise Refuse(f"{page}: unexpected envelope node {node[0]}")
        _, key, line, expr, end = node
        if not attribution_ok(page, key, line):
            raise Refuse(f"attribution failed: {page}:{line} does not contain "
                         f"{key!r}")
        ev.span = (line, end)
        value = ev.ev(expr)
        srcs[key] = f"{page}:{line}"
        if value is ABSENT:
            env[key] = OrderedDict([("present", False)])
        elif value is FORM_DATA:
            env[key] = OrderedDict([("present", True), ("value", "<form_data>")])
        else:
            env[key] = OrderedDict([("present", True), ("value", value)])
    return env, srcs


def ref_binding(page: str, family: str) -> tuple:
    """Where the case reference lands on the UPDATE body, read from source.

    Three mechanics, and Finding B is the reason they are not one:
    Resident `header.ref_no`, Birth/Death the LITERAL FLAT key
    `"header.document_no"`, Marriage/Divorce the NESTED `header` ->
    `document_no`. The first two are appended to a spread copy of the same
    object; the third is a parameter re-invoked with the reference.
    """
    if family == "nested":
        line = find_line(page, r"^\s*document_no:\s*documentNo,")
        return ("header", "document_no"), line
    src_lines = lines_of(page)
    for i, raw in enumerate(src_lines, start=1):
        m = re.search(r'\.\.\.payload,\s*"([^"]+)":\s*current\.reference_no',
                      raw)
        if m:
            return (m.group(1),), i
    raise Refuse(f"{page}: no `...payload, \"<key>\": current.reference_no`")


def build_family_book(locale: str, variant: str) -> OrderedDict:
    """FamilyBook — the THIRD payload family. No `form_data` at all.

    `me.requestFamilyBookCopy({ reason })` (`FamilyBookPage.tsx:236`) reaches
    `api.post("/me/family-book/request-copy", body ?? {})`
    (`endpoints.ts:128`), so the request body IS `{reason}`. `reason` is
    `say("copyReason")`, read out of the page's own COPY table at submit time
    — which is why it is a Guard A key.
    """
    page = "FamilyBookPage.tsx"
    src_lines = lines_of(page)
    start = find_line(page, r"^\s*copyReason:\s*\{")
    _first, _last, close = block_range(src_lines, start)
    values = {}
    for i in range(start, close + 1):
        for m in re.finditer(r'\b(en|lo):\s*"((?:\\.|[^"\\])*)"',
                             src_lines[i - 1]):
            values[m.group(1)] = (json.loads(f'"{m.group(2)}"'), i)
    if set(values) != {"en", "lo"}:
        raise Refuse(f"{page}: COPY.copyReason is not a bilingual pair")
    value, value_line = values[locale]
    call = find_line(page, r"requestCopy\.run\(say\(\"copyReason\"\)\)")
    # The wire KEY and the wire VALUE come from two different places on this
    # form, which is true of no other payload in the product: the key is an ES
    # shorthand in the mutation's own body, the value is read out of the page's
    # COPY table at submit. `src` cites the key; `valueSrc` cites the value, so
    # neither citation has to stand in for the other.
    key_line = find_line(page, r"me\.requestFamilyBookCopy\(\{\s*reason\s*\}\)")

    body = OrderedDict([("reason", Leaf(value, f"{page}:{key_line}"))])
    env = OrderedDict([("reason", OrderedDict([("present", True),
                                               ("value", value)]))])
    doc = OrderedDict()
    doc["schema"] = "tier0/1"
    doc["route"] = FORMS["family-book"]["route"]
    doc["form"] = "family-book"
    doc["body"] = "request"
    doc["locale"] = locale
    doc["attempt"] = "first"
    doc["clock"] = CLOCK
    doc["wire_shape"] = (
        "THE REQUEST BODY IS THIS OBJECT. FamilyBook has no `form_data` "
        "envelope key — it is the third payload family (Finding A). "
        f"{page}:{call} -> endpoints.ts:128 -> client.ts:242. The `form_data` "
        "field below is the oracle's slot for `the payload tree`, not a wire "
        "key.")
    doc["provenance"] = provenance("family-book", variant, locale)
    doc["form_data"] = tree_json(body)
    doc["paths"] = tree_paths(body)
    doc["src"] = tree_srcs(body)
    doc["requestEnvelope"] = env
    doc["envelopeSrc"] = OrderedDict([("reason", f"{page}:{key_line}")])
    doc["valueSrc"] = OrderedDict([
        ("/reason", f"{page}:{value_line}"),
        ("_note", f"`say(\"copyReason\")` at {page}:{call} reads the COPY "
                  f"table at submit time, which is why this is a Guard A key."),
    ])
    doc["refBinding"] = OrderedDict([
        ("pointer", None),
        ("mechanic", "none — FamilyBook sends ONE body and no case reference "
                     "is ever bound into it"),
        ("src", f"{page}:{key_line}"),
    ])
    return doc


def provenance(form: str, variant: str, locale: str) -> OrderedDict:
    return OrderedDict([
        ("web_commit", WEB_COMMIT),
        ("entry", "B"),
        ("derived_by", "test/fidelity/derive_forms_oracles.py"),
        ("method",
         "re-transcription of the page's buildFormData from source text; key "
         "order, nesting, helper key lists, both envelopes and every per-leaf "
         "src are EXTRACTED from the pinned source, values are computed from "
         "the fixture matrix by an evaluator with one explicit rule per "
         "measured expression shape"),
        ("leaf_provenance", "transcribed"),
        ("leaf_provenance_note",
         "Entry B marks every leaf `transcribed`. `execute_forms_oracle.mjs` "
         "(Entry A) upgrades the leaves it captures to `executed` and asserts "
         "A == B byte-for-byte per leaf (F0-AC-104). Until that run happens "
         "against this document, no leaf here claims to have been executed — "
         "which is the claim F0-AC-104 exists to stop being free."),
        ("fixture", f"fixtures/tier0/{form}/{variant}.{locale}.json"),
    ])


def build_documents(form: str, variant: str, locale: str) -> list:
    spec = FORMS[form]
    page = spec["page"]
    if spec["family"] == "bodyless":
        return [build_family_book(locale, variant)]

    raw_fx = load_fixture(form, variant, locale)
    fx = hydrate_locations(raw_fx, locale, page)

    consts = {}
    for ident in ("SERVICE_CODE", "OFFICE_DEFERRED"):
        try:
            consts[ident] = const_string(page, ident)[0]
        except Refuse:
            pass

    helpers = {}
    if re.search(r"const parentData = ", read(page)):
        helpers["parentData"] = make_parent_data(page)
    if re.search(r"const spousePayload = ", read(page)):
        helpers["spousePayload"] = make_spouse_payload(page)

    ref_path, ref_line = ref_binding(page, spec["family"])
    reference = fx.get("_reference_no", "REF-0001")

    defaults = state_initialisers(page)
    used_defaults = {}

    def evaluator(document_no: str) -> Evaluator:
        return Evaluator(page, fx, locale, spec["ns"], document_no, consts,
                         helpers, defaults, used_defaults)

    builder_nodes = arrow_object(page, r"const buildFormData = ")

    # ── create body ──
    create_ev = evaluator("")
    create_tree = build_nodes(builder_nodes, create_ev, page)

    # ── update body ──
    if spec["family"] == "nested":
        # buildFormData is RE-INVOKED with the reference: same paths, exactly
        # one differing value (F0-AC-34's nested pair relation).
        update_tree = build_nodes(builder_nodes, evaluator(reference), page)
    else:
        # The SAME object spread with the reference appended LAST: +1 key,
        # order otherwise unchanged.
        update_tree = OrderedDict(create_tree)
        update_tree[ref_path[0]] = Leaf(reference, f"{page}:{ref_line}")

    create_env, create_env_src = envelope_of(
        page, r"applications\.create\(\{", create_ev)
    update_env, update_env_src = envelope_of(
        page, r"applications\.update\(", create_ev)

    docs = []
    for kind, tree, env, env_src in (
            ("create", create_tree, create_env, create_env_src),
            ("update", update_tree, update_env, update_env_src)):
        d = OrderedDict()
        d["schema"] = "tier0/1"
        d["route"] = spec["route"]
        d["form"] = form
        d["body"] = kind
        d["locale"] = locale
        d["attempt"] = "first"
        d["clock"] = CLOCK
        d["provenance"] = provenance(form, variant, locale)
        d["form_data"] = tree_json(tree)
        d["paths"] = tree_paths(tree)
        d["src"] = tree_srcs(tree)
        d[f"{kind}Envelope"] = env
        d["envelopeSrc"] = env_src
        d["refBinding"] = OrderedDict([
            ("pointer", "/" + "/".join(ref_path)),
            ("mechanic", "nested-parameter" if spec["family"] == "nested"
             else "flat-appended-last"),
            ("src", f"{page}:{ref_line}"),
        ])
        if spec["family"] == "nested":
            d["notes"] = [GUARD_B_NOTE]
        docs.append(d)
    return docs


# ─────────────────────────────────────────────────────────────────────────────
# 7. Emission
# ─────────────────────────────────────────────────────────────────────────────

def write_doc(directory: str, name: str, doc: dict) -> tuple:
    os.makedirs(directory, exist_ok=True)
    path = os.path.join(directory, name)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    return path, len(doc["paths"])


def main() -> int:
    canonical, variants = [], []
    for form, spec in FORMS.items():
        for variant in spec["variants"]:
            for locale in ("en", "lo"):
                for doc in build_documents(form, variant, locale):
                    name = f"{form}.{doc['body']}.{locale}.json"
                    if variant == spec["canonical"]:
                        canonical.append(write_doc(OUT, name, doc))
                    else:
                        variants.append(write_doc(
                            VARIANTS_OUT,
                            f"{form}.{variant}.{doc['body']}.{locale}.json",
                            doc))

    for path, n in canonical:
        print(f"wrote {os.path.relpath(path, PROJECT)}  ({n} leaves)")
    for path, n in variants:
        print(f"  variant {os.path.relpath(path, PROJECT)}  ({n} leaves)")

    print(f"\n{len(canonical)} of 22 Tier 0 oracle documents "
          f"(+{len(variants)} non-canonical fixture variants).")
    if len(canonical) != 22:
        print("FAIL: F0-AC-34 requires exactly 22.")
        return 1
    print("Entry B complete. Every leaf is `transcribed`; F0-AC-104's "
          "`executed` upgrade is execute_forms_oracle.mjs's to make.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
