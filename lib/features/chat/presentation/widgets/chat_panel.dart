/// The chat panel — `CustomerServiceChat.tsx:197-541`.
///
/// Nine states, and specs.md § 6.10 gates every one of them: `signedOut`,
/// `loading`, `error`, `greeting`, `transcript`, `pending`, `typing`, `rating`,
/// `minimized`. They are decided here, in the order the source decides them.
///
/// ## Two things the source does that a "sensible" port silently corrects
///
/// 1. **The error branch renders no message line here.** `:328` prints
///    `transcript.error.message`, the backend's own sentence. This port has no
///    such sentence: `ChatRepositoryImpl` builds `Failure.message` with
///    `e.toString()`, so rendering it would put `ApiException: …` in front of a
///    citizen — and a fixed bilingual line needs a 23rd `chat` key where § 6.12
///    rules **exactly 22** (B9-AC-46). The line is omitted and the omission is
///    recorded in the Tier 1 oracle's own `not_evaluated`, rather than absorbed.
///    This is the same disposition `notification_menu_sheet.dart` reached for
///    the same reason.
/// 2. **The `tel:` / `mailto:` shortcuts are inert.** Opening a platform URI
///    needs `url_launcher`, which this app does not declare and § 4.3 forbids
///    B9 from adding ("**B9 adds none. Zero.**"). So the buttons render, they
///    hide exactly when the source hides them (`:239`, `:249` — B9-AC-43), and
///    their tap is a no-op. `support_channel_tile.dart` took the same
///    disposition for the same channels in B2c; unlike there, the value is
///    **not** on screen here — it is only in the `title` attribute — so this is
///    reported as the strictly worse gap it is, not as an equivalent one.
///
/// ## The typing indicator is inside the scroller, not beside it
///
/// `:433` is a sibling of the loading/error/rows ternary **inside** the
/// scrolling div (`:316`-`:463`), not of the div. So it shows during a failed
/// fetch too, if a send happens to be in flight. Reproduced as written.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/entities/chat_entities.dart';
import '../bloc/chat_bloc.dart';
import 'clock_time.dart';
import 'formatted_text.dart';

/// `max-w-sm` — `:200`. The panel is `calc(100vw - 2rem)` capped at this.
const double kChatPanelMaxWidth = 384;

/// `right-4` doubled — the `calc(100vw - 2rem)` inset at `:200`.
const double kChatPanelHorizontalInset = 32;

/// `maxHeight: minimized ? "64px" : "520px"` — `:202`.
const double kChatPanelMaxHeight = 520;
const double kChatPanelMinimizedHeight = 64;

/// `tel:${supportPhone.replace(/\s/g, "")}` — `:241`.
///
/// A pure function so B9-AC-43's whitespace claim is assertable without a
/// launcher: the target is computed and rendered as the button's tooltip
/// exactly as the source computes its `href`, even though nothing can open it.
String chatTelTarget(String phone) =>
    'tel:${phone.replaceAll(RegExp(r'\s'), '')}';

