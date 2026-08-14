/// The one repository — two datasources behind it (L-1), plus the in-flight
/// de-duplication `ssd.md` § 11.3 keeps and the persisted cache it drops.
///
/// ## Why de-duplication is kept where fidelity says reproduce
///
/// `useQuery` (`api/hooks.ts:37`) has **no cache, no dedup, no in-flight
/// sharing**, and Birth fires **19** independent reference fetches (R-22). The
/// line `ssd.md` § V.4 draws:
///
/// > *Fidelity governs observable behaviour; it does not require replicating a
/// > performance defect.*
///
/// Eliminating 19 duplicate requests is invisible to the citizen except that
/// the same UI arrives sooner; no paired screenshot can detect it.
///
/// ## Three details, because they are the parts that get implemented wrong
///
/// 1. **The `Future` is cached, not the result.** Caching only the completed
///    list still lets 19 simultaneous requests fire — the sharing has to start
///    before the first one lands. `F0-AC-55` asserts one HTTP request for 19
///    concurrent calls **by request count, not by timing**.
/// 2. **In-memory only. No Hive box, no disk, no TTL.** Lifetime = the app
///    process. The persisted 24-hour SWR cache is **dropped**: staleness across
///    sessions is a divergence the web does not have (`ssd.md` § 12).
/// 3. **Not cleared on sign-out.** It holds public reference data with no
///    personal content, and clearing it would itself be behaviour the web does
///    not have. Sign-out clears tokens, not reference data.
///
/// A **failed** future is evicted, so the retry `LoadFailure` offers actually
/// re-requests. Caching a rejection would make L-8's retry affordance a button
/// that redisplays the same error forever — the guard is that
/// `F0-AC-55`'s counterpart test retries after a failure and observes a
/// **second** request.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/lookup_key.dart';
import '../../domain/entities/lookup_option.dart';
import '../../domain/repositories/reference_repository.dart';
import '../datasources/location_remote_datasource.dart';
import '../datasources/reference_list_remote_datasource.dart';

class ReferenceRepositoryImpl implements ReferenceRepository {
  ReferenceRepositoryImpl({
    required this.referenceLists,
    required this.locations,
  });

  final ReferenceListRemoteDatasource referenceLists;
  final LocationRemoteDatasource locations;

  /// Keyed on `(key, parentId, paging)`. **`paging` is part of the key**: a
  /// `firstPageOnly` answer is a *different list* from an `all` answer for the
  /// same district, and sharing one future between them would hand whichever
  /// caller arrived second the other one's rows — silently, and only on
  /// districts with more than 200 villages.
  final Map<String, Future<List<LookupOption>>> _inFlight =
      <String, Future<List<LookupOption>>>{};

  /// Exposed for `F0-AC-55`'s assertion and for nothing else.
  int get cachedEntryCount => _inFlight.length;

  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async {
    final String cacheKey = '${key.id}|${parentId ?? ''}|${paging.name}';

    // The `Future` goes into the map BEFORE it is awaited. That is the whole
    // mechanism: the 2nd…19th caller finds it there and awaits the same one.
    final Future<List<LookupOption>> pending =
        _inFlight[cacheKey] ??= _fetch(key, parentId, paging);

    try {
      return Right<Failure, List<LookupOption>>(await pending);
    } on ApiException catch (e) {
      _inFlight.remove(cacheKey);
      return Left<Failure, List<LookupOption>>(Failure(e.message));
    } catch (e) {
      _inFlight.remove(cacheKey);
      return Left<Failure, List<LookupOption>>(Failure(e.toString()));
    }
  }

  Future<List<LookupOption>> _fetch(
    LookupKey key,
    String? parentId,
    PagingMode paging,
  ) {
    // Exhaustive over the sealed hierarchy — a new `LookupKey` is a compile
    // error here rather than a silent empty list.
    switch (key) {
      case ProvincesKey():
        return locations.provinces();
      case DistrictsKey():
        return locations.districts(parentId ?? '');
      case VillagesKey():
        return locations.villages(parentId ?? '', paging: paging);
      case ReferenceListKey(:final String type):
        return referenceLists.list(type);
    }
  }
}
