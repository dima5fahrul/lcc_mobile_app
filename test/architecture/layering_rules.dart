/// The **implementation** of G-L1 … G-L5 and G-L7 — the layering guards defined
/// in SSD § 4.7 — as pure functions over a scanned directory tree.
///
/// `layering_test.dart` is the production run of them over `lib/`.
/// `guard_selftest_test.dart` (§ 6.7.7, B2-AC-7) is the negative control: it
/// runs the *same functions* over the deliberately-violating fixture trees
/// under `fixtures/violations/` and asserts each one reports exactly its
/// fixture's violation.
///
/// ## G-L6 is not here, and its absence is a decision (B9a, B9-AC-9)
///
/// `GOR-245-f0-form-kernel/specs.md` § 6.1.3 proposed a **G-L6** worded *"no
/// file under `lib/features/**` or `lib/core/**` imports `lib/presentation/**`"*.
/// Measured against this tree at `f530d8e`,
/// `grep -rn "presentation/{theme,icons,common,shell}/" lib/features lib/core`
/// returns **170 lines** — every B2 page importing `presentation/theme/`, which
/// is what that directory is *for* (SSD § 4.4).
///
/// `ssd.md`:156-157's *"nothing → presentation"* is a Clean-Architecture
/// **layer** rule — `data/` and `domain/` must not depend on `presentation/` —
/// not a ban on a feature page using a shared widget. Read as F0 words it, it
/// makes `lib/presentation/` unusable by construction and contradicts § 4.4 in
/// the same document.
///
/// So B9a **refuses G-L6 by name** rather than re-wording it into something
/// else that would then disagree with F0's document. The number is left unused;
/// a gap in the sequence is cheaper than two specs disagreeing about what
/// `G-L6` asserts. It goes back to F0 and the SSD as FU-2.
///
/// ## Why the machinery moved out of `layering_test.dart`
///
/// specs.md § 6.7.7 asks for the minimal change — `_scanLib()`'s hardcoded
/// `const String _libDir = 'lib'` becoming a parameter — and says the rest of
/// the file is untouched. Parameterising the scan is necessary but on its own
/// is not sufficient: with the five assertions inlined inside `test()` bodies
/// in a `main()`, a self-test in another file cannot invoke a guard at all, and
/// the only way to "prove the guards fire" would be to re-implement them in the
/// self-test — which proves a *copy* fires and says nothing about the guard the
/// build actually runs. That is precisely the vacuity § 6.7.7 exists to close.
///
/// So the scanner and the five violation-collecting functions live here, and
/// `layering_test.dart` keeps every `expect` and every `reason:` string
/// verbatim. The rule text did not change; only who can call it did. This is a
/// recorded deviation from § 6.7.7's "the rest of the file is untouched".
///
/// ## Three implementation choices worth knowing about
///
/// **1. Imports are matched as resolved paths, not as substrings.** Every
/// import in `lib/` today is *relative* (`../../core/storage/...`), so a naive
/// `contains('/data/')` would miss `import '../models/x.dart'` from a sibling
/// directory and would fire on an unrelated package whose name happens to
/// contain the word. [DartImport.target] is the URI resolved against the
/// importing file's own directory and expressed relative to the scan root, and
/// every rule below matches whole path *segments* of that.
/// `package:lcc_mobile_app/...` is resolved too, so the guards keep working if
/// the codebase ever switches import style.
///
/// **2. The G-L5 identifier scan runs on source with comments stripped**, via
/// [stripComments]. This is not defensive polish — it is load-bearing right
/// now. `language_toggle.dart` and `app_top_bar.dart` both *document* the seam
/// by naming `injection<StorageService>()` in a doc comment, and
/// `auth_page.dart` names `authInjection` while explaining who owns the BLoC's
/// lifetime. A raw-text scan would fail on all three and the only way to get
/// green would be to delete the explanation of the rule from the files the rule
/// governs. The stripper keeps string *contents* (so a hypothetical
/// `'${injection<T>()}'` interpolation is still caught) and only drops comments.
///
/// **3. Only `import` directives are inspected, not `export`.** § 4.7 says
/// "imports", and `lib/` contains zero `export` directives today, so the two
/// readings currently describe the same set of edges. If a barrel file ever
/// lands, [DartImport] parsing is the one place to widen.
library;

import 'dart:io';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

/// One `import` directive: the literal URI, the 1-based line it sits on, and
/// [target] — the URI resolved to a scan-root-relative path, or null for
/// `dart:` and third-party `package:` imports, which no guard here constrains
/// by path.
class DartImport {
  const DartImport({
    required this.uri,
    required this.line,
    required this.target,
  });

  final String uri;
  final int line;
  final String? target;
}

/// One non-generated Dart file under the scan root.
class DartFile {
  const DartFile({
    required this.path,
    required this.imports,
    required this.code,
    this.source = '',
  });

  /// Scan-root-relative, forward slashes — e.g.
  /// `core/di/dependency_injection.dart`.
  final String path;

  final List<DartImport> imports;

  /// File contents with comments removed. See choice 2 in the library doc.
  final String code;

  /// The file **as written**, comments and all.
  ///
  /// [code] cannot serve G-L8: [stripComments] collapses a block comment to a
  /// single space, so every line number after one is wrong, and G-L8's whole
  /// output is `file:line` citations. [trCallsIn] therefore does its own
  /// comment-aware pass over this.
  final String source;

  /// Imports that resolve inside this package.
  Iterable<DartImport> get localImports =>
      imports.where((DartImport i) => i.target != null);

  List<String> get segments => path.split('/');

  /// True when [segment] is a whole path segment of [path]. `under('data')`
  /// matches `features/auth/data/models/x.dart` and never `metadata/x.dart`.
  bool under(String segment) => segments.contains(segment);

  /// The owning feature for `features/<name>/...`, else null.
  String? get feature => (segments.length > 1 && segments.first == 'features')
      ? segments[1]
      : null;

