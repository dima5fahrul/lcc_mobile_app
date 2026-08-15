/// The top-up sheet — `WalletPage.tsx:714-892`, the `TopUpDialog` component.
///
/// **This sheet builds a request that moves real money.** specs.md § 4.4
/// forbids executing `POST /me/wallet/topup` against any host, absolutely; the
/// surface is built and proven against a mock transport only.
///
/// ## A bottom sheet, not a dialog (§ 6.7, `B6-AC-51`)
///
/// ```
/// overlay: "fixed inset-0 … flex items-end sm:items-center … p-0 sm:p-6"
/// dialog:  "bg-white w-full sm:max-w-md rounded-t-3xl sm:rounded-3xl
///           max-h-[90vh] overflow-auto"                       — :753-754
/// ```
///
/// Tailwind's `sm:` breakpoint is 640 px and the fidelity baseline is captured
/// at **390 px** (`manifest.md`), so the `sm:` branch is unreachable at every
/// width this port is measured against: full width, bottom-anchored, top-only
/// 24 px radius, capped at 90 % of the viewport, scrollable body, sticky
/// header. `sm:max-w-md` (this sheet) vs `sm:max-w-lg` (B6b's pay sheet) is a
/// desktop-only difference and is deliberately **not** encoded — it would be an
/// untested branch.
///
/// Barrier tap, Escape and the header's close control all dismiss;
/// `showModalBottomSheet`'s defaults give the first two.
///
/// ## The amount transform is the batch's sharpest defect surface
///
/// `Number(amount.replace(/[^\d]/g, "")) || 0` — `:735`. Three transforms, and
/// a `int.tryParse` port gets `"12a3"` wrong (`null` where the web says `123`).
/// [parseTopUpAmount] is the port and `B6-AC-34` gates it. The field's own
/// `onChange` **also** strips non-digits (`:777`), so both halves are here.
///
/// ## The guard runs before the request is built (`B6-AC-35`, security item 9)
///
/// `canSubmit = !tooSmall && !tooBig && Boolean(methodCode) && !topUp.pending`
/// (`:740`). All four conditions are evaluated in [_canSubmit] and
/// [_submit] returns early on a false — the event that reaches the BLoC always
/// carries an `int` inside `[min, max]` and a non-empty method code. No value
/// reaches the body unparsed.
///
/// ## `m.code !== "wallet"` (`B6-AC-53`)
///
/// The wallet cannot top itself up (`:728`). Live `PaymentSection` filters on
/// `m.enabled` alone and therefore keeps it — 6 rows here, 7 there, from the
/// same recorded catalogue. `WalletState.topUpOptions` is the filter.
///
/// ## `${m.color}1A` is a **runtime** colour (`B6-AC-41`)
///
/// `backgroundColor: ${m.color || "#344EAD"}1A` (`:844`) — a 10 %-alpha wash
/// computed from an API-supplied hex, with `#344EAD` as the empty fallback. It
/// must not be a token: two different API colours must produce two different
/// washes, which a hardcoded constant would pass a one-colour test against.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/usecases/wallet_usecases.dart';
import '../../domain/wallet_formatting.dart';
import '../bloc/wallet_bloc.dart';
import 'wallet_panels.dart';

/// Opens the sheet over the wallet page.
///
/// [bloc] is passed explicitly rather than read from [context] because
/// `showModalBottomSheet` builds in the **root navigator's** context, which is
/// outside the route's `BlocProvider`. `BlocProvider.value` re-exposes the same
/// instance — `.value`, never `create:`, so closing the sheet does not close a
/// BLoC the page still owns.
Future<void> showWalletTopUpSheet(
  BuildContext context, {
  required WalletBloc bloc,
  required int min,
  required int max,
}) {
  bloc.add(const WalletTopUpSheetOpened());

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    // `rounded-t-3xl` — 24 px, **top only**.
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (BuildContext sheetContext) => BlocProvider<WalletBloc>.value(
      value: bloc,
      child: WalletTopUpSheet(min: min, max: max),
    ),
  ).whenComplete(() => bloc.add(const WalletTopUpSheetClosed()));
}

