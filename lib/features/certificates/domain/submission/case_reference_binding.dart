/// How the case reference number enters the **second** body of a submission.
///
/// Every one of the five pages POSTs two bodies: `create` without the
/// reference, then `update` (PATCH) with it — because the reference is
/// server-minted and does not exist until `create` returns
/// (specs.md § 2.2 Finding B).
///
/// ## Why this is a named type and not a `String`
///
/// It looks like "the key name differs", and it is not. The two variants differ
/// in **two** things a string cannot carry, and Tier 0 compares serialised
/// bytes, so both are the difference between PASS and FAIL:
///
/// | | key count / order | builder invocations |
/// |---|---|---|
/// | [FlatAppendedReference] | **+1 key, appended LAST** | **once** — the same payload object is spread |
/// | [NestedParameterReference] | **unchanged** count, unchanged order, one value replaced | **twice** — the builder is re-run |
///
/// The second row is `MarriageCertificatePage.tsx:964` `buildFormData("")` and
/// `:981` `buildFormData(reference)`. Each invocation independently
/// re-evaluates `today()` at `:900`. Hoisting it into one call and mutating the
/// document number is the obvious refactor, it is what the flat pages already
/// do, and it **changes behaviour at a midnight boundary** — so the plan
/// records the mechanic rather than leaving it to whoever writes the page
/// (specs.md § 6.2.6 item 1, `F0-AC-14`).
///
/// FamilyBook has **no inhabitant** here (specs.md § 6.2.4). Do not add a
/// `.none` to make F4 fit.
library;

/// Sealed so the two mechanics are a compile-time choice with a name, and so a
/// third cannot be added without every `switch` over it going red.
sealed class CaseReferenceBinding {
  const CaseReferenceBinding();

  /// Resident `"header.ref_no"`; Birth and Death `"header.document_no"` — a
  /// **literal flat key containing a dot**, not a nested object.
  ///
  /// `ResidentCertificatePage.tsx:522`, `BirthDeclarationPage.tsx:835`,
  /// `DeathDeclarationPage.tsx:859`.
  const factory CaseReferenceBinding.flatAppended(String key) =
      FlatAppendedReference;

  /// Marriage and Divorce `["header", "document_no"]` — a **nested object**,
  /// reached by re-running the builder with the reference as its parameter.
  ///
  /// `MarriageCertificatePage.tsx:899`, `DivorceCertificatePage.tsx:799`.
  const factory CaseReferenceBinding.nestedParameter(List<String> path) =
      NestedParameterReference;

  /// True when producing the second body means **re-running** the page's
  /// `buildFormData`, false when it means spreading the first body.
  ///
  /// This is the midnight-boundary fact, expressed as a value the page cannot
  /// get wrong by being tidier than the source.
  bool get rebuildsPayload;

  /// The JSON Pointer this binding writes, in the form the Tier 0 oracles
  /// record it (`refBinding.pointer`): `/header.ref_no` for the flat family,
  /// `/header/document_no` for the nested one. They differ, and a dotted
  /// flattening would make them the same string — which is mutant M5.
  String get pointer;

  /// The two bodies of one submission, produced the way this page produces
  /// them.
  ///
  /// [buildFormData] is the page's own transcription (F1/F2/F3 own those; F0
  /// writes none). It takes the reference to embed and returns the `form_data`
  /// tree.
  ///
  /// The **invocation count** is the observable this method exists to fix in
  /// place: flat calls it once, nested twice.
  SubmissionBodies bodies(
    Map<String, Object?> Function(String reference) buildFormData,
    String reference,
  );
}

/// The pair of `form_data` trees one submission puts on the wire.
class SubmissionBodies {
  const SubmissionBodies({required this.create, required this.update});

  /// The tree sent with `POST /applications`, before any reference exists.
  final Map<String, Object?> create;

  /// The tree sent with `PATCH /applications/{id}`, carrying the reference.
  final Map<String, Object?> update;
}

