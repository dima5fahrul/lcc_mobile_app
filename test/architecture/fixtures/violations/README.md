# Guard fixtures — the negative control for G-L1 … G-L5 and G-L7

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
2. every **other** guard reports **nothing** — a guard that fires on the wrong
   file is as broken as one that never fires.

| Tree   | Guard | The violation |
|--------|-------|---------------|
| `g_l1` | G-L1  | `presentation/widget.dart` imports `../data/model.dart` |
| `g_l2` | G-L2  | `domain/entity.dart` imports `../presentation/widget.dart` |
| `g_l3` | G-L3  | `features/a/di/x.dart` imports `../../b/data/y.dart` |
| `g_l4` | G-L4  | `core/thing.dart` imports `package:flutter/material.dart` |
| `g_l5` | G-L5  | `presentation/page.dart` imports `../di/auth_injection.dart` and names `authInjection` |
| `g_l7` | G-L7  | `presentation/shell/app_bar_fixture.dart` imports `../../features/notifications/presentation/bell.dart` |

There is no `g_l6`, and the gap is deliberate — see `layering_rules.dart`'s
library doc (B9-AC-9).

## `g_l7` is the one that landed before its defect could exist (B9a)

The other five were written after B2 had already put five features under rules
of unknown efficacy. `g_l7` is different: `ssd.md`:255 forbade
`lib/presentation/** → features/*/presentation/**` from the day the SSD landed
and **nothing enforced it** — G-L1 checks only the `data/` half, and G-L3 opens
with `if (file.feature == null) continue;`, which skips every file under
`lib/presentation/` by construction.

Measured at `f530d8e`: **zero** such edges in the tree. B9 is the first batch
whose design could create one, so the guard and this fixture land in B9a,
*before* the shell composes its first feature widget. A guard written after its
first consumer is a guard written to match it (specs.md § 6.5, § 8.1).

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
