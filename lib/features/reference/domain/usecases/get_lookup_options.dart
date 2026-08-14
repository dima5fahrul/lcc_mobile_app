/// `GetLookupOptions` — the one use case of the reference feature.
///
/// A page BLoC resolves this, not a widget: `ssd.md`:511 rules *"Route builders
/// and `main.dart` may resolve from a locator. **No widget may**"*, enforced by
/// G-L5. That is the seam RULING 8 draws and `F0-AC-77` proves — the kernel
/// widgets take `ReferenceFieldState` as a parameter and never see this class.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/lookup_key.dart';
import '../entities/lookup_option.dart';
import '../repositories/reference_repository.dart';

class GetLookupOptions {
  const GetLookupOptions({required this.repository});

  final ReferenceRepository repository;

  Future<Either<Failure, List<LookupOption>>> call(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) =>
      repository.options(key, parentId: parentId, paging: paging);
}
