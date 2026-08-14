#!/usr/bin/env node
/**
 * Entry A — the EXECUTED Tier 0 oracle (§ 6.5.5, RULING 10 as amended at v1.3).
 *
 *   node test/fidelity/execute_forms_oracle.mjs [--form=resident] [--locale=en]
 *        [--control=value-drift|no-capture|broken-route]
 *
 * The pinned web application is served locally, driven under Playwright with
 * every off-origin request intercepted, and the **serialised request body is
 * read off the wire** — `route.request().postData()`, the exact bytes
 * `client.ts:242`'s bare `JSON.stringify` produced. Nothing is transcribed and
 * nothing is released to the network.
 *
 * `derive_forms_oracles.py` (Entry B) re-transcribes the same builders from
 * source text. This file asserts **A === B byte-for-byte on every leaf A
 * covers** (`F0-AC-104`). A disagreement is a BLOCKED condition (§ 8.3): it is
 * either a transcription defect or a rig defect, and an implementer must not
 * be free to pick the cheaper one, so nothing here edits either side to match.
 *
 * ## The six binding properties, each with the measurement behind it
 *
 *  1. **Subject is the pinned source.** `git rev-parse HEAD` in
 *     `sources/lcc-app` must equal `62f8a529…` BEFORE capture; otherwise this
 *     aborts. A baseline spanning two web commits is unattributable (§ 8.3).
 *     The deployed staging bundle is not a permitted subject: deployed `Lb`
 *     reaches three of Resident's `applicant.*` leaves, so an oracle captured
 *     from staging bakes them in (§ 3.2 clause 4, Finding L-3).
 *  2. **Bodies are read, never sent.** Every write verb is captured and
 *     withheld. There is no code path in this file that lets a request proceed
 *     to a real host — the off-origin route predicate below is total.
 *  3. **`fulfill`, not `abort`, on the create.** The update body derives from
 *     `created.reference_no` (`ResidentCertificatePage.tsx:506-517`), so
 *     rejecting the create rejects `submitCase` and the ten update oracles
 *     never come into existence — precisely the ones where the two
 *     `CaseReferenceBinding` inhabitants differ.
 *  4. **Reads are fulfilled from fixtures, so no credential is needed.** A
 *     SYNTHETIC token is seeded before boot. `session.tsx:33` makes
 *     `isAuthenticated` a pure client-side token-presence test and `:42-50`
 *     only clears on 401/403, so a synthetic token boots the app
 *     authenticated with zero packets (Finding L-4).
 *  5. **Zero egress, asserted rather than intended.** API requests that fell
 *     through the API route to the safety net are counted and a non-zero count
 *     FAILS (`F0-AC-103`), and `--control=broken-route` proves the counter can
 *     go non-zero. A rig that
 *     "mostly" intercepts is a rig that can POST a real application against a
 *     real wallet.
 *  6. **The clock is frozen at ADR-0005's instant** before the app boots, so
 *     `today()` cannot move between the create and the update on the nested
 *     pages (§ 6.2.6 item 1) and A cannot disagree with B for a reason that is
 *     not a defect.
 *
 * ## Scope actually driven, stated plainly rather than implied
 *
 * **The six properties above are complete and are exercised on every run.**
 * Each one prints its own evidence and each one can fail the run. What is NOT
 * complete is the UI driver, and the honest statement of where it stops is
 * this:
 *
 *   **MEASURED, this run:** `#/service/resident-certificate` does not open the
 *   Resident form on a cold profile. The application boots into its ONBOARDING
 *   flow (a language chooser and a welcome carousel) and the hash is ignored
 *   until that flow is dismissed; `document.body` at that point contains
 *   `ຍິນດີຕ້ອນຮັບ` and a `ຂ້າມ` / `ຕໍ່ໄປ` pair, and there is no `input[type=file]`
 *   on the page at all. Reaching `buildFormData` therefore needs: dismiss
 *   onboarding -> home -> the citizen-and-registration category -> the service
 *   -> six wizard steps (five uploads, one native `<select>`, three cascading
 *   `SearchableSelect` popovers, one date field) -> the payment step.
 *
 * So Entry A currently captures **zero write bodies**, this file reports that
 * as **NOT EVALUATED with a non-zero exit code**, and `F0-AC-104` is NOT
 * satisfied. It is deliberately not reported as a pass: "every captured leaf
 * agrees" is vacuously true of a rig that captured nothing, which is the exact
 * vacuity `F0-AC-106(b)` exists to expose.
 *
 * Those leaves are NOT eligible for `oracle_coverage.yaml` either. That
 * register takes only branches proven **structurally unreachable**, never
 * branches nobody drove — a cap on effort would invite exactly the relabelling
 * `F0-AC-105` was written to prevent.
 */

import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const PKG = resolve(HERE, "..", "..");
const PROJECT = resolve(PKG, "..", "..");
const WEB = join(PROJECT, "sources", "lcc-app");
const VENDOR = join(WEB, "node_modules");
const API_FIXTURES = join(HERE, "fixtures", "api");
const TIER0 = join(PROJECT, "docs", "fidelity-baseline", "2026-08-13",
  "oracle", "tier0");
const EXECUTED = join(TIER0, "executed");

const WEB_COMMIT = "62f8a529aaa024a8b35b0af50a8fbd4850a63962";
/** ADR-0005's frozen instant. Local +07:00 = 2026-08-14, UTC = 2026-08-13. */
const CLOCK_MS = Date.parse("2026-08-14T02:00:00+07:00");
const SYNTHETIC_TOKEN = "synthetic.tier0-rig.not-a-credential";

const require = createRequire(join(VENDOR, "noop.cjs"));

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? "true"];
  }),
);
const FORM = args.form ?? "resident";
const LOCALE = args.locale ?? "en";
const CONTROL = args.control ?? "";
const DEFAULT_VARIANT = FORM === "resident" || FORM === "birth"
  || FORM === "death" ? "baseline" : "asymmetric";
const VARIANT = args.variant ?? DEFAULT_VARIANT;
/**
 * Entry B names the default variant's oracle `<form>.<body>.<locale>.json` in
 * `oracle/tier0/` and every other variant `<form>.<variant>.<body>.<locale>`
 * in `oracle/tier0/variants/`. Entry A has to land and compare under the SAME
 * names, or a `--variant` run silently overwrites the baseline capture and
 * compares against the wrong counterpart.
 */
const VARIANT_TAG = VARIANT === DEFAULT_VARIANT ? "" : `${VARIANT}.`;

const fail = (msg) => { console.error(`\nFAIL: ${msg}\n`); process.exit(1); };

// ─────────────────────────────────────────────────────────────────────────────
// Property 1 — the subject is the pinned source, proven before anything runs
// ─────────────────────────────────────────────────────────────────────────────

function assertPinnedSubject() {
  const head = execFileSync("git", ["-C", WEB, "rev-parse", "HEAD"],
    { encoding: "utf8" }).trim();
  if (head !== WEB_COMMIT) {
    fail(`sources/lcc-app is at ${head}, not the pin ${WEB_COMMIT}. § 8.3 `
      + `makes a moved pin a BLOCKED condition: a baseline spanning two web `
      + `commits is unattributable. Nothing is captured.`);
  }
  console.log(`pin verified: ${head}`);
}

/** § 3.2 clause 2 — the rig must leave the port source untouched. */
function gitStatusOfWeb() {
  return execFileSync("git", ["-C", WEB, "status", "--porcelain"],
    { encoding: "utf8" }).trimEnd();
}

// ─────────────────────────────────────────────────────────────────────────────
// The read fixtures every GET is fulfilled from
// ─────────────────────────────────────────────────────────────────────────────

/**
 * The synthetic location registry the tier0 fixtures select from. Bilingual,
 * so `nameOf` = `text(found.name, lang)` (`MarriageCertificatePage.tsx:307`)
 * resolves differently per locale seed and Guard B is a resolution path.
 */
const LOCATIONS = {
  provinces: [
    { id: "11111111-1111-4111-8111-111111111111",
      name: { en: "Test Province One", lo: "ແຂວງທົດສອບໜຶ່ງ" } },
    { id: "55555555-5555-4555-8555-555555555555",
      name: { en: "Test Province Five", lo: "ແຂວງທົດສອບຫ້າ" } },
  ],
  districts: [
    { id: "22222222-2222-4222-8222-222222222222",
      province_id: "11111111-1111-4111-8111-111111111111",
      name: { en: "Test District Two", lo: "ເມືອງທົດສອບສອງ" } },
    { id: "66666666-6666-4666-8666-666666666666",
      province_id: "55555555-5555-4555-8555-555555555555",
      name: { en: "Test District Six", lo: "ເມືອງທົດສອບຫົກ" } },
  ],
  villages: [
    { id: "33333333-3333-4333-8333-333333333333",
      district_id: "22222222-2222-4222-8222-222222222222",
      name: { en: "Test Village Three", lo: "ບ້ານທົດສອບສາມ" } },
    { id: "77777777-7777-4777-8777-777777777777",
      district_id: "66666666-6666-4666-8666-666666666666",
      name: { en: "Test Village Seven", lo: "ບ້ານທົດສອບເຈັດ" } },
  ],
};

