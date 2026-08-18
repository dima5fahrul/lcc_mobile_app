/// `BirthDeclarationPage.tsx:594-644` and `:902-1608` — the page shell.
///
/// Four top-level renderings, in the source's own order of precedence:
/// **service loading** (`:903`), **service error** (`:912`), **success**
/// (`:936`), and the wizard (`:1011`).
///
/// ## Step 6 is Review, and there is no payment step
///
/// `STEP_META`'s sixth entry is `stepReview`. This file imports nothing from
/// `lib/presentation/payment/` and mounts no `PaymentSection` (`F2-AC-51`).
/// The **only** payment affordance is the success screen's pay button, and it
/// fires a mutation separate from `submitCase` (`F2-AC-49`).
///
/// ## The CTA is never disabled
///
/// `:1578-1602` has no `disabled` attribute. A second tap while a submission is
/// in flight is ignored **in the handler** (`:864`), the background becomes
/// `#C7D2FE`, and the label becomes a spinner plus `t("submitting")`. A port
/// that disables the button has diverged (`fsd.md`:348, `F2-AC-66`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../presentation/forms/validation/scroll_to_first_error.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import 'birth_fields.dart';
import 'birth_form_cubit.dart';
import 'birth_form_state.dart';
import 'birth_steps.dart';

class BirthDeclarationPage extends StatefulWidget {
  const BirthDeclarationPage({
    super.key,
    required this.cubit,
    required this.onBack,
  });

  final BirthFormCubit cubit;

  /// `onBack` — `:648`. Called when the citizen leaves step 1 backwards, and by
  /// the success screen's back-to-home button.
  final VoidCallback onBack;

  @override
  State<BirthDeclarationPage> createState() => _BirthDeclarationPageState();
}

class _BirthDeclarationPageState extends State<BirthDeclarationPage> {
  final ScrollController _scroll = ScrollController();
  int _lastScrollTick = 0;

  @override
  void initState() {
    super.initState();
    widget.cubit.load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BirthFormCubit, BirthFormViewState>(
      bloc: widget.cubit,
      // `scrollToFirstError()` is a side effect of two transitions (`:868`,
      // `:888`), not a rendered thing. The cubit bumps a counter and the page
      // performs it, so nothing in the cubit reaches for a `BuildContext`.
      listenWhen: (BirthFormViewState a, BirthFormViewState b) =>
          a.scrollToErrorTick != b.scrollToErrorTick,
      listener: (BuildContext context, BirthFormViewState state) {
        if (state.scrollToErrorTick == _lastScrollTick) return;
        _lastScrollTick = state.scrollToErrorTick;
        scrollToFirstError(context);
      },
      builder: (BuildContext context, BirthFormViewState state) {
        if (state.showsServiceLoading) {
          return _ServiceLoading(
            label: birthTxtOf(context, BirthTxt.loading),
          );
        }
        if (state.showsServiceError) {
          return _ServiceError(
            message: birthTxtOf(context, BirthTxt.loadFailed),
            detail: state.service.error ?? '',
            retryLabel: birthTxtOf(context, BirthTxt.retry),
            backLabel: birthT(context, 'backToHome'),
            onRetry: widget.cubit.refetchService,
            onBack: widget.onBack,
          );
        }
        if (state.submitted != null) {
          return BirthSuccessScreen(
            cubit: widget.cubit,
            state: state,
            onBack: widget.onBack,
          );
        }

        return ValidationScope(
          showErrors: state.showErrors,
          serverErrors: state.serverErrors,
          onClearServerError: widget.cubit.clearServerError,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  _SubHeader(
                    title: birthT(context, 'headerTitle'),
                    subtitle: birthT(context, 'headerSubtitle'),
                    onBack: () {
                      if (widget.cubit.goBack()) widget.onBack();
                    },
                  ),
                  BirthStepIndicator(step: state.step),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          BirthStepHeader(step: state.step),
                          // `:1046-1051` — the red panel above the step body.
                          // A non-validation error renders here and clears
                          // NOTHING (`F2-AC-64`).
                          if (state.submitError != null)
                            BirthNotice(
                              text: state.submitError!,
                              icon: 'circle-alert',
                            ),
                          _body(state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BirthCta(
              pending: state.submitPending,
              label: state.isLastStep
                  ? birthT(context, 'submitDeclaration')
                  : birthT(context, 'continue'),
              pendingLabel: birthT(context, 'submitting'),
              onTap: widget.cubit.next,
            ),
          ),
        );
      },
    );
  }

  Widget _body(BirthFormViewState state) {
    switch (state.step) {
      case 1:
        return BirthStep1(cubit: widget.cubit, state: state);
      case 2:
        return BirthStep2(cubit: widget.cubit, state: state);
      case 3:
        return BirthStep3(cubit: widget.cubit, state: state);
      case 4:
        return BirthStep4(cubit: widget.cubit, state: state);
      case 5:
        return BirthStep5(cubit: widget.cubit, state: state);
      default:
        return BirthStep6(cubit: widget.cubit, state: state);
    }
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const LucideIcon(name: 'chevron-left', size: 20),
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
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

/// `:595-630` — the step indicator.
class BirthStepIndicator extends StatelessWidget {
  const BirthStepIndicator({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < kBirthStepMeta.length; i++) ...<Widget>[
              _Dot(
                id: kBirthStepMeta[i].id,
                done: step > kBirthStepMeta[i].id,
                active: step == kBirthStepMeta[i].id,
              ),
              if (i != kBirthStepMeta.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: step > kBirthStepMeta[i].id
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.gray200,
                  ),
                ),
            ],
          ],
        ),
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.id, required this.done, required this.active});
  final int id;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: done ? 0.55 : 1,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done || active
                ? AppColors.primary
                : AppColors.gray100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: done
              ? const LucideIcon(name: 'check', size: 14)
              : Text(
                  '$id',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: active ? AppColors.white : AppColors.gray400Inline,
                  ),
                ),
        ),
      );
}

