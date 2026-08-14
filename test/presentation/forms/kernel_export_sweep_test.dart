/// `F0-AC-96` — the 23 kernel exports are **EXERCISED, not merely declared**.
///
/// ## The shape this file closes
///
/// `F0-AC-21` maps all 23 exports of `formFields.tsx` + `formValidation.tsx` to
/// a named Dart home with its reason, and `kernel_export_map.json` is that map.
/// v1.0's `AC-24` was satisfied by exactly that much — *"exists / enumerated in
/// `qa-report.md`"* — which left **all eleven** `formValidation.tsx` exports and
/// nine of `formFields.tsx`'s with no behavioural assertion anywhere.
///
/// A JSON file that nothing reads is not evidence. Until this test landed,
/// `kernel_export_map.json` had **no reader at all**: `grep -rln
/// kernel_export_map test/ lib/` returned nothing, so the map could have named
/// a symbol that did not exist, at a file that did not exist, and every gate
/// would still have been green.
///
/// ## What it asserts, in two halves
///
/// **1. The map resolves against disk** (runs always). Every row's `dart_file`
/// exists and its `dart_symbol` is really declared there. This is what catches
/// a map gone stale against a kernel that moved, and it needs no coverage run.
///
/// **2. The lcov sweep** (runs when `coverage/lcov.info` is present). Every
/// symbol's declaring line range carries at least one covered line, and the
/// test FAILS **naming** any symbol whose range is entirely unhit.
///
/// The declaring RANGE is derived here rather than recorded in the JSON, so the
/// map cannot go stale against a line the kernel moves: locate the declaration,
/// then scan forward to the next top-level declaration.
///
/// ## Why the sweep is conditional and why that is not a silent skip
///
/// `coverage/lcov.info` exists only after `flutter test --coverage`, which
/// `F0-AC-4` requires the batch to run anyway. Making the sweep unconditional
/// would fail every plain `flutter test` and break `F0-AC-3`; using `skip:`
/// would report a fourth gate status this spec forbids (§ 7 preamble). So the
/// sweep is conditional on the artefact — and when it is absent the test says
/// so **out loud** and half 1 still asserts, rather than passing on nothing.
/// `qa-report.md` records the sweep's result from the coverage run, not from
/// this file's default-mode exit code.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One row of `kernel_export_map.json`.
class _Export {
  _Export(Map<String, dynamic> row)
      : n = row['n'] as int,
        symbol = row['symbol'] as String,
        src = row['src'] as String,
        exported = row['exported'] as bool,
        dartFile = row['dart_file'] as String?,
        dartSymbol = row['dart_symbol'] as String?,
        reason = row['reason'] as String;

  final int n;
  final String symbol;
  final String src;
  final bool exported;
  final String? dartFile;
  final String? dartSymbol;
  final String reason;
}

bool _isDocComment(String line) {
  final String t = line.trimLeft();
  return t.startsWith('//') || t.startsWith('/*') || t.startsWith('*');
}

int _indent(String line) => line.length - line.trimLeft().length;

/// True when [line] opens a declaration at [indent] — a class, a member, or a
/// top-level function/variable. Continuations, closing braces and comments do
/// not.
bool _opensDeclaration(String line, int indent) {
  final String t = line.trimLeft();
  if (t.isEmpty || _isDocComment(t)) return false;
  if (_indent(line) != indent) return false;
  final String first = t[0];
  if (first == '}' || first == ')' || first == ']' || first == ',') {
    return false;
  }
  return true;
}

