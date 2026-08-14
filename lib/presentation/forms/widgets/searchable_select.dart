/// `formFields.tsx:104-226` — the select2-style dropdown with type-to-search.
///
/// **This is the widget RULING 2 turns on.** It is already fully
/// parameter-driven in the source — it takes `options`, `loading`, `failed`,
/// `onRetry`, `emptyMessage` and nothing else — and Marriage's and Divorce's
/// weaker error surface is produced by **omitting** three of those, not by a
/// fork:
///
/// ```tsx
/// {failed && onRetry ? <LoadFailure onRetry={onRetry} /> : <FieldError show={hasError} message={message} />}
/// ```
/// (`formFields.tsx:223`)
///
/// The kernel's `LocationFields` passes them (`:493-494`, `:507-508`,
/// `:520-521`); Marriage's page-local `ApiLocationFields` does not
/// (`:314-359`). **The divergence is entirely in the caller.** One kernel, zero
/// variants, no `weakSurface` boolean — a boolean gets § 6.3.4's fourth row
/// wrong in both directions, because Marriage's location selects show
/// `NOTHING_YET` inside the dropdown *and* no failure row
/// (`F0-AC-26`, `F0-AC-27`).
///
/// ## Three behaviours that look incidental and are not
///
/// 1. **`.slice(0, 100)` after filtering** (`:145`), and a "refine your search"
///    hint when exactly 100 survive (`:216`). A port that renders every match
///    silently loses the hint.
/// 2. **The query resets on open, not on close** (`:157` `setQuery("")` inside
///    the toggle). Reopening a select shows the whole list again.
/// 3. **`o.sub && o.sub !== o.label`** (`:207`) — the secondary line is hidden
///    when it repeats the primary, which is what happens for a place whose Lao
///    and English names are the same string.
///
/// ## Nothing here fetches
///
/// No locator, no repository, no `Future`. Every state the widget can be in is
/// a parameter, which is what lets `F0-AC-77` pump it with the DI container
/// completely uninitialised.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../icons/lucide_icon.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../validation/field_error.dart';
import '../validation/validation_scope.dart';
import 'field_base.dart';
import 'field_label.dart';
import 'field_sentences.dart';
import 'load_failure.dart';
import 'option.dart';

/// `formFields.tsx:145` — the cap, and the trigger for the "refine" hint.
const int kSearchableSelectLimit = 100;

/// `max-h-60` — the scrollable row area.
const double kDropdownMaxHeight = 240;

class SearchableSelect extends StatefulWidget {
  const SearchableSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.disabled = false,
    this.loading = false,
    this.path,
    this.failed,
    this.onRetry,
    this.emptyMessage,
  });

  final Widget label;
  final String value;
  final List<Option> options;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;
  final bool disabled;
  final bool loading;

  /// `form_data` key, so a server-side error can land on this field.
  final String? path;

  /// **Nullable, deliberately.** The list behind this select could not be
  /// loaded — or the caller does not model that state at all, which is
  /// Marriage's and Divorce's case.
  final bool? failed;

  /// **Nullable, deliberately.** `:223` requires *both* this and [failed] to
  /// render the failure row.
  final VoidCallback? onRetry;

  /// **Nullable, deliberately.** Shown inside the dropdown when the list loaded
  /// but came back empty; null falls through to `NOTHING_YET`, which is why
  /// Marriage's selects still show it.
  final String? emptyMessage;

  @override
  State<SearchableSelect> createState() => _SearchableSelectState();
}