  /// § 4.7's "under `presentation/` (either kind)" — `lib/presentation/**` and
  /// `features/*/presentation/**` alike.
  bool get isPresentation => under('presentation');
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanning
// ─────────────────────────────────────────────────────────────────────────────

const String _packagePrefix = 'package:lcc_mobile_app/';

/// The production scan root. `flutter test` runs with the package root as its
/// working directory — the same assumption `test/helpers/app_test_harness.dart`'s
/// `JsonFileAssetLoader` already makes when it reads `assets/i18n/*.json` off
/// disk.
const String kLibDir = 'lib';

final RegExp _importDirective = RegExp('''^\\s*import\\s+r?['"]([^'"]+)['"]''');

bool _isIdentifierChar(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

/// Removes `//` line comments and (nestable) `/* */` block comments, leaving
/// string literals intact. See choice 2 in the library doc for why.
///
/// Raw strings are recognised (`r'...'`) so that a trailing backslash inside
/// one does not swallow the rest of the file as if it were an escape.
String stripComments(String src) {
  final StringBuffer out = StringBuffer();
  final int n = src.length;
  int i = 0;

  while (i < n) {
    final String c = src[i];

    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }

    if (c == '/' && i + 1 < n && src[i + 1] == '*') {
      int depth = 1;
      i += 2;
      while (i < n && depth > 0) {
        if (src[i] == '/' && i + 1 < n && src[i + 1] == '*') {
          depth++;
          i += 2;
        } else if (src[i] == '*' && i + 1 < n && src[i + 1] == '/') {
          depth--;
          i += 2;
        } else {
          i++;
        }
      }
      // A space, not nothing: `a/* x */b` must not become the identifier `ab`.
      out.write(' ');
      continue;
    }

    if (c == "'" || c == '"') {
      final bool isRaw =
          i > 0 &&
          src[i - 1] == 'r' &&
          (i < 2 || !_isIdentifierChar(src[i - 2]));
      final bool triple = i + 2 < n && src[i + 1] == c && src[i + 2] == c;
      final String delim = triple ? c * 3 : c;

      out.write(delim);
      i += delim.length;

      while (i < n) {
        if (!isRaw && src[i] == r'\') {
          out.write(src[i]);
          if (i + 1 < n) out.write(src[i + 1]);
          i += 2;
          continue;
        }
        if (src.startsWith(delim, i)) {
          out.write(delim);
          i += delim.length;
          break;
        }
        // An unterminated single-quote string cannot cross a newline; bail
        // rather than consuming the remainder of the file.
        if (!triple && src[i] == '\n') break;
        out.write(src[i]);
        i++;
      }
      continue;
    }

    out.write(c);
    i++;
  }

  return out.toString();
}

/// Joins a root-relative directory with a relative import URI, collapsing
/// `.` and `..`.
String _joinRelative(String dir, String relative) {
  final List<String> segments = dir
      .split('/')
      .where((String s) => s.isNotEmpty)
      .toList();
  for (final String s in relative.split('/')) {
    if (s.isEmpty || s == '.') continue;
    if (s == '..') {
      if (segments.isNotEmpty) segments.removeLast();
      continue;
    }
    segments.add(s);
  }
  return segments.join('/');
}

/// Resolves [uri] as seen from [fromPath] to a root-relative path, or null
/// when it points outside this package (`dart:`, third-party `package:`).
String? _resolveImport(String fromPath, String uri) {
  if (uri.startsWith(_packagePrefix)) {
    return uri.substring(_packagePrefix.length);
  }
  if (uri.startsWith('dart:') || uri.startsWith('package:')) return null;

  final int slash = fromPath.lastIndexOf('/');
  final String dir = slash == -1 ? '' : fromPath.substring(0, slash);
  return _joinRelative(dir, uri);
}

/// Thrown when [scanTree] is pointed at a directory that does not exist.
///
/// A typed failure rather than an `expect`, so this file stays importable from
/// non-test code and so the caller decides how to phrase the failure. Both
/// callers do phrase it — see `layering_test.dart`'s scan reason.
class MissingScanRoot implements Exception {
  const MissingScanRoot(this.dir);

  final String dir;

  @override
  String toString() =>
      'Expected to find `$dir/` relative to the working directory. '
      '`flutter test` runs from the package root; if this fails, the suite '
      'was launched from somewhere else and these guards scanned nothing.';
}

/// Every non-generated Dart file under [dir], sorted by path.
///
/// [dir] is a parameter rather than the hardcoded `'lib'` § 4.7's original
/// implementation used — that is § 6.7.7's minimal change, and it is what lets
/// the self-test point the same scanner at a fixture tree. Generated code is
/// excluded by § 4.7: it has no independent placement decision, it inherits its
/// source file's.
List<DartFile> scanTree(String dir) {
  final Directory root = Directory(dir);
  if (!root.existsSync()) throw MissingScanRoot(dir);

  final List<DartFile> files = <DartFile>[];

  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;

    final String path = entity.path.replaceAll(r'\', '/');
    if (!path.endsWith('.dart')) continue;
    if (path.endsWith('.freezed.dart') || path.endsWith('.g.dart')) continue;

    final String rootRelative = path.startsWith('$dir/')
        ? path.substring(dir.length + 1)
        : path;

    final String source = entity.readAsStringSync();
    final List<String> lines = source.split('\n');
    final List<DartImport> imports = <DartImport>[];

    for (int i = 0; i < lines.length; i++) {
      final RegExpMatch? match = _importDirective.firstMatch(lines[i]);
      if (match == null) continue;
      final String uri = match.group(1)!;
      imports.add(
        DartImport(
          uri: uri,
          line: i + 1,
          target: _resolveImport(rootRelative, uri),
        ),
      );
    }

    files.add(
      DartFile(
        path: rootRelative,
        imports: imports,
        code: stripComments(source),
        source: source,
      ),
    );
  }

  files.sort((DartFile a, DartFile b) => a.path.compareTo(b.path));
  return files;
}

/// True when [target] sits under `<segment>/` at any depth.
bool _targetUnder(String target, String segment) =>
    target.split('/').contains(segment);

/// `features/<name>/...` → `<name>`, else null.
String? _targetFeature(String target) {
  final List<String> s = target.split('/');
  return (s.length > 1 && s.first == 'features') ? s[1] : null;
}

/// `features/<name>/<layer>/...` → `<layer>`, else null.
String? _targetFeatureLayer(String target) {
  final List<String> s = target.split('/');
  return (s.length > 2 && s.first == 'features') ? s[2] : null;
}

String cite(DartFile file, DartImport import) =>
    '${file.path}:${import.line} -> ${import.uri}';

// ─────────────────────────────────────────────────────────────────────────────
// Guards — each returns the citations it found, empty meaning "green"
// ─────────────────────────────────────────────────────────────────────────────

/// **G-L1** — no file under `presentation/` (either kind) imports `**/data/**`.
List<String> glL1Violations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files.where((DartFile f) => f.isPresentation)) {
    for (final DartImport import in file.localImports) {
      if (_targetUnder(import.target!, 'data')) {
        violations.add(cite(file, import));
      }
    }
  }

  return violations;
}

