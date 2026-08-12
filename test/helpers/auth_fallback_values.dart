import 'package:mocktail/mocktail.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';

void registerAuthFallbackValues() {
  registerFallbackValue(RegisterParams(
    phone: '+8562012345',
    name: 'Test',
    password: 'password123',
  ));
  registerFallbackValue(RequestOtpParams(phone: '+8562012345', purpose: 'login'));
  registerFallbackValue(VerifyOtpParams(
    phone: '+8562012345',
    code: '123456',
    purpose: 'login',
  ));
  registerFallbackValue(LoginParams(phone: '+8562012345', password: 'password123'));
  registerFallbackValue(ForgotPasswordParams(phone: '+8562012345'));
  registerFallbackValue(ResetPasswordParams(
    phone: '+8562012345',
    code: '123456',
    newPassword: 'newpass123',
  ));
}
