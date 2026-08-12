/// `Bilingual` — a Lao/English label pair returned by place-name lookups.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts`:
///   `interface Bilingual { en: string; lo: string; }`
///
/// Domain entity (no `fromJson` — the data layer's [BilingualModel] handles
/// wire parsing; this class is the framework-agnostic shape the UI and usecases
/// depend on).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'bilingual.freezed.dart';

@freezed
abstract class Bilingual with _$Bilingual {
  const factory Bilingual({
    required String en,
    required String lo,
  }) = _Bilingual;
}
