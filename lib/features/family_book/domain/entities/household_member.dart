/// `HouseholdMember` — one person on a household record.
///
/// Ported from `lcc-app/src/app/api/types.ts:586-598`.
///
/// ## The page distrusts its own types, and the page is the contract
///
/// `types.ts` declares `gender: string`, `relation: string`, `nationality:
/// string`, `status: string` and `uin: string` as **required**. The page does
/// not believe any of them:
///
/// ```tsx
/// m.gender?.toLowerCase().startsWith("m")   // :214  — optional chain
/// labelOf(RELATION_KEY, m.relation ?? "")   // :487  — nullish coalesce
/// <ReadField … value={m.nationality ?? ""}/>// :489
/// {m.status || "—"}                         // :471
/// {say("uin")}: {m.uin || "—"}              // :495
/// ```
///
/// Five defensive reads is not a style; it is the observable contract
/// (`specs.md` § 5, `F4-AC-42`). Declaring them non-nullable here to match the
/// TypeScript would put a `!` or a `late` between the wire and the screen and
/// turn a half-populated row into a crash — the added failure mode `ssd.md`
/// § 11.2 L-10 forbids. They are nullable, and every render site reproduces the
/// source's own fallback rather than a shared one.
///
/// [name] is the one string kept non-nullable: `:482` passes it straight to
/// `ReadField`, whose own `value || "—"` (`:110`) already covers the empty
/// case, and the parser answers `''` for an absent key. No bang, no default
/// sentence.
///
/// ## `person_id` and `age` are parsed and never rendered
///
/// `application_row.dart`'s rule, applied: *"Every field the wire carries IS
/// parsed"*, because a partial construction makes the entity mean something
/// subtly different from the row it came from. Neither has a call site in
/// `FamilyBookPage.tsx`; both are on the wire.
///
/// The one field deliberately **not** modelled anywhere in this feature is
/// `FamilyBook.place`, and that exclusion is a ruling with its own reason —
/// see `family_book.dart`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'household_member.freezed.dart';

@freezed
abstract class HouseholdMember with _$HouseholdMember {
  const factory HouseholdMember({
    /// `types.ts:587`. The React list key at `:458`; never rendered.
    required String id,

    /// `:495` — rendered as `{m.uin || "—"}`, so an empty string is a real
    /// state with its own copy.
    String? uin,

    /// `:482`, through `ReadField`'s own `value || "—"`.
    @Default('') String name,

    /// `:484` via `labelOf(GENDER_KEY, m.gender ?? "")`, and `:214`'s count via
    /// `m.gender?.toLowerCase().startsWith("m")`.
    String? gender,

    /// `:485`, `:556`. An ISO date string; the page never parses it.
    String? dateOfBirth,

    /// `:487` via `labelOf(RELATION_KEY, m.relation ?? "")`, and `:456`'s
    /// `isHeadRelation(m.relation ?? "")`.
    String? relation,

    /// `:489` — rendered **raw**, through no lookup map, even though six
    /// `nat*` labels sit in the namespace. See `family_book_derivations.dart`.
    String? nationality,

    /// `:475-481`. Falsy — `null` **or** `''` — renders no element at all.
    String? photoUrl,

    /// `:471` and `:490`, both raw.
    String? status,

    /// `types.ts:589`, `:597`. Parsed, never rendered.
    String? personId,
    int? age,
  }) = _HouseholdMember;

  const HouseholdMember._();
}
