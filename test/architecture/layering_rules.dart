/// The **implementation** of G-L1 … G-L5 — the layering guards defined in
/// SSD § 4.7 — as five pure functions over a scanned directory tree.
///
/// `layering_test.dart` is the production run of these five over `lib/`.
/// `guard_selftest_test.dart` (§ 6.7.7, B2-AC-7) is the negative control: it
/// runs the *same five functions* over the deliberately-violating fixture trees
/// under `fixtures/violations/` and asserts each one reports exactly its
/// fixture's violation.
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
  });

  /// Scan-root-relative, forward slashes — e.g.
  /// `core/di/dependency_injection.dart`.
  final String path;

  final List<DartImport> imports;

  /// File contents with comments removed. See choice 2 in the library doc.
  final String code;

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

final RegExp _importDirective = RegExp(
  '''^\\s*import\\s+r?['"]([^'"]+)['"]''',
);

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
          i > 0 && src[i - 1] == 'r' && (i < 2 || !_isIdentifierChar(src[i - 2]));
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
  final List<String> segments =
      dir.split('/').where((String s) => s.isNotEmpty).toList();
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

    final String rootRelative =
        path.startsWith('$dir/') ? path.substring(dir.length + 1) : path;

    final String source = entity.readAsStringSync();
    final List<String> lines = source.split('\n');
    final List<DartImport> imports = <DartImport>[];

    for (int i = 0; i < lines.length; i++) {
      final RegExpMatch? match = _importDirective.firstMatch(lines[i]);
      if (match == null) continue;
      final String uri = match.group(1)!;
      imports.add(DartImport(
        uri: uri,
        line: i + 1,
        target: _resolveImport(rootRelative, uri),
      ));
    }

    files.add(DartFile(
      path: rootRelative,
      imports: imports,
      code: stripComments(source),
    ));
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

  for (final DartFile file
      in files.where((DartFile f) => f.segments.first == 'core')) {
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

  for (final DartFile file
      in files.where((DartFile f) => f.segments.first == 'core')) {
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
