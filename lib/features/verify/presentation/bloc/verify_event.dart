part of 'verify_bloc.dart';

/// One event — a code was submitted for verification. Typed-code entry (Task
/// 4's page) and the scanner (Task 5) both dispatch it; the bloc is
/// downstream of `certificateCodeFromScanned`, which is the ONLY producer of
/// a non-null code, so nothing here re-validates shape and the code is sent
/// exactly as received — the server normalises it (upper case, dashes,
/// `O`→`0`, `I`/`L`→`1`).
final class VerifySubmitted extends VerifyEvent {
  const VerifySubmitted(this.code);

  final String code;
}
