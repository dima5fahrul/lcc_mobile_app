/// Forms v2 — the split Latin-name keys and the new optional fields
/// (`MOBILE-API-E-CERTIFICATES.md` § "Application forms v2").
///
/// One golden-style assertion set per service, in the shape the payload gate
/// uses everywhere else in this tree: `jsonEncode` of what the builder returns,
/// compared as the wire sees it.
///
/// ## The one rule every assertion here protects
///
/// **Every new field is OPTIONAL — absent key when empty, never `""`.** That is
/// what keeps every existing comparison green: the Tier 0 oracles, the F0-AC-82
/// spouse-key guard, F2-AC-31's key arithmetic and the B4 golden logs were all
/// captured before these fields existed, and none of their fixtures populate
/// them. A port that emitted the new keys unconditionally — or worse, emitted
/// them as empty strings — would move bytes on twenty documents for no input
/// at all.
///
/// ## The key names are the guide's, verbatim
///
/// | Service | Keys |
/// | --- | --- |
/// | resident | `applicant.surname`, `applicant.given_name` |
/// | birth | `child.child_surname`, `child.child_given_name`, `child.child_time_of_birth` (`HH:MM`), `parents.mother.{surname,given_name}`, `parents.father.{surname,given_name}` |
/// | death | `deceased.deceased_surname`, `deceased.deceased_given_name` |
/// | marriage | `spouses.spouse_{a,b}.{surname,given_name,place_of_birth}` |
/// | divorce | `spouses.{husband,wife}.{surname,given_name,place_of_birth}`, `basis.children_minor_count` (bare number), `basis.custody_with` (`husband\|wife\|shared\|not-applicable`) |
///
/// Each form keeps its existing shape — flat dotted keys on Resident/Birth/
/// Death, nested objects on Marriage/Divorce — because the guide says the
/// server reads both and the form should keep sending whichever shape it
/// already sends.
library;

import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_steps.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_steps.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_payload.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_payload.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';

import '../../../helpers/app_test_harness.dart';

/// The label tests render real widgets; any reach into the write slice or the
/// reference catalogue is a bug in the test, so both collaborators throw.
class _RefRepo implements ReferenceRepository {
  const _RefRepo();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
        '${invocation.memberName} — the label tests must not reach the '
        'reference catalogue',
      );
}

class _UnusedRepo implements ApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
        '${invocation.memberName} — the label tests must not reach the '
        'write slice',
      );
}

