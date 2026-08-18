/// **The state machine — `F4-AC-20`, `F4-AC-26`, `F4-AC-35`, `F4-AC-38`,
/// `F4-AC-39`, `F4-AC-41`, `F4-AC-40`.**
///
/// Every test here builds the cubit from hand-written doubles and never calls
/// `DependencyInjection.init()`. That is `F1-AC-10`'s property applied to this
/// batch: the page's behaviour must be assertable without a container.
library;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/family_book.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/family_book/domain/family_book_copy.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/bloc/family_book_cubit.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/bloc/family_book_state.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../family_book_test_helper.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-35 — loading initialises to `enabled`, not to `true`
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-35 the initial state IS `useQuery`\'s initial state', () {
    test('authenticated: loading starts TRUE', () {
      final FamilyBookCubit c = cubitOver(
        FakeFamilyBookRepository(),
        authenticated: true,
      );
      addTearDown(c.close);
      expect(c.state.loading, isTrue);
      expect(c.state.showsLoading, isTrue);
      expect(c.state.showsSignedOut, isFalse);
    });

    test('signed out: loading starts FALSE, so the skeleton never renders', () {
      // `hooks.ts:46` is `useState(enabled)` and `enabled` is
      // `isAuthenticated` (`:201`). A port that initialised to `true` would
      // show a skeleton to a signed-out citizen for one frame, which the web
      // never does.
      final FamilyBookCubit c = cubitOver(
        FakeFamilyBookRepository(),
        authenticated: false,
      );
      addTearDown(c.close);
      expect(c.state.loading, isFalse);
      expect(c.state.showsLoading, isFalse);
      expect(c.state.showsSignedOut, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-20 — zero requests when signed out
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-20 the read is gated on `enabled`', () {
    test('a signed-out load() issues ZERO reads', () async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository();
      final FamilyBookCubit c = cubitOver(repo, authenticated: false);
      addTearDown(c.close);

      await c.load();

      // The capability, not the flag: `enabled: false` in `hooks.ts:42`,
      // `:59-62` skips the fetch entirely rather than discarding its answer.
      expect(repo.reads, 0);
      expect(c.state.showsSignedOut, isTrue);
    });

    test('a signed-out refetch() also issues zero reads', () async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository();
      final FamilyBookCubit c = cubitOver(repo, authenticated: false);
      addTearDown(c.close);

      await c.refetch();
      expect(repo.reads, 0);
    });

    test('an authenticated load() issues exactly one', () async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(book: householdFixture());
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();
      expect(repo.reads, 1);
      expect(c.state.showsHousehold, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The cascade — a 404 is the empty state
  // ───────────────────────────────────────────────────────────────────────────
  group('the eight-state cascade', () {
    test('a 404 lands on EMPTY, not on ERROR', () async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository(
        readFailure: const NotFoundFailure('family book not found'),
      );
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();

      expect(c.state.showsError, isFalse);
      expect(c.state.showsEmpty, isTrue);
      expect(c.state.showsStepIndicator, isFalse);
    });

    test('any other failure lands on ERROR', () async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(readFailure: const Failure('boom'));
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();

      expect(c.state.showsError, isTrue);
      expect(c.state.showsEmpty, isFalse);
      expect(c.state.failure?.message, 'boom');
    });

    test('success is checked AFTER !book, so a success always has a book '
        'behind it', () async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(book: householdFixture());
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();
      await c.requestCopy(Lang.en); // 1 -> 2
      await c.requestCopy(Lang.en); // 2 -> 3
      await c.requestCopy(Lang.en); // submit

      expect(c.state.showsSuccess, isTrue);
      expect(c.state.book, isNotNull);
      // The step indicator's guard is `book`, and it is still true here — but
      // the success screen does not render the frame at all, which is what
      // `family_book_page_test.dart` asserts.
      expect(c.state.showsStepIndicator, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-38 — retry re-enters LOADING
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-38 retry re-enters loading, not `refreshing`', () {
    test('the book is cleared and loading is set before the read runs',
        () async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(book: householdFixture());
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await c.load();
      expect(c.state.book, isNotNull);

      final List<FamilyBookViewState> seen = <FamilyBookViewState>[];
      final StreamSubscription<FamilyBookViewState> sub =
          c.stream.listen(seen.add);
      addTearDown(sub.cancel);

      await c.refetch();
      await Future<void>.delayed(Duration.zero);

      // The very first state a retry produces must be the skeleton: `error`
      // implies `data === undefined`, so `hasData` is false and `useQuery`
      // re-enters `loading` rather than `refreshing` (`hooks.ts:67-68`). A
      // port that kept the stale book would render a spinner over content the
      // web has already discarded.
      expect(seen.first.loading, isTrue);
      expect(seen.first.book, isNull);
      expect(seen.first.showsLoading, isTrue);
    });

    test('retrying from the error state re-reads', () async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(readFailure: const Failure('boom'));
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();
      expect(c.state.showsError, isTrue);

      repo
        ..readFailure = null
        ..book = householdFixture();
      await c.refetch();

      expect(repo.reads, 2);
      expect(c.state.showsHousehold, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-39 / F4-AC-41 — the CTA and the failed write
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-39 a failed request-copy leaves the citizen on step 3', () {
    Future<FamilyBookCubit> onStep3(FakeFamilyBookRepository repo) async {
      final FamilyBookCubit c = cubitOver(repo);
      await c.load();
      await c.requestCopy(Lang.en);
      await c.requestCopy(Lang.en);
      expect(c.state.step, 3);
      return c;
    }

    test('the failure renders inline and the step does not move', () async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository(
        book: householdFixture(),
        writeFailure: const Failure('The registry refused this request.'),
      );
      final FamilyBookCubit c = await onStep3(repo);
      addTearDown(c.close);

      await c.requestCopy(Lang.en);

      expect(c.state.step, 3, reason: 'the catch block does not reset it');
      expect(c.state.submitted, isNull, reason: 'no navigation to success');
      expect(c.state.submitPending, isFalse);
      expect(c.state.submitFailure?.message,
          'The registry refused this request.');
      expect(c.state.showsHousehold, isTrue);
    });

    test('a retry after a failure clears the previous message first', () async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository(
        book: householdFixture(),
        writeFailure: const Failure('first'),
      );
      final FamilyBookCubit c = await onStep3(repo);
      addTearDown(c.close);

      await c.requestCopy(Lang.en);
      expect(c.state.submitFailure?.message, 'first');

      repo.writeFailure = null;
      await c.requestCopy(Lang.en);
      expect(c.state.submitFailure, isNull);
      expect(c.state.submitted, isNotNull);
    });

    test('F4-AC-41 a second tap while pending does not send a second '
        'request', () async {
      final Completer<void> gate = Completer<void>();
      final _GatedRepository repo =
          _GatedRepository(gate, gateWrites: true)
            ..book = householdFixture();
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();
      await c.requestCopy(Lang.en);
      await c.requestCopy(Lang.en);

      unawaited(c.requestCopy(Lang.en));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.submitPending, isTrue);

      await c.requestCopy(Lang.en);
      expect(repo.writes, 1, reason: '`disabled={requestCopy.pending}`');

      gate.complete();
      await Future<void>.delayed(Duration.zero);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // goBack — F4-AC-40
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-40 goBack decrements, then defers to the caller', () {
    test('on step > 1 it decrements and answers false', () async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(book: householdFixture());
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();
      await c.requestCopy(Lang.en);
      expect(c.state.step, 2);

      expect(c.goBack(), isFalse);
      expect(c.state.step, 1);
    });

    test('on step 1 it answers true and leaves the step alone', () async {
      final FamilyBookCubit c = cubitOver(FakeFamilyBookRepository());
      addTearDown(c.close);
      expect(c.goBack(), isTrue);
      expect(c.state.step, 1);
    });

    test('it answers true in every bookless state too — the chevron is wired '
        'in all of them', () async {
      final FamilyBookCubit c = cubitOver(
        FakeFamilyBookRepository(readFailure: const Failure('boom')),
      );
      addTearDown(c.close);
      await c.load();
      expect(c.state.showsError, isTrue);
      expect(c.goBack(), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // T0-2 — the reason is read at SUBMIT time
  // ───────────────────────────────────────────────────────────────────────────
  group('the reason string is the locale in force AT SUBMIT', () {
    test('reasonFor answers each locale\'s COPY bytes', () {
      expect(FamilyBookCubit.reasonFor(Lang.en), kFbCopyReason.en);
      expect(FamilyBookCubit.reasonFor(Lang.lo), kFbCopyReason.lo);
      expect(kFbCopyReason.en, isNot(kFbCopyReason.lo));
    });

    test('flipping the language between mount and submit sends the NEW '
        'bytes', () async {
      // The page opens in English and the citizen switches to Lao on the
      // review step. `say()` closes over `lang` and is called at `:236`, so
      // the Lao string goes out. A cubit that captured `lang` at construction
      // would send the English one and would pass every test that never flips.
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(book: householdFixture());
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);

      await c.load();
      await c.requestCopy(Lang.en);
      await c.requestCopy(Lang.en);
      await c.requestCopy(Lang.lo);

      expect(repo.reasons.single, kFbCopyReason.lo);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The fee — F4-NV-5
  // ───────────────────────────────────────────────────────────────────────────
  group('the review step\'s fee', () {
    test('with no reader the SEED stands — which is what getServiceConfig '
        'answers before the catalogue lands', () async {
      final FamilyBookCubit c =
          cubitOver(FakeFamilyBookRepository(book: householdFixture()));
      addTearDown(c.close);
      await c.load();
      expect(c.state.copyFee, kFamilyBookSeedFeeLak);
      expect(kFamilyBookSeedFeeLak, 0, reason: 'serviceConfig.ts:115');
    });

    test('a catalogue answer REPLACES the seed', () async {
      final FamilyBookCubit c = cubitOver(
        FakeFamilyBookRepository(book: householdFixture()),
        readFee: () async => 12000,
      );
      addTearDown(c.close);
      await c.load();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.copyFee, 12000);
    });

    test('a catalogue FAILURE leaves the seed and does not touch the page\'s '
        'error state', () async {
      // `useServiceConfig`'s contract: `config` is never undefined, so a fee
      // never renders blank. Folding a catalogue failure into the page's error
      // card would put "We could not load your family book" in front of a
      // citizen whose family book loaded fine.
      final FamilyBookCubit c = cubitOver(
        FakeFamilyBookRepository(book: householdFixture()),
        readFee: () async => null,
      );
      addTearDown(c.close);
      await c.load();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.copyFee, kFamilyBookSeedFeeLak);
      expect(c.state.showsError, isFalse);
      expect(c.state.showsHousehold, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-26 — a late answer after disposal
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-26 a response arriving after disposal is discarded', () {
    test('closing mid-flight does not throw and writes no state', () async {
      final Completer<void> gate = Completer<void>();
      final _GatedRepository repo =
          _GatedRepository(gate, gateReads: true)..book = householdFixture();
      final FamilyBookCubit c = cubitOver(repo);

      final Future<void> inFlight = c.load();
      await Future<void>.delayed(Duration.zero);

      await c.close();
      gate.complete();

      // Without the `isClosed` guard this throws
      // `StateError: Cannot emit new states after calling close`, which a
      // citizen leaving the page mid-request would see as a framework error —
      // an added failure mode, L-10's first clause.
      await expectLater(inFlight, completes);
      expect(c.isClosed, isTrue);
    });
  });
}

/// A repository whose answers wait on a caller-held gate.
///
/// Two flags rather than one, because the two tests that need it need opposite
/// halves: the double-tap test holds the **write** open while the read must
/// complete, and the disposal test holds the **read** open.
class _GatedRepository extends FakeFamilyBookRepository {
  _GatedRepository(this.gate, {this.gateReads = false, this.gateWrites = false});

  final Completer<void> gate;
  final bool gateReads;
  final bool gateWrites;

  @override
  Future<Either<Failure, FamilyBook>> getFamilyBook() async {
    if (gateReads) await gate.future;
    return super.getFamilyBook();
  }

  @override
  Future<Either<Failure, ApplicationRow>> requestFamilyBookCopy(
    String reason,
  ) async {
    // Counted BEFORE the await so a second tap while the first is in flight is
    // visible as a second write if the guard ever stops working.
    writes++;
    reasons.add(reason);
    if (gateWrites) await gate.future;
    return Right<Failure, ApplicationRow>(row);
  }
}
