/// **The planted ADR-0005 O-4 violation** — both halves, on one line each.
///
/// `DateTime.now().toUtc()` is the defect itself: `new Date().toISOString()`
/// is what dates every Lao submission made between 00:00 and 07:00 local
/// YESTERDAY. The file is under `features/planted/domain/`, which is inside
/// O-4's real scope (`lib/**`) and outside the one directory v1.0 narrowed it
/// to — so it also proves the widened scope is the reason the guard works.
library;

DateTime brokenNow() => DateTime.now().toUtc();

String brokenToday() => DateTime.now().toUtc().toIso8601String().substring(0, 10);