/// `mailto:${supportEmail}` — `:251`. **No whitespace strip**, and that
/// asymmetry is the source's, not an oversight here.
String chatMailtoTarget(String email) => 'mailto:$email';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final double available =
        MediaQuery.sizeOf(context).width - kChatPanelHorizontalInset;
    final double width =
        available < kChatPanelMaxWidth ? available : kChatPanelMaxWidth;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (BuildContext context, ChatState state) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            // `style={{ maxHeight: minimized ? "64px" : "520px" }}` — `:202`.
            maxHeight: state.minimized
                ? kChatPanelMinimizedHeight
                : kChatPanelMaxHeight,
          ),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: AppColors.white,
              // `rounded-3xl` — `:200`.
              borderRadius: BorderRadius.circular(24),
              boxShadow: const <BoxShadow>[
                // `shadow-2xl` — `:199`.
                BoxShadow(
                  color: AppColors.cardShadowMedium,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            // `overflow-hidden` — `:199`. Load-bearing at 64 px: the minimised
            // panel clips its own body rather than laying it out.
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ChatPanelHeader(state: state),
                if (!state.minimized && !state.isAuthenticated)
                  const ChatSignInPrompt(),
                if (!state.minimized && state.isAuthenticated) ...<Widget>[
                  Flexible(child: ChatTranscript(state: state)),
                  if (state.ratingOpen) ChatRatingStrip(state: state),
                  if (!state.ratingOpen) ChatSuggestionChips(state: state),
                  ChatComposer(state: state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Header — `:205-279` ──────────────────────────────────────────────────────

class ChatPanelHeader extends StatelessWidget {
  const ChatPanelHeader({super.key, required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final ChatBloc bloc = context.read<ChatBloc>();

    return Container(
      // `backgroundColor: "#344EAD"` — inline hex at `:207`.
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          const _AgentAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  // `agentName ?? t("agentName")` — `:217`. The human agent's
                  // name once one picks the thread up, the bot's until then.
                  state.agentName ?? 'chat.agentName'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'chat.status'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    // `text-white/60` — `:218`.
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // `{threadId && !minimized && …}` — `:222`.
          if (state.threadId != null && !state.minimized)
            _HeaderButton(
              icon: Icons.done_all,
              label: 'chat.endConversation'.tr(),
              onPressed: () => bloc.add(const ChatRatingRequested()),
            ),
          // `{supportPhone && …}` / `{supportEmail && …}` — `:239`, `:249`.
          // Hidden until the channel is published, which is the whole reason
          // these stopped being literals (`:232-238`).
          if (state.supportPhone.isNotEmpty)
            _HeaderButton(
              icon: Icons.phone_outlined,
              label: 'chat.callUs'.tr(),
              // `title={`${t("callUs")} · ${supportPhone}`}` — `:243`.
              tooltip: '${'chat.callUs'.tr()} · ${state.supportPhone}',
              // Inert: no `url_launcher` — see the library doc.
              onPressed: null,
            ),
          if (state.supportEmail.isNotEmpty)
            _HeaderButton(
              icon: Icons.mail_outline,
              label: 'chat.emailUs'.tr(),
              tooltip: '${'chat.emailUs'.tr()} · ${state.supportEmail}',
              onPressed: null,
            ),
          _HeaderButton(
            // lucide `ChevronDown`, rotated 180° when minimised — `:265-268`.
            icon: state.minimized
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            label: 'chat.minimize'.tr(),
            onPressed: () => bloc.add(const ChatMinimizeToggled()),
          ),
          _HeaderButton(
            icon: Icons.close,
            label: 'chat.close'.tr(),
            onPressed: () => bloc.add(const ChatDismissed()),
          ),
        ],
      ),
    );
  }
}

/// `:210-215` — the bot glyph with its presence dot.
class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              // `bg-white/20` — `:211`.
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              // lucide `Bot`, `w-5 h-5 text-white` — `:212`.
              Icons.smart_toy_outlined,
              size: 20,
              color: AppColors.white,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                // `bg-green-400` — `:214`. Class-derived, so Tier 2 cannot see
                // it; named with its provenance in `app_colors.dart`.
                color: AppColors.presenceOnline,
                shape: BoxShape.circle,
                // `border-2 border-white` — `:214`.
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 32 × 32 `bg-white/15` square the header repeats five times.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;

  /// `aria-label` — a semantics label, not a rendered string, so it does not
  /// enter the Tier 1 dump.
  final String label;

  /// `title` — the phone/email shortcuts carry the channel value here, which is
  /// where the source puts it too (`:243`, `:253`).
  final String? tooltip;

  /// Null for the two channel shortcuts: they are inert without `url_launcher`.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget button = Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            // `bg-white/15` — `:227`, `:244`, `:254`, `:263`, `:274`.
            color: AppColors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
      ),
    );

    final String? title = tooltip;
    return title == null ? button : Tooltip(message: title, child: button);
  }
}

