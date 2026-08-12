/// `RegisterResultModel` — wire-shape mirror of [RegisterResult].
///
/// The nested `challenge` field maps to [OtpChallengeModel] → [OTPChallenge].
/// Ported from `lcc-app/src/app/api/types.ts`:
///   `interface RegisterResult { citizen_id: string; challenge: OTPChallenge; }`
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/register_result.dart';
import '../../../session/domain/entities/otp_challenge.dart';
import 'otp_challenge_model.dart';

part 'register_result_model.freezed.dart';
part 'register_result_model.g.dart';

@freezed
abstract class RegisterResultModel with _$RegisterResultModel {
  const factory RegisterResultModel({
    @JsonKey(name: 'citizen_id') required String citizenId,
    required OtpChallengeModel challenge,
  }) = _RegisterResultModel;

  factory RegisterResultModel.fromJson(Map<String, dynamic> json) =>
      _$RegisterResultModelFromJson(json);
}

extension RegisterResultModelX on RegisterResultModel {
  RegisterResult toEntity() => RegisterResult(
        citizenId: citizenId,
        challenge: challenge.toEntity(),
      );
}
