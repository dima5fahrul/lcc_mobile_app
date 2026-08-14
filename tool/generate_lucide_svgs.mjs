#!/usr/bin/env node
//
// generate_lucide_svgs.mjs — B2a lucide icon pipeline
//
// Spec: projects/lcc-mobile-app/docs/greenfield/GOR-245-b2-readonly-surface/
//       specs.md § 6.3.2 (generation contract), § 6.3.3 (bundling),
//       § 6.3.5 (two resolver scopes), § 2.2 Finding C (the 86-name union).
//
// WHAT IT DOES
//   Reads the geometry of 86 lucide icons out of the *in-tree, pinned*
//   `lucide-react@0.487.0` the web application itself renders, and emits
//
//     assets/icons/lucide/<PascalName>.svg          — one SVG per name
//     lib/presentation/icons/lucide_registry.g.dart — name -> asset path
//
// WHY IT LOOKS LIKE THIS (§ 6.3.2, verbatim constraints)
//
//   * Offline. No network fetch, ever. Icon geometry for a government
//     application must have in-tree provenance; a CDN pull at build time does
//     not. Nothing below opens a socket.
//   * Version-asserted. `node_modules/lucide-react/package.json` must read
//     exactly 0.487.0 or this script exits non-zero. A different version is a
//     different glyph set and would silently fork the fidelity oracle.
//   * Deterministic and idempotent. Same input, byte-identical output; a
//     re-run rewrites nothing. Names are emitted in sorted order, attributes
//     in the order lucide declares them, and no timestamp is ever written into
//     an output file.
//   * The name list is explicit (`NAMES` below), not "everything lucide
//     ships", so the bundle cannot grow by accident.
//   * `key:` attributes are dropped — React reconciliation metadata, not
//     geometry.
//   * If `node_modules/lucide-react` is absent (fresh checkout) the script
//     fails with the restoration command. It does NOT run an install: the web
//     tree is read-only under ADR-0001 / § 4.1.
//
// NAME RESOLUTION — why the barrel file and not a kebab-case transform
//
//   The obvious implementation maps `FileText` -> `file-text` with a regex.
//   That is wrong for this package. lucide 0.487.0 re-exports several of the
//   names the web imports under *aliases* whose file names are unrelated:
//
//       Users2      -> icons/users-round.js
//       Globe2      -> icons/earth.js
//       CheckCircle -> icons/circle-check-big.js
//       AlertCircle -> icons/circle-alert.js
//       HelpCircle  -> icons/circle-help.js
//
//   A transform would emit a "Users2.svg" containing whatever `users-2.js`
//   happens to be — a different glyph from the one the web renders, and an
//   invisible fidelity divergence. So the authority is
//   `dist/esm/lucide-react.js`'s own export table, parsed below.
//
// USAGE
//   node tool/generate_lucide_svgs.mjs            # write
//   node tool/generate_lucide_svgs.mjs --check    # verify, write nothing
//
// Run from the Flutter package root (`sources/lcc_mobile_app/`); the script
// resolves every path from its own location, so any cwd works.

import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runInNewContext } from 'node:vm';

// ─────────────────────────────────────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────────────────────────────────────

const REQUIRED_LUCIDE_VERSION = '0.487.0';

const PACKAGE_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const LUCIDE_ROOT = resolve(PACKAGE_ROOT, '../lcc-app/node_modules/lucide-react');
const OUT_SVG_DIR = join(PACKAGE_ROOT, 'assets/icons/lucide');
const OUT_REGISTRY = join(PACKAGE_ROOT, 'lib/presentation/icons/lucide_registry.g.dart');

const RESTORE_COMMAND = 'cd projects/lcc-mobile-app/sources/lcc-app && pnpm install --frozen-lockfile';