/// **G-L2** — no file under `**/domain/**` imports `**/data/**` or
/// `**/presentation/**`.
List<String> glL2Violations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files.where((DartFile f) => f.under('domain'))) {
    for (final DartImport import in file.localImports) {
      if (_targetUnder(import.target!, 'data') ||
          _targetUnder(import.target!, 'presentation')) {
        violations.add(cite(file, import));
      }
    }
  }

  return violations;
}

/// **G-L3** — no file under `features/A/**` imports
/// `features/B/{data,presentation}/**`, A ≠ B.
List<String> glL3Violations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files) {
    final String? from = file.feature;
    if (from == null) continue;

    for (final DartImport import in file.localImports) {
      final String? to = _targetFeature(import.target!);
      if (to == null || to == from) continue;
      if (_targetUnder(import.target!, 'data') ||
          _targetUnder(import.target!, 'presentation')) {
        violations.add('[$from → $to] ${cite(file, import)}');
      }
    }
  }

  return violations;
}

/// The two `package:flutter` libraries `lib/core/**` may not import.
const Set<String> kForbiddenCorePackages = <String>{
  'package:flutter/material.dart',
  'package:flutter/widgets.dart',
};

/// **G-L4** — no file under `core/**` imports Flutter UI or a feature's
/// `data/` / `presentation/`.
List<String> glL4Violations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files.where(
    (DartFile f) => f.segments.first == 'core',
  )) {
    for (final DartImport import in file.imports) {
      if (kForbiddenCorePackages.contains(import.uri)) {
        violations.add(cite(file, import));
        continue;
      }
      final String? target = import.target;
      if (target == null) continue;
      if (_targetFeature(target) == null) continue;
      if (_targetUnder(target, 'data') ||
          _targetUnder(target, 'presentation')) {
        violations.add(cite(file, import));
      }
    }
  }

  return violations;
}

/// The two feature layers a `core → features/**` edge may legitimately point
/// at. See [glL4Unclassified] for why this is stated rather than implied.
const Set<String> kAllowedCoreToFeatureLayers = <String>{'domain', 'di'};

/// **G-L4, second half** — a `core → features/**` import landing in a layer
/// that is neither `domain/` nor `di/`.
///
/// § 4.7 phrases G-L4's carve-out as "the single allowed exception is
/// `core/session/bloc/**` → `features/session/domain/**`", and § 6.3's
/// verification #5 claimed the R3 edge would be "the only `core → features`
/// import in the tree". Both are inaccurate as written: the tree holds
/// **nine** `core → features` imports across **two** files —
///
///   6 × domain : core/session/bloc/session_bloc.dart      → features/session/domain/**
///                core/di/dependency_injection.dart        → features/session/domain/**
///   3 × di     : core/di/dependency_injection.dart        → features/{auth,session}/di/**
///
/// — and every one of them passes [glL4Violations], because that rule forbids
/// only `{data,presentation}`. So the exception clause is already vacuous for
/// `domain/`, and `core/di → features/*/di` is *unforbidden* rather than
/// *permitted*.
///
/// That distinction matters for the next reader, so it is pinned here instead
/// of being left to inference. The composition root is the one place that is
/// supposed to know every feature exists — `DependencyInjection.init()` cannot
/// wire `AuthFeatureInjection` without importing it — so `core/di →
/// features/*/di` is a deliberate allowance, not an oversight. Any *other*
/// shape of `core → features` edge is neither forbidden above nor intended, and
/// fails here.
List<String> glL4Unclassified(List<DartFile> files) {
  final List<String> unclassified = <String>[];

  for (final DartFile file in files.where(
    (DartFile f) => f.segments.first == 'core',
  )) {
    for (final DartImport import in file.localImports) {
      final String target = import.target!;
      if (_targetFeature(target) == null) continue;
      final String? layer = _targetFeatureLayer(target);
      if (!kAllowedCoreToFeatureLayers.contains(layer)) {
        unclassified.add('[layer=$layer] ${cite(file, import)}');
      }
    }
  }

  return unclassified;
}

/// Exactly the three container names in the codebase: the root `injection` and
/// the two feature-scoped `GetIt.asNewInstance()` containers.
const List<String> kLocatorNames = <String>[
  'injection',
  'authInjection',
  'sessionInjection',
];

/// **G-L5** — no file under `lib/presentation/**` or
/// `features/*/presentation/**` names a locator or imports a `**/di/**` path.
List<String> glL5Violations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files.where((DartFile f) => f.isPresentation)) {
    // (a) The import half: a widget file has no business importing DI wiring.
    for (final DartImport import in file.localImports) {
      if (_targetUnder(import.target!, 'di')) {
        violations.add('[di import] ${cite(file, import)}');
      }
    }

    // (b) The identifier half, over comment-stripped source. Whole-identifier
    // matching, so `dependency_injection` and `AuthFeatureInjection` — which
    // are file/class names, not container reads — do not trip it.
    for (final String locator in kLocatorNames) {
      final RegExp whole = RegExp(
        r'(?<![A-Za-z0-9_$])' + locator + r'(?![A-Za-z0-9_$])',
      );
      if (whole.hasMatch(file.code)) {
        violations.add('[locator `$locator`] ${file.path}');
      }
    }
  }

  return violations;
}

/// **G-L7** — no file under `lib/presentation/**` imports
/// `features/*/presentation/**`.
///
/// ## The hole this closes, measured
///
/// `ssd.md`:255 has said since the SSD landed: *"`presentation/**` may import
/// `core/**`, `features/*/domain/**`, and other `presentation/**`. It may
/// **not** import `features/*/data/**` or `features/*/presentation/**`."*
/// **Nothing enforced the second half.**
///
/// - [glL1Violations] scans `isPresentation` files for `data/` targets. It
///   catches the `data/` clause and never looks at `presentation/`.
/// - [glL3Violations] opens with `final String? from = file.feature;
///   if (from == null) continue;`, and [DartFile.feature] is non-null only for
///   paths beginning `features/`. **Every file under `lib/presentation/` has
///   `feature == null` and is skipped**, by construction.
/// - G-L2, G-L4 and G-L5 are scoped elsewhere.
///
/// The rule was green at 0 edges purely because no batch had needed one. B9 is
/// the first batch whose design could break it — a feature BLoC behind a shell
/// widget is precisely the temptation — so the guard lands in **B9a, before its
/// first consumer exists** (specs.md § 6.5, § 8.1). A guard written after the
/// code it constrains is a guard written to match it, which is the vacuity
/// B2-AC-7 exists to prevent and which `d22cd98`'s own commit message admitted
/// to.
///
/// ## Two scoping choices
///
/// **1. `segments.first == 'presentation'`, not [DartFile.isPresentation].**
/// The latter is true for `features/*/presentation/**` too, and one feature's
/// widget importing another's is **G-L3's** rule, with its own citation format
/// (`[a → b] …`). Widening this one to cover it would make two guards report
/// the same edge and send a reader to whichever fired first.
///
/// **2. The target's feature layer must be exactly `presentation`**, rather
/// than `_targetUnder(target, 'presentation')`. `ssd.md`:255 names
/// `features/*/presentation/**` — the layer directly under the feature — and
/// the segment test would also match a hypothetical
/// `features/x/data/presentation/`, which is a different (and already
/// G-L1-caught) mistake.
List<String> glL7Violations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files.where(
    (DartFile f) => f.segments.first == 'presentation',
  )) {
    for (final DartImport import in file.localImports) {
      final String target = import.target!;
      if (_targetFeature(target) == null) continue;
      if (_targetFeatureLayer(target) != 'presentation') continue;
      violations.add(cite(file, import));
    }
  }

  return violations;
}

