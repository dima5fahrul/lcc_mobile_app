/// The six auth usecases' `Params` value objects.
///
/// Not decoration: every one extends `Equatable`, and their `props` is what
/// makes `verify(() => usecase(LoginParams(...)))` match by value in the
/// existing usecase tests and what lets `blocTest` compare emitted states. A
/// field left out of `props` makes two different requests compare equal, and
/// the assertions that rely on argument matching quietly stop discriminating.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';

void main() {
  group('LoginParams', () {
    test('compares by phone and password', () {
      const LoginParams a = LoginParams(phone: '+856201', password: 'p1');

      expect(a, const LoginParams(phone: '+856201', password: 'p1'));
      expect(a.hashCode,
          const LoginParams(phone: '+856201', password: 'p1').hashCode);
      expect(a, isNot(const LoginParams(phone: '+856202', password: 'p1')));
      expect(a, isNot(const LoginParams(phone: '+856201', password: 'p2')));
    });
  });

  group('RegisterParams', () {
    test('compares by every field, email included', () {
      const RegisterParams a = RegisterParams(
        phone: '+856201',
        name: 'A',
        password: 'p1',
        email: 'a@x.io',
      );

      expect(
        a,
        const RegisterParams(
          phone: '+856201',
          name: 'A',
          password: 'p1',
          email: 'a@x.io',
        ),
      );
      expect(
        a,
        isNot(const RegisterParams(phone: '+856201', name: 'A', password: 'p1')),
        reason: 'a null email is a different request',
      );
      expect(
        a,
        isNot(const RegisterParams(
          phone: '+856201',
          name: 'B',
          password: 'p1',
          email: 'a@x.io',
        )),
      );
    });
  });

  group('RequestOtpParams', () {
    test('compares by phone and purpose', () {
      const RequestOtpParams a =
          RequestOtpParams(phone: '+856201', purpose: 'login');

      expect(a, const RequestOtpParams(phone: '+856201', purpose: 'login'));
      expect(
        a,
        isNot(const RequestOtpParams(phone: '+856201', purpose: 'forgot')),
        reason: 'login and forgot are different challenges for one phone',
      );
    });
  });

  group('VerifyOtpParams', () {
    test('compares by phone, code and purpose', () {
      const VerifyOtpParams a = VerifyOtpParams(
        phone: '+856201',
        code: '123456',
        purpose: 'login',
      );

      expect(
        a,
        const VerifyOtpParams(
          phone: '+856201',
          code: '123456',
          purpose: 'login',
        ),
      );
      expect(
        a,
        isNot(const VerifyOtpParams(
          phone: '+856201',
          code: '654321',
          purpose: 'login',
        )),
      );
    });
  });

  group('ForgotPasswordParams', () {
    test('compares by phone', () {
      expect(
        const ForgotPasswordParams(phone: '+856201'),
        const ForgotPasswordParams(phone: '+856201'),
      );
      expect(
        const ForgotPasswordParams(phone: '+856201'),
        isNot(const ForgotPasswordParams(phone: '+856202')),
      );
    });
  });

  group('ResetPasswordParams', () {
    test('compares by phone, code and the new password', () {
      const ResetPasswordParams a = ResetPasswordParams(
        phone: '+856201',
        code: '123456',
        newPassword: 'n1',
      );

      expect(
        a,
        const ResetPasswordParams(
          phone: '+856201',
          code: '123456',
          newPassword: 'n1',
        ),
      );
      expect(
        a,
        isNot(const ResetPasswordParams(
          phone: '+856201',
          code: '123456',
          newPassword: 'n2',
        )),
      );
    });
  });
}
