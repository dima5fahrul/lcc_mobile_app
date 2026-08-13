// G-L5 fixture — the container. Named `authInjection` because the guard scans
// for that exact identifier, and filed under `di/` because the guard's other
// half scans for the import edge.
class FixtureLocator {
  const FixtureLocator();

  String call() => 'fixture';
}

const FixtureLocator authInjection = FixtureLocator();
