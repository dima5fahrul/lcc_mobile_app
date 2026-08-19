/// The account header — `AccountPage.tsx:309-377`.
///
/// A `linear-gradient(135deg, #1A2D6B 0%, #344EAD 100%)` band with a 24 px
/// radial dot overlay at 10 % opacity, carrying the avatar, the name, the UIN
/// line and the "Verified Citizen" chip.
///
/// ## V-16 / V-17 — the likeness ruling, and why there is no photograph here
///
/// `AccountPage.tsx:327` is:
///
/// ```tsx
/// <img src={account?.avatar_url || PROFILE_PHOTO} alt="Profile" … />
/// ```
///
/// where `PROFILE_PHOTO` is `userPhoto` from `../../imports/user-photo.png`.
/// A signed-in citizen with no `avatar_url` is shown **a stock photograph of an
/// identifiable stranger's face, presented as their own profile photo**, in a
/// government identity application. That is V-17
/// (`GOR-245-b1b-assets/security-review.md`:382-404), and it is a defect in the
/// ADR-0001 port oracle rather than in this port.
///
/// **The oracle contradicts itself, and the correct branch is the one written
/// in prose.** `Hero.tsx:226-231`:
///
/// > *The stock portrait belongs to the specimen card only. A signed-in citizen
/// > whose registry record carries no photo gets their initial instead —
/// > someone else's face does not become a placeholder just because it is
/// > standing in.*
///
/// **So B8 ports the comment, not the code.** [_Avatar] renders
/// `account.avatarUrl` when the citizen's own record supplies it, and an
/// initial tile in **every** other case — absent, empty, and network-error
/// alike. There is no `Image.asset` pointing at a photograph of a person
/// anywhere under `lib/features/account/` (B8-AC-11), and `grep -rn
/// "user-photo" lib/` returns only prose comments like this one, which is the
/// **second clause** of V-16's own verification and is what closes it
/// (B8-AC-12). B8 does **not** delete `assets/images/user-photo.webp` — that
/// asset is B1b's, deleting it is outside this batch's ownership, and V-16 does
/// not require it. Removal remains the preferred remedy and is FU-5, for B11.
///
/// The implementation is **reused, not re-derived**: `lao_id_card.dart:313-365`
/// solved exactly this for the digital ID card, and two details in it are easy
/// to get wrong from scratch — see [_Avatar].
///
/// ## Still open, and not closed by this file
///
/// `GOR-245-b2-readonly-surface/security-review.md`:533-550 measured three
/// properties of rendering a live citizen photo with `Image.network`: no
/// `Authorization` header (so `avatar_url` must be public or pre-signed), no
/// host constraint (the handset GETs whatever host the API names, outside
/// `api_endpoint.dart`'s HTTPS guard), and caching outside
/// `FlutterSecureStorage`. **All three apply verbatim to this avatar.** They
/// are a different finding from V-16/V-17 — a *live* citizen, not a specimen —
/// and B8 does not resolve them. GG-6; B8-AC-59 item 1 puts them on the
/// security review's agenda by name so they are not absorbed into V-16/V-17's
/// closure.
///
/// ## B8b IS here now — the avatar is the upload control
///
/// B8a rendered no camera glyph and no tap target, because § 6.14 item 5
/// requires that a non-shipping B8b leave no dead affordance behind. **B8b
/// ships, so both arrive**: the disc is a tap target (`:333-340`, a transparent
/// button over the image — B8-AC-53) and the badge becomes the source's
/// three-way (`:348-356` — B8-AC-55). The paragraph that used to say "B8b is
/// not here" is replaced rather than deleted, because the *reason* it said so
/// is still the reason the two batches are separate.
///
/// **What B8b does NOT change is the ruling above.** V-16 and V-17 are about a
/// stranger's face being *shown* to a citizen; B8b is about a citizen's own
/// face being *sent* to a server. They share this widget and nothing else, and
/// `security-review-b8b.md` § 6 re-verified against both findings' own text
/// that the closure neither extends to the upload nor is threatened by it. The
/// `avatar_url`-absent branch is still the initial tile, in every case.
///
/// **One property this file makes worse, named rather than left to inference.**
/// B8a's `MEDIUM-2` (`security-review.md` § 3.5) records that
/// [_Avatar]'s `Image.network` carries no `Authorization` header, no host
/// constraint and caches outside `FlutterSecureStorage`. Those were latent: the
/// test citizen has no `avatar_url` and `B8-AC-42` is NOT EVALUATED, so the
/// branch may never have run against real data. **B8b makes it run for every
/// citizen who uploads** — `security-review-b8b.md` `B8b-8` (INFO). That is not
/// a reason to withhold B8b; it is why **FU-12** (constrain the host against
/// `ApiEndpoint.baseUrl`'s authority) stops being an optional B11 improvement
/// and becomes a precondition on a real citizen's avatar (§ 12(c) R-3).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../session/domain/entities/citizen_account.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({
    super.key,
    required this.account,
    required this.loading,
    required this.uploading,
    required this.onPickAvatar,
  });

  /// Null until the first `GET /me/profile` lands.
  final CitizenAccount? account;

  /// `profileQuery.loading && !account` — `:359`. Drives the name skeleton.
  final bool loading;

  /// `uploadAvatar.pending` — `:349`. Drives the badge's spinner branch. B8b.
  final bool uploading;

  /// The avatar tap — `onClick={() => fileRef.current?.click()}` (`:334`).
  ///
  /// **Required, not nullable, and not defaulted.** The source renders the
  /// button unconditionally; a nullable callback would make a
  /// tap-target-less avatar a reachable configuration, and `B8-AC-53` would
  /// then be satisfiable by a widget with no control on it. B8b.
  final VoidCallback onPickAvatar;

  /// `background-size: 24px 24px` on the radial-dot overlay — `:320`.
  static const double dotSpacing = 24;

  /// `opacity-10` on that overlay — `:316`.
  static const double dotOverlayOpacity = 0.10;

  /// `rgba(255,255,255,0.6)` dot colour — `:319`.
  static const double dotAlpha = 0.6;

  /// `w-20 h-20` — `:325`.
  static const double avatarSize = 80;

  /// `border-4 border-white/30` — `:325`. B8-AC-38's "20 px avatar ring" is the
  /// ring *diameter* contribution (4 px on each of two sides × … ); the literal
  /// source value is a 4 px border, which is what is asserted.
  static const double avatarRingWidth = 4;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // `135deg` in CSS is top-left → bottom-right.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.newsHeaderStart, AppColors.primary],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: dotOverlayOpacity,
              child: CustomPaint(painter: const _DotOverlayPainter()),
            ),
          ),
          Padding(
            // `px-4 pt-6 pb-10` — `:310`.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gap16,
              AppSpacing.gap24,
              AppSpacing.gap16,
              AppSpacing.gap40,
            ),
            child: Column(
              children: <Widget>[
                _Avatar(
                  account: account,
                  uploading: uploading,
                  onPick: onPickAvatar,
                ),
                const SizedBox(height: AppSpacing.gap12),
                _Name(account: account, loading: loading),
                const SizedBox(height: AppSpacing.gap4),
                // `{c("uin")}: {account?.uin ?? "—"}` — `:366`. One text node,
                // not two: the label, a colon-space and the value are a single
                // JSX text run, and Tier 1 compares nodes.
                Text(
                  '${'account.uin'.tr()}: ${account?.uin ?? '—'}',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: AppTypography.size14,
                  ),
                ),
                if (account?.verified ?? false) ...<Widget>[
                  const SizedBox(height: AppSpacing.gap8),
                  const _VerifiedChip(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `{account?.name ?? "—"}`, or a pulse bar while the first read is in flight —
/// `:358-364`.
class _Name extends StatelessWidget {
  const _Name({required this.account, required this.loading});

  final CitizenAccount? account;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      // `<span className="inline-block h-5 w-40 rounded bg-white/20 animate-pulse" />`
      // — `:360`. **Contributes no text**, which is the assertion Tier 1 makes
      // about this state.
      return Container(
        width: 160,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      );
    }

    return Text(
      account?.name ?? '—',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: AppTypography.size18,
        fontWeight: AppTypography.semiBold,
      ),
    );
  }
}

