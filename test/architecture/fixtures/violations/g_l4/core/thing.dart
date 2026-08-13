// G-L4 fixture — THE VIOLATION. A `core/` file importing Flutter UI.
// SSD § 4.4 / § 4.5: core must stay importable without a widget tree.
import 'package:flutter/material.dart';

const Widget fixtureWidget = SizedBox.shrink();
