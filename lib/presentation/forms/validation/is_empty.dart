/// `formValidation.tsx:89-93` — what counts as "empty" for required-field
/// validation.
///
/// ```ts
/// export function isEmpty(value: unknown): boolean {
///   if (value == null) return true;
///   if (typeof value === "string") return value.trim() === "";
///   return false;
/// }
/// ```
///
/// Ported literally, including the third line, which is the one that matters:
/// **a non-string, non-null value is never empty.** An empty `List`, an empty
/// `Map` and `0` are all "filled in" as far as this function is concerned, and
/// a Dart port that reached for `value.isEmpty` on a collection would reject
/// forms the web accepts.
library;

bool isEmpty(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim() == '';
  return false;
}
