/// The help centre's four entities.
///
/// Ports of `types.ts`'s `FaqCategory`, `FaqItem`, `HelpArticle` and
/// `SupportChannel`. One file rather than four, for the reason
/// `home_usecases.dart` gives about its own set: `HelpCenterPage.tsx` is a
/// single screen that renders all four side by side, and four files of a dozen
/// lines each would scatter one page's data model over four places while making
/// the *set* — the thing a reader needs — invisible. They are still four
/// separate types.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'help_entities.freezed.dart';

/// `GET /help/categories` — one topic chip. Four rows on staging:
/// `getting-started` · `services` · `payments` · `account`.
@freezed
abstract class FaqCategory with _$FaqCategory {
  const factory FaqCategory({
    @Default('') String id,

    /// Sent back as `?category=<code>`, and the key
    /// `HelpCenterPage.tsx:64`'s `CATEGORY_TAB` deep-link table is looked up by.
    @Default('') String code,
    @Default(Bilingual(en: '', lo: '')) Bilingual name,

    /// A **lucide name**, resolved through `AppIcons.help` — the 12-name help
    /// scope, not the 54-name service one. `app_icons.dart`'s doc explains why
    /// merging the two registries would be an observable divergence.
    @Default('') String icon,
  }) = _FaqCategory;
}

/// `GET /help/faqs` (paged) — one question.
@freezed
abstract class FaqItem with _$FaqItem {
  const factory FaqItem({
    @Default('') String id,

    /// The category **code**, matched against [FaqCategory.code] to find the
    /// question's swatch and icon (`catMeta`, `HelpCenterPage.tsx:132-136`).
    @Default('') String category,
    @Default(Bilingual(en: '', lo: '')) Bilingual question,
    @Default(Bilingual(en: '', lo: '')) Bilingual answer,
    @Default(<String>[]) List<String> tags,

    /// `a.helpful >= 5 && !searching` gates the "Popular right now" pill
    /// (`:302`).
    @Default(0) int helpful,
    @Default(0) int notHelpful,
  }) = _FaqItem;
}

/// `GET /help/articles` and `GET /help/articles/<slug>` — a step-by-step guide.
@freezed
abstract class HelpArticle with _$HelpArticle {
  const factory HelpArticle({
    @Default('') String id,
    @Default('') String slug,
    @Default(Bilingual(en: '', lo: '')) Bilingual title,

    /// Null when the row carries no body.
    ///
    /// ## The source's claim about when that happens is WRONG, and it is
    /// recorded rather than relied on
    ///
    /// `HelpCenterPage.tsx:443` states it as fact — *"The body only comes with
    /// the single-article endpoint."* Measured against the 2026-08-13 recording
    /// of `GET /help/articles`: **both rows carry a full `body`**
    /// (`test/features/help/data/help_wire_test.dart` asserts the measurement).
    ///
    /// The port keeps the lazy second request anyway, because that is what the
    /// source does and because `guide.data?.slug === g.slug` — not the list
    /// row — is what gates the rendered body. Reading the list body instead
    /// would be a behaviour change justified only by an assumption about an API
    /// that has already proved wrong once, in this very comment.
    ///
    /// The nullability still earns its keep: an empty `Bilingual` could not
    /// express the difference between "no body yet" (skeleton) and "a guide
    /// with an empty body" (blank prose).
    Bilingual? body,
  }) = _HelpArticle;
}

/// `GET /help/channels` — one support channel tile.
@freezed
abstract class SupportChannel with _$SupportChannel {
  const factory SupportChannel({
    @Default('') String id,

    /// `phone` · `email` · `chat` · `office`. Only the first two become links
    /// (`tel:` / `mailto:`, `:492-496`); the other two render as plain tiles.
    @Default('') String kind,
    @Default(Bilingual(en: '', lo: '')) Bilingual label,

    /// The dialable number / address / free text. Rendered verbatim, so it is a
    /// plain `String` on the wire and here.
    @Default('') String value,
    @Default(Bilingual(en: '', lo: '')) Bilingual hours,

    /// A lucide name, resolved through `AppIcons.help`. Note the source passes
    /// a **different fallback** here — `icon(ch.icon, MessageCircle)` at `:490`
    /// versus the default `FileText` everywhere else; see
    /// `help_repository.dart` for how that is preserved.
    @Default('') String icon,
  }) = _SupportChannel;
}