// ─────────────────────────────────────────────────────────────────────────────
// G-L8 — `.tr()` must bind to a context (B10 § 6.7.4, D-3)
// ─────────────────────────────────────────────────────────────────────────────

/// One `.tr(...)` call site found by [trCallsIn].
class TrCall {
  const TrCall({required this.line, required this.key, required this.bound});

  /// 1-based, in the file as written.
  final int line;

  /// The i18n key the call is on — `'layout.home'.tr()` → `layout.home`.
  ///
  /// Empty when the receiver is not a string literal (e.g.
  /// `tab.labelKey.tr()`); [rawReceiver] is what was found instead, so an
  /// allowlist entry can still name the site stably.
  final String key;

  /// True when the argument list passes `context:`.
  final bool bound;

  /// The literal key when there is one, else the receiver expression's last
  /// identifier — enough to distinguish two calls in the same file.
  String get rawReceiver => key;
}

/// Every `.tr(` call in [source], comment- and string-aware, with line numbers
/// that match the file as written.
///
/// ## Why this is a hand-rolled scan and not a regex
///
/// The thing being decided is *"does this argument list contain `context:` at
/// depth 1"*, and argument lists nest: `'k'.tr(namedArgs: {'a': f(context)})`
/// mentions `context` and is **not** bound. A regex over `\.tr\([^)]*\)` also
/// stops at the first `)`, which is inside `f(` above. Paren balancing is the
/// minimum correct machinery, so it is written out rather than approximated.
///
/// Strings and comments are skipped so that a `.tr(` inside a doc comment —
/// this file's own doc comments contain several — is not a call site. That is
/// the same load-bearing property [stripComments] provides for G-L5, done in
/// one pass here because line numbers must survive it.
List<TrCall> trCallsIn(String source) {
  final List<TrCall> calls = <TrCall>[];
  final int n = source.length;
  int i = 0;
  int line = 1;

  // Where each scanned character came from, so a key literal can be read back.
  final StringBuffer plain = StringBuffer();
  final List<int> plainLine = <int>[];

  void emit(String c, int atLine) {
    plain.write(c);
    plainLine.add(atLine);
  }

  while (i < n) {
    final String c = source[i];

    if (c == '\n') {
      line++;
      emit('\n', line - 1);
      i++;
      continue;
    }

    // `//` line comment
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      while (i < n && source[i] != '\n') {
        i++;
      }
      continue;
    }

    // `/* */`, nestable
    if (c == '/' && i + 1 < n && source[i + 1] == '*') {
      int depth = 1;
      i += 2;
      while (i < n && depth > 0) {
        if (source[i] == '\n') line++;
        if (source[i] == '/' && i + 1 < n && source[i + 1] == '*') {
          depth++;
          i += 2;
        } else if (source[i] == '*' && i + 1 < n && source[i + 1] == '/') {
          depth--;
          i += 2;
        } else {
          i++;
        }
      }
      emit(' ', line);
      continue;
    }

    // String literals are kept **verbatim** (quotes included) because the key
    // this guard reports is one of them.
    if (c == "'" || c == '"') {
      final bool isRaw =
          i > 0 &&
          source[i - 1] == 'r' &&
          (i < 2 || !_isIdentifierChar(source[i - 2]));
      final bool triple = i + 2 < n && source[i + 1] == c && source[i + 2] == c;
      final String delim = triple ? c * 3 : c;

      emit(delim, line);
      i += delim.length;

      while (i < n) {
        if (!isRaw && source[i] == r'\') {
          emit(source[i], line);
          if (i + 1 < n) emit(source[i + 1], line);
          i += 2;
          continue;
        }
        if (source.startsWith(delim, i)) {
          emit(delim, line);
          i += delim.length;
          break;
        }
        if (source[i] == '\n') {
          if (!triple) break;
          line++;
        }
        emit(source[i], line);
        i++;
      }
      continue;
    }

    emit(c, line);
    i++;
  }

  final String flat = plain.toString();

  for (int p = 0; p + 3 < flat.length; p++) {
    if (flat[p] != '.') continue;
    if (!flat.startsWith('.tr(', p)) continue;

    // Balance the argument list.
    int depth = 0;
    int q = p + 3;
    int close = -1;
    bool inStr = false;
    String strDelim = '';
    for (; q < flat.length; q++) {
      final String ch = flat[q];
      if (inStr) {
        if (ch == r'\') {
          q++;
        } else if (ch == strDelim) {
          inStr = false;
        }
        continue;
      }
      if (ch == "'" || ch == '"') {
        inStr = true;
        strDelim = ch;
        continue;
      }
      if (ch == '(' || ch == '[' || ch == '{') depth++;
      if (ch == ')' || ch == ']' || ch == '}') {
        depth--;
        if (depth == 0) {
          close = q;
          break;
        }
      }
    }
    if (close == -1) continue;

    final String args = flat.substring(p + 4, close);
    final bool bound = _hasTopLevelContextArg(args);

    // Read the key back: the string literal immediately before `.tr`.
    String key = '';
    if (p > 0 && (flat[p - 1] == "'" || flat[p - 1] == '"')) {
      final String delim = flat[p - 1];
      final int open = flat.lastIndexOf(delim, p - 2);
      if (open != -1) key = flat.substring(open + 1, p - 1);
    } else {
      // A non-literal receiver. Three real shapes in this tree:
      //
      //   tab.labelKey.tr()            → `labelKey`
      //   widget.errorKey?.tr()        → `errorKey`
      //   (a ? 'k1' : 'k2').tr()       → no trailing identifier at all
      //
      // Walk back over the postfix chain (identifiers, `.`, `?`, and balanced
      // groups) and take its last identifier. The third shape has none, so it
      // gets the sentinel `<expr>` — which is still a stable, countable slot
      // because entries match as a multiset per file.
      int s = p - 1;
      int depth = 0;
      while (s >= 0) {
        final String ch = flat[s];
        if (ch == ')' || ch == ']' || ch == '}') {
          depth++;
          s--;
          continue;
        }
        if (ch == '(' || ch == '[' || ch == '{') {
          if (depth == 0) break;
          depth--;
          s--;
          continue;
        }
        if (depth > 0) {
          s--;
          continue;
        }
        if (_isIdentifierChar(ch) || ch == '.' || ch == '?') {
          s--;
          continue;
        }
        break;
      }
      final String chain = flat.substring(s + 1, p);
      int t = chain.length;
      while (t > 0 && _isIdentifierChar(chain[t - 1])) {
        t--;
      }
      final String trailing = chain.substring(t);
      key = trailing.isEmpty ? '<expr>' : trailing;
    }

    calls.add(TrCall(line: plainLine[p], key: key, bound: bound));
  }

  return calls;
}

