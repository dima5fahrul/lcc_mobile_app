/// Standing the chat up in a test.
///
/// ## Why this lives here and not in `test/helpers/`
///
/// The same reason `notification_test_helper.dart` gives: B9's § 3.1 scope
/// table names `test/features/chat/**` and does not name `test/helpers/`, and
/// B9-AC-48 makes a path outside that table a scope finding. A deviation from
/// house convention, stated rather than left for a reviewer to notice.
///
/// ## The fixtures are SYNTHETIC and the loader says so out loud
///
/// `test/fidelity/oracle.dart`'s `loadApi` reads the baseline's `oracle/api/`,
/// which holds **real recorded staging payloads**. B9's fixtures are not that
/// and must not be reached through the same door: they live under
/// `test/fidelity/fixtures/api/` and are read by [loadSyntheticChatApi], whose
/// name is the reminder.
///
/// For chat the standard is not merely unmet but unmeetable: a recording of
/// `POST /me/chat/threads` requires **writing a thread to a live account**,
/// which `manifest-authenticated.md` records the slot 16-47 session explicitly
/// refused. Reported NOT EVALUATED with that reason, never PASS
/// (specs.md § 2.2 Finding I, B9-AC-57).
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/chat/data/models/chat_wire.dart';
import 'package:lcc_mobile_app/features/chat/domain/entities/chat_entities.dart';
import 'package:lcc_mobile_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:lcc_mobile_app/features/chat/domain/usecases/chat_usecases.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_panel.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_repository.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../helpers/app_test_harness.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures — SYNTHETIC, declared as such in their own `_capture.provenance`
// ─────────────────────────────────────────────────────────────────────────────

const String _apiFixtureDir = 'test/fidelity/fixtures/api';
const String _tier0FixtureDir = 'test/features/chat/fidelity/fixtures';

Map<String, dynamic> _read(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Missing fixture `${file.path}`. `flutter test` runs from the package '
      'root; if this is absent the suite was launched from somewhere else, or '
      'the checkout is incomplete.',
    );
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// `test/fidelity/fixtures/api/<name>.json` — the whole envelope.
Map<String, dynamic> loadSyntheticChatApi(String name) =>
    _read('$_apiFixtureDir/$name.json');

/// `test/features/chat/fidelity/fixtures/chat-tier0-payloads.json`.
Map<String, dynamic> loadTier0Payloads() =>
    _read('$_tier0FixtureDir/chat-tier0-payloads.json');

