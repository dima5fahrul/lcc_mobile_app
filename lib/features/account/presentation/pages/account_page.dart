/// Account tab — the port of `lcc-app/src/app/components/AccountPage.tsx`
/// (749 lines), B8a.
///
/// Replaces the 53-line P0-5 placeholder whose own doc comment named this
/// batch's target ("*The real screen … profile header, document wallet,
/// settings groups — is a later batch*").
///
/// A **protected** path (`AppRoutes._protectedPaths`), so the router guards it;
/// see `history_page.dart` for why there is no second in-page check.
///
/// ## Sign-out is unchanged, and that is a requirement
///
/// The stub's sign-out was real and correct: it dispatches `SessionSignOut` and
/// lets the router's `refreshListenable` do the navigating. The button moves
/// into the new layout; **the mechanism is not re-implemented** (specs.md
/// § 4.2 item 1, B8-AC-30), and the rationale comment below travels with it.
///
/// The web's `handleSignOut` additionally calls `navigateTo("home")`
/// (`AccountPage.tsx:289-292`). **The Flutter port must not add that** — it is
/// a pre-existing, correct divergence and the comment on [_SignOutButton] says
/// why.
///
/// ## What this page is NOT — GG-3, stated loudly
///
/// **`DocumentViewer` and the View / Download actions are deferred (FU-2).**
/// See `documents_card.dart` for the four grounds. This is the one place B8 is
/// not a complete port of `AccountPage`.
///
/// **Avatar upload is B8b**, and B8b has shipped — the § 6.7 security review
/// (`security-review-b8b.md`) and B8a's § 8.1 exit gate both closed on
/// 2026-08-19, which is what `B8-AC-58` required. The avatar is now a control
/// as well as a render (`account_header.dart`). The `DocumentViewer` deferral
/// above is unaffected and is still the one place B8 is not a complete port.
///
/// **`DELETE /me/account` does not exist and must not be added.**
/// `me.deactivate` is defined at `endpoints.ts:125` and called from nowhere in
/// the shipped web app: no component, no route, no button, no confirmation
/// dialog. Porting it would invent an irreversible deletion that exists only in
/// the port, invisible to every fidelity tier because there is nothing to
/// compare against, in an application whose APK is unrecallable under ADR-0002.
/// If deletion is wanted it is a feature request against the **web app** first
/// (specs.md § 6.1, FU-4). This paragraph is here because the roadmap's
/// endpoint list is what a future faithful-port dispatch will read.
///
/// ## Tier 3 is NOT EVALUATED for this entire page — GG-1
///
/// `docs/fidelity-baseline/2026-08-13/{en,lo}/05-account.png` exist and their
/// filename says "account". **They are screenshots of the sign-in page**:
/// `manifest.md`:92 records the slot as "redirected → `/signin`", and the image
/// shows "Welcome Back" and a `1 + 9 = ?` captcha. No slot in 01-47 shows the
/// authenticated AccountPage. Claiming a Tier 3 gate against that reference
/// would read as PASS and be worse than NOT EVALUATED (B8-AC-39). FU-6 costs
/// one authenticated, **read-only** capture session at 390 CSS px in both
/// locales.
///
/// ## Three BLoCs, provided by the route builder
///
/// specs.md § 6.3 splits the page's state three ways because the source runs
/// three independent `useQuery` calls with independent loading and error states
/// rendering in three places. The providers live in `app_routes.dart`, not
/// here: G-L5 forbids any widget under `presentation/` from resolving a
/// locator, and route builders are the sanctioned seam (`ssd.md` § 6.4). That
/// edit to `app_routes.dart` is a **recorded deviation from B8-AC-9** — see the
/// hand-back; the AC assumed the file was unnecessary because the route already
/// exists, which is true of the route and not of the providers.
///
/// `SessionBloc` arrives by `BlocProvider.of<SessionBloc>(context)`, a context
/// read, exactly as the stub already did.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/bloc/session_bloc.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../../session/domain/entities/citizen_account.dart';
import '../bloc/account_documents_bloc.dart';
import '../bloc/account_preferences_bloc.dart';
import '../bloc/account_profile_bloc.dart';
import '../../domain/entities/picked_avatar.dart';
import '../bloc/account_profile_state_view.dart';
import '../widgets/account_header.dart';
import '../widgets/account_primitives.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/documents_card.dart';
import '../widgets/language_panel.dart';
import '../widgets/password_form.dart';
import '../widgets/preferences_panel.dart';
import '../widgets/profile_editor.dart';
import '../widgets/settings_card.dart';