/// True when `context:` appears as a **depth-1** named argument of the list.
bool _hasTopLevelContextArg(String args) {
  int depth = 0;
  bool inStr = false;
  String delim = '';
  for (int i = 0; i < args.length; i++) {
    final String c = args[i];
    if (inStr) {
      if (c == r'\') {
        i++;
      } else if (c == delim) {
        inStr = false;
      }
      continue;
    }
    if (c == "'" || c == '"') {
      inStr = true;
      delim = c;
      continue;
    }
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if (depth != 0) continue;
    if (args.startsWith('context:', i)) {
      final bool boundaryOk = i == 0 || !_isIdentifierChar(args[i - 1]);
      if (boundaryOk) return true;
    }
  }
  return false;
}

/// One line of `test/architecture/tr_allowlist.yaml`.
class TrAllowEntry {
  const TrAllowEntry({
    required this.path,
    required this.line,
    required this.key,
    required this.batch,
  });

  final String path;

  /// Informational — see [glL8Violations] for why it is not the match key.
  final int line;
  final String key;
  final String batch;

  String get slot => '$path::$key';
}

/// **G-L8** — no `.tr()` call in `lib/**` may omit `context:`, unless its site
/// is listed in `test/architecture/tr_allowlist.yaml`.
///
/// ## The rule, and the defect it closes
///
/// `easy_localization-3.0.8/lib/src/public.dart`:39-44:
///
/// ```dart
/// return context != null
///     ? Localization.of(context)!.tr(key, …)   // registers a dependency
///     : Localization.instance.tr(key, …);      // global — no dependency
/// ```
///
/// A bare `.tr()` reads the global. It creates no `InheritedWidget`
/// dependency, so when `_EasyLocalizationDelegate.load` swaps
/// `Localization.instance` asynchronously and `Localizations` rebuilds with
/// the **identical** `child` instance, `framework.dart`:4014 short-circuits and
/// nothing below repaints. That is **D-3**, and B10 § 6.6 measured it: nine
/// strings on Home stay in the old language until the next navigation.
///
/// **The `const` theory is refuted, not implemented.** `ssd.md`:775-778 rules
/// that *"new pages must not mark a subtree `const` when it contains a `.tr()`
/// call"*. Measured (§ 6.6.3): a **`const`** widget calling
/// `.tr(context: context)` refreshes; a **non-const** one calling bare `.tr()`
/// (`AppBottomNav`, `app_shell.dart`:130) goes stale; and commit `d22cd98`
/// already removed the `const` from both sites that theory blames while the
/// defect survived. `const` is not the discriminator. `context:` is, and that
/// is what this guard checks.
///
/// ## Why an allowlist rather than a clean sweep
///
/// § 6.7.3. The remaining sites live in files owned by B2, B9 and F0, with
/// three more batches authoring against them concurrently; rewriting them all
/// would make B10 unmergeable. A guard with **no** allowlist would fail on
/// ~300 pre-existing lines and be switched off within a day (§ 6.7.4). A guard
/// with a **shrinking, enumerated** allowlist constrains new code immediately
/// and turns the backlog into something countable.
///
/// **The list may only shrink.** Adding an entry to make a build pass is
/// forbidden — stated in the file's own header, and asserted by
/// `tr_allowlist_test.dart`'s ceiling check.
///
/// ## DECLARED DEVIATION from § 6.7.4 — entries match on `path::key`, not on
/// `path:line`
///
/// `B10-AC-10` asks for `file:line` per entry, and every entry **records** its
/// line. But matching on the line number was measured to be unusable in this
/// tree: adding a single doc comment shifts every site below it, and this
/// repository has **concurrent writers** (§ 2.2 finding 5b) — B10's own D-3
/// edit to `hero_header.dart` moved a listed line by five. A guard that goes
/// red because somebody above it wrote a comment is a guard that gets deleted,
/// which is precisely the outcome § 6.7.4 designed the allowlist to avoid.
///
/// So the **match** is `path::key` as a multiset (N bare calls on key `k` in
/// file `f` are covered by exactly N entries for `f::k`), and the line is
/// carried for a human to navigate by. Nothing about the ceiling weakens: a
/// new bare `.tr()` anywhere — new file, new key, or an extra call on an
/// already-listed key — raises the required count above the list and fails.
List<String> glL8Violations(
  List<DartFile> files, {
  required List<TrAllowEntry> allowlist,
}) {
  final List<String> violations = <String>[];

  // Remaining budget per `path::key`.
  final Map<String, int> budget = <String, int>{};
  for (final TrAllowEntry entry in allowlist) {
    budget[entry.slot] = (budget[entry.slot] ?? 0) + 1;
  }

  for (final DartFile file in files) {
    for (final TrCall call in trCallsIn(file.source)) {
      if (call.bound) continue;
      final String slot = '${file.path}::${call.key}';
      final int left = budget[slot] ?? 0;
      if (left > 0) {
        budget[slot] = left - 1;
        continue;
      }
      violations.add(
        '${file.path}:${call.line} -> ${call.key}.tr() '
        'has no `context:`',
      );
    }
  }

  return violations;
}

