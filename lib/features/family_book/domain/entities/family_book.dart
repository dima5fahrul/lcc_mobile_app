/// `FamilyBook` — the household record `GET /me/family-book` answers.
///
/// `types.ts:615-621` extending `HouseholdSummary` (`:598-613`), **plus the two
/// cover fields the shared type does not name** and which
/// `FamilyBookPage.tsx:33-36` adds locally:
///
/// ```tsx
/// type FamilyBookRecord = FamilyBook & {
///   head_id_no?: string;
///   nationality?: string;
/// };
/// ```
///
/// ## `place` is NOT modelled, and the reason is a name collision
///
/// `types.ts:617` declares a `place?` field whose type is a per-level
/// `Bilingual` structure — a different shape from [Jurisdiction]'s flat
/// strings. The page reads that field **nowhere**. What it does read is
///
/// ```tsx
/// const place = book?.jurisdiction;          // :217
/// ```
///
/// a **local variable** called `place` bound to the `jurisdiction` field, whose
/// six flat strings feed the three address rows at `:420-424` and the address
/// line. A port that modelled the declared field and wired it to those rows
/// would render nothing, or the wrong thing, and the shared name is exactly
/// what would make the mistake look correct on review (`specs.md` § 6.11,
/// `F4-AC-43`). So it is absent by ruling, not by oversight — and this file
/// does not even spell its type name, because `F4-AC-43` greps for it.
///
/// ## Four fields are parsed and never rendered, and that is deliberate
///
/// [id], [status], [houseNo] and [reissueCount] are declared by
/// `HouseholdSummary` and read by no line of `FamilyBookPage.tsx`; so is
/// [nationality], which `specs.md` § 5 rules *"Model it; do not render it"*.
/// `application_row.dart` states the rule this follows — *"Every field the wire
/// carries IS parsed"*, because a partial construction makes the entity mean
/// something subtly different from the row it came from, and the next batch
/// that needs one has to re-derive the parse. `place` is the single exception
/// above, and it is excepted for a reason that does not apply to these.
///
/// ## Three counts are nullable, and the nullability is load-bearing
///
/// `:213-215` is `??`, not `||`:
///
/// ```tsx
/// const total = book?.total_members ?? members.length;
/// ```
///
/// A server **`0`** is therefore kept and NOT recomputed from the list. Modelling
/// these as non-nullable `int` with a `0` default would erase the distinction
/// between "the server said zero" and "the server said nothing", and the second
/// is the only one that counts the array. `F4-AC-45`.
///
/// [jurisdiction] is nullable for the same class of reason: `:217` is
/// `book?.jurisdiction`, and an absent block is a rendered state — three blank
/// `ReadField`s and an [addressLine] that falls through to [address] — not an
/// error (`F4-AC-69`).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../application/domain/entities/jurisdiction.dart';
import 'household_member.dart';

part 'family_book.freezed.dart';

@freezed
abstract class FamilyBook with _$FamilyBook {
  const factory FamilyBook({
    /// `types.ts:599`. Parsed, never rendered.
    String? id,

    /// `:402`, `:358`, `:524`.
    @Default('') String householdNo,

    /// Rendered **twice** on step 1 — once as the cover holder (`:409`), once
    /// as the head (`:412`) — and again at `:357` and `:525`. That is the
    /// source's own duplication, not a copy-paste in this port.
    @Default('') String headName,

    /// `:413`, `:526`. **Not in `HouseholdSummary`** — the page's own local
    /// extension at `:34`.
    String? headIdNo,

    /// **Not in `HouseholdSummary`** (`:35`) and read by no line. Modelled per
    /// `specs.md` § 5; never rendered.
    String? nationality,

    /// `:415`, `:527`.
    @Default('') String unit,

    /// `:416`, `:527`.
    @Default('') String group,

    /// `:220` — the **second** fallback of [addressLine], never a field of its
    /// own on screen.
    String? address,

    /// `types.ts:604`. Parsed, never rendered.
    String? houseNo,

    /// `types.ts:620`. Parsed, never rendered — and not to be confused with a
    /// member's `status`, which `:471` and `:490` do render.
    String? status,

    /// `types.ts:621`. Parsed, never rendered.
    int? reissueCount,

    /// `:213`. Nullable — see the library doc: `??`, not `||`.
    int? totalMembers,

    /// `:214`.
    int? maleMembers,

    /// `:215`.
    int? femaleMembers,

    /// `:431` (step 1, falling back to [registeredAt] then to
    /// `t("setOnIssuance")`) and `:529` (step 3, same chain but falling back to
    /// `"—"`). **Two different fallbacks for one field**, both reproduced
    /// (`F4-AC-71`).
    String? issuedAt,

    /// `:431`, `:529`.
    String? registeredAt,

    /// `:217`. The six flat strings behind the three address rows. Shared with
    /// the application feature under CFI — one `Jurisdiction`, not a second
    /// copy (`ssd.md` § 4.3, § 4.5).
    Jurisdiction? jurisdiction,

    /// `:212` — `book?.members ?? []`.
    @Default(<HouseholdMember>[]) List<HouseholdMember> members,
  }) = _FamilyBook;

  const FamilyBook._();
}
