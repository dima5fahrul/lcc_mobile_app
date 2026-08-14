/// The one lookup interface — `ssd.md` § 11.1, L-1.
///
/// One method, two endpoint families behind it. A widget asks for
/// `LookupKey.villages` with a district id and never learns which host answered.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/lookup_key.dart';
import '../entities/lookup_option.dart';

abstract class ReferenceRepository {
  /// The rows for [key], in **server order, unfiltered**.
  ///
  /// - **L-3** — no client re-sort. The web applies none.
  /// - **L-4** — no `active` filtering. The web does not filter; its `labelOf`
  ///   falls back to the raw code.
  /// - **L-7** — [paging] defaults to [PagingMode.all], so villages page to the
  ///   end unless a caller deliberately asks otherwise.
  ///
  /// [parentId] is required by [DistrictsKey] and [VillagesKey] and ignored by
  /// the others.
  ///
  /// **De-duplication is the implementation's, and it caches the `Future`, not
  /// the result** (`ssd.md` § 11.3). Caching only the completed list still lets
  /// Birth's 19 simultaneous requests fire.
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  });
}
