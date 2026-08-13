part of 'service_bloc.dart';

/// What the catalogue page can do.
///
/// Plain classes rather than a freezed union: `flutter_bloc`'s `on<E>` already
/// gives per-event dispatch, and a union would add a `map`/`when` layer over a
/// dispatch mechanism that exists. `AuthBloc` makes the same call.
sealed class ServiceEvent {
  const ServiceEvent();
}

/// Mount. Fetches `/service-categories` and the unfiltered `/services`
/// together — the pair `ServicePage.tsx:298-299` fires on render.
final class ServiceStarted extends ServiceEvent {
  const ServiceStarted();
}

/// The error panel's "Retry" in the **category** view — `retryCatalogue()`,
/// which refetches both catalogue queries (`ServicePage.tsx:352-355`).
final class ServiceCatalogueRetried extends ServiceEvent {
  const ServiceCatalogueRetried();
}

/// A category chip tapped, or the header's back arrow (which sends null).
final class ServiceCategorySelected extends ServiceEvent {
  const ServiceCategorySelected(this.code);

  /// A [ServiceCategory.code], or null for "all categories".
  final String? code;
}

/// One keystroke in the search field. Raw, untrimmed — the field shows exactly
/// what was typed, and only the *query* is trimmed.
final class ServiceSearchChanged extends ServiceEvent {
  const ServiceSearchChanged(this.query);

  final String query;
}

/// The debounce window elapsed. Dispatched by the BLoC's own timer, never by
/// the page — it is internal, and it is public only because `part` files share
/// a library rather than a privacy boundary.
final class ServiceSearchDebounced extends ServiceEvent {
  const ServiceSearchDebounced(this.query);

  /// Already trimmed.
  final String query;
}

/// The error panel's "Retry" in the **list** view — `listQuery.refetch`
/// (`ServicePage.tsx:495`), which refetches only the filtered list.
final class ServiceListRetried extends ServiceEvent {
  const ServiceListRetried();
}
