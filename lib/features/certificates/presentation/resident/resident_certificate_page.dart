/// `ResidentCertificatePage.tsx:318-1067` — the page itself: the four
/// top-level branches and the fixed bottom CTA.
///
/// The branch order is the source's and it is load-bearing: **loading**
/// (`:584`), **error** (`:593`), **success** (`:617`), then the wizard
/// (`:672`). A success renders even while a refetch is in flight, because the
/// success check comes after both catalogue checks and both are guarded by
/// `&& !serviceQuery.data`.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/forms/validation/scroll_to_first_error.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/forms/widgets/field_base.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../application/domain/entities/application_detail.dart';
import '../../../wallet/domain/wallet_formatting.dart';
import 'resident_fields.dart';
import 'resident_form_cubit.dart';
import 'resident_steps.dart';

/// `TXT` — `ResidentCertificatePage.tsx:136-146`.
///
/// **Six page-local sentences the `resident` namespace does not carry**, and
/// they must not be promoted into it: the namespace's key count is asserted at
/// exactly 102 and promoting these would make it 108 (`F1-AC-74`,
/// `F1-AC-76`). They live here as constants, which is where the source puts
/// them.
class ResidentTxt {
  const ResidentTxt._();

  static const FormSentencePair loadFailed = FormSentencePair(
    en: 'We could not load this service right now.',
    lo: 'ພວກເຮົາບໍ່ສາມາດໂຫຼດບໍລິການນີ້ໄດ້ໃນຕອນນີ້.',
  );
  static const FormSentencePair retry =
      FormSentencePair(en: 'Retry', lo: 'ລອງໃໝ່');
  static const FormSentencePair loading = FormSentencePair(
    en: 'Loading the service…',
    lo: 'ກຳລັງໂຫຼດບໍລິການ…',
  );
  static const FormSentencePair receipt =
      FormSentencePair(en: 'Receipt No.', lo: 'ເລກທີ່ໃບຮັບເງິນ');
  static const FormSentencePair fee =
      FormSentencePair(en: 'Fee', lo: 'ຄ່າທຳນຽມ');
}

/// A `Bilingual` that is a compile-time constant.
///
/// `Bilingual` is a `freezed` class and its constructor is not `const`, so the
/// six sentences above cannot be written as one. Same two fields, same
/// resolution rule.
class FormSentencePair {
  const FormSentencePair({required this.en, required this.lo});

  final String en;
  final String lo;

  String call(Lang lang) => lang == Lang.lo ? lo : en;
}

/// `ResidentCertificatePageProps` — `:319-321`.
class ResidentCertificatePage extends StatefulWidget {
  const ResidentCertificatePage({
    super.key,
    required this.cubit,
    required this.onBack,
    this.pickFile = pickResidentFile,
  });

  /// Resolved by the **route builder**, never by a widget (`ssd.md`:511,
  /// G-L5). Passed rather than created here so a test can pump the page with a
  /// cubit built from fakes and no container at all (`F1-AC-10`).
  final ResidentFormCubit cubit;

  /// `onBack()` — `:320`. Called when back is tapped on step 1 (`:547`).
  final VoidCallback onBack;

  /// Injected all the way down to [ResidentUploadBox] so R-21 is assertable
  /// without a device (`F1-AC-43`).
  final ResidentFilePicker pickFile;

  @override
  State<ResidentCertificatePage> createState() =>
      _ResidentCertificatePageState();
}

class _ResidentCertificatePageState extends State<ResidentCertificatePage> {
  int _lastScrollTick = 0;

  @override
  void initState() {
    super.initState();
    // The four `useQuery`s at `:336-340`, which fire on mount.
    widget.cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final Lang lang = Localizations.localeOf(context).languageCode == 'lo'
        ? Lang.lo
        : Lang.en;

    return BlocConsumer<ResidentFormCubit, ResidentFormViewState>(
      bloc: widget.cubit,
      // `scrollToFirstError()` is a side effect of two transitions (`:557`,
      // `:578`), not a rendered thing. The cubit bumps a counter and the page
      // performs it, so nothing in the cubit reaches for a `BuildContext`.
      listenWhen: (ResidentFormViewState a, ResidentFormViewState b) =>
          a.scrollToErrorTick != b.scrollToErrorTick,
      listener: (BuildContext context, ResidentFormViewState state) {
        if (state.scrollToErrorTick == _lastScrollTick) return;
        _lastScrollTick = state.scrollToErrorTick;
        scrollToFirstError(context);
      },
      builder: (BuildContext context, ResidentFormViewState state) {
        // `:584-591` — loading.
        if (state.showsServiceLoading) {
          return _ServiceLoading(text: ResidentTxt.loading(lang));
        }
        // `:593-614` — error, with retry AND back-to-home (`F1-AC-73`).
        if (state.showsServiceError) {
          return _ServiceError(
            message: ResidentTxt.loadFailed(lang),
            detail: state.service.error ?? '',
            retryLabel: ResidentTxt.retry(lang),
            onRetry: widget.cubit.refetchService,
            onBack: widget.onBack,
          );
        }
        // `:617-668` — success.
        final ResidentSubmitted? submitted = state.submitted;
        if (submitted != null) {
          return _SuccessCard(
            submitted: submitted,
            citizenName: state.form.citizenName,
            processingTime: _processingTime(context, state, lang),
            lang: lang,
            onBack: widget.onBack,
          );
        }
        return _wizard(context, state, lang);
      },
    );
  }

