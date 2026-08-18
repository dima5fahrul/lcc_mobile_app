/// Documents feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase, mirroring
/// `NotificationsFeatureInjection.init()`.
///
/// ## It registers no BLoC, and that is the design
///
/// `features/documents/` is **page-less** — the third such feature after
/// `features/reference/` and `features/application/`. B5 creates no route and
/// no page (specs.md § 6.1); its two widgets live in `lib/presentation/documents/`
/// and are pure functions of their parameters (`B5-AC-17`, `B5-AC-80`), and the
/// only state it needs is the third query, which lands in `HistoryDetailBloc`
/// because B7b invited it there and because a second BLoC could not be reached
/// by the source's one refresh button (specs.md § 6.6).
///
/// ## Five files, not the three `features/history/di/` uses
///
/// specs.md § 3.1 row 3 grants `features/documents/di/**` and names the shape
/// as *"the three-file shape `features/history/di/` uses"*. History's three
/// files are container + usecase re-export + entry point, and it has **no data
/// layer at all**: both its use cases are re-exported out of
/// `applicationInjection`. `features/documents/` owns a datasource and a
/// repository, so the model that fits is `features/notifications/di/`'s five —
/// container, datasource, repository, usecase, entry point. Every file is
/// inside the granted `di/**` path; the deviation is from the Notes column's
/// analogy, not from the scope, and it is recorded in `code-review.md` rather
/// than absorbed.
library;

import 'documents_datasource_injection.dart';
import 'documents_repository_injection.dart';
import 'documents_usecase_injection.dart';

class DocumentsFeatureInjection {
  static Future<void> init() async {
    DocumentsDatasourceInjection.inject();
    DocumentsRepositoryInjection.inject();
    DocumentsUsecaseInjection.inject();
  }
}
