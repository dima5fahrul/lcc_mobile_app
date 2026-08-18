/// `FamilyBookRemoteDatasource` — the family-book feature's HTTP boundary.
///
/// **Two calls, both Bearer, and neither is `anonymous`.**
///
/// | Method | Path | Auth | Source |
/// |---|---|---|---|
/// | [getFamilyBook] | `GET /me/family-book` | Bearer | `endpoints.ts:128` |
/// | [requestFamilyBookCopy] | `POST /me/family-book/request-copy` | Bearer | `endpoints.ts:128-129` |
///
/// Both are `/me/*`, so neither carries `anonymous: true` in the source and
/// neither does here. That is a real property rather than a default: sending a
/// bearer to a public endpoint triggers a refresh round trip on a request that
/// never needed one (`news_remote_datasource.dart`'s note), and the inverse —
/// omitting it here — would make every read 401.
///
/// ## Why the reads ask for `dynamic`
///
/// `news_remote_datasource.dart` records the measurement in full: `ApiClient`
/// forwards `T` to `_dio.get<T>()`, Dio casts the decoded **envelope** to `T`,
/// and the envelope is a map. Asking for anything narrower throws before
/// `_unwrap` runs and surfaces as `NETWORK_ERROR` — a served request reported
/// as being offline. One rule, no exceptions: ask for `dynamic`, check here.
///
/// ## The 404 is thrown, not swallowed
///
/// `GET /me/family-book` answers `404 NOT_FOUND` on every account this
/// programme has. This layer lets the `ApiException` out unchanged, exactly as
/// the application feature's detail read does: the **repository** is where a
/// 404 becomes a distinguishable failure, because that is the layer whose type
/// the page reads.
library;

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../domain/entities/family_book.dart';
import '../models/family_book_wire.dart';

abstract class FamilyBookRemoteDatasource {
  /// `GET /me/family-book` — Bearer.
  ///
  /// Throws the [ApiException] the client raises, 404 included.
  Future<FamilyBook> getFamilyBook();

  /// `POST /me/family-book/request-copy` — Bearer.
  ///
  /// The body is [requestCopyBody]'s single-key map, passed through **as
  /// built**: `client.ts:242` is a bare `JSON.stringify(options.body)`, so this
  /// map's insertion order is the byte order on the socket. Nothing here may
  /// add a key, elide one, or reorder.
  Future<ApplicationRow> requestFamilyBookCopy(String reason);
}

class FamilyBookRemoteDatasourceImpl implements FamilyBookRemoteDatasource {
  const FamilyBookRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<FamilyBook> getFamilyBook() async {
    final dynamic body = await apiClient.get<dynamic>(
      ApiEndpoint.meFamilyBook,
    );
    if (body is! Map<String, dynamic>) {
      // Not an object is not a household. Unlike the service catalogue — which
      // has a seeded table to fall back on — there is no such thing as a
      // fallback family book, so this throws and the page renders its error
      // branch (`:305-323`) rather than a blank cover with every field `—`.
      throw const ApiException(
        status: 0,
        code: ApiCode.internalError,
        message: 'GET /me/family-book did not answer an object.',
      );
    }
    return familyBookFrom(body);
  }

  @override
  Future<ApplicationRow> requestFamilyBookCopy(String reason) async {
    final dynamic body = await apiClient.post<dynamic>(
      ApiEndpoint.meFamilyBookRequestCopy,
      body: requestCopyBody(reason),
    );
    return applicationRowFrom(dataObject(body));
  }
}