/** `ReferenceItem` (`api/types.ts:225`) — id, type, code, bilingual label. */
const refItem = (type, code, en, lo, i) => ({
  id: `ref-${type}-${i}`, type, code, label: { en, lo },
  sort_order: i, active: true,
});
const REFERENCE_LISTS = {
  // `ResidentCertificatePage.tsx:339-340` asks for exactly these two types.
  nationality: [
    refItem("nationality", "lao", "Lao", "ລາວ", 1),
    refItem("nationality", "lao-plus", "Lao (dual)", "ລາວ (ສອງສັນຊາດ)", 2),
    refItem("nationality", "thai", "Thai", "ໄທ", 3),
    refItem("nationality", "vietnamese", "Vietnamese", "ຫວຽດນາມ", 4),
  ],
  "certificate-purpose": [
    refItem("certificate-purpose", "school-enrolment",
      "School enrolment", "ລົງທະບຽນຮຽນ", 1),
    refItem("certificate-purpose", "other", "Other", "ອື່ນໆ", 2),
  ],

  // ── Birth's nine remaining types ────────────────────────────────────────
  // `BirthDeclarationPage.tsx:259-268` (`useRefLists`) asks for exactly ten
  // types; `nationality` above is the tenth. Every `code` below is one the
  // tier0/birth fixture matrix actually selects — an option list that merely
  // "looks plausible" would let a mis-driven select resolve to the page's
  // blank default and be captured as an executed byte.
  //
  // Each of these already has an EMPTY on-disk fixture under
  // `fixtures/api/reference-*.json`, written by an earlier run's fallback
  // ("synthetic empty envelope … feeds no Tier 0 leaf"). That statement is
  // false for Birth: nine of these DO feed Tier 0 leaves. `readBodyFor`
  // consults this table BEFORE the on-disk file, so the empty envelopes are
  // shadowed rather than silently served.
  //
  // ── Death's eight types ─────────────────────────────────────────────────
  // `DeathDeclarationPage.tsx:253-263` (`useRefLists`) asks for exactly eight
  // types — ethnicity, nationality, ethnic-group, religion, education-level,
  // marital-status, relation, cause-of-death. Seven of the eight are types
  // Birth already asks for; `cause-of-death` is new. But the death
  // fixtures select six CODES no list below carried before them
  // (`lao-theung`, `none`, `vocational`, `divorced`, `neighbour`,
  // `Deceased Ethnic Group`). A code the rig does not fulfil is not a silent
  // miss: `selectOption` throws, so it stops the run — but the run has to be
  // able to complete for `F0-AC-104` to be evaluated at all, so they are added
  // here rather than worked around in the driver.
  ethnicity: [
    refItem("ethnicity", "lao-loum", "Lao Loum", "ລາວລຸ່ມ", 1),
    refItem("ethnicity", "hmong", "Hmong", "ມົ້ງ", 2),
    refItem("ethnicity", "khmu", "Khmu", "ຂະມຸ", 3),
    refItem("ethnicity", "lao-theung", "Lao Theung", "ລາວເທິງ", 4),
  ],
  "ethnic-group": [
    // The fixture stores free-text-looking values here, but the control is a
    // `ReferenceSelectView` (`:544`), so the value can only be a CODE the list
    // carries. These three codes are the fixture's three values verbatim.
    refItem("ethnic-group", "Mother Ethnic Group",
      "Mother Ethnic Group", "ຊົນເຜົ່າຂອງແມ່", 1),
    refItem("ethnic-group", "Father Ethnic Group",
      "Father Ethnic Group", "ຊົນເຜົ່າຂອງພໍ່", 2),
    refItem("ethnic-group", "Informant Ethnic Group",
      "Informant Ethnic Group", "ຊົນເຜົ່າຂອງຜູ້ແຈ້ງ", 3),
    refItem("ethnic-group", "Deceased Ethnic Group",
      "Deceased Ethnic Group", "ຊົນເຜົ່າຂອງຜູ້ເສຍຊີວິດ", 4),
  ],
  religion: [
    refItem("religion", "buddhist", "Buddhist", "ພຸດ", 1),
    refItem("religion", "animist", "Animist", "ຜີ", 2),
    refItem("religion", "christian", "Christian", "ຄຣິສຕຽນ", 3),
  ],
  "education-level": [
    refItem("education-level", "primary", "Primary", "ປະຖົມ", 1),
    refItem("education-level", "secondary", "Secondary", "ມັດທະຍົມ", 2),
    refItem("education-level", "tertiary", "Tertiary", "ຊັ້ນສູງ", 3),
    refItem("education-level", "none", "None", "ບໍ່ໄດ້ຮຽນ", 4),
    refItem("education-level", "vocational", "Vocational", "ວິຊາຊີບ", 5),
  ],
  "marital-status": [
    refItem("marital-status", "single", "Single", "ໂສດ", 1),
    refItem("marital-status", "married", "Married", "ແຕ່ງງານແລ້ວ", 2),
    refItem("marital-status", "widowed", "Widowed", "ໝ້າຍ", 3),
    refItem("marital-status", "divorced", "Divorced", "ຢ່າຮ້າງ", 4),
  ],
  relation: [
    refItem("relation", "father", "Father", "ພໍ່", 1),
    refItem("relation", "mother", "Mother", "ແມ່", 2),
    refItem("relation", "uncle", "Uncle", "ລຸງ", 3),
    refItem("relation", "neighbour", "Neighbour", "ເພື່ອນບ້ານ", 4),
  ],
  // Death only (`DeathDeclarationPage.tsx:261`). The fixture matrix selects
  // `other`, which is the ONE code that also renders a second control
  // (`:1240`, the free-text "specify") — so a list that omitted it would not
  // merely blank a leaf, it would change the step's control COUNT and shift
  // every text ordinal after it.
  "cause-of-death": [
    refItem("cause-of-death", "illness", "Illness", "ເຈັບປ່ວຍ", 1),
    refItem("cause-of-death", "accident", "Accident", "ອຸບັດຕິເຫດ", 2),
    refItem("cause-of-death", "other", "Other", "ອື່ນໆ", 3),
  ],
  // Divorce only (`DivorceCertificatePage.tsx:654`). MEASURED: this page does
  // NOT treat the list as opaque reference data. `:745-746` compares the
  // selected code against the string literals "voluntary" and "contested",
  // and those two comparisons are the only thing that renders step 1's
  // mediation block (`:1204-1334`) or its court block (`:1337-1374`). So the
  // two literals must be in this list or step 1 has no reachable content at
  // all beyond the select itself.
  //
  // `mutual` is here because it is the tier0/divorce fixture matrix's value
  // VERBATIM (all six fixtures). A list that omitted it would stop the run at
  // `selectOption`'s MISSING OPTION and hide the far more consequential fact
  // that the pinned page has no branch for that code — see `driveDivorce`,
  // which measures the rendered DOM after the select is set rather than
  // assuming either outcome.
  "divorce-type": [
    refItem("divorce-type", "voluntary", "Voluntary", "ສະໝັກໃຈ", 1),
    refItem("divorce-type", "contested", "Contested", "ຂັດແຍ້ງ", 2),
    refItem("divorce-type", "mutual", "Mutual consent", "ຕົກລົງກັນ", 3),
  ],
  "blood-type": [
    refItem("blood-type", "O+", "O+", "O+", 1),
    refItem("blood-type", "A+", "A+", "A+", 2),
  ],
  "delivery-mode": [
    refItem("delivery-mode", "natural", "Natural", "ທຳມະຊາດ", 1),
    refItem("delivery-mode", "caesarean", "Caesarean", "ຜ່າຕັດ", 2),
  ],
  "birth-type": [
    refItem("birth-type", "single", "Single", "ຄົນດຽວ", 1),
    refItem("birth-type", "twins", "Twins", "ຝາແຝດ", 2),
  ],
};

const SYNTHESISED = {
  "locations-provinces": { data: LOCATIONS.provinces },
  "locations-districts": { data: LOCATIONS.districts },
  "locations-villages": { data: LOCATIONS.villages },
  "payment-methods": {
    data: [{ code: "laoqr", kind: "qr", enabled: true,
      label: { en: "Lao QR", lo: "ລາວ ຄິວອາ" } }],
  },
  // `CitizenProfile` (`api/types.ts`): `SessionProvider` reads
  // `profile.account.name` (`session.tsx:93`) during its first render, so an
  // envelope of the wrong shape crashes the app before any form exists. That
  // is the "stale or wrong fulfilled read" error class § 6.5.5 names, and it
  // is why it surfaces here as a boot failure rather than as a quiet default.
  "me-profile": {
    data: {
      account: { id: "00000000-0000-4000-8000-000000000000",
        name: "Test Citizen", uin: "TEST-UIN", phone: "02055500000",
        email: "test.citizen@example.test" },
      place: {
        province_name: { en: "Test Province One", lo: "ແຂວງທົດສອບໜຶ່ງ" },
        district_name: { en: "Test District Two", lo: "ເມືອງທົດສອບສອງ" },
        village_name: { en: "Test Village Three", lo: "ບ້ານທົດສອບສາມ" },
      },
      household_no: "CB-987654",
    },
  },
};

/** A read fixture, with the capture header `F0-AC-103` requires. */
function fixtureFor(slug, endpoint) {
  const path = join(API_FIXTURES, `${slug}.json`);
  if (existsSync(path)) return JSON.parse(readFileSync(path, "utf8"));

  // Two of the reads have a REAL recording under the versioned baseline; the
  // rest are synthetic and say so, because a synthesised fixture presented as
  // a recording is the provenance claim RULING 10 exists to stop being free.
  const recorded = join(TIER0, "..", "api", `${slug}.json`);
  let payload; let provenance;
  if (existsSync(recorded)) {
    payload = JSON.parse(readFileSync(recorded, "utf8"));
    provenance = `recorded — copied from oracle/api/${slug}.json`;
  } else if (SYNTHESISED[slug]) {
    payload = SYNTHESISED[slug];
    provenance = "synthetic — no recording of this endpoint exists in the "
      + "baseline and this programme has no account that could make one "
      + "(manifest-authenticated.md). The values are the ones the tier0 "
      + "fixture matrix selects from, so a mis-driven select cannot silently "
      + "resolve to a default.";
  } else {
    payload = { data: [] };
    provenance = "synthetic empty envelope — this endpoint is fulfilled so "
      + "that nothing escapes, and it feeds no Tier 0 leaf.";
  }

  const doc = {
    _capture: {
      endpoint,
      status: 200,
      captured_at: new Date(CLOCK_MS).toISOString(),
      provenance,
      credential: "none — the rig seeds a synthetic token and never "
        + "authenticates against any host",
    },
    ...payload,
  };
  mkdirSync(API_FIXTURES, { recursive: true });
  writeFileSync(path, `${JSON.stringify(doc, null, 2)}\n`, "utf8");
  return doc;
}

