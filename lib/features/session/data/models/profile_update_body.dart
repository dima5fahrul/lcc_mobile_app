/// The `PATCH /me/profile` **request body** — the one place in `lib/` that
/// knows the wire names of the profile-update fields.
///
/// CFI (`ssd.md` § 4.3): wire knowledge lives in `data/models/` and nowhere
/// else. [ProfileUpdate] is the framework-agnostic diff; this function is the
/// snake_case serialisation of it.
///
/// ## Why a function and not `@JsonSerializable`
///
/// `json_serializable` emits every declared key and writes `null` for the
/// absent ones unless `includeIfNull: false` is set on each — and the whole
/// claim of specs.md § 6.9 leaf 1 is about **which keys are present**, not
/// about their values. A generated map with `"name": null` in it is a
/// *different request* from one with no `name` key at all, and the difference
/// is exactly the divergence Tier 0 exists to catch. Building the map by hand,
/// with one `if` per field, makes the presence rule readable at the point where
/// it is enforced and testable without pumping a widget.
///
/// ## Key order is part of the claim
///
/// `AccountPage.tsx:213-215` assigns `name`, then `email`, then `address`.
/// Dart `Map` literals preserve insertion order and `jsonEncode` respects it,
/// so building them in that order gates key order for free — the disposition
/// F0 § 6.2.3 ruled for the certificate payloads and B9b followed for chat
/// (`tier0_chat_payload_test.dart`).
///
/// `preferred_lang` is emitted last because no source call site ever combines
/// it with the other three: `LanguageToggle.tsx:71` sends it alone.
library;

import '../../domain/entities/profile_update.dart';

/// `PATCH /me/profile`'s body — **only the keys the source would have set**.
///
/// An absent field means "not in the JSON object", not `null`. See the library
/// doc for why that distinction is the point.
Map<String, dynamic> profileUpdateBody(ProfileUpdate update) {
  final Map<String, dynamic> body = <String, dynamic>{};
  if (update.name != null) body['name'] = update.name;
  if (update.email != null) body['email'] = update.email;
  if (update.address != null) body['address'] = update.address;
  if (update.preferredLang != null) {
    body['preferred_lang'] = update.preferredLang;
  }
  return body;
}
