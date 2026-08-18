/// **P-1 … P-8 — `F4-AC-33`, `F4-AC-44` … `F4-AC-48`.**
///
/// This file is where F4's fidelity claim for the four unmeasurable states
/// lives (`specs.md` § 6.4). Every expectation below is either transcribed from
/// `FamilyBookPage.tsx` or — for the two registry maps — **parsed out of it at
/// run time**, so a transcription slip in `family_book_derivations.dart` fails
/// here rather than shipping.
///
/// The maps are the part worth doing that way. A hand-written expected map is a
/// second transcription of the same source by the same reader in the same hour;
/// it agrees with the first one for exactly the reason it should not be
/// trusted.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/family_book.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/household_member.dart';
import 'package:lcc_mobile_app/features/family_book/domain/family_book_derivations.dart';

import '../family_book_test_helper.dart';

/// `$WEB/src/app/components/FamilyBookPage.tsx`, from the package root.
const String kPageSource = '../lcc-app/src/app/components/FamilyBookPage.tsx';

String _source() {
  final File f = File(kPageSource);
  expect(
    f.existsSync(),
    isTrue,
    reason: 'NOT EVALUATED — $kPageSource is absent, so every assertion that '
        'parses it would pass vacuously. The pinned web checkout is the '
        'oracle (ADR-0001); a missing one is a missing measurement.',
  );
  return f.readAsStringSync();
}

/// `const NAME: Record<string, string> = { … };`, parsed to a map.
///
/// Keys are quoted (`"head of household"`) or bare (`head`); values are always
/// quoted. Written as one regular expression over the brace-delimited block so
/// a key with a space cannot be dropped silently — which is the failure mode
/// `i18n_parse.py`'s header records three times over.
Map<String, String> parseRegistry(String source, String name) {
  final int start = source.indexOf('const $name: Record<string, string> = {');
  expect(start, isNot(-1), reason: '$name is not in the pinned source');
  final int end = source.indexOf('};', start);
  final String block = source.substring(start, end);

  final Map<String, String> out = <String, String>{};
  final RegExp entry = RegExp(r'(?:"([^"]+)"|(\w+))\s*:\s*"(\w+)"');
  for (final RegExpMatch m in entry.allMatches(block)) {
    out[(m.group(1) ?? m.group(2))!] = m.group(3)!;
  }
  return out;
}

/// The identity translator: `t(key)` answers the key.
///
/// The point of P-1 is *which branch runs*, not what the dictionary says, so
/// the fake makes the branch visible: a `relHead` in the output means the map
/// hit, anything else means it missed.
String identity(String key) => key;

