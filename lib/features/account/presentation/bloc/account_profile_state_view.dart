/// The slice of [AccountProfileState] the profile editor draws.
///
/// A plain value object rather than the state itself, for two reasons that are
/// both about testability rather than tidiness:
///
/// 1. `ProfileEditor` can be pumped with a literal — no BLoC, no use cases, no
///    `FakeAsync` — which is what lets Tier 1 assert the editor's nodes in both
///    locales cheaply, and what lets B8-AC-49 assert the *absence* of an
///    `address` error slot by handing it one and finding nothing rendered.
/// 2. It names the two i18n **keys** rather than resolved strings, so the
///    locale is applied at the render site. A BLoC that stored `c("saved")`
///    would freeze the string in whichever locale was current when the save
///    happened — the exact class of bug Tier 1's Lao run exists to catch.
library;

/// Built from a state by [ProfileEditorView.from]; constructible by hand in a
/// test.
class ProfileEditorView {
  const ProfileEditorView({
    this.saving = false,
    this.nameError,
    this.emailError,
    this.saveError,
    this.noteKey,
  });

  /// `saveProfile.pending` — `AccountPage.tsx:548`.
  final bool saving;

  /// `saveProfile.fieldErrors.name` — `:516`.
  final String? nameError;

  /// `saveProfile.fieldErrors.email` — `:530`.
  final String? emailError;

  /// `saveProfile.error.message` — `:545`.
  final String? saveError;

  /// `profileNote` — `:547`, as an i18n **key** (`account.saved` /
  /// `account.nothingChanged`) or null.
  final String? noteKey;
}