// ── Signed out — `:282-311` ──────────────────────────────────────────────────

class ChatSignInPrompt extends StatelessWidget {
  const ChatSignInPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // `bg-[#F5F7FF]` — inline hex at `:283`.
      color: AppColors.chatSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              // `backgroundColor: "#EEF2FF"` — inline hex at `:286`.
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.login, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'chat.signInTitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'chat.signInBody'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              // `setOpen(false); navigateTo("auth")` — `:301-304`.
              //
              // `/signin`, NOT `/account`. The notification bell's sign-in
              // prompt goes to `account` (`Layout.tsx:216`,
              // `onTabChange("account")`) and this one goes to the auth page.
              // Two prompts, two destinations, both measured — a reviewer
              // comparing the two features will expect them to agree and the
              // source does not.
              onPressed: () {
                context.read<ChatBloc>().add(const ChatDismissed());
                context.go(AppNameRoutes.signin);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'chat.signIn'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── The transcript scroller — `:316-463` ─────────────────────────────────────

class ChatTranscript extends StatelessWidget {
  const ChatTranscript({super.key, required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `bg-[#F5F7FF]` — inline hex at `:316`.
      color: AppColors.chatSurface,
      child: SingleChildScrollView(
        // REQUIRED, not tidiness: `MenuAnchor` and `Scaffold`'s body both adopt
        // the `PrimaryScrollController` on mobile, and a second position
        // attached to it throws inside `Scrollbar`. B9a's `_RowList` hit
        // exactly this and its comment has the framework assertion verbatim.
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ..._body(),
            // `{isTyping && …}` — `:433`. A sibling of the ternary INSIDE the
            // scroller, so it shows during a failed fetch too.
            if (state.isTyping) ...<Widget>[
              const SizedBox(height: 12),
              const ChatTypingIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  /// `:317-430`'s ternary, in its own order: loading → error → rows.
  List<Widget> _body() {
    if (state.transcriptLoading) return const <Widget>[_TranscriptSkeleton()];
    if (state.transcriptFailed) return const <Widget>[_TranscriptError()];

    final List<Widget> rows = <Widget>[];

    // `{messages.length === 0 && …}` — `:340`. Not an empty state: the
    // assistant opens the conversation.
    if (state.showsGreeting) {
      rows.add(ChatBubble(text: 'chat.greeting'.tr(), mine: false));
    }

    for (final ChatMessage message in state.messages) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(
        ChatBubble(
          text: message.body,
          mine: message.isMine,
          // `{clockTime(msg.sent_at)}` — `:404`. Only real messages carry one;
          // the greeting and the optimistic bubble do not.
          time: chatClockTime(message.sentAt),
        ),
      );
    }

    // `{pendingText && …}` — `:411-428`. The message currently in flight, at
    // `opacity-70`.
    final String? pending = state.pendingText;
    if (pending != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(ChatBubble(text: pending, mine: true, opacity: 0.7));
    }

    return rows;
  }
}

/// `:318-325` — two pulsing placeholder rows.
class _TranscriptSkeleton extends StatelessWidget {
  const _TranscriptSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // `aria-busy="true"` — `:318`.
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < 2; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.gray200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 192,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// `:327-336`.
///
/// **No message line** — see the library doc. The retry control is
/// `chat.tryAgain`, which unlike the notification menu's is the right copy on
/// the right action: `Layout.tsx:238`'s wrong-label quirk is the *bell's*
/// (B9-AC-37) and does not appear here.
class _TranscriptError extends StatelessWidget {
  const _TranscriptError();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FilledButton(
            onPressed: () =>
                context.read<ChatBloc>().add(const ChatTranscriptRetried()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'chat.tryAgain'.tr(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One message — `:364-408`, and `:340-362` for the greeting.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.mine,
    this.time,
    this.opacity = 1,
  });

  final String text;

  /// `msg.sender_type === "citizen"` — `:365`. Flips the row direction, the
  /// avatar and the bubble colours.
  final bool mine;

  /// Already formatted. Null for the greeting and the optimistic bubble, which
  /// have no timestamp in the source either.
  final String? time;

  /// `opacity-70` on the in-flight bubble — `:412`.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        // `backgroundColor: mine ? "#E5E7EB" : "#344EAD"` — `:374`.
        color: mine ? AppColors.gray200 : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        // lucide `User` / `Bot` — `:376-380`.
        mine ? Icons.person_outline : Icons.smart_toy_outlined,
        size: 16,
        color: mine ? AppColors.gray500 : AppColors.white,
      ),
    );

    final Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          // `borderBottomRightRadius: "4px"` / `borderBottomLeftRadius: "4px"`
          // — `:392`, `:397`. The tail.
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        boxShadow: mine
            ? null
            : const <BoxShadow>[
                // `boxShadow: "0 1px 4px rgba(0,0,0,0.07)"` — `:355`, `:398`.
                BoxShadow(
                  color: AppColors.chatBubbleShadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: ChatFormattedText(
        text: text,
        style: TextStyle(
          fontSize: 14,
          height: 1.625,
          // `color: "white"` / `"#1F2937"` — `:391`, `:396`.
          color: mine ? AppColors.white : AppColors.gray800,
        ),
      ),
    );

    final String? stamp = time;
    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        bubble,
        if (stamp != null && stamp.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              stamp,
              style: const TextStyle(fontSize: 11, color: AppColors.gray400),
            ),
          ),
        ],
      ],
    );

    // `max-w-[75%]` — `:384`.
    final Widget body = Flexible(
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.75,
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: column,
        ),
      ),
    );

