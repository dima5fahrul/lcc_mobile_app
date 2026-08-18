/// `interface LocationValue` and `blankLocation` — Marriage `:68-80`,
/// Divorce `:66-78`, declared identically on both pages.
///
/// Six fields: the three ids that go on the wire and the three resolved names
/// that only ever reach `address_text`. Keeping the names in the value is what
/// makes `address_text` a **pick-time** resolution rather than a submit-time
/// one — `nameOf(rows, id) = text(found.name, lang)` runs inside the select's
/// `onChange` (Marriage `:307-310`, `:321-327`), so a citizen who picks under
/// `en` and switches to `lo` before submitting still sends the English name.
///
/// That is Guard B in `tier0_payload_equality_test.dart:1116-1141`, and it is
/// deliberately **not** in Guard A: an inequality assertion over
/// `address_text` would fail a faithful port and pass one that re-resolved at
/// submit.
///
/// No Flutter import: the payload builders read this and they are pure.
library;

class CertificateLocationValue {
  const CertificateLocationValue({
    this.provinceId = '',
    this.districtId = '',
    this.villageId = '',
    this.provinceName = '',
    this.districtName = '',
    this.villageName = '',
  });

  final String provinceId;
  final String districtId;
  final String villageId;
  final String provinceName;
  final String districtName;
  final String villageName;

  /// `blankLocation` — six empty strings. Marriage `:77-80`.
  static const CertificateLocationValue blank = CertificateLocationValue();

  CertificateLocationValue copyWith({
    String? provinceId,
    String? districtId,
    String? villageId,
    String? provinceName,
    String? districtName,
    String? villageName,
  }) =>
      CertificateLocationValue(
        provinceId: provinceId ?? this.provinceId,
        districtId: districtId ?? this.districtId,
        villageId: villageId ?? this.villageId,
        provinceName: provinceName ?? this.provinceName,
        districtName: districtName ?? this.districtName,
        villageName: villageName ?? this.villageName,
      );

  @override
  bool operator ==(Object other) =>
      other is CertificateLocationValue &&
      other.provinceId == provinceId &&
      other.districtId == districtId &&
      other.villageId == villageId &&
      other.provinceName == provinceName &&
      other.districtName == districtName &&
      other.villageName == villageName;

  @override
  int get hashCode => Object.hash(provinceId, districtId, villageId,
      provinceName, districtName, villageName);
}
