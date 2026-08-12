/// `AuthPage` — the sign-in / register / OTP / reset shell.
///
/// Ported from `lcc-app/src/app/components/AuthPage.tsx`. The shell holds an
/// [AuthBloc] via [BlocProvider] and manages the four-step state machine
/// (`form(login)` / `form(register)` / `otp` / `reset`) plus the OTP purpose.
///
/// On a successful login or OTP verify the page reads the emitted
/// [CitizenSession] and wires it into the app-wide [SessionBloc] via
/// `SessionSignIn(session)` — the AuthBloc does not depend on SessionBloc, so
/// the two features stay decoupled (matches the TS `signIn(session)` port).
///
/// ## Provider scoping (defect F-1)
///
/// Two BLoCs are read from this subtree and both are now genuinely provided:
///
/// - **`SessionBloc`** — app-scoped. `main.dart` puts a
///   `BlocProvider<SessionBloc>.value` **above** `MaterialApp.router`, so every
///   route, inside the shell or not, has it as an ancestor. `/signin` is
///   mounted outside the `ShellRoute`, which is exactly why the provider has to
///   sit above the router rather than in `AppShell`. Backed by the
///   `registerLazySingleton<SessionBloc>` in
///   `features/session/di/session_feature_injection.dart` — one instance for
///   the app's lifetime, shared with the router's `refreshListenable`.
/// - **`AuthBloc`** — auth-screen-scoped, provided by [AuthPage] itself and by
///   nothing above it. `AuthFeatureInjection` registers it with
///   `registerFactory`, i.e. a fresh BLoC per resolution, so the provider must
///   be one that owns a per-mount instance: this page resolves exactly once in
///   `initState`, hands it down with `BlocProvider.value`, and `close()`s it in
///   `dispose`. Factory registration and page-scoped ownership match, which is
///   the pairing F-2 got wrong in the opposite direction (a factory BLoC held
///   as if it were a singleton).
///
///   The lifetime is deliberate, not incidental: leaving `/signin` must throw
///   away the in-flight auth attempt. A half-entered password, an unverified
///   OTP challenge and the phone number it was issued for are all short-lived
///   credentials — an app-scoped AuthBloc would keep them resident, and worse,
///   would replay a stale `AuthStatus.success` into `BlocListener` the next
///   time the page mounted, signing the citizen in from a state they had
///   already navigated away from.
///
/// ## Post-success destination
///
/// The `from` query param (written by the router's auth gate) arrives as the
/// [from] constructor argument — already percent-decoded by the router, which
/// owns the wire format. The page never reads `GoRouterState` itself: that
/// keeps the auth feature from importing the router class (a layering
/// inversion) and lets [AuthPage] be pumped in a test with no `GoRouter` in
/// the tree. When [from] is null or empty the citizen goes to
/// [AppNameRoutes.home].
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../utils/routes/app_name_routes.dart';
import '../../../session/domain/entities/citizen_session.dart';
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../di/auth_injection.dart';
import '../bloc/auth_bloc.dart';
import 'login_form.dart';
import 'otp_form.dart';
import 'register_form.dart';
import 'reset_form.dart';

/// The step the auth flow is currently on. Port of `AuthStep` in AuthPage.tsx.
enum AuthStep { form, otp, reset }

/// Which mode the form step is in. Port of `AuthMode` in AuthPage.tsx.
enum AuthMode { login, register }

/// Which one-time-code flow the OTP screen is serving. Port of `OtpPurpose`.
enum OtpPurpose { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.from});

  /// Where to send the citizen once the session is established — the decoded
  /// `?from=` the auth gate attached when it bounced them here. Null when they
  /// reached `/signin` directly, in which case success lands on
  /// [AppNameRoutes.home].
  final String? from;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = authInjection<AuthBloc>();
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: _AuthShell(from: widget.from),
    );
  }
}

