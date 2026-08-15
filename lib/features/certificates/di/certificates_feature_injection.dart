/// Certificates feature injection entry point.
///
/// ## One line of registration, and no data layer
///
/// The feature registers **a BLoC and nothing else**, which is the mirror image
/// of `features/application/` and `features/reference/` — both of which register
/// everything *but* a BLoC. `features/certificates/data/` does not exist and
/// must not (`specs.md` § 3.1 row 2, `F1-AC-17`): the wire work for a
/// certificate submission is `features/application/`'s four write methods, and
/// an empty-but-present `data/` here would invite F2 to duplicate them.
///
/// ## Ordering — four hard prerequisites, not a preference
///
/// `CertificatesBlocInjection` closes over `applicationInjection`,
/// `referenceInjection`, `serviceInjection` and `walletInjection`. All four must
/// already have run. Alphabetically `certificates` sorts before all of them, so
/// **DI-6's alphabetical rule yields here and the deviation is stated at the
/// call site** — the same thing steps 11 (chat -> help) and 12 (account ->
/// session/auth) of `dependency_injection.dart` already do.
///
/// The registration is a factory, so a wrong order would not fail here; it would
/// fail at the first resolution, i.e. the first time a citizen opens the form.
/// `certificates_injection_test.dart` asserts the order rather than trusting
/// this comment.
library;

import 'certificates_bloc_injection.dart';

class CertificatesFeatureInjection {
  static Future<void> init() async {
    CertificatesBlocInjection.inject();
  }
}