class _SearchableSelectState extends State<SearchableSelect> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _query = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _query.dispose();
    super.dispose();
  }

  void _toggle() {
    // `:157` — `if (!disabled) { setQuery(""); setOpen((o) => !o); }`
    if (widget.disabled) return;
    setState(() {
      _query.clear();
      _open = !_open;
    });
    if (_open) {
      _portal.show();
    } else {
      _portal.hide();
    }
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _portal.hide();
  }

  /// `:141-145` — trim, lowercase, match against `"${label} ${sub}"`, cap at
  /// 100. Reproduced including the space between the two fields, which affects
  /// a query that spans them.
  List<Option> get _filtered {
    final String q = _query.text.trim().toLowerCase();
    final Iterable<Option> matched = q.isEmpty
        ? widget.options
        : widget.options.where(
            (Option o) =>
                '${o.label} ${o.sub ?? ''}'.toLowerCase().contains(q),
          );
    return matched.take(kSearchableSelectLimit).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final FieldErrorState error = ValidationScope.fieldErrorOf(
      context,
      path: widget.path,
      required: widget.required,
      value: widget.value,
      disabled: widget.disabled,
    );
    // `:148` — `const outlined = hasError || Boolean(failed);`
    final bool outlined = error.hasError || (widget.failed ?? false);

    final Option? selected = widget.options
        .where((Option o) => o.value == widget.value)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FieldLabel(label: widget.label, required: widget.required),
        CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _portal,
            overlayChildBuilder: _buildDropdown,
            child: _buildButton(selected, outlined),
          ),
        ),
        // `:223` — the whole of RULING 2, in one line.
        if ((widget.failed ?? false) && widget.onRetry != null)
          LoadFailure(onRetry: widget.onRetry!, focusNode: _focusNode)
        else
          FieldErrorText(
            show: error.hasError,
            message: error.message,
            focusNode: _focusNode,
          ),
      ],
    );
  }

  Widget _buildButton(Option? selected, bool outlined) {
    return Semantics(
      button: true,
      enabled: !widget.disabled,
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Focus(
          focusNode: _focusNode,
          canRequestFocus: !widget.disabled,
          child: Container(
            width: double.infinity,
            padding: kFieldPadding,
            decoration: fieldDecoration(
              hasError: outlined,
              focused: false,
              disabled: widget.disabled,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    selected?.label ?? widget.placeholder,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    // `:164` — `truncate ${selected ? "text-gray-800" : "text-gray-400"}`
                    style: selected != null
                        ? kFieldTextStyle
                        : kFieldPlaceholderStyle,
                  ),
                ),
                const SizedBox(width: AppSpacing.gap8),
                // `:167` — `w-4 h-4 text-gray-400`, rotated when open.
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const LucideIcon(
                    name: 'ChevronDown',
                    size: AppSpacing.gap16,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    // `:170` — `open && !disabled`.
    if (widget.disabled) return const SizedBox.shrink();

    return CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      // `mt-2`
      offset: const Offset(0, AppSpacing.gap8),
      child: Align(
        alignment: Alignment.topLeft,
        child: TapRegion(
          // `:132-139` — the `mousedown` listener that closes on an outside
          // click. `TapRegion` is the same behaviour without a global listener
          // to forget to remove.
          onTapOutside: (_) => _close(),
          child: _DropdownPanel(
            query: _query,
            loading: widget.loading,
            filtered: _filtered,
            value: widget.value,
            emptyMessage: widget.emptyMessage,
            hasQuery: _query.text.trim().isNotEmpty,
            onPicked: (String v) {
              ValidationScope.clearServerErrorOf(context)(widget.path);
              widget.onChanged(v);
              _close();
            },
            onQueryChanged: () => setState(() {}),
          ),
        ),
      ),
    );
  }
}

class _DropdownPanel extends StatelessWidget {
  const _DropdownPanel({
    required this.query,
    required this.loading,
    required this.filtered,
    required this.value,
    required this.emptyMessage,
    required this.hasQuery,
    required this.onPicked,
    required this.onQueryChanged,
  });

  final TextEditingController query;
  final bool loading;
  final List<Option> filtered;
  final String value;
  final String? emptyMessage;
  final bool hasQuery;
  final ValueChanged<String> onPicked;
  final VoidCallback onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: kFieldRadius,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.gray200),
          ),
          boxShadow: <BoxShadow>[
            // `shadow-xl`
            BoxShadow(
              color: AppColors.cardShadowMedium,
              blurRadius: AppSpacing.gap24,
              offset: Offset(0, AppSpacing.gap8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _searchRow(context),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: kDropdownMaxHeight),
              child: _body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap12,
          vertical: AppSpacing.gap8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.gray50,
          borderRadius:
              BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
        ),
        child: Row(
          children: <Widget>[
            const LucideIcon(
              name: 'Search',
              size: AppSpacing.gap16,
              color: AppColors.gray400Inline,
            ),
            const SizedBox(width: AppSpacing.gap8),
            Expanded(
              child: TextField(
                controller: query,
                autofocus: true,
                onChanged: (_) => onQueryChanged(),
                style: kFieldTextStyle,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'fields.search'.tr(context: context),
                  hintStyle: kFieldPlaceholderStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (loading) {
      // `:185-188` — spinner + `fields.loading`.
      //
      // The glyph is Flutter's, not lucide's: `Loader2` is not among the 89
      // bundled icons and `assets/icons/**` is byte-frozen and outside F0b's
      // scope. A spinning indicator of the same size in the same slot; the
      // string, which is what Tier 1 reads, is identical.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              width: AppSpacing.gap16,
              height: AppSpacing.gap16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.gray400Inline),
              ),
            ),
            const SizedBox(width: AppSpacing.gap8),
            Text(
              'fields.loading'.tr(context: context),
              style: kFieldPlaceholderStyle,
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      // `:189-192` — `q ? t("noResults") : emptyMessage ?? text(NOTHING_YET, lang)`.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap24),
        child: Center(
          child: Text(
            hasQuery
                ? 'fields.noResults'.tr(context: context)
                : emptyMessage ?? kNothingYetKey.tr(context: context),
            style: kFieldPlaceholderStyle,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: AppSpacing.gap4),
          for (final Option o in filtered)
            _Row(option: o, active: o.value == value, onTap: () => onPicked(o.value)),
          // `:216-218` — only when the cap was hit exactly.
          if (filtered.length == kSearchableSelectLimit)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap16,
                vertical: AppSpacing.gap8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'fields.refineSearch'.tr(context: context),
                  // `text-[11px] text-gray-400`
                  style: const TextStyle(
                    fontSize: AppTypography.size11,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.gap4),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.option, required this.active, required this.onTap});

  final Option option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          // `px-4 py-2.5`
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap10,
          ),
          // `active ? "bg-[#EEF2FF]" : "hover:bg-gray-50"` — there is no hover
          // on a touch device, so only the active fill is ported.
          color: active ? AppColors.primarySoft : null,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      option.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: kFieldTextStyle,
                    ),
                    // `:207` — hidden when the secondary repeats the primary.
                    if (option.sub != null && option.sub != option.label)
                      Text(
                        option.sub!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: AppTypography.size12,
                          color: AppColors.gray400Inline,
                        ),
                      ),
                  ],
                ),
              ),
              if (active)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.gap8),
                  child: LucideIcon(
                    name: 'Check',
                    size: AppSpacing.gap16,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