/// The avatar disc — V-16 / V-17's ruling in code, and B8b's upload control.
/// See the library doc.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.account,
    required this.uploading,
    required this.onPick,
  });

  final CitizenAccount? account;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final String url = account?.avatarUrl ?? '';
    final String name = account?.name ?? '';

    // `displayName.trim().charAt(0).toUpperCase()` — `Hero.tsx:183`, reused
    // from `lao_id_card.dart:322-324` rather than re-derived.
    //
    // **`[0]`, not `.characters.first`.** JavaScript's `charAt(0)` returns one
    // UTF-16 **code unit**, so for "ບຸນມີ ສີສະຫວັດ" the web prints the bare
    // consonant "ບ" and not the grapheme cluster "ບຸ" a Dart `Characters`
    // iterator would give. The cluster is arguably the nicer render; it is also
    // a different string, and Tier 1 compares text exactly. B8-AC-13 asserts
    // the inequality, not just the equality.
    final String trimmed = name.trim();
    final String initial = trimmed.isEmpty ? '' : trimmed[0].toUpperCase();

    final Widget tile = DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.idInitialGradientStart, AppColors.primary],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: AppTypography.size30,
            fontWeight: AppTypography.bold,
          ),
        ),
      ),
    );

    final Widget disc = Container(
      width: AccountHeader.avatarSize,
      height: AccountHeader.avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.3),
          width: AccountHeader.avatarRingWidth,
        ),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? tile
            : Image.network(
                url,
                fit: BoxFit.cover,
                // **The initial tile is the error state as well as the
                // absent state** (B8-AC-14). A broken-image glyph on a
                // government identity surface is worse than no photo, and
                // this is the second of the two details
                // `lao_id_card.dart` records as easy to miss.
                errorBuilder: (_, __, ___) => tile,
                semanticLabel: name,
              ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // ── B8-AC-53 — the photo IS the control ────────────────────────────
        //
        // ```tsx
        // <button onClick={() => fileRef.current?.click()}
        //         aria-label={c("photoHint")} title={c("photoHint")}
        //         className="absolute inset-0 rounded-full">
        //   <span className="sr-only">{c("photoHint")}</span>
        // </button>
        // ```
        //
        // A transparent button over the image, `inset-0` on the disc's box —
        // **not** a separate visible camera button beside it. In Flutter that
        // is a `Semantics(button: true, label:)` wrapping a bare
        // `GestureDetector`.
        //
        // `GestureDetector` and **not** `InkWell`: the source's button has no
        // hover, focus or active styling of any kind, so a Material ripple
        // would be a visual affordance the web does not have — L-10(b) in its
        // smallest form.
        //
        // `photoHint` carries all three of the source's accessible strings
        // (`aria-label`, `title`, and the `sr-only` span) because Flutter has
        // one slot where the DOM has three, and they hold the same value.
        //
        // **There is no `disabled` and no in-flight check here**, exactly as
        // `:333-340` has none. Tapping during an upload starts a second
        // concurrent POST — `security-review-b8b.md` `B8b-5`, GG-8, ported as
        // measured. See `AccountAvatarPicked`.
        Semantics(
          button: true,
          // `context:` — G-L8. `tr_allowlist.yaml` is a ceiling that every
          // batch after B10 must leave shorter, and its one rule is that a new
          // site is never added to it to make a build pass. This one has a
          // context, so it takes it.
          label: 'account.photoHint'.tr(context: context),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPick,
            child: disc,
          ),
        ),
        // `bottom-0 right-0 w-6 h-6 bg-green-400 rounded-full border-2
        // border-white` — `:348`. **The badge is always green**, in all three
        // branches, even when it shows a camera; that is the source's styling
        // and it is ported as-is (B8-AC-55).
        //
        // **`AbsorbPointer`, and it is a port rather than a precaution.** In
        // the DOM the badge is a sibling *after* the button (`:348` vs `:333`),
        // so it paints on top and a click on it hits a `<div>` with no handler
        // — the upload does not open. A Flutter `Stack` hit-tests in reverse
        // paint order, but a bare `Container` does not absorb, so without this
        // the tap would fall through to the `GestureDetector` beneath and
        // tapping the green dot would open the picker. That is a behaviour the
        // web does not have.
        Positioned(
          right: 0,
          bottom: 0,
          child: AbsorbPointer(
            child: Container(
              width: AppSpacing.gap24,
              height: AppSpacing.gap24,
              decoration: BoxDecoration(
                color: AppColors.presenceOnline,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: Center(child: _badgeGlyph()),
            ),
          ),
        ),
      ],
    );
  }

  /// The three-way, in the source's own order — `:349-355`. B8-AC-55.
  ///
  /// ```tsx
  /// {uploadAvatar.pending ? <RefreshCw … animate-spin />
  ///  : account?.verified  ? <CheckCircle … />
  ///  :                      <Camera … />}
  /// ```
  ///
  /// **Order is observable**: an unverified citizen mid-upload shows the
  /// spinner, and a *verified* citizen mid-upload shows the spinner too, not
  /// the tick. A port that tested `verified` first would look right in the only
  /// state most fixtures exercise.
  ///
  /// All three are `w-3 h-3 text-white` on the same always-green disc.
  Widget _badgeGlyph() {
    if (uploading) {
      return const _SpinningGlyph(
        child: LucideIcon(
          name: 'RefreshCw',
          size: AppSpacing.gap12,
          color: AppColors.white,
        ),
      );
    }
    if (account?.verified ?? false) {
      return const LucideIcon(
        name: 'CheckCircle',
        size: AppSpacing.gap12,
        color: AppColors.white,
      );
    }
    // `Camera` was bundled by B8b — see `tool/generate_lucide_svgs.mjs`. Before
    // that it was not in the registry, and `AppIcons.assetFor` would have
    // silently rendered `FileText`: a document glyph on a citizen's avatar,
    // invisible to every fidelity tier this project owns.
    return const LucideIcon(
      name: 'Camera',
      size: AppSpacing.gap12,
      color: AppColors.white,
    );
  }
}

