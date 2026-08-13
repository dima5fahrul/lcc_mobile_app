/// Home's wire → entity parsing, hand-written rather than generated.
///
/// ## Why no `freezed` model layer here
///
/// The service catalogue's `ServiceModel` earns its generated `fromJson`: it
/// mirrors a 21-field row that three layers pass around. Home's five endpoints
/// are read **once each, into an entity, and never round-tripped** — nothing
/// serialises a `HomeSummary` back to JSON. A generated model per endpoint
/// would add five `@freezed` classes, five `.g.dart` files and five
/// `toEntity()` extensions whose only job is to be discarded one line later.
///
/// The thing generation would have bought — that the parse cannot silently
/// disagree with the entity — is bought instead by parsing **against the
/// recorded staging payloads** (B2-AC-36), which is a stronger check than
/// either: `json_serializable` validates a hand-written fixture against a
/// hand-written model and both can be wrong together.
///
/// ## Every read is defensive, and that is a ported behaviour
///
/// `bilingualFrom` accepts *both* wire shapes because § 5 measured that they
/// both occur: `/services` sends `{en,lo}` objects and `/news` / `/help/faqs`
/// send **plain strings** for the same conceptual field. A model that assumed
/// one shape parses a hand-written fixture happily and throws on real staging
/// data — and the throw surfaces as an error panel that looks like a network
/// problem, which is the failure § 5 names by hand.
///
/// A missing scalar becomes its zero value rather than a parse failure, for the
/// reason `bilingual_converter.dart` gives: *"a half-populated pair renders one
/// language blank, which is visible and diagnosable; a thrown parse error takes
/// the whole page down over one bad field."*
library;

import '../../../service/domain/entities/service.dart';
import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/digital_id_card.dart';
import '../../domain/entities/home_faq_item.dart';
import '../../domain/entities/home_news_item.dart';
import '../../domain/entities/home_summary.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primitives
// ─────────────────────────────────────────────────────────────────────────────

/// A string field, or `''`.
String stringAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  return raw is String ? raw : '';
}

/// An integer field, or `fallback`.
///
/// Accepts a `double` because JSON has one number type and a backend that
/// serialises `20000.0` is sending an integer amount — rejecting it would fail
/// on a server-side formatting change that means nothing.
int intAt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final Object? raw = json[key];
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

/// A boolean field, or `fallback`.
bool boolAt(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final Object? raw = json[key];
  return raw is bool ? raw : fallback;
}

/// **The mixed-shape reader** (§ 5, B2-AC-36).
///
/// * `{"en": …, "lo": …}` → both sides, each defaulting to `''`
/// * `"a plain string"` → that string on **both** sides
/// * anything else (null, a number, a list) → an empty pair
///
/// Copying a plain string into both sides is the faithful answer, not a
/// shortcut: `text(value, lang)` (`types.ts:17-22`) falls back
/// `wanted || en || lo || ""`, so a single-language field already renders the
/// same text in either locale on the web. Storing it once and leaving the other
/// side blank would produce the same screen through a different mechanism and
/// would make the fallback untestable.
Bilingual bilingualAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is String) return Bilingual(en: raw, lo: raw);
  if (raw is Map<String, dynamic>) {
    return Bilingual(
      en: raw['en'] is String ? raw['en'] as String : '',
      lo: raw['lo'] is String ? raw['lo'] as String : '',
    );
  }
  return const Bilingual(en: '', lo: '');
}

