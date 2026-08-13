# Guard fixtures — the negative control for G-L1 … G-L5

specs.md § 6.7.7 / B2-AC-7.

`d22cd98`'s own commit message recorded the debt these trees close: *"NOT YET
PROVEN: the guards have not been observed failing when their rule is
violated."* `layering_test.dart` asserted its scanner found *files*; nothing
asserted that any of its five rules could fire.

Each directory below is a **complete, deliberately-broken scan root** holding
exactly one violation of exactly one guard. `guard_selftest_test.dart` points
`scanTree()` at each one and asserts:

1. the guard that owns it reports **exactly** that violation — the count and
   the cited `path:line -> uri`, not merely "non-empty"; and
2. the other four guards report **nothing** — a guard that fires on the wrong
   file is as broken as one that never fires.

| Tree   | Guard | The violation |
|--------|-------|---------------|
| `g_l1` | G-L1  | `presentation/widget.dart` imports `../data/model.dart` |
| `g_l2` | G-L2  | `domain/entity.dart` imports `../presentation/widget.dart` |
| `g_l3` | G-L3  | `features/a/di/x.dart` imports `../../b/data/y.dart` |
| `g_l4` | G-L4  | `core/thing.dart` imports `package:flutter/material.dart` |
| `g_l5` | G-L5  | `presentation/page.dart` imports `../di/auth_injection.dart` and names `authInjection` |

## Why these are real, compiling, analyzer-clean Dart

They are not string blobs fed to a parser in memory. `scanTree()` reads files
off disk, resolves relative imports against the importing file's own directory
and strips comments — three behaviours a synthetic in-memory fixture would
bypass, and all three are where a scanner breaks in practice. So the fixtures
are files, every import resolves to a file that exists, and every imported
symbol is used, which keeps `flutter analyze` at `No issues found!`.

## Why they cannot pollute the production scan

`scanTree()` is rooted at the directory it is handed, and the production run
hands it `lib`. These live under `test/`, are never imported by `lib/`, and are
not `*_test.dart` so the runner never executes them. The isolation is
structural, not a convention someone has to remember.

**Do not "fix" these files.** They are broken on purpose; a green fixture means
a vacuous guard.
