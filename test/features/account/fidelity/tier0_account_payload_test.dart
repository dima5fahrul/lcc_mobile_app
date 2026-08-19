/// **Tier 0 — payload equality for B8a's three bodied writes.
/// B8-AC-24, B8-AC-31 … B8-AC-35, B8-AC-16 … B8-AC-18.**
///
/// specs.md § 6.9 rules that Tier 0 **APPLIES** to B8, *against* `roadmap.md`
/// § B8's parenthetical that it does not. The roadmap's claim ("no form, no
/// `form_data`") is true of the language toggle in the P0 tree and false of
/// B8, which carries four request bodies — three in B8a — two of which contain
/// real transforms with asymmetries a re-implementer gets wrong.
///
/// ## Where this lives, and why not with F0a's
///
/// `test/features/account/fidelity/`, deliberately **not** an extension of
/// `test/fidelity/tier0_payload_equality_test.dart`. That file holds the
/// suite's one intentional red — an Entry-A-vs-Entry-B disagreement awaiting an
/// architect ruling (F0-AC-104) — and specs.md § 4.1 forbids B8 from touching
/// it. Extending it would tangle two batches' Tier 0 results in one file and
/// put B8's PASS behind F0's open question. B8-AC-24; the same disposition B9b
/// took (`tier0_chat_payload_test.dart`).
///
/// ## Two counter-implementations, and they are the point
///
/// `FACTORY-RULES.md`'s Capability Rule: *"if a test would pass with its
/// subject empty, missing or inert, it is evidence for the wiring, not the
/// criterion."* Applied here, that means an equality assertion is not enough —
/// for both transforms, the **tidy rewrite a careful developer reaches for
/// first** agrees with the real one on the obvious inputs.
///
/// So this file implements both wrong versions ([_naiveSymmetricBody],
/// [_shallowSpreadBody]) and asserts the **inequality** on the discriminating
/// fixtures, *and* asserts that the discriminating fixtures still discriminate
/// — so a fixture that stopped being sharp fails the test rather than passing
/// it vacuously. That is B9b's `lao_over_80` pattern, applied to a five-line
/// diff and a two-level spread.
///
/// ## The claim is about the ENCODED STRING
///
/// Key order is part of it. `AccountPage.tsx:213-215` assigns `name`, `email`,
/// `address` in that order and `types.ts:335-339` declares `language`,
/// `notifications`, `biometric_login` in that order; Dart `Map` literals
/// preserve insertion order and `jsonEncode` respects it, so asserting the
/// encoded string gates order for free (F0 § 6.2.3).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/account/data/models/account_wire.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_preferences.dart';
import 'package:lcc_mobile_app/features/session/data/models/profile_update_body.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_account.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/profile_update.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/jurisdiction.dart';

import '../../../fidelity/oracle.dart' show kWebCommit;

// ─────────────────────────────────────────────────────────────────────────────
// Fixture loading
// ─────────────────────────────────────────────────────────────────────────────

const String _fixturePath =
    'test/features/account/fidelity/fixtures/account-tier0-payloads.json';

