/// The Marriage fee is **static** — `blocked.md` § 1 option (b), approved
/// 2026-08-18.
///
/// ## What this file is guarding, and why the obvious test does not guard it
///
/// The source recomputes the fee whenever `has_foreign_spouse` or
/// `creates_betrothal_record` changes (`MarriageCertificatePage.tsx:766-774`).
/// Option (b) reads the fee off the `marriage` service-catalogue row instead,
/// so it cannot vary — a **citizen-visible** loss on a form whose price
/// genuinely does depend on both inputs, accepted deliberately and recorded in
/// `marriage_form_cubit.dart`'s library doc and in `marriageQuotePortFrom`.
///
/// A test that loaded the page and read the fee once would pass with the
/// re-fire fully restored. So every test here does three things together:
///
/// 1. **drives a real transition** and asserts the *input* actually flipped —
///    otherwise the fee holding still proves nothing but that nothing happened;
/// 2. hands the cubit a port that answers a **different number on every
///    invocation**, so any second read is visible in the fee itself, not only
///    in a call count;
/// 3. asserts the call count as well, so a recomputation that happened to
///    return the same number is still caught.
///
/// The structural half of the property is not asserted here because it is not
/// runtime-observable: [MarriageQuotePort] declares **no parameters**, so no
/// implementation can see either input. That is a compile error to undo. This
/// file covers the other half — that the cubit does not re-read, and does not
/// derive a fee of its own from form state.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

/// The catalogue's `marriage` row as recorded on 2026-08-13 — see
/// `certificate_quote_port_test.dart`, which reads it rather than restating it.
const int kRecordedMarriageFeeLak = 100000;

/// A quote port that answers a **different fee every time it is called**.
///
/// The first call answers [kRecordedMarriageFeeLak]; every later one answers
/// [poisoned]. So "the fee did not change" and "the port was read once" are two
/// independent observations of the same property, and a test that asserted only
/// the first would still fail if the re-fire came back.
class _DriftingQuote {
  static const int poisoned = 999999;

  int calls = 0;

  Future<Either<Failure, MarriageQuote>> read() async {
    final int fee = calls == 0 ? kRecordedMarriageFeeLak : poisoned;
    calls++;
    return Right<Failure, MarriageQuote>(
      MarriageQuote(feeLak: fee, lines: const <MarriageQuoteLine>[]),
    );
  }
}

Future<Either<Failure, List<LookupOption>>> _lookup(
  LookupKey key, {
  String? parentId,
  PagingMode paging = PagingMode.all,
}) async =>
    const Right<Failure, List<LookupOption>>(<LookupOption>[
      LookupOption(
        id: 'lao',
        code: 'lao',
        label: Bilingual(en: 'Lao', lo: 'ລາວ'),
      ),
      LookupOption(
        id: 'thai',
        code: 'thai',
        label: Bilingual(en: 'Thai', lo: 'ໄທ'),
      ),
    ]);

MarriageFormCubit _cubit(MarriageQuotePort? loadQuote) => MarriageFormCubit(
      clock: SubmissionClock.fixed(DateTime(2026, 8, 18, 9)),
      getLookupOptions: _lookup,
      createApplication: (Map<String, Object?> _) async =>
          throw StateError('create must not run in this test'),
      updateApplication: (String _, Map<String, Object?> __) async =>
          throw StateError('update must not run in this test'),
      addAttachment: (
        String _,
        PickedAttachment __, {
        required String slot,
        required String kind,
        required String label,
      }) async =>
          throw StateError('addAttachment must not run in this test'),
      submitApplication: (String _) async =>
          throw StateError('submit must not run in this test'),
      lang: Lang.en,
      loadQuote: loadQuote,
    );

