/// `marriageQuotePortFrom` / `divorceQuotePortFrom` — the capability, with no
/// container involved.
///
/// ## Why this file and not three lines in `certificates_injection_test.dart`
///
/// That file's own library doc draws the line: **wiring** ("the container
/// really does pass it") and **capability** ("the adapter really does turn one
/// thing into the other") are different questions and either alone passes with
/// the defect present. The wiring half lives there, beside the pay seam's, and
/// needs the fourteen-container `init()`/`reset()` scaffolding. This half needs
/// none of it.
///
/// ## And why it reads the recorded catalogue instead of a hand-written row
///
/// `blocked.md` § 1 option (b) is an **accepted citizen-visible divergence**,
/// and the size of what was given up is a property of the real data, not of the
/// adapter. A hand-written `Service(feeLak: 100000)` would let these tests pass
/// while saying nothing about what a citizen is actually shown. So the marriage
/// and divorce rows come from
/// `docs/fidelity-baseline/2026-08-13/oracle/api/services.json` — what
/// `GET /services` really answered — parsed through the production model, the
/// same recording B2's Tier 1 oracle uses.
///
/// The consequence is that the sharpest fact about option (b) is **measured
/// here and goes red if it changes**: the `marriage` row is a *range*
/// (`fee_is_range: true`, 100,000–250,000 LAK), so the adapter answers the
/// bottom of it. See `marriageQuotePortFrom`'s doc.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/certificates/di/certificates_bloc_injection.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_cubit.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_services.dart';

import '../../../helpers/service_test_helper.dart';

Service _row(String code) =>
    recordedServices().firstWhere((Service s) => s.code == code);

GetServices _catalogue(FakeServiceRepository repository) =>
    GetServices(repository: repository);

