/// `VerifyBloc` — the verify feature's presentation state, over Task 3's
/// `VerifyByCode` use case.
///
/// ## One event, five states
///
/// `VerifySubmitted(code)` is the whole input surface today: typed-code entry
/// and the scanner (Task 5) both land here after `certificateCodeFromScanned`
/// has gated the text, which is why the bloc forwards the code verbatim —
/// the server normalises it, the guide says "send what the user typed after
/// steps 2 and 3", and the bloc is downstream of step 2's gate.
///
/// ## The fold mirrors the repository's, one state per branch
///
/// Task 3's `VerifyRepositoryImpl._guard` folds the transport into exactly
/// three shapes this bloc maps one-to-one:
///
/// * `Right(VerificationResult)` → `VerifyState.result` — **whatever the
///   status is**, including `not-found`, which the guide sends as a normal
///   200 (`valid: false`). Collapsing it into an error here would put an
///   error screen in front of a citizen who mistyped a code, the exact
///   misreading of § Errors the transport test pins at the repository.
/// * `Left(TooManyRequestsFailure)` → `VerifyState.tooManyRequests` — the
///   guide's "Please wait a minute"; never retry in a loop". The distinct
///   state carries no message and no retry affordance can be built from it.
/// * `Left(Failure)` → `VerifyState.failure(message)` — the server's own
///   sentence, rendered verbatim by the page.
///
/// `TooManyRequestsFailure` is the verify slice's own leaf of `Failure`
/// (`application_failures.dart`'s `NotFoundFailure` pattern): Equatable
/// compares `runtimeType` before `props`, so a bloc test can tell the 429
/// branch from the generic one on the Left's type alone.
///
/// ## No generation guard, deliberately
///
/// The notifications bloc stamps in-flight requests because `bloc`'s default
/// transformer is concurrent and two bell taps race. Verification has no
/// equivalent race today: the entry page dispatches on submit, the scanner
/// (Task 5) dispatches one scan at a time, and a slower stale answer arriving
/// over a faster fresh one would need two in-flight submissions from one page
/// — which the UI (a blocking submit + a full-frame checking state) does not
/// offer. Adding the guard is Task 5's call if the scanner's flow makes the
/// race real; it is not preempted here.
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/verification_result.dart';
import '../../domain/usecases/verify_usecases.dart';
import '../../domain/verify_failures.dart';

part 'verify_bloc.freezed.dart';
part 'verify_event.dart';
part 'verify_state.dart';

/// One event today; `sealed` so Task 5's scanner-added events (and Task 7's
/// PDF-check wiring) must be enumerated by any `switch` that appears.
sealed class VerifyEvent {
  const VerifyEvent();
}

class VerifyBloc extends Bloc<VerifyEvent, VerifyState> {
  VerifyBloc({required this.verifyByCode}) : super(const VerifyState.initial()) {
    on<VerifySubmitted>(_onSubmitted);
  }

  final VerifyByCode verifyByCode;

  Future<void> _onSubmitted(
    VerifySubmitted event,
    Emitter<VerifyState> emit,
  ) async {
    emit(const VerifyState.loading());

    final Either<Failure, VerificationResult> answer =
        await verifyByCode(event.code);

    if (answer.isRight()) {
      emit(
        VerifyState.result(
          answer.getOrElse(() => throw StateError('unreachable: isRight')),
        ),
      );
      return;
    }

    final Failure failure =
        answer.fold((Failure f) => f, (VerificationResult _) => throw StateError('unreachable: isLeft'));
    if (failure is TooManyRequestsFailure) {
      emit(const VerifyState.tooManyRequests());
      return;
    }
    emit(VerifyState.failure(failure.message));
  }
}