/// The four accordion keys — `AccountPage.tsx:503`, `:569`, `:611`, `:658`.
///
/// An enum over one nullable slot, not four booleans: `openPanel` is
/// `string | null` and `toggle` is `cur === key ? null : key` (`:186`, `:304`),
/// so **opening one closes any other, across all three groups**. Four booleans
/// would make four-open-at-once representable. B8-AC-43.
enum AccountPanel { profile, notifications, language, security }

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.pickAvatar = pickAvatarFile});

  /// The OS picker, hoisted so a widget test can drive the whole upload path
  /// without a platform channel — the `ResidentFilePicker` idiom
  /// (`resident_fields.dart:50`). B8b.
  ///
  /// A default rather than a required parameter because `app_routes.dart`
  /// builds this page with no arguments and § 4.1 keeps that file out of B8b's
  /// scope. The default **is** the real picker, so production wiring is the
  /// zero-argument case and a test must opt *out*.
  final AvatarFilePicker pickAvatar;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  /// `const [openPanel, setOpenPanel] = useState<string | null>(null)`.
  AccountPanel? _openPanel;

  @override
  void initState() {
    super.initState();
    // The three `useQuery` calls' `[]` dependency lists — one fetch each, on
    // mount (`AccountPage.tsx:189-191`).
    context.read<AccountProfileBloc>().add(const AccountProfileRequested());
    context.read<AccountDocumentsBloc>().add(const AccountDocumentsRequested());
    context
        .read<AccountPreferencesBloc>()
        .add(const AccountPreferencesRequested());
  }

  /// `toggle = (key) => setOpenPanel(cur => cur === key ? null : key)`.
  void _toggle(AccountPanel panel) => setState(() {
        _openPanel = _openPanel == panel ? null : panel;
      });

  /// `handleAvatar`'s first three lines — `AccountPage.tsx:234-237`. B8b.
  ///
  /// ```tsx
  /// const file = e.target.files?.[0];
  /// e.target.value = "";
  /// if (!file) return;
  /// ```
  ///
  /// **`e.target.value = ""` runs *before* the early return**, and that
  /// ordering is the whole point: it clears the input whether or not a file
  /// came back, so re-picking the *same* file fires `onChange` again. Flutter
  /// has no input element to clear, so the analogue is that **nothing here
  /// memoises a picker result** — every tap calls [AvatarFilePicker] afresh and
  /// every non-null result dispatches. B8-AC-54.
  ///
  /// A cancelled pick returns null and does nothing at all. It must **not**
  /// clear an existing avatar: `if (!file) return` returns before the upload,
  /// and there is no delete path in the source (`endpoints.ts` has no avatar
  /// DELETE; FU-4's reasoning about `me.deactivate` applies here in miniature).
  ///
  /// **No in-flight guard**, matching `:234-245` — `B8b-5`/GG-8.
  Future<void> _pickAvatar() async {
    final AccountProfileBloc bloc = context.read<AccountProfileBloc>();
    final PickedAvatar? file = await widget.pickAvatar();
    if (file == null) return;
    bloc.add(AccountAvatarPicked(file));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<AccountProfileBloc, AccountProfileState>>[
        BlocListener<AccountProfileBloc, AccountProfileState>(
          // `await session.refresh()` — `AccountPage.tsx:224`, the second half
          // of B8-AC-51. The first half (`profileQuery.refetch()`) is the
          // BLoC's.
          //
          // A listener rather than a BLoC-to-BLoC call because `SessionBloc`
          // arrives by context and a BLoC has no context; see the file's doc.
          listenWhen: (AccountProfileState was, AccountProfileState now) =>
              now.saveOutcome == SaveOutcome.saved &&
              was.saveOutcome != SaveOutcome.saved,
          listener: (BuildContext context, AccountProfileState _) {
            BlocProvider.of<SessionBloc>(context)
                .add(const SessionEvent.refreshProfile());
          },
        ),
        // The **same** two refreshes after a successful avatar upload —
        // `AccountPage.tsx:240-241`. A second listener rather than a widened
        // `listenWhen` on the first, because the two are different source
        // lines with different triggers and collapsing them would make a
        // future change to one silently change the other.
        //
        // The BLoC resets `avatarOutcome` to `none` before each attempt, so
        // this edge exists on every upload, not only the first. B8b.
        BlocListener<AccountProfileBloc, AccountProfileState>(
          listenWhen: (AccountProfileState was, AccountProfileState now) =>
              now.avatarOutcome == AvatarOutcome.uploaded &&
              was.avatarOutcome != AvatarOutcome.uploaded,
          listener: (BuildContext context, AccountProfileState _) {
            BlocProvider.of<SessionBloc>(context)
                .add(const SessionEvent.refreshProfile());
          },
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BlocBuilder<AccountProfileBloc, AccountProfileState>(
              builder: (BuildContext context, AccountProfileState state) =>
                  AccountHeader(
                account: state.account,
                loading: state.isLoadingHeader,
                uploading: state.uploadingAvatar,
                onPickAvatar: _pickAvatar,
              ),
            ),
            Padding(
              // `px-4 … py-6 space-y-6` — `:379`.
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap16,
                vertical: AppSpacing.gap24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _ProfileErrorBanner(),
                  const _DocumentsSection(),
                  const SizedBox(height: AppSpacing.gap24),
                  _AccountGroup(
                    openPanel: _openPanel,
                    onToggle: _toggle,
                  ),
                  const SizedBox(height: AppSpacing.gap24),
                  _SettingsGroup(
                    openPanel: _openPanel,
                    onToggle: _toggle,
                  ),
                  const SizedBox(height: AppSpacing.gap24),
                  _SecurityGroup(
                    openPanel: _openPanel,
                    onToggle: _toggle,
                  ),
                  const SizedBox(height: AppSpacing.gap24),
                  const _SignOutButton(),
                  const SizedBox(height: AppSpacing.gap24),
                  const _VersionFooter(),
                  // `<div className="h-4" />` — `:735`.
                  const SizedBox(height: AppSpacing.gap16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `{profileQuery.error && …}` — `:380-390`.
class _ProfileErrorBanner extends StatelessWidget {
  const _ProfileErrorBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountProfileBloc, AccountProfileState>(
      builder: (BuildContext context, AccountProfileState state) {
        if (!state.hasFailed) return const SizedBox.shrink();

        // `profileQuery.error.message || c("profileError")` — `:384`. The API's
        // message wins.
        final String message =
            (state.errorMessage == null || state.errorMessage!.isEmpty)
                ? 'account.profileError'.tr()
                : state.errorMessage!;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.gap24),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.gap16),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              border: Border.all(color: AppColors.dangerOutlineSoft),
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            ),
            child: Row(
              children: <Widget>[
                const LucideIcon(
                  name: 'AlertCircle',
                  size: AppSpacing.gap20,
                  color: AppColors.dangerGlyph,
                ),
                const SizedBox(width: AppSpacing.gap12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.dangerText,
                      fontSize: AppTypography.size14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gap12),
                AccountButton(
                  label: 'account.retry'.tr(),
                  secondary: true,
                  onPressed: () => context
                      .read<AccountProfileBloc>()
                      .add(const AccountProfileRetried()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// `:392-490`.
class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountDocumentsBloc, AccountDocumentsState>(
      builder: (BuildContext context, AccountDocumentsState state) =>
          DocumentsCard(
        loading: state.isLoading,
        failed: state.hasFailed,
        errorMessage: state.errorMessage,
        documents: state.items,
        onRetry: () => context
            .read<AccountDocumentsBloc>()
            .add(const AccountDocumentsRetried()),
      ),
    );
  }
}

/// The Account group — `:492-556`. Three rows: the profile editor, and two
/// **inert** rows showing the citizen's phone and email.
class _AccountGroup extends StatelessWidget {
  const _AccountGroup({required this.openPanel, required this.onToggle});

  final AccountPanel? openPanel;
  final ValueChanged<AccountPanel> onToggle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountProfileBloc, AccountProfileState>(
      builder: (BuildContext context, AccountProfileState state) {
        final CitizenAccount? account = state.account;

        return SettingsCard(
          label: 'account.groupAccount'.tr(),
          children: <Widget>[
            SettingsRow(
              icon: 'User',
              label: 'account.personalInfo'.tr(),
              desc: 'account.personalInfoDesc'.tr(),
              divider: true,
              open: openPanel == AccountPanel.profile,
              onTap: () => onToggle(AccountPanel.profile),
              child: ProfileEditor(
                account: account,
                view: ProfileEditorView(
                  saving: state.saving,
                  nameError: state.fieldErrors['name'],
                  emailError: state.fieldErrors['email'],
                  saveError: state.saveError,
                  noteKey: switch (state.saveOutcome) {
                    SaveOutcome.none => null,
                    SaveOutcome.saved => 'account.saved',
                    SaveOutcome.nothingChanged => 'account.nothingChanged',
                  },
                ),
                onSave: (String name, String email, String address) =>
                    context.read<AccountProfileBloc>().add(
                          AccountProfileSaved(
                            name: name,
                            email: email,
                            address: address,
                          ),
                        ),
              ),
            ),
            // `<Row icon={Phone} label={t("phoneNumber")} desc={account?.phone ?? "—"} divider />`
            // — `:553`. **No `onClick`**, so it is inert and renders a
            // `ChevronRight`. B8-AC-48.
            SettingsRow(
              icon: 'Phone',
              label: 'account.phoneNumber'.tr(),
              desc: _orDash(account?.phone),
              divider: true,
            ),
            // `:554` — `desc={account?.email || "—"}`. Note the source uses
            // `||` here and `??` on the line above: an **empty** email falls
            // back to the dash, an empty phone does not. Both are ported as
            // written; `_orDash` implements the `||` form and the phone row
            // above uses it too because `CitizenAccount.phone` is
            // non-nullable here, so `?? "—"` can never fire and `|| "—"` is
            // the only behaviour reachable in Dart. Recorded rather than
            // silently unified.
            SettingsRow(
              icon: 'Mail',
              label: 'account.emailAddress'.tr(),
              desc: _orDash(account?.email),
              divider: false,
            ),
          ],
        );
      },
    );
  }

  static String _orDash(String? value) =>
      (value == null || value.isEmpty) ? '—' : value;
}

/// The Settings group — `:558-645`.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.openPanel, required this.onToggle});

  final AccountPanel? openPanel;
  final ValueChanged<AccountPanel> onToggle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountPreferencesBloc, AccountPreferencesState>(
      builder: (BuildContext context, AccountPreferencesState state) {
        final AccountPreferencesBloc bloc =
            context.read<AccountPreferencesBloc>();

        return SettingsCard(
          label: 'account.groupSettings'.tr(),
          children: <Widget>[
            SettingsRow(
              icon: 'Bell',
              label: 'account.notifications'.tr(),
              desc: 'account.notificationsDesc'.tr(),
              divider: true,
              open: openPanel == AccountPanel.notifications,
              onTap: () => onToggle(AccountPanel.notifications),
              child: NotificationsPanel(
                loading: state.isLoading,
                errorMessage: state.hasFailed ? state.errorMessage : null,
                preferences: state.preferences,
                saveError: state.saveError,
                onRetry: () => bloc.add(const AccountPreferencesRetried()),
                onToggle: (NotificationChannel channel, bool enabled) =>
                    bloc.add(AccountNotificationToggled(
                  channel,
                  enabled: enabled,
                )),
              ),
            ),
            SettingsRow(
              icon: 'Globe',
              label: 'account.language'.tr(),
              // `desc={prefs ? (prefs.language === "lo" ? "ລາວ" : "English") :
              // t("languageValue")}` — `:609`. Before the first read it is the
              // i18n key; after it, the **server's** record rendered as an
              // endonym. Two different sources for one line.
              desc: state.preferences == null
                  ? 'account.languageValue'.tr()
                  : LanguagePanel.labelFor(state.preferences!.language),
              divider: true,
              open: openPanel == AccountPanel.language,
              onTap: () => onToggle(AccountPanel.language),
              child: LanguagePanel(
                preferences: state.preferences,
                onSelected: (String code) =>
                    bloc.add(AccountLanguageSelected(code)),
              ),
            ),
            // `:638-643` — inert, `ChevronRight`.
            SettingsRow(
              icon: 'CreditCard',
              label: 'account.paymentMethods'.tr(),
              desc: 'account.paymentMethodsDesc'.tr(),
              divider: false,
            ),
          ],
        );
      },
    );
  }
}

/// The Security group — `:647-717`.
class _SecurityGroup extends StatelessWidget {
  const _SecurityGroup({required this.openPanel, required this.onToggle});

  final AccountPanel? openPanel;
  final ValueChanged<AccountPanel> onToggle;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      label: 'account.groupSecurity'.tr(),
      children: <Widget>[
        SettingsRow(
          icon: 'Shield',
          label: 'account.privacySecurity'.tr(),
          desc: 'account.privacySecurityDesc'.tr(),
          divider: true,
          open: openPanel == AccountPanel.security,
          onTap: () => onToggle(AccountPanel.security),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              BlocBuilder<AccountPreferencesBloc, AccountPreferencesState>(
                builder: (
                  BuildContext context,
                  AccountPreferencesState state,
                ) =>
                    BiometricSwitch(
                  preferences: state.preferences,
                  onChanged: (bool enabled) => context
                      .read<AccountPreferencesBloc>()
                      .add(AccountBiometricToggled(enabled: enabled)),
                ),
              ),
              BlocBuilder<AccountProfileBloc, AccountProfileState>(
                builder: (BuildContext context, AccountProfileState state) =>
                    PasswordForm(
                  pending: state.changingPassword,
                  errorKey: passwordErrorKey(state.passwordError),
                  serverError: state.passwordServerError,
                  changed: state.passwordChanged,
                  onSubmit: (String current, String next, String confirm) =>
                      context.read<AccountProfileBloc>().add(
                            AccountPasswordSubmitted(
                              currentPassword: current,
                              newPassword: next,
                              confirmPassword: confirm,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
        // `:709-715` — **`helpSupport` navigates and does not toggle**, while
        // still rendering a `ChevronDown`, because `Row`'s chevron branch keys
        // off *having a handler* rather than off being a panel (`:165`). A
        // source quirk, ported and not corrected. B8-AC-44 asserts the
        // navigation, not merely that the row is tappable.
        SettingsRow(
          icon: 'HelpCircle',
          label: 'account.helpSupport'.tr(),
          desc: 'account.helpSupportDesc'.tr(),
          divider: false,
          onTap: () => context.go(AppNameRoutes.help),
        ),
      ],
    );
  }
}

/// `:719-728`, and the one behaviour § 4.2 freezes.
class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SessionBloc, SessionState, bool>(
      // The stub's gate, preserved: the button renders only once the session
      // has resolved to `authenticated`. During the boot hold
      // (`initial` / `loading`) there is nothing to sign out of yet.
      selector: (SessionState state) =>
          state.status == SessionStatus.authenticated,
      builder: (BuildContext context, bool isAuthenticated) {
        if (!isAuthenticated) return const SizedBox.shrink();

        return Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          child: InkWell(
            // **Nothing here navigates by hand.** `SessionSignOut` revokes the
            // refresh token best-effort, clears `FlutterSecureStorage` and
            // emits `unauthenticated`; the router's `refreshListenable` then
            // re-runs `redirect`, finds `/account` protected and sends the
            // citizen to `/signin?from=%2Faccount`. Navigating here would race
            // the gate and could leave the app on a protected page with no
            // session.
            //
            // The web's `handleSignOut` **does** call `navigateTo("home")`
            // (`AccountPage.tsx:291`). Not porting that is a deliberate,
            // pre-existing divergence carried over from the P0 stub, and this
            // comment is the record of it (specs.md § 4.2 item 1, B8-AC-30).
            onTap: () => BlocProvider.of<SessionBloc>(context)
                .add(const SessionEvent.signOut()),
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.gap16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dangerOutlineSoft),
                borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const LucideIcon(
                    name: 'LogOut',
                    size: AppSpacing.gap16,
                    color: AppColors.dangerGlyph,
                  ),
                  const SizedBox(width: AppSpacing.gap8),
                  Text(
                    'account.signOut'.tr(),
                    style: const TextStyle(
                      color: AppColors.dangerGlyph,
                      fontSize: AppTypography.size14,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// `:730-733`.
///
/// **Not i18n.** The source hardcodes both lines in English in *both* locales,
/// including the version string, and they are ported verbatim as literals —
/// B8-AC-47. Turning them into keys would let the Lao column drift from the
/// web's, which prints "LaoGov v2.1.0" to a Lao reader too.
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  /// `<p className="text-gray-300 text-xs">LaoGov v2.1.0</p>` — `:731`.
  static const String version = 'LaoGov v2.1.0';

  /// `:732`.
  static const String ministry = 'Ministry of Interior, Lao PDR';

  @override
  Widget build(BuildContext context) => const Column(
        children: <Widget>[
          Text(
            version,
            style: TextStyle(
              color: AppColors.gray300,
              fontSize: AppTypography.size12,
            ),
          ),
          Text(
            ministry,
            style: TextStyle(
              color: AppColors.gray300,
              fontSize: AppTypography.size12,
            ),
          ),
        ],
      );
}
