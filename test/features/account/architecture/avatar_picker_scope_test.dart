/// **S-2 and the send-raw ruling, asserted against the SOURCE TEXT.**
///
/// ## Why a source scan and not a behavioural test
///
/// `pickAvatarFile()` calls `FilePicker.platform.pickFiles`, a plugin method
/// channel. No headless test invokes it — the whole point of the
/// [AvatarFilePicker] seam is that tests inject a fake instead — so
/// `avatar_picker.dart` measures **0 % line coverage** and every behavioural
/// case in this batch runs past it. That is the right design and it leaves a
/// real hole: the one line that decides what the OS picker will accept is the
/// one line nothing executes.
///
/// The Capability Rule question, asked of the existing gates: *what would fail
/// if somebody added `type: FileType.image` here tomorrow?*
///
/// * `flutter analyze` — nothing. It is a valid argument.
/// * `flutter test` — nothing. No case reaches the call.
/// * **R-21's repo-wide guard** (`layering_rules.dart`'s
///   `pickerRejectionViolations`) — nothing. Its four patterns are
///   `allowedExtensions`, `FileType.custom`, `mimeType` and an
///   `endsWith('.pdf')`-shaped test. **`FileType.image` matches none of them**,
///   because F0b wrote the guard against the five certificate forms, whose
///   `accept` strings were `image/*,application/pdf` — the trap there was
///   `custom`, not `image`.
/// * `security-review-b8b.md` § 12(a) **S-2** — a sentence in a document.
///
/// So the answer today is "nothing", and the citizen quietly loses the ability
/// to upload the `.pdf` or `.heic` the web would have accepted. This file is
/// the gate that fires instead.
///
/// ## The same question for the send-raw ruling
///
/// `image_picker`'s `imageQuality` / `maxWidth` / `maxHeight` re-encode and drop
/// EXIF as a side effect — `security-review-b8b.md` § 4.2 calls that *"the
/// sharpest remaining implementation hazard in the batch"*. `file_picker` has no
/// such parameter, so the hazard arrives only with the package; the scan below
/// checks the package is absent from the feature **and** from `pubspec.yaml`.
///
/// `tier0_avatar_payload_test.dart` covers the other half — that the bytes
/// which reach the wire are the bytes that were picked — behaviourally, and
/// with an observed mutation. Between them the ruling is enforced at both ends.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The file whose one call site this is about.
const String _picker =
    'lib/features/account/presentation/widgets/avatar_picker.dart';

/// The call the port must reproduce — `resident_fields.dart:59-63`.
const String _oracleCall =
    'lib/features/certificates/presentation/resident/resident_fields.dart';

/// The body of the first `pickFiles( … )` call in [source], comments stripped.
///
/// Comments are stripped for the reason `layering_rules.dart`'s G-L5 scan
/// strips them: this file's own prose names `FileType.image` and
/// `allowedExtensions` several times, and a scan that read comments would fail
/// on its own documentation.
String _pickFilesArgs(String source) {
  final String code = source
      .split('\n')
      .map((String l) {
        final int i = l.indexOf('//');
        return i == -1 ? l : l.substring(0, i);
      })
      .join('\n');

  final int open = code.indexOf('pickFiles(');
  expect(open, isNonNegative, reason: 'no `pickFiles(` call found at all — '
      'this scan must not pass by finding nothing');

  int depth = 0;
  for (int i = open + 'pickFiles('.length - 1; i < code.length; i++) {
    if (code[i] == '(') depth++;
    if (code[i] == ')') {
      depth--;
      if (depth == 0) {
        return code.substring(open + 'pickFiles('.length, i);
      }
    }
  }
  fail('unbalanced parentheses after `pickFiles(`');
}

