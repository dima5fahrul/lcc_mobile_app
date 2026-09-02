/// GOR-269 Group D — the visit-stack invariants `fix-plan.md` § 9.2 names,
/// driven directly against the model.
///
/// `specs.md` § 7.7 makes unit tests the **primary** instrument for `I-1`…`I-8`
/// and the assembled app the integration proof, for a reason worth restating:
/// several of these invariants are about states a widget test can only reach
/// awkwardly or not at all. `I-4`'s bound needs thirty distinct locations, and
/// this app mounts fifteen routes — driving it through the router would mean
/// inventing synthetic ones and would then be testing the invention.
///
/// Every test below names the invariant it covers and the `GOR-269-AC-n` that
/// carries it, so a reviewer can go the other way — from the criterion to the
/// line that proves it — without reading the whole file.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/utils/routes/back_visit_stack.dart';

void main() {
  group('the empty journey', () {
    test('I-8 / AC-30 — stepBack returns null so the framework can exit', () {
      final BackVisitStack stack = BackVisitStack();

      expect(stack.stepBack(), isNull);
      expect(stack.hasPredecessor, isFalse);
      expect(stack.current, isNull);
      expect(stack.predecessor, isNull);
    });

    test('I-8 / AC-18 — one entry is still no predecessor, so `/` exits', () {
      final BackVisitStack stack = BackVisitStack()..record('/');

      expect(stack.depth, 1);
      expect(stack.hasPredecessor, isFalse,
          reason: 'a start destination has nothing behind it, and the exit is '
              'derived from that rather than from the path being `/`');
      expect(stack.stepBack(), isNull);
      expect(stack.entries, <String>['/'],
          reason: 'a refused step must not consume the entry either');
    });
  });

  group('recording forward visits', () {
    test('I-2 / AC-24 — consecutive duplicates collapse', () {
      final BackVisitStack stack = BackVisitStack()
        ..record('/')
        ..record('/wallet')
        ..record('/wallet')
        ..record('/wallet');

      expect(stack.entries, <String>['/', '/wallet']);
      expect(stack.stepBack(), '/',
          reason: 'AC-24: one Back reaches /wallet s predecessor, not /wallet');
    });

    test('I-3 / AC-25 — non-consecutive duplicates do NOT collapse', () {
      final BackVisitStack stack = BackVisitStack()
        ..record('/')
        ..record('/wallet')
        ..record('/');

      expect(stack.entries, <String>['/', '/wallet', '/'],
          reason: 'OQ-8 ruled a true visit stack: / stops being terminal the '
              'moment the citizen walks away from it and back');
      expect(stack.stepBack(), '/wallet');
    });

    test('a location differing only in its query is a different entry', () {
      final BackVisitStack stack = BackVisitStack()
        ..record('/signin')
        ..record('/signin?from=%2Faccount');

      expect(stack.depth, 2,
          reason: 'the `from` intent is part of where the citizen is, so '
              'dropping it on the way back would lose the destination');
    });
  });

  group('I-4 / AC-26 — the journey is bounded', () {
    test('the default bound is at or above the floor of 20', () {
      expect(BackVisitStack.kDefaultBound, greaterThanOrEqualTo(20));
    });

    test('bound + 10 distinct navigations leave at most `bound` entries', () {
      const int bound = BackVisitStack.kDefaultBound;
      final BackVisitStack stack = BackVisitStack();

      for (int i = 0; i < bound + 10; i++) {
        stack.record('/synthetic-$i');
      }

      expect(stack.depth, bound);
    });

    test('eviction is oldest-first, so the recent journey is the one kept', () {
      final BackVisitStack stack = BackVisitStack(bound: 3)
        ..record('/a')
        ..record('/b')
        ..record('/c')
        ..record('/d');

      expect(stack.entries, <String>['/b', '/c', '/d'],
          reason: '/a is the entry a citizen is least likely to want back');
    });

    test('AC-26 — at most `bound` Back presses reach the exit', () {
      const int bound = BackVisitStack.kDefaultBound;
      final BackVisitStack stack = BackVisitStack();
      for (int i = 0; i < bound + 10; i++) {
        stack.record('/synthetic-$i');
      }

      int presses = 0;
      while (stack.stepBack() != null) {
        presses++;
        // A guard rather than a bare loop: if the bound ever regressed, this
        // test should fail with a number rather than hang the suite.
        expect(presses, lessThanOrEqualTo(bound),
            reason: 'Back must never become a two-hundred-press escape');
      }
      // One more press than the walk: the last one is the exit itself.
      expect(presses + 1, lessThanOrEqualTo(bound));
    });

    test('a bound with no room for a predecessor is rejected outright', () {
      expect(() => BackVisitStack(bound: 1), throwsA(isA<AssertionError>()));
    });
  });

  group('I-5 — a back navigation does not re-deepen the journey', () {
    test('AC-27 — two Backs from three deep reach the first location', () {
      // The journey `qa-report.md` § 2.4.1 measured, then walked back.
      final BackVisitStack stack = BackVisitStack()
        ..record('/')
        ..record('/service')
        ..record('/service/resident-certificate');

      final String? first = stack.stepBack();
      // The arrival is observed by the policy exactly as any other location
      // change is; `retreat` is what keeps it from counting as a new visit.
      stack.retreat(first!);
      expect(first, '/service');

      final String? second = stack.stepBack();
      stack.retreat(second!);
      expect(second, '/',
          reason: 'AC-27: the second press reaches `/`, and does not oscillate '
              'between the last two entries');

      expect(stack.entries, <String>['/']);
      expect(stack.hasPredecessor, isFalse,
          reason: 'and a third press exits, which is AC-10 s second half');
    });
  });

  group('retreat — the backward movement the dispatcher declares', () {
    test('an arrival already on the head is a no-op', () {
      final BackVisitStack stack = BackVisitStack()
        ..record('/')
        ..record('/service');

      stack.retreat('/service');

      expect(stack.entries, <String>['/', '/service']);
    });

    test('an arrival at the recorded predecessor shrinks the journey', () {
      // `/news` -> `/news/:slug`, then the navigator pops it back to `/news`.
      // Recording that arrival as a visit is the oscillation bug: the next
      // Back press would walk the citizen forward into the article again.
      final BackVisitStack stack = BackVisitStack()
        ..record('/')
        ..record('/news')
        ..record('/news/a-slug');

      stack.retreat('/news');

      expect(stack.entries, <String>['/', '/news'],
          reason: 'a backward movement must shrink the journey, never grow it');
      expect(stack.stepBack(), '/',
          reason: 'so the next Back reaches `/` and not the article again');
    });

    test('an arrival the journey never recorded replaces the head', () {
      final BackVisitStack stack = BackVisitStack()
        ..record('/')
        ..record('/account');

      stack.retreat('/signin?from=%2Faccount');

      expect(stack.entries, <String>['/', '/signin?from=%2Faccount'],
          reason: 'a redirect intervened; the citizen still moved backward, so '
              'the journey may not deepen');
    });

    test('retreating into an empty journey seeds it rather than losing it', () {
      final BackVisitStack stack = BackVisitStack()..retreat('/help');

      expect(stack.entries, <String>['/help']);
    });
  });

  group('I-6 / AC-28 — the journey does not survive a sign-out', () {
    test('clear empties it, and Back then exits', () {
      final BackVisitStack stack = BackVisitStack()
        ..record('/')
        ..record('/account')
        ..record('/history');

      stack.clear();

      expect(stack.entries, isEmpty);
      expect(stack.stepBack(), isNull,
          reason: 'no stale protected predecessor is left for Back to bounce '
              'off `_redirect` on');
    });

    test('a cleared journey still records normally afterwards', () {
      final BackVisitStack stack = BackVisitStack()
        ..record('/account')
        ..clear()
        ..record('/signin')
        ..record('/');

      expect(stack.entries, <String>['/signin', '/'],
          reason: 'the mechanism is not disabled by a sign-out, only emptied');
    });
  });

  group('I-7 / FC-7 — the model has no persistence surface at all', () {
    test('entries are a defensive copy a caller cannot mutate', () {
      final BackVisitStack stack = BackVisitStack()..record('/');

      expect(() => stack.entries.add('/wallet'),
          throwsA(isA<UnsupportedError>()));
      expect(stack.entries, <String>['/']);
    });
  });
}
