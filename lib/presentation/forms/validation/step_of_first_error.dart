/// `formValidation.tsx:172-183` — the step a submission's first complaint
/// belongs to.
///
/// The API answers 422 with every missing field at once and they rarely live on
/// the step the citizen is standing on, so the form jumps to the **earliest**
/// one before scrolling to it. [steps] maps a field path to the step that
/// renders it.
///
/// ## D-G is NOT fixed here, and that is deliberate
///
/// `fsd.md` § 13.1 assigns D-G ("422 errors do not route on 4 of 5 wizards") to
/// F0. Measured, the kernel already provides this function **correctly**; the
/// defect is that Marriage and Divorce have no `FIELD_STEP` map at all and
/// Birth's and Death's have gaps. Those are **page** artefacts.
///
/// F0 must not invent a `FIELD_STEP` for a page it is not writing — doing so
/// means authoring five pages' error maps before the pages exist, and every one
/// of them would be a guess that Tier 1 cannot check. F0 ports the function;
/// F1/F2/F3 supply correct maps (specs.md § 6.3.6).
library;

/// The lowest step number among [paths] that [steps] knows about, or null when
/// it knows about none of them.
///
/// Paths absent from [steps] are **skipped**, not treated as step 0 — that is
/// the `if (step === undefined) continue;` at `formValidation.tsx:179`, and it
/// is why a page with a gappy map silently fails to route rather than routing
/// to the wrong step.
int? stepOfFirstError(List<String> paths, Map<String, int> steps) {
  int? earliest;
  for (final String path in paths) {
    final int? step = steps[path];
    if (step == null) continue;
    if (earliest == null || step < earliest) earliest = step;
  }
  return earliest;
}
