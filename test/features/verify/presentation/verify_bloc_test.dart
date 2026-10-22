/// `VerifyBloc` — Task 4's five-state contract over Task 3's two use cases.
///
/// The repository is a **fake, not a mock**, for the reason
/// `notification_test_helper.dart` records: most claims below are about which
/// state a given *answer* lands in, and a hand-written double keeps every
/// answer mutable per test without a mocktail stub per case. It is wired
/// through the **real use case** (`verifyBlocOver`), so the test proves the
/// bloc against the production composition, not around it.
///
/// The four claims the brief names, and the guards they carry:
///
/// * `VerifySubmitted` → `loading` → `result` — the happy path emits BOTH
///   states, in order, so the page can draw its spinner before the answer.
/// * `not-found` → `result`, **never `failure`** — the guide's "an unknown
///   code or hash is not an HTTP error" (§ Errors), which Task 3's transport
///   test already pinned at the repository; this is the same claim one layer
///   up, where a wrong fold would flash an error screen at a citizen who
///   simply mistyped.
/// * 429 → `tooManyRequests`, a state distinct from `failure` — the guide:
///   ""Please wait a minute"; never retry in a loop". A distinct state is
///   what stops the page from rendering the generic error sentence (and
///   stops a future auto-retry from being wired into the error path).
/// * generic error → `failure(message)` — the server's own sentence, folded
///   by Task 3's `_guard`, rendered verbatim.
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/verify/domain/entities/verification_result.dart';
import 'package:lcc_mobile_app/features/verify/domain/repositories/verify_repository.dart';
import 'package:lcc_mobile_app/features/verify/domain/usecases/verify_usecases.dart';
import 'package:lcc_mobile_app/features/verify/domain/verify_failures.dart';
import 'package:lcc_mobile_app/features/verify/presentation/bloc/verify_bloc.dart';

import '../verify_fixture.dart';

/// A repository double whose next answer each test sets.
class FakeVerifyRepository implements VerifyRepository {
  Either<Failure, VerificationResult> byCode =
      Right<Failure, VerificationResult>(issuedResult());

  Either<Failure, VerificationResult> byHash =
      Right<Failure, VerificationResult>(issuedResult());

  int byCodeCalls = 0;
  final List<String> byCodeArguments = <String>[];

  /// When set, [verifyByCode] suspends on THIS instead of answering
  /// immediately — the `wallet_bloc_test.dart` shape
  /// (`pending[Completer<...>]`), so an in-flight state is observable
  /// deterministically. **Not** a real `Future.delayed`: a timer-based
  /// delay was tried first and it is wrong — the fake's answer would resolve
  /// on whatever wall-clock schedule the test machine happens to give it,
  /// so a single `tester.pump()` sometimes catches `loading` and sometimes
  /// races past it under load, and a timer left pending past the end of
  /// ITS OWN test can fire during the NEXT test and fail that one instead
  /// (measured: this is what broke the unrelated 429 case the one time it
  /// ran under the full suite rather than alone). A `Completer` only
  /// resolves when the test calls `.complete(...)`, so there is nothing
  /// left running once the test does.
  Completer<Either<Failure, VerificationResult>>? pendingByCode;

  @override
  Future<Either<Failure, VerificationResult>> verifyByCode(String code) async {
    byCodeCalls++;
    byCodeArguments.add(code);
    if (pendingByCode != null) return pendingByCode!.future;
    return byCode;
  }

  @override
  Future<Either<Failure, VerificationResult>> verifyDocumentHash(
    String hash,
  ) async {
    return byHash;
  }
}

/// A bloc over the fake, wired through the real use case — the
/// `notificationsBlocOver` shape.
VerifyBloc verifyBlocOver(FakeVerifyRepository repository) => VerifyBloc(
      verifyByCode: VerifyByCode(repository: repository),
    );

