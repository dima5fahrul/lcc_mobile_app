/// `DeathDeclarationPage.tsx:623-671` and `:926-1550` — the page shell.
///
/// Four top-level renderings, in the source's order: **service loading**
/// (`:927`), **service error** (`:936`), **success** (`:960`), the wizard
/// (`:1033`).
///
/// ## The step header interpolates; Birth's reads a table
///
/// [DeathStepHeader] resolves `` t(`step${step}Title`) `` (`:667-668`).
/// Birth's `StepHeader` looks the key up in `STEP_META`. `F2-AC-58` forbids
/// normalising either onto the other, so this file keeps the interpolation and
/// `death_form_state.dart` keeps [deathStepTitleKey] rather than a table.
///
/// ## The CTA is never disabled
///
/// `:1520-1544` — no `disabled`. The re-entry guard is the cubit's, the
/// background becomes `#C7D2FE` while pending (`F2-AC-66`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../presentation/forms/validation/scroll_to_first_error.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import 'death_fields.dart';
import 'death_form_cubit.dart';
import 'death_form_state.dart';
import 'death_steps.dart';

class DeathDeclarationPage extends StatefulWidget {
  const DeathDeclarationPage({
    super.key,
    required this.cubit,
    required this.onBack,
  });

  final DeathFormCubit cubit;
  final VoidCallback onBack;

  @override
  State<DeathDeclarationPage> createState() => _DeathDeclarationPageState();
}

class _DeathDeclarationPageState extends State<DeathDeclarationPage> {
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
    return BlocConsumer<DeathFormCubit, DeathFormViewState>(
      bloc: widget.cubit,
      listenWhen: (DeathFormViewState a, DeathFormViewState b) =>
          a.scrollToErrorTick != b.scrollToErrorTick,
      listener: (BuildContext context, DeathFormViewState state) {
        if (state.scrollToErrorTick == _lastScrollTick) return;
        _lastScrollTick = state.scrollToErrorTick;
        scrollToFirstError(context);
      },
      builder: (BuildContext context, DeathFormViewState state) {
        if (state.showsServiceLoading) {
          return _ServiceLoading(
            label: deathTxtOf(context, DeathTxt.loading),
          );
        }
        if (state.showsServiceError) {
          return _ServiceError(
            message: deathTxtOf(context, DeathTxt.loadFailed),
            detail: state.service.error ?? '',
            retryLabel: deathTxtOf(context, DeathTxt.retry),
            backLabel: deathT(context, 'backToHome'),
            onRetry: widget.cubit.refetchService,
            onBack: widget.onBack,
          );
        }
        if (state.submitted != null) {
          return DeathSuccessScreen(
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
                    // `title` / `subtitle` — Birth's are `headerTitle` /
                    // `headerSubtitle` (measured difference #25).
                    title: deathT(context, 'title'),
                    subtitle: deathT(context, 'subtitle'),
                    onBack: () {
                      if (widget.cubit.goBack()) widget.onBack();
                    },
                  ),
                  DeathStepIndicator(step: state.step),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          DeathStepHeader(step: state.step),
                          // `:1068-1073` — a non-validation error renders here
                          // and clears nothing (`F2-AC-64`).
                          if (state.submitError != null)
                            DeathNotice(
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
            bottomNavigationBar: DeathCta(
              pending: state.submitPending,
              label: state.isLastStep
                  ? deathT(context, 'submitDeclaration')
                  : deathT(context, 'continue'),
              pendingLabel: deathT(context, 'submitting'),
              onTap: widget.cubit.next,
            ),
          ),
        );
      },
    );
  }

  Widget _body(DeathFormViewState state) {
    switch (state.step) {
      case 1:
        return DeathStep1(cubit: widget.cubit, state: state);
      case 2:
        return DeathStep2(cubit: widget.cubit, state: state);
      case 3:
        return DeathStep3(cubit: widget.cubit, state: state);
      case 4:
        return DeathStep4(cubit: widget.cubit, state: state);
      case 5:
        return DeathStep5(cubit: widget.cubit, state: state);
      default:
        return DeathStep6(cubit: widget.cubit, state: state);
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

/// `:624-659` — the step indicator, over [kDeathSteps]'s bare ids.
class DeathStepIndicator extends StatelessWidget {
  const DeathStepIndicator({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < kDeathSteps.length; i++) ...<Widget>[
              _Dot(
                id: kDeathSteps[i],
                done: step > kDeathSteps[i],
                active: step == kDeathSteps[i],
              ),
              if (i != kDeathSteps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: step > kDeathSteps[i]
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

/// `:661-671` — `StepHeader`, resolving its keys by **interpolation**.
class DeathStepHeader extends StatelessWidget {
  const DeathStepHeader({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              deathT(context, 'stepOf')
                  .replaceAll('{n}', '$step')
                  .replaceAll('{m}', '${kDeathSteps.length}'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              deathT(context, deathStepTitleKey(step)),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              deathT(context, deathStepSubtitleKey(step)),
              style: const TextStyle(fontSize: 12, color: AppColors.gray400Inline),
            ),
          ],
        ),
      );
}

/// `:1518-1546` — the fixed bottom CTA. Never disabled.
class DeathCta extends StatelessWidget {
  const DeathCta({
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
              color:
                  pending ? AppColors.infoBorder : AppColors.primary,
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

/// `:960-1029` — the success screen.
///
/// Six rows, **seven** with the receipt (`:983`). Its keys are `sumDeceased` /
/// `sumDocumentNo` / `sumInformant` / `sumFee` / `sumEstReview` / `sumStatus`
/// and `dash` — entirely different names from Birth's `successChild` /
/// `documentNo` / `successInformant` / `fee` / `successEstReview` /
/// `successStatus` / `emptyValue` (measured difference #19).
class DeathSuccessScreen extends StatelessWidget {
  const DeathSuccessScreen({
    super.key,
    required this.cubit,
    required this.state,
    required this.onBack,
  });

  final DeathFormCubit cubit;
  final DeathFormViewState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bool unpaid = state.unpaid;
    final String dash = deathT(context, 'dash');
    final List<(String, String)> rows = <(String, String)>[
      (
        deathT(context, 'sumDeceased'),
        state.form.deceased.fullName.isEmpty
            ? dash
            : state.form.deceased.fullName
      ),
      (deathT(context, 'sumDocumentNo'), state.submitted!.row.referenceNo),
      (
        deathT(context, 'sumInformant'),
        state.form.informant.fullName.isEmpty
            ? dash
            : state.form.informant.fullName
      ),
      (deathT(context, 'sumFee'), '${state.submitted!.row.feeLak}'),
      if (state.receiptNo != null)
        (deathTxtOf(context, DeathTxt.receipt), state.receiptNo!),
      (deathT(context, 'sumEstReview'), deathT(context, 'sumEstReviewValue')),
      (deathT(context, 'sumStatus'), deathT(context, 'sumStatusValue')),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
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
                deathT(context, 'successTitle'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                deathT(context, 'successText'),
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
              // `:1003` — a small red line, clearing nothing.
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
                            deathFill(
                              deathTxtOf(context, DeathTxt.payNow),
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
                      deathT(context, 'backToHome'),
                      style: TextStyle(
                        color: unpaid ? AppColors.buttonGhostInk : AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                deathT(context, 'trackHint'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
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