void main() {
  // Any fixed instant; none of the new keys read the clock.
  final SubmissionClock clock = SubmissionClock.fixed(
    DateTime(2026, 8, 14, 2),
  );

  /// Walks every leaf of a decoded payload and fails on `""` under any of the
  /// v2 keys — the "never send `''`" half of the rule, stated structurally.
  void expectNoEmptyV2Value(
    Map<String, Object?> payload,
    Set<String> v2LeafKeys,
  ) {
    void walk(String path, Object? value) {
      if (value is Map<String, Object?>) {
        value.forEach((String k, Object? v) => walk(
              path.isEmpty ? k : '$path.$k',
              v,
            ));
        return;
      }
      if (v2LeafKeys.contains(path)) {
        expect(value, isNot(''),
            reason: '$path is a v2 optional field — absent key when empty, '
                'never `""`');
      }
    }

    walk('', payload);
  }

  group('resident — applicant split names (flat dotted shape)', () {
    const Set<String> v2Keys = <String>{
      'applicant.surname',
      'applicant.given_name',
    };

    test('populated → both keys present, adjacent to citizen_name', () {
      final Map<String, Object?> payload = buildResidentFormData(
        const ResidentFormData(
          citizenName: 'ສົມສະໜັກ ວົງຄຳພັນ',
          surname: 'VONGKHAMPHANH',
          givenName: 'SOMSANACK',
          age: '34',
        ),
        clock,
      );
      final String json = jsonEncode(payload);
      expect(payload['applicant.surname'], 'VONGKHAMPHANH');
      expect(payload['applicant.given_name'], 'SOMSANACK');
      // Wire order: the split names sit with the other applicant identity
      // keys — after the full name, before the age.
      final int atName = json.indexOf('"applicant.citizen_name"');
      final int atSurname = json.indexOf('"applicant.surname"');
      final int atGiven = json.indexOf('"applicant.given_name"');
      final int atAge = json.indexOf('"applicant.age"');
      expect(atSurname, greaterThan(atName), reason: json);
      expect(atGiven, greaterThan(atSurname), reason: json);
      expect(atAge, greaterThan(atGiven), reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });

    test('empty → both keys absent, and nowhere a "" for them', () {
      final Map<String, Object?> payload = buildResidentFormData(
        const ResidentFormData(citizenName: 'ສົມສະໜັກ ວົງຄຳພັນ', age: '34'),
        clock,
      );
      final String json = jsonEncode(payload);
      expect(payload.containsKey('applicant.surname'), isFalse, reason: json);
      expect(payload.containsKey('applicant.given_name'), isFalse,
          reason: json);
      expect(json.contains('surname'), isFalse, reason: json);
      expect(json.contains('given_name'), isFalse, reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });
  });

  group('birth — child split names + time of birth, parent split names', () {
    const Set<String> v2Keys = <String>{
      'child.child_surname',
      'child.child_given_name',
      'child.child_time_of_birth',
      'parents.mother.surname',
      'parents.mother.given_name',
      'parents.father.surname',
      'parents.father.given_name',
    };

    test('populated → child keys emitted in the flat shape, HH:MM verbatim',
        () {
      final Map<String, Object?> payload = buildBirthFormData(
        const BirthFormData(
          child: BirthChildInfo(
            fullName: 'ນ້ອງສົມສະໜັກ',
            surname: 'VONGSAVANH',
            givenName: 'SOMSANACK',
            dob: '2026-08-01',
            timeOfBirth: '06:45',
          ),
        ),
        clock,
        legalBasisText: 'x',
      );
      final String json = jsonEncode(payload);
      expect(payload['child.child_surname'], 'VONGSAVANH', reason: json);
      expect(payload['child.child_given_name'], 'SOMSANACK', reason: json);
      // HH:MM — the guide's format, passed through verbatim.
      expect(payload['child.child_time_of_birth'], '06:45', reason: json);
      expect(json.contains('"child.child_time_of_birth":"06:45"'), isTrue,
          reason: json);
      // Order: split names after the full name, time after the dob.
      final int atChildName = json.indexOf('"child.child_name"');
      final int atSurname = json.indexOf('"child.child_surname"');
      final int atGiven = json.indexOf('"child.child_given_name"');
      final int atDob = json.indexOf('"child.child_dob"');
      final int atTime = json.indexOf('"child.child_time_of_birth"');
      expect(atSurname, greaterThan(atChildName), reason: json);
      expect(atGiven, greaterThan(atSurname), reason: json);
      expect(atDob, greaterThan(atGiven), reason: json);
      expect(atTime, greaterThan(atDob), reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });

    test('populated → mother and father carry the keys under their OWN '
        'prefixes only — the bare `parents` mirror does not grow', () {
      final Map<String, Object?> payload = buildBirthFormData(
        const BirthFormData(
          mother: BirthParentInfo(
            fullName: 'ແມ່',
            surname: 'SISOUK',
            givenName: 'BOUNTHAN',
          ),
          father: BirthParentInfo(
            fullName: 'ພໍ່',
            surname: 'SISOUK',
            givenName: 'KHAMLA',
          ),
        ),
        clock,
        legalBasisText: 'x',
      );
      final String json = jsonEncode(payload);
      expect(payload['parents.mother.surname'], 'SISOUK', reason: json);
      expect(payload['parents.mother.given_name'], 'BOUNTHAN', reason: json);
      expect(payload['parents.father.surname'], 'SISOUK', reason: json);
      expect(payload['parents.father.given_name'], 'KHAMLA', reason: json);
      // The guide names `parents.mother.*` and `parents.father.*` and nothing
      // at the bare prefix — the schema's mandatory set is the mother's mirror
      // and must not grow a key the schema does not validate.
      expect(payload.containsKey('parents.surname'), isFalse, reason: json);
      expect(payload.containsKey('parents.given_name'), isFalse, reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });

    test('father-unknown → the collapsed father block carries no split keys',
        () {
      final Map<String, Object?> payload = buildBirthFormData(
        const BirthFormData(
          fatherUnknown: true,
          father: BirthParentInfo(surname: 'SISOUK', givenName: 'KHAMLA'),
        ),
        clock,
        legalBasisText: 'x',
      );
      final String json = jsonEncode(payload);
      expect(json.contains('parents.father.surname'), isFalse, reason: json);
      expect(json.contains('parents.father.given_name'), isFalse,
          reason: json);
    });

    test('empty → none of the seven keys anywhere, never ""', () {
      final Map<String, Object?> payload = buildBirthFormData(
        const BirthFormData(child: BirthChildInfo(fullName: 'ນ້ອງສົມສະໜັກ')),
        clock,
        legalBasisText: 'x',
      );
      final String json = jsonEncode(payload);
      for (final String key in v2Keys) {
        expect(payload.containsKey(key), isFalse, reason: '$key — $json');
      }
      expect(json.contains('surname'), isFalse, reason: json);
      expect(json.contains('given_name'), isFalse, reason: json);
      expect(json.contains('time_of_birth'), isFalse, reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });
  });

  group('death — deceased split names (flat dotted shape)', () {
    const Set<String> v2Keys = <String>{
      'deceased.deceased_surname',
      'deceased.deceased_given_name',
    };

    test('populated → both keys present, adjacent to deceased_name', () {
      final Map<String, Object?> payload = buildDeathFormData(
        const DeathFormData(
          deceased: DeathDeceasedInfo(
            fullName: 'ຜູ້ຕາຍ',
            surname: 'VONGSAVANH',
            givenName: 'SOMSANACK',
          ),
        ),
        clock,
        legalBasisText: 'x',
      );
      final String json = jsonEncode(payload);
      expect(payload['deceased.deceased_surname'], 'VONGSAVANH', reason: json);
      expect(payload['deceased.deceased_given_name'], 'SOMSANACK',
          reason: json);
      final int atName = json.indexOf('"deceased.deceased_name"');
      final int atSurname = json.indexOf('"deceased.deceased_surname"');
      final int atGiven = json.indexOf('"deceased.deceased_given_name"');
      final int atFingerprint = json.indexOf('"deceased.deceased_fingerprint"');
      expect(atSurname, greaterThan(atName), reason: json);
      expect(atGiven, greaterThan(atSurname), reason: json);
      expect(atFingerprint, greaterThan(atGiven), reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });

    test('empty → both keys absent, never ""', () {
      final Map<String, Object?> payload = buildDeathFormData(
        const DeathFormData(deceased: DeathDeceasedInfo(fullName: 'ຜູ້ຕາຍ')),
        clock,
        legalBasisText: 'x',
      );
      final String json = jsonEncode(payload);
      expect(payload.containsKey('deceased.deceased_surname'), isFalse,
          reason: json);
      expect(payload.containsKey('deceased.deceased_given_name'), isFalse,
          reason: json);
      expect(json.contains('surname'), isFalse, reason: json);
      expect(json.contains('given_name'), isFalse, reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });
  });

  group('marriage — spouse split names + place of birth (nested shape)', () {
    const Set<String> v2Keys = <String>{
      'spouses.spouse_a.surname',
      'spouses.spouse_a.given_name',
      'spouses.spouse_a.place_of_birth',
      'spouses.spouse_b.surname',
      'spouses.spouse_b.given_name',
      'spouses.spouse_b.place_of_birth',
    };

    test('populated → nested inside each spouse object, both spouses', () {
      final Map<String, Object?> payload = buildMarriageFormData(
        const MarriageFormData(
          spouseA: MarriageSpouseInfo(
            fullName: 'ຍິງ ກຽວວິໄລ',
            surname: 'KEOVILAY',
            givenName: 'SOMSAVANH',
            placeOfBirth: 'Vientiane',
          ),
          spouseB: MarriageSpouseInfo(
            fullName: 'ຊາຍ ວົງສະຫວັນ',
            surname: 'VONGSAVANH',
            givenName: 'KHAMLA',
            placeOfBirth: 'Savannakhet',
          ),
        ),
        clock,
        '',
      );
      final Map<String, Object?> spouses =
          payload['spouses']! as Map<String, Object?>;
      final Map<String, Object?> a = spouses['spouse_a']! as Map<String, Object?>;
      final Map<String, Object?> b = spouses['spouse_b']! as Map<String, Object?>;
      expect(a['surname'], 'KEOVILAY');
      expect(a['given_name'], 'SOMSAVANH');
      expect(a['place_of_birth'], 'Vientiane');
      expect(b['surname'], 'VONGSAVANH');
      expect(b['given_name'], 'KHAMLA');
      expect(b['place_of_birth'], 'Savannakhet');
      // The section-level mirror is the API's validation surface for the
      // seven existing keys and gains nothing — the guide lists no
      // `spouses.surname`.
      expect(spouses.containsKey('surname'), isFalse);
      expect(spouses.containsKey('place_of_birth'), isFalse);
      expectNoEmptyV2Value(payload, v2Keys);
    });

    test('empty → no new key inside either spouse object, never ""', () {
      final Map<String, Object?> payload = buildMarriageFormData(
        const MarriageFormData(
          spouseA: MarriageSpouseInfo(fullName: 'ຍິງ ກຽວວິໄລ'),
          spouseB: MarriageSpouseInfo(fullName: 'ຊາຍ ວົງສະຫວັນ'),
        ),
        clock,
        '',
      );
      final Map<String, Object?> spouses =
          payload['spouses']! as Map<String, Object?>;
      for (final String which in <String>['spouse_a', 'spouse_b']) {
        final Map<String, Object?> s =
            spouses[which]! as Map<String, Object?>;
        expect(s.containsKey('surname'), isFalse, reason: which);
        expect(s.containsKey('given_name'), isFalse, reason: which);
        expect(s.containsKey('place_of_birth'), isFalse, reason: which);
      }
      expectNoEmptyV2Value(payload, v2Keys);
    });
  });

  group('divorce — spouse split names, place of birth, basis custody block',
      () {
    const Set<String> v2Keys = <String>{
      'spouses.husband.surname',
      'spouses.husband.given_name',
      'spouses.husband.place_of_birth',
      'spouses.wife.surname',
      'spouses.wife.given_name',
      'spouses.wife.place_of_birth',
      'basis.children_minor_count',
      'basis.custody_with',
    };

    DivorceFormData formWithCustody(String custodyWith) =>
        DivorceFormData(
          husband: const DivorceSpouseInfo(
            fullName: 'ຊາຍ',
            surname: 'VONGSAVANH',
            givenName: 'KHAMLA',
            placeOfBirth: 'Savannakhet',
          ),
          wife: const DivorceSpouseInfo(
            fullName: 'ຍິງ',
            surname: 'KEOVILAY',
            givenName: 'SOMSAVANH',
            placeOfBirth: 'Vientiane',
          ),
          hasChildren: true,
          children: DivorceChildren(
            list: 'one daughter, 7',
            custody: 'joint custody agreed',
            minorCount: 2,
            custodyWith: custodyWith,
          ),
        );

    test('populated → nested inside husband/wife objects', () {
      final Map<String, Object?> payload =
          buildDivorceFormData(formWithCustody('shared'), clock, '');
      final Map<String, Object?> spouses =
          payload['spouses']! as Map<String, Object?>;
      final Map<String, Object?> h =
          spouses['husband']! as Map<String, Object?>;
      final Map<String, Object?> w = spouses['wife']! as Map<String, Object?>;
      expect(h['surname'], 'VONGSAVANH');
      expect(h['given_name'], 'KHAMLA');
      expect(h['place_of_birth'], 'Savannakhet');
      expect(w['surname'], 'KEOVILAY');
      expect(w['given_name'], 'SOMSAVANH');
      expect(w['place_of_birth'], 'Vientiane');
      // The six-key mirror gains nothing — the guide lists no
      // `spouses.surname` at section level.
      expect(spouses.containsKey('surname'), isFalse);
      expectNoEmptyV2Value(payload, v2Keys);
    });

    test('children_minor_count is a BARE JSON number, never a string', () {
      final Map<String, Object?> payload =
          buildDivorceFormData(formWithCustody('shared'), clock, '');
      final Map<String, Object?> basis =
          payload['basis']! as Map<String, Object?>;
      final Object? count = basis['children_minor_count'];
      expect(count, 2);
      expect(count, isA<int>(),
          reason: 'the guide types it `number` — `"2"` is different bytes');
      // Nested shape: the leaf serialises without the `basis.` prefix.
      expect(jsonEncode(payload).contains('"children_minor_count":2'), isTrue,
          reason: 'bare number in the serialised body — no quotes');
      expect(jsonEncode(payload).contains('"children_minor_count":"2"'),
          isFalse, reason: 'never a quoted string');
      expectNoEmptyV2Value(payload, v2Keys);
    });

    test('custody_with serialises each of the four guide values', () {
      for (final String value in <String>[
        'husband',
        'wife',
        'shared',
        'not-applicable',
      ]) {
        final Map<String, Object?> payload =
            buildDivorceFormData(formWithCustody(value), clock, '');
        final Map<String, Object?> basis =
            payload['basis']! as Map<String, Object?>;
        expect(basis['custody_with'], value, reason: value);
        // Nested shape: the leaf serialises without the `basis.` prefix.
        expect(
          jsonEncode(payload).contains('"custody_with":"$value"'),
          isTrue,
          reason: value,
        );
        expectNoEmptyV2Value(payload, v2Keys);
      }
    });

    test('empty → none of the eight keys anywhere, never ""', () {
      final Map<String, Object?> payload = buildDivorceFormData(
        const DivorceFormData(
          husband: DivorceSpouseInfo(fullName: 'ຊາຍ'),
          wife: DivorceSpouseInfo(fullName: 'ຍິງ'),
        ),
        clock,
        '',
      );
      final String json = jsonEncode(payload);
      final Map<String, Object?> spouses =
          payload['spouses']! as Map<String, Object?>;
      for (final String which in <String>['husband', 'wife']) {
        final Map<String, Object?> s =
            spouses[which]! as Map<String, Object?>;
        expect(s.containsKey('surname'), isFalse, reason: '$which — $json');
        expect(s.containsKey('given_name'), isFalse, reason: '$which — $json');
        expect(s.containsKey('place_of_birth'), isFalse,
            reason: '$which — $json');
      }
      final Map<String, Object?> basis =
          payload['basis']! as Map<String, Object?>;
      expect(basis.containsKey('children_minor_count'), isFalse, reason: json);
      expect(basis.containsKey('custody_with'), isFalse, reason: json);
      expect(json.contains('custody_with'), isFalse, reason: json);
      expectNoEmptyV2Value(payload, v2Keys);
    });
  });

  group('labels — the v2 fields render real text, not raw keys', () {
    // easy_localization returns the KEY ITSELF on a miss, so a label wired
    // through the wrong namespace renders as literal `birth.surnameLabel` —
    // green payloads, broken screen. These pump the real step widgets with
    // the real bundle and assert the rendered text of one v2 site per form
    // that reads from the shared `forms` namespace.
    //
    // `pumpAndSettle` cannot be used: `EasyLocalization` keeps a frame
    // scheduled and it never returns (see birth_page_widget_test.dart). Three
    // explicit pumps clear the layout passes.
    Future<void> pumpStep(WidgetTester tester, Widget step) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(body: SingleChildScrollView(child: step)),
            ),
          ),
        ),
      );
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('birth step 2 renders the child surname label and placeholder',
        (WidgetTester tester) async {
      final BirthFormCubit cubit = BirthFormCubit(
        clock: clock,
        getLookupOptions:
            GetLookupOptions(repository: const _RefRepo()),
        createApplication: CreateApplication(repository: _UnusedRepo()),
        updateApplication: UpdateApplication(repository: _UnusedRepo()),
        addAttachment: AddAttachment(repository: _UnusedRepo()),
        submitApplication: SubmitApplication(repository: _UnusedRepo()),
        loadService: () async => Left<Failure, Service>(Failure('unused')),
        loadPaymentMethods: () async =>
            const Right<Failure, List<PaymentMethod>>(<PaymentMethod>[]),
        readLegalBasisText: () => 'unused',
      );
      await pumpStep(tester, BirthStep2(cubit: cubit, state: cubit.state));

      // FieldLabel uppercases its Text child (`_Uppercase` in
      // field_label.dart), so the render is the uppercased string.
      expect(find.text('SURNAME (LATIN SCRIPT)'), findsOneWidget,
          reason: 'the v2 label must come from the `forms` namespace — '
              'a raw `birth.surnameLabel` here means the field was wired '
              'through birthT and hit a missing key');
      // The miss class itself: easy_localization echoes the key verbatim on a
      // miss, so ANY rendered dotted key is a label wired to the wrong
      // namespace. Nothing on this step may degrade to one.
      expect(
        find.textContaining(RegExp(r'\b(birth|forms)\.[a-zA-Z]')),
        findsNothing,
        reason: 'a rendered raw i18n key means a label missed its namespace',
      );
    });

    testWidgets('death step 2 renders the deceased given-name label',
        (WidgetTester tester) async {
      final DeathFormCubit cubit = DeathFormCubit(
        clock: clock,
        getLookupOptions:
            GetLookupOptions(repository: const _RefRepo()),
        createApplication: CreateApplication(repository: _UnusedRepo()),
        updateApplication: UpdateApplication(repository: _UnusedRepo()),
        addAttachment: AddAttachment(repository: _UnusedRepo()),
        submitApplication: SubmitApplication(repository: _UnusedRepo()),
        loadService: () async => Left<Failure, Service>(Failure('unused')),
        loadPaymentMethods: () async =>
            const Right<Failure, List<PaymentMethod>>(<PaymentMethod>[]),
        readLegalBasisText: () => 'unused',
      );
      await pumpStep(tester, DeathStep2(cubit: cubit, state: cubit.state));

      expect(find.text('GIVEN NAME (LATIN SCRIPT)'), findsOneWidget,
          reason: 'the v2 label must come from the `forms` namespace — '
              'a raw `death.givenNameLabel` here means the field was wired '
              'through deathT and hit a missing key');
      expect(
        find.textContaining(RegExp(r'\b(death|forms)\.[a-zA-Z]')),
        findsNothing,
        reason: 'a rendered raw i18n key means a label missed its namespace',
      );
    });
  });
}