/// A list of `Bilingual`, tolerating either element shape. Never null.
List<Bilingual> bilingualListAt(Map<String, dynamic> json, String key) {
  final Object? raw = json[key];
  if (raw is! List) return const <Bilingual>[];
  return raw
      .map((Object? element) {
        if (element is String) return Bilingual(en: element, lo: element);
        if (element is Map<String, dynamic>) {
          return Bilingual(
            en: element['en'] is String ? element['en'] as String : '',
            lo: element['lo'] is String ? element['lo'] as String : '',
          );
        }
        return null;
      })
      .whereType<Bilingual>()
      .toList(growable: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rows
// ─────────────────────────────────────────────────────────────────────────────

/// One row of `GET /services` into the shared [Service] entity.
///
/// Deliberately parses **every** field of the row, including the ten Home does
/// not draw, because the entity is the service feature's and a partial
/// construction would make `Service` mean something different depending on
/// which feature built it. See `HomeRepository.getPhase1Services`' doc for why
/// Home holds the shared entity rather than a projection of its own, and
/// `bilingual_converter.dart` for why this cannot simply reuse
/// `ServiceModel.fromJson` (G-L3: `features/home/**` may not import
/// `features/service/data/**`).
Service serviceFrom(Map<String, dynamic> json) => Service(
      id: stringAt(json, 'id'),
      code: stringAt(json, 'code'),
      categoryId: stringAt(json, 'category_id'),
      categoryCode: stringAt(json, 'category_code'),
      name: bilingualAt(json, 'name'),
      shortName: stringAt(json, 'short_name'),
      description: bilingualAt(json, 'description'),
      icon: stringAt(json, 'icon'),
      color: stringAt(json, 'color'),
      feeLak: intAt(json, 'fee_lak'),
      feeMaxLak: intAt(json, 'fee_max_lak'),
      feeIsRange: boolAt(json, 'fee_is_range'),
      slaDays: intAt(json, 'sla_days'),
      processingTime: bilingualAt(json, 'processing_time'),
      requiredDocs: bilingualListAt(json, 'required_docs'),
      requiresPayment: boolAt(json, 'requires_payment'),
      isPhase1: boolAt(json, 'is_phase1'),
      // `active` defaults TRUE, matching `ServiceModel`: a row that omits the
      // flag is live, and defaulting it false would hide services on a
      // backend that stopped sending a column.
      active: boolAt(json, 'active', fallback: true),
      sortOrder: intAt(json, 'sort_order'),
      routePath: stringAt(json, 'route_path'),
      familyBookEffect: stringAt(json, 'family_book_effect'),
    );

/// `GET /me/home-summary`.
HomeSummary homeSummaryFrom(Map<String, dynamic> json) => HomeSummary(
      name: stringAt(json, 'name'),
      verified: boolAt(json, 'verified'),
      eidVerified: boolAt(json, 'eid_verified'),
      activeApplications: intAt(json, 'active_applications'),
      readyDocuments: intAt(json, 'ready_documents'),
      unreadNotifications: intAt(json, 'unread_notifications'),
      walletBalanceLak: intAt(json, 'wallet_balance_lak'),
      nextAction: nextActionFrom(json['next_action']),
      generatedAt: stringAt(json, 'generated_at'),
    );

/// `next_action`, which the wire sends as an object **or as `null`**.
///
/// Null in, null out — the banner's whole condition is
/// `summary.data?.next_action` being present (`HomePage.tsx:393`), so
/// synthesising an empty object here would make every signed-in home render an
/// empty amber banner.
HomeNextAction? nextActionFrom(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  return HomeNextAction(
    action: stringAt(raw, 'action'),
    // `label` stays nullable: an absent label takes the
    // `t("actionRequiredTitle")` branch, and an empty `Bilingual` would take
    // it too — but only if the renderer remembered to check emptiness as well
    // as nullness. One representation, one check.
    label: raw['label'] == null ? null : bilingualAt(raw, 'label'),
    tab: stringAt(raw, 'tab'),
    applicationId: stringAt(raw, 'application_id'),
    referenceNo: stringAt(raw, 'reference_no'),
    status: stringAt(raw, 'status'),
  );
}

/// `GET /me/digital-id`.
DigitalIdCard digitalIdFrom(Map<String, dynamic> json) => DigitalIdCard(
      uin: stringAt(json, 'uin'),
      cardNo: stringAt(json, 'card_no'),
      photoUrl: stringAt(json, 'photo_url'),
      verifyCode: stringAt(json, 'verify_code'),
      verifyUrl: stringAt(json, 'verify_url'),
      qrPayload: stringAt(json, 'qr_payload'),
    );

/// One row of `GET /news`.
HomeNewsItem newsItemFrom(Map<String, dynamic> json) => HomeNewsItem(
      id: stringAt(json, 'id'),
      slug: stringAt(json, 'slug'),
      categoryName: bilingualAt(json, 'category_name'),
      categoryColor: stringAt(json, 'category_color'),
      title: bilingualAt(json, 'title'),
      excerpt: bilingualAt(json, 'excerpt'),
      coverUrl: stringAt(json, 'cover_url'),
      publishedDate: stringAt(json, 'published_date'),
      publishedAt: stringAt(json, 'published_at'),
    );

/// One row of `GET /help/faqs`.
HomeFaqItem faqItemFrom(Map<String, dynamic> json) => HomeFaqItem(
      id: stringAt(json, 'id'),
      question: bilingualAt(json, 'question'),
      answer: bilingualAt(json, 'answer'),
    );
