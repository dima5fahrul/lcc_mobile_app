part of 'account_documents_bloc.dart';

/// Two events. Plain sealed classes, matching `notifications_event.dart` and
/// `help_event.dart`; only the *state* is freezed.
sealed class AccountDocumentsEvent {
  const AccountDocumentsEvent();
}

/// The `useQuery` fired on mount — `AccountPage.tsx:190`, dependency list `[]`,
/// so exactly once per visit to the page.
final class AccountDocumentsRequested extends AccountDocumentsEvent {
  const AccountDocumentsRequested();
}

/// `docsQuery.refetch()` — the error branch's button, `AccountPage.tsx:412`.
final class AccountDocumentsRetried extends AccountDocumentsEvent {
  const AccountDocumentsRetried();
}
