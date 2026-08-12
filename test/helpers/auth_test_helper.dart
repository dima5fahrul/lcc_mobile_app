import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';
import 'package:lcc_mobile_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lcc_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRegister extends Mock implements Register {}

class MockRequestOtp extends Mock implements RequestOtp {}

class MockVerifyOtp extends Mock implements VerifyOtp {}

class MockLogin extends Mock implements Login {}

class MockForgotPassword extends Mock implements ForgotPassword {}

class MockResetPassword extends Mock implements ResetPassword {}

/// A validation [ApiException] with one field error, for tests that assert the
/// bloc surfaces `fieldMap()` into state.
ApiException fakeValidationApiException({
  String field = 'phone',
  String message = 'phone is invalid',
  int status = 422,
}) {
  return ApiException(
    status: status,
    code: 'VALIDATION_ERROR',
    message: 'Validation failed',
    fields: [FieldError(field: field, message: message)],
  );
}
