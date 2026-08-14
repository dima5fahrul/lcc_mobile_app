/// **The planted G-L6 violation** — a `data/` file importing `presentation/`.
///
/// This is the exact edge `GOR-245-f0-form-kernel/specs.md` § 6.1.2 row 3
/// describes: B4's submission executor lives in `features/certificates/data/`,
/// and RULING 9's revoked placement would have had it importing
/// `lib/presentation/forms/submission/`. Before G-L6 no guard in the tree could
/// see it — G-L1 checks presentation→data, G-L2 checks only `domain/`, G-L4
/// only `core → features/*`, G-L7 only `lib/presentation → features/*/presentation`.
library;

import '../presentation/widget.dart';

const String usesWidget = widget;