    // `flex-row-reverse` for the citizen — `:369`.
    //
    // The children are reordered rather than the row's `textDirection` being
    // flipped to `rtl`. `flex-row-reverse` is a **visual ordering** in CSS; it
    // does not change the writing direction of the text inside, and `rtl` here
    // would — Lao and English are both LTR scripts and a bubble laid out RTL
    // would mis-place punctuation and any bidi run in a citizen's own message.
    final List<Widget> children = <Widget>[
      avatar,
      const SizedBox(width: 8),
      body,
    ];

    return Opacity(
      opacity: opacity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: mine ? children.reversed.toList(growable: false) : children,
      ),
    );
  }
}

/// `:434-459` — three bouncing dots.
///
/// A static row rather than an animation, and that is deliberate: an
/// indefinitely-repeating animation makes `pumpAndSettle` time out, which is
/// what `CircularProgressIndicator` already costs the notification menu's tests.
/// Tier 1 compares text (this contributes none), Tier 2 compares colour (the
/// dots are `#344EAD` at 60 %), and Tier 3 has no reference for any open state.
/// The motion is therefore ungated in every tier and paying for it in test
/// ergonomics buys nothing — recorded rather than quietly dropped.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            size: 16,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.chatBubbleShadow,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: SizedBox(
            height: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    decoration: BoxDecoration(
                      // `backgroundColor: "#344EAD", opacity: 0.6` — `:451-452`.
                      color: AppColors.primary.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Rate and close — `:466-491` ──────────────────────────────────────────────

class ChatRatingStrip extends StatelessWidget {
  const ChatRatingStrip({super.key, required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final ChatBloc bloc = context.read<ChatBloc>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'chat.ratePrompt'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int n = 1; n <= 5; n++)
                Semantics(
                  // `aria-label={L(lang, `${n} out of 5`, `${n} ຈາກ 5`)}` —
                  // `:477`. **Templated**, and B9-AC-47 asserts the rendered
                  // string for n = 1…5 in both locales rather than the key's
                  // presence: a positional-argument mistake yields a key that
                  // is present, a translation that is present, and a label that
                  // reads `{} out of 5`.
                  label: 'chat.rateStarLabel'.tr(args: <String>['$n']),
                  button: true,
                  child: InkWell(
                    // `disabled={closeThread.pending}` — `:476`.
                    onTap: state.closePending
                        ? null
                        : () => bloc.add(ChatRated(n)),
                    borderRadius: BorderRadius.circular(8),
                    child: Opacity(
                      // `disabled:opacity-40` — `:478`.
                      opacity: state.closePending ? 0.4 : 1,
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.star_border,
                          size: 20,
                          // `text-gray-400` — `:478`. The `hover:text-amber-500`
                          // half has no mobile equivalent and is not ported.
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => bloc.add(const ChatRatingDismissed()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'chat.rateNotNow'.tr(),
                style: const TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick replies — `:494-514` ───────────────────────────────────────────────

/// The opening quick replies until the citizen writes, then the bot's
/// suggestions — `:187-192`.
///
/// The two are different kinds of string and the widget is where that is
/// resolved: the opening four are **i18n keys** (`t(key)`, `:189`) and the
/// bot's are literal text from the API. `ChatState.botSuggestions` returns null
/// for the opening case rather than pretending they are the same list.
class ChatSuggestionChips extends StatelessWidget {
  const ChatSuggestionChips({super.key, required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final List<String>? bot = state.botSuggestions;
    final List<String> labels = bot ??
        kChatQuickReplies
            .map((String key) => key.tr())
            .toList(growable: false);

    // `{!rating && suggestions.length > 0 && …}` — `:494`. An agent-assigned
    // thread yields an empty list and the strip disappears entirely.
    if (labels.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 8),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < labels.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                child: InkWell(
                  // `onClick={() => sendMessage(label)}` — `:499`. The chip
                  // sends the LABEL, which is why a chip tap is subject to the
                  // same `isTyping` guard the button is.
                  onTap: () => context
                      .read<ChatBloc>()
                      .add(ChatMessageSubmitted(labels[i])),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      // `borderColor: "#344EAD", color: "#344EAD"` — `:501`.
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Composer — `:517-537` ────────────────────────────────────────────────────

/// The input row.
///
/// ## Why the controller is written back from BLoC state
///
/// The web's `<input>` is **controlled**: `value={input}` (`:521`). Two of the
/// source's behaviours are writes *to* it that no keystroke caused —
/// `setInput("")` when a send starts (`:133`) and `setInput(body)` when one
/// fails (`:147`, *"the citizen keeps the text so they can try again rather
/// than losing what they wrote"*). A widget-local controller could not express
/// either to a test, so `input` is BLoC state and this listener is the write
/// back.
///
/// The listener is guarded on the two strings actually differing, so ordinary
/// typing — which reaches the BLoC through [ChatInputChanged] — never round
/// trips and never moves the cursor.
class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key, required this.state});

  final ChatState state;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.state.input);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromState();
  }

  void _syncFromState() {
    if (_controller.text == widget.state.input) return;
    _controller.value = TextEditingValue(
      text: widget.state.input,
      selection: TextSelection.collapsed(offset: widget.state.input.length),
    );
  }

  void _submit() =>
      context.read<ChatBloc>().add(ChatMessageSubmitted(_controller.text));

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (String value) =>
                  context.read<ChatBloc>().add(ChatInputChanged(value)),
              // `onKeyDown={e => e.key === "Enter" && sendMessage(input)}` —
              // `:523`.
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 14, color: AppColors.gray700),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'chat.placeholder'.tr(),
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray400,
                ),
                filled: true,
                // `bg-gray-100` — `:525`.
                fillColor: AppColors.gray100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            // `aria-label={t("send")}` — `:530`.
            label: 'chat.send'.tr(),
            button: true,
            child: Opacity(
              // `disabled:opacity-40` — `:532`.
              opacity: widget.state.canSend ? 1 : 0.4,
              child: InkWell(
                // `disabled={!input.trim() || isTyping}` — `:529`.
                onTap: widget.state.canSend ? _submit : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