void main() {
  late String source;

  setUpAll(() => source = _source());

  // ───────────────────────────────────────────────────────────────────────────
  // P-2 / P-3 — F4-AC-44
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-44 the two registry maps, against the pinned source', () {
    test('RELATION_KEY is transcribed entry for entry — and there are '
        'NINETEEN, not the twenty specs.md § 6.6 states', () {
      final Map<String, String> web = parseRegistry(source, 'RELATION_KEY');

      // The measured correction. `F4-AC-44` says "All 20 … A count below 20/4
      // is a FAIL"; the pinned source at `:77-85` declares 19. The criterion's
      // premise is wrong and this assertion is what shows it, rather than a
      // twentieth invented entry that would satisfy the number and diverge
      // from the web.
      expect(web.length, 19,
          reason: 'FamilyBookPage.tsx:77-85 — 19 spellings, counted from the '
              'source rather than from the port');
      expect(web.values.toSet().length, 8, reason: '8 distinct labels');

      expect(kRelationKey, equals(web));

      // Individually, per the criterion, so a failure names the spelling.
      for (final MapEntry<String, String> e in web.entries) {
        expect(labelOf(kRelationKey, e.key, identity), e.value,
            reason: 'spelling "${e.key}" must resolve to ${e.value}');
      }
    });

    test('GENDER_KEY is FOUR spellings onto TWO labels, single letters '
        'included', () {
      final Map<String, String> web = parseRegistry(source, 'GENDER_KEY');
      expect(web.length, 4);
      expect(web.values.toSet().length, 2);
      expect(kGenderKey, equals(web));

      for (final MapEntry<String, String> e in web.entries) {
        expect(labelOf(kGenderKey, e.key, identity), e.value);
      }
      // `"M"` and `"F"` are real registry values, and the normalisation is
      // what makes them work.
      expect(labelOf(kGenderKey, 'M', identity), 'genderMale');
      expect(labelOf(kGenderKey, 'F', identity), 'genderFemale');
    });

    test('the normalisation is not cosmetic — two spellings carry a space', () {
      expect(labelOf(kRelationKey, '  Head Of Household  ', identity),
          'relHead');
      expect(labelOf(kRelationKey, 'HOUSEHOLD HEAD', identity), 'relHead');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P-1 — F4-AC-46
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-46 labelOf, all three branches', () {
    test('a MISS returns the raw value — not "—", not "Other"', () {
      expect(labelOf(kRelationKey, 'cousin', identity), 'cousin');
      // Not the `relOther` label the namespace happens to carry.
      expect(labelOf(kRelationKey, 'cousin', identity), isNot('relOther'));
    });

    test('an EMPTY value returns the em dash', () {
      expect(labelOf(kRelationKey, '', identity), '—');
      expect(labelOf(kGenderKey, '', identity), '—');
    });

    test('a WHITESPACE-ONLY value returns itself, because `||` is falsy only '
        'for the empty string', () {
      // `map["   ".trim().toLowerCase()]` misses, and `"   " || "—"` is
      // `"   "` in JavaScript. A port that trimmed the fallback too would
      // render the dash here and pass every other assertion in this group.
      expect(labelOf(kRelationKey, '   ', identity), '   ');
    });

    test('a MISS is returned as given — untrimmed, un-lowercased', () {
      expect(labelOf(kRelationKey, ' Cousin ', identity), ' Cousin ');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P-4
  // ───────────────────────────────────────────────────────────────────────────
  group('P-4 isHeadRelation — three spellings, not one', () {
    test('exactly the relHead spellings satisfy it', () {
      final Map<String, String> web = parseRegistry(source, 'RELATION_KEY');
      for (final MapEntry<String, String> e in web.entries) {
        expect(isHeadRelation(e.key), e.value == 'relHead',
            reason: '"${e.key}" -> ${e.value}');
      }
      expect(
        web.entries.where((MapEntry<String, String> e) => e.value == 'relHead'),
        hasLength(3),
      );
    });

    test('an unknown or blank relation is not the head', () {
      expect(isHeadRelation('cousin'), isFalse);
      expect(isHeadRelation(''), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P-5 — F4-AC-45
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-45 the three counts — `??`, not `||`', () {
    final List<HouseholdMember> three = <HouseholdMember>[
      memberFixture(id: 'a', gender: 'Male'),
      memberFixture(id: 'b', gender: 'M'),
      memberFixture(id: 'c', gender: 'female'),
    ];

    test('a server total of 0 with three members in the list renders 0', () {
      final FamilyBook book =
          householdFixture(totalMembers: 0, members: three);
      expect(totalMembersOf(book), 0,
          reason: '`book?.total_members ?? members.length` keeps a server 0');
    });

    test('an ABSENT server total counts the array', () {
      expect(totalMembersOf(householdFixture(members: three)), 3);
    });

    test('men counts "Male", "M" and "m" — startsWith, on the lowercased '
        'value', () {
      final FamilyBook book = householdFixture(
        members: <HouseholdMember>[
          memberFixture(id: 'a', gender: 'Male'),
          memberFixture(id: 'b', gender: 'M'),
          memberFixture(id: 'c', gender: 'm'),
          memberFixture(id: 'd', gender: 'female'),
        ],
      );
      expect(menCountOf(book), 3);
      expect(womenCountOf(book), 1);
    });

    test('the predicate is LOOSE, and the port keeps the looseness', () {
      // `"married".startsWith("m")` is true. This is the source's own
      // behaviour (`:214`); tightening it to an exact GENDER_KEY match would
      // be a different count on the same data.
      final FamilyBook book = householdFixture(
        members: <HouseholdMember>[memberFixture(id: 'a', gender: 'married')],
      );
      expect(menCountOf(book), 1);
    });

    test('a null gender counts as neither', () {
      final FamilyBook book = householdFixture(
        members: <HouseholdMember>[memberFixture(id: 'a')],
      );
      expect(menCountOf(book), 0);
      expect(womenCountOf(book), 0);
    });

    test('a null book is zero of everything and does not throw', () {
      expect(totalMembersOf(null), 0);
      expect(menCountOf(null), 0);
      expect(womenCountOf(null), 0);
      expect(membersOf(null), isEmpty);
    });

    test('the SINGULAR branch — asserted in `en`, because `lo` cannot carry '
        'it', () {
      // `familyBook.ts:173-174` — `person` and `people` are the byte-identical
      // `ຄົນ` in Lao, so both arms of `total === 1 ? t("person") : t("people")`
      // render the same bytes there (specs.md § 2.2 Finding D). A test that
      // ran only in `lo` would pass with the condition inverted, dropped, or
      // replaced by `Intl.plural`.
      final File ns = File('../lcc-app/src/app/i18n/ns/familyBook.ts');
      expect(ns.existsSync(), isTrue);
      final String text = ns.readAsStringSync();
      expect(text, contains('person: "ຄົນ"'));
      expect(text, contains('people: "ຄົນ"'));
      expect(text, contains('person: "person"'));
      expect(text, contains('people: "people"'));

      // The branch itself is a widget-level render; the count it reads is
      // here, and `family_book_page_test.dart` asserts the English words.
      expect(totalMembersOf(householdFixture(totalMembers: 1)), 1);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P-6 — F4-AC-47
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-47 addressLine — all three arms', () {
    test('village, district, province — in THAT order, joined by ", "', () {
      expect(
        addressLineOf(householdFixture()),
        'Ban Sisavath, Chanthabouly, Vientiane Capital',
      );
    });

    test('a partly-filled jurisdiction drops the absent levels', () {
      expect(
        addressLineOf(householdFixture(
          jurisdiction: const Jurisdiction(provinceName: 'Champasak'),
        )),
        'Champasak',
      );
    });

    test('an ALL-EMPTY jurisdiction falls through to book.address', () {
      // `[].filter(Boolean).join(", ")` is `""`, which is falsy — so `||`
      // continues. A `??` chain would stop at the empty string and render a
      // blank line.
      expect(
        addressLineOf(householdFixture(
          jurisdiction: const Jurisdiction(),
          address: 'Unit 7, Group 3',
        )),
        'Unit 7, Group 3',
      );
      expect(
        addressLineOf(householdFixture(
          jurisdiction: null,
          address: 'Unit 7, Group 3',
        )),
        'Unit 7, Group 3',
      );
    });

    test('an empty address falls through to the em dash', () {
      expect(
        addressLineOf(householdFixture(jurisdiction: null, address: null)),
        '—',
      );
      expect(
        addressLineOf(householdFixture(jurisdiction: null, address: '')),
        '—',
      );
    });

    test('an absent book does not throw', () {
      expect(addressLineOf(null), '—');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P-8 — F4-AC-48
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-48 the step-3 sub-line, and its disagreement with P-1', () {
    test('four elements, fixed order, " · " between them', () {
      final HouseholdMember m = memberFixture(
        relation: 'son',
        gender: 'M',
        dateOfBirth: '2011-05-02',
        uin: 'UIN-77',
      );
      expect(
        memberSubLine(m, identity),
        'relChild · genderMale · 2011-05-02 · UIN-77',
      );
    });

    test('a BLANK relation contributes nothing here — while the same blank '
        'renders "—" through labelOf', () {
      final HouseholdMember m = memberFixture(
        relation: '',
        gender: 'f',
        dateOfBirth: '1990-01-01',
      );

      // P-8: the `&&` short-circuits before `labelOf` runs.
      expect(memberSubLine(m, identity), 'genderFemale · 1990-01-01');
      expect(memberSubLine(m, identity), isNot(contains('—')));

      // P-1, in the same test, on the same value: step 2's `ReadField` shows
      // the dash. Normalising the two is an L-10 failure in whichever
      // direction it is normalised.
      expect(labelOf(kRelationKey, m.relation ?? '', identity), '—');
    });

    test('a null relation behaves as a blank one', () {
      expect(memberSubLine(memberFixture(uin: 'X'), identity), 'X');
    });

    test('an all-empty member renders the em dash and nothing else', () {
      expect(memberSubLine(memberFixture(), identity), '—');
    });

    test('an unmapped relation reaches the sub-line RAW', () {
      expect(
        memberSubLine(memberFixture(relation: 'cousin'), identity),
        'cousin',
      );
    });

    test('the separator is U+00B7 with a space either side', () {
      final String line = memberSubLine(
        memberFixture(gender: 'f', uin: 'U'),
        identity,
      );
      expect(line, 'genderFemale · U');
      expect(line.contains('·'), isTrue);
      expect(line.contains(' · '), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // P-7 — F4-AC-33
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-33 formatLak at four points', () {
    // **This is a PURE-FUNCTION test, not a claim about the server.**
    // `F4-NV-5`: the recorded staging catalogue says `fee_lak: 0` for
    // `family-book` and the seeded table says `fee: 0`, so the grouped-number
    // branch is unreachable from any recorded payload. The 12,000 below is
    // SYNTHETIC and is labelled as such in `qa-report.md`.
    test('null renders the em dash — "not configured", not "free"', () {
      expect(formatLak(null, 'en'), '—');
      expect(formatLak(null, 'lo'), '—');
    });

    test('zero renders Free / ຟຣີ — the only branch the catalogue reaches', () {
      expect(formatLak(0, 'en'), 'Free');
      expect(formatLak(0, 'lo'), 'ຟຣີ');
    });

    test('SYNTHETIC 12000 groups with a COMMA in BOTH locales', () {
      // `serviceConfig.ts:41` calls `toLocaleString("en-US")` with a literal
      // locale, so only the currency word changes. A port that reached for a
      // locale-aware grouper would render a different string in Lao and would
      // be a degrade-better (specs.md § 2.2 Finding A).
      expect(formatLak(12000, 'en'), '12,000 LAK');
      expect(formatLak(12000, 'lo'), '12,000 ກີບ');
      expect(formatLak(12000, 'lo'), contains(','));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // orDash — the page's most repeated expression
  // ───────────────────────────────────────────────────────────────────────────
  group('orDash — `value || "—"`', () {
    test('empty and null both become the dash; whitespace does not', () {
      expect(orDash(''), '—');
      expect(orDash(null), '—');
      expect(orDash(' '), ' ');
      expect(orDash('x'), 'x');
    });
  });
}
