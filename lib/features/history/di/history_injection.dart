/// The history feature's own `GetIt` container.
///
/// ## A recorded scope deviation — specs.md § 3.1's B7a table omits this path
///
/// § 3.1 grants B7a `lib/features/history/presentation/{bloc,pages,widgets}/**`
/// and, on the `lib/core/di/dependency_injection.dart` row, *"two alphabetical
/// lines (`ApplicationFeatureInjection`, **`HistoryFeatureInjection`**)"*. The
/// second class has to live somewhere, and `lib/features/history/di/` is the
/// only place consistent with every other feature in the tree. The table is
/// therefore incomplete rather than prohibitive, and the two alternatives are
/// both worse:
///
/// * registering `HistoryBloc` in `applicationInjection` would make the
///   page-less application feature import `features/history/presentation/**`,
///   pointing the shared feature at one of its four consumers — the exact
///   arrow § 6.2 spent a section avoiding;
/// * a container-less `HistoryBloc` constructed in the route builder would put
///   `applicationInjection<ListApplications>()` inside `app_routes.dart`,
///   which is legal under CR-1 but bypasses DI-2 and leaves B7b's second BLoC
///   nowhere to go.
///
/// **Recorded, not absorbed** — the batch report names it so the architect can
/// amend § 3.1 rather than discover it in review.
library;

import 'package:get_it/get_it.dart';

final historyInjection = GetIt.asNewInstance();