void main() {
  group('the recorded catalogue — what option (b) is actually reading', () {
    test('the `marriage` row is a RANGE, and that is the cost of option (b)',
        () {
      final Service marriage = _row('marriage');

      expect(marriage.feeIsRange, isTrue,
          reason: 'the catalogue itself says this service does not have one '
              'price. The web resolves which one applies by POSTing '
              '/services/marriage/quote with {has_foreign_spouse, '
              'creates_betrothal_record}; option (b) cannot, and answers '
              'fee_lak — the bottom of the range. If this row ever stops '
              'being a range, re-read blocked.md § 1: the divergence would '
              'have shrunk.');
      expect(marriage.feeLak, 100000);
      expect(marriage.feeMaxLak, 250000);
    });

    test('the `divorce` row is flat, so option (b) costs that page nothing',
        () {
      final Service divorce = _row('divorce');

      expect(divorce.feeIsRange, isFalse);
      expect(divorce.feeLak, 10000);
      expect(divorce.feeMaxLak, 0);
    });

  });

  // `Service` carries no itemisation member at all — that is *why* both ports
  // answer `const []`, and the assertion that it stays empty is made against
  // the ports themselves below, where an invented line item would show up.

  group('marriageQuotePortFrom', () {
    test('answers the `marriage` row\'s fee, and an EMPTY breakdown', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      final MarriageQuotePort port =
          marriageQuotePortFrom(_catalogue(repository));

      final Either<Failure, MarriageQuote> result = await port();

      final MarriageQuote quote = result.getOrElse(
        () => throw StateError('the recorded catalogue has a marriage row'),
      );
      expect(quote.feeLak, _row('marriage').feeLak);
      expect(quote.feeLak, 100000);
      expect(quote.lines, isEmpty,
          reason: 'a catalogue row has one fee_lak and no breakdown. '
              ':776-777 is `breakdown ?? lines ?? []`, so an empty list is a '
              'state the source renders too — inventing rows to fill the fee '
              'card would be the dishonest alternative.');
    });

    test('it reads the WHOLE catalogue once and selects by code — it does not '
        'guess a row', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      final MarriageQuotePort port =
          marriageQuotePortFrom(_catalogue(repository));

      await port();

      expect(repository.serviceCalls.length, 1);
      expect(repository.serviceCalls.single.search, isNull,
          reason: 'GetServicesParams.all — the same unnarrowed read '
              'residentServiceReader makes');
      expect(repository.serviceCalls.single.category, isNull);
    });

    test('THE CAPABILITY RULE — a catalogue with no `marriage` row is a '
        'Failure, not a zero fee', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      repository.nextServices = recordedServices()
          .where((Service s) => s.code != 'marriage')
          .toList(growable: false);
      final MarriageQuotePort port =
          marriageQuotePortFrom(_catalogue(repository));

      final Either<Failure, MarriageQuote> result = await port();

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) => expect(f.message, contains('marriage')),
        (MarriageQuote q) => fail('a missing row must not yield ${q.feeLak}'),
      );
      // The failure mode this rules out: a `MarriageQuote(feeLak: 0)` renders
      // "0 LAK" in the review card and as the pay button's amount, as though
      // the API had said the marriage were free.
    });

    test('an EMPTY catalogue is a Failure too — the empty-subject case', () async {
      final FakeServiceRepository repository =
          FakeServiceRepository(services: const <Service>[]);
      final MarriageQuotePort port =
          marriageQuotePortFrom(_catalogue(repository));

      expect((await port()).isLeft(), isTrue);
    });

    test('a transport failure stays a Failure and is not swallowed', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      repository.failServices();
      final MarriageQuotePort port =
          marriageQuotePortFrom(_catalogue(repository));

      final Either<Failure, MarriageQuote> result = await port();

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) => expect(f.message, 'stubbed services failure',
            reason: 'the API\'s own sentence reaches the citizen, rather than '
                'being replaced by a generic one at the seam'),
        (MarriageQuote q) => fail('unreachable'),
      );
    });
  });

  group('divorceQuotePortFrom', () {
    test('answers the `divorce` row\'s fee, and an EMPTY breakdown', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      final DivorceQuotePort port =
          divorceQuotePortFrom(_catalogue(repository));

      final DivorceQuote quote = (await port()).getOrElse(
        () => throw StateError('the recorded catalogue has a divorce row'),
      );

      expect(quote.feeLak, _row('divorce').feeLak);
      expect(quote.feeLak, 10000);
      expect(quote.lines, isEmpty);
    });

    test('THE CAPABILITY RULE — a missing `divorce` row is a Failure', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      repository.nextServices = recordedServices()
          .where((Service s) => s.code != 'divorce')
          .toList(growable: false);

      expect(
        (await divorceQuotePortFrom(_catalogue(repository))()).isLeft(),
        isTrue,
      );
    });

    test('the two ports do not answer each other\'s row', () async {
      final FakeServiceRepository repository = FakeServiceRepository();

      final MarriageQuote marriage =
          (await marriageQuotePortFrom(_catalogue(repository))())
              .getOrElse(() => throw StateError('marriage row missing'));
      final DivorceQuote divorce =
          (await divorceQuotePortFrom(_catalogue(repository))())
              .getOrElse(() => throw StateError('divorce row missing'));

      expect(marriage.feeLak, isNot(equals(divorce.feeLak)),
          reason: 'a crossed service code is invisible in every other '
              'assertion in this file — both ports would still answer a real '
              'fee off a real row');
    });
  });

  test('the service-code constants agree with `CertificateForm`', () {
    // The claim `kResidentServiceCodeConstant`'s doc makes about a
    // `certificates_di_test.dart` that does not exist in the tree, made true
    // for F3's two constants. Two independent transcriptions of one source
    // line are only worth more than deduplication if something checks they
    // still agree.
    expect(kMarriageServiceCodeConstant, CertificateForm.marriage.serviceCode);
    expect(kDivorceServiceCodeConstant, CertificateForm.divorce.serviceCode);
  });
}
