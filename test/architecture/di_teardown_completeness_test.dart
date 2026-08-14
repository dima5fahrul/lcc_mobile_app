/// Every feature container must be reset by the DI tests that call `init()`.
///
/// ## Why this file exists
///
/// This omission has now shipped **five times** — B9a, B9b, B8, and F0b twice
/// over — and every occurrence looked identical:
///
/// > A feature adds `final xInjection = GetIt.asNewInstance();` and wires
/// > `XFeatureInjection.init()` into `DependencyInjection.init()`, but does not
/// > add `await xInjection.reset();` to the `tearDown` of the DI tests. The
/// > first test passes. The second calls `init()` against a container that is
/// > still populated and throws
/// > **`Type ApiClient is already registered inside GetIt`** — roughly thirty
/// > failures at once, every one of them pointing at `ApiClient`, which is not
/// > the problem, instead of at the container that forgot, which is.
///
/// `dependency_injection_test.dart`'s own header **predicted this in prose**
/// before three of the five occurrences:
///
/// > *"Adding a feature container without adding its reset here breaks this
/// > file first and loudly, which is the behaviour that caught it."*
///
/// It was accurate every time and prevented none of them. A documented hazard
/// that keeps recurring is a **missing guard, not a recurring mistake** — prose
/// that is right but unexecuted is not a gate. That is the whole reason this
/// file exists rather than a sixth paragraph in that header.
///
/// ## What it asserts, and why it is derived rather than listed
///
/// The container set is **recomputed from the source on every run** by scanning
/// `lib/features/*/di/**` for `GetIt.asNewInstance()`. A hand-maintained list
/// would go stale in exactly the way the tearDowns went stale — the same defect
/// wearing a different hat — so the guard must not contain one.
///
/// The failure message **names the container**, because the entire cost of this
/// defect was five rounds of an error that named `ApiClient`.
///
/// ## Its own non-vacuity
///
/// A scan that finds no containers passes trivially. The last test pins the
/// discovered count as non-empty and prints it, so an empty scan reads as a
/// broken scanner rather than as a clean tree — `FACTORY-RULES.md`'s Capability
/// Rule applied to the guard itself.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files whose `tearDown` must reset every container, because each calls
/// `DependencyInjection.init()` more than once across its tests.
const List<String> kDiTestFiles = <String>[
  'test/core/di/dependency_injection_test.dart',
  'test/features/news/di/news_injection_test.dart',
  'test/features/home/di/home_injection_test.dart',
];

/// `final xInjection = GetIt.asNewInstance();`
final RegExp _declaration = RegExp(
  r'final\s+(\w+)\s*=\s*GetIt\.asNewInstance\(\)',
);

/// Every `xInjection` declared anywhere under `lib/features/*/di/`.
Map<String, String> discoverContainers() {
  final Map<String, String> found = <String, String>{};
  final Directory features = Directory('lib/features');
  if (!features.existsSync()) return found;

  for (final FileSystemEntity entity in features.listSync()) {
    if (entity is! Directory) continue;
    final Directory di = Directory('${entity.path}/di');
    if (!di.existsSync()) continue;

    for (final FileSystemEntity file in di.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final RegExpMatch m
          in _declaration.allMatches(file.readAsStringSync())) {
        found[m.group(1)!] = file.path;
      }
    }
  }
  return found;
}

void main() {
  group('DI teardown completeness — the fifth-occurrence guard', () {
    final Map<String, String> containers = discoverContainers();

    for (final String path in kDiTestFiles) {
      test('$path resets every feature container', () {
        final File file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'NOT EVALUATED — $path does not exist, so this guard checked '
              'nothing. If the file moved, update kDiTestFiles; do not delete '
              'this assertion.',
        );

        final String src = file.readAsStringSync();
        final List<String> missing = <String>[];
        for (final MapEntry<String, String> e in containers.entries) {
          if (!src.contains('${e.key}.reset()')) {
            missing.add('${e.key}  (declared in ${e.value})');
          }
        }

        expect(
          missing,
          isEmpty,
          reason: 'These containers are created but never reset in $path:\n'
              '  ${missing.join('\n  ')}\n\n'
              'The second call to DependencyInjection.init() in that file will '
              'throw "Type ApiClient is already registered inside GetIt" and '
              'take down every test after it. The message will name ApiClient. '
              'ApiClient is not the problem — the container above is.\n\n'
              'Fix: add `await <container>.reset();` to that file\'s tearDown, '
              'and import it. This has now happened five times; the guard '
              'exists so it is six lines of work instead of an afternoon.',
        );
      });
    }

    test('the scan is not vacuous — containers were actually discovered', () {
      // Printed unconditionally: a passing guard with no number is what this
      // whole discipline exists to stop.
      // ignore: avoid_print
      print('DI containers discovered under lib/features/*/di/: '
          '${containers.length} — ${(containers.keys.toList()..sort()).join(', ')}');

      expect(
        containers,
        isNotEmpty,
        reason: 'NOT EVALUATED — the scanner found zero containers under '
            'lib/features/*/di/, so every assertion above passed against an '
            'empty set. Either the declaration pattern changed from '
            '`GetIt.asNewInstance()` or the directory layout moved. A guard '
            'that finds nothing is not a guard that found nothing wrong.',
      );
    });
  });
}
