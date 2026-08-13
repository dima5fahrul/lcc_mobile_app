/// **G-L1 … G-L5** — the layering guards defined in SSD § 4.7.
///
/// Five directory scans over `lib/**/*.dart` (excluding `*.freezed.dart` and
/// `*.g.dart`, which are generated and follow their source file's placement).
/// Each one fails the suite with a `path:line -> uri` list, so a violation
/// names itself rather than making a reviewer diff two trees.
///
/// | Guard | Assertion | Enforces |
/// |---|---|---|
/// | G-L1 | no file under `presentation/` (either kind) imports `**/data/**` | § 3.2 |
/// | G-L2 | no file under `**/domain/**` imports `**/data/**` or `**/presentation/**` | § 3.2 |
/// | G-L3 | no file under `features/A/**` imports `features/B/{data,presentation}/**`, A ≠ B | CFI (§ 4.3) |
/// | G-L4 | no file under `lib/core/**` imports `package:flutter/{material,widgets}.dart` or `features/*/{data,presentation}/**` | § 4.4, § 4.5 |
/// | G-L5 | no file under `lib/presentation/**` or `features/*/presentation/**` names `injection` / `authInjection` / `sessionInjection`, or imports a `**/di/**` path | CR-1 (§ 6.4) |
///
/// **Why G-L5 exists at all.** CR-1 removed the two global-locator reads that
/// lived inside widgets (`LanguageToggle`'s `storage ?? injection<...>()` and
/// `AuthPage.initState`'s `authInjection<AuthBloc>()`). That was a one-time
/// cleanup; B2 adds five more pages, each needing a BLoC, and the cheapest way
/// to give a new page one is the pattern that was just deleted. G-L5 is what
/// makes the fix permanent: the sanctioned seam is "route builders and
/// `main.dart` may resolve from a locator, no widget may", and this test is the
/// half of that sentence a compiler cannot express.
///
/// ## Three implementation choices worth knowing about
///
/// **1. Imports are matched as resolved paths, not as substrings.** Every
/// import in `lib/` today is *relative* (`../../core/storage/...`), so a naive
/// `contains('/data/')` would miss `import '../models/x.dart'` from a sibling
/// directory and would fire on an unrelated package whose name happens to
/// contain the word. [_Import.target] is the URI resolved against the importing
/// file's own directory and expressed relative to `lib/`, and every rule below
/// matches whole path *segments* of that. `package:lcc_mobile_app/...` is
/// resolved too, so the guards keep working if the codebase ever switches
/// import style.
///
/// **2. The G-L5 identifier scan runs on source with comments stripped**, via
/// [_stripComments]. This is not defensive polish — it is load-bearing right
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
/// lands, [_Import] parsing is the one place to widen.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

/// One `import` directive: the literal URI, the 1-based line it sits on, and
/// [target] — the URI resolved to a `lib/`-relative path, or null for `dart:`
/// and third-party `package:` imports, which no guard here constrains by path.
class _Import {
  const _Import({required this.uri, required this.line, required this.target});

  final String uri;
  final int line;
  final String? target;
}

/// One non-generated file under `lib/`.
class _DartFile {
  const _DartFile({
    required this.path,
    required this.imports,
    required this.code,
  });

  /// `lib/`-relative, forward slashes — e.g. `core/di/dependency_injection.dart`.
  final String path;

  final List<_Import> imports;

  /// File contents with comments removed. See choice 2 in the library doc.
  final String code;

  /// Imports that resolve inside this package.
  Iterable<_Import> get localImports =>
      imports.where((_Import i) => i.target != null);

  List<String> get segments => path.split('/');

  /// True when [segment] is a whole path segment of [path]. `under('data')`
  /// matches `features/auth/data/models/x.dart` and never `metadata/x.dart`.
  bool under(String segment) => segments.contains(segment);

