/// **B2-AC-11** — no raw colour literal outside `lib/presentation/theme/`.
///
/// specs.md § 6.2 states the rule and then states why it is a *test* rather
/// than a review comment: fidelity Tier 2 compares the web's tokens against the
/// Flutter theme as values, and a value that is written inline in a widget body
/// is not in the theme, so Tier 2 cannot see it. `#344EAD` used to appear as a
/// hardcoded `Color(0xFF344EAD)` in 20+ widget bodies — the gate could not
/// return an answer at all. A reviewer catching the 21st is not a mechanism;
/// this is.
///
/// ## Two literal forms, one rule
///
/// * `Color(0x…)` — a hex constructor.
/// * `Colors.<name>` — Material's stock palette. Whole-identifier matched, so
///   `AppColors.white` (the token) does **not** trip it while a bare
///   `Colors.white` does. That distinction is the entire point: the offence is
///   naming a colour that the theme does not own, not the substring `Colors.`.
///
/// `Color.fromARGB` / `Color.fromRGBO` are deliberately **not** matched. Both
/// take computed channels — `AppColors.shade()` is built on `fromARGB` — and a
/// rule that banned them would ban the arithmetic the theme itself performs.
/// A literal written that way would evade this scan; that is a known and
/// accepted gap, recorded here rather than papered over, because every literal
/// the port actually produces is written in one of the two forms above.
///
/// ## The grandfather list is closed
///
/// SSD § 10.1's exemption covers `features/auth/presentation/**` only, and its
/// members are enumerated below **file by file** so the list cannot silently
/// grow: adding a colour literal to a new auth file fails this test, and the
/// only sanctioned fix is to convert the file to tokens. The trigger for
/// conversion is unchanged — whenever an auth page is unfrozen for another
/// reason, its literals convert in the same change. The auth forms are frozen
/// today (§ 4.2), which is why they are exempt and not simply fixed.
///
/// New code has no exemption, at all, ever.
library;

import 'package:flutter_test/flutter_test.dart';

import 'layering_rules.dart';

/// The only directory allowed to hold a raw colour literal.
const String _themeDir = 'presentation/theme';

/// **The closed grandfather list** (SSD § 10.1). Ten files, every one under
/// `features/auth/presentation/**`, measured 2026-08-13. Named individually —
/// a glob would let the eleventh file join without anyone deciding to let it.
const Set<String> _grandfathered = <String>{
  'features/auth/presentation/pages/auth_page.dart',
  'features/auth/presentation/pages/login_form.dart',
  'features/auth/presentation/pages/otp_form.dart',
  'features/auth/presentation/pages/register_form.dart',
  'features/auth/presentation/pages/reset_form.dart',
  'features/auth/presentation/widgets/api_notice.dart',
  'features/auth/presentation/widgets/cta_button.dart',
  'features/auth/presentation/widgets/field_error.dart',
  'features/auth/presentation/widgets/field_label.dart',
  'features/auth/presentation/widgets/password_strength.dart',
};

final RegExp _hexConstructor = RegExp(r'(?<![A-Za-z0-9_$])Color\(\s*0x');
final RegExp _materialPalette =
    RegExp(r'(?<![A-Za-z0-9_$])Colors\.[a-zA-Z]');

/// Every `line:snippet` in [file] that holds a raw colour literal.
List<String> _literalsIn(DartFile file) {
  final List<String> hits = <String>[];
  final List<String> lines = file.code.split('\n');

  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];
    if (_hexConstructor.hasMatch(line) || _materialPalette.hasMatch(line)) {
      hits.add('${file.path}:${i + 1} -> ${line.trim()}');
    }
  }

  return hits;
}

void main() {
  late final List<DartFile> files;

  setUpAll(() {
    files = scanTree(kLibDir);
    expect(files, isNotEmpty, reason: 'the scanner found nothing to inspect');
  });

  test('B2-AC-11 — no raw colour literal outside presentation/theme/', () {
    final List<String> offenders = <String>[];

    for (final DartFile file in files) {
      if (file.path.startsWith('$_themeDir/')) continue;
      if (_grandfathered.contains(file.path)) continue;
      offenders.addAll(_literalsIn(file));
    }

    expect(
      offenders,
      isEmpty,
      reason: 'specs.md § 6.2 / SSD § 10.1: every colour the app draws with is '
          'a named token in `lib/presentation/theme/app_colors.dart`, because '
          'that file is the only thing fidelity Tier 2 can read. Move the '
          'value there and cite the source line it came from. If the colour '
          'arrives from the API at runtime (`Service.color`, '
          '`ServiceCategory.color`), it is DATA and must not be transcribed as '
          'a constant at all — parse it at the edge and pass it down.'
          '\nOffenders:\n  ${offenders.join('\n  ')}',
    );
  });

  test('the grandfather list is exact — no dead entries, no silent growth', () {
    final Set<String> paths = files.map((DartFile f) => f.path).toSet();

    // (a) Every listed file still exists. A stale entry is an exemption
    //     nobody is watching.
    final Set<String> missing = _grandfathered.difference(paths);
    expect(
      missing,
      isEmpty,
      reason: 'These grandfathered files no longer exist. Delete their entries '
          'in the same change that deleted them.\n  ${missing.join('\n  ')}',
    );

    // (b) Every listed file still actually contains a literal. Once an auth
    //     file is converted to tokens its exemption must be removed, or the
    //     list slowly becomes a permanent carve-out for a solved problem.
    final List<String> converted = _grandfathered
        .where((String p) =>
            _literalsIn(files.firstWhere((DartFile f) => f.path == p)).isEmpty)
        .toList(growable: false);
    expect(
      converted,
      isEmpty,
      reason: 'These files hold no colour literal any more — they have been '
          'converted. Remove them from the list; the list is closed and it '
          'only ever shrinks.\n  ${converted.join('\n  ')}',
    );

    // (c) Every listed file is under the one exempt subtree.
    final List<String> outside = _grandfathered
        .where((String p) => !p.startsWith('features/auth/presentation/'))
        .toList(growable: false);
    expect(
      outside,
      isEmpty,
      reason: 'SSD § 10.1 scopes the exemption to '
          '`features/auth/presentation/**` and nothing else.\n  '
          '${outside.join('\n  ')}',
    );
  });

  test('the theme itself is where the literals live (a positive control)', () {
    // If this ever goes empty, the scan above is passing because it found
    // nothing rather than because the tree is clean — the same trivial-pass
    // hazard `layering_test.dart`'s `isNotEmpty` check exists to catch.
    final List<String> inTheme = files
        .where((DartFile f) => f.path.startsWith('$_themeDir/'))
        .expand(_literalsIn)
        .toList(growable: false);

    expect(inTheme, isNotEmpty);
  });
}