/// Allowlist entries that no longer describe a bare `.tr()` in the tree.
///
/// A stale entry is a **permission that outlived its subject** — the same
/// hazard `color_literal_test.dart`'s "no dead entries" check exists for. It is
/// reported separately from [glL8Violations] because the two mean opposite
/// things: a violation is new debt, a dead entry is debt already paid that the
/// list has not been told about.
List<String> glL8DeadEntries(
  List<DartFile> files, {
  required List<TrAllowEntry> allowlist,
}) {
  final Map<String, int> actual = <String, int>{};
  for (final DartFile file in files) {
    for (final TrCall call in trCallsIn(file.source)) {
      if (call.bound) continue;
      final String slot = '${file.path}::${call.key}';
      actual[slot] = (actual[slot] ?? 0) + 1;
    }
  }

  final Map<String, int> listed = <String, int>{};
  for (final TrAllowEntry entry in allowlist) {
    listed[entry.slot] = (listed[entry.slot] ?? 0) + 1;
  }

  final List<String> dead = <String>[];
  listed.forEach((String slot, int count) {
    final int have = actual[slot] ?? 0;
    if (have < count) {
      dead.add(
        '$slot — listed $count time(s), found $have. Delete the '
        'surplus entr${count - have == 1 ? 'y' : 'ies'}: the list may only '
        'shrink, and it shrinks by deletion.',
      );
    }
  });
  dead.sort();
  return dead;
}

/// Parses `test/architecture/tr_allowlist.yaml`.
///
/// A hand-rolled line parser rather than `package:yaml`: the file is a flat
/// list of four scalar fields and adding a parser dependency to reach it would
/// be a `pubspec.yaml` change, which B10 § 4.3 forbids outright.
List<TrAllowEntry> parseTrAllowlist(String yaml) {
  final List<TrAllowEntry> entries = <TrAllowEntry>[];
  String? path;
  int? line;
  String? key;
  String? batch;

  String unquote(String v) {
    final String t = v.trim();
    if (t.length >= 2 &&
        ((t.startsWith('"') && t.endsWith('"')) ||
            (t.startsWith("'") && t.endsWith("'")))) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  void flush() {
    if (path != null && line != null && key != null) {
      entries.add(
        TrAllowEntry(
          path: path!,
          line: line!,
          key: key!,
          batch: batch ?? 'unknown',
        ),
      );
    }
    path = null;
    line = null;
    key = null;
    batch = null;
  }

  for (final String rawLine in yaml.split('\n')) {
    final String trimmed = rawLine.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    if (trimmed.startsWith('- ')) {
      flush();
      final String rest = trimmed.substring(2).trim();
      if (rest.startsWith('file:')) {
        path = unquote(rest.substring('file:'.length));
      }
      continue;
    }
    if (trimmed.startsWith('file:')) {
      path = unquote(trimmed.substring('file:'.length));
    } else if (trimmed.startsWith('line:')) {
      line = int.tryParse(unquote(trimmed.substring('line:'.length)));
    } else if (trimmed.startsWith('key:')) {
      key = unquote(trimmed.substring('key:'.length));
    } else if (trimmed.startsWith('batch:')) {
      batch = unquote(trimmed.substring('batch:'.length));
    }
  }
  flush();

  return entries;
}

// ─────────────────────────────────────────────────────────────────────────────
// G-L6 — the `→ presentation` edge nothing else can see (F0b, § 6.1.3)
// ─────────────────────────────────────────────────────────────────────────────

/// **G-L6** — no file under `**/data/**` or `lib/core/**` imports
/// `**/presentation/**`.
///
/// ## This is NARROWER than F0's § 6.1.3 wording, and the narrowing is measured
///
/// `GOR-245-f0-form-kernel/specs.md` § 6.1.3 words G-L6 as *"no file under
/// `lib/features/**` or `lib/core/**` imports `lib/presentation/**`"*, and
/// `F0-AC-74` asks for it to be green on the real tree. **It cannot be.**
/// Measured at `6ae5bea`:
///
/// ```
/// grep -rn "presentation/{theme,icons,common,shell}/" lib/features lib/core
/// → 218 lines
/// ```
///
/// — every B2/B8/B9/B10 page importing `presentation/theme/`, which is what
/// that directory is *for* (`ssd.md` § 4.4). B9a measured 170 of the same lines
/// at `f530d8e` and **refused the rule by name** rather than re-word it into
/// something that would then disagree with F0's document (B9-AC-9, FU-2). This
/// is F0b answering that FU rather than landing the impossible pair.
///
/// ## Why this scope is the rule § 6.1.2 actually needed
///
/// `ssd.md`:156-157's *"nothing → presentation"* is a Clean-Architecture
/// **layer** rule: `data/` and `domain/` must not depend on `presentation/`.
/// The hazard § 6.1.2 row 3 names is precisely one edge —
///
/// > *v1.0 § 6.1 itself says the executor "lives in `features/certificates/data/`".
/// > A `data/` file importing `lib/presentation/forms/submission/` is a
/// > `data → presentation` edge, forbidden by name.*
///
/// — and **nothing in the tree could see it**: [glL1Violations] is
/// presentation→data, [glL2Violations] covers only `domain/`, [glL4Violations]
/// covers `core → features/*/{data,presentation}` but not `core →
/// lib/presentation/**`, and [glL7Violations] is `lib/presentation →
/// features/*/presentation`. This closes exactly that gap and no more.
///
/// Measured green in both halves before it was written: zero `data → presentation`
/// imports and zero `core → presentation` imports at `6ae5bea`.
///
/// ## Two scoping choices
///
/// **1. `domain/` is left to G-L2**, which already forbids the same edge with
/// its own citation format. Two guards reporting one edge sends a reader to
/// whichever fired first — the reason [glL7Violations] declines to cover
/// G-L3's ground.
///
/// **2. Both kinds of `presentation/` count.** `ssd.md`:157 does not
/// distinguish `lib/presentation/` from `features/*/presentation/`, and a
/// repository importing its own feature's widget is the same layer inversion as
/// one importing the shell. G-L3 sees the cross-feature case only.
List<String> glL6Violations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files) {
    final bool isData = file.under('data');
    final bool isCore = file.segments.first == 'core';
    if (!isData && !isCore) continue;

    for (final DartImport import in file.localImports) {
      if (_targetUnder(import.target!, 'presentation')) {
        violations.add(cite(file, import));
      }
    }
  }

  return violations;
}

// ─────────────────────────────────────────────────────────────────────────────
// The date path — ADR-0005 O-4, over `lib/**` (F0b, `F0-AC-29` / `F0-AC-84`)
// ─────────────────────────────────────────────────────────────────────────────

