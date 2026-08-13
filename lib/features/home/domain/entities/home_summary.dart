/// `HomeSummary` — one row of `GET /me/home-summary`.
///
/// Ported from `lcc-app/src/app/api/types.ts:398-416`. **Authenticated only**:
/// `HomePage.tsx:163` fires it with `enabled: Boolean(isAuthenticated)`, so a
/// signed-out citizen never requests it and the four summary tiles are simply
/// absent — not loading, not an error (§ 6.6, manifest F-4).
///
/// ## Why `nextAction` is a nullable entity rather than six nullable fields
///
/// The wire's `next_action` is `{…} | null` and the source's own comment says
/// *"It may be null, and its fields vary by what is pending, so every field
/// here is optional."* Flattening it into the parent would lose the one
/// distinction the banner branches on — `summary.data?.next_action` present or
/// not (`HomePage.tsx:393`) — and would make "no action pending" and "an action
/// with every field blank" the same value.
///
/// ## What is deliberately NOT on this entity
///
/// Nothing is dropped: all nine wire fields are here. `verified` and
/// `eidVerified` are not rendered by B2b's Home — the badge that would read
/// them lives on `AccountPage` — but they are one line each and the row is
/// what a later batch reads. That is the same call `Service` records in its own
/// doc: the cost of carrying a field is one line, the cost of two models of one
/// endpoint is a class of bug.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'home_summary.freezed.dart';

/// `HomeSummary.next_action` — whatever the server says needs the citizen next.
///
/// Every field is optional on the wire, so every field here carries a default
/// rather than being nullable: the banner asks "is there a reference number to
/// print?", and `''` answers that as well as `null` does while removing a
/// null-check from each of the four call sites. [label] is the exception — it
/// is `Bilingual?` because `text(label, lang) || t("actionRequiredTitle")`
/// (`HomePage.tsx:401`) falls back to a *translated* title when the label is
/// absent, and an empty `Bilingual` and a missing one must both take that
/// branch.
@freezed
abstract class HomeNextAction with _$HomeNextAction {
  const factory HomeNextAction({
    @Default('') String action,
    Bilingual? label,

    /// The tab the banner's "Update document" link goes to. The source
    /// defaults it at the call site (`tab ?? "history"`,
    /// `HomePage.tsx:409`), so the empty string here means "the source's
    /// default applies", not "nowhere".
    @Default('') String tab,
    @Default('') String applicationId,
    @Default('') String referenceNo,
    @Default('') String status,
  }) = _HomeNextAction;
}

/// `GET /me/home-summary`.
@freezed
abstract class HomeSummary with _$HomeSummary {
  const factory HomeSummary({
    /// The citizen's display name. The hero prints it beside the greeting
    /// (`HomePage.tsx:279`).
    @Default('') String name,
    @Default(false) bool verified,
    @Default(false) bool eidVerified,
    @Default(0) int activeApplications,
    @Default(0) int readyDocuments,
    @Default(0) int unreadNotifications,
    @Default(0) int walletBalanceLak,

    /// Null when nothing is pending — which is the common case and is why the
    /// banner is conditional rather than empty.
    HomeNextAction? nextAction,
    @Default('') String generatedAt,
  }) = _HomeSummary;
}