/**
 * The 86-name union (§ 2.2 Finding C): every distinct `lucide-react` component
 * imported across B2's nine source files —
 *
 *   HomePage 16 · ServicePage 59 · HelpCenterPage 19 · YourIdPage 10 · Hero 6
 *   · NewsDetailPage 6 · NewsPage 3 · ServiceCard 0 · GlassIcon 0
 *
 * 53 of these are data-driven (the API sends the name); the other 33 are page
 * chrome resolved at compile time. Both kinds are bundled, because a name that
 * only appears in chrome today is still a name a page renders.
 *
 * Sorted, so the emitted registry has a stable, reviewable order.
 *
 * ── B8a: +3 = 89 ────────────────────────────────────────────────────────────
 *
 * `AccountPage.tsx:2-21` imports 18 lucide components. Measured against the
 * 86 above, **three are not bundled**: `CreditCard` (`:16`, the Payment
 * Methods row), `Globe` (`:5`, the Language row) and `LogOut` (`:8`, the
 * sign-out button). `Camera` (`:19`) is B8b's and is deliberately NOT added
 * here — a bundled glyph with no renderer is the shape B9a refused for
 * `deleteNotification`.
 *
 * **`Globe` is NOT `Globe2`.** `Globe2` is already in the list above and is
 * lucide's alias for `icons/earth.js`; `Globe` is `icons/globe.js`, a
 * different drawing. Reusing the bundled one because the name looks close is
 * precisely the invisible fidelity divergence this file's own NAME RESOLUTION
 * note is about.
 *
 * **Recorded scope deviation.** specs.md § 3.1's B8a table does not name
 * `tool/`, `assets/icons/lucide/` or `lib/presentation/icons/`. The
 * alternative was rendering three wrong glyphs on a government identity
 * screen — a divergence no fidelity tier in this project can see (Tier 1 reads
 * text, Tier 2 reads colour tokens, Tier 3 has no reference for this page at
 * all, § 2.2 Finding C). The change is additive, generated and deterministic,
 * the bundle grows from 31,264 B against a 120,000 B ceiling, and neither
 * resolver scope in `app_icons.dart` changes (still 54 and 12). Reported in
 * the hand-back rather than left for a diff to find.
 */
const NAMES = [
  'Accessibility', 'AlertCircle', 'AlertOctagon', 'AlertTriangle', 'ArrowRight',
  'Award', 'Baby', 'BadgeCheck', 'Bell', 'BookOpen', 'Building', 'Building2',
  'Bus', 'Calendar', 'CalendarCheck', 'Car', 'CarFront', 'Check', 'CheckCircle',
  'ChevronDown', 'ChevronLeft', 'ChevronRight', 'ClipboardList', 'Clock',
  'Coins', 'CreditCard', 'Download', 'Eye', 'EyeOff', 'FileCheck2',
  'FileClock', 'FileText',
  'Gavel', 'Globe', 'Globe2', 'GraduationCap', 'Hammer', 'HandCoins', 'HandHeart',
  'Hash', 'Heart', 'HeartCrack', 'HeartHandshake', 'HeartPulse', 'HelpCircle',
  'Home', 'IdCard', 'Landmark', 'LayoutGrid', 'LifeBuoy', 'LogOut', 'Mail',
  'Map',
  'MapPin', 'MapPinned', 'Megaphone', 'MessageCircle', 'Phone', 'PiggyBank',
  'Plane', 'QrCode', 'Receipt', 'RefreshCw', 'Rocket', 'Route', 'School',
  'ScrollText', 'Search', 'Settings2', 'Share2', 'Shield', 'ShieldCheck',
  'Siren', 'Stethoscope', 'StickyNote', 'Store', 'Syringe', 'Tag', 'ThumbsDown',
  'ThumbsUp', 'Tractor', 'User', 'UserCircle', 'UserMinus', 'Users', 'Users2',
  'Wallet', 'X', 'Zap',
];

const EXPECTED_NAME_COUNT = 89; // 86 (B2a) + 3 (B8a: CreditCard, Globe, LogOut)

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

const CHECK_ONLY = process.argv.includes('--check');

function die(message) {
  process.stderr.write(`generate_lucide_svgs: ${message}\n`);
  process.exit(1);
}

/**
 * React prop name -> SVG attribute name.
 *
 * NOT a blanket camelCase-to-kebab transform: `viewBox` is camelCase in SVG
 * itself, and lowering it to `view-box` produces a file that every renderer
 * silently draws at the wrong scale. So the mapping is enumerated, and an
 * unrecognised capital letter is a hard failure rather than a guess — if a
 * future lucide adds `fillRule` to a glyph this batch bundles, the generator
 * stops instead of emitting something subtly wrong.
 */
const ATTRIBUTE_NAMES = {
  strokeWidth: 'stroke-width',
  strokeLinecap: 'stroke-linecap',
  strokeLinejoin: 'stroke-linejoin',
  strokeDasharray: 'stroke-dasharray',
  fillRule: 'fill-rule',
  clipRule: 'clip-rule',
  clipPath: 'clip-path',
  viewBox: 'viewBox',
};

function svgAttribute(attribute) {
  if (Object.hasOwn(ATTRIBUTE_NAMES, attribute)) return ATTRIBUTE_NAMES[attribute];
  if (/[A-Z]/.test(attribute)) {
    die(`unmapped camelCase attribute "${attribute}" — add it to ATTRIBUTE_NAMES deliberately`);
  }
  return attribute;
}

