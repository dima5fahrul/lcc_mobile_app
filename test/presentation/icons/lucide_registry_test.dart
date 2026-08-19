/// **B2-AC-13** — every declared icon asset actually resolves.
///
/// The instrument is `rootBundle.load()`, the same one B1b-AC-8 used for the
/// image set: a declared-but-absent asset is invisible at runtime (it throws
/// only at the call site, on the screen that needs it), so the declaration is
/// checked here rather than being discovered by a citizen.
///
/// This also pins the two halves of § 6.3 that can silently drift apart: the
/// generated registry and the scoped resolver tables in `app_icons.dart`. A
/// scope naming an icon nobody bundled would resolve "successfully" to a blank.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/icons/app_icons.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_registry.g.dart';
import 'package:lcc_mobile_app/presentation/shell/language_toggle.dart';

/// § 2.2 Finding C: distinct `lucide-react` components imported across B2's
/// nine source files.
///
/// **86 → 89 at B8a.** `AccountPage.tsx` imports three glyphs no earlier batch
/// rendered — `Globe` (the Language row, `:606`), `CreditCard` (Payment
/// methods, `:639`) and `LogOut` (Sign out, `:723`) — so the union grew by
/// exactly three and `lucide_registry.g.dart` was regenerated. Verified against
/// `HEAD` as the only three added; total `assets/icons/**` is 33,009 bytes,
/// well inside [kIconByteCeiling]. B8's § 3.1 table does not name this file —
/// a recorded scope deviation, on the same grounds as the DI tearDowns: the
/// page cannot render its own rows without its own glyphs.
/// ── B12: +3 = 92 ────────────────────────────────────────────────────────────
///
/// F4's `blocked.md` B-3 recorded `BookX`, `RotateCcw` and `Crown` as unbundled:
/// `family_book_states.dart` names them and `AppIcons.assetFor` fell back to
/// `FileText`. F4 left it — the icon set was outside its § 3.1 — and noted the
/// consequence would change once the page was reachable.
///
/// B12 made it reachable. A wrong glyph on a page no citizen can open became a
/// wrong glyph on the empty state, which B-3 itself calls the single most
/// visible element on slot 47. Bundled here on that ground.
///
/// ── B8b: +1 = 93 ────────────────────────────────────────────────────────────
///
/// `Camera` — `AccountPage.tsx:19`, rendered at `:354` as the avatar badge's
/// third branch. B8a bundled its own three and **reserved this one for B8b by
/// name** (`tool/generate_lucide_svgs.mjs`), on the ground that a bundled glyph
/// with no renderer is what B9a refused for `deleteNotification`. B8b ships the
/// upload, so the renderer now exists.
///
/// The failure mode this closes is the one F4's B-3 hit above, before it was
/// visible: `AppIcons.assetFor` falls back to `FileText`, so an unbundled
/// `Camera` does not render *nothing* — it renders a **document** on a
/// citizen's avatar, and `B8-AC-55`'s three-way badge would look satisfied to
/// any assertion that only counted `LucideIcon`s.
///
/// Generated, not drawn: `node tool/generate_lucide_svgs.mjs`, reading the
/// in-tree pinned `lucide-react@0.487.0`. `--check` re-run afterwards reports
/// `written 0`, so the output is idempotent and the geometry is the web's own.
const int kLucideUnionSize = 93;

/// § 6.3.3's ceiling for `assets/icons/**` in total.
const int kIconByteCeiling = 120000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('B2-AC-13 assets resolve through rootBundle', () {
    test('the registry holds the 93-name union', () {
      expect(lucideRegistry, hasLength(kLucideUnionSize));
      expect(lucideRegistry.values.toSet(), hasLength(kLucideUnionSize),
          reason: 'two names sharing one asset path would make the byte '
              'ceiling and the fidelity oracle disagree');
    });

    test('the key, the file name and the API token are one string', () {
      // § 6.3.3's whole point: no case-mapping layer exists to get wrong.
      for (final MapEntry<String, String> entry in lucideRegistry.entries) {
        expect(entry.value, 'assets/icons/lucide/${entry.key}.svg');
      }
    });

    test('every registry entry loads with non-zero length', () async {
      final List<String> empty = <String>[];

      for (final String asset in lucideRegistry.values) {
        final ByteData data = await rootBundle.load(asset);
        if (data.lengthInBytes == 0) empty.add(asset);
      }

      expect(empty, isEmpty);
    });

    test('both R-24 flag assets load with non-zero length', () async {
      for (final String asset in <String>[kUkFlagAsset, kLaoFlagAsset]) {
        final ByteData data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(0), reason: asset);
      }
    });

    test('the bundle stays under the 120,000 B ceiling', () async {
      int total = 0;
      for (final String asset in <String>[
        ...lucideRegistry.values,
        kUkFlagAsset,
        kLaoFlagAsset,
      ]) {
        total += (await rootBundle.load(asset)).lengthInBytes;
      }

      expect(total, lessThanOrEqualTo(kIconByteCeiling),
          reason: 'assets/icons/** measured $total B');
    });
  });

  group('the scoped tables and the bundle cannot drift apart', () {
    test('every service-scope name is bundled', () {
      expect(
        AppIcons.serviceScope.difference(lucideRegistry.keys.toSet()),
        isEmpty,
      );
    });

    test('every help-scope name is bundled', () {
      expect(
        AppIcons.helpScope.difference(lucideRegistry.keys.toSet()),
        isEmpty,
      );
    });

    test('the fallback itself is bundled — a missing one would be a blank', () {
      expect(lucideRegistry, contains(AppIcons.fallback));
    });

    test('the scopes are the source s sizes, 54 and 12', () {
      // ServicePage.tsx:104 and HelpCenterPage.tsx:35. If either count moves,
      // the port has stopped matching the registry it was copied from.
      expect(AppIcons.serviceScope, hasLength(54));
      expect(AppIcons.helpScope, hasLength(12));
    });
  });
}