/// The one sanctioned `DateTime.now()` site, and the one registered exception.
///
/// A **register**, not an allowlist that can be appended to casually: each row
/// carries why the site is not a date path, and
/// [dateNowUnregisteredSites] recomputes membership every run, so a site that
/// moves goes red instead of staying quietly exempt.
const Map<String, String> kDateNowRegister = <String, String>{
  'features/certificates/domain/submission/submission_clock.dart':
      'SubmissionClock.system() — the single default clock construction ADR-0005 '
      'O-4 sanctions. Every other date on a payload reads an INJECTED clock, '
      'which is what lets Tier 0 freeze the instant.',
  // **Not in the spec, and it was already in the tree when F0b arrived.**
  // `F0-AC-29` says `DateTime.now()` appears "only at the single default
  // `SubmissionClock` construction". Measured at `6ae5bea` there is a second
  // site, landed by B9a, and it is legitimate: `relativeTime(when, {now})`
  // formats "3 hours ago" for a notification list and the `?? DateTime.now()`
  // is its injectable default. It reaches no payload key and no `form_data`
  // value, so it is not a date path — but it exists, so the criterion as
  // worded is unsatisfiable and the honest answer is a register with two rows,
  // not a guard that is green because it was never written.
  'features/notifications/presentation/widgets/relative_time.dart':
      'relativeTime(when, {now}) — B9a. An injectable default for RENDERING a '
      'relative timestamp. It reaches no payload key, so it is not a date '
      'path; it is registered rather than exempted so a move goes red.',
  // A third row, and it is the same shape as B9a's for the same reason —
  // registered on that precedent rather than on a new argument.
  //
  // `daysUntil(value, {now})` is the Bills Due chip's whole arithmetic
  // (`WalletPage.tsx:78-84`): whole days from now until a due date, `ceil`, and
  // the chip is red / amber / grey off the result. `B6-AC-21` requires the
  // clock to be a parameter and requires that **no test read
  // `DateTime.now()`** — every test of it passes a fixed instant, and
  // `payment_result_test.dart` includes a two-clock negative control that fails
  // if `now` were ignored. So the injection this guard exists to enforce is
  // present and is under test; the `?? DateTime.now()` is only the default that
  // spares ~4 render call sites from threading a clock they have no opinion
  // about.
  //
  // It reaches no payload key and no `form_data` value — the pay POST's body is
  // exactly `{"method_code": …}` (`B6-AC-36`) and carries no date at all — so
  // it is not a date path. Registered rather than exempted, so a move into one
  // goes red.
  'features/wallet/domain/wallet_formatting.dart':
      'daysUntil(value, {now}) — B6b. An injectable default for RENDERING the '
      'Bills Due chip. It reaches no payload key, so it is not a date '
      'path; it is registered rather than exempted so a move goes red.',
};

/// [src] with every comment's CONTENT removed and its **line count
/// preserved**.
///
/// [stripComments] cannot serve the three line-cited scans below: it collapses
/// a block comment to a single space, so every line number after one is wrong —
/// the same reason `trCallsIn` does its own pass over [DartFile.source]
/// (see [DartFile.source]'s own doc). These guards' whole output is `file:line`
/// citations, so they need a blanker rather than a stripper.
///
/// String *contents* survive, exactly as [stripComments] preserves them: a
/// hypothetical `const s = 'DateTime.now()';` is still a hit, because a rule
/// that could be evaded by quoting is not a rule.
String blankComments(String src) {
  final StringBuffer out = StringBuffer();
  bool inLine = false;
  bool inBlock = false;
  String? quote;
  bool escaped = false;

  for (int i = 0; i < src.length; i++) {
    final String c = src[i];
    final String next = i + 1 < src.length ? src[i + 1] : '';

    if (c == '\n') {
      inLine = false;
      out.write(c);
      continue;
    }

    if (inLine || inBlock) {
      if (inBlock && c == '*' && next == '/') {
        inBlock = false;
        out.write('  ');
        i++;
        continue;
      }
      out.write(' ');
      continue;
    }

    if (quote != null) {
      out.write(c);
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == quote) {
        quote = null;
      }
      continue;
    }

    if (c == '/' && next == '/') {
      inLine = true;
      out.write('  ');
      i++;
      continue;
    }
    if (c == '/' && next == '*') {
      inBlock = true;
      out.write('  ');
      i++;
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
      out.write(c);
      continue;
    }
    out.write(c);
  }

  return out.toString();
}

final RegExp _dateNowCall = RegExp(
  r'(?<![A-Za-z0-9_$])DateTime\s*\.\s*now\s*\(',
);
final RegExp _toUtcCall = RegExp(r'(?<![A-Za-z0-9_$])toUtc\s*\(');

/// **ADR-0005 O-4, first half** — `toUtc()` appears **nowhere** under the scan
/// root.
///
/// Absolute, with no register: `new Date().toISOString()` is what makes the web
/// date every submission between 00:00 and 07:00 local **yesterday**, on eleven
/// call sites reaching eight registered wire keys. There is no legitimate
/// `toUtc()` in this application's date path, and a guard that admitted one
/// would be admitting the defect back.
///
/// Scoped to `lib/**`, not to `lib/presentation/forms/`: v1.0 narrowed O-4 to
/// one directory, which also defeated § 6.12 Q-6 — nothing stopped an F1 page
/// under `features/certificates/**` from calling `DateTime.now().toUtc()`.
///
/// Runs over [DartFile.code], so **documenting** the rule is not violating it.
/// This file's own doc comments name `toUtc()` a dozen times.
List<String> toUtcViolations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files) {
    final List<String> lines = blankComments(file.source).split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (_toUtcCall.hasMatch(lines[i])) {
        violations.add('${file.path}:${i + 1} -> ${lines[i].trim()}');
      }
    }
  }

  return violations;
}

/// **ADR-0005 O-4, second half** — a `DateTime.now()` outside
/// [kDateNowRegister].
List<String> dateNowUnregisteredSites(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files) {
    if (kDateNowRegister.containsKey(file.path)) continue;
    final List<String> lines = blankComments(file.source).split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (_dateNowCall.hasMatch(lines[i])) {
        violations.add('${file.path}:${i + 1} -> ${lines[i].trim()}');
      }
    }
  }

  return violations;
}

/// A [kDateNowRegister] row whose file holds no `DateTime.now()` at all.
///
/// The direction that stops the register becoming a waiver: a row that stops
/// qualifying goes red rather than staying quietly exempt, so the next reader
/// cannot inherit a permission nobody still needs.
List<String> dateNowDeadRegisterRows(List<DartFile> files) {
  final Map<String, DartFile> byPath = <String, DartFile>{
    for (final DartFile f in files) f.path: f,
  };

  final List<String> dead = <String>[];
  for (final String path in kDateNowRegister.keys) {
    final DartFile? file = byPath[path];
    if (file == null) {
      dead.add('$path (registered, but no such file in the scan)');
      continue;
    }
    if (!_dateNowCall.hasMatch(blankComments(file.source))) {
      dead.add('$path (registered, but holds no DateTime.now())');
    }
  }
  return dead;
}