/// `:632-644` — `StepHeader`.
///
/// Reads `STEP_META`'s per-step `titleKey`/`subtitleKey`. Death has no such
/// table and interpolates `` t(`step${step}Title`) `` instead (`F2-AC-58`).
class BirthStepHeader extends StatelessWidget {
  const BirthStepHeader({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final BirthStepMeta meta =
        kBirthStepMeta.firstWhere((BirthStepMeta m) => m.id == step);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'birth.stepOf'
                .replaceAll('birth.stepOf', birthT(context, 'stepOf'))
                .replaceAll('{n}', '$step')
                .replaceAll('{m}', '$kBirthStepCount'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            birthT(context, meta.titleKey),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            birthT(context, meta.subtitleKey),
            style: const TextStyle(fontSize: 12, color: AppColors.gray400Inline),
          ),
        ],
      ),
    );
  }
}

/// `:1576-1604` — the fixed bottom CTA.
///
/// **Never disabled.** `onTap` is always wired; the re-entry guard is the
/// cubit's `if (state.submitPending) return`. The background is `#C7D2FE`
/// while pending and `#344EAD` otherwise (`F2-AC-66`, `F2-AC-77`).
class BirthCta extends StatelessWidget {
  const BirthCta({
    super.key,
    required this.pending,
    required this.label,
    required this.pendingLabel,
    required this.onTap,
  });

  final bool pending;
  final String label;
  final String pendingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: pending ? AppColors.infoBorder : AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
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
                    pendingLabel,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...<Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const LucideIcon(name: 'arrow-right', size: 16),
                ],
              ],
            ),
          ),
        ),
      );
}

/// `:936-1007` — the success screen.
///
/// **Six rows, seven with the receipt** (`:959`). `unpaid` gates whether the pay
/// button renders; when it flips false the back-to-home button changes from
/// outlined to filled in the same transition. `payError` renders as a small red
/// line above the button and clears nothing (`F2-AC-52`).
class BirthSuccessScreen extends StatelessWidget {
  const BirthSuccessScreen({
    super.key,
    required this.cubit,
    required this.state,
    required this.onBack,
  });

  final BirthFormCubit cubit;
  final BirthFormViewState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bool unpaid = state.unpaid;
    final String empty = birthT(context, 'emptyValue');
    final List<(String, String)> rows = <(String, String)>[
      (
        birthT(context, 'successChild'),
        state.form.child.fullName.isEmpty ? empty : state.form.child.fullName
      ),
      (birthT(context, 'documentNo'), state.submitted!.row.referenceNo),
      (
        birthT(context, 'successInformant'),
        state.form.informant.fullName.isEmpty
            ? empty
            : state.form.informant.fullName
      ),
      (birthT(context, 'fee'), '${state.submitted!.row.feeLak}'),
      // `:959` — the SEVENTH row, conditional on a receipt existing.
      if (state.receiptNo != null)
        (birthTxtOf(context, BirthTxt.receipt), state.receiptNo!),
      (birthT(context, 'successEstReview'), birthT(context, 'successEstReviewValue')),
      (birthT(context, 'successStatus'), birthT(context, 'successStatusValue')),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              // `:941-946` — the gradient badge. Both stops are Tier 2
              // comparison targets (`F2-AC-77`).
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.primary, AppColors.brandGradientEnd],
                  ),
                ),
                child: const LucideIcon(name: 'check', size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                birthT(context, 'successTitle'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                birthT(context, 'successText'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
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
                    for (final (String, String) row in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              row.$1,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.muted,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                row.$2,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // `:979-981` — a pay failure is a small red line, above the
              // button. It does not clear `submitted`, does not navigate, and
              // does not disable anything.
              if (state.payError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.payError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.dangerStrong,
                    ),
                  ),
                ),
              // `:983-992` — the pay button RENDERS only while unpaid.
              if (unpaid)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GestureDetector(
                    onTap: cubit.payNow,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (state.payPending) ...<Widget>[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            birthFill(
                              birthTxtOf(context, BirthTxt.payNow),
                              <String, String>{
                                'amount': '${state.submitted!.row.feeLak}',
                              },
                            ),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // `:994-1000` — outlined while unpaid, filled once paid.
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GestureDetector(
                  onTap: onBack,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: unpaid ? AppColors.white : AppColors.primary,
                      border: unpaid
                          ? Border.all(color: AppColors.gray200)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      birthT(context, 'backToHome'),
                      style: TextStyle(
                        color:
                            unpaid ? AppColors.buttonGhostInk : AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                birthT(context, 'trackHint'),
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

class _ServiceLoading extends StatelessWidget {
  const _ServiceLoading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray400Inline,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ServiceError extends StatelessWidget {
  const _ServiceError({
    required this.message,
    required this.detail,
    required this.retryLabel,
    required this.backLabel,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final String detail;
  final String retryLabel;
  final String backLabel;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const LucideIcon(name: 'circle-alert', size: 40),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 14)),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400Inline,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      retryLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onBack,
                  child: Text(
                    backLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