  /// The owning feature for `features/<name>/...`, else null.
  String? get feature =>
      (segments.length > 1 && segments.first == 'features')
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

/// `flutter test` runs with the package root as its working directory — the
/// same assumption `test/helpers/app_test_harness.dart`'s `JsonFileAssetLoader`
/// already makes when it reads `assets/i18n/*.json` off disk.
const String _libDir = 'lib';

final RegExp _importDirective = RegExp(
  '''^\\s*import\\s+r?['"]([^'"]+)['"]''',
);

bool _isIdentifierChar(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

/// Removes `//` line comments and (nestable) `/* */` block comments, leaving
/// string literals intact. See choice 2 in the library doc for why.
///
/// Raw strings are recognised (`r'...'`) so that a trailing backslash inside
/// one does not swallow the rest of the file as if it were an escape.
String _stripComments(String src) {
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
      final bool isRaw = i > 0 &&
          src[i - 1] == 'r' &&
          (i < 2 || !_isIdentifierChar(src[i - 2]));
      final bool triple =
          i + 2 < n && src[i + 1] == c && src[i + 2] == c;
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

/// Joins a `lib/`-relative directory with a relative import URI, collapsing
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

/// Resolves [uri] as seen from [fromPath] to a `lib/`-relative path, or null
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

List<_DartFile> _scanLib() {
  final Directory dir = Directory(_libDir);
  expect(
    dir.existsSync(),
    isTrue,
    reason: 'Expected to find `$_libDir/` relative to the working directory. '
        '`flutter test` runs from the package root; if this fails, the suite '
        'was launched from somewhere else and these guards scanned nothing.',
  );

  final List<_DartFile> files = <_DartFile>[];

  for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;

    final String path = entity.path.replaceAll(r'\', '/');
    if (!path.endsWith('.dart')) continue;
    // Generated code is excluded by § 4.7: it has no independent placement
    // decision, it inherits its source file's.
    if (path.endsWith('.freezed.dart') || path.endsWith('.g.dart')) continue;

    final String libRelative = path.startsWith('$_libDir/')
        ? path.substring(_libDir.length + 1)
        : path;

    final String source = entity.readAsStringSync();
    final List<String> lines = source.split('\n');
    final List<_Import> imports = <_Import>[];

    for (int i = 0; i < lines.length; i++) {
      final RegExpMatch? match = _importDirective.firstMatch(lines[i]);
      if (match == null) continue;
      final String uri = match.group(1)!;
      imports.add(_Import(
        uri: uri,
        line: i + 1,
        target: _resolveImport(libRelative, uri),
      ));
    }

    files.add(_DartFile(
      path: libRelative,
      imports: imports,
      code: _stripComments(source),
    ));
  }

  files.sort((_DartFile a, _DartFile b) => a.path.compareTo(b.path));

  expect(
    files,
    isNotEmpty,
    reason: 'Scanned `$_libDir/` and found no non-generated Dart files. A '
        'guard that inspects nothing passes trivially, which is worse than '
        'failing — treat this as a broken scanner, not a clean tree.',
  );

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

String _cite(_DartFile file, _Import import) =>
    '${file.path}:${import.line} -> ${import.uri}';

// ─────────────────────────────────────────────────────────────────────────────
// Guards
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late final List<_DartFile> files;

  setUpAll(() {
    files = _scanLib();
  });

  test('G-L1 — no presentation file imports a data/ path', () {
    final List<String> violations = <String>[];

    for (final _DartFile file in files.where((_DartFile f) => f.isPresentation)) {
      for (final _Import import in file.localImports) {
        if (_targetUnder(import.target!, 'data')) {
          violations.add(_cite(file, import));
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'SSD § 3.2: presentation depends on domain, never on data. A '
          'page or BLoC that reaches for a model or a datasource has bound '
          'itself to the wire format. Route the call through a use case and '
          'take the domain entity instead.\nOffenders:\n  '
          '${violations.join('\n  ')}',
    );
  });

  test('G-L2 — no domain file imports a data/ or presentation/ path', () {
    final List<String> violations = <String>[];

    for (final _DartFile file in files.where((_DartFile f) => f.under('domain'))) {
      for (final _Import import in file.localImports) {
        if (_targetUnder(import.target!, 'data') ||
            _targetUnder(import.target!, 'presentation')) {
          violations.add(_cite(file, import));
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'SSD § 3.2: domain is the innermost layer and depends on '
          'nothing outward. Both directions of this edge are defects — a '
          'domain type that knows a model is not portable, and one that knows '
          'a widget is not testable.\nOffenders:\n  '
          '${violations.join('\n  ')}',
    );
  });

  test('G-L3 — no feature imports another feature s data/ or presentation/',
      () {
    final List<String> violations = <String>[];

    for (final _DartFile file in files) {
      final String? from = file.feature;
      if (from == null) continue;

      for (final _Import import in file.localImports) {
        final String? to = _targetFeature(import.target!);
        if (to == null || to == from) continue;
        if (_targetUnder(import.target!, 'data') ||
            _targetUnder(import.target!, 'presentation')) {
          violations.add('[$from → $to] ${_cite(file, import)}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Cross-Feature Isolation (SSD § 4.3): one feature may depend on '
          "another feature's `domain/` — that is the shared-kernel edge `auth "
          '→ session/domain` already relies on — but never on its `data/` or '
          "`presentation/`. Reaching into another feature's models or widgets "
          'welds the two release cycles together.\nOffenders:\n  '
          '${violations.join('\n  ')}',
    );
  });

  test('G-L4 — core imports no Flutter UI and no feature data/ or '
      'presentation/', () {
    const Set<String> forbiddenPackages = <String>{
      'package:flutter/material.dart',
      'package:flutter/widgets.dart',
    };

    final Iterable<_DartFile> coreFiles =
        files.where((_DartFile f) => f.segments.first == 'core');

    // ── The rule as § 4.7 words it ─────────────────────────────────────────
    final List<String> violations = <String>[];

    for (final _DartFile file in coreFiles) {
      for (final _Import import in file.imports) {
        if (forbiddenPackages.contains(import.uri)) {
          violations.add(_cite(file, import));
          continue;
        }
        final String? target = import.target;
        if (target == null) continue;
        if (_targetFeature(target) == null) continue;
        if (_targetUnder(target, 'data') ||
            _targetUnder(target, 'presentation')) {
          violations.add(_cite(file, import));
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'SSD § 4.4 / § 4.5: `lib/core/**` is the layer every feature is '
          'allowed to depend on, so it must not depend on any of them, and it '
          'must stay importable without a widget tree. `material.dart` / '
          "`widgets.dart` in core is how a 'core' utility quietly becomes "
          'un-unit-testable.\nOffenders:\n  ${violations.join('\n  ')}',
    );

    // ── The allowance, stated rather than left implicit ────────────────────
    //
    // § 4.7 phrases G-L4's carve-out as "the single allowed exception is
    // `core/session/bloc/**` → `features/session/domain/**`", and § 6.3's
    // verification #5 claimed the R3 edge would be "the only `core → features`
    // import in the tree". Both are inaccurate as written: the tree holds
    // **nine** `core → features` imports across **two** files —
    //
    //   6 × domain : core/session/bloc/session_bloc.dart      → features/session/domain/**
    //                core/di/dependency_injection.dart        → features/session/domain/**
    //   3 × di     : core/di/dependency_injection.dart        → features/{auth,session}/di/**
    //
    // — and every one of them passes the rule above, because the rule forbids
    // only `{data,presentation}`. So the exception clause is already vacuous
    // for `domain/`, and `core/di → features/*/di` is *unforbidden* rather
    // than *permitted*.
    //
    // That distinction matters for the next reader, so it is pinned here
    // instead of being left to inference. The composition root is the one
    // place that is supposed to know every feature exists — `DependencyInjection
    // .init()` cannot wire `AuthFeatureInjection` without importing it — so
    // `core/di → features/*/di` is a deliberate allowance, not an oversight.
    // Any *other* shape of `core → features` edge is neither forbidden above
    // nor intended, and fails here.
    const Set<String> allowedCoreToFeatureLayers = <String>{'domain', 'di'};

    final List<String> unclassified = <String>[];

    for (final _DartFile file in coreFiles) {
      for (final _Import import in file.localImports) {
        final String target = import.target!;
        if (_targetFeature(target) == null) continue;
        final String? layer = _targetFeatureLayer(target);
        if (!allowedCoreToFeatureLayers.contains(layer)) {
          unclassified.add('[layer=$layer] ${_cite(file, import)}');
        }
      }
    }

    expect(
      unclassified,
      isEmpty,
      reason: 'A `core → features/**` import landed in a layer that is '
          'neither `domain/` (the shared kernel, imported not edited) nor '
          '`di/` (the composition root wiring features together). Those two '
          'are the whole allowance. Adding a third means core has grown a '
          'dependency on a feature\'s internals — change the design or widen '
          'this set deliberately, in the SSD first.\nOffenders:\n  '
          '${unclassified.join('\n  ')}',
    );
  });

  test('G-L5 — no presentation file resolves from a global locator', () {
    // Exactly the three container names in the codebase: the root `injection`
    // and the two feature-scoped `GetIt.asNewInstance()` containers.
    const List<String> locators = <String>[
      'injection',
      'authInjection',
      'sessionInjection',
    ];

    final List<String> violations = <String>[];

    for (final _DartFile file in files.where((_DartFile f) => f.isPresentation)) {
      // (a) The import half: a widget file has no business importing DI wiring.
      for (final _Import import in file.localImports) {
        if (_targetUnder(import.target!, 'di')) {
          violations.add('[di import] ${_cite(file, import)}');
        }
      }

      // (b) The identifier half, over comment-stripped source. Whole-identifier
      // matching, so `dependency_injection` and `AuthFeatureInjection` — which
      // are file/class names, not container reads — do not trip it.
      for (final String locator in locators) {
        final RegExp whole = RegExp(
          r'(?<![A-Za-z0-9_$])' + locator + r'(?![A-Za-z0-9_$])',
        );
        if (whole.hasMatch(file.code)) {
          violations.add('[locator `$locator`] ${file.path}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'CR-1 (SSD § 6.4). The seam is: **route builders and `main.dart` '
          'may resolve from a locator; no widget may.** A page needing a BLoC '
          'gets it from a `BlocProvider(create: (_) => xInjection<XBloc>())` in '
          'the route table (`lib/utils/routes/app_routes.dart`); a widget '
          'needing a service takes it as a constructor parameter threaded from '
          'the `ShellRoute` builder. This scales to 21 pages with zero locator '
          'references inside widgets — and every violation below is one more '
          'widget that cannot be pumped in a test without standing a container '
          'up first.\nOffenders:\n  ${violations.join('\n  ')}',
    );
  });
}
