// G-L1 fixture — the `data/` half. Nothing is wrong with this file; it exists
// so the offending import in `presentation/widget.dart` resolves to something
// real, which is what `scanTree()`'s relative-path resolution needs.
class FixtureModel {
  const FixtureModel();
}
