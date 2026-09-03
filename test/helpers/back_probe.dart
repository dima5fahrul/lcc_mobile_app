/// The hardware-Back probe GOR-269's Stage 2 established and Stage 7 turned
/// into in-tree regression tests.
///
/// ## Why a widget test is admissible evidence of a *hardware* button press
///
/// No device or emulator is available to any stage of this ticket, so the
/// question `qa-report.md` § 2.2 had to answer — and answered by ruling rather
/// than by assertion — is what counts as admissible evidence without hardware.
/// The ruling, restated here because these tests inherit it:
///
/// * **The inbound path is the production one.** On Android the embedder turns
///   `KEYCODE_BACK` (and 3-button / gesture navigation) into a
///   `flutter/navigation` platform message carrying the method `popRoute`.
///   `WidgetsBinding._handleNavigationInvocation` routes it to
///   `handlePopRoute()`. [pressBack] injects that same message on that same
///   channel; there is no test-only entry point involved.
/// * **The outbound call is the production one.** `handlePopRoute()` walks
///   every `WidgetsBindingObserver` and, if none returns true, calls
///   `SystemNavigator.pop()` — on Android, the call that finishes the Activity.
///   [interceptPlatformChannel] mocks `SystemChannels.platform`, so **the app
///   closing becomes an observable event** rather than a process death.
/// * **Everything between the two is production.** These tests pump the real
///   `App` from `lib/main.dart` through `app_test_harness.dart`, which doubles
///   exactly two things: the HTTP transport and the secure-storage channel.
///
/// **Two independent signals per press.** [BackPress.exited] comes from the
/// platform-call list; [BackPress.popRouteReply] is `handlePopRoute()`'s own
/// `bool` return, decoded off the channel reply. They travel different code
/// paths and agreed on all 18 of Stage 2's rows. Assert both, not one: a
/// single-signal probe cannot distinguish a result from a measurement artefact.
///
/// **The instrument is falsifiable, and Stage 2 falsified it** — it reported
/// `EXIT=false` on 4 of 22 rows before any fix existed. A post-fix suite in
/// which *every* row reports "Back was handled" is indistinguishable from a
/// broken probe, which is why `GOR-269-AC-18` and `-AC-21` — the two rows that
/// must still report the exit — are this instrument's own control and are
/// written as tests rather than left implicit.
///
/// ## What it does not establish, stated rather than buried
///
/// * The Activity does not actually die; the call that kills it is observed one
///   frame earlier. Everything downstream of the engine receiving
///   `SystemNavigator.pop` is **NOT EVALUATED**.
/// * OEM- and Android-version-level variation at the *embedder* level is **NOT
///   EVALUATED**. Both inbound channels the framework exposes are driven, which
///   is the whole of the framework's surface, but not the whole of every OEM's.
library;

import 'dart:ui' show AppLifecycleState;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One Back press, as both signals saw it.
class BackPress {
  const BackPress({required this.popRouteReply, required this.platformCalls});

  /// `handlePopRoute()`'s own return value: true when an observer handled the
  /// press, false when it fell through to the exit. Null on the predictive-back
  /// channel, which discards the bool (`binding.dart:_handleCommitBackGesture`).
  final bool? popRouteReply;

  /// Every method invoked on `SystemChannels.platform` during the press.
  final List<String> platformCalls;

  /// Whether the app was closed.
  bool get exited => platformCalls.contains('SystemNavigator.pop');

  @override
  String toString() =>
      'BackPress(exited: $exited, popRouteReply: $popRouteReply, '
      'platform: $platformCalls)';
}