/// `animate-spin` — a continuous 1 s rotation, Tailwind's default.
///
/// The shape is `history_detail_hero.dart`'s `_Spinner`, which is private to
/// that library and so is reproduced rather than imported. Its reasoning holds
/// here too: a `RotationTransition` over an explicit controller is
/// deterministic under `pumpWidget`, where an implicit animation plus
/// `pumpAndSettle` on an infinite repeat never settles.
class _SpinningGlyph extends StatefulWidget {
  const _SpinningGlyph({required this.child});

  final Widget child;

  @override
  State<_SpinningGlyph> createState() => _SpinningGlyphState();
}

class _SpinningGlyphState extends State<_SpinningGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _controller, child: widget.child);
}

/// `{account?.verified && …}` — `:368-375`. `bg-white/10 border-white/20
/// rounded-full px-3 py-1`, a `text-green-400` check and a `text-green-300`
/// label.
class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap12,
        vertical: AppSpacing.gap4,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const LucideIcon(
            name: 'CheckCircle',
            size: AppSpacing.gap12,
            color: AppColors.presenceOnline,
          ),
          const SizedBox(width: AppSpacing.gap6),
          Text(
            'account.verifiedCitizen'.tr(),
            style: const TextStyle(
              color: AppColors.green300,
              fontSize: AppTypography.size12,
            ),
          ),
        ],
      ),
    );
  }
}

/// `backgroundImage: radial-gradient(circle, rgba(255,255,255,0.6) 1px,
/// transparent 1px)` at `backgroundSize: 24px 24px` — `:317-321`.
///
/// A painter rather than a tiled asset: the pattern is two numbers and a
/// colour, and an asset would add a file to a bundle that has a measured
/// ceiling.
class _DotOverlayPainter extends CustomPainter {
  const _DotOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.white.withValues(alpha: AccountHeader.dotAlpha);

    for (double y = 0; y < size.height; y += AccountHeader.dotSpacing) {
      for (double x = 0; x < size.width; x += AccountHeader.dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotOverlayPainter oldDelegate) => false;
}