void main() {
  late FakeVerifyRepository repository;

  setUp(() {
    repository = FakeVerifyRepository();
  });

  group('VerifySubmitted — the happy path', () {
    blocTest<VerifyBloc, VerifyState>(
      'loading then result, in that order, with the answer carried',
      build: () => verifyBlocOver(repository),
      act: (VerifyBloc bloc) =>
          bloc.add(const VerifySubmitted('RES-7Q4K-19XD')),
      expect: () => <Matcher>[
        isA<VerifyState>().having((VerifyState s) => s.isLoading, 'isLoading',
            isTrue),
        isA<VerifyState>()
            .having((VerifyState s) => s.result, 'result',
                isA<VerificationResult>())
            .having((VerifyState s) => s.result?.status, 'result.status',
                'issued')
            .having((VerifyState s) => s.result?.verifyCode, 'verifyCode',
                'RES-7Q4K-19XD'),
      ],
      verify: (_) {
        expect(repository.byCodeCalls, 1);
      },
    );

    blocTest<VerifyBloc, VerifyState>(
      'the submitted code is sent to the use case as typed',
      build: () => verifyBlocOver(repository),
      act: (VerifyBloc bloc) => bloc.add(const VerifySubmitted('res 7q4k 19xd')),
      expect: () => <Matcher>[
        isA<VerifyState>(),
        isA<VerifyState>(),
      ],
      verify: (_) {
        expect(
          repository.byCodeArguments.single,
          'res 7q4k 19xd',
          reason: 'the server normalises (upper case, dashes, O→0); the '
              'client sends what the citizen typed after the shape gate — and '
              'the bloc is downstream of that gate, so it forwards verbatim',
        );
      },
    );
  });

  group('VerifySubmitted — not-found is a result, never a failure', () {
    blocTest<VerifyBloc, VerifyState>(
      'a 200 not-found answer lands in result with status not-found',
      setUp: () {
        repository.byCode = Right<Failure, VerificationResult>(notFoundResult());
      },
      build: () => verifyBlocOver(repository),
      act: (VerifyBloc bloc) => bloc.add(const VerifySubmitted('RES-0000-0000')),
      expect: () => <Matcher>[
        isA<VerifyState>().having((VerifyState s) => s.isLoading, 'isLoading',
            isTrue),
        isA<VerifyState>()
            .having((VerifyState s) => s.result?.status, 'result.status',
                'not-found')
            .having((VerifyState s) => s.failure, 'failure', isNull)
            .having((VerifyState s) => s.isTooManyRequests, 'isTooManyRequests',
                isFalse),
      ],
      verify: (_) {
        expect(
          repository.byCodeArguments.single,
          'RES-0000-0000',
          reason: 'an unknown code is not an HTTP error (§ Errors) — the '
              'NOT FOUND screen is a result screen, and the request really '
              'went out',
        );
      },
    );
  });

  group('VerifySubmitted — 429', () {
    blocTest<VerifyBloc, VerifyState>(
      'a TooManyRequestsFailure folds to the tooManyRequests state',
      setUp: () {
        repository.byCode = const Left<Failure, VerificationResult>(
          TooManyRequestsFailure('Too many verification attempts.'),
        );
      },
      build: () => verifyBlocOver(repository),
      act: (VerifyBloc bloc) => bloc.add(const VerifySubmitted('RES-7Q4K-19XD')),
      expect: () => <Matcher>[
        isA<VerifyState>().having((VerifyState s) => s.isLoading, 'isLoading',
            isTrue),
        isA<VerifyState>()
            .having((VerifyState s) => s.isTooManyRequests, 'isTooManyRequests',
                isTrue)
            .having((VerifyState s) => s.failure, 'failure', isNull)
            .having((VerifyState s) => s.result, 'result', isNull),
      ],
    );
  });

  group('VerifySubmitted — generic error', () {
    blocTest<VerifyBloc, VerifyState>(
      'a plain Failure folds to failure with the server sentence',
      setUp: () {
        repository.byCode = const Left<Failure, VerificationResult>(
          Failure('Something went wrong on the server.'),
        );
      },
      build: () => verifyBlocOver(repository),
      act: (VerifyBloc bloc) => bloc.add(const VerifySubmitted('RES-7Q4K-19XD')),
      expect: () => <Matcher>[
        isA<VerifyState>().having((VerifyState s) => s.isLoading, 'isLoading',
            isTrue),
        isA<VerifyState>()
            .having((VerifyState s) => s.failure, 'failure',
                'Something went wrong on the server.')
            .having((VerifyState s) => s.isTooManyRequests, 'isTooManyRequests',
                isFalse)
            .having((VerifyState s) => s.result, 'result', isNull),
      ],
    );
  });
}