void main() {
  test(
      'the fee does not move across has_foreign_spouse transitions — and the '
      'input really does flip', () async {
    final _DriftingQuote quote = _DriftingQuote();
    final MarriageFormCubit cubit = _cubit(quote.read);
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.quote.data!.feeLak, kRecordedMarriageFeeLak);
    expect(quote.calls, 1);
    expect(marriageAnyForeign(cubit.state.form), isFalse,
        reason: 'both nationalities start blank');

    // false -> true, on spouse A. `:761-763`.
    cubit.patchSpouseA(
      (MarriageSpouseInfo s) => s.copyWith(nationality: 'thai'),
    );
    expect(marriageAnyForeign(cubit.state.form), isTrue,
        reason: 'the transition under test must actually have happened — '
            'otherwise this whole test is asserting that nothing changed '
            'nothing');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.quote.data!.feeLak, kRecordedMarriageFeeLak);

    // Still true via spouse B while A goes back to `lao` — the source would
    // hold the higher fee across this pair of edits, and re-fire twice.
    cubit.patchSpouseB(
      (MarriageSpouseInfo s) => s.copyWith(nationality: 'thai'),
    );
    cubit.patchSpouseA((MarriageSpouseInfo s) => s.copyWith(nationality: 'lao'));
    expect(marriageAnyForeign(cubit.state.form), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.quote.data!.feeLak, kRecordedMarriageFeeLak);

    // true -> false.
    cubit.patchSpouseB((MarriageSpouseInfo s) => s.copyWith(nationality: 'lao'));
    expect(marriageAnyForeign(cubit.state.form), isFalse);

    // And an address edit, which used to re-fire the quote as a side effect of
    // driving the cascade.
    cubit.patchSpouseA(
      (MarriageSpouseInfo s) => s.copyWith(
        address: const CertificateLocationValue(provinceId: 'p-1'),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.quote.data!.feeLak, kRecordedMarriageFeeLak,
        reason: 'the fee is the `marriage` catalogue row and no form state '
            'may move it (blocked.md § 1 option (b)). A drifting port makes a '
            'second read show up here as 999999.');
    expect(quote.calls, 1,
        reason: 'six edits, one read. Any re-fire is a second GET /services '
            'for a number that cannot have changed.');
  });

  test(
      'the fee does not move across creates_betrothal_record transitions — '
      'and that input really does flip too', () async {
    final _DriftingQuote quote = _DriftingQuote();
    final MarriageFormCubit cubit = _cubit(quote.read);
    addTearDown(cubit.close);

    await cubit.load();
    expect(marriageIncludeBetrothalFee(cubit.state.form), isFalse);
    expect(cubit.state.quote.data!.feeLak, kRecordedMarriageFeeLak);

    // false -> true. On the web this is the edit that visibly raises the price
    // (`:764`, `:772`).
    cubit.setBetrothalMode(MarriageBetrothalMode.newRecord);
    expect(marriageIncludeBetrothalFee(cubit.state.form), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.quote.data!.feeLak, kRecordedMarriageFeeLak);

    // true -> false, through both routes out of `newRecord`.
    cubit.setBetrothalMode(MarriageBetrothalMode.none);
    expect(marriageIncludeBetrothalFee(cubit.state.form), isFalse);
    cubit.setBetrothalMode(MarriageBetrothalMode.newRecord);
    cubit.resetBetrothal();
    expect(marriageIncludeBetrothalFee(cubit.state.form), isFalse);

    // The third arm, which also runs `searchRecords`.
    cubit.setBetrothalMode(MarriageBetrothalMode.existing);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.quote.data!.feeLak, kRecordedMarriageFeeLak);
    expect(quote.calls, 1,
        reason: 'five mode changes, one read. `creates_betrothal_record` still '
            'reaches the wire payload — it just no longer moves the price.');
  });

  test('the two inputs are still computed and still reach the payload — the '
      'fee is what was given up, not the fields', () async {
    // Guards the reverse mistake: "the fee is static" is not licence to stop
    // computing `creates_betrothal_record`, which is a `form_data` field
    // (`:904`) and a Tier 0 leaf. If someone deletes the input plumbing along
    // with the re-fire, this goes red.
    final MarriageFormCubit cubit = _cubit(_DriftingQuote().read);
    addTearDown(cubit.close);

    await cubit.load();
    cubit.setBetrothalMode(MarriageBetrothalMode.newRecord);
    cubit.patchSpouseA(
      (MarriageSpouseInfo s) => s.copyWith(nationality: 'thai'),
    );

    expect(marriageIncludeBetrothalFee(cubit.state.form), isTrue);
    expect(marriageAnyForeign(cubit.state.form), isTrue);
  });

  test('a catalogue with no `marriage` row surfaces as an ERROR, never as a '
      'zero fee', () async {
    // The Capability Rule half. `certificateServiceReader` answers a `Failure`
    // when the row is absent, and the page must render that rather than a
    // confident 0 LAK — F1 made the same call for `residentServiceReader`.
    final MarriageFormCubit cubit = _cubit(
      () async => const Left<Failure, MarriageQuote>(
        Failure('The marriage service is not in the catalogue.'),
      ),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.quote.data, isNull,
        reason: 'no fee is not the same as a fee of zero');
    expect(
      cubit.state.quote.error,
      'The marriage service is not in the catalogue.',
    );
    expect(cubit.state.quote.loading, isFalse);
  });

  test('with NO port at all the quote stays in its loading state — the '
      'pre-option-(b) behaviour, kept only for direct construction', () async {
    // Production cannot reach this: `certificates_bloc_injection.dart` always
    // passes `marriageQuotePortFrom`, and `certificates_injection_test.dart`
    // asserts it. Recorded here so a reader who finds a null port in a widget
    // test knows what it renders — an eternal `…`, not a zero.
    final MarriageFormCubit cubit = _cubit(null);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.quote.loading, isTrue);
    expect(cubit.state.quote.data, isNull);
    expect(cubit.state.quote.error, isNull);
  });
}