/// The `[start, end]` 1-based line range declaring [symbol] in [source].
///
/// Handles **both** top-level declarations and class members: five of the
/// mapped symbols (`showErrorsOf`, `serverErrorsOf`, `serverErrorOf`,
/// `clearServerErrorOf`, `fieldErrorOf`) are `static` members of
/// `ValidationScope`, not top-level functions, and a top-level-only scan
/// reports all five as missing.
///
/// Distinguishing a declaration from a CALL SITE is the other half:
/// `validation_scope.dart:132` reads `… = serverErrorOf(context, path);` and
/// `:137` calls `showErrorsOf(context)`. Both mention the symbol; neither
/// declares it. A declaration head is required — the symbol preceded by a type
/// or modifier, or by `class`/`enum`/`mixin`/`extension`/`typedef` — and any
/// line whose symbol occurrence is preceded by `=`, `return`, `.` or `(` is
/// rejected.
///
/// Returns null when no declaration is found, which the caller reports by name
/// rather than treating as an empty range that would sweep clean.
List<int>? _declarationRange(List<String> source, String symbol) {
  final String s = RegExp.escape(symbol);
  final RegExp typeDecl = RegExp('^(?:class|enum|mixin|extension|typedef)\\s+$s'
      r'(?:[^A-Za-z0-9_$]|$)');
  // <modifiers/type…> symbol( | = | ; | =>
  final RegExp memberDecl = RegExp(
      r'^(?:@\w+\s+)*'
      r'(?:(?:static|final|const|late|abstract|external|covariant)\s+)*'
      // the type, which may itself be a function type —
      // `void Function(String? path) clearServerErrorOf(…)` is one of the five
      r'(?:[\w$<>,\s?\[\]\.()]+?\s+)?'
      '$s'
      r'\s*(?:\(|=[^=]|;|=>|<)');
  // the symbol appearing as a call or a reference, never a declaration
  final RegExp usage = RegExp(r'(?:[=.]\s*|return\s+|\(\s*)'
      '$s'
      r'\s*\(');

  int? start;
  int indent = 0;
  for (int i = 0; i < source.length; i++) {
    final String line = source[i];
    final String t = line.trimLeft();
    if (t.isEmpty || _isDocComment(t)) continue;
    if (t.startsWith('import ') ||
        t.startsWith('export ') ||
        t.startsWith('part ') ||
        t.startsWith('library')) {
      continue;
    }
    if (usage.hasMatch(line)) continue;
    if (typeDecl.hasMatch(t) || memberDecl.hasMatch(t)) {
      start = i + 1;
      indent = _indent(line);
      break;
    }
  }
  if (start == null) return null;

  // Runs to the next declaration at the SAME indentation (a sibling), or to
  // the end of the enclosing block — whichever comes first.
  int end = source.length;
  for (int i = start; i < source.length; i++) {
    final String line = source[i];
    if (line.trimLeft().isEmpty) continue;
    final bool sibling = _opensDeclaration(line, indent);
    final bool blockEnd = _indent(line) < indent && line.trimLeft().startsWith('}');
    if (!sibling && !blockEnd) continue;
    int boundary = i;
    while (boundary > start && _isDocComment(source[boundary - 1])) {
      boundary--;
    }
    end = boundary;
    break;
  }
  return <int>[start, end];
}

/// `lib/…​.dart` → {line: hits}, parsed from an lcov tracefile.
Map<String, Map<int, int>> _parseLcov(String text) {
  final Map<String, Map<int, int>> out = <String, Map<int, int>>{};
  String? file;
  for (final String line in const LineSplitter().convert(text)) {
    if (line.startsWith('SF:')) {
      file = line.substring(3).trim();
      // Flutter emits absolute or package-root-relative paths; normalise.
      final int lib = file.indexOf('lib/');
      if (lib > 0) file = file.substring(lib);
      out.putIfAbsent(file, () => <int, int>{});
    } else if (line.startsWith('DA:') && file != null) {
      final List<String> parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final int? n = int.tryParse(parts[0]);
        final int? hits = int.tryParse(parts[1]);
        if (n != null && hits != null) {
          out[file]![n] = (out[file]![n] ?? 0) + hits;
        }
      }
    } else if (line == 'end_of_record') {
      file = null;
    }
  }
  return out;
}