  /// `:343-345` — `serviceQuery.data ? text(processing_time, lang) :
  /// t("successCompletionValue")`.
  String _processingTime(
    BuildContext context,
    ResidentFormViewState state,
    Lang lang,
  ) =>
      state.service.data == null
          ? 'resident.successCompletionValue'.tr(context: context)
          : text(state.service.data!.processingTime, lang);

  Widget _wizard(
    BuildContext context,
    ResidentFormViewState state,
    Lang lang,
  ) {
    // `<ValidationProvider showErrors serverErrors onClearServerError>` —
    // `:673-677`, wrapping the WHOLE wizard including the CTA.
    return ValidationScope(
      showErrors: state.showErrors,
      serverErrors: state.serverErrors,
      onClearServerError: widget.cubit.clearServerError,
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          children: <Widget>[
            _SubHeader(onBack: _goBack),
            ResidentStepIndicator(step: state.step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ResidentStepHeader(step: state.step),
                    // `{submitError && (…)}` — `:708-713`. What the API said
                    // about the last submission, above the step body.
                    if (state.submitError != null) ...<Widget>[
                      const SizedBox(height: 20),
                      ResidentNotice.red(text: state.submitError!),
                    ],
                    const SizedBox(height: 20),
                    _stepBody(state),
                  ],
                ),
              ),
            ),
            _Cta(
              pending: state.submitPending,
              isLastStep: state.isLastStep,
              amount: state.fee,
              lang: lang,
              onTap: widget.cubit.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(ResidentFormViewState state) => switch (state.step) {
        1 => ResidentStep1(
            cubit: widget.cubit,
            state: state,
            pickFile: widget.pickFile,
          ),
        2 => ResidentStep2(
            cubit: widget.cubit,
            state: state,
            pickFile: widget.pickFile,
          ),
        3 => ResidentStep3(cubit: widget.cubit, state: state),
        4 => ResidentStep4(cubit: widget.cubit, state: state),
        5 => ResidentStep5(cubit: widget.cubit, state: state),
        _ => ResidentStep6(cubit: widget.cubit, state: state),
      };

  /// `goBack` — `:544-548`.
  void _goBack() {
    if (widget.cubit.goBack()) widget.onBack();
  }
}

/// `:584-590`.
class _ServiceLoading extends StatelessWidget {
  const _ServiceLoading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray400Inline,
              ),
            ),
          ],
        ),
      );
}

/// `:593-613` — **retry AND back-to-home**, both (`F1-AC-73`).
class _ServiceError extends StatelessWidget {
  const _ServiceError({
    required this.message,
    required this.detail,
    required this.retryLabel,
    required this.onRetry,
    required this.onBack,
  });

  final String message;

