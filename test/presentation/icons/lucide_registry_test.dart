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
const int kLucideUnionSize = 86;

/// § 6.3.3's ceiling for `assets/icons/**` in total.
const int kIconByteCeiling = 120000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('B2-AC-13 assets resolve through rootBundle', () {
    test('the registry holds the 86-name union', () {
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