class WalletTopUpSheet extends StatefulWidget {
  const WalletTopUpSheet({super.key, required this.min, required this.max});

  /// `overview?.min_top_up_lak ?? 10000` — `:556`. Defaulted at the **call
  /// site** (specs.md § 5.2 ruling 3), so the page resolves it, not the model.
  final int min;

  /// `overview?.max_top_up_lak ?? 50000000` — `:557`.
  final int max;

  @override
  State<WalletTopUpSheet> createState() => _WalletTopUpSheetState();
}

class _WalletTopUpSheetState extends State<WalletTopUpSheet> {
  /// `useState<string>(String(min))` — `:737`. A **string**, because the field
  /// is a text input and the parse is what makes it a number.
  late final TextEditingController _amount = TextEditingController(
    text: widget.min.toString(),
  );

  /// `const [picked, setPicked] = useState("")` — `:738`. Empty until the
  /// citizen taps a row; `methodCode` falls through to `options[0]`.
  String _picked = '';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _value => parseTopUpAmount(_amount.text);

  String _methodCode(List<PaymentMethod> options) {
    if (_picked.isNotEmpty) return _picked;
    // `picked || options[0]?.code || ""` — `:739`. **Never a literal code**:
    // whatever the API sorts first wins.
    return options.isEmpty ? '' : options.first.code;
  }

  bool _canSubmit(List<PaymentMethod> options, bool pending) {
    final int v = _value;
    return v >= widget.min &&
        v <= widget.max &&
        _methodCode(options).isNotEmpty &&
        !pending;
  }

