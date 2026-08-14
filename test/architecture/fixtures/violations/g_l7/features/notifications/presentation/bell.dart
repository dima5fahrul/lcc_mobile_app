// G-L7 fixture — the IMPORT TARGET, not the violation.
//
// A feature's own presentation widget. Deliberately importless: it has to be
// reachable without tripping a second guard, so that the self-test's
// "every other guard stays silent" assertion is measuring G-L7's precision
// rather than this file's tidiness.
class FixtureBell {
  const FixtureBell();
}