void main() {
  late String pickerSource;

  setUpAll(() {
    pickerSource = File(_picker).readAsStringSync();
  });

  group('S-2 — the picker rejects nothing (R-21)', () {
    test('THE CRITERION — `pickFiles` is passed `withData` and NOTHING else',
        () {
      final String args = _pickFilesArgs(pickerSource);

      // Named arguments actually present, in order.
      final List<String> named = RegExp(r'(\w+)\s*:')
          .allMatches(args)
          .map((RegExpMatch m) => m.group(1)!)
          .toList();

      expect(
        named,
        <String>['withData'],
        reason: 'B8b must reproduce `resident_fields.dart:59-63` exactly. '
            '`accept="image/*"` at `AccountPage.tsx:344` filters what the OS '
            'picker SHOWS and rejects nothing — a citizen who navigates to a '
            '`.pdf` can still choose it and the web will upload it. Any '
            '`type:` or `allowedExtensions:` here is a capability the citizen '
            'loses, i.e. L-10(b).',
      );
      expect(args, contains('withData: true'));
    });

    test('specifically: no `FileType` of any kind — the form R-21\'s repo-wide '
        'guard cannot see', () {
      // `kPickerRejectionForms` catches `FileType.custom` and never plain
      // `FileType.image`. Asserted here on the whole file's code, not just the
      // call, so a `const type = FileType.image;` above it fails too.
      final String code = pickerSource
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('///'))
          .map((String l) {
            final int i = l.indexOf('//');
            return i == -1 ? l : l.substring(0, i);
          })
          .join('\n');

      expect(code, isNot(contains('FileType')));
      expect(code, isNot(contains('allowedExtensions')));
    });

    test('THE CONTROL — the scan is looking at a real call, and the oracle '
        'call it claims to match really does look like this', () {
      // Without this, both cases above pass against an empty file, a renamed
      // method, or a `_pickFilesArgs` that silently returned ''. And the claim
      // "reproduces resident_fields.dart" is checked rather than asserted.
      expect(pickerSource, contains('FilePicker.platform.pickFiles'));

      final String oracleArgs =
          _pickFilesArgs(File(_oracleCall).readAsStringSync());
      final List<String> oracleNamed = RegExp(r'(\w+)\s*:')
          .allMatches(oracleArgs)
          .map((RegExpMatch m) => m.group(1)!)
          .toList();

      expect(oracleNamed, <String>['withData'],
          reason: 'if F1 ever adds an argument to its picker, this batch must '
              'find out from a failure here rather than from a citizen');
      expect(
        _pickFilesArgs(pickerSource).replaceAll(RegExp(r'\s'), ''),
        oracleArgs.replaceAll(RegExp(r'\s'), ''),
        reason: 'the two calls are textually the same modulo whitespace',
      );
    });
  });

  group('the send-raw ruling — no re-encode can enter through a parameter', () {
    test('`image_picker` is absent from the feature AND from pubspec.yaml', () {
      // Two independent grounds, both in `security-review-b8b.md`: its iOS
      // `NSPhotoLibraryUsageDescription` requirement is an `ios/**` edit, which
      // specs.md § 8.3 item 2 makes BLOCKED-not-widened; and its
      // `imageQuality:` re-encodes, dropping EXIF without anyone deciding to.
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('image_picker')),
          reason: 'B8-AC-57 as amended: B8b adds ZERO dependencies');
      expect(pubspec, contains('file_picker:'),
          reason: 'and the picker it does use has been here since F1 — if this '
              'ever fails, the amendment\'s premise is gone');
    });

    test('no re-encode parameter appears anywhere under features/account/', () {
      final List<String> offenders = <String>[];
      for (final FileSystemEntity e
          in Directory('lib/features/account').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final String code = e
            .readAsStringSync()
            .split('\n')
            .where((String l) => !l.trimLeft().startsWith('///'))
            .map((String l) {
              final int i = l.indexOf('//');
              return i == -1 ? l : l.substring(0, i);
            })
            .join('\n');
        for (final String p in <String>[
          'imageQuality',
          'maxWidth',
          'maxHeight',
          'decodeImage',
          'encodeJpg',
        ]) {
          if (code.contains(p)) offenders.add('${e.path}: $p');
        }
      }

      expect(offenders, isEmpty,
          reason: 'the file is transmitted byte-identical to what the picker '
              'returned (security-review-b8b.md § 12(a) S-4). Stripping EXIF '
              'is forbidden by L-10(b) — the port may not degrade BETTER than '
              'the source either — and the realistic way it happens is a '
              'parameter added to keep uploads small.');
    });
  });
}
