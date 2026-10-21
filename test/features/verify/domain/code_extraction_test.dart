/// `certificateCodeFromScanned` — the scanner's gate.
///
/// The parser **is** MOBILE-API-E-CERTIFICATES.md (2026-10) § QR codes and
/// deep links, "Extracting a code from scanned text", rules 1-3 verbatim:
///
/// 1. A URL is accepted only when its path is `/v/<code>` or `/verify/<code>`
///    or its fragment is `#/verify/<code>` — **any host** (older certificates
///    point at older hosts). Take the last segment, URL-decode it, trim it.
/// 2. Non-URL text is accepted only in a certificate-code shape: the new
///    `^[A-Za-z]{3}-?[0-9A-Za-z]{4}-?[0-9A-Za-z]{4}$` or the legacy
///    `^[0-9]{6}(-[0-9A-Za-z]{4}){4}-[0-9]$`, and it is sent **as typed** —
///    the server normalises (upper case, dashes, `O`→`0`), the client does not.
/// 3. Anything else — a Wi-Fi QR, a phone number, plain text — is `null`, so
///    a scanned password or personal data never reaches server logs.
///
/// These tests are pure Dart: no transport, no fixtures, just the three rules
/// and the boundary cases the guide names plus the ones its wording pins
/// (whole-string regex, path-shape gate, decode-then-trim order).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/verify/domain/code_extraction.dart';

void main() {
  group('rule 1 — a URL is accepted by its PATH SHAPE, on any host', () {
    test('the new /v/ form extracts the code', () {
      expect(
        certificateCodeFromScanned('https://portal.gov.la/v/RES-7Q4K-19XD'),
        'RES-7Q4K-19XD',
      );
    });

    test('the /verify/ form extracts the code', () {
      expect(
        certificateCodeFromScanned('https://portal.gov.la/verify/RES7Q4K19XD'),
        'RES7Q4K19XD',
      );
    });

    test('the #/verify/ fragment form extracts the code', () {
      expect(
        certificateCodeFromScanned('https://x/#/verify/RES-7Q4K-19XD'),
        'RES-7Q4K-19XD',
      );
    });

    test('an older host is accepted — the guide: "any host: older '
        'certificates point at older hosts"', () {
      expect(
        certificateCodeFromScanned(
          'https://old-api.gov.la/verify/260924-AB12-CD34-EF56-GH78-3',
        ),
        '260924-AB12-CD34-EF56-GH78-3',
      );
    });

    test('the segment is percent-decoded, then trimmed', () {
      // `%20` rides in the URL and dies at the trim — the guide's
      // "URL-decode it and trim whitespace", in that order.
      expect(
        certificateCodeFromScanned('https://portal.gov.la/v/RES-7Q4K-19XD%20'),
        'RES-7Q4K-19XD',
      );
      expect(
        certificateCodeFromScanned('https://portal.gov.la/v/RES%2D7Q4K-19XD'),
        'RES-7Q4K-19XD',
      );
    });

    test('ANY host passes when the path is /v/<code> — even wa.me '
        '(path shape is the gate, not the host, per the guide)', () {
      // The guide's rule 1 names wa.me as a NON-certificate only for its own
      // phone path; a wa.me URL whose *path* is /v/<code> satisfies the rule
      // as written. Recorded so the behaviour is pinned, not discovered.
      expect(
        certificateCodeFromScanned('https://wa.me/v/RES-7Q4K-19XD'),
        'RES-7Q4K-19XD',
      );
    });

    test('a URL with any other path is not a certificate', () {
      expect(
        certificateCodeFromScanned('https://portal.gov.la/pay/1'),
        isNull,
        reason: 'a payment link is not a certificate',
      );
      expect(
        certificateCodeFromScanned('https://wa.me/85620123456'),
        isNull,
        reason: 'the guide names wa.me/<phone> explicitly',
      );
      expect(
        certificateCodeFromScanned('https://portal.gov.la/v/'),
        isNull,
        reason: 'a path of /v/ with no segment has no code to take',
      );
    });
  });

  group('rule 2 — non-URL text in a code shape, sent AS TYPED', () {
    test('the new dashed form', () {
      expect(certificateCodeFromScanned('RES-7Q4K-19XD'), 'RES-7Q4K-19XD');
    });

    test('the new undashed form', () {
      expect(certificateCodeFromScanned('RES7Q4K19XD'), 'RES7Q4K19XD');
    });

    test('lowercase is accepted and sent as typed — no client-side '
        'normalisation (the server does it)', () {
      expect(certificateCodeFromScanned('res-7q4k-19xd'), 'res-7q4k-19xd');
      expect(certificateCodeFromScanned('div-4h7z-5ika'), 'div-4h7z-5ika');
    });

    test('the legacy form', () {
      expect(
        certificateCodeFromScanned('260924-AB12-CD34-EF56-GH78-3'),
        '260924-AB12-CD34-EF56-GH78-3',
      );
      expect(
        certificateCodeFromScanned('260924-ab12-cd34-ef56-gh78-3'),
        '260924-ab12-cd34-ef56-gh78-3',
        reason: 'legacy shape is case-insensitive too, and as typed',
      );
    });

    test('the regex is on the WHOLE string — a code wearing extra text '
        'fails the shape', () {
      expect(
        certificateCodeFromScanned('code RES-7Q4K-19XD'),
        isNull,
      );
      expect(
        certificateCodeFromScanned('RES-7Q4K-19XD please'),
        isNull,
      );
    });
  });

  group('rule 3 — anything else is null, and nothing reaches the API', () {
    test('a bare wa.me link (no scheme, phone path)', () {
      expect(certificateCodeFromScanned('wa.me/85620123456'), isNull);
    });

    test('a Wi-Fi QR payload', () {
      expect(certificateCodeFromScanned('wifi:S:HomeNet;P:secret123;;'), isNull);
    });

    test('a phone number', () {
      expect(certificateCodeFromScanned('+856 20 1234 5678'), isNull);
    });

    test('plain text', () {
      expect(certificateCodeFromScanned('hello world'), isNull);
    });

    test('the empty string', () {
      expect(certificateCodeFromScanned(''), isNull);
    });

    test('a truncated new-form code', () {
      expect(
        certificateCodeFromScanned('RES-7Q4K-19'),
        isNull,
        reason: 'two groups, not three — rule 2 wants three',
      );
    });

    test('spaces where the dashes go are NOT a code shape', () {
      // The guide's typed-codes prose notes the SERVER normalises
      // `RES 7Q4K 19XD`; the client gate stays the rule-2 regex on the whole
      // string, which a space does not satisfy — so this is null here. The
      // normalisation prose describes the server, and the typed field's own
      // pre-processing is Task 4's surface, not this parser's.
      expect(certificateCodeFromScanned('RES 7Q4K 19XD'), isNull);
    });

    test('a code with surrounding whitespace is NOT trimmed — the trim in '
        'rule 1 belongs to the URL branch only, and rule 2 sends as typed',
        () {
      expect(certificateCodeFromScanned(' RES-7Q4K-19XD'), isNull);
      expect(certificateCodeFromScanned('RES-7Q4K-19XD\n'), isNull);
    });
  });
}
