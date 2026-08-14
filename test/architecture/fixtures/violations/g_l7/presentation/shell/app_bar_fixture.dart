// G-L7 fixture — THE VIOLATION. A file under `lib/presentation/**` importing a
// feature's `presentation/`.
//
// `ssd.md`:255: presentation may import `core/**`, `features/*/domain/**` and
// other `presentation/**`; it may NOT import `features/*/presentation/**`.
//
// The offender is a shell bar rather than, say, a theme file, because that is
// the real shape of the mistake: a shell widget that wants to render a feature
// widget needs the feature's BLoC type, and reaching for the import is the
// path of least resistance. specs.md § 6.4's composed-parameter seam is what
// makes it avoidable; this guard is what makes it noticed.
//
// It trips G-L7 and nothing else, by construction:
//   * G-L1 wants a `data/` target — this one is `presentation/`.
//   * G-L2 wants the importer under `domain/`.
//   * G-L3 skips it: `feature` is null for anything not under `features/`,
//     which is the exact hole G-L7 exists to fill.
//   * G-L4 wants the importer under `core/`.
//   * G-L5 wants a `di/` import or a locator identifier — neither is here.
import '../../features/notifications/presentation/bell.dart';

const FixtureBell fixtureBell = FixtureBell();