/// Makes `SystemNavigator.pop` observable for the rest of the test.
///
/// Returns the live list of method names seen on `SystemChannels.platform`.
/// The handler answers the three incidental calls the app emits during normal
/// operation (`qa-report.md` § 2.8 measured them:
/// `SystemChrome.setApplicationSwitcherDescription`,
/// `LiveText.isLiveTextInputAvailable` and `Clipboard.hasStrings`) with shapes
/// their callers can decode, so intercepting the channel does not itself change
/// how the app behaves.
///
/// ## [frameworkHandlesBack] — the *outbound* half, and why it is separate
///
/// Every other signal this file exposes describes what the app does **after**
/// Android has decided to deliver a Back press into Flutter. Passing a list
/// here also records the argument of every
/// `SystemNavigator.setFrameworkHandlesBack` call, which is the app deciding
/// whether Android delivers that press **at all** (`SRE-269-5`). It is an
/// optional out-parameter rather than a second interceptor because only one
/// mock handler can be installed on `SystemChannels.platform` at a time, and a
/// test that wanted both signals would otherwise have to choose.
///
/// Nothing is recorded here unless the app is at a lifecycle state that permits
/// the call — see [resumeApp], without which this list stays empty on a route
/// where the running app would have emitted.
List<String> interceptPlatformChannel(
  WidgetTester tester, {
  List<bool>? frameworkHandlesBack,
}) {
  final List<String> calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      calls.add(call.method);
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
        frameworkHandlesBack?.add(call.arguments as bool);
      }
      return switch (call.method) {
        'Clipboard.hasStrings' => <String, dynamic>{'value': false},
        'LiveText.isLiveTextInputAvailable' => false,
        _ => null,
      };
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

/// Drives the app to [AppLifecycleState.resumed] — the state a real Android app
/// is in whenever a citizen can press anything.
///
/// **A widget test leaves the lifecycle `null`**, and `null` is not a neutral
/// default here: `WidgetsApp._defaultOnNavigationNotification` returns early on
/// it (`widgets/app.dart:1443-1447`) and never reaches
/// `SystemNavigator.setFrameworkHandlesBack`. So the entire outbound
/// platform-gate conversation is silent in an unresumed test, which is why 3599
/// green tests coexisted with `SRE-269-5` and why any test asserting on
/// [interceptPlatformChannel]'s `frameworkHandlesBack` list must call this
/// first or measure nothing.
///
/// Driven over `flutter/lifecycle` with the same reasoning [pressBack] uses for
/// `flutter/navigation`: the embedder sends exactly this message
/// (`ServicesBinding._handleLifecycleMessage`, `services/binding.dart:60`,
/// `:302-310`), so there is no test-only entry point involved.
Future<void> resumeApp(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.lifecycle.name,
    const StringCodec().encodeMessage(AppLifecycleState.resumed.toString()),
    (ByteData? _) {},
  );
  await tester.pumpAndSettle();
}

/// Presses Android hardware Back the way the platform does.
///
/// [platformCalls] is [interceptPlatformChannel]'s list; it is cleared first so
/// the result describes this press and not the app's incidental chatter.
Future<BackPress> pressBack(
  WidgetTester tester,
  List<String> platformCalls,
) async {
  platformCalls.clear();

  final ByteData? reply =
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (ByteData? _) {},
  );
  await tester.pumpAndSettle();

  return BackPress(
    popRouteReply:
        reply == null ? null : const JSONMethodCodec().decodeEnvelope(reply) as bool,
    platformCalls: List<String>.of(platformCalls),
  );
}

/// Drives a full Android 14+ predictive-back gesture: `startBackGesture` →
/// `updateBackGestureProgress` → `commitBackGesture`.
///
/// A genuinely separate inbound code path — `flutter/backgesture`, handled by
/// `WidgetsBinding._handleBackGestureInvocation` — and not the same test in
/// different clothing. It converges on `handlePopRoute()` only because no
/// observer claims the gesture, which is the mechanism `qa-report.md` § 2.8
/// measured and `OQ-7` closed on. Driving it is what proves a fix installed at
/// the observer level covers both channels rather than only the one it was
/// written against.
Future<BackPress> pressPredictiveBack(
  WidgetTester tester,
  List<String> platformCalls,
) async {
  platformCalls.clear();
  const StandardMethodCodec codec = StandardMethodCodec();

  Future<void> send(String method, [Object? arguments]) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (ByteData? _) {},
    );
  }

  await send('startBackGesture', <String, dynamic>{
    'touchOffset': <double>[0.0, 300.0],
    'progress': 0.0,
    'swipeEdge': 0,
  });
  await send('updateBackGestureProgress', <String, dynamic>{
    'touchOffset': <double>[200.0, 300.0],
    'progress': 0.9,
    'swipeEdge': 0,
  });
  await send('commitBackGesture');
  await tester.pumpAndSettle();

  return BackPress(
    popRouteReply: null,
    platformCalls: List<String>.of(platformCalls),
  );
}
