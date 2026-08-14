/// The LaoID card — `Hero.tsx:140-348`'s `LaoIdCard`.
///
/// A 16:9 card over the `bg-id` security pattern: header strip, then one body
/// row of photo | identity | QR, then the nationality line, then (signed out)
/// the "Sign in to activate" hint.
///
/// ## The signed-out card is the one with a baseline
///
/// § 6.5.2(b): `summary` and `digitalId` are `enabled: isAuthenticated`, the
/// 2026-08-13 capture was unauthenticated, so **Tier 3 is NOT EVALUATED for
/// the authenticated render** and the signed-out one is gated normally. Tiers 1
/// and 2 bind both, because they read source rather than screenshots. That is
/// why the two branches below are written from the source line by line rather
/// than "the signed-out one carefully, the other one roughly".
///
/// ## The stock portrait is deliberately never rendered — V-16/V-17
///
/// `Hero.tsx:232` reads
/// `authenticated && (photoUrl || !issuedUin) ? <img src={photoUrl || citizenPhoto}>`,
/// so a signed-in citizen whose record carries **no** UIN and **no** photo gets
/// the bundled stock likeness `user-photo.png`. Two reasons that branch is not
/// ported:
///
/// 1. **B2-AC-42 item 4** requires confirming that *no B2 surface renders
///    `user-photo`* — the likeness finding V-16/V-17 is open and
///    release-blocking on B8. Porting the branch would make that confirmation
///    false.
/// 2. **The source's own comment contradicts its code.** `Hero.tsx:226-231`
///    says, in as many words: *"The stock portrait belongs to the specimen card
///    only. A signed-in citizen whose registry record carries no photo gets
///    their initial instead — someone else's face does not become a
///    placeholder just because it is standing in."* The condition three lines
///    below does not implement that. This ports the comment.
///
/// The result: a photo is shown **only** when the citizen's own record supplies
/// its URL; every other case draws the initial tile. Recorded as a deliberate
/// divergence in the hand-back, not smuggled in as a styling choice.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/digital_id_card.dart';
import '../../domain/home_formatting.dart';
import 'tier_a_image.dart';

/// `SPECIMEN_UIN` — `Hero.tsx:20`.
///
/// The number printed on the signed-out card. It is never shown to a signed-in
/// citizen, who sees the UIN the API issued them; printing the specimen there
/// would put a stranger's number on their own ID.
const String kSpecimenUin = '1-2540-08842-15';

/// The specimen name, per locale — `Hero.tsx:173-176`.
String specimenName(String languageCode) =>
    languageCode == kLao ? 'ບຸນມີ ສີສະຫວັດ' : 'Bounmy Sisavath';

class LaoIdCard extends StatefulWidget {
  const LaoIdCard({
    super.key,
    required this.authenticated,
    this.name = '',
    this.card,
    this.onSignIn,
    this.interactive = true,
  });

  final bool authenticated;

  /// `interactive = true` — `Hero.tsx`:147, added by B10 § 6.9.
  ///
  /// The web's `<LaoIdCard>` gates three things on it, and **only** three:
  ///
  /// | source | gate |
  /// |---|---|
  /// | `:263` | the UIN reveal eye — `authenticated && interactive` |
  /// | `:287` | the QR **button** — `interactive ? <button> : <div aria-hidden>` |
  /// | `:316` | the QR dialog — `interactive && showQr` |
  ///
  /// Note what `:287` does **not** do: the QR tile is still drawn when
  /// `interactive` is false, at the same size, colour and radius. It stops
  /// being a control (no tap, `aria-hidden`) and stays a picture. Removing it
  /// would change the card's layout, which is precisely what splash slide 3
  /// must not do — the whole reason it renders the real card is *"so what the
  /// slide promises is exactly what the user meets after signing in"*
  /// (`SplashScreens.tsx`:155).
  ///
  /// **The default is `true`**, so every pre-B10 call site is byte-identical
  /// in behaviour (`B10-AC-39`). The only caller passing `false` is the splash
  /// slot in `app_routes.dart`.
  final bool interactive;