void main() {
  late final Map<String, dynamic> map;
  late final List<_Export> exports;

  setUpAll(() {
    final File f = File('test/presentation/forms/kernel_export_map.json');
    expect(f.existsSync(), isTrue,
        reason: 'kernel_export_map.json is the subject of F0-AC-96; without '
            'it this whole file would pass by having nothing to check');
    map = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    exports = (map['exports'] as List<dynamic>)
        .map((dynamic e) => _Export(e as Map<String, dynamic>))
        .toList();
  });

  group('the map itself (F0-AC-21)', () {
    test('the denominator is the source\'s, and it is 23', () {
      final Map<String, dynamic> d =
          map['denominator'] as Map<String, dynamic>;
      // Measured: `grep -c '^export ' formFields.tsx` -> 12,
      //           `grep -c '^export ' formValidation.tsx` -> 11.
      expect(d['formFields.tsx'], 12);
      expect(d['formValidation.tsx'], 11);
      expect(d['total'], 23);
      expect(exports.where((_Export e) => e.exported).length, 23,
          reason: 'every one of the 23 source exports has a row');
    });

    test('LoadFailure is carried but NOT counted — it is private', () {
      final Iterable<_Export> private =
          exports.where((_Export e) => !e.exported);
      expect(private.map((_Export e) => e.symbol), <String>['LoadFailure'],
          reason: 'formFields.tsx:53 declares it without `export`. It is '
              'recorded because § 6.3.7 gives it row 9 and F0-AC-25/26 assert '
              'its presence and its absence — but counting it would make the '
              'denominator disagree with the source.');
      expect(exports.length, 24);
    });

    test('every row carries a reason and a source line', () {
      for (final _Export e in exports) {
        expect(e.reason, isNotEmpty, reason: '${e.symbol} has no reason');
        expect(e.src, matches(RegExp(r'^form(Fields|Validation)\.tsx:\d+$')),
            reason: '${e.symbol}: `${e.src}` is not a form `file:line`');
      }
    });

    test('exactly one symbol is unported, and it is ReferenceSelect', () {
      // The gate shrinks by one for each `dart_file: null`, so the set is
      // asserted by name rather than by count alone.
      final Iterable<String> unported = exports
          .where((_Export e) => e.dartFile == null)
          .map((_Export e) => e.symbol);
      expect(unported, <String>['ReferenceSelect'],
          reason: 'ReferenceSelect needs a GetLookupOptions no widget may '
              'resolve (ssd.md:511, G-L5), so its composition happens where '
              'the state lives. Any OTHER null here is a symbol that quietly '
              'left the sweep.');
      expect(exports.where((_Export e) => e.dartFile != null).length, 23,
          reason: "the sweep's denominator");
    });
  });

  group('the map resolves against disk', () {
    test('every dart_file exists and declares its dart_symbol', () {
      final List<String> broken = <String>[];

      for (final _Export e in exports) {
        final String? path = e.dartFile;
        if (path == null) continue;

        final File f = File(path);
        if (!f.existsSync()) {
          broken.add('${e.symbol}: $path does not exist');
          continue;
        }
        final List<String> source = f.readAsLinesSync();
        final List<int>? range = _declarationRange(source, e.dartSymbol!);
        if (range == null) {
          broken.add(
              '${e.symbol}: `${e.dartSymbol}` is not declared in $path');
        }
      }

      expect(broken, isEmpty,
          reason: 'the export map has gone stale against the kernel.\n  '
              '${broken.join('\n  ')}');
    });
  });

  group('the lcov sweep (F0-AC-96)', () {
    test('no mapped symbol has an entirely unhit declaring range', () {
      final File lcov = File('coverage/lcov.info');

      if (!lcov.existsSync()) {
        // Not a skip and not a pass on nothing: the resolution half above has
        // already asserted, and this states plainly what was not evaluated.
        printOnFailure('');
        // ignore: avoid_print
        print(
          'F0-AC-96 lcov sweep: NOT EVALUATED — coverage/lcov.info absent. '
          'Run `flutter test --coverage` (F0-AC-4 requires it anyway) and '
          'record the result in qa-report.md. The map-resolves-against-disk '
          'half of this file ran and asserted.',
        );
        return;
      }

      final Map<String, Map<int, int>> coverage =
          _parseLcov(lcov.readAsStringSync());
      final List<String> unhit = <String>[];
      final List<String> unmeasurable = <String>[];
      int swept = 0;

      for (final _Export e in exports) {
        final String? path = e.dartFile;
        if (path == null) continue;

        final List<int>? range =
            _declarationRange(File(path).readAsLinesSync(), e.dartSymbol!);
        if (range == null) {
          unmeasurable.add(
              '${e.symbol}: `${e.dartSymbol}` is not declared in $path — '
              'the resolution test above names this too');
          continue;
        }
        final Map<int, int>? lines = coverage[path];
        if (lines == null) {
          unmeasurable.add('${e.symbol}: $path has no record in lcov.info');
          continue;
        }

        final Iterable<MapEntry<int, int>> inRange = lines.entries.where(
            (MapEntry<int, int> d) =>
                d.key >= range[0] && d.key <= range[1]);

        if (inRange.isEmpty) {
          // No executable line in the range — a `const`-only declaration. It
          // cannot be swept, so it is reported rather than counted as covered.
          unmeasurable.add(
            '${e.symbol} (${e.dartSymbol} @ $path:${range[0]}-${range[1]}): '
            'no executable line — nothing for lcov to record',
          );
          continue;
        }

        swept++;
        if (!inRange.any((MapEntry<int, int> d) => d.value > 0)) {
          unhit.add(
            '${e.symbol} -> ${e.dartSymbol} @ $path:${range[0]}-${range[1]} '
            '(${inRange.length} executable lines, ALL zero) — declared, '
            'never exercised. ${e.src}',
          );
        }
      }

      // Reported, not asserted away: a symbol with no executable line is a
      // real limit of the instrument and belongs in the record.
      if (unmeasurable.isNotEmpty) {
        // ignore: avoid_print
        print('F0-AC-96 — ${unmeasurable.length} symbol(s) carry no '
            'executable line and cannot be swept:\n  '
            '${unmeasurable.join('\n  ')}');
      }

      expect(unhit, isEmpty,
          reason: 'F0-AC-96: these kernel exports are declared but never '
              'exercised. Declaration is what v1.0 accepted and what this '
              'criterion exists to stop.\n  ${unhit.join('\n  ')}');

      expect(swept, greaterThan(0),
          reason: 'the sweep matched no symbol at all — lcov.info was parsed '
              'but nothing lined up, which is an instrument failure, not a '
              'pass');
    });
  });
}
