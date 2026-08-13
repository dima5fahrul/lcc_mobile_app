part of 'home_bloc.dart';

/// What the home page can do.
///
/// Plain sealed classes rather than a freezed union, matching `ServiceEvent`
/// and `AuthEvent`: `flutter_bloc`'s `on<E>` already gives per-event dispatch,
/// and a union would add a `map`/`when` layer over a mechanism that exists.
sealed class HomeEvent {
  const HomeEvent();
}

/// Mount. Fires the three **anonymous** queries the source runs unconditionally
/// (`HomePage.tsx:171-178`): phase-1 services, featured news, FAQs.
///
/// It deliberately does not carry `isAuthenticated`. The two `me.*` queries are
/// driven by [HomeAuthChanged] instead, because the source's `enabled:` option
/// re-evaluates when the flag changes — a citizen who signs in without leaving
/// the page gets their summary — and a single mount event could only express
/// the value at mount.
final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// The session's `authenticated` flag settled or flipped.
///
/// Port of `useQuery(..., [isAuthenticated], { enabled: Boolean(isAuthenticated) })`
/// (`HomePage.tsx:163-170`), whose two halves are both load-bearing:
///
/// * **enabled → fetch.** Signing in mid-visit fills the summary tiles and the
///   ID card without a navigation.
/// * **disabled → no request, and no stale data.** Signing out must not leave
///   the previous citizen's UIN and wallet balance on screen. The handler
///   clears both regions back to `initial`, which is the state that renders
///   them as *absent* rather than as an error.
final class HomeAuthChanged extends HomeEvent {
  const HomeAuthChanged({required this.isAuthenticated});

  final bool isAuthenticated;
}

/// The summary panel's "Try again" — `summary.refetch` (`HomePage.tsx:331`).
final class HomeSummaryRetried extends HomeEvent {
  const HomeSummaryRetried();
}

/// The service grid's "Try again" — `servicesQuery.refetch`
/// (`HomePage.tsx:471`). Retries whichever grid is showing: the quick actions,
/// or the current search.
final class HomeServicesRetried extends HomeEvent {
  const HomeServicesRetried();
}

/// The news slider's "Try again" — `newsQuery.refetch` (`HomePage.tsx:635`).
final class HomeNewsRetried extends HomeEvent {
  const HomeNewsRetried();
}

/// The FAQ list's retry.
///
/// **The source has no control for this**, and that is a defect rather than a
/// design: `HomePage.tsx:745-748` renders `faqQuery.error ? c("faqError") :
/// c("faqEmpty")` as a bare paragraph with nothing to press, so a citizen whose
/// FAQ request fails has no way to try again short of reloading the page. § 6.6
/// makes **error-with-retry** one of four mandatory states and B2-AC-16 asserts
/// it per network-backed surface, so the retry exists here. It is an addition
/// to the port, made because the gate requires it, and it is recorded as such.
final class HomeFaqsRetried extends HomeEvent {
  const HomeFaqsRetried();
}

/// One keystroke in the hero's search field. Raw and untrimmed — the field
/// shows exactly what was typed, and only the *query* is trimmed.
final class HomeSearchChanged extends HomeEvent {
  const HomeSearchChanged(this.query);

  final String query;
}

/// The debounce window elapsed. Dispatched by the BLoC's own timer, never by
/// the page — it is internal, and it is public only because `part` files share
/// a library rather than a privacy boundary.
final class HomeSearchDebounced extends HomeEvent {
  const HomeSearchDebounced(this.query);

  /// Already trimmed.
  final String query;
}

/// The search field's clear button — `setSearchQuery("")`
/// (`HomePage.tsx:303`).
final class HomeSearchCleared extends HomeEvent {
  const HomeSearchCleared();
}

/// The citizen confirmed "Yes, dismiss" — `setShowBanner(false)`
/// (`HomePage.tsx:821`).
final class HomeBannerDismissed extends HomeEvent {
  const HomeBannerDismissed();
}

/// A FAQ row was tapped — `setOpenFaq(open ? null : i)`
/// (`HomePage.tsx:755`). Tapping the open one closes it.
final class HomeFaqToggled extends HomeEvent {
  const HomeFaqToggled(this.index);

  final int index;
}