// ─────────────────────────────────────────────────────────────────────────────
// R-21 — no picker may reject a file (F0b, `F0-AC-40`)
// ─────────────────────────────────────────────────────────────────────────────

/// The forms a hard file-type rejection takes in Flutter.
///
/// `FileType.custom` + `allowedExtensions` is `file_picker`'s hard filter with
/// no escape hatch; `.mimeType` and an `endsWith('.pdf')`-shaped test are how
/// the same rejection gets hand-rolled once the picker is open.
final List<RegExp> kPickerRejectionForms = <RegExp>[
  RegExp(r'(?<![A-Za-z0-9_$])allowedExtensions(?![A-Za-z0-9_$])'),
  RegExp(r'(?<![A-Za-z0-9_$])FileType\s*\.\s*custom(?![A-Za-z0-9_$])'),
  RegExp(r'(?<![A-Za-z0-9_$])mimeType(?![A-Za-z0-9_$])'),
  RegExp(r'''\.\s*endsWith\s*\(\s*['"]\.(pdf|jpg|jpeg|png|heic)['"]'''),
];

/// **R-21** — no code path may reject a picked file on the basis of its
/// extension or MIME type.
///
/// ## Repo-wide, and that is the whole point
///
/// v1.0 scoped this scan to `lib/presentation/forms/` — where, since § 4.3
/// commits that F0 builds **no upload widget**, a picker call cannot appear by
/// construction. It was worse than vacuous. The real risk surface is F1's
/// `features/certificates/`, which `F0-AC-23` says will not exist during F0, so
/// the guard must be repo-wide to be **inherited** at all.
///
/// ## What it is defending
///
/// In HTML `accept` filters the picker's default view and rejects nothing;
/// the client performs no MIME or size validation anywhere. In Flutter
/// `FileType.custom` + `allowedExtensions` is a hard filter, so porting the
/// five `accept` strings as `allowedExtensions` diverges on **all five** pages
/// — Birth's `image/*,application/pdf` becomes a rejection the web does not
/// have too. Resident is the loudest instance of a general error, not a special
/// case (specs.md § 6.6.1).
///
/// The binding requirement F1–F3 inherit: **a `.pdf` selected on the Resident
/// form must reach the attachment list.**
List<String> pickerRejectionViolations(List<DartFile> files) {
  final List<String> violations = <String>[];

  for (final DartFile file in files) {
    final List<String> lines = blankComments(file.source).split('\n');
    for (int i = 0; i < lines.length; i++) {
      for (final RegExp form in kPickerRejectionForms) {
        if (form.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1} -> ${lines[i].trim()}');
          break;
        }
      }
    }
  }

  return violations;
}

// ─────────────────────────────────────────────────────────────────────────────
// RULING 2 — the kernel is ONE kernel, with zero variants (F0b, `F0-AC-22`)
// ─────────────────────────────────────────────────────────────────────────────

/// The six names a **fork of the kernel** would arrive under.
///
/// Every one of them is a real symbol in the port source, and every one of them
/// is a *call shape* of the same two controls rather than a control of its own:
///
/// | Source symbol | What it actually is |
/// |---|---|
/// | `InputField` (`formFields.tsx:60`) | `FieldBase` + a `<input>`; the kernel's `FieldBase` with a text child |
/// | `SelectField` (`:113`) | `SearchableSelect` with `failed`/`onRetry`/`emptyMessage` **omitted** |
/// | `TextAreaField` (`:88`) | `FieldBase` + a multi-line child |
/// | `DatedField` | a `DateField` that has been given a second name |
/// | `ApiLocationFields` (`:409`) | `LocationFieldsView` with the same three parameters omitted |
/// | `UseRefList` / `RefList` | the fetching half of `useReferenceOptions`, which `ssd.md` § 7.2 puts in the page BLoC |
///
/// **Why a name scan and not a review note.** § 6.3.4's fourth row is the whole
/// ruling: Marriage/Divorce's weaker error surface is produced by **omitting**
/// `failed` / `onRetry` / `emptyMessage`, exactly as `formFields.tsx:223` does.
/// The cheap way to get that surface is a second widget, and a second widget is
/// how a kernel becomes two kernels that drift. Nothing else in the tree can
/// see a new `class SelectField extends StatelessWidget` appearing under
/// `lib/presentation/forms/` — it breaks no layering rule and no test.
///
/// Scoped to `lib/presentation/forms/**`, which is where a variant would have
/// to live to be reachable as one. A page-local private helper elsewhere is a
/// different question and F1's to answer.
const List<String> kForbiddenKernelSymbols = <String>[
  'InputField',
  'SelectField',
  'TextAreaField',
  'DatedField',
  'ApiLocationFields',
  'UseRefList',
  'RefList',
];

final RegExp _declarationKeyword = RegExp(
  r'(?<![A-Za-z0-9_$])(class|mixin|extension|enum|typedef)\s+(\w+)',
);

/// **`F0-AC-22`** — no *declaration* under `lib/presentation/forms/**` carries
/// one of [kForbiddenKernelSymbols].
///
/// Declarations only, deliberately. The doc comments in this kernel cite
/// `SelectField` and `ApiLocationFields` by name a dozen times, because
/// explaining that a variant is *not* built requires naming the variant. The
/// scan therefore runs over [DartFile.code] (comments already stripped) and
/// matches a declaration keyword followed by the name, so documenting the rule
/// is not violating it — the same property `guard_selftest_test.dart` already
/// asserts for G-L1…G-L8.
List<String> forbiddenKernelSymbolViolations(
  List<DartFile> files, {
  String scope = 'presentation/forms/',
}) {
  final List<String> violations = <String>[];

  for (final DartFile file in files) {
    if (!file.path.startsWith(scope)) continue;
    final List<String> lines = blankComments(file.source).split('\n');
    for (int i = 0; i < lines.length; i++) {
      for (final RegExpMatch m in _declarationKeyword.allMatches(lines[i])) {
        final String name = m.group(2)!;
        if (kForbiddenKernelSymbols.contains(name)) {
          violations.add('${file.path}:${i + 1} -> ${m.group(1)} $name');
        }
      }
    }
  }

  return violations;
}
