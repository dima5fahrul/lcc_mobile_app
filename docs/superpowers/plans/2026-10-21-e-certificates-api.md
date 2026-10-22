# E-Certificates API v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the app to the new mobile e-certificates API (MOBILE-API-E-CERTIFICATES.md): `files[]` wire model, server PDF download/view, certificate QR, public verification (scan + typed code), on-device PDF hash check, and forms v2 field keys.

**Architecture:** Extend `features/documents/` (collection slice) with the new wire fields and file/QR endpoints. Add a new `features/verify/` slice (clean-arch: datasource → repository → usecase → bloc → pages) for the two anonymous verification endpoints. A pure `code_extraction.dart` parser gates everything that reaches `/verify/*`. PDFs are stored and opened in the platform viewer; the app never renders a certificate itself. Forms v2 adds optional Latin-name keys and photo slots to the existing `features/certificates/` submission payloads.

**Tech Stack:** Flutter/Dart ^3.12.2, dio ^5.8.0, freezed 3, flutter_bloc, get_it, easy_localization. New deps: `crypto` (SHA-256), `mobile_scanner` (scan), `qr_flutter` (draw certificate QR), `open_filex` + `path_provider` (platform PDF viewer).

**Spec:** `/Users/linkit/Downloads/MOBILE-API-E-CERTIFICATES.md` (read it before any task).

**NOTE:** This file was recreated on 2026-10-21 after a housekeeping step misidentified it as an untracked scratch copy and deleted it. Task 1 and Task 2 (plus Task 8 through fix round 1) were completed under the original. The authoritative progress record is `.superpowers/sdd/2026-10-21-e-certificates-api/progress.md`.

## Global Constraints

- One envelope for JSON; the two PDF-file endpoints return raw bytes (`Content-Type: application/pdf`) — `ApiClient.getBytes` must bypass `_unwrap` for success and decode JSON envelopes only on error bodies. (Refined in Task 2: a 2xx `success:false` JSON body also folds to an ApiException; a 2xx `success:true` envelope on a bytes endpoint is reported as malformed.)
- Both `/verify/*` calls go out with `anonymous: true` (no bearer), matching the datasource pattern.
- Bearer token never appears in a URL.
- Unknown code/hash on `/verify` is **HTTP 200 `status: "not-found"`**, not an error.
- `.tr(context: context)` only — `tr_allowlist.yaml` is a ceiling; never add entries. Labels for forms v2 use the `forms.*` namespace directly (NOT `birthT`/`deathT` — those prefix `birth.`/`death.` where the keys do not exist).
- Payment `QrPlaceholder` stays decorative and argument-less — the new QR encoder is only for certificate payloads.
- Release HTTPS guard in `api_endpoint.dart` untouched.
- Guard tests (`documents_scope_test.dart` B5-AC-7/B5-AC-8) adjudicated against the OLD guide; the new guide supersedes those two adjudications — update the tests with a dated reason, keep their spirit (no dead endpoints, verify hits bounded).
- Status strings stay plain `String` (open set), per existing `IssuedCertificate.status` decision.
- Commit scope: `e-cert` (swap in the real ticket id if one exists).

## Review Focus

1. A scanned Wi-Fi/wa.me/payment QR must never reach the API — parser returns null, UI shows "not a certificate" and sends nothing (Task 3 tests it; Task 5 wires it).
2. `not-found` is 200: result screen, not an error snack (Task 3/4 tests).
3. Legacy certificate with no stored file: `files[]` empty and file endpoint 404 — hide View/Download and the hash check instead of crashing (Task 1, 6 tests).
4. 429 on `/verify` (30/min/IP): one friendly message, no automatic retry loop (Task 4 test).
5. A downloaded PDF that was later revoked: always re-check `/verify/{code}` before any VALID badge — result screens derive solely from a live response (Task 4).

---

### Task 1: Wire model v2 — `files[]`, `copy`, `layouts`, `holders`, detail nesting — ✅ COMPLETE (a684595, review clean)

