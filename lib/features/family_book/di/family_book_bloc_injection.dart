/// The family-book page's Cubit registration.
///
/// ## `registerFactoryParam`, not `registerLazySingleton`
///
/// `certificates_bloc_injection.dart`'s reason, and `AuthFeatureInjection`'s
/// before it: a visit to this page is scoped to one visit. [FamilyBookCubit]
/// holds a step index and, once the copy is requested, a created
/// `ApplicationRow`. A singleton would open the page on step 3 for the next
/// citizen, with the previous citizen's success card already rendered.
///
/// The parameter is `bool authenticated` rather than a `Lang`, and that is the
/// one shape difference from the resident wizard's registration. FamilyBook's
/// locale is read at **submit** time from the widget's own context (§ 6.5 T0-2,
/// `FamilyBookCubit.requestCopy`), so the cubit needs no language at
/// construction; what it does need at construction is `enabled`, because
/// `useQuery`'s `loading` initialises to it (`hooks.ts:46`) and that decides
/// whether a signed-out mount shows a skeleton for one frame (`F4-AC-35`).
///
/// ## It closes over one other container, for one value
///
/// `serviceInjection`, for the review step's fee. That is the
/// `ChatUsecaseInjection` -> `helpInjection` shape — the only sanctioned
/// cross-container form (`ssd.md` § 5.1) — and it is why
/// `FamilyBookFeatureInjection` must be registered **after**
/// `ServiceFeatureInjection`.
///
/// **This edge is a measured correction to `F4-AC-14`**, whose enumeration
/// names only `application/domain`. It is reported rather than hidden: without
/// it the review step would render the seeded fee forever and a citizen would
/// see `Free` for a copy the backend had started charging for — the exact
/// defect `FamilyBookPage.tsx:531-533` records having already been fixed once
/// in the web. The alternative, leaving the port unwired the way F1 left
/// `probeIdentity`, is not comparable: F1's gap needed an *edit* to another
/// feature, this one needs only a closure over its container.
library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failure.dart';
import '../../service/di/service_injection.dart';
import '../../service/domain/entities/service.dart';
import '../../service/domain/usecases/get_services.dart';
import '../domain/usecases/family_book_usecases.dart';
import '../presentation/bloc/family_book_cubit.dart';
import 'family_book_injection.dart';

class FamilyBookBlocInjection {
  static void inject() {
    familyBookInjection.registerFactoryParam<FamilyBookCubit, bool, void>(
      (bool authenticated, _) => FamilyBookCubit(
        getFamilyBook: familyBookInjection<GetFamilyBook>(),
        requestFamilyBookCopy: familyBookInjection<RequestFamilyBookCopy>(),
        authenticated: authenticated,
        readFee: familyBookFeeReader(serviceInjection<GetServices>()),
      ),
    );
  }
}

/// `useServiceConfig("family-book").fee` — `FamilyBookPage.tsx:190-191` — as
/// one read of the catalogue list.
///
/// ## A recorded divergence, not a shortcut
///
/// The web reads a **cached catalogue keyed by code**; this reads the list and
/// selects the row. `api_endpoint.dart` carries only `services = '/services'`
/// (B2a) and `specs.md` § 3.1 row 5 grants that file for **exactly two**
/// constants, so F4 may not add a by-code endpoint. It is the same divergence
/// `residentServiceReader` recorded, with the same consequence: one request
/// instead of a cached lookup, same `fee_lak` off the same row.
///
/// ## A failure is NOT an error here, and that is the difference from Resident
///
/// `residentServiceReader` answers a `Failure` when the catalogue has no
/// `resident` row, because the resident page has an error branch and a
/// zero-fee `Service` would render `0 LAK` as though the API had said so.
/// FamilyBook has no such branch: `useServiceConfig`'s contract is *"`config`
/// is never undefined: until the catalogue lands it is the seeded value (or the
/// default), so a fee never renders as a blank"* (`serviceConfig.ts:252-256`).
///
/// So this answers `null` — "no answer" — and [FamilyBookCubit] leaves
/// `kFamilyBookSeedFeeLak` standing, which is what `getServiceConfig` returns
/// for a known code before the catalogue arrives. Folding a catalogue failure
/// into the page's error card would put *"We could not load your family book"*
/// in front of a citizen whose family book loaded fine.
FamilyBookFeeReader familyBookFeeReader(GetServices getServices) => () async {
      final Either<Failure, List<Service>> result =
          await getServices(GetServicesParams.all);
      return result.fold(
        (Failure _) => null,
        (List<Service> rows) {
          for (final Service s in rows) {
            if (s.code == kFamilyBookServiceCode) return s.feeLak;
          }
          return null;
        },
      );
    };

/// `useServiceConfig("family-book")` — `FamilyBookPage.tsx:190`.
///
/// Spelled here rather than imported from the presentation layer for the reason
/// `certificates_bloc_injection.dart` gives about its own service code: two
/// independent transcriptions of one source line are worth more than the
/// deduplication, and the DI test asserts they agree.
const String kFamilyBookServiceCode = 'family-book';
