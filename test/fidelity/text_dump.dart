/// The widget-tree text dump Tier 1 compares against the oracle.
///
/// § 6.5.3: *"Tier 1 then runs as a **Dart test** comparing a Flutter
/// widget-tree text dump against that JSON, with no browser in the loop."*
/// This is that dump.
///
/// ## Order is the whole point
///
/// A set comparison would pass a page that renders every right string in the
/// wrong order — the description above the title, the fee above the name. So
/// the walk is a depth-first **pre-order** traversal of the element tree, which
/// for the `Column`/`Row` layouts this page is built from is reading order.
///
/// ## Three things it deliberately does
///
/// 1. **A `TextField` contributes exactly one node and its subtree is
///    skipped.** `InputDecorator` renders the hint as a real `Text` widget, so
///    descending would emit the placeholder twice — once from the field, once
///    from the decorator — and the duplicate would be indistinguishable from a
///    genuine double-render.
/// 2. **A field with a value emits its value, not its placeholder.** That is
///    what a citizen sees, and the web behaves the same way; an oracle that
///    expected the placeholder in a searched state would be describing a screen
///    nobody has.
/// 3. **`Text.rich` is flattened with `toPlainText()`.** The fee is one visual
///    string built from two spans; the web presents one string.
///
/// ## What it does not capture, and why that is fine
///
/// Colour, size, weight, position. Those are Tier 2's and Tier 3's. Tier 1 asks
/// one question — *is every element the web presents present here, with the
/// same text, in the same order, in both locales* — and answering more than
/// that would make it fail for reasons it is not the gate for.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One rendered text node.
class DumpNode {
  const DumpNode({required this.role, required this.text, this.heading = false});

  /// `text` · `input` · `placeholder`. Coarser than the oracle's roles on
  /// purpose — see [rolesAreComparable].
  final String role;

  final String text;

  /// True when an ancestor `Semantics` declares `header: true`.
  final bool heading;

  @override
  String toString() => heading ? '[h] $text' : text;
}

/// Depth-first pre-order text dump of the subtree under [root].
List<DumpNode> dumpText(WidgetTester tester, Finder root) {
  final List<DumpNode> nodes = <DumpNode>[];

  void visit(Element element, bool underHeader) {
    final Widget widget = element.widget;

    if (widget is Semantics) {
      underHeader = underHeader || (widget.properties.header ?? false);
    }

    if (widget is TextField) {
      final String value = widget.controller?.text ?? '';
      if (value.isNotEmpty) {
        nodes.add(DumpNode(role: 'input', text: value));
      } else {
        final String? hint = widget.decoration?.hintText;
        if (hint != null && hint.isNotEmpty) {
          nodes.add(DumpNode(role: 'placeholder', text: hint));
        }
      }
      // Skip the subtree — see note 1 in the library doc.
      return;
    }

    if (widget is Text) {
      final String text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
      if (text.isNotEmpty) {
        nodes.add(DumpNode(role: 'text', text: text, heading: underHeader));
      }
    }

    element.visitChildren((Element child) => visit(child, underHeader));
  }

  visit(tester.element(root), false);
  return nodes;
}

/// Whether an oracle role and a dump role describe the same kind of node.
///
/// The oracle distinguishes eleven roles (`cardTitle`, `panelHint`, `chip`, …)
/// because it is derived from markup that has them; a Flutter tree has three
/// kinds of text node. Rather than pretend the dump can tell a `cardMeta` from
/// a `chip`, the comparison collapses the oracle's roles into the dump's — and
/// keeps the two roles that ARE distinguishable, because those are the two
/// where a mistake is invisible in a plain text diff:
///
/// * `placeholder` — hint text vs. a real label. Rendering the placeholder as a
///   permanent label would read identically in a text dump.
/// * `input` — the citizen's own typed text vs. copy.
bool rolesAreComparable(String oracleRole, String dumpRole) {
  switch (oracleRole) {
    case 'placeholder':
      return dumpRole == 'placeholder';
    case 'input':
      return dumpRole == 'input';
    default:
      return dumpRole == 'text';
  }
}