/** `/api/v1/locations/provinces/<id>/districts` -> `locations-districts`. */
function slugFor(pathname) {
  const p = pathname.replace(/^.*\/api\/v1\//, "").replace(/\/+$/, "");
  if (/^locations\/provinces$/.test(p)) return "locations-provinces";
  if (/^locations\/provinces\/[^/]+\/districts$/.test(p)) return "locations-districts";
  if (/^locations\/districts\/[^/]+\/villages$/.test(p)) return "locations-villages";
  if (/^locations\/districts$/.test(p)) return "locations-districts";
  if (/^reference-lists\/(.+)$/.test(p)) return `reference-${RegExp.$1}`;
  if (p === "services") return "services";
  if (p === "service-categories") return "service-categories";
  if (p === "payment-methods") return "payment-methods";
  if (p === "me" || p === "me/profile") return "me-profile";
  return p.replace(/[^a-z0-9]+/gi, "-").toLowerCase() || "root";
}

function readBodyFor(pathname) {
  const m = /\/api\/v1\/reference-lists\/([^/?]+)/.exec(pathname);
  if (m && REFERENCE_LISTS[m[1]]) {
    return { _capture: { endpoint: pathname, status: 200, provenance:
      "synthetic — the codes are exactly the ones the tier0 fixtures select" },
      data: REFERENCE_LISTS[m[1]] };
  }
  if (/\/locations\/provinces\/[^/]+\/districts/.test(pathname)) {
    const id = /provinces\/([^/]+)\/districts/.exec(pathname)[1];
    return { data: LOCATIONS.districts.filter((d) => d.province_id === id) };
  }
  if (/\/locations\/districts\/[^/]+\/villages/.test(pathname)) {
    const id = /districts\/([^/]+)\/villages/.exec(pathname)[1];
    return { data: LOCATIONS.villages.filter((v) => v.district_id === id) };
  }
  // `catalog.quote` is a POST (`endpoints.ts:182-183`) but it is a READ in
  // every respect that matters: it computes a fee and mutates nothing. Only
  // the two NESTED pages call it — `MarriageCertificatePage.tsx` and
  // `DivorceCertificatePage.tsx:667` — which is why Resident/Birth/Death runs
  // never surfaced it.
  //
  // It is answered from here rather than from `fixtures/api/`, because § 3.1's
  // file table is closed (`F0-AC-66`) and `fixtureFor` would WRITE a new
  // `services-<code>-quote.json` on first call. It feeds no Tier 0 leaf: `fee`
  // reaches only the CTA label and `PaymentSection`'s amount, never
  // `buildFormData`. Nor can the value here decide whether `pay` is issued —
  // that guard reads `submittedCase.fee_lak` off the SUBMIT response
  // (`DivorceCertificatePage.tsx:883`), not this one.
  if (/\/services\/[^/]+\/quote$/.test(pathname)) {
    return { _capture: { endpoint: pathname, status: 200, provenance:
      "synthetic — a fee quote, fulfilled so the POST cannot escape and so "
      + "the page's fee query does not sit in its error state" },
      data: { total_lak: 0, lines: [] } };
  }
  return fixtureFor(slugFor(pathname), pathname);
}

// ─────────────────────────────────────────────────────────────────────────────
// Property 2/3/5 — the interception table
// ─────────────────────────────────────────────────────────────────────────────

const WRITE_VERBS = [
  { name: "create", method: "POST", rx: /\/api\/v1\/applications$/ },
  { name: "update", method: "PATCH", rx: /\/api\/v1\/applications\/[^/]+$/ },
  { name: "attachment", method: "POST",
    rx: /\/api\/v1\/applications\/[^/]+\/attachments$/ },
  { name: "submit", method: "POST",
    rx: /\/api\/v1\/applications\/[^/]+\/submit$/ },
  { name: "pay", method: "POST", rx: /\/api\/v1\/applications\/[^/]+\/pay$/ },
  { name: "family-book-copy", method: "POST",
    rx: /\/api\/v1\/me\/family-book\/request-copy$/ },
];

/**
 * POSTs that are READS in everything but the verb.
 *
 * MEASURED on divorce: `catalog.quote` fires at mount (`useQuery`,
 * `DivorceCertificatePage.tsx:667`) and is a POST (`endpoints.ts:182-183`).
 * It is not in `WRITE_VERBS`, so before this list existed it fell to the
 * handler's "unmodelled write verb" arm, was aborted, and was counted as a
 * fall-through — i.e. `F0-AC-103` FAILED on divorce for a request that
 * mutates nothing and carries no Tier 0 payload. Aborting it also left
 * `quote.error` set, which renders an error row on step 5.
 *
 * These are fulfilled, never forwarded, and never captured as oracles: a
 * quote body is an INPUT to a fee calculation, not a `form_data` payload.
 */
const READ_SHAPED_POSTS = [
  { name: "fee-quote", method: "POST",
    rx: /\/api\/v1\/services\/[^/]+\/quote$/ },
];

const SYNTHETIC_CASE = {
  id: "aaaaaaaa-0000-4000-8000-000000000001",
  reference_no: "RC-2026-000123",
  status: "draft",
  status_label: { en: "Draft", lo: "ຮ່າງ" },
  fee_lak: 0,
  payment_state: "unpaid",
  subject_name: "Test Citizen",
};

/**
 * Two routes, and the pair is what makes `F0-AC-103` non-vacuous.
 *
 *  * **The safety net** is registered FIRST and is TOTAL over off-origin
 *    requests. Playwright matches the most recently registered route first, so
 *    it is the last resort. It aborts. Nothing in this file lets a request
 *    proceed to a real host — `F0-AC-103` greps for the absence of that call,
 *    and there is none.
 *  * **The API handler** is registered SECOND and therefore wins. It matches
 *    `/api/v1/` and fulfils.
 *
 * The counted quantity is **API requests that fell through to the safety net**
 * — requests the intended route pattern should have taken and did not. A
 * single total handler would make the count structurally zero and the
 * assertion worthless; `--control=broken-route` breaks the API pattern on
 * purpose and the count must go non-zero.
 *
 * Off-origin NON-API requests are aborted too and reported by name. They are
 * not failures — `index.html` references a font CDN — but they are printed
 * rather than swallowed, because "we intercepted everything" is a claim and
 * the list is the evidence.
 */
async function attach(page, state) {
  const local = state.origin;
  const apiMarker = CONTROL === "broken-route" ? "/api/v2/" : "/api/v1/";

  await page.route(
    (url) => !url.href.startsWith(local),
    async (route) => {
      const req = route.request();
      const url = new URL(req.url());
      if (url.pathname.includes("/api/v1/")) {
        state.fellThrough.push(`${req.method()} ${req.url()}`);
      } else {
        state.blockedEgress.push(`${req.method()} ${req.url()}`);
      }
      await route.abort();
    },
  );

  await page.route(
    (url) => !url.href.startsWith(local) && url.pathname.includes(apiMarker),
    async (route) => {
      const req = route.request();
      const url = new URL(req.url());
      state.handled.add(req.url());

      const write = WRITE_VERBS.find(
        (w) => w.method === req.method() && w.rx.test(url.pathname));
      if (write) {
        // THE MEASUREMENT. `postData()` is the exact serialised bytes; there
        // is nothing between the page's object literal and this string
        // (`client.ts:233-242`, `endpoints.ts:325`).
        if (CONTROL !== "no-capture") {
          state.captured.push({
            verb: write.name,
            method: req.method(),
            url: req.url(),
            postData: req.postData(),
          });
        }
        await route.fulfill({
          status: write.name === "create" ? 201 : 200,
          contentType: "application/json",
          // `reference_no` is a FIXTURE INPUT, not a rig constant. Each tier0
          // fixture declares `_reference_no` and Entry B computes the update
          // body's `header.document_no` / `purpose.*` from it; the nested
          // pages read it back off the create response
          // (`BirthDeclarationPage.tsx:832`). Answering with a hard-coded
          // reference would make Entry A and Entry B disagree on a leaf where
          // neither is defective — a manufactured BLOCKED that hides real ones.
          body: JSON.stringify({
            data: {
              ...SYNTHETIC_CASE,
              reference_no: state.referenceNo ?? SYNTHETIC_CASE.reference_no,
            },
          }),
        });
        return;
      }

      const readShaped = READ_SHAPED_POSTS.find(
        (r) => r.method === req.method() && r.rx.test(url.pathname));
      if (readShaped) {
        (state.readShaped ??= []).push(`${req.method()} ${req.url()}`);
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify(readBodyFor(url.pathname)),
        });
        return;
      }

      if (req.method() !== "GET") {
        state.fellThrough.push(`${req.method()} ${req.url()} (unmodelled `
          + `write verb — captured and withheld, never sent)`);
        await route.abort();
        return;
      }

      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify(readBodyFor(url.pathname)),
      });
    },
  );

  // The counter `F0-AC-103` asserts on. Evaluated after the run, so the
  // handler's own bookkeeping cannot race the event.
  page.on("request", (req) => state.seen.push(req.url()));
}

// ─────────────────────────────────────────────────────────────────────────────
// Properties 4 and 6 — synthetic session and frozen clock, before app boot
// ─────────────────────────────────────────────────────────────────────────────

const bootScript = (token, clockMs, locale) => `
  try {
    window.localStorage.setItem("lcc.access_token", ${JSON.stringify(token)});
    window.localStorage.setItem("lcc.refresh_token", ${JSON.stringify(token)});
    // i18n/index.tsx:14 — the ONE key the LanguageProvider reads. Seeding the
    // wrong one leaves the app in its default locale and every "lo" capture is
    // silently an "en" capture.
    window.localStorage.setItem("lcc-lang", ${JSON.stringify(locale)});
    // SplashScreens.tsx:31 — the boot splash always runs, then the three
    // onboarding screens run ONCE per browser profile. Without this the hash
    // route is ignored and no form is ever reachable (measured).
    window.localStorage.setItem("lcc_onboarding_seen", "1");
  } catch (e) { /* memory-only session */ }
  const FIXED = ${clockMs};
  const RealDate = Date;
  function FrozenDate(...a) {
    return a.length ? new RealDate(...a) : new RealDate(FIXED);
  }
  FrozenDate.prototype = RealDate.prototype;
  FrozenDate.now = () => FIXED;
  FrozenDate.parse = RealDate.parse;
  FrozenDate.UTC = RealDate.UTC;
  window.Date = FrozenDate;
`;

// ─────────────────────────────────────────────────────────────────────────────
// The field driver
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Resident's six steps, in render order, read from
 * `ResidentCertificatePage.tsx:716-1036`. Each list is the DOM order of the
 * controls that step renders, so the mapping from fixture key to on-screen
 * control is auditable against the JSX the same way every other transcription
 * in this batch is.
 *
 * `texts` are `input[type=text]` in order; `natives` are `ReferenceSelectView`
 * (a real `<select>`, `formFields.tsx:308`); `combos` are `SearchableSelect`
 * (a button plus a popover, `:154`/`:197`); `dates` are `DateField`.
 */
const RESIDENT_STEPS = [
  { step: 1, src: "ResidentCertificatePage.tsx:725-774", uploads: 4 },
  { step: 2, src: "ResidentCertificatePage.tsx:805-841", uploads: 1,
    texts: ["citizenName", "age", "occupation"],
    natives: ["nationality"] },
  { step: 3, src: "ResidentCertificatePage.tsx:856-884",
    combos: ["province", "district", "villageName"],
    texts: ["villageChiefName", "certifyingJurisdiction"] },
  { step: 4, src: "ResidentCertificatePage.tsx:904-928",
    texts: ["currentVillage", "houseNo", "unitNuayBan", "groupKhum"] },
  { step: 5, src: "ResidentCertificatePage.tsx:945-1009",
    texts: ["censusBookNo", "censusDistrictProvince", "fatherName",
      "motherName", "nativePlace"],
    dates: ["censusBookDate"],
    natives: ["purpose"] },
  // The payment method defaults to `qr`, and `isPaymentValid` returns true for
  // it with no input (`PaymentSection.tsx:100-109`). Pressing the CTA here is
  // what runs `submitCase` -> create -> update -> attachments -> submit -> pay.
  { step: 6, src: "ResidentCertificatePage.tsx:1022" },
];