/// The shell: a dark-blue gradient background with a white card carrying the
/// current step. Port of `AuthShell` in AuthPage.tsx (the photo-backed version
/// is the web build; Flutter uses a brand gradient so no image assets are
/// required).
class _AuthShell extends StatefulWidget {
  const _AuthShell({this.from});

  /// See [AuthPage.from].
  final String? from;

  @override
  State<_AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<_AuthShell> {
  AuthStep _step = AuthStep.form;
  AuthMode _mode = AuthMode.login;
  OtpPurpose _otpPurpose = OtpPurpose.login;

  /// The phone the challenge was issued for, exactly as the API normalised it.
  String _pendingPhone = '';

  void _openChallenge(String realPhone, AuthStep next, {OtpPurpose? purpose}) {
    setState(() {
      _pendingPhone = realPhone;
      _step = next;
      if (purpose != null) _otpPurpose = purpose;
    });
  }

  void _backToForm() {
    setState(() {
      _step = AuthStep.form;
    });
    context.read<AuthBloc>().add(const AuthEvent.resetState());
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
      _step = AuthStep.form;
    });
    context.read<AuthBloc>().add(const AuthEvent.resetState());
  }

  /// On a successful login / OTP verify, hand the session to SessionBloc and
  /// navigate to the `from` destination (or home). Port of `signIn(session)` +
  /// `onSuccess()` in AuthPage.tsx.
  ///
  /// `context.read<SessionBloc>()` resolves against the provider `main.dart`
  /// installs above `MaterialApp.router` — see the F-1 note at the top of this
  /// file. Both statements run synchronously in the same frame, so nothing
  /// touches `context` across an async gap.
  ///
  /// The explicit `go` is not redundant with the router's own
  /// `authenticated && location == /signin` redirect branch: `SessionSignIn` is
  /// handled asynchronously, so at this instant the session is still
  /// unauthenticated. Navigating now takes the citizen off the auth screen
  /// immediately; if the target is protected the gate will hold them at
  /// `/signin` for the moment it takes the profile to load and then release
  /// them to the same place. Either path converges on [_destination] — which
  /// is what the harness for this dispatch asserted end to end.
  void _onSession(CitizenSession session) {
    context.read<SessionBloc>().add(SessionEvent.signIn(session));
    context.go(_destination);
  }

  /// The post-success destination. F-4: this used to be the string literal
  /// `'/'`. [AppNameRoutes] exists so route paths have exactly one definition —
  /// a literal here would silently stop agreeing with the router the day the
  /// home path changes, and it would not be a compile error.
  String get _destination {
    final String? from = widget.from;
    return (from != null && from.isNotEmpty) ? from : AppNameRoutes.home;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.success && state.session != null) {
          _onSession(state.session!);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF101C48), Color(0xFF1A2A5E)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Brand block.
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Column(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 56, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          'LAOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'auth.brand'.tr(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // White card carrying the current step.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildStep(),
                  ),
                  const SizedBox(height: 24),
                  // Trust footer.
                  Text(
                    'auth.trustLine'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'auth.trustSub'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case AuthStep.otp:
        return OtpForm(
          pendingPhone: _pendingPhone,
          purpose: _otpPurpose,
          onBack: _backToForm,
        );
      case AuthStep.reset:
        return ResetForm(
          pendingPhone: _pendingPhone,
          onBack: _backToForm,
        );
      case AuthStep.form:
        return _mode == AuthMode.login
            ? LoginForm(
                onSwitchToRegister: () => _switchMode(AuthMode.register),
                onOtpRequested: (phone) {
                  _openChallenge(phone, AuthStep.otp, purpose: OtpPurpose.login);
                },
                onResetRequested: (phone) {
                  _openChallenge(phone, AuthStep.reset);
                },
              )
            : RegisterForm(
                onSwitchToLogin: () => _switchMode(AuthMode.login),
                onRegisterSuccess: (phone) {
                  _openChallenge(phone, AuthStep.otp, purpose: OtpPurpose.register);
                },
              );
    }
  }
}