function escapeAttribute(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

/**
 * Returns the balanced literal that starts at the first `[` or `{` after
 * [marker], as source text. Used instead of a regex because a `d="…"` path can
 * legally contain either bracket character inside a string, and because the
 * bundler emits some icon nodes on one line and others across many.
 */
function literalAfter(source, marker, open, close) {
  const at = source.indexOf(marker);
  if (at < 0) return null;

  const start = source.indexOf(open, at + marker.length);
  if (start < 0) return null;

  let depth = 0;
  let inString = null;

  for (let i = start; i < source.length; i++) {
    const c = source[i];
    if (inString) {
      if (c === '\\') i++;
      else if (c === inString) inString = null;
      continue;
    }
    if (c === '"' || c === "'" || c === '`') { inString = c; continue; }
    if (c === open) depth++;
    else if (c === close && --depth === 0) return source.slice(start, i + 1);
  }
  return null;
}

/**
 * Evaluates a pure data literal in an empty sandbox.
 *
 * The alternative — `import()`ing the icon module and reading its `__iconNode`
 * export — pulls `createLucideIcon.js` and therefore React into this script for
 * no benefit. What is wanted is the array, not the component.
 */
function evalLiteral(literal, what) {
  try {
    return runInNewContext(`(${literal})`, Object.create(null), { timeout: 1000 });
  } catch (error) {
    die(`could not parse ${what}: ${error.message}`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reading the pinned package
// ─────────────────────────────────────────────────────────────────────────────

function assertPinnedLucide() {
  if (!existsSync(LUCIDE_ROOT)) {
    die(
      `lucide-react is not installed at\n  ${LUCIDE_ROOT}\n\n` +
      'Icon geometry is read from the in-tree package the web application ' +
      'itself renders; this script never downloads it (§ 6.3.2). Restore it ' +
      `with:\n\n  ${RESTORE_COMMAND}\n\n` +
      'and re-run. If the tree cannot be restored, the batch escalates (§ 8).',
    );
  }

  const manifest = JSON.parse(readFileSync(join(LUCIDE_ROOT, 'package.json'), 'utf8'));
  if (manifest.version !== REQUIRED_LUCIDE_VERSION) {
    die(
      `lucide-react is ${manifest.version}, required ${REQUIRED_LUCIDE_VERSION}.\n` +
      'A different version is a different glyph set and silently forks the ' +
      'fidelity oracle (§ 6.3.2). Refusing to generate.',
    );
  }
  return manifest.version;
}

/** `{ FileText: 'file-text', Users2: 'users-round', … }` from the ESM barrel. */
function readExportTable() {
  const barrel = readFileSync(join(LUCIDE_ROOT, 'dist/esm/lucide-react.js'), 'utf8');
  const table = Object.create(null);

  const line = /export\s*\{([^}]*)\}\s*from\s*['"]\.\/icons\/([a-z0-9-]+)\.js['"]/g;
  for (const match of barrel.matchAll(line)) {
    for (const clause of match[1].split(',')) {
      const alias = clause.trim().match(/^default\s+as\s+([A-Za-z0-9_]+)$/);
      if (alias) table[alias[1]] = match[2];
    }
  }
  return table;
}

/** lucide's own SVG wrapper, read rather than retyped. */
function readDefaultAttributes() {
  const source = readFileSync(join(LUCIDE_ROOT, 'dist/esm/defaultAttributes.js'), 'utf8');
  const literal = literalAfter(source, 'defaultAttributes =', '{', '}');
  if (!literal) die('could not locate defaultAttributes in the lucide package');
  return evalLiteral(literal, 'defaultAttributes');
}

/**
 * The geometry of one icon, plus a cross-check that the file really is the one
 * that backs [name]: every icon module ends with
 * `const <Pascal> = createLucideIcon("<kebab>", __iconNode)`, and the kebab
 * name there must equal the file we resolved through the export table.
 */
function readIconNode(name, file) {
  const path = join(LUCIDE_ROOT, 'dist/esm/icons', `${file}.js`);
  if (!existsSync(path)) die(`${name}: expected ${path}, which does not exist`);

  const source = readFileSync(path, 'utf8');

  const declared = source.match(/createLucideIcon\(\s*"([a-z0-9-]+)"/);
  if (!declared) die(`${name}: ${file}.js has no createLucideIcon call to verify against`);
  if (declared[1] !== file) {
    die(`${name}: ${file}.js declares itself as "${declared[1]}" — export table and module disagree`);
  }

  const literal = literalAfter(source, 'const __iconNode =', '[', ']');
  if (!literal) die(`${name}: no __iconNode array in ${file}.js`);

  const node = evalLiteral(literal, `${name} (__iconNode)`);
  if (!Array.isArray(node) || node.length === 0) die(`${name}: empty geometry`);
  return node;
}

// ─────────────────────────────────────────────────────────────────────────────
// Emitting
// ─────────────────────────────────────────────────────────────────────────────

function renderSvg(iconNode, defaults) {
  const wrapper = Object.entries(defaults)
    .map(([k, v]) => `${svgAttribute(k)}="${escapeAttribute(v)}"`)
    .join(' ');

  const children = iconNode
    .map(([tag, attributes]) => {
      const rendered = Object.entries(attributes)
        // React reconciliation metadata, not geometry (§ 6.3.2).
        .filter(([k]) => k !== 'key')
        .map(([k, v]) => `${svgAttribute(k)}="${escapeAttribute(v)}"`)
        .join(' ');
      return `<${tag} ${rendered}/>`;
    })
    .join('');

  return `<svg ${wrapper}>${children}</svg>\n`;
}

function renderRegistry(entries, version) {
  const rows = entries
    .map(([name, asset]) => `  '${name}': '${asset}',`)
    .join('\n');

  return `// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Source:  lucide-react ${version} (ISC), read from the in-tree, pinned copy at
//          sources/lcc-app/node_modules/lucide-react — the same package the web
//          application renders. No network fetch is involved (§ 6.3.2).
// Command: node tool/generate_lucide_svgs.mjs
// Entries: ${entries.length}
//
// The key is the web's own component name, which is also the name the
// catalogue API sends and the SVG's file name — one string end to end, so no
// case-mapping layer exists to get wrong (§ 6.3.3).
//
// This table is the ASSET index, not a resolver. Scoping — which names a given
// surface is allowed to resolve, and what an unknown name falls back to — lives
// in \`app_icons.dart\`, because the web has two registries with different
// coverage and merging them would render the wrong glyph (§ 6.3.5).
library;

/// Every bundled lucide glyph, by its lucide component name.
const Map<String, String> lucideRegistry = <String, String>{
${rows}
};
`;
}

/** Writes only when the bytes differ, so a re-run is genuinely a no-op. */
function emit(path, contents, report) {
  const unchanged = existsSync(path) && readFileSync(path, 'utf8') === contents;
  if (unchanged) { report.unchanged++; return; }

  if (CHECK_ONLY) { report.wouldChange.push(path); return; }

  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, contents, 'utf8');
  report.written++;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

function main() {
  if (NAMES.length !== EXPECTED_NAME_COUNT) {
    die(`NAMES holds ${NAMES.length} entries, expected ${EXPECTED_NAME_COUNT} (§ 2.2 Finding C)`);
  }
  if (new Set(NAMES).size !== NAMES.length) die('NAMES contains a duplicate');
  const sorted = [...NAMES].sort();
  if (sorted.some((n, i) => n !== NAMES[i])) die('NAMES is not sorted — fix the list, not this check');

  const version = assertPinnedLucide();
  const exportTable = readExportTable();
  const defaults = readDefaultAttributes();

  const report = { written: 0, unchanged: 0, wouldChange: [] };
  const entries = [];
  const digest = createHash('sha256');

  for (const name of NAMES) {
    const file = exportTable[name];
    if (!file) die(`${name} is not exported by lucide-react ${version}`);

    const svg = renderSvg(readIconNode(name, file), defaults);
    const asset = `assets/icons/lucide/${name}.svg`;

    emit(join(PACKAGE_ROOT, asset), svg, report);
    entries.push([name, asset]);
    digest.update(`${name} ${svg}`);
  }

  // A name removed from NAMES must take its SVG with it, or the bundle grows
  // monotonically and the byte ceiling (§ 6.3.3) drifts out of meaning.
  const expected = new Set(NAMES.map((n) => `${n}.svg`));
  const orphans = existsSync(OUT_SVG_DIR)
    ? readdirSync(OUT_SVG_DIR).filter((f) => f.endsWith('.svg') && !expected.has(f))
    : [];
  for (const orphan of orphans) {
    if (CHECK_ONLY) report.wouldChange.push(join(OUT_SVG_DIR, orphan));
    else rmSync(join(OUT_SVG_DIR, orphan));
  }

  emit(OUT_REGISTRY, renderRegistry(entries, version), report);

  const summary =
    `lucide-react ${version} · ${entries.length} icons · ` +
    `written ${report.written} · unchanged ${report.unchanged} · ` +
    `orphans removed ${orphans.length}\n` +
    `geometry sha256 ${digest.digest('hex')}\n`;
  process.stdout.write(summary);

  if (CHECK_ONLY && report.wouldChange.length > 0) {
    process.stderr.write(
      `--check: ${report.wouldChange.length} file(s) out of date:\n  ` +
      `${report.wouldChange.join('\n  ')}\n`,
    );
    process.exit(1);
  }
}

main();
