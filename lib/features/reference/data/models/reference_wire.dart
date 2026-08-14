/// **L-2 lives here, and nowhere else.**
///
/// `ssd.md`:836: *"the wire difference — reference-lists say `label`, locations
/// say `name` — is absorbed in the data layer and never surfaces upward."*
/// Both shapes become [LookupOption] here; no widget, BLoC or use case ever
/// learns which endpoint answered.
library;

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/lookup_option.dart';

/// `{en, lo}`, defensively — a missing side becomes `''` rather than throwing,
/// because `text()` already has a documented fallback chain for exactly that
/// and a lookup list is not worth a crash.
Bilingual bilingualFrom(Object? raw) {
  if (raw is Map) {
    return Bilingual(
      en: (raw['en'] as String?) ?? '',
      lo: (raw['lo'] as String?) ?? '',
    );
  }
  return const Bilingual(en: '', lo: '');
}

/// `types.ts:225-233`'s `ReferenceItem` — `{id, type, code, label, note?,
/// sort_order, active}`.
///
/// `code` is the value that goes on the wire (`formFields.tsx:262`).
LookupOption referenceItemFrom(Map<String, dynamic> row) => LookupOption(
      id: (row['id'] as String?) ?? '',
      code: (row['code'] as String?) ?? '',
      label: bilingualFrom(row['label']),
      sortOrder: (row['sort_order'] as num?)?.toInt(),
      // L-4 — read, recorded, and never filtered on.
      active: (row['active'] as bool?) ?? true,
    );

/// `types.ts:67-94`'s `Province` / `District` / `Village`.
///
/// The three differ only in fields nothing in a select reads, so one mapper
/// serves all three — and note **`code` is filled from `id`, not from the wire's
/// own `code`**. That is not a shortcut: `formFields.tsx:479`
/// `value: byId ? row.id : row.name.en` puts the **UUID** in the select's
/// value, and `valueMode` is id-only in the port (§ 6.3.5). The wire's `code`
/// (`"VTE"`, …) reaches no payload key, so surfacing it as `LookupOption.code`
/// would put a value in `form_data` that the web never sends.
LookupOption locationRowFrom(Map<String, dynamic> row) {
  final String id = (row['id'] as String?) ?? '';
  return LookupOption(
    id: id,
    code: id,
    label: bilingualFrom(row['name']),
    active: (row['active'] as bool?) ?? true,
  );
}

/// `formFields.tsx:235-240` — **both** wire shapes, in the source's own order.
///
/// ```ts
/// const payload = (await catalog.referenceList(type, signal)) as unknown;
/// if (Array.isArray(payload)) return payload as ReferenceItem[];
/// const items = (payload as { items?: ReferenceItem[] } | null)?.items;
/// return Array.isArray(items) ? items : [];
/// ```
///
/// The live API sends `{type, count, items}` — the source's own comment at
/// `:230-234` says so. The bare-array branch is nevertheless required, because
/// it exists in the source and FR-LOOK-2 makes the tolerance the behaviour
/// (`F0-AC-53`, `F0-AC-93`). The final `: []` is ported too: an unparseable
/// payload is an empty list, not an error, which is why L-8's failure surface
/// is driven by the transport and not by this function.
List<Map<String, dynamic>> referenceRowsFrom(Object? payload) {
  if (payload is List) {
    return payload.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  if (payload is Map) {
    final Object? items = payload['items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList(growable: false);
    }
  }
  return const <Map<String, dynamic>>[];
}
