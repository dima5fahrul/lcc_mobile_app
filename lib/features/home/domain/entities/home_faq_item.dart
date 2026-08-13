/// `HomeFaqItem` — one row of Home's FAQ accordion.
///
/// `GET /help/faqs?per_page=5` (`HomePage.tsx:178`), paged. The source's own
/// comment states why Home reads the help centre's endpoint rather than keeping
/// its own copy: *"The five questions the help centre publishes, rather than a
/// second copy of them kept here — the Help page reads the same endpoint."*
///
/// ## Why this is not `features/help/`'s entity
///
/// Same reason as [HomeNewsItem]: `features/help/**` is B2c's and the two
/// sub-batches run concurrently against disjoint file scopes (§ 3.1, § 2.3).
/// B2c's `FaqItem` will carry `category`, `category_name`, `tags`, `helpful`
/// and `not_helpful` for the help centre's own filtering and the
/// `POST /help/faqs/:id/feedback` control. Home renders a question and an
/// answer.
///
/// ## The mixed-wire-shape trap (§ 5, B2-AC-36)
///
/// `question` and `answer` are the two fields § 5 flags as arriving `{en,lo}`
/// on some rows and as a **plain string** on others. They are `Bilingual` here
/// and the parsing lives in `data/models/home_bilingual.dart`, which accepts
/// both shapes — a model that assumed one would parse a hand-written fixture
/// happily and fail on real staging data, and the failure would surface as an
/// error state that looks like a network problem.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'home_faq_item.freezed.dart';

@freezed
abstract class HomeFaqItem with _$HomeFaqItem {
  const factory HomeFaqItem({
    @Default('') String id,
    @Default(Bilingual(en: '', lo: '')) Bilingual question,
    @Default(Bilingual(en: '', lo: '')) Bilingual answer,
  }) = _HomeFaqItem;
}