  /// `serviceQuery.error.message` — `:599`. The API's own sentence, under the
  /// fixed copy rather than instead of it.
  final String detail;
  final String retryLabel;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const LucideIcon(
                  name: 'AlertCircle',
                  size: 40,
                  color: AppColors.dangerGlyphSoft,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400Inline,
                  ),
                ),
                const SizedBox(height: 16),
                _PrimaryButton(
                  label: retryLabel,
                  icon: 'RefreshCw',
                  onTap: onRetry,
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBack,
                    child: Text(
                      'resident.backToHome'.tr(context: context),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray400Inline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// `:617-667` — the success card and its six rows.
class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.submitted,
    required this.citizenName,
    required this.processingTime,
    required this.lang,
    required this.onBack,
  });

  final ResidentSubmitted submitted;
  final String citizenName;
  final String processingTime;
  final Lang lang;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ApplicationDetail decided = submitted.decided;

    // `:635-643` — the rows, in order, with the receipt row CONDITIONAL.
    final List<_SuccessRow> rows = <_SuccessRow>[
      _SuccessRow(
        label: 'resident.successApplicant'.tr(context: context),
        // `decided.subject_name || form.citizenName` — `:636`. Falls back to
        // what the citizen typed when the API answered an empty subject.
        value: decided.row.subjectName.isEmpty
            ? citizenName
            : decided.row.subjectName,
      ),
      _SuccessRow(
        label: 'resident.successReference'.tr(context: context),
        value: decided.row.referenceNo,
      ),
      // `...(submitted.receiptNo ? [{…}] : [])` — `:638-640`. **Absent**, not
      // blank, when there is no receipt (`F1-AC-27`).
      if (submitted.receiptNo != null)
        _SuccessRow(
          label: ResidentTxt.receipt(lang),
          value: submitted.receiptNo!,
        ),
      _SuccessRow(
        label: ResidentTxt.fee(lang),
        value: formatLak(decided.row.feeLak, lang.name),
      ),
      _SuccessRow(
        label: 'resident.successCompletion'.tr(context: context),
        value: processingTime,
      ),
      _SuccessRow(
        label: 'resident.successStatus'.tr(context: context),
        value: text(decided.row.statusLabel, lang),
        // `isStatus: true` — rendered as an amber pill, not plain text
        // (`:647-650`).
        isStatus: true,
      ),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  // `linear-gradient(135deg, #344EAD 0%, #1a2d7a 100%)` —
                  // `:624`. Tier 2 compares both stops (`F1-AC-56`).
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.primary, AppColors.brandGradientEnd],
                  ),
                ),
                child: const LucideIcon(
                  name: 'Check',
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'resident.successTitle'.tr(context: context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'resident.successMessage'.tr(context: context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < rows.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 12),
                      rows[i],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _PrimaryButton(
                label: 'resident.backToHome'.tr(context: context),
                onTap: onBack,
              ),
              const SizedBox(height: 12),
              Text(
                'resident.trackHint'.tr(context: context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400Inline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  final String label;
  final String value;
  final bool isStatus;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isStatus
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warningReference,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray800,
                      ),
                    ),
            ),
          ),
        ],
      );
}

/// `:681-696` — the sub-header, with a spacer balancing the back button.
class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: LucideIcon(
                      name: 'ChevronLeft',
                      size: 20,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    'resident.headerTitle'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray800,
                    ),
                  ),
                  Text(
                    'resident.headerSubtitle'.tr(context: context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      );
}

/// `:1035-1063` — the fixed bottom CTA.
class _Cta extends StatelessWidget {
  const _Cta({
    required this.pending,
    required this.isLastStep,
    required this.amount,
    required this.lang,
    required this.onTap,
  });

  final bool pending;
  final bool isLastStep;
  final int amount;
  final Lang lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: Semantics(
        button: true,
        // **NEVER disabled** (`F1-AC-65`). The source's `<button>` carries no
        // `disabled` attribute and keeps `cursor: pointer` while pending
        // (`:1042`); only its fill changes. The double-tap guard is
        // `if (submitCase.pending) return;` inside `handleNext` (`:553`), i.e.
        // in the cubit. A port that disabled this button has diverged.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // `backgroundColor: pending ? "#C7D2FE" : "#344EAD"` — `:1041`.
              // `backgroundColor: pending ? "#C7D2FE" : "#344EAD"` — `:1041`.
              color: pending ? AppColors.ctaPendingFill : AppColors.primary,
              borderRadius: kFieldRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (pending) ...<Widget>[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'resident.processingPayment'.tr(context: context),
                    style: _label,
                  ),
                ] else ...<Widget>[
                  Flexible(
                    child: Text(
                      isLastStep
                          // `t("pay", { amount: formatLak(fee, lang) })` —
                          // `:1052`.
                          ? 'resident.pay'.tr(
                              context: context,
                              namedArgs: <String, String>{
                                'amount': formatLak(amount, lang.name),
                              },
                            )
                          : 'resident.continue'.tr(context: context),
                      overflow: TextOverflow.ellipsis,
                      style: _label,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const LucideIcon(
                    name: 'ArrowRight',
                    size: 16,
                    color: AppColors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}

/// `:600-607`, `:657-663` — the full-width brand-blue button.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: kFieldRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  LucideIcon(name: icon!, size: 16, color: AppColors.white),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
