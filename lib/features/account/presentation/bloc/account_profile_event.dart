part of 'account_profile_bloc.dart';

sealed class AccountProfileEvent {
  const AccountProfileEvent();
}

/// `useQuery(me.profile, [])` on mount — `AccountPage.tsx:189`.
final class AccountProfileRequested extends AccountProfileEvent {
  const AccountProfileRequested();
}

/// `profileQuery.refetch()` — the error banner's button, `AccountPage.tsx:386`.
final class AccountProfileRetried extends AccountProfileEvent {
  const AccountProfileRetried();
}

/// The Save button — `AccountPage.tsx:548`.
///
/// Carries the **three raw form values**, untrimmed, because the source reads
/// `form` at press time and trims at the comparison site
/// (`form.name.trim() !== account.name`). Trimming in the widget would move
/// half of the transform out of the place Tier 0 gates.
///
/// **There are exactly three, and `phone` is not one of them** — the editor has
/// three inputs and Phone is a read-only row (`:553`). B8-AC-32 / B8-AC-48.
final class AccountProfileSaved extends AccountProfileEvent {
  const AccountProfileSaved({
    required this.name,
    required this.email,
    required this.address,
  });

  final String name;
  final String email;
  final String address;
}

/// The citizen picked a photograph for their avatar — `handleAvatar`'s body
/// after the early return (`AccountPage.tsx:238`). B8b.
///
/// **One event per pick, and no in-flight guard anywhere.** The source's
/// button has no `disabled` attribute (`:333-340`) and `handleAvatar` has no
/// pending check (`:234-245`), so tapping the avatar twice starts two
/// concurrent multipart POSTs and network ordering decides which photograph
/// becomes the citizen's identity avatar. That is `security-review-b8b.md`'s
/// `B8b-5` (MEDIUM): a real weakness, **ported as measured** and recorded as
/// **GG-8**, because adding a guard the web does not have is L-10(b) — the same
/// rule that forbids stripping EXIF two files away.
///
/// It also carries `B8-AC-54`: re-picking the **same** file fires a second
/// upload. Nothing memoises a picker result, and
/// [UploadAvatarParams] compares on identity rather than bytes so that two
/// picks of one photograph cannot collapse into one.
final class AccountAvatarPicked extends AccountProfileEvent {
  const AccountAvatarPicked(this.file);

  final PickedAvatar file;
}

/// The password form's submit — `AccountPage.tsx:673`.
///
/// [confirmPassword] is carried so the BLoC can run the source's second check
/// (`:277`). It is **never forwarded to the use case** and so can never reach
/// the wire — B8-AC-34.
final class AccountPasswordSubmitted extends AccountProfileEvent {
  const AccountPasswordSubmitted({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
}