/**
 * Birth's six steps, in render order, read from
 * `BirthDeclarationPage.tsx:1055-1546`. Same discipline as `RESIDENT_STEPS`
 * above — every index below is the DOM ordinal of a control in the JSX that
 * step renders — with two shape differences the page forces:
 *
 *  1. **Indices are EXPLICIT `[ordinal, value]` pairs, not list position.**
 *     Step 2 sets `child.birth_type` first and leaves the other selects for a
 *     second pass, so its `natives` list is sparse. A positional list cannot
 *     express that without a placeholder that reads as "set this to blank".
 *  2. **A step is a list of PASSES.** Two controls gate the existence of
 *     others: `birthType === "twins"` renders the twin pair (`:1157-1172`) and
 *     the sole-parent toggle un-renders the whole father section (`:1357`).
 *     A pass boundary is where the DOM must be re-read.
 *
 * The fixture stores only a VILLAGE id per address; `chainFor` walks the
 * synthetic registry back up to its district and province, because
 * `LocationFields` disables each level until its parent is set (`:481`,
 * `:494`) and a driver that guessed the parents would click a disabled button.
 */
function chainFor(villageId, what) {
  const v = LOCATIONS.villages.find((r) => r.id === villageId);
  if (!v) {
    throw new Error(`FIXTURE_VILLAGE_UNKNOWN ${what}=${villageId} — the `
      + `fixture selects a village the rig does not fulfil, so the combo `
      + `would be left at its default and captured as an executed byte`);
  }
  const d = LOCATIONS.districts.find((r) => r.id === v.district_id);
  const p = LOCATIONS.provinces.find((r) => r.id === d.province_id);
  return [p.id, d.id, v.id];
}

/** `[start, start+1, …]` paired with `values`. */
const idx = (start, values) => values.map((v, k) => [start + k, v]);

/**
 * `SearchableSelect`'s trigger, narrowed for Birth.
 *
 * MEASURED: the sole-parent toggle (`BirthDeclarationPage.tsx:1332-1337`) is
 * also a `button[type=button]` carrying `rounded-2xl` AND `justify-between`,
 * so `RESIDENT_STEPS`' selector matches it and every combo index on step 4
 * shifts by one. `gap-2` separates them — the trigger has `gap-2`
 * (`formFields.tsx:157`), the toggle has `gap-3`. The popover's option
 * buttons carry `gap-2` too but no `rounded-2xl`, so they stay excluded.
 */
const BIRTH_COMBO = 'button[type="button"].rounded-2xl.justify-between.gap-2';

function birthSteps(fx) {
  const c = fx.child;
  const twins = c.birthType === "twins";

  // Step 2's text and select ordinals, computed rather than hard-coded,
  // because the twin pair sits in the MIDDLE of both runs (`:1157-1172`).
  const texts2 = [[0, c.fullName], [1, c.birthOrder]];
  let ti = 2;
  if (twins) texts2.push([ti++, c.twinName]);
  texts2.push([ti++, c.pobCountry], [ti++, c.addrHouseNo], [ti++, c.weight],
    [ti++, c.height], [ti++, c.deliveryAssistedBy], [ti++, c.fingerprint]);

  // select 1 is `birth_type`, set in pass 1, so pass 2 starts at 2.
  const natives2 = [[0, c.gender]];
  let ni = 2;
  if (twins) natives2.push([ni++, c.twinGender]);
  natives2.push([ni++, c.ethnicity], [ni++, c.nationality], [ni++, c.religion],
    [ni++, c.bloodType], [ni++, c.deliveryMode]);

  /**
   * `ParentSection` (`:453-580`) renders identically for the mother
   * (prefix `parents`) and the father (prefix `parents.father`), so ONE pass
   * shape serves steps 3 and 4. That is a fact about the SECTION COMPONENT,
   * not about the payload: `parentData` is emitted under two prefixes for the
   * mother and one for the father (`:786-790`), and Death's own `parentData`
   * has a 14th key (`workplace`) — § 6.4 item 6 forbids sharing across pages,
   * and nothing here is shared with any other form's driver.
   */
  const parentPass = (p, who) => ({
    combos: idx(0, chainFor(p.addrVillage, `${who}.addrVillage`)),
    texts: [[0, p.fullName], [1, p.addrHouseNo], [2, p.censusOrId],
      [3, p.occupation], [4, p.fingerprint]],
    dates: [[0, p.dob]],
    natives: [[0, p.maritalStatus], [1, p.ethnicity], [2, p.nationality],
      [3, p.ethnicGroup], [4, p.religion], [5, p.education]],
  });

  const inf = fx.informant;

  return [
    { step: 1, src: "BirthDeclarationPage.tsx:1076-1090",
      passes: [{ combos: idx(0, [fx.header.province, fx.header.district,
        fx.header.village]) }] },

    { step: 2, src: "BirthDeclarationPage.tsx:1101-1297",
      passes: [
        { natives: [[1, c.birthType]] },
        { uploads: 1,
          combos: [...idx(0, chainFor(c.pobVillage, "child.pobVillage")),
            ...idx(3, chainFor(c.addrVillage, "child.addrVillage"))],
          texts: texts2, dates: [[0, c.dob]], natives: natives2 },
      ] },

    { step: 3, src: "BirthDeclarationPage.tsx:1299-1310",
      passes: [parentPass(fx.mother, "mother")] },

    // `fatherUnknown` is the KEY-SET branch, not a value branch: the 13
    // `parents.father.*` keys collapse to one `parents.father.status`
    // (`:788-790`). Toggling it is therefore the whole pass.
    { step: 4, src: "BirthDeclarationPage.tsx:1312-1367",
      passes: fx.fatherUnknown
        ? [{ toggle: true }]
        : [parentPass(fx.father, "father")] },

    { step: 5, src: "BirthDeclarationPage.tsx:1369-1497",
      passes: [{
        combos: idx(0, chainFor(inf.addrVillage, "informant.addrVillage")),
        texts: [[0, inf.fullName], [1, inf.addrHouseNo], [2, inf.censusOrId],
          [3, inf.phone], [4, inf.email], [5, inf.fingerprint]],
        dates: [[0, inf.dob]],
        natives: [[0, inf.relationship], [1, inf.maritalStatus],
          [2, inf.education], [3, inf.nationality], [4, inf.ethnicity],
          [5, inf.ethnicGroup], [6, inf.religion]],
      }] },

    // Pressing the CTA here runs `submitCase` -> create -> update -> attach ->
    // submit (`:817-844`). `pay` is a SEPARATE button on the success screen
    // and is gated on `submitted.fee_lak > 0` (`:936`), which the synthetic
    // case sets to 0, so Birth's `pay` is never issued. It carries no
    // `form_data` and is not a Tier 0 oracle either way.
    { step: 6, src: "BirthDeclarationPage.tsx:1546" },
  ];
}

/** form -> { plan(fixture), drive(page, fixture) }. */
const DRIVERS = {
  resident: { plan: () => RESIDENT_STEPS, drive: driveResident },
  birth: { plan: birthSteps, drive: driveBirth },
  death: { plan: deathSteps, drive: driveDeath },
  divorce: { plan: divorceSteps, drive: driveDivorce },
};

const PNG_1PX = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk"
  + "+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==", "base64");

/** The one CTA, in the fixed footer (`ResidentCertificatePage.tsx:1034`). */
function cta(page) {
  return page.locator("div.fixed.bottom-0 button").last();
}

async function driveResident(page, fixture) {
  const form = fixture.form;
  if (!(await page.locator('input[type="file"]').count())) {
    throw new Error("FORM_NOT_REACHED — the hash route did not open the "
      + "Resident wizard. A driver that carried on from here would fill "
      + "whatever controls happened to be on screen and capture the page's "
      + "DEFAULTS as executed bytes.");
  }

  for (const plan of RESIDENT_STEPS) {
    await page.waitForTimeout(200);

    for (let i = 0; i < (plan.uploads ?? 0); i++) {
      const input = page.locator('input[type="file"]').nth(i);
      await input.setInputFiles({
        name: `synthetic-${plan.step}-${i}.png`,
        mimeType: "image/png",
        buffer: PNG_1PX,
      });
      await page.waitForTimeout(250);
    }
    // Step 1 reads the uploaded ID and prefills three of step 2's fields. The
    // CTA is gated on `!detecting`, so the fills below must come after it
    // settles or they are overwritten by the detection that lands late.
    if (plan.uploads) await page.waitForTimeout(1200);

    for (const [i, key] of (plan.combos ?? []).entries()) {
      await pickCombo(page, i, String(form[key] ?? ""));
      await page.waitForTimeout(350);
    }
    for (const [i, key] of (plan.texts ?? []).entries()) {
      const box = page.locator('input[type="text"]').nth(i);
      await box.fill(String(form[key] ?? ""), { timeout: 5000 });
    }
    for (const [i, key] of (plan.dates ?? []).entries()) {
      await page.locator('input[type="date"]').nth(i)
        .fill(String(form[key] ?? ""), { timeout: 5000 });
    }
    for (const [i, key] of (plan.natives ?? []).entries()) {
      await page.locator("select").nth(i)
        .selectOption(String(form[key] ?? ""), { timeout: 5000 });
    }

    await page.waitForTimeout(200);
    const button = cta(page);
    const before = await stepIndicator(page);
    await button.click({ timeout: 8000 });
    await page.waitForTimeout(plan.step === 6 ? 2500 : 700);

    if (plan.step < 6) {
      const after = await stepIndicator(page);
      if (after === before) {
        throw new Error(`STEP_${plan.step}_DID_NOT_ADVANCE — canProceed() is `
          + `false, so a mandatory control on this step was not set. The run `
          + `stops here rather than pressing on and capturing the page's `
          + `defaults (${plan.src}).`);
      }
    }
  }
}

/** The step counter the wizard renders, used to prove the CTA advanced. */
async function stepIndicator(page) {
  const text = await page.locator("body").innerText();
  // MEASURED: `StepHeader` renders `t("stepOf")` under Tailwind `uppercase`
  // (`BirthDeclarationPage.tsx:641`), and `innerText` returns the TRANSFORMED
  // text — "STEP 1 OF 6". Without `i` this falls through to the 80-character
  // slice, which still differs between steps (so the advance check kept
  // working) but can never be read as a step NUMBER.
  const m = /(\d+)\s*\/\s*6|\b(\d+)\s+(?:of|ຈາກ)\s+6/i.exec(text);
  return m ? (m[1] ?? m[2]) : text.slice(0, 80);
}

/**
 * `SearchableSelect` is a button plus a popover of option buttons
 * (`formFields.tsx:154`, `:197`) — not a `<select>`.
 *
 * It THROWS when the option is absent. A combo the rig silently fails to set
 * leaves the page's DEFAULT in the payload, which is the single
 * systematic-error class § 6.5.5 names as the reason Entry B survives: a
 * document that looks executed but carries a default is worse than none.
 */