/// The flat family: Resident, Birth, Death.
class FlatAppendedReference extends CaseReferenceBinding {
  const FlatAppendedReference(this.key);

  /// The literal wire key — `"header.ref_no"` or `"header.document_no"`. The
  /// dot is part of the key, not a path separator.
  final String key;

  @override
  bool get rebuildsPayload => false;

  @override
  String get pointer => '/$key';

  /// Appends [reference] under [key] to a copy of [body], **last**.
  ///
  /// `ResidentCertificatePage.tsx:522`
  /// `form_data: { ...payload, "header.ref_no": current.reference_no }`.
  /// Dart map literals are insertion-ordered `LinkedHashMap`s, so spreading
  /// then adding reproduces the JS spread's key order exactly — the new key
  /// goes last, and the count rises by one.
  Map<String, Object?> appendTo(Map<String, Object?> body, String reference) =>
      <String, Object?>{...body, key: reference};

  @override
  SubmissionBodies bodies(
    Map<String, Object?> Function(String reference) buildFormData,
    String reference,
  ) {
    // ONE invocation. The page builds the payload once and spreads it — which
    // is why Resident's create and update `event_date` can never disagree
    // across a midnight boundary while Marriage's can.
    final Map<String, Object?> payload = buildFormData('');
    return SubmissionBodies(
      create: payload,
      update: appendTo(payload, reference),
    );
  }
}

/// The nested family: Marriage, Divorce.
class NestedParameterReference extends CaseReferenceBinding {
  const NestedParameterReference(this.path);

  /// `["header", "document_no"]` — real nesting, two levels.
  final List<String> path;

  @override
  bool get rebuildsPayload => true;

  @override
  String get pointer => '/${path.join('/')}';

  /// Writes [reference] at [path] inside [body], in place of whatever value the
  /// builder left there.
  ///
  /// **Neither the key count nor the key order changes** at any level — that is
  /// the whole distinction from [FlatAppendedReference.appendTo], and it is
  /// invisible if the binding is expressed as a key name.
  ///
  /// Throws [ArgumentError] when the path does not already exist: the builder
  /// emits `header.document_no` as `""` on the create pass
  /// (`MarriageCertificatePage.tsx:899` `document_no: caseReference,`), so a
  /// missing leaf means the transcription dropped a key, and creating it here
  /// would append it — silently converting this mechanic into the other one.
  Map<String, Object?> writeInto(
    Map<String, Object?> body,
    String reference,
  ) {
    Map<String, Object?> cursor = body;
    for (int i = 0; i < path.length - 1; i++) {
      final Object? next = cursor[path[i]];
      if (next is! Map<String, Object?>) {
        throw ArgumentError.value(
          body,
          'body',
          'nestedParameter path ${path.join('/')} does not resolve: '
              '"${path[i]}" is ${next == null ? 'absent' : next.runtimeType}. '
              'Creating it here would append a key and turn a nested binding '
              'into a flat one.',
        );
      }
      cursor = next;
    }
    final String leaf = path.last;
    if (!cursor.containsKey(leaf)) {
      throw ArgumentError.value(
        body,
        'body',
        'nestedParameter leaf "$leaf" is absent from ${path.join('/')}. The '
            'builder must already emit it (as "" on the create pass).',
      );
    }
    cursor[leaf] = reference;
    return body;
  }

  @override
  SubmissionBodies bodies(
    Map<String, Object?> Function(String reference) buildFormData,
    String reference,
  ) {
    // TWO invocations, deliberately. `MarriageCertificatePage.tsx:964` and
    // `:981`. Each re-evaluates `today()` at `:900`; caching the first result
    // and calling `writeInto` on it would be one invocation and a different
    // payload at midnight.
    return SubmissionBodies(
      create: buildFormData(''),
      update: buildFormData(reference),
    );
  }
}
