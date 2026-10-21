/// `certificateCodeFromScanned` — the scanner's gate, rules 1-3 of
/// MOBILE-API-E-CERTIFICATES.md (2026-10) § QR codes and deep links,
/// "Extracting a code from scanned text", verbatim:
///
/// 1. *"If the text is a URL, accept it only when its path is `/v/<code>` or
///    `/verify/<code>`, or its fragment is `#/verify/<code>` (any host: older
///    certificates point at older hosts). Take `<code>`, URL-decode it and
///    trim whitespace."*
/// 2. *"If the text is not a URL, accept it only in a certificate-code shape,
///    ignoring case: the new `^[A-Z]{3}-?[0-9A-Z]{4}-?[0-9A-Z]{4}$` … or the
///    legacy `^[0-9]{6}(-[0-9A-Z]{4}){4}-[0-9]$`."*
/// 3. *"Anything else (a Wi-Fi QR, a phone number, plain text) is not a
///    certificate … and send **nothing** to the API, so a scanned password or
///    personal data never reaches server logs."*
///
/// ## The three readings the guide's wording pins, and this file takes
///
/// * **"Any host" is literal.** The gate is the path *shape* (`/v/<code>` …),
///   not a host allow-list — older certificates point at older hosts the app
///   cannot enumerate, and a `https://wa.me/v/RES-7Q4K-19XD` passes rule 1
///   exactly as `https://portal.gov.la/v/RES-7Q4K-19XD` does. There is no
///   client-side host list and none may be added: the next host the portal
///   configures would be a production break.
/// * **Rule 2's regex is on the whole string** (`^…$`), so a code wearing
///   extra text — `code RES-7Q4K-19XD` — is rule 3's `null`, not a match to
///   be excavated.
/// * **Typed codes are sent as typed.** The server normalises (upper case,
///   spaces and dashes removed, `O`→`0`, `I`/`L`→`1`); the client does
///   nothing — "send what the user typed after steps 2 and 3". The only
///   trimming in the whole parser is rule 1's own URL-decode-then-trim.
///
/// **Pure Dart** — no Flutter, no transport; the scanner (Task 5) and the
/// typed-code entry (Task 4) both call this before anything reaches the API.
library;

/// The new certificate-code shape, case-insensitive: three letters, optional
/// dash, four alphanumerics, optional dash, four alphanumerics.
///
/// The guide writes `[A-Z]`/`[0-9A-Z]` and then says "ignoring case"; the
/// character classes below are the same classes folded, so `res-7q4k-19xd`
/// matches and is sent lowercase, as typed.
final RegExp _newCode = RegExp(r'^[A-Za-z]{3}-?[0-9A-Za-z]{4}-?[0-9A-Za-z]{4}$');

/// The legacy shape: six digits, then four dash-separated groups of four,
/// then one final digit — `260924-AB12-CD34-EF56-GH78-3`.
final RegExp _legacyCode =
    RegExp(r'^[0-9]{6}(-[0-9A-Za-z]{4}){4}-[0-9]$');

/// Extracts a verify code from scanned QR text, or returns `null` when the
/// text is not a certificate code — in which case the caller must send
/// nothing to the API (rule 3).
///
/// URLs are recognised by Dart's [Uri] (`scheme://` shape); the segment after
/// `/v/`, `/verify/` or `#/verify/` is taken last, percent-decoded by
/// `Uri.pathSegments`/`Uri.fragment` and trimmed. Non-URL text must satisfy
/// one of the two whole-string shapes above, and comes back exactly as
/// typed.
String? certificateCodeFromScanned(String raw) {
  final Uri? uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    // Rule 1 — the path/fragment shape is the gate, ANY host.
    final List<String> pathSegments = uri.pathSegments;
    final String fragment = uri.fragment;

    String? fromSegments(List<String> segments) {
      // `/v/<code>` and `/verify/<code>` — the path IS the marker plus the
      // code, nothing more (a `/some/v/<code>` path is not the shape the
      // guide describes, and rule 3's spirit is to send nothing when unsure).
      // `pathSegments` arrives percent-DECODED: Uri performs the URL-decode
      // rule 1 asks for.
      if (segments.length != 2) return null;
      final String marker = segments[0].toLowerCase();
      if (marker != 'v' && marker != 'verify') return null;
      final String code = segments[1].trim();
      return code.isEmpty ? null : code;
    }

    final String? fromPath = fromSegments(pathSegments);
    if (fromPath != null) return fromPath;

    // `#/verify/<code>` — the hash-route form static hosts serve. The
    // fragment of `https://x/#/verify/CODE` reads `/verify/CODE`, decoded
    // like the path.
    if (fragment.isNotEmpty) {
      final Uri? fragmentUri = Uri.tryParse(fragment);
      if (fragmentUri != null) {
        final String? fromFragment = fromSegments(fragmentUri.pathSegments);
        if (fromFragment != null) return fromFragment;
      }
    }
    // Any other URL — a payment link, `wa.me/<phone>`, a web page — is not a
    // certificate (rule 1's own closing sentence).
    return null;
  }

  // Rule 2 — not a URL: the code shapes, whole string, as typed.
  final String text = raw;
  if (_newCode.hasMatch(text) || _legacyCode.hasMatch(text)) {
    return text;
  }

  // Rule 3 — anything else.
  return null;
}