/// The four synthetic threads, parsed by the **production** `*From` function.
/// Parsing them any other way would test the fixture, not the parser.
List<ChatThread> syntheticThreads() =>
    (loadSyntheticChatApi('me-chat-threads')['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(chatThreadFrom)
        .toList(growable: false);

/// The six synthetic messages, likewise.
List<ChatMessage> syntheticMessages() =>
    (loadSyntheticChatApi('me-chat-messages')['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(chatMessageFrom)
        .toList(growable: false);

/// The support channels the chat header reads.
///
/// Hand-built rather than loaded: `/help/channels` is **B2c's** endpoint and
/// its fixture is B2c's; B9b consumes the domain entity through
/// `GetSupportChannels` and never parses the JSON (specs.md § 6.6), so a
/// fixture here would be testing a boundary this feature does not have.
///
/// `hotline` and not `phone` on purpose: `supportPhone` falls back
/// `phone → hotline` (`:52`) and a fixture that supplied `phone` could not
/// fail the fallback (B9-AC-43).
List<SupportChannel> syntheticChannels() => const <SupportChannel>[
      SupportChannel(
        id: 'ch-hotline',
        kind: 'hotline',
        label: Bilingual(en: 'Hotline', lo: 'ສາຍດ່ວນ'),
        value: '1590 234',
        hours: Bilingual(en: 'Mon-Fri', lo: 'ຈັນ-ສຸກ'),
        icon: 'phone',
      ),
      SupportChannel(
        id: 'ch-email',
        kind: 'email',
        label: Bilingual(en: 'Email', lo: 'ອີເມວ'),
        value: 'support@lcc.gov.la',
        hours: Bilingual(en: '24/7', lo: '24/7'),
        icon: 'mail',
      ),
      SupportChannel(
        id: 'ch-office',
        kind: 'office',
        label: Bilingual(en: 'Office', lo: 'ຫ້ອງການ'),
        value: 'Vientiane',
        hours: Bilingual(en: 'Mon-Fri', lo: 'ຈັນ-ສຸກ'),
        icon: 'building',
      ),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// The doubles
// ─────────────────────────────────────────────────────────────────────────────

/// Counts every call, because most of B9b's criteria are **invocation-count**
/// claims rather than rendering claims: "the poll is scoped to four conditions"
/// (B9-AC-17), "the read-marker fires on mount with zero messages and again per
/// inbound message" (B9-AC-35) and "a send is suppressed while one is in
/// flight" (B9-AC-36) are all statements about how many times a use case ran,
/// and none of them is visible in a rendered tree.
class FakeChatRepository implements ChatRepository {
  late Either<Failure, List<ChatThread>> threads =
      Right<Failure, List<ChatThread>>(syntheticThreads());

  late Either<Failure, List<ChatMessage>> messages =
      Right<Failure, List<ChatMessage>>(syntheticMessages());

  Either<Failure, StartedThread> started = Right<Failure, StartedThread>(
    const StartedThread(thread: ChatThread(id: 'th-new-9', status: 'open')),
  );
  Either<Failure, SentMessage> sent = const Right<Failure, SentMessage>(
    SentMessage(),
  );
  Either<Failure, Unit> read = const Right<Failure, Unit>(unit);
  Either<Failure, Unit> closed = const Right<Failure, Unit>(unit);

  int threadCalls = 0;
  final List<String> messageCalls = <String>[];
  final List<String> startedSubjects = <String>[];
  final List<String> startedMessages = <String>[];
  final List<({String threadId, String body})> sentCalls =
      <({String threadId, String body})>[];
  final List<String> readCalls = <String>[];
  final List<({String threadId, int rating})> closeCalls =
      <({String threadId, int rating})>[];

  /// Held open so a test can observe the in-flight window — the one a
  /// concurrent second dispatch would race into.
  Duration latency = Duration.zero;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  void failEverything() {
    const Failure f = Failure('stubbed failure');
    threads = const Left<Failure, List<ChatThread>>(f);
    messages = const Left<Failure, List<ChatMessage>>(f);
    started = const Left<Failure, StartedThread>(f);
    sent = const Left<Failure, SentMessage>(f);
    read = const Left<Failure, Unit>(f);
    closed = const Left<Failure, Unit>(f);
  }

  void emptyTranscript() =>
      messages = const Right<Failure, List<ChatMessage>>(<ChatMessage>[]);

  void noThreads() =>
      threads = const Right<Failure, List<ChatThread>>(<ChatThread>[]);

  @override
  Future<Either<Failure, List<ChatThread>>> getThreads() async {
    threadCalls++;
    await _wait();
    return threads;
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required String threadId,
    required int perPage,
  }) async {
    messageCalls.add('$threadId|$perPage');
    await _wait();
    return messages;
  }

  @override
  Future<Either<Failure, StartedThread>> startThread({
    required String subject,
    required String message,
  }) async {
    // The subject arrives here UNTRUNCATED — the transform lives in
    // `chat_wire.dart`, where the request body is built, so that Tier 0 asserts
    // the encoded body rather than an intermediate value (specs.md § 6.7).
    startedSubjects.add(subject);
    startedMessages.add(message);
    await _wait();
    return started;
  }

  @override
  Future<Either<Failure, SentMessage>> sendMessage({
    required String threadId,
    required String body,
  }) async {
    sentCalls.add((threadId: threadId, body: body));
    await _wait();
    return sent;
  }

  @override
  Future<Either<Failure, Unit>> markRead(String threadId) async {
    readCalls.add(threadId);
    await _wait();
    return read;
  }

  @override
  Future<Either<Failure, Unit>> closeThread({
    required String threadId,
    required int rating,
  }) async {
    closeCalls.add((threadId: threadId, rating: rating));
    await _wait();
    return closed;
  }
}

/// The one help-domain dependency the chat re-exports (specs.md § 6.6).
///
/// A double of the **help repository**, not of `GetSupportChannels`: the chat
/// consumes the real use case, so a double one layer down proves the re-export
/// is wired rather than that a stub was handed in.
class FakeHelpChannelsRepository implements HelpRepository {
  late Either<Failure, List<SupportChannel>> channels =
      Right<Failure, List<SupportChannel>>(syntheticChannels());

  int calls = 0;

  void nonedPublished() =>
      channels = const Right<Failure, List<SupportChannel>>(<SupportChannel>[]);

  @override
  Future<Either<Failure, List<SupportChannel>>> getChannels() async {
    calls++;
    return channels;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'The chat reaches `HelpRepository` for /help/channels only. '
        '`${invocation.memberName}` is the help centre\'s and calling it from '
        'here would be a cross-feature dependency the chat does not have.',
      );
}

/// A [ChatBloc] over the two doubles, wired exactly as production wires it —
/// through the real use cases, not around them.
ChatBloc chatBlocOver(
  FakeChatRepository repository, {
  FakeHelpChannelsRepository? help,
}) =>
    ChatBloc(
      getChatThreads: GetChatThreads(repository: repository),
      getChatMessages: GetChatMessages(repository: repository),
      startChatThread: StartChatThread(repository: repository),
      sendChatMessage: SendChatMessage(repository: repository),
      markThreadRead: MarkThreadRead(repository: repository),
      closeChatThread: CloseChatThread(repository: repository),
      getSupportChannels: GetSupportChannels(
        repository: help ?? FakeHelpChannelsRepository(),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Pumping
// ─────────────────────────────────────────────────────────────────────────────

/// Pumps [ChatPanel] under [bloc], with no shell, no router and no container.
///
/// **That this is possible is the point of the seam.** The panel is a feature
/// widget composed into the chrome through `AppShell.floatingAction`; if it had
/// been written into `lib/presentation/shell/` it would need the shell, and the
/// shell would need the feature's BLoC type — the edge `ssd.md`:255 forbids and
/// G-L7 fails the build over.
///
/// **Does not settle.** Callers pump explicitly, as `pumpNotificationMenu` does:
/// the panel may hold a live 4,000 ms `Timer.periodic`, and `pumpAndSettle`
/// would spin on it until it timed out.
Future<void> pumpChatPanel(
  WidgetTester tester,
  ChatBloc bloc, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 1400);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: BlocProvider<ChatBloc>.value(
                value: bloc,
                child: const ChatPanel(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