### Task 2: File & QR endpoints + `ApiClient.getBytes` — ✅ COMPLETE (d8e7107, review pending at recreation time)

### Task 8: Forms v2 — split Latin names and new optional fields — ✅ COMPLETE (6ad45db + 8c2bc88 fix round 1, re-review pending at recreation time)

### Task 3: Verify domain+data — anonymous endpoints, checks model, code extraction

**Files:**
- Create: `lib/features/verify/domain/entities/verification_result.dart` (freezed: `VerificationResult`, `VerificationChecks` → `SignatureCheck`/`RecordHashCheck`/`RevocationCheck`, `IssuerContact`) — all strings lenient-parsed, `status` plain String (open set: issued/expired/revoked/superseded/not-found)
- Create: `lib/features/verify/domain/code_extraction.dart` — pure `String? certificateCodeFromScanned(String raw)`
- Create: datasource/repository/usecases (`VerifyByCode`, `VerifyDocumentHash`) with the documents-slice `_guard` shape
- Create: 4 DI files mirroring `documents/di/*` (anonymous client still the root `ApiClient`, `anonymous: true` per call)
- Modify: `lib/core/constant/api_endpoint.dart` (`verifyByCode(String code)` → `/verify/<enc code>`, `verifyDocumentHash` → `/verify/document-hash`)
- Modify: `test/features/documents/documents_scope_test.dart` (B5-AC-8 update, dated)
- Test: `test/features/verify/domain/code_extraction_test.dart`, `test/features/verify/data/verify_transport_test.dart`

**Interfaces:**
- Produces: `certificateCodeFromScanned`: (1) URL accepted only when path is `/v/<code>` or `/verify/<code>` or fragment `#/verify/<code>` (any host) → percent-decoded, trimmed code; (2) non-URL accepted only matching `^[A-Za-z]{3}-?[0-9A-Za-z]{4}-?[0-9A-Za-z]{4}$` (new) or `^[0-9]{6}(-[0-9A-Za-z]{4}){4}-[0-9]$` (legacy), as typed (no normalisation — server does it); (3) anything else → `null`. `VerifyByCode.call(code) → Either<Failure, VerificationResult>`; `VerifyDocumentHash.call(hash) → Either<Failure, VerificationResult>`.

- [ ] **Step 1: Failing tests.** Parser: `https://portal.gov.la/v/RES-7Q4K-19XD`, `.../verify/RES7Q4K19XD`, `https://x/#/verify/RES-7Q4K-19XD`, old-host URL, legacy code → codes; `wa.me/85620...`, `https://portal/pay/1`, `wifi:S:...`, `RES-7Q4K-19` (short), `hello world` → null; lowercase typed code accepted as-is. Transport: unknown code answers **200** with `status: "not-found"` and is a Right, not a Failure; 429 becomes a Failure whose message the bloc will map; `document-hash` POSTs `{"hash": "<64 hex>"}` anonymous (assert no Authorization header via recorded adapter); checks sub-objects parse (`recorded`/`missing`, `match`/`mismatch`/`missing`, `not-revoked`/`revoked`/`superseded`); masked holder stays masked (nothing to do, just pin it).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** parser first (no URL host allow-list — any host per guide), then wire/entity (lenient readers copied from `certificate_wire.dart` style, declared locally per G-L3), then transport with `anonymous: true`. Update B5-AC-8: new hits allowed only under `lib/features/verify/` + `lib/core/constant/` (bounded-prefix assertion, dated reason).
- [ ] **Step 4: Run** `flutter test test/features/verify test/features/documents` — PASS.
- [ ] **Step 5: Commit** `feat(e-cert): anonymous verify endpoints + strict code extraction`.

### Task 4: Verify presentation — bloc, five result screens, typed-code entry, routes

