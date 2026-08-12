/// Abstract `NetworkClient` — the contract every HTTP implementation
/// (Dio, http, mock) must satisfy.
///
/// Extends the flutter-boilerplate pattern: the boilerplate declared only
/// `get` + `post`; we add `put`, `patch`, `delete`, and `upload` (multipart)
/// because the LCC citizen portal uses all five verbs plus file uploads
/// (`/me/avatar`, document attachments).
///
/// Every method returns the **raw envelope** (`Map<String, dynamic>`) so a
/// single wrapper can unwrap `{ success, message, data, ... }` once — the
/// typed unwrapping lives in [ApiClient].
abstract class NetworkClient {
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  });

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  });

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  });

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  });

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  });

  /// Multipart upload. `formData` is the Dio `FormData` (caller builds it);
  /// the implementer must NOT set `Content-Type` so the multipart boundary is
  /// generated automatically.
  Future<Map<String, dynamic>> upload(
    String endpoint, {
    required dynamic formData,
  });
}
