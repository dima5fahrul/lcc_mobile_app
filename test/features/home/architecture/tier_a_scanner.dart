/// The **B2-AC-31 scanner** — every bundled-image call site in a tree, with the
/// asset it names and whether it constrained the decode.
///
/// Split out of the test for the same reason `layering_rules.dart` was split
/// out of `layering_test.dart`: the negative control has to run **this**
/// function against a violating fixture, not a copy of it. A self-test that
/// re-implements the rule proves a copy fires and says nothing about the guard
/// the build actually runs, which is the vacuity § 6.7.7 exists to close.
library;

import '../../../architecture/layering_rules.dart';

/// The eleven Tier A assets, B1b § 6.3's table.
///
/// Keyed by bundled path, because that is what a call site names. Written here
/// rather than imported from `tier_a_image.dart` **on purpose**: the production
/// list is the eight slides plus two backdrops the app actually uses, and this
/// is the *tier* — including `user-photo`, which no B2 surface may render at
/// all (B2-AC-42 item 4, V-16/V-17). A guard that read its own subject from the
/// code it guards would go quiet the moment someone deleted an entry.
const Set<String> kTierAAssetPaths = <String>{
  // 8 category slides — 864×1152 each (rows 1-8)
  'assets/images/civil-population.webp',
  'assets/images/immigration.webp',
  'assets/images/land-property.webp',
  'assets/images/health.webp',
  'assets/images/social-protection.webp',
  'assets/images/education.webp',
  'assets/images/transport.webp',
  'assets/images/tax-payment.webp',
  // row 9 — 1600×818 native
  'assets/images/hero-bg.webp',
  // row 10 — 1000×585 native
  'assets/images/bg-id.webp',
  // row 11 — 288×384. Not rendered by any B2 surface; listed so that a call
  // site that starts rendering it is caught by this guard as well as by the
  // security review.
  'assets/images/user-photo.webp',
};

/// The five Tier B marks (B1b § 6.3 rows 12-16).
///
/// They ship a 1x/2.0x/3.0x ladder, so Flutter's resolution-aware `AssetImage`
/// picks the right rung *and* decodes it at the right size with no call-site
/// discipline — B1b § 6.4's explicit carve-out. Named here so the guard can
/// assert it is looking at a tree that contains **both** tiers: a scanner that
/// found no Tier B call sites either would be passing because it parses
/// nothing.
const Set<String> kTierBAssetPaths = <String>{
  'assets/images/logo-lcc.webp',
  'assets/images/moha-sm.webp',
  'assets/images/mops-sm.webp',
  'assets/images/edl-logo.webp',
  'assets/images/nampapa-logo.webp',
};

/// One `Image.asset(...)` / `AssetImage(...)` call found in the source.
class ImageCallSite {
  const ImageCallSite({
    required this.path,
    required this.line,
    required this.constructor,
    required this.asset,
    required this.hasCacheWidth,
    required this.hasCacheHeight,
  });

  /// Scan-root-relative file, e.g. `features/home/presentation/widgets/x.dart`.
  final String path;

  final int line;

  /// `Image.asset` or `AssetImage`.
  final String constructor;

  /// The asset string literal the call names, or null when the argument is not
  /// a literal — see [ImageCallSite.isTierA]'s note.
  final String? asset;

  final bool hasCacheWidth;
  final bool hasCacheHeight;

  /// True when this call site loads an asset on the Tier A list.
  ///
  /// A call whose first argument is **not** a string literal (a variable, a
  /// field, an interpolation) returns false and is reported separately by
  /// [unresolvedTierACandidates] rather than silently passing: the scanner
  /// cannot see through a variable, and a guard that treated "I could not tell"
  /// as "it is fine" would be defeated by `Image.asset(myPath)`.
  bool get isTierA => asset != null && kTierAAssetPaths.contains(asset);

  bool get isTierB => asset != null && kTierBAssetPaths.contains(asset);

  /// B1b § 6.4 says `cacheWidth`/`cacheHeight`. Either bounds the decode —
  /// Flutter derives the other from the asset's aspect — so either satisfies
  /// it, and requiring both would fail a correct call site.
  bool get constrainsDecode => hasCacheWidth || hasCacheHeight;

  String get citation => '$path:$line -> $constructor(${asset ?? '<dynamic>'})';
}

final RegExp _imageCall = RegExp(
  r'(?<![A-Za-z0-9_$.])(Image\.asset|AssetImage)\s*\(',
);