**Files:**
- Create: `lib/features/verify/presentation/bloc/verify_bloc.dart|state.dart|event.dart` (freezed state)
- Create: `lib/features/verify/presentation/pages/verify_result_page.dart`, `verify_code_entry_page.dart`
- Create: `lib/features/verify/di/verify_feature_injection.dart` (+3 files)
- Modify: `lib/core/di/dependency_injection.dart` (`VerifyFeatureInjection.init()` after Documents), `lib/utils/routes/app_name_routes.dart` (`/verify`, `/verify/:code`, `/v/:code`), `lib/utils/routes/app_routes.dart` (three GoRoutes, one builder; public — NOT in `_protectedPaths`), `assets/i18n/en.json`, `assets/i18n/lo.json`
- Test: `test/features/verify/presentation/verify_bloc_test.dart`, `test/features/verify/presentation/verify_result_page_test.dart`, `test/utils/routes/` (extend route test)

**Interfaces:**
- Consumes: Task 3 usecases. `VerifyState`: `initial | loading | result(VerificationResult) | tooManyRequests | failure(String)` — `not-found` is a `result` with `status: "not-found"`.
- Produces: `GoRouter` navigable `/verify` (typed entry: TextField + Scan button), `/verify/:code` and `/v/:code` (same result page, code from path). Screen mapping from `status`: issued→VALID (+valid_until, issuing office), expired→EXPIRED (+date), revoked→REVOKED (+revoked_at, reason), superseded→REPLACED (+replaced_by_certificate_no), not-found→NOT FOUND (+rescan/retype affordance). Checks copy honest per guide: `recorded` ≠ "verified"; `ca`/`format`/`timestamp` rendered only when non-empty. Entry button "Check a PDF file" shown only when `checks.record_hash.status != 'missing'` (Task 7 hooks it).

- [ ] **Step 1: Failing tests.** Bloc: `VerifySubmitted('RES-7Q4K-19XD')` → loading → result; `not-found` → result(not-found), no failure; 429 → `tooManyRequests`; generic error → failure(message). Widget: each of the five statuses renders its title + the guide's required extras; `record_hash: 'mismatch'` shows the warn + PDF-check offer; `record_hash: 'missing'` hides it; CA fields absent when empty. Route test: `/v/RES-7Q4K-19XD` and `/verify/RES-7Q4K-19XD` both build the result page; `/verify` is reachable signed-out.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** (bloc, pages with `.tr(context: context)`, i18n keys `verify.*` in both locales, DI chain, routes).
- [ ] **Step 4: Run** `flutter test test/features/verify test/utils/routes` — PASS.
- [ ] **Step 5: Commit** `feat(e-cert): verification result screens, typed entry, /v deep-link route`.

### Task 5: QR scanner page