  void _submit(List<PaymentMethod> options, bool pending) {
    if (!_canSubmit(options, pending)) return;
    context.read<WalletBloc>().add(
      WalletTopUpSubmitted(amountLak: _value, methodCode: _methodCode(options)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final Lang lang = Lang.fromCode(language);

    return BlocConsumer<WalletBloc, WalletState>(
      listenWhen: (WalletState p, WalletState c) =>
          p.topUpSucceeded != c.topUpSucceeded && c.topUpSucceeded,
      // `onDone` — `:559-562`: close the sheet, then `refreshMoney()`. The
      // refresh is the BLoC's; closing is the sheet's.
      listener: (BuildContext context, WalletState state) =>
          Navigator.of(context).pop(),
      builder: (BuildContext context, WalletState state) {
        final List<PaymentMethod> options = state.topUpOptions;
        final String methodCode = _methodCode(options);
        final int value = _value;
        final bool outOfRange = value < widget.min || value > widget.max;

        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _stickyHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _amountField(language),
                      const SizedBox(height: 20),
                      _methodSection(state, options, methodCode, lang),
                      // `{(tooSmall || tooBig) && value > 0 && …}` — `:865`.
                      // **`value > 0`**: an empty field is not an error, it is
                      // an unfinished one.
                      if (outOfRange && value > 0) ...<Widget>[
                        const SizedBox(height: 20),
                        Text(
                          'wallet.amountOutOfRange'.tr(
                            context: context,
                            namedArgs: <String, String>{
                              'min': formatKip(widget.min, language),
                              'max': formatKip(widget.max, language),
                            },
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                      if (state.topUpError != null) ...<Widget>[
                        const SizedBox(height: 20),
                        Text(
                          state.topUpError!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _cta(options, state.topUpPending, language),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// `:756-769` — title left, 32×32 grey close button right, sticky.
  Widget _stickyHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'wallet.topUp'.tr(context: context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
          ),
          Semantics(
            button: true,
            // `aria-label={tc("close")}` — `:761`.
            label: 'common.close'.tr(context: context),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const LucideIcon(
                  name: 'X',
                  size: 16,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountField(String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'payment.amount'.tr(context: context).toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _amount,
          // `inputMode="numeric"` — `:775`.
          keyboardType: TextInputType.number,
          // `onChange={e => setAmount(e.target.value.replace(/[^\d]/g, ""))}`
          // — `:777`. The field strips as you type; `parseTopUpAmount` strips
          // again at submit. Both are the source's, and the second is what
          // makes a paste of `"50,000"` land on `50000`.
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (String _) => setState(() {}),
          style: const TextStyle(fontSize: 14, color: AppColors.gray800),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: AppColors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                // `focus:ring-2 focus:ring-[#344EAD]/30` — `:778`.
                color: AppColors.primary.withValues(alpha: 0.30),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // `{formatKip(min, lang)} – {formatKip(max, lang)}` — `:781`. The
          // separator is U+2013 EN DASH, as the source writes it.
          '${formatKip(widget.min, language)} – ${formatKip(widget.max, language)}',
          style: const TextStyle(fontSize: 12, color: AppColors.gray400Inline),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            // `[50000,100000,200000,500000].filter(v => v >= min && v <= max)`
            // — `:784-786` (`B6-AC-52`).
            for (final int v in kTopUpPresets)
              if (v >= widget.min && v <= widget.max)
                _PresetChip(
                  label: formatKip(v, language),
                  // `value === v` — equality against the **parsed integer**,
                  // not against the raw text (`:790`).
                  active: _value == v,
                  onTap: () => setState(() => _amount.text = v.toString()),
                ),
          ],
        ),
      ],
    );
  }

  Widget _methodSection(
    WalletState state,
    List<PaymentMethod> options,
    String methodCode,
    Lang lang,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          // `lang === "lo" ? "ຊ່ອງທາງຕື່ມເງິນ" : "Top-up method"` — `:805`,
          // relocated into the namespace by § 6.13(3).
          'wallet.topUpMethodLabel'.tr(context: context).toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 6),
        if (state.methodsLoading)
          Column(
            children: <Widget>[
              for (int i = 0; i < 2; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          )
        else if (state.methodsError != null)
          WalletRetryCard(
            message: state.methodsError!,
            boxed: false,
            onRetry: () => context.read<WalletBloc>().add(
              const WalletPaymentMethodsRetried(),
            ),
          )
        else if (options.isEmpty)
          Text(
            'wallet.noTopUpMethod'.tr(context: context),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray400Inline,
            ),
          )
        else
          Column(
            children: <Widget>[
              for (int i = 0; i < options.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: _MethodRow(
                    method: options[i],
                    active: options[i].code == methodCode,
                    lang: lang,
                    onTap: () => setState(() => _picked = options[i].code),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cta(List<PaymentMethod> options, bool pending, String language) {
    final bool enabled = _canSubmit(options, pending);
    return Opacity(
      // `disabled:opacity-60` — `:883`.
      opacity: enabled ? 1.0 : 0.6,
      child: InkWell(
        onTap: enabled ? () => _submit(options, pending) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            pending
                ? 'wallet.processing'.tr(context: context)
                // `${t("topUp")} · ${formatKip(value, lang)}` — `:888`.
                : '${'wallet.topUp'.tr(context: context)} · ${formatKip(_value, language)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// `:787-800` — a rounded pill, blue when the parsed amount equals it.
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.white,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.gray200,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

/// `:830-858` — one selectable method row.
class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.method,
    required this.active,
    required this.lang,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool active;
  final Lang lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `m.color || "#344EAD"` — `AppColors.parseHex`'s default fallback **is**
    // `primary` (`#344EAD`), so the empty case is handled by the parser rather
    // than by a second literal here.
    final Color accent = AppColors.parseHex(method.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? AppColors.primary : AppColors.gray200,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // `${m.color || "#344EAD"}1A` — a **runtime** 10 %-alpha wash
                // computed from the API hex (`B6-AC-41`). `0x1A / 0xFF` is
                // 0.10196…; `withValues(alpha:)` takes the ratio, and rounding
                // it to `0.1` would land on `0x19`. Written as the exact ratio.
                color: accent.withValues(alpha: 0x1A / 0xFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: LucideIcon(name: 'CreditCard', size: 16, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text(method.label, lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray800,
                    ),
                  ),
                  Text(
                    // **Raw, untranslated** — `:850`. `B6-DIV-2`: the API sends
                    // English only and the source renders it with no
                    // `text(…, lang)`, two lines from an instruction note that
                    // *is* translated. Ported as measured; FU-7 files it
                    // against the API, where the fix belongs.
                    method.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.gray300,
                  width: 2,
                ),
              ),
              child: active
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
