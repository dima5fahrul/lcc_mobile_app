part of 'help_bloc.dart';

sealed class HelpEvent {
  const HelpEvent();
}

/// The mount fetch, dispatched by the `/help` route builder.
final class HelpStarted extends HelpEvent {
  const HelpStarted();
}

// ── The four retries § 6.6 / B2-AC-16 require ────────────────────────────────
//
// Two of these have a counterpart in the source (`faqs.refetch` at `:269`,
// `guides.refetch` at `:404`, `channels.refetch` at `:477`, `guide.refetch` at
// `:441`) and ONE does not: the topic chips render `categories.data ?? []`
// (`:226`) with no error branch at all. [HelpCategoriesRetried] is therefore an
// **addition**, recorded in the Tier 1 oracle as one rather than smuggled in.

final class HelpCategoriesRetried extends HelpEvent {
  const HelpCategoriesRetried();
}

final class HelpFaqsRetried extends HelpEvent {
  const HelpFaqsRetried();
}

final class HelpGuidesRetried extends HelpEvent {
  const HelpGuidesRetried();
}

final class HelpChannelsRetried extends HelpEvent {
  const HelpChannelsRetried();
}

/// `guide.refetch` — the expanded guide's body — `:441`.
final class HelpGuideRetried extends HelpEvent {
  const HelpGuideRetried();
}

// ── Controls ─────────────────────────────────────────────────────────────────

/// A topic chip — a `FaqCategory.code`, or [kHelpAllTopics].
final class HelpTopicPicked extends HelpEvent {
  const HelpTopicPicked(this.topic);

  final String topic;
}

/// A keystroke in the search field — `:184-187`.
final class HelpSearchChanged extends HelpEvent {
  const HelpSearchChanged(this.query);

  final String query;
}

/// Emitted [kHelpSearchDebounce] after the last [HelpSearchChanged]. Internal
/// to the BLoC; a page never dispatches it.
final class HelpSearchDebounced extends HelpEvent {
  const HelpSearchDebounced(this.query);

  final String query;
}

/// The `X` inside the field — `:194`.
final class HelpSearchCleared extends HelpEvent {
  const HelpSearchCleared();
}

final class HelpPreviousPage extends HelpEvent {
  const HelpPreviousPage();
}

final class HelpNextPage extends HelpEvent {
  const HelpNextPage();
}

/// Expand or collapse a question — `:287`.
final class HelpFaqToggled extends HelpEvent {
  const HelpFaqToggled(this.id);

  final String id;
}

/// Expand or collapse a guide — `:416`. Expanding fetches its body.
final class HelpGuideToggled extends HelpEvent {
  const HelpGuideToggled(this.slug);

  final String slug;
}

/// A thumbs-up / thumbs-down on an expanded question — `:338`, `:345`.
final class HelpFaqVoted extends HelpEvent {
  const HelpFaqVoted({required this.id, required this.helpful});

  final String id;
  final bool helpful;
}