/// Reads the balanced argument list starting at the `(` at [open].
///
/// Naive `indexOf(')')` would stop at the first nested call — and every real
/// call site here has one (`BorderRadius.circular(...)`, a `math.min(...)` in
/// the `cacheWidth` expression), so a naive scan would report *no* `cacheWidth`
/// on a call site that has one. Strings are skipped so a `)` inside an asset
/// path cannot end the list early.
String _argumentList(String source, int open) {
  int depth = 0;
  int i = open;
  final StringBuffer out = StringBuffer();

  while (i < source.length) {
    final String c = source[i];

    if (c == "'" || c == '"') {
      final int start = i;
      i++;
      while (i < source.length && source[i] != c) {
        if (source[i] == r'\') i++;
        i++;
      }
      i++;
      out.write(source.substring(start, i.clamp(0, source.length)));
      continue;
    }

    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return out.toString();
    }
    out.write(c);
    i++;
  }

  // Unbalanced — return what we have; the caller treats a missing keyword as
  // absent, which fails closed.
  return out.toString();
}

final RegExp _firstStringLiteral = RegExp('''['"]([^'"]*)['"]''');
final RegExp _cacheWidthArg =
    RegExp(r'(?<![A-Za-z0-9_$])cacheWidth\s*:');
final RegExp _cacheHeightArg =
    RegExp(r'(?<![A-Za-z0-9_$])cacheHeight\s*:');

/// Every bundled-image call site under [dir].
///
/// Runs over **comment-stripped** source ([DartFile.code]) for the reason
/// `layering_rules.dart` gives: this file's own library doc quotes
/// `Image.asset(..., cacheWidth: …)` while explaining the rule, and a raw-text
/// scan would report the documentation as a call site.
List<ImageCallSite> scanImageCalls(String dir) {
  final List<ImageCallSite> sites = <ImageCallSite>[];

  for (final DartFile file in scanTree(dir)) {
    final String code = file.code;

    for (final RegExpMatch match in _imageCall.allMatches(code)) {
      final int open = match.end - 1;
      final String args = _argumentList(code, open);

      final RegExpMatch? literal = _firstStringLiteral.firstMatch(args);
      // 1-based line of the call, counted on the stripped source. Comment
      // stripping preserves newlines (only comment *bodies* go), so the number
      // matches the file.
      final int line = '\n'.allMatches(code.substring(0, open)).length + 1;

      sites.add(ImageCallSite(
        path: file.path,
        line: line,
        constructor: match.group(1)!,
        asset: literal?.group(1),
        hasCacheWidth: _cacheWidthArg.hasMatch(args),
        hasCacheHeight: _cacheHeightArg.hasMatch(args),
      ));
    }
  }

  return sites;
}

/// **The rule.** Tier A call sites that did not constrain their decode.
List<String> tierAViolations(List<ImageCallSite> sites) => sites
    .where((ImageCallSite s) => s.isTierA && !s.constrainsDecode)
    .map((ImageCallSite s) => s.citation)
    .toList(growable: false);

/// Call sites whose asset the scanner could not resolve to a literal.
///
/// Reported as a **separate** failure rather than folded into
/// [tierAViolations], because they are a different problem with a different
/// fix: the rule is not broken, the guard has been blinded.
///
/// Exactly one such site is expected and is **not** a hole —
/// [kSanctionedDynamicLoader]'s. See its doc.
List<String> unresolvedTierACandidates(List<ImageCallSite> sites) => sites
    .where((ImageCallSite s) => s.asset == null)
    .map((ImageCallSite s) => s.citation)
    .toList(growable: false);

/// The one file allowed to call `Image.asset` with a non-literal path.
///
/// `TierAImage` is generic over a [TierAAsset] descriptor, so its own call
/// reads `Image.asset(asset.path, …)` — a variable, which this scanner cannot
/// resolve. That is not a blind spot to close but the shape of the fix: the
/// helper exists precisely so the eleven paths are named **once**, in a
/// descriptor table, instead of eleven times at eleven call sites.
///
/// The guard covers it from the other side. [tierAPathLiterals] finds every
/// place a Tier A path is *written*, and the test asserts they are all in this
/// file — so a path can only reach `Image.asset` through the helper, and the
/// helper's own call site is checked to constrain its decode like any other.
const String kSanctionedDynamicLoader =
    'features/home/presentation/widgets/tier_a_image.dart';

/// Every file under [dir] that writes a Tier A asset path as a string literal,
/// with the path it wrote and the line.
///
/// The complement of [scanImageCalls]: that one asks "does this *call*
/// constrain its decode", this one asks "where could a Tier A asset even be
/// named". Together they close the loop — a path that appears nowhere but the
/// descriptor table cannot be loaded except through [TierAImage].
List<String> tierAPathLiterals(String dir) {
  final List<String> found = <String>[];

  for (final DartFile file in scanTree(dir)) {
    final List<String> lines = file.code.split('\n');
    for (int i = 0; i < lines.length; i++) {
      for (final String asset in kTierAAssetPaths) {
        if (lines[i].contains("'$asset'") || lines[i].contains('"$asset"')) {
          found.add('${file.path}:${i + 1} -> $asset');
        }
      }
    }
  }

  return found;
}