Map<String, dynamic> _load() =>
    jsonDecode(File(_fixturePath).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _cases(String kind) =>
    (_load()['cases'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((Map<String, dynamic> c) => c['kind'] == kind)
        .toList(growable: false);

Map<String, dynamic> _case(String id) => (_load()['cases'] as List<dynamic>)
    .cast<Map<String, dynamic>>()
    .firstWhere((Map<String, dynamic> c) => c['id'] == id);

/// The fixture's synthetic `CitizenAccount` — the diff's left-hand side.
CitizenAccount _account() {
  final Map<String, dynamic> j = _load()['account'] as Map<String, dynamic>;
  return CitizenAccount(
    id: j['id'] as String,
    uin: j['uin'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String,
    email: j['email'] as String,
    nationalIdNo: j['national_id_no'] as String,
    dateOfBirth: j['date_of_birth'] as String,
    gender: j['gender'] as String,
    preferredLang: j['preferred_lang'] as String,
    // `jurisdiction` is an object on the wire (`types.ts` `interface
    // Jurisdiction`) — it was typed `String` here and in production until
    // 2026-08-19, which is what broke citizen login. This fixture parse
    // mirrors the production one so the oracle measures the shipped shape.
    jurisdiction: j['jurisdiction'] is Map<String, dynamic>
        ? Jurisdiction(
            provinceId: (j['jurisdiction'] as Map<String, dynamic>)['province_id'] as String?,
            provinceName: (j['jurisdiction'] as Map<String, dynamic>)['province_name'] as String?,
            districtId: (j['jurisdiction'] as Map<String, dynamic>)['district_id'] as String?,
            districtName: (j['jurisdiction'] as Map<String, dynamic>)['district_name'] as String?,
            villageId: (j['jurisdiction'] as Map<String, dynamic>)['village_id'] as String?,
            villageName: (j['jurisdiction'] as Map<String, dynamic>)['village_name'] as String?,
          )
        : null,
    householdNo: j['household_no'] as String,
    address: j['address'] as String,
    verified: j['verified'] as bool,
    eidVerified: j['eid_verified'] as bool,
    active: j['active'] as bool,
    createdAt: j['created_at'] as String,
  );
}

/// What production sends: the body built by the real code path, encoded exactly
/// as Dio will encode it.
String _encode(Map<String, dynamic> body) => jsonEncode(body);

// ─────────────────────────────────────────────────────────────────────────────
// The two counter-implementations — see the library doc
// ─────────────────────────────────────────────────────────────────────────────

/// **WRONG ON PURPOSE.** The tidy "if it changed, include it" loop, with the
/// three fields treated symmetrically.
///
/// This is what `handleSaveProfile` looks like when a developer factors out
/// what appears to be duplication — and it is the implementation the
/// `name_cleared_*` fixtures exist to reject. Kept here, in the test, so the
/// comparison is against a REAL rival implementation rather than against this
/// test's idea of one.
Map<String, dynamic> _naiveSymmetricBody({
  required CitizenAccount account,
  required String name,
  required String email,
  required String address,
}) {
  final Map<String, dynamic> body = <String, dynamic>{};
  for (final (String key, String value, String current) in <
      (String, String, String)>[
    ('name', name.trim(), account.name),
    ('email', email.trim(), account.email),
    ('address', address.trim(), account.address ?? ''),
  ]) {
    if (value != current) body[key] = value;
  }
  return body;
}

/// **WRONG ON PURPOSE.** A single-level spread over the preferences object,
/// which replaces the whole nested `notifications` value instead of merging
/// into it.
Map<String, dynamic> _shallowSpreadBody({
  required CitizenPreferences prefs,
  required Map<String, dynamic> patch,
}) {
  final Map<String, dynamic> notifications = <String, dynamic>{
    if (patch.containsKey('in_app')) 'in_app': patch['in_app'],
    if (patch.containsKey('email')) 'email': patch['email'],
    if (patch.containsKey('sms')) 'sms': patch['sms'],
  };
  return <String, dynamic>{
    'language': patch['language'] ?? prefs.language,
    'notifications': notifications,
    'biometric_login': patch['biometric_login'] ?? prefs.biometricLogin,
  };
}

CitizenPreferences _prefsFrom(Map<String, dynamic> j) =>
    citizenPreferencesFrom(j);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('the fixture is honest about what it is — B8-AC-35', () {
    test('it declares itself SYNTHETIC and says why a recording is impossible',
        () {
      final Map<String, dynamic> capture =
          _load()['_capture'] as Map<String, dynamic>;

      expect(capture['provenance'] as String, contains('SYNTHETIC'));
      expect(
        capture['provenance'] as String,
        contains('ZERO writes to the account'),
        reason: 'A REQUEST-body fixture could not be a recording even in '
            'principle: obtaining one means writing to a live citizen’s '
            'profile, preferences or password, which the slot 16-47 session '
            'explicitly refused. The reason has to survive in the artefact.',
      );
      expect(
        capture['provenance'] as String,
        contains('NO REAL CITIZEN DATA'),
        reason: 'no real citizen data, no real UIN, no token, no real password',
      );
      expect(capture['credential'] as String, contains('none'));
      expect(capture['web_commit'], kWebCommit);
    });

    test('it pins the three endpoints it covers', () {
      final List<dynamic> endpoints =
          (_load()['_capture'] as Map<String, dynamic>)['endpoints']
              as List<dynamic>;
      expect(endpoints, hasLength(3));
      expect(endpoints.join(' '), contains('PATCH /api/v1/me/profile'));
      expect(endpoints.join(' '), contains('PUT /api/v1/me/preferences'));
      expect(
        endpoints.join(' '),
        contains('POST /api/v1/auth/change-password'),
      );
    });

    test('it covers no endpoint B8a does not call — no /me/avatar, no '
        'DELETE /me/account', () {
      final String all = jsonEncode(_load()['_capture']);
      expect(all, isNot(contains('/me/avatar')),
          reason: 'the avatar upload is B8b, behind its own security review');
      expect(all, isNot(contains('DELETE')),
          reason: '`me.deactivate` has zero call sites in the oracle '
              '(specs.md § 6.1) — a Tier 0 leaf for it would be the first '
              'half of porting it');
    });

    test('the fixture set is non-empty and its size is PRINTED, not implied',
        () {
      final List<dynamic> cases = _load()['cases'] as List<dynamic>;
      // Fail rather than skip on an empty set: a skip reads as "absent" rather
      // than "unevaluated" (F0a's own note,
      // `tier0_payload_equality_test.dart:244-257`).
      expect(cases, isNotEmpty);
      // ignore: avoid_print
      print('Tier 0 (B8a): ${cases.length} cases — '
          '${_cases('profile_diff').length} profile_diff, '
          '${_cases('language_mirror').length} language_mirror, '
          '${_cases('preferences_put').length} preferences_put, '
          '${_cases('change_password').length} change_password');
      expect(_cases('profile_diff'), isNotEmpty);
      expect(_cases('language_mirror'), isNotEmpty);
      expect(_cases('preferences_put'), isNotEmpty);
      expect(_cases('change_password'), isNotEmpty);
    });
  });

  // ── B8-AC-31 — the dirty-field diff ───────────────────────────────────────

  group('B8-AC-31 — handleSaveProfile\'s dirty diff, encoded body for body',
      () {
    for (final Map<String, dynamic> c in _cases('profile_diff')) {
      final String id = c['id'] as String;
      final Map<String, dynamic> form = c['form'] as Map<String, dynamic>;

      test('$id — the encoded body matches key-for-key and in order', () {
        final ProfileUpdate update = ProfileUpdate.diff(
          account: _account(),
          name: form['name'] as String,
          email: form['email'] as String,
          address: form['address'] as String,
        );

        expect(_encode(profileUpdateBody(update)), c['expected_body'],
            reason: c['note'] as String);
        expect(
          profileUpdateBody(update).keys.toList(),
          (c['expected_keys'] as List<dynamic>).cast<String>(),
        );
      });
    }
  });

  group('B8-AC-31 — and it is NOT the naive symmetric implementation', () {
    // The two ids whose whole reason for existing is that the two
    // implementations disagree.
    const List<String> discriminating = <String>[
      'name_cleared_email_changed',
      'name_cleared_only',
    ];

    test('the discriminating fixtures PROVABLY discriminate', () {
      for (final String id in discriminating) {
        final Map<String, dynamic> c = _case(id);
        expect(
          c['expected_body'],
          isNot(c['naive_symmetric_body']),
          reason: 'fixture `$id` no longer distinguishes the two '
              'implementations, so every assertion below it is vacuous. This '
              'test says so instead of going green.',
        );
      }
    });

    for (final String id in discriminating) {
      test('$id — real ≠ naive, and the naive one is what the fixture says',
          () {
        final Map<String, dynamic> c = _case(id);
        final Map<String, dynamic> form = c['form'] as Map<String, dynamic>;
        final CitizenAccount account = _account();

        final String real = _encode(profileUpdateBody(
          ProfileUpdate.diff(
            account: account,
            name: form['name'] as String,
            email: form['email'] as String,
            address: form['address'] as String,
          ),
        ));
        final String naive = _encode(_naiveSymmetricBody(
          account: account,
          name: form['name'] as String,
          email: form['email'] as String,
          address: form['address'] as String,
        ));

        // The rival implementation really does produce what the fixture
        // claims — so the inequality below is against a live rival, not a
        // remembered one.
        expect(naive, c['naive_symmetric_body']);
        expect(
          real,
          isNot(naive),
          reason: 'Clearing the name must send NOTHING for `name` '
              '(AccountPage.tsx:213 guards on truthiness AND difference). The '
              'symmetric rewrite sends `name: ""` and blanks the citizen’s '
              'name on a government record — and the screen looks correct '
              'either way. Tier 0 is the only instrument that sees it.',
        );
      });
    }

    test('the CONTROL case cannot tell the two apart — the reason the two '
        'above exist', () {
      final Map<String, dynamic> c = _case('all_three_changed');
      final Map<String, dynamic> form = c['form'] as Map<String, dynamic>;
      final CitizenAccount account = _account();

      expect(
        _encode(profileUpdateBody(ProfileUpdate.diff(
          account: account,
          name: form['name'] as String,
          email: form['email'] as String,
          address: form['address'] as String,
        ))),
        _encode(_naiveSymmetricBody(
          account: account,
          name: form['name'] as String,
          email: form['email'] as String,
          address: form['address'] as String,
        )),
        reason: 'This is the point: with all three fields edited both '
            'implementations agree, so a fixture set made only of this shape '
            'would have reported PASS for a port that got `name` wrong.',
      );
    });

    test('the asymmetry, stated directly: `name` cannot go empty, `email` and '
        '`address` can', () {
      final CitizenAccount account = _account();

      Map<String, dynamic> diff(String n, String e, String a) =>
          profileUpdateBody(ProfileUpdate.diff(
            account: account,
            name: n,
            email: e,
            address: a,
          ));

      expect(diff('', account.email, account.address ?? ''), isEmpty);
      expect(diff(account.name, '', account.address ?? ''), <String, dynamic>{
        'email': '',
      });
      expect(diff(account.name, account.email, ''), <String, dynamic>{
        'address': '',
      });
    });
  });

  // ── B8-AC-32 — phone is never sent ────────────────────────────────────────

  test('B8-AC-32 — `phone` appears in NO body from any B8 surface', () {
    final CitizenAccount account = _account();

    // Every profile_diff fixture, plus both language mirrors.
    for (final Map<String, dynamic> c in _cases('profile_diff')) {
      final Map<String, dynamic> form = c['form'] as Map<String, dynamic>;
      final Map<String, dynamic> body = profileUpdateBody(ProfileUpdate.diff(
        account: account,
        name: form['name'] as String,
        email: form['email'] as String,
        address: form['address'] as String,
      ));
      expect(body.containsKey('phone'), isFalse, reason: c['id'] as String);
    }
    for (final Map<String, dynamic> c in _cases('language_mirror')) {
      final Map<String, dynamic> body = profileUpdateBody(
        ProfileUpdate(preferredLang: c['preferred_lang'] as String),
      );
      expect(body.containsKey('phone'), isFalse, reason: c['id'] as String);
    }

    // …and it is unrepresentable, not merely unset: `ProfileUpdate` has no
    // `phone` field, so no future call site can add one by accident. That is
    // the structural half of the claim, and it is what makes this AC hold by
    // construction rather than by fixture coverage.
    expect(
      const ProfileUpdate().toString(),
      isNot(contains('phone')),
      reason: '`me.updateProfile`’s TypeScript type permits `phone` '
          '(endpoints.ts:99) and no shipped surface ever sends it — the editor '
          'has three inputs and Phone is a read-only row (:553).',
    );
  });

  // ── B8-AC-16 / B8-AC-18 — R-25's first mirror ─────────────────────────────

  group('B8-AC-16 — the language mirror sends `preferred_lang` and nothing '
      'else', () {
    for (final Map<String, dynamic> c in _cases('language_mirror')) {
      test('${c['id']} — exactly one key', () {
        final Map<String, dynamic> body = profileUpdateBody(
          ProfileUpdate(preferredLang: c['preferred_lang'] as String),
        );
        expect(_encode(body), c['expected_body']);
        expect(body.keys.toList(), <String>['preferred_lang']);
      });
    }
  });

  test('B8-AC-18 — the two mirrors are DIFFERENT requests, not one collapsed '
      'into the other', () {
    // Mirror 1: PATCH /me/profile, field `preferred_lang`.
    final Map<String, dynamic> viaProfile =
        profileUpdateBody(const ProfileUpdate(preferredLang: 'en'));

    // Mirror 2: PUT /me/preferences, field `language`, whole object.
    final Map<String, dynamic> p =
        _case('prefs_language_second_mirror')['prefs'] as Map<String, dynamic>;
    final Map<String, dynamic> viaPreferences =
        preferencesBody(_prefsFrom(p).merge(language: 'en'));

    expect(viaProfile.keys, contains('preferred_lang'));
    expect(viaProfile.keys, isNot(contains('language')));
    expect(viaPreferences.keys, contains('language'));
    expect(viaPreferences.keys, isNot(contains('preferred_lang')));
    expect(
      _encode(viaProfile),
      isNot(_encode(viaPreferences)),
      reason: 'specs.md § 2.2 Finding H: the web mirrors "language" to TWO '
          'server fields on TWO endpoints. Collapsing them into one call is '
          'the tidying that would silently stop maintaining one of them.',
    );
  });

  // ── B8-AC-33 / B8-AC-17 — the whole-object PUT ────────────────────────────

  group('B8-AC-33 — PUT /me/preferences is the WHOLE object', () {
    for (final Map<String, dynamic> c in _cases('preferences_put')) {
      final String id = c['id'] as String;

      test('$id — five fields, in declaration order', () {
        final CitizenPreferences prefs =
            _prefsFrom(c['prefs'] as Map<String, dynamic>);
        final Map<String, dynamic> patch = c['patch'] as Map<String, dynamic>;

        final CitizenPreferences next = prefs.merge(
          language: patch['language'] as String?,
          inApp: patch['in_app'] as bool?,
          email: patch['email'] as bool?,
          sms: patch['sms'] as bool?,
          biometricLogin: patch['biometric_login'] as bool?,
        );

        expect(_encode(preferencesBody(next)), c['expected_body'],
            reason: c['note'] as String);

        // The structural half: all five, always.
        final Map<String, dynamic> body = preferencesBody(next);
        expect(body.keys.toList(),
            <String>['language', 'notifications', 'biometric_login']);
        expect(
          (body['notifications']! as Map<String, dynamic>).keys.toList(),
          <String>['in_app', 'email', 'sms'],
        );
      });
    }
  });

  group('B8-AC-33 — and it is NOT a shallow spread', () {
    test('the fixtures PROVABLY discriminate', () {
      for (final Map<String, dynamic> c in _cases('preferences_put')) {
        expect(
          c['expected_body'],
          isNot(c['shallow_spread_body']),
          reason: 'fixture `${c['id']}` no longer distinguishes the merged '
              'object from a shallow spread, so the assertions below it are '
              'vacuous.',
        );
      }
    });

    for (final Map<String, dynamic> c in _cases('preferences_put')) {
      test('${c['id']} — real ≠ shallow, and shallow is what the fixture says',
          () {
        final CitizenPreferences prefs =
            _prefsFrom(c['prefs'] as Map<String, dynamic>);
        final Map<String, dynamic> patch = c['patch'] as Map<String, dynamic>;

        final String shallow =
            _encode(_shallowSpreadBody(prefs: prefs, patch: patch));
        expect(shallow, c['shallow_spread_body']);

        final String real = _encode(preferencesBody(prefs.merge(
          language: patch['language'] as String?,
          inApp: patch['in_app'] as bool?,
          email: patch['email'] as bool?,
          sms: patch['sms'] as bool?,
          biometricLogin: patch['biometric_login'] as bool?,
        )));

        expect(
          real,
          isNot(shallow),
          reason: 'A shallow spread drops the untouched notification booleans. '
              'The endpoint is a PUT, so the server takes the omission as '
              '"set them false" — and the UI still looks right, because it '
              'refetches what it just reset.',
        );
      });
    }
  });

  // ── B8-AC-34 — the credential body ────────────────────────────────────────

  test('B8-AC-34 — change-password sends exactly two keys and never `confirm`',
      () {
    final Map<String, dynamic> c = _case('change_password');

    // The body as `AuthRemoteDatasourceImpl.changePassword` builds it. Written
    // out here rather than reached through the datasource because reaching it
    // would need an `ApiClient` double, and the claim is about the map.
    final Map<String, dynamic> body = <String, dynamic>{
      'current_password': c['current_password'],
      'new_password': c['new_password'],
    };

    expect(_encode(body), c['expected_body']);
    expect(body.keys.toList(), <String>['current_password', 'new_password']);
    expect(body.containsKey('confirm'), isFalse);
    expect(body.containsKey('confirm_password'), isFalse);
    // A value assertion is deliberately NOT made here: the fixture's `confirm`
    // equals its `new_password` (they must match for the form to submit at
    // all), so "the confirm value is absent from the body" is unprovable by
    // value and would be a test that looks stronger than it is. The key-list
    // assertion above is the whole claim, and the structural test below is
    // what stops it drifting.
  });

  test('B8-AC-34 — the datasource\'s body is what this test asserts, not a '
      'copy that could drift', () {
    // Read the datasource source and check the two literals are the ones
    // above. A structural check rather than an execution one: constructing the
    // datasource needs an `ApiClient`, and the claim is about which two string
    // literals appear in the map it builds.
    final String source = File(
      'lib/features/auth/data/datasources/auth_remote_datasource.dart',
    ).readAsStringSync();

    final int start = source.indexOf('Future<void> changePassword({');
    expect(start, greaterThan(-1));
    final String body = source.substring(start);

    expect(body, contains("'current_password': currentPassword"));
    expect(body, contains("'new_password': newPassword"));
    expect(
      body.substring(0, body.indexOf('}')),
      isNot(contains('confirm')),
      reason: '`confirm` must not be reachable from the datasource at all — '
          'it is not on `ChangePasswordParams` and not on the repository '
          'method, so there is no value here to serialise.',
    );
  });
}
