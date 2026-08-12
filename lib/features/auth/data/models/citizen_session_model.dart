/// `CitizenSessionModel` — wire-shape mirror of [CitizenSession].
///
/// The session feature exposes the [CitizenSession] entity and the
/// [CitizenAccountModel] / [AuthTokensModel] for its nested fields, but does
/// not expose a session-level model. This model composes those two existing
/// models so the auth datasource can parse the session returned by login /
/// verify-otp without duplicating the field mapping.
///
/// Ported from `lcc-app/src/app/api/types.ts`:
///   `interface CitizenSession { actor: "citizen"; citizen: CitizenAccount; tokens: AuthTokens; }`
///
/// NOTE: This model is hand-written (not `json_serializable`-generated) because
/// `json_serializable` could not resolve the cross-feature nested
/// `CitizenAccountModel`/`AuthTokensModel` types during codegen (the analyzer
/// reported `InvalidType`). The `fromJson`/`toJson` delegates to the nested
/// models' own generated `fromJson`/`toJson`, which are already produced by
/// the session feature's codegen. This keeps the wire-parse boundary inside
/// the datasource without a separate generator pass.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/data/models/auth_tokens_model.dart';
import '../../../session/data/models/citizen_account_model.dart';
import '../../../session/domain/entities/citizen_session.dart';

part 'citizen_session_model.freezed.dart';

@freezed
abstract class CitizenSessionModel with _$CitizenSessionModel {
  const factory CitizenSessionModel({
    required String actor,
    required CitizenAccountModel citizen,
    required AuthTokensModel tokens,
  }) = _CitizenSessionModel;

  /// Hand-written `fromJson` that delegates to the nested models' generated
  /// `fromJson`. Avoids a `json_serializable` pass that cannot resolve the
  /// cross-feature nested types.
  factory CitizenSessionModel.fromJson(Map<String, dynamic> json) {
    return CitizenSessionModel(
      actor: json['actor'] as String,
      citizen: CitizenAccountModel.fromJson(
        json['citizen'] as Map<String, dynamic>,
      ),
      tokens: AuthTokensModel.fromJson(
        json['tokens'] as Map<String, dynamic>,
      ),
    );
  }
}

extension CitizenSessionModelX on CitizenSessionModel {
  CitizenSession toEntity() => CitizenSession(
        actor: actor,
        citizen: citizen.toEntity(),
        tokens: tokens.toEntity(),
      );
}