async function pickCombo(page, index, value,
  selector = 'button[type="button"].rounded-2xl.justify-between') {
  const trigger = page.locator(selector).nth(index);
  await trigger.click({ timeout: 8000 });
  await page.waitForTimeout(250);

  // The visible label is the bilingual NAME the rig itself fulfilled for this
  // id, resolved through the same `text(name, lang)` the page uses. Matching
  // on the id -> label mapping rather than on raw text means the locale seed
  // cannot change which row is chosen.
  const row = [...LOCATIONS.provinces, ...LOCATIONS.districts,
    ...LOCATIONS.villages].find((r) => r.id === value);
  const wanted = row ? (row.name[LOCALE] || row.name.en) : value;

  const options = page.locator('div[class*="z-[60]"] button[type="button"]');
  const count = await options.count();
  for (let i = 0; i < count; i++) {
    const label = (await options.nth(i).innerText()).trim();
    if (label === wanted || label.startsWith(wanted)) {
      await options.nth(i).click();
      return;
    }
  }
  throw new Error(`COMBO_OPTION_ABSENT index=${index} value=${value} `
    + `wanted=${JSON.stringify(wanted)} — the rig would otherwise capture the `
    + `page's DEFAULT and present it as an executed byte`);
}

// ─────────────────────────────────────────────────────────────────────────────
// Birth's field driver
// ─────────────────────────────────────────────────────────────────────────────

/** The sole-parent toggle (`BirthDeclarationPage.tsx:1332-1337`), gap-3. */
const fatherToggle = (page) =>
  page.locator('button[type="button"].rounded-2xl.justify-between.gap-3');

/**
 * One pass over the controls currently rendered. Combos go FIRST because
 * `LocationFields` disables each level until its parent holds a value
 * (`formFields.tsx:494`, `:507`), and a disabled trigger is a click timeout,
 * not a silent no-op — which is the behaviour we want.
 */
async function applyPass(page, pass, combo) {
  if (!combo) throw new Error("applyPass needs the CALLING PAGE's combo "
    + "selector. Defaulting it would let one page's trigger narrowing decide "
    + "another page's combo ordinals — § 6.4 item 6.");
  for (const [i, value] of pass.combos ?? []) {
    await pickCombo(page, i, String(value ?? ""), combo);
    await page.waitForTimeout(350);
  }
  for (const [i, value] of pass.texts ?? []) {
    await page.locator('input[type="text"]').nth(i)
      .fill(String(value ?? ""), { timeout: 5000 });
  }
  for (const [i, value] of pass.dates ?? []) {
    await page.locator('input[type="date"]').nth(i)
      .fill(String(value ?? ""), { timeout: 5000 });
  }
  for (const [i, value] of pass.natives ?? []) {
    // `selectOption` THROWS when the code is not among the <option> values, so
    // a reference list the rig failed to fulfil stops the run instead of
    // leaving the page's blank default in the payload.
    await page.locator("select").nth(i)
      .selectOption(String(value ?? ""), { timeout: 5000 });
  }
}

