/// The strings `HistoryPage.tsx` builds from a `lang === "lo" ? … : …`
/// ternary or a bilingual lookup table, lifted into the `history` namespace.
///
/// ## Why they became keys (§ 6.11)
///
/// Both components bypass i18n for ~14 strings. The alternative to lifting
/// them — an inline `context.locale.languageCode == 'lo' ? … : …` in a Dart
/// widget — would put user-visible copy **outside `easy_localization`**, where
/// the language toggle, `i18n_test.dart`'s key-set parity check and every
/// future i18n audit cannot see it.
///
/// **This is a mechanism change with identical rendered output, and is
/// therefore not a divergence.** The string each key resolves to is
/// byte-identical to the source ternary's arm for that locale, and
/// `test/features/history/presentation/lifted_ternaries_test.dart` asserts it
/// arm by arm against the pinned TSX (`B7-AC-45`) — not against a
/// transcription, which would only prove B7 agrees with itself.
///
/// ## The five B7a arms
///
/// | Key | Source |
/// |---|---|
/// | `tryAgain` | `HistoryPage.tsx:145` |
/// | `emptyHint` | `:276-277` |
/// | `slaOverdue` | `:376-378` |
/// | `slaWaiting` | `:379-381` |
/// | `payment*` (6) | `paymentLabel`'s table, `HistoryDetailPage.tsx:65-74` |
///
/// `paymentLabel` is a table rather than a ternary, but it is the same class of
/// thing — bilingual copy living in a `.tsx` — and `HistoryPage.tsx:359` calls
/// it, so B7a lifts it. The `?? ["—", "—"]` fallback at `:73` becomes
/// [kPaymentLabelKeys]' `unknown` entry, which is the only reason
/// `PaymentState.unknown` has a rendered inhabitant at all.
///
/// **Not lifted:** `HistoryPage.tsx:230-232`'s signed-out sub-copy. § 6.5 rules
/// that whole branch unported — the Flutter route redirects before the page
/// mounts — and porting only its string would leave a key no widget reads,
/// which is the 27-dead-key mistake at a smaller scale.
library;

import '../../../application/domain/entities/case_status.dart';
import '../../../application/domain/usecases/application_usecases.dart';

/// The namespace every key below sits in.
const String kHistoryNs = 'history';

/// `paymentLabel(state, lang)` → the key holding that state's pair.
///
/// Six entries for five wire states: `unknown` is the Dart spelling of the
/// source's `?? ["—", "—"]`.
const Map<PaymentState, String> kPaymentLabelKeys = <PaymentState, String>{
  PaymentState.paid: '$kHistoryNs.paymentPaid',
  PaymentState.pending: '$kHistoryNs.paymentPending',
  PaymentState.failed: '$kHistoryNs.paymentFailed',
  PaymentState.refunded: '$kHistoryNs.paymentRefunded',
  PaymentState.free: '$kHistoryNs.paymentFree',
  PaymentState.unknown: '$kHistoryNs.paymentUnknown',
};

/// `FILTERS` — `HistoryPage.tsx:56-61`, in render order, id → label key.
///
/// The **ids** are `kFilterAll` / `kFilterPending` / … from
/// `application_usecases.dart` (they index `kFilterStatuses`); the **labels**
/// are not parallel to them — the `pending` chip's label key is
/// `filterInReview`, not `filterPending`. Writing the key by transforming the
/// id would silently produce a missing-key placeholder.
/// The ids are the `kFilterStatuses` constants themselves, not string
/// literals: a chip whose id drifted from that table would render, highlight,
/// and filter by nothing.
const List<(String, String)> kHistoryFilterChips = <(String, String)>[
  (kFilterAll, '$kHistoryNs.filterAll'),
  (kFilterPending, '$kHistoryNs.filterInReview'),
  (kFilterApproved, '$kHistoryNs.filterApproved'),
  (kFilterRejected, '$kHistoryNs.filterRejected'),
];
