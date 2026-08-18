/// `refItems` + `useRefList` — Marriage `:161-185`, Divorce `:144-168`,
/// byte-identical (Finding K).
///
/// ## `loading` is computed and read by nothing, and that is the port's job to
/// preserve
///
/// `useRefList` returns `{ options, loading }`. Grepping `\.loading` across
/// both pages returns five hits on Marriage (`:320`, `:337`, `:355` — the
/// location cascade; `:1206` — the record picker; `:1575` — the fee quote) and
/// four on Divorce (`:329`, `:342`, `:360`, `:1121`). **Not one of them is a
/// `useRefList` result.** Six reference lists compute the field on every render
/// and nothing reads it.
///
/// So the reference-backed selects on these two pages render **the same thing**
/// whether their list is loading, loaded-empty or failed: a `<select>` holding
/// only its placeholder. That is § 6.3(i)/(ii) and `fsd.md` D-H, dispositioned
/// **REPRODUCE**.
///
/// The Dart hazard is the opposite of the usual one. An analyzer warns about an
/// unused local; it does not warn about an unread field, so nothing stops an
/// implementer from wiring [loading] into the select "because it is right
/// there" — which would add a state the web does not have (`L-10`(b)).
/// [loading] is therefore declared, populated, and asserted **unread**:
/// `F3-AC-22` greps for readers and `F3-AC-26` asserts the select's render is
/// invariant under it.
///
/// ## No `failed`
///
/// `useRefList` does not expose one. `useQuery`'s error is simply not
/// destructured (`:180`), so the page cannot know the list failed even if it
/// wanted to. Adding a `failed` here would be inventing state — the reason
/// § 6.3(i) forbids mounting `ReferenceSelectView`, expressed one layer down.
library;

import '../../../../i18n/i18n.dart';
import '../../../../presentation/forms/widgets/option.dart';
import '../../../reference/domain/entities/lookup_option.dart';

/// `useRefList(type)`'s return — `{ options, loading }` and nothing else.
class CertificateRefList {
  const CertificateRefList({
    this.options = const <Option>[],
    this.loading = false,
  });

  /// `:182` — `refItems(data).map(item => ({ value: item.code, label: text(item.label, lang) }))`.
  ///
  /// A page-family `SelectOption` in the source (`{value, label}`, no `sub`).
  /// Reusing the kernel's [Option] with `sub` left null renders identically —
  /// only `SearchableSelect` reads `sub`, and no reference-backed select on
  /// these two pages is a `SearchableSelect`.
  final List<Option> options;

  /// **Declared, never read.** See the library comment. `F3-AC-22`.
  final bool loading;

  /// The loading state as the source computes it: `useQuery` in flight, so
  /// `data` is undefined and `refItems(undefined)` is `[]`.
  static const CertificateRefList loadingList =
      CertificateRefList(loading: true);
}

/// `refItems(data)` + the `.map` at `:182`, against the domain's
/// [LookupOption] instead of the wire's `ReferenceItem`.
///
/// `refItems` exists to absorb two wire shapes — a bare array, or
/// `{ type, count, items }`. `features/reference/`'s data layer already
/// normalises both to `List<LookupOption>` before the domain sees them, so the
/// branch has no inhabitant here and is not re-implemented: re-parsing the
/// envelope in `presentation/` would be endpoint knowledge in a widget layer,
/// which `F3-AC-11` greps for.
///
/// `label` is `text(item.label, lang)` — resolved once, at the language the
/// citizen is reading, exactly as `:182` does.
CertificateRefList certificateRefListFrom(
  List<LookupOption> rows,
  Lang lang, {
  bool loading = false,
}) =>
    CertificateRefList(
      options: <Option>[
        for (final LookupOption row in rows)
          Option(value: row.code, label: text(row.label, lang)),
      ],
      loading: loading,
    );

// `labelFor` (`DivorceCertificatePage.tsx:170-171`) deliberately does NOT live
// here. It is **Divorce-only** — Finding K's eleven do not include it, and § 6.2
// admits into this directory only what Finding K measured as duplicated *and*
// semantically identical. Marriage spells the same lookup inline at `:1551` and
// `:1559` with a different fallback (`|| t("dash")` against Divorce's `?? ""`),
// so the two are not one helper with a parameter; they are two call sites that
// happen to read the same list. It belongs in `divorce/`.
//
// This note exists because a shared directory accretes: three of this project's
// recorded governance failures (`B9-AC-10`, `B10-AC-54`, `B10-AC-4`) began as a
// batch-scoped helper that looked harmless one directory up.