  /// The citizen's display name, from `/me/home-summary`. Empty while that
  /// request is in flight — `name || "—"` (`Hero.tsx:172`) covers it.
  final String name;

  /// `/me/digital-id`, or null when signed out / still loading.
  final DigitalIdCard? card;

  final VoidCallback? onSignIn;

  @override
  State<LaoIdCard> createState() => _LaoIdCardState();
}

class _LaoIdCardState extends State<LaoIdCard> {
  /// `useState showUin` — `Hero.tsx:169`. Hidden by default, and only ever
  /// togglable when signed in. Widget-local: nothing outside this card can
  /// observe it, and it must reset when the card leaves the tree.
  bool _showUin = false;

  @override
  void didUpdateWidget(LaoIdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Signing out with the UIN revealed must not leave the next render — or
    // the next citizen — looking at a revealed field. The source gets this for
    // free by unmounting; a Flutter element is reused, so it is explicit.
    if (oldWidget.authenticated && !widget.authenticated && _showUin) {
      _showUin = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    final bool authed = widget.authenticated;

    // `authenticated ? name || "—" : <specimen>` — `Hero.tsx:172-176`.
    final String displayName = authed
        ? (widget.name.isEmpty ? '—' : widget.name)
        : specimenName(languageCode);

    // `issuedUin || SPECIMEN_UIN` — `Hero.tsx:182`.
    final String issuedUin = widget.card?.uin ?? '';
    final String uin = issuedUin.isEmpty ? kSpecimenUin : issuedUin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(
          // `aspect-[16/9]` — the proportions of a real card.
          aspectRatio: 16 / 9,
          child: _card(context, languageCode, authed, displayName, uin),
        ),
        if (!authed) ...<Widget>[
          const SizedBox(height: AppSpacing.gap12),
          // `mt-3 w-full text-center text-white/80 text-sm font-medium
          //  underline underline-offset-2`
          TextButton(
            onPressed: widget.onSignIn,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'hero.idSignIn'.tr(),
              style: const TextStyle(
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.medium,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _card(
    BuildContext context,
    String languageCode,
    bool authed,
    String displayName,
    String uin,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // `object-fill`, not cover: the pattern is an ornate border
                // meant to stretch to the card's edges.
                TierAImage(
                  asset: kIdCardBackdrop,
                  paintWidth: constraints.maxWidth,
                  fit: BoxFit.fill,
                ),
                // `bg-white/35` legibility scrim.
                ColoredBox(color: AppColors.white.withValues(alpha: 0.35)),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.gap16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _header(),
                      const SizedBox(height: AppSpacing.gap8),
                      Expanded(
                        child: _body(
                          languageCode,
                          authed,
                          displayName,
                          uin,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// `Hero.tsx:201-221` — brand mark, brand + sub-brand, verified badge.
  Widget _header() {
    return Row(
      children: <Widget>[
        Container(
          width: AppSpacing.gap32,
          height: AppSpacing.gap32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: const Center(
            child: LucideIcon(
              name: 'ShieldCheck',
              size: AppSpacing.gap16,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gap8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'hero.idCardBrand'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.bold,
                  height: AppTypography.lineTight,
                ),
              ),
              Text(
                'hero.idCardSub'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 10,
                  height: AppTypography.lineTight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.gap8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap8,
            vertical: AppSpacing.gap2,
          ),
          decoration: BoxDecoration(
            color: AppColors.verifiedSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: AppColors.verifiedOutline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const LucideIcon(
                name: 'BadgeCheck',
                size: AppSpacing.gap12,
                color: AppColors.verifiedText,
              ),
              const SizedBox(width: AppSpacing.gap4),
              Text(
                'hero.idVerified'.tr(),
                style: const TextStyle(
                  color: AppColors.verifiedText,
                  fontSize: 10,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `Hero.tsx:225-303` — portrait | identity | QR.
  Widget _body(
    String languageCode,
    bool authed,
    String displayName,
    String uin,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _portrait(authed, displayName),
        const SizedBox(width: AppSpacing.gap10),
        Expanded(child: _identity(authed, displayName, uin)),
        const SizedBox(width: AppSpacing.gap10),
        Center(child: _qrButton()),
      ],
    );
  }

  /// `aspect-[3/4]` strip: the citizen's own photo, or their initial.
  ///
  /// See the library doc for why `user-photo` never appears here.
  Widget _portrait(bool authed, String displayName) {
    final String photoUrl = authed ? (widget.card?.photoUrl ?? '') : '';
    // `displayName.trim().charAt(0).toUpperCase()` — `Hero.tsx:183`.
    //
    // `[0]`, not `.characters.first`. JavaScript's `charAt(0)` returns one
    // **UTF-16 code unit**, so for the Lao specimen "ບຸນມີ ສີສະຫວັດ" the web
    // prints the bare consonant "ບ" and not the grapheme cluster "ບຸ" that a
    // Dart `Characters` iterator would give. The cluster is arguably the nicer
    // render; it is also a different string from the one the web draws, and
    // Tier 1 compares text byte-exactly. Caught by the Tier 1 Lao run, which
    // is what that gate is for.
    final String trimmed = displayName.trim();
    final String initial = trimmed.isEmpty ? '' : trimmed[0].toUpperCase();

    final Widget fallback = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: const LinearGradient(
          // `linear-gradient(135deg, …)` — the topLeft → bottomRight diagonal.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.idInitialGradientStart,
            AppColors.primary,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: AppTypography.size24,
            fontWeight: AppTypography.bold,
          ),
        ),
      ),
    );

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: photoUrl.isEmpty
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                // The registry photo is remote and may 404, expire or be
                // blocked. A broken-image glyph on a government ID card is
                // worse than no photo, so the initial tile is the error state
                // as well as the absent one.
                errorBuilder: (_, __, ___) => fallback,
                // No `cacheWidth`: B2-AC-31 and B1b § 6.4 are about *bundled*
                // Tier A assets, whose native size is known at build time. A
                // remote image of unknown dimensions decoded to a guessed
                // width would be a different, unmeasured trade.
                semanticLabel: displayName,
              ),
            ),
    );
  }

  /// `Hero.tsx:248-285` — name, UIN + toggle, nationality.
  Widget _identity(bool authed, String displayName, String uin) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'hero.idName'.tr().toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: 10,
            height: AppTypography.lineTight,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.gap4),
        Text(
          // Signed out, even the specimen name is masked — the card is a
          // specimen, not a demo of somebody's record (`Hero.tsx:253`).
          authed ? displayName : maskValue(displayName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: AppTypography.size14,
            fontWeight: AppTypography.semiBold,
            height: AppTypography.lineTight,
          ),
        ),
        const SizedBox(height: AppSpacing.gap8),
        Row(
          children: <Widget>[
            Text(
              'hero.idUin'.tr().toUpperCase(),
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: AppSpacing.gap6),
            Flexible(
              child: Text(
                // `authenticated && showUin ? uin : maskValue(uin, " -")` —
                // the separators stay so the shape of a UIN is recognisable.
                authed && _showUin ? uin : maskValue(uin, keep: ' -'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.gray700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            // `authenticated && interactive` — `Hero.tsx`:263.
            if (authed && widget.interactive)
              IconButton(
                onPressed: () => setState(() => _showUin = !_showUin),
                tooltip:
                    _showUin ? 'hero.idHide'.tr() : 'hero.idShow'.tr(),
                iconSize: AppSpacing.gap14,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.gap24,
                  minHeight: AppSpacing.gap24,
                ),
                icon: LucideIcon(
                  name: _showUin ? 'EyeOff' : 'Eye',
                  size: AppSpacing.gap14,
                  color: AppColors.gray500,
                  semanticsLabel:
                      _showUin ? 'hero.idHide'.tr() : 'hero.idShow'.tr(),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap8),
        // `<span>NATIONALITY</span> <span class="font-semibold">Lao PDR</span>`
        // — one line, two weights. `Text.rich` because the web presents it as
        // one string and Tier 1 flattens spans with `toPlainText()`.
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: 'hero.idNationality'.tr().toUpperCase(),
                style: const TextStyle(
                  color: AppColors.gray500,
                  letterSpacing: 0.4,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: 'hero.idNationalityValue'.tr(),
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            height: AppTypography.lineTight,
          ),
        ),
      ],
    );
  }

  /// `Hero.tsx:287-302` — the QR tile.
  ///
  /// **Two shapes, one picture.** `:287` is a ternary, not a conditional
  /// render: with `interactive` it is a `<button>` that opens the verification
  /// dialog; without, it is an `aria-hidden` `<div>` with byte-identical
  /// styling. The tile is therefore always drawn — see [LaoIdCard.interactive]
  /// for why removing it would break the one thing splash slide 3 exists to
  /// promise.
  Widget _qrButton() {
    const Widget tile = _QrTile();

    if (!widget.interactive) {
      // `aria-hidden` — a picture, not a control.
      return const ExcludeSemantics(child: tile);
    }

    return Semantics(
      button: true,
      label: 'hero.idTapVerify'.tr(),
      child: InkWell(
        onTap: () => _openVerifyDialog(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: tile,
      ),
    );
  }

  /// `Hero.tsx:316-345`'s `DialogShell`.
  ///
  /// `DialogShell.tsx` itself is **B10's** — § 6.3.4 pulled
  /// `presentation/common/` forward for `GlassIcon` and nothing else — so this
  /// uses Flutter's `showDialog`, which already provides the overlay, the
  /// barrier dismiss, the focus trap and the Escape handling that
  /// `DialogShell` hand-rolls for the web. Same behaviour, framework mechanism,
  /// no widget authored in another batch's directory.
  void _openVerifyDialog(BuildContext context) {
    final String payload = widget.card?.verifyPayload ?? '';

    showDialog<void>(
      context: context,
      // `bg-black/50` — `Hero.tsx:319`.
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.gap24),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  tooltip: 'hero.idVerifyClose'.tr(),
                  icon: LucideIcon(
                    name: 'X',
                    size: AppSpacing.gap16,
                    color: AppColors.gray500,
                    semanticsLabel: 'hero.idVerifyClose'.tr(),
                  ),
                ),
              ),
              Container(
                width: AppSpacing.qrPreview,
                height: AppSpacing.qrPreview,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: const Center(
                  // The source renders a `QrCode` *glyph* at 160 px, not a
                  // generated code — the card's payload is a URL or a code,
                  // printed as text below. Porting the glyph rather than
                  // adding a QR encoder keeps that honest: nothing here claims
                  // to be scannable.
                  child: LucideIcon(
                    name: 'QrCode',
                    size: 160,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gap16),
              Text(
                'hero.idVerifyTitle'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: AppTypography.size16,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              const SizedBox(height: AppSpacing.gap6),
              Text(
                'hero.idVerifyDesc'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: AppTypography.size14,
                  height: AppTypography.lineRelaxed,
                ),
              ),
              if (payload.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.gap12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gap12,
                    vertical: AppSpacing.gap8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Text(
                    payload,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gray700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The QR square itself — `Hero.tsx`:288-302 / `:296-303`, which are the same
/// box drawn twice with different wrappers.
///
/// Extracted so the interactive and non-interactive branches of
/// [_LaoIdCardState._qrButton] cannot drift: the source's own duplication is
/// two literal copies of the same class list, and copying that duplication
/// into Dart would be copying a maintenance hazard rather than a behaviour.
class _QrTile extends StatelessWidget {
  const _QrTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.tile44,
      height: AppSpacing.tile44,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 6),
        ],
      ),
      child: const Center(
        child: LucideIcon(
          name: 'QrCode',
          size: 28,
          color: AppColors.white,
        ),
      ),
    );
  }
}