**Files:**
- Modify: `pubspec.yaml` (`mobile_scanner: ^7.0.0` — one dependency, justified in a comment citing the guide's scanner requirement), `ios/Runner/Info.plist` (`NSCameraUsageDescription`), `android/app/src/main/AndroidManifest.xml` (`CAMERA` uses-permission)
- Create: `lib/features/verify/presentation/pages/verify_scanner_page.dart`
- Test: `test/features/verify/presentation/verify_scanner_page_test.dart`

**Interfaces:**
- Consumes: Task 3 `certificateCodeFromScanned`, Task 4 routes.
- Produces: `VerifyScannerPage` — `MobileScanner(onDetect)`: extract → non-null → `context.push('/verify/<code>')` (pop the scanner so Back returns to entry); null → in-page banner `verify.notCertificateQr`, keep scanning, **no API call**.

- [ ] **Step 1: Failing test** — pump the page with a stubbed controller; feed `Barcode` values: a `/v/` URL barcode navigates; a `wa.me` barcode shows the banner and pushes nothing (assert no navigation).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** (guard against duplicate pushes with a `NavigatorObserver`-free `if (!controller.isStarting)`-style flag or route lock).
- [ ] **Step 4: Run** `flutter test test/features/verify` — PASS. `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(e-cert): QR scanner with strict code gating`.

### Task 6: Server PDF view/download + certificate QR rendering

**Files:**
- Modify: `pubspec.yaml` (`qr_flutter: ^4.1.0`, `open_filex: ^4.0.0`, `path_provider: ^2.1.0` — justified comments)
- Create: `lib/presentation/documents/certificate_file_actions.dart` (widget: per `files[]` layout, View + Download)
- Create: `lib/features/documents/domain/certificate_pdf_io.dart` — `Future<void> openPdfBytes(Uint8List bytes, String fileName)` (temp file via `path_provider`, `OpenFilex.open`), `Future<void> savePdfBytes(...)` (reuse `FilePicker.platform.saveFile` pattern from `document_viewer.dart`), `bool sha256Matches(Uint8List bytes, String headerHex)` (empty header → true)
- Modify: `lib/features/history/presentation/pages/history_detail_page.dart` + `lib/presentation/documents/document_actions_row.dart` — mount `CertificateFileActions` when `certificate.hasStoredFile`; render `QrImageView(data: certificate.qrPayload)` in the viewer panel when `hasQrPayload`, else keep the existing faux-QR path untouched
- Modify: `lib/features/documents/di/documents_usecase_injection.dart` (Task 2 usecases already registered — wire into the widget's bloc/cubit access)
- Test: `test/presentation/documents/certificate_file_actions_test.dart`, `test/features/documents/domain/certificate_pdf_io_test.dart`

**Interfaces:**
- Consumes: Task 1 `files[]`/`fileForLayout`, Task 2 `DownloadCertificateFile` (returns bytes+filename+sha256Header).
- Produces: View → `openPdfBytes` (platform viewer, `disposition=inline`); Download → `savePdfBytes` with the `Content-Disposition` filename (fallback `<certificate_no>-<layout>.pdf`); integrity: when `sha256Header` non-empty and mismatched → surface `verify.integrityFailed` failure instead of opening.

- [ ] **Step 1: Failing tests.** IO: `sha256Matches` true/false/empty-header; `openPdfBytes` writes a temp file with the given name (inject a temp-dir accessor for testability). Widget: certificate with two files renders two View buttons and two Download buttons; `hasStoredFile == false` renders nothing; download failure shows `verify.integrityFailed` when hashes mismatch, opens nothing.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement**; keep `renderDocumentPdf`/`DocSpec` painter untouched for the no-file legacy path.
- [ ] **Step 4: Run** `flutter test test/presentation/documents test/features/documents test/features/history` — PASS.
- [ ] **Step 5: Commit** `feat(e-cert): server-PDF view/download with SHA-256 integrity, real certificate QR`.

### Task 7: On-device PDF hash check

**Files:**
- Modify: `pubspec.yaml` (`crypto: ^3.0.0` direct dep — already in the lock transitively)
- Create: `lib/features/verify/presentation/pages/verify_file_check_page.dart` — pick file (`file_picker`, already present), stream-read SHA-256 → 64 lower-case hex, call `VerifyDocumentHash`, then: `not-found` → "not an issued document or was changed"; found + `verify_code` == viewed code → "matches the issued document" (+ `layout` note), but if `status` is revoked/superseded/expired → that status screen wins; found + different code → "a genuine but different certificate" + its number
- Modify: `lib/features/verify/presentation/pages/verify_result_page.dart` — the Task 4 entry button pushes this page with the viewed `verify_code`
- Test: `test/features/verify/presentation/verify_file_check_page_test.dart`

**Interfaces:**
- Consumes: Task 3 `VerifyDocumentHash`, Task 4 state/route plumbing.
- Produces: `String sha256HexOfBytes(List<int> bytes)` helper (stream-read for big files: chunk 64 KiB, `crypto`'s `sha256.startChunkedConversion`).

- [ ] **Step 1: Failing tests** — pure helper: known vector (`abc` → `ba7816bf…`); page test with a stubbed picker + bloc: match shows match copy; different code shows the other certificate's number; not-found shows the not-issued copy.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/features/verify` — PASS.
- [ ] **Step 5: Commit** `feat(e-cert): on-device PDF hash check via /verify/document-hash`.

### Task 9: Photo slots + `office_use` guard

**Files:**
- Modify: `lib/features/certificates/presentation/{marriage,divorce}/` upload steps + `lib/features/certificates/domain/submission/attachment_guard.dart` / `attachment_accept_policy.dart`
- Test: `test/features/certificates/domain/submission/attachment_slots_test.dart`, extend goldens

**Interfaces:**
- Consumes: existing `POST /applications/{id}/attachments` multipart path (`api_endpoint.dart:595`) with `slot` + `kind=photo`.
- Produces: photo slots `spouses.spouse_a.photo`/`spouses.spouse_b.photo` (marriage), `spouses.husband.photo`/`spouses.wife.photo` (divorce); `applicant.photo` (residence) already exists — no change. Guard: any `office_use` key in outgoing `form_data` is dropped before send (officer-only section per guide).

- [ ] **Step 1: Failing tests** — marriage/divorce upload steps produce the new slots with `kind: photo`; a payload containing `office_use.icd10` (simulated) is stripped by the executor's send path; residence slot unchanged.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** (UI mirrors the existing applicant-photo control; guard in the submission executor where `form_data` is serialised).
- [ ] **Step 4: Run** `flutter test test/features/certificates` — PASS; then the whole suite `flutter test` green.
- [ ] **Step 5: Commit** `feat(e-cert): 3x4 photo slots for marriage/divorce, office_use never sent`.

### Out-of-code follow-ups (record, do not implement)

- **Deep links for `/v/*` — BOTH halves, server and client. Neither is done.** (Guide § QR codes and deep links; the client half added 2026-10-22 after the whole-branch review's C-1(b) found this item recorded only half.)
  1. **Server half.** Send the app bundle ID (`applicationId` = `com.linkit360.lcc`, and the iOS bundle identifier) + the signing certificate SHA-256 to the backend team so the **portal host** publishes `/.well-known/assetlinks.json` (Android App Links) and `/.well-known/apple-app-site-association` (iOS Universal Links) for the path `/v/*`.
  2. **Client half — not written, and deliberately not guessed.** `android/app/src/main/AndroidManifest.xml` has only MAIN/LAUNCHER, and there is no `CFBundleURLTypes` in `ios/Runner/Info.plist` and no `.entitlements` file anywhere under `ios/`. What has to be added once the host is known:
     - **Android:** a second `<intent-filter android:autoVerify="true">` on `.MainActivity` with `android.intent.action.VIEW` + `android.intent.category.DEFAULT` + `android.intent.category.BROWSABLE`, `<data android:scheme="https" android:host="<portal-host>"/>`, and **two** `android:pathPrefix` entries — `/v` (the portal's current form) and `/verify` (the older `https://<api-host>/verify/<code>` form that older certificates' QR codes still carry). The hash-route form `https://<host>/#/verify/<code>` needs no path prefix of its own: a fragment is never sent to the OS matcher, so `/` on that host would have to be claimed for it, which is out of scope.
     - **iOS:** a `Runner.entitlements` carrying `com.apple.developer.associated-domains` = `applinks:<portal-host>`, referenced from the target's `CODE_SIGN_ENTITLEMENTS`.
  3. **Why neither was added in code on 2026-10-22.** The repo holds no portal host. The only host literal anywhere is `ApiEndpoint.baseUrl`'s `--dart-define` default `https://api.staging.linkit360.la/api/v1` — the *API* host, staging, and overridable at build time. Claiming App Links for a staging API host in a production manifest would be wrong, and `autoVerify="true"` against a host with no `assetlinks.json` makes Android **drop** the verified-link association for the whole app. So the config waits on item 1's answer.
  4. **The feature does not wait on it.** `_VerifyEntryAction` on the account page (`account_page.dart`) reaches `/verify` with no deep link involved, so the slice is reachable in a shipped build today; these two files only change *how* a citizen arrives.
- Family-book `request-copy` already wired under F4; the guide's "works on every database now" is a server change — no app edit.
- 401 refresh / 404 / 422 field errors already handled by `RefreshInterceptor` + envelope `errors[]` — verified by existing tests, not re-implemented.
