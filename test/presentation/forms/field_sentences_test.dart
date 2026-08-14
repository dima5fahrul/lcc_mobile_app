/// The three kernel-owned sentences, checked against the JSON assets —
/// § 6.11's third row, and the consumer `field_sentences.dart` names.
///
/// ## Why this file has to exist
///
/// `formFields.tsx:30-38` declares `LOAD_FAILED`, `RETRY` and `NOTHING_YET` as
/// module-level `Bilingual` literals that **no `ns/*.ts` namespace owns**
/// (§ 6.11). The widgets cannot render those literals directly — they render
/// `.tr(context: context)` out of `assets/i18n/{en,lo}.json` so the strings
/// repaint when the citizen flips the toggle (D-3 / G-L8). That means the
/// bytes exist twice: once as the transcription of record in
/// `field_sentences.dart`, once as JSON.
///
/// Two copies with nothing comparing them is a typo waiting to happen, and a
/// typo in the **Lao** side is invisible to every reviewer who does not read
/// Lao. This file is the comparison. Without it `kFormFieldSentences` is a
/// constant nobody reads, which is exactly how it looked before this test
/// landed.
///
/// The assertion runs against the real asset files rather than a fixture,
/// because the file the app ships is the thing that can be wrong.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/field_sentences.dart';

Map<String, dynamic> _load(String locale) {
  final File f = File('assets/i18n/$locale.json');
  expect(
    f.existsSync(),
    isTrue,
    reason: 'assets/i18n/$locale.json must exist — without it this test would '
        'pass vacuously by finding nothing to disagree with',
  );
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  late Map<String, dynamic> en;
  late Map<String, dynamic> lo;

  setUpAll(() {
    en = _load('en');
    lo = _load('lo');
  });

  group('the kernel-owned formFields group', () {
    test('exists in BOTH locales', () {
      expect(en[kFormFieldsNamespace], isA<Map<String, dynamic>>());
      expect(lo[kFormFieldsNamespace], isA<Map<String, dynamic>>());
    });

    test('carries exactly the three sentences, and no fourth', () {
      // A fourth key here would mean the kernel grew a sentence the source has
      // no literal for — a divergence no fidelity tier reads, since Tier 1
      // draws these from the component source (§ 6.11).
      const Set<String> expected = <String>{
        'loadFailed',
        'retry',
        'nothingYet',
      };
      expect(
        (en[kFormFieldsNamespace] as Map<String, dynamic>).keys.toSet(),
        expected,
      );
      expect(
        (lo[kFormFieldsNamespace] as Map<String, dynamic>).keys.toSet(),
        expected,
      );
    });

    test('every key the widgets actually call is present', () {
      // The widgets reference these three by constant, not by literal, so a
      // renamed constant and a renamed JSON key would drift together and stay
      // green. Resolving the constant against the file is what catches it.
      for (final String dotted in kFormFieldSentences.keys) {
        final List<String> parts = dotted.split('.');
        expect(parts, hasLength(2), reason: '$dotted is not `group.key`');
        expect(
          (en[parts[0]] as Map<String, dynamic>?)?.containsKey(parts[1]),
          isTrue,
          reason: 'en.json is missing $dotted, which a widget calls .tr() on',
        );
        expect(
          (lo[parts[0]] as Map<String, dynamic>?)?.containsKey(parts[1]),
          isTrue,
          reason: 'lo.json is missing $dotted, which a widget calls .tr() on',
        );
      }
    });
  });

  group('the JSON equals the transcription of formFields.tsx:30-38', () {
    test('the English side is byte-identical to the source literals', () {
      kFormFieldSentences.forEach((String dotted, FormSentence sentence) {
        final List<String> parts = dotted.split('.');
        expect(
          (en[parts[0]] as Map<String, dynamic>)[parts[1]],
          sentence.en,
          reason: '$dotted: en.json disagrees with the literal transcribed '
              'from formFields.tsx:30-38',
        );
      });
    });

    test('the LAO side is byte-identical — the half no reviewer can eyeball',
        () {
      kFormFieldSentences.forEach((String dotted, FormSentence sentence) {
        final List<String> parts = dotted.split('.');
        expect(
          (lo[parts[0]] as Map<String, dynamic>)[parts[1]],
          sentence.lo,
          reason: '$dotted: lo.json disagrees with the literal transcribed '
              'from formFields.tsx:30-38. This is the assertion that exists '
              'because a Lao typo is invisible in review.',
        );
      });
    });

    test('the two locales differ — the check is not comparing en to en', () {
      // Without this, a lo.json accidentally filled with English copy would
      // satisfy every assertion above.
      for (final FormSentence s in kFormFieldSentences.values) {
        expect(s.lo, isNot(s.en));
      }
    });
  });

  group('the transcription itself', () {
    test('is the three constants, mapped under the formFields group', () {
      expect(kFormFieldSentences, hasLength(3));
      expect(kFormFieldSentences[kLoadFailedKey], kLoadFailed);
      expect(kFormFieldSentences[kRetryKey], kRetry);
      expect(kFormFieldSentences[kNothingYetKey], kNothingYet);
      for (final String key in kFormFieldSentences.keys) {
        expect(key, startsWith('$kFormFieldsNamespace.'));
      }
    });

    test('FormSentence compares by VALUE — the assertions above depend on it',
        () {
      // `expect(a, b)` on two identical-but-distinct instances must pass, or
      // every equality assertion in this file would be an identity check that
      // happens to hold for `const`.
      expect(
        const FormSentence(en: 'Retry', lo: 'ລອງໃໝ່'),
        FormSentence(en: 'Ret${'ry'}', lo: 'ລອງ${'ໃໝ່'}'),
      );
      expect(
        const FormSentence(en: 'a', lo: 'b'),
        isNot(const FormSentence(en: 'a', lo: 'c')),
      );
    });

    test('is NOT the twelve-key `fields` namespace — they are different groups',
        () {
      // `fields` is a verbatim port of `i18n/ns/fields.ts`, fixed at 12
      // (`F0-AC-63`). Appending the three sentences there would make the port
      // of a source file differ from the source file, which is why the kernel
      // owns a separate group.
      expect(kFormFieldsNamespace, isNot('fields'));
      expect((en['fields'] as Map<String, dynamic>).length, 12);
      expect((lo['fields'] as Map<String, dynamic>).length, 12);
      for (final String key in kFormFieldSentences.keys) {
        expect(
          (en['fields'] as Map<String, dynamic>).containsKey(key.split('.')[1]),
          isFalse,
          reason: 'a kernel sentence leaked into the ported `fields` namespace',
        );
      }
    });
  });
}