async function driveBirth(page, fixture) {
  // Birth's step 1 has no upload, so Resident's `input[type=file]` probe does
  // not apply. The step counter is the reachability proof here: it exists only
  // inside the wizard (`StepHeader`, `:643`).
  const opened = await stepIndicator(page);
  if (opened !== "1") {
    throw new Error(`FORM_NOT_REACHED — the hash route did not open the Birth `
      + `wizard at step 1 (step indicator read ${JSON.stringify(opened)}). A `
      + `driver that carried on from here would fill whatever controls `
      + `happened to be on screen and capture the page's DEFAULTS as `
      + `executed bytes.`);
  }

  for (const plan of birthSteps(fixture)) {
    await page.waitForTimeout(250);

    for (const pass of plan.passes ?? []) {
      if (pass.toggle) {
        await fatherToggle(page).click({ timeout: 8000 });
        await page.waitForTimeout(400);
        continue;
      }
      for (let i = 0; i < (pass.uploads ?? 0); i++) {
        await page.locator('input[type="file"]').nth(i).setInputFiles({
          name: `synthetic-${plan.step}-${i}.png`,
          mimeType: "image/png",
          buffer: PNG_1PX,
        });
        // `UploadBox` sets state from a `FileReader.onload` (`:355-357`), so
        // the guard `canProceed` reads is not set synchronously.
        await page.waitForTimeout(500);
      }
      await applyPass(page, pass, BIRTH_COMBO);
      await page.waitForTimeout(250);
    }

    await page.waitForTimeout(200);
    const before = await stepIndicator(page);
    await cta(page).click({ timeout: 8000 });
    await page.waitForTimeout(plan.step === 6 ? 3000 : 800);

    if (plan.step < 6) {
      const after = await stepIndicator(page);
      if (after === before) {
        throw new Error(`STEP_${plan.step}_DID_NOT_ADVANCE — canProceed() is `
          + `false, so a mandatory control on this step was not set. The run `
          + `stops here rather than pressing on and capturing the page's `
          + `defaults (${plan.src}).`);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Death's field driver
// ─────────────────────────────────────────────────────────────────────────────

/**
 * `SearchableSelect`'s trigger on Death.
 *
 * MEASURED: `ParentStep`'s "parent deceased / unknown" toggle
 * (`DeathDeclarationPage.tsx:588-593`) is a `button[type=button]` carrying
 * `rounded-2xl` AND `justify-between`, exactly like Birth's sole-parent
 * toggle, so the un-narrowed Resident selector matches it and every combo
 * index on steps 3 and 4 shifts by one. `gap-2` separates them — the trigger
 * has `gap-2` (`formFields.tsx:157`), the toggle has `gap-3` (`:590`).
 *
 * Step 1's "Document No." panel is also `rounded-2xl justify-between`
 * (`DeathDeclarationPage.tsx:1078`) but it is a `<div>`, so `button[type=…]`
 * already excludes it. The popover's option rows carry `justify-between gap-2`
 * (`formFields.tsx:203`) and no `rounded-2xl`, so they stay excluded too.
 *
 * This constant is Death's own on purpose. § 6.4 item 6 forbids sharing a
 * helper across pages: the two strings are equal TODAY, and a shared constant
 * would make one page's re-style silently mis-drive the other.
 */
const DEATH_COMBO = 'button[type="button"].rounded-2xl.justify-between.gap-2';

/** The parent skip toggle (`DeathDeclarationPage.tsx:588-593`), gap-3. */
const deathParentToggle = (page) =>
  page.locator('button[type="button"].rounded-2xl.justify-between.gap-3');

/**
 * Death's six steps, in render order, read from
 * `DeathDeclarationPage.tsx:1076-1512`. Same `[ordinal, value]` discipline as
 * `birthSteps`, and the same reason for it: two ordinals are conditional.
 *
 *  1. **`cause === "other"` renders a free-text "specify"** (`:1240-1248`) in
 *     the MIDDLE of step 2's text run, so every text after it shifts. It is
 *     set in its own pass, and the ordinals below are computed from whether
 *     that pass rendered it.
 *  2. **The parent skip toggle un-renders the whole `ParentSection`**
 *     (`:614`). Toggling it is the entire pass, exactly as for Birth's
 *     `fatherUnknown` — but here it exists on BOTH parent steps and the mother
 *     side collapses TWO key blocks (`parents.*` and `parents.mother.*`,
 *     `:815-816`), not one.
 *
 * NOTHING here is shared with `birthSteps`. Death's `ParentSection`
 * (`:449-570`) is a different component from Birth's: it inserts `workplace`
 * between `occupation` and `fingerprint` (`:556-568`), which moves the
 * fingerprint text ordinal from Birth's 4 to Death's 5. A shared `parentPass`
 * would be right on thirteen keys and silently wrong on the fourteenth — the
 * exact failure § 6.4 item 6 names.
 */
function deathSteps(fx) {
  const d = fx.deceased;
  const causeOther = d.cause === "other";

  // Step 2's text ordinals, computed rather than hard-coded, because the
  // "specify the cause" box sits between `time_of_death` and `occupation`.
  const texts2 = [[0, d.fullName], [1, d.addrHouseNo], [2, d.censusOrId],
    [3, d.timeOfDeath]];
  let ti = 4;
  if (causeOther) texts2.push([ti++, d.causeOther]);
  texts2.push([ti++, d.occupation], [ti++, d.workplace], [ti++, d.fingerprint]);

  /**
   * `ParentSection` renders identically for the mother (prefix `parents`) and
   * the father (prefix `parents.father`), so one pass shape serves steps 3
   * and 4 OF THIS PAGE. Ordinals read off `:461-568`.
   */
  const parentPass = (p, who) => ({
    combos: idx(0, chainFor(p.addrVillage, `${who}.addrVillage`)),
    texts: [[0, p.fullName], [1, p.addrHouseNo], [2, p.censusOrId],
      [3, p.occupation], [4, p.workplace], [5, p.fingerprint]],
    dates: [[0, p.dob]],
    natives: [[0, p.maritalStatus], [1, p.ethnicity], [2, p.nationality],
      [3, p.ethnicGroup], [4, p.religion], [5, p.education]],
  });

  const inf = fx.informant;

  return [
    { step: 1, src: "DeathDeclarationPage.tsx:1088-1102",
      passes: [{ combos: idx(0, [fx.header.province, fx.header.district,
        fx.header.village]) }] },

    // The current-address `LocationFields` (`:1181-1190`) precedes the
    // place-of-death one (`:1201-1214`) in the DOM, so the address chain is
    // combos 0-2 and the place-of-death chain is 3-5 — the OPPOSITE order to
    // Birth's step 2, where place of birth comes first.
    { step: 2, src: "DeathDeclarationPage.tsx:1117-1315",
      passes: [
        { natives: [[4, d.cause]] },
        { uploads: 1,
          combos: [...idx(0, chainFor(d.addrVillage, "deceased.addrVillage")),
            ...idx(3, chainFor(d.podVillage, "deceased.podVillage"))],
          texts: texts2,
          dates: [[0, d.dob], [1, d.dateOfDeath]],
          natives: [[0, d.gender], [1, d.ethnicity], [2, d.nationality],
            [3, d.maritalStatus], [5, d.education], [6, d.ethnicGroup],
            [7, d.religion]] },
      ] },

    // `motherSkip` is the KEY-SET branch for TWO blocks at once: `parents.*`
    // and `parents.mother.*` both collapse to a single `.status` key
    // (`:765-766`, `:815-816`). Toggling it is therefore the whole pass.
    { step: 3, src: "DeathDeclarationPage.tsx:1317-1328",
      passes: fx.motherSkip
        ? [{ toggle: true }]
        : [parentPass(fx.mother, "mother")] },

    { step: 4, src: "DeathDeclarationPage.tsx:1331-1342",
      passes: fx.fatherSkip
        ? [{ toggle: true }]
        : [parentPass(fx.father, "father")] },

    // Death's informant is TWELVE keys (`:820-831`) against Birth's fifteen —
    // no `ethnicity`, no `ethnic_group`, no `religion`. Three of Birth's seven
    // informant selects simply do not exist here, and its select run is
    // relation / marital / education / nationality (`:1362`, `:1440-1456`).
    { step: 5, src: "DeathDeclarationPage.tsx:1345-1457",
      passes: [{
        combos: idx(0, chainFor(inf.addrVillage, "informant.addrVillage")),
        texts: [[0, inf.fullName], [1, inf.addrHouseNo], [2, inf.censusOrId],
          [3, inf.phone], [4, inf.email], [5, inf.fingerprint]],
        dates: [[0, inf.dob]],
        natives: [[0, inf.relationship], [1, inf.maritalStatus],
          [2, inf.education], [3, inf.nationality]],
      }] },

    // Pressing the CTA here runs `submitCase` -> create -> update -> attach ->
    // submit (`:840-868`). `pay` is a SEPARATE mutation (`:871-877`) fired
    // from a button on the success screen that only renders while
    // `submitted.fee_lak > 0` (`:960`), which the synthetic case sets to 0 —
    // so Death's `pay`, like Birth's, is never issued. It carries no
    // `form_data` and is not a Tier 0 oracle either way.
    { step: 6, src: "DeathDeclarationPage.tsx:1512" },
  ];
}

async function driveDeath(page, fixture) {
  // Death's step 1 has no upload either, so Resident's `input[type=file]`
  // probe does not apply. The step counter is the reachability proof: it
  // exists only inside the wizard (`StepHeader`, `:661-668`).
  const opened = await stepIndicator(page);
  if (opened !== "1") {
    throw new Error(`FORM_NOT_REACHED — the hash route did not open the Death `
      + `wizard at step 1 (step indicator read ${JSON.stringify(opened)}). A `
      + `driver that carried on from here would fill whatever controls `
      + `happened to be on screen and capture the page's DEFAULTS as `
      + `executed bytes.`);
  }

  for (const plan of deathSteps(fixture)) {
    await page.waitForTimeout(250);

    for (const pass of plan.passes ?? []) {
      if (pass.toggle) {
        await deathParentToggle(page).click({ timeout: 8000 });
        await page.waitForTimeout(400);
        continue;
      }
      for (let i = 0; i < (pass.uploads ?? 0); i++) {
        await page.locator('input[type="file"]').nth(i).setInputFiles({
          name: `synthetic-${plan.step}-${i}.png`,
          mimeType: "image/png",
          buffer: PNG_1PX,
        });
        // `UploadBox` sets state from a `FileReader.onload` (`:346-352`), so
        // the guard `canProceed` reads is not set synchronously.
        await page.waitForTimeout(500);
      }
      await applyPass(page, pass, DEATH_COMBO);
      await page.waitForTimeout(250);
    }

    await page.waitForTimeout(200);
    const before = await stepIndicator(page);
    await cta(page).click({ timeout: 8000 });
    await page.waitForTimeout(plan.step === 6 ? 3000 : 800);

    if (plan.step < 6) {
      const after = await stepIndicator(page);
      if (after === before) {
        throw new Error(`STEP_${plan.step}_DID_NOT_ADVANCE — canProceed() is `
          + `false, so a mandatory control on this step was not set. The run `
          + `stops here rather than pressing on and capturing the page's `
          + `defaults (${plan.src}).`);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divorce's field driver
// ─────────────────────────────────────────────────────────────────────────────

/**
 * `SearchableSelect`'s trigger on Divorce.
 *
 * MEASURED: `ToggleRow` — the "there are children" switch
 * (`DivorceCertificatePage.tsx:429-437`) — is a `button[type=button]` carrying
 * `rounded-2xl` AND `justify-between`, exactly like Birth's and Death's parent
 * toggles, so the un-narrowed Resident selector matches it and every combo
 * ordinal after it on step 1 shifts. `gap-2` separates them: the trigger has
 * `gap-2` (`formFields.tsx:158`), the toggle has `gap-3` (`:433`).
 *
 * Three other `rounded-2xl` buttons live on step 1 and none of them collide:
 * the two mediation-mode chooser cards (`:1067`, `:1081`) and `DocUpload`'s
 * drop target (`:407`) carry `gap-3` but NOT `justify-between`; the
 * mediation-number panel (`:1214`) has both classes but is a `<div>`. The
 * popover's option rows (`formFields.tsx:203`) carry `justify-between gap-2`
 * and no `rounded-2xl`, so they stay excluded.
 *
 * This constant is Divorce's own on purpose (§ 6.4 item 6). It is equal to
 * `DEATH_COMBO` and `BIRTH_COMBO` TODAY; a shared constant would let one
 * page's restyle silently mis-drive the other two.
 */
const DIVORCE_COMBO = 'button[type="button"].rounded-2xl.justify-between.gap-2';

/** The "there are children" toggle (`DivorceCertificatePage.tsx:1285`). */
const divorceChildrenToggle = (page) =>
  page.locator('button[type="button"].rounded-2xl.justify-between.gap-3');

/**
 * The two mediation-mode cards (`:1064` select-existing, `:1078` create-new).
 * They render only while `mediationMode === ""`, which is also the only state
 * in which no `ToggleRow` exists, so `gap-3 p-4 rounded-2xl` without
 * `justify-between` selects exactly this pair, in DOM order.
 */
const divorceMediationChooser = (page) =>
  page.locator('button[type="button"].rounded-2xl.gap-3.p-4');

/** One pass over the controls Divorce currently renders. */
async function applyDivorcePass(page, pass) {
  // Combos first: `ApiLocationFields` disables district until a province is
  // set and village until a district is (`:341`, `:359`), and a disabled
  // trigger is a click timeout rather than a silent no-op.
  for (const [i, value] of pass.combos ?? []) {
    await pickCombo(page, i, String(value ?? ""), DIVORCE_COMBO);
    await page.waitForTimeout(350);
  }
  for (const [i, value] of pass.texts ?? []) {
    await page.locator('input[type="text"]').nth(i)
      .fill(String(value ?? ""), { timeout: 5000 });
  }
  // Divorce is the first page in this batch with `<textarea>` controls
  // (`TextAreaField`, `:220`): five of step 1's mediation inputs and both
  // children inputs are textareas, not text boxes, so they occupy their own
  // ordinal run and do NOT shift `input[type=text]`.
  for (const [i, value] of pass.textareas ?? []) {
    await page.locator("textarea").nth(i)
      .fill(String(value ?? ""), { timeout: 5000 });
  }
  for (const [i, value] of pass.dates ?? []) {
    await page.locator('input[type="date"]').nth(i)
      .fill(String(value ?? ""), { timeout: 5000 });
  }
  for (const [i, value] of pass.natives ?? []) {
    await page.locator("select").nth(i)
      .selectOption(String(value ?? ""), { timeout: 5000 });
  }
}

/**
 * Divorce's six steps, in render order, read from
 * `DivorceCertificatePage.tsx:1034-1554`.
 *
 * Step 1 is the whole difficulty and it is unlike anything in Birth or Death.
 * `basis.divorceType` is not merely a payload leaf: `:745-746` turns it into
 * `isVoluntary` / `isContested`, and those two booleans decide which of THREE
 * mutually exclusive sub-forms step 1 renders —
 *
 *   * `isVoluntary && mediationMode === ""`   the two chooser cards (`:1056`)
 *   * `isVoluntary && mediationMode === "new"` the mediation record, the
 *     division block, the children pair and the two witnesses (`:1204-1334`)
 *   * `isContested`                            the court block (`:1337-1374`)
 *
 * — and NEITHER renders for any other code. The header `ApiLocationFields`
 * exists only inside the second and third of those (`:1224`, `:1339`), so a
 * code with no branch leaves step 1 with one `<select>` and nothing else.
 *
 * `spousePass` is Divorce's own (§ 6.4 item 6). `SpouseSection` (`:460-530`)
 * is an eight-control section whose ordinals are read off `:470`, `:479`,
 * `:486`, `:496`, `:506`, `:512`, `:520`; Marriage's same-named section is a
 * different component feeding a 13-key `spousePayload` against Divorce's 8.
 */
function divorceSteps(fx) {
  const m = fx.mediation ?? {};
  const kids = fx.children ?? {};
  const voluntary = fx.basis.divorceType === "voluntary";
  const contested = fx.basis.divorceType === "contested";

  const headerCombos = [[0, fx.header.provinceId], [1, fx.header.districtId],
    [2, fx.header.villageId]];

  const spousePass = (s) => ({
    combos: [[0, s.address.provinceId], [1, s.address.districtId],
      [2, s.address.villageId]],
    texts: [[0, s.fullName], [1, s.idOrPassport], [2, s.addrHouseNo],
      [3, s.marriageCertRef]],
    dates: [[0, s.dob]],
    natives: [[0, s.nationality]],
  });

  // Step 1's textarea run, computed rather than hard-coded, because the
  // children pair (`:1293`, `:1300`) renders in the MIDDLE of nothing but at
  // the END of the run — it is conditional on `hasChildren`, and a fixture
  // with `hasChildren: false` simply has no ordinals 4 and 5.
  const textareas1 = [[0, m.reasonsHusband], [1, m.reasonsWife],
    [2, m.outcome], [3, m.propertyDivision]];
  if (fx.hasChildren) textareas1.push([4, kids.list], [5, kids.custody]);

  const step1 = [
    // Pass 1 sets the type. Everything else on this step is downstream of it.
    { natives: [[0, fx.basis.divorceType]] },
    // Pass 2 MEASURES what that produced and refuses to guess. See
    // `probeDivorceBranch`.
    { probe: true },
  ];
  if (voluntary) {
    step1.push(
      { chooser: 1 },
      { combos: headerCombos },
      { childrenToggle: Boolean(fx.hasChildren) },
      { dates: [[0, m.dateMarriageBegan]],
        textareas: textareas1,
        texts: [[0, m.debts], [1, m.additionalAssets],
          [2, m.w1Name], [3, m.w2Name]] },
    );
  } else if (contested) {
    step1.push(
      { combos: headerCombos },
      { uploads: 1,
        texts: [[0, fx.court.name]],
        dates: [[0, fx.court.decisionDate]] },
    );
  }

  return [
    { step: 1, src: "DivorceCertificatePage.tsx:1034-1376", passes: step1 },
    { step: 2, src: "DivorceCertificatePage.tsx:1379-1394",
      passes: [spousePass(fx.husband)] },
    { step: 3, src: "DivorceCertificatePage.tsx:1397-1412",
      passes: [spousePass(fx.wife)] },
    // The three uploads are household book, guarantee certificate, photos —
    // that DOM order (`:1442`, `:1448`, `:1455`) is NOT the order `uploads()`
    // lists them in for the attachment POSTs (`:840-845`), and only the DOM
    // order matters here.
    { step: 4, src: "DivorceCertificatePage.tsx:1415-1470",
      passes: [{ uploads: 3,
        dates: [[0, fx.basis.dateOfDivorce]],
        texts: [[0, fx.basis.placeOfRegistration]] }] },
    // Step 5 is a read-only review (`:1473-1542`); `canProceed()` returns the
    // default `true` for it (`:775`). No controls, so no pass.
    { step: 5, src: "DivorceCertificatePage.tsx:1473-1542", passes: [] },
    // Pressing the CTA here runs `submitCase` (`:848-887`): create ->
    // attachments -> update -> submit, then `pay` behind a two-part guard
    // (`:883`) that reads `submittedCase.fee_lak` off the SUBMIT response.
    // The synthetic case sets `fee_lak: 0`, so Divorce's `pay` is not issued
    // — same as Birth's and Death's. It carries no `form_data` and is not a
    // Tier 0 oracle either way.
    { step: 6, src: "DivorceCertificatePage.tsx:1545-1554", passes: [] },
  ];
}

/**
 * Step 1's branch, MEASURED after the type select is set — not assumed.
 *
 * This exists because the alternative is worse in a specific way. If the
 * fixture's `divorceType` has no branch, the page renders one `<select>` and
 * nothing else; a driver that pressed on would find no combos, no date, no
 * textareas, fill nothing, and stop at the generic
 * `STEP_1_DID_NOT_ADVANCE` — which reads as "a mandatory control was missed"
 * when the truth is "this state does not exist in the pinned application."
 * Those two are not the same finding and § 8.3 needs the second one named.
 */
async function probeDivorceBranch(page, fx) {
  const inventory = {
    selects: await page.locator("select").count(),
    combos: await page.locator(DIVORCE_COMBO).count(),
    choosers: await divorceMediationChooser(page).count(),
    toggles: await divorceChildrenToggle(page).count(),
    texts: await page.locator('input[type="text"]').count(),
    textareas: await page.locator("textarea").count(),
    dates: await page.locator('input[type="date"]').count(),
    files: await page.locator('input[type="file"]').count(),
  };
  const seen = JSON.stringify(inventory);
  const code = fx.basis.divorceType;
  const voluntary = code === "voluntary";
  const contested = code === "contested";

  // What the fixture ITSELF says step 1 must have produced, read off the
  // fixture rather than off the page.
  const wantsMediation = Boolean(
    (fx.mediation?.propertyDivision ?? "").trim()
    || (fx.mediation?.outcome ?? "").trim()
    || (fx.mediation?.dateMarriageBegan ?? "").trim()
    || fx.hasChildren);
  const wantsCourt = Boolean(
    (fx.court?.name ?? "").trim() || (fx.court?.decisionDate ?? "").trim());

  if (!voluntary && !contested) {
    throw new Error(`DIVORCE_TYPE_HAS_NO_BRANCH divorceType=${
      JSON.stringify(code)} — MEASURED after setting the type select: ${seen}. `
      + `\`DivorceCertificatePage.tsx:745-746\` compares the selected code `
      + `against the STRING LITERALS "voluntary" and "contested"; any other `
      + `code leaves \`isVoluntary\` and \`isContested\` both false, so step 1 `
      + `renders only the type select (:1036) — no header ApiLocationFields `
      + `(:1224/:1339), no mediation block, no court block — and `
      + `\`canProceed()\` falls through to the contested arm (:765), which `
      + `needs a header, a court name, a decision date and a court-decision `
      + `upload that this state never renders. The step therefore cannot `
      + `advance for ANY sequence of clicks. This is not a missed control: `
      + `the state the fixture describes does not exist in the pinned `
      + `application. Nothing is edited to make it exist.`
      + (wantsMediation && wantsCourt
        ? ` It is also unreachable independently of the code: the fixture `
          + `carries BOTH mediation content (only editable under `
          + `isVoluntary && mediationMode === "new", :1204-1334) AND court `
          + `content (only editable under isContested, :1337-1374), and those `
          + `two branches are mutually exclusive on one boolean pair.`
        : ""));
  }

  if (wantsMediation && wantsCourt) {
    throw new Error(`DIVORCE_FIXTURE_SPANS_BOTH_BRANCHES `
      + `divorceType=${JSON.stringify(code)} — MEASURED: ${seen}. The fixture `
      + `carries mediation content (editable only under `
      + `isVoluntary && mediationMode === "new", :1204-1334) AND court `
      + `content (editable only under isContested, :1337-1374). \`:745-746\` `
      + `makes those branches mutually exclusive, so no sequence of UI `
      + `actions produces both. Driving one of them and leaving the other at `
      + `its blank default would land an Entry A document whose disagreement `
      + `with Entry B was manufactured by this driver's choice — the exact `
      + `thing § 8.3 forbids resolving unilaterally.`);
  }

  if (contested && !wantsCourt) {
    throw new Error(`DIVORCE_CONTESTED_WITHOUT_COURT — the fixture selects `
      + `"contested" but carries no court name or decision date, and `
      + `\`canProceed()\` (:765) requires both plus the decree upload.`);
  }
}

async function driveDivorce(page, fixture) {
  // Divorce's step 1 has no upload on the voluntary path, so Resident's
  // `input[type=file]` probe does not apply. The step counter is the
  // reachability proof: it exists only inside the wizard (`StepHeader`,
  // `:570-581`).
  const opened = await stepIndicator(page);
  if (opened !== "1") {
    throw new Error(`FORM_NOT_REACHED — the hash route did not open the `
      + `Divorce wizard at step 1 (step indicator read `
      + `${JSON.stringify(opened)}). A driver that carried on from here would `
      + `fill whatever controls happened to be on screen and capture the `
      + `page's DEFAULTS as executed bytes.`);
  }

  for (const plan of divorceSteps(fixture)) {
    await page.waitForTimeout(250);

    for (const pass of plan.passes ?? []) {
      if (pass.probe) {
        await probeDivorceBranch(page, fixture);
        continue;
      }
      if (pass.chooser !== undefined) {
        const cards = divorceMediationChooser(page);
        const n = await cards.count();
        if (n !== 2) {
          throw new Error(`DIVORCE_MEDIATION_CHOOSER_NOT_RENDERED — expected `
            + `the two cards at :1064/:1078, found ${n}. Clicking blind here `
            + `would leave mediationMode "" and capture the page's defaults.`);
        }
        await cards.nth(pass.chooser).click({ timeout: 8000 });
        await page.waitForTimeout(600);
        continue;
      }
      if (pass.childrenToggle !== undefined) {
        // `hasChildren` starts false (`:638`), so the fixture's `true` is one
        // click and its `false` is none. It is a KEY-VALUE branch, not a
        // key-set one: `mediation.custody_arrangement` (:805),
        // `mediation.children` (:812) and `basis.custody_reference` (:830)
        // all stay present and collapse to "".
        if (pass.childrenToggle) {
          const toggle = divorceChildrenToggle(page);
          const n = await toggle.count();
          if (n !== 1) {
            throw new Error(`DIVORCE_CHILDREN_TOGGLE_AMBIGUOUS — expected `
              + `exactly one gap-3 toggle at :1285, found ${n}.`);
          }
          await toggle.click({ timeout: 8000 });
          await page.waitForTimeout(400);
        }
        continue;
      }
      for (let i = 0; i < (pass.uploads ?? 0); i++) {
        await page.locator('input[type="file"]').nth(i).setInputFiles({
          name: `synthetic-${plan.step}-${i}.png`,
          mimeType: "image/png",
          buffer: PNG_1PX,
        });
        // `DocUpload` sets state straight from the change event (`:382-386`),
        // but React's commit is still a tick away.
        await page.waitForTimeout(400);
      }
      await applyDivorcePass(page, pass);
      await page.waitForTimeout(250);
    }

    await page.waitForTimeout(200);
    const before = await stepIndicator(page);
    await cta(page).click({ timeout: 8000 });
    await page.waitForTimeout(plan.step === 6 ? 3000 : 800);

    if (plan.step < 6) {
      const after = await stepIndicator(page);
      if (after === before) {
        throw new Error(`STEP_${plan.step}_DID_NOT_ADVANCE — canProceed() is `
          + `false, so a mandatory control on this step was not set. The run `
          + `stops here rather than pressing on and capturing the page's `
          + `defaults (${plan.src}).`);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// A === B, per leaf
// ─────────────────────────────────────────────────────────────────────────────

function leafPaths(node, prefix = "") {
  if (node !== null && typeof node === "object" && !Array.isArray(node)) {
    return Object.entries(node).flatMap(([k, v]) =>
      leafPaths(v, `${prefix}/${k.replace(/~/g, "~0").replace(/\//g, "~1")}`));
  }
  if (Array.isArray(node)) {
    return node.flatMap((v, i) => leafPaths(v, `${prefix}/${i}`));
  }
  return [prefix];
}

function valueAt(root, pointer) {
  let cur = root;
  for (const raw of pointer.slice(1).split("/")) {
    const token = raw.replace(/~1/g, "/").replace(/~0/g, "~");
    if (cur === null || typeof cur !== "object" || !(token in cur)) {
      return undefined;
    }
    cur = cur[token];
  }
  return cur;
}

/**
 * `F0-AC-104`. Returns `{ compared, mismatches }`.
 *
 * `compared === 0` is NOT a pass. `F0-AC-106(b)` exists because a rig that
 * captured nothing satisfies "every captured leaf agrees" vacuously, and that
 * is the same shape as `F0-AC-86`'s complement guard over an empty oracle.
 */
function compareEntries(executedBody, transcribed, label) {
  const mismatches = [];
  let compared = 0;
  const wanted = leafPaths(transcribed);
  const got = leafPaths(executedBody);
  for (const p of wanted) {
    if (!got.includes(p)) {
      mismatches.push(`${label}: MISSING ON THE WIRE  ${p}`);
      continue;
    }
    const a = JSON.stringify(valueAt(executedBody, p));
    const b = JSON.stringify(valueAt(transcribed, p));
    compared++;
    if (a !== b) {
      mismatches.push(`${label}: ${p} — executed ${a}, transcribed ${b}`);
    }
  }
  for (const p of got) {
    if (!wanted.includes(p)) mismatches.push(`${label}: UNEXPECTED  ${p}`);
  }
  return { compared, mismatches };
}

// ─────────────────────────────────────────────────────────────────────────────
// Run
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  assertPinnedSubject();
  const before = gitStatusOfWeb();

  const { createServer } = await import(
    join(VENDOR, "vite", "dist", "node", "index.js"));
  const { chromium } = require(join(VENDOR, "playwright"));

  const server = await createServer({
    root: WEB,
    configFile: join(WEB, "vite.config.ts"),
    server: { host: "127.0.0.1", port: 0, strictPort: false },
    logLevel: "warn",
  });
  await server.listen();
  const port = server.config.server.port ?? server.httpServer.address().port;
  const origin = `http://127.0.0.1:${port}`;
  console.log(`serving the pinned source at ${origin}`);

  const state = {
    origin, handled: new Set(), seen: [],
    fellThrough: [], blockedEgress: [], captured: [],
  };

  const browser = await chromium.launch({ headless: true });
  let exitCode = 0;
  try {
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.addInitScript(bootScript(SYNTHETIC_TOKEN, CLOCK_MS, LOCALE));
    await attach(page, state);

    await page.goto(`${origin}/`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);

    const authed = await page.evaluate(
      () => window.localStorage.getItem("lcc.access_token"));
    const frozen = await page.evaluate(() => new Date().toISOString());
    console.log(`synthetic session seeded: ${authed !== null}`);
    console.log(`clock frozen at: ${frozen}`);
    if (frozen.slice(0, 10) !== "2026-08-13") {
      fail(`the clock is not frozen at ADR-0005's instant (got ${frozen}); `
        + `today() would move between the create and the update`);
    }

    const fixturePath = join(HERE, "fixtures", "tier0", FORM,
      `${VARIANT}.${LOCALE}.json`);
    const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));
    // The create response's `reference_no` is a fixture input — see the
    // `route.fulfill` on the write verbs.
    state.referenceNo = fixture._reference_no;
    if (CONTROL === "value-drift") {
      // F0-AC-106(a): one character changed in a DRIVEN INPUT must surface as
      // an A-vs-B disagreement naming the leaf. The drifted field has to be
      // one this form's driver actually TYPES — drifting a key the driver
      // never touches proves nothing, and a `--control` run that is inert on
      // the form under test is the vacuity F0-AC-106 exists to expose.
      if (fixture.form) fixture.form.citizenName = `${fixture.form.citizenName}X`;
      else if (fixture.child) fixture.child.fullName = `${fixture.child.fullName}X`;
      else if (fixture.deceased) {
        fixture.deceased.fullName = `${fixture.deceased.fullName}X`;
      } else fail(`--control=value-drift has no driven input to drift on ${FORM}`);
    }

    // routes.ts:21-26 — the hash path per service. Hard-coded here rather than
    // guessed, so adding a driver for another family does not also need a
    // navigation fix.
    const ROUTES = {
      resident: "#/service/resident-certificate",
      birth: "#/service/birth-declaration",
      death: "#/service/death-declaration",
      marriage: "#/service/marriage-certificate",
      divorce: "#/service/divorce-certificate",
      "family-book": "#/service/family-book",
    };
    if (!ROUTES[FORM]) fail(`no route known for form ${FORM}`);
    await page.goto(`${origin}/${ROUTES[FORM]}`,
      { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);

    // The locale seed, PROVEN rather than assumed. Resident has no
    // locale-dependent payload key (Finding E lists none on this form), so its
    // `en` and `lo` captures are identical BY DESIGN and cannot themselves
    // show the seed took. Reading the CTA back is the only evidence available
    // here — and it matters: the app reads `lcc-lang` (i18n/index.tsx:14) and
    // nothing else, so seeding a near-miss key leaves every "lo" capture
    // silently an "en" capture.
    const ctaLabel = (await cta(page).innerText().catch(() => "")).trim();
    console.log(`locale seed ${LOCALE}: CTA reads ${JSON.stringify(ctaLabel)}`);
    if (!ctaLabel) {
      console.error("locale seed UNVERIFIED — no CTA on screen to read back");
    }

    let driverError = null;
    if (DRIVERS[FORM]) {
      try {
        await DRIVERS[FORM].drive(page, fixture);
      } catch (err) { driverError = err.message; }
    } else {
      driverError = `NO_DRIVER_FOR_${FORM}`;
    }

    // ── Property 5, evaluated ────────────────────────────────────────────
    const offOrigin = state.seen.filter((u) => !u.startsWith(origin));
    console.log(`\nrequests seen: ${state.seen.length} `
      + `(off-origin ${offOrigin.length}, fulfilled by the API route `
      + `${state.handled.size}, fell through ${state.fellThrough.length})`);
    console.log(`write bodies captured: ${state.captured.length}`);
    for (const line of state.blockedEgress) {
      console.log(`  blocked non-API egress (aborted, never sent): ${line}`);
    }
    if (state.fellThrough.length) {
      console.error("F0-AC-103 FAIL — these API requests reached no API "
        + "handler. They were aborted by the safety net, so nothing left the "
        + "machine, but the route table did not cover them:");
      for (const u of state.fellThrough) console.error(`  ${u}`);
      exitCode = 1;
    } else {
      console.log("F0-AC-103: every /api/v1/ request was taken by the API "
        + "route; zero fell through; zero left the machine.");
    }

    // ── F0-AC-104 — land Entry A, then assert A === B per leaf ──────────
    let compared = 0;
    const mismatches = [];
    const landed = [];
    const withheld = [];
    // A CONTROL run must never land documents. `--control=value-drift`
    // deliberately drives a corrupted input, and writing its capture over the
    // real Entry A oracle would leave a poisoned document on disk that reads
    // as evidence.
    const land = CONTROL === "";
    if (state.captured.length && land) mkdirSync(EXECUTED, { recursive: true });

    for (const cap of state.captured) {
      // The attachment POST is `multipart/form-data`, not JSON — it is
      // captured and withheld like every other write, but it carries no Tier 0
      // payload and is not an oracle.
      if (cap.verb === "attachment" || !cap.postData
          || !cap.postData.trimStart().startsWith("{")) {
        withheld.push(`${cap.verb} (${cap.postData ? "non-JSON body" : "no body"})`);
        continue;
      }
      let body;
      try {
        body = JSON.parse(cap.postData);
      } catch (err) {
        withheld.push(`${cap.verb} (unparseable: ${err.message})`);
        continue;
      }
      // `submit` and `pay` carry no `form_data`; they are part of the sequence
      // Tier 0 models but not part of the payload it compares.
      if (!(cap.verb === "create" || cap.verb === "update")) {
        withheld.push(`${cap.verb} (no form_data — sequence, not payload)`);
        continue;
      }
      const kind = cap.verb;
      const formData = body.form_data ?? body;

      const doc = {
        schema: "tier0/1",
        form: FORM,
        body: kind,
        locale: LOCALE,
        attempt: "first",
        clock: new Date(CLOCK_MS).toISOString(),
        provenance: {
          web_commit: WEB_COMMIT,
          entry: "A",
          derived_by: "test/fidelity/execute_forms_oracle.mjs",
          method: "EXECUTED — route.request().postData() on the pinned "
            + "application, served locally from sources/lcc-app at the pin and "
            + "driven under Playwright with every off-origin request "
            + "intercepted. Nothing here is transcribed.",
          leaf_provenance: "executed",
          request: { method: cap.method, url: cap.url },
          fixture: `fixtures/tier0/${FORM}/${VARIANT}.${LOCALE}.json`,
        },
        form_data: formData,
        paths: leafPaths(formData),
        envelope: Object.fromEntries(Object.entries(body).map(([k, v]) => [
          k, k === "form_data" ? { present: true, value: "<form_data>" }
            : { present: true, value: v },
        ])),
        // The evidence itself. Every field above is derived from this string;
        // this string came off the socket.
        raw_bytes: cap.postData,
      };
      const name = `${FORM}.${VARIANT_TAG}${kind}.${LOCALE}.json`;
      if (land) {
        writeFileSync(join(EXECUTED, name),
          `${JSON.stringify(doc, null, 2)}\n`, "utf8");
        landed.push(name);
      }

      const bPath = VARIANT_TAG
        ? join(TIER0, "variants", name) : join(TIER0, name);
      if (!existsSync(bPath)) {
        mismatches.push(`${name}: Entry B has no counterpart`);
        continue;
      }
      const b = JSON.parse(readFileSync(bPath, "utf8"));
      // The label carries the VARIANT too. Without it a `--variant` run's
      // disagreement prints under the baseline's name, and a reader chasing
      // `death.create.en` would open the wrong pair of documents.
      const r = compareEntries(formData, b.form_data,
        `${FORM}.${VARIANT_TAG}${kind}.${LOCALE}`);
      compared += r.compared;
      mismatches.push(...r.mismatches);
    }

    console.log(`\nEntry A landed ${landed.length} document(s): `
      + `${landed.join(", ") || "(none)"}`);
    for (const w of withheld) console.log(`  withheld, not an oracle: ${w}`);

    console.log(`\nF0-AC-104: ${compared} leaves compared A vs B, `
      + `${mismatches.length} disagreements`);
    for (const m of mismatches) console.error(`  ${m}`);
    if (mismatches.length) {
      console.error("\nBLOCKED (§ 8.3). A disagreement is EITHER a "
        + "transcription defect OR a rig defect. Do not edit one side to "
        + "match the other — escalate with the file:line Entry B cited.");
      exitCode = 1;
    }
    if (compared === 0) {
      console.error("\nF0-AC-104 NOT EVALUATED — zero leaves were captured, "
        + "so \"every captured leaf agrees\" is vacuously true. This is "
        + "exactly the vacuity F0-AC-106(b) exists to expose, and it is "
        + "reported as NOT EVALUATED rather than PASS.");
      if (CONTROL !== "no-capture") exitCode = 2;
    }
    if (driverError) {
      console.error(`\ndriver stopped: ${driverError}`);
      console.error("Entry A's MECHANISM ran (pin, boot, synthetic session, "
        + "frozen clock, total interception, zero egress). Its FIELD DRIVER "
        + "did not complete, so no form reached submitCase and no write body "
        + "exists to compare. These leaves are NOT eligible for "
        + "oracle_coverage.yaml: that register takes only branches proven "
        + "structurally unreachable (F0-AC-105).");
    }
  } finally {
    await browser.close();
    await server.close();
  }

  // ── § 3.2 clause 2 ────────────────────────────────────────────────────
  const after = gitStatusOfWeb();
  console.log(`\ngit status in sources/lcc-app after the run:\n${after || "(clean)"}`);
  if (after !== before) {
    console.error("FAIL — the rig changed the port source. § 4.1 makes any "
      + "write under sources/lcc-app an automatic FAIL (F0-AC-66).");
    exitCode = 1;
  }
  process.exit(exitCode);
}

main().catch((err) => { console.error(err); process.exit(1); });
