// G-L3 fixture — THE VIOLATION. Feature A imports feature B's `data/`.
//
// The offender sits in `di/` rather than `presentation/` or `domain/` on
// purpose: from either of those, the same import would ALSO break G-L1 or
// G-L2, and the self-test could not then tell "G-L3 fired" from "some guard
// fired". Cross-Feature Isolation (SSD § 4.3) is the only rule this trips.
import '../../b/data/y.dart';

const FixtureRow fixtureRow = FixtureRow();
