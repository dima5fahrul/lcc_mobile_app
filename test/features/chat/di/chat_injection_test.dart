/// **B9-AC-12** — the chat's DI, and the one ordering constraint it introduces.
///
/// Every registration is *resolved* here, not merely checked for presence:
/// `isRegistered` returns true for a factory that throws the moment it runs,
/// and this feature's factory reaches into a **second container** — so a
/// presence check is exactly the check that would miss the defect.
///
/// ## The ordering is the point
///
/// `ChatUsecaseInjection` re-exports `GetSupportChannels` out of
/// `helpInjection` (specs.md § 6.6), so `HelpFeatureInjection.init()` must have
/// run first. Every registration is lazy, so a wrong order does not fail at
/// registration — it fails at the first resolution, i.e. the first time a
/// citizen taps the launcher. That is why the order is asserted here rather
/// than trusted to the comment at `dependency_injection.dart` step 11.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_feature_injection.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_injection.dart';
import 'package:lcc_mobile_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:lcc_mobile_app/features/chat/domain/usecases/chat_usecases.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:lcc_mobile_app/features/help/di/help_feature_injection.dart';
import 'package:lcc_mobile_app/features/help/di/help_injection.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';

import '../../../helpers/core_test_helper.dart';

void main() {
  Future<void> registerRoot() async {
    injection.registerLazySingleton<StorageService>(
      () => inMemoryStorageService(<String, String>{}),
    );
    injection.registerLazySingleton<ApiClient>(
      () => ApiClient(
        dio: buildTestDio(
          storage: injection<StorageService>(),
          adapter: RecordingHttpAdapter.always(<String, dynamic>{}),
          withInterceptors: false,
        ),
        storage: injection<StorageService>(),
      ),
    );
  }

  setUp(() async {
    await injection.reset();
    await helpInjection.reset();
    await chatInjection.reset();
    await registerRoot();
  });

  tearDown(() async {
    await injection.reset();
    await helpInjection.reset();
    await chatInjection.reset();
  });

  group('with help registered first — the production order', () {
    setUp(() async {
      await HelpFeatureInjection.init();
      await ChatFeatureInjection.init();
    });

    test('DI-3 — the feature shares the ROOT ApiClient, it does not build a '
        'second Dio', () {
      expect(chatInjection<ApiClient>(), same(injection<ApiClient>()),
          reason: 'all six chat calls are authenticated `/me/*` requests, so '
              'they need the Auth/Refresh interceptor chain that lives inside '
              'the root client');
    });

    test('DI-2 — every registration is lazy and resolves', () {
      expect(chatInjection<ChatRemoteDatasource>(),
          isA<ChatRemoteDatasourceImpl>());
      expect(chatInjection<ChatRepository>(), isA<ChatRepository>());
      expect(chatInjection<GetChatThreads>(), isA<GetChatThreads>());
      expect(chatInjection<GetChatMessages>(), isA<GetChatMessages>());
      expect(chatInjection<StartChatThread>(), isA<StartChatThread>());
      expect(chatInjection<SendChatMessage>(), isA<SendChatMessage>());
      expect(chatInjection<MarkThreadRead>(), isA<MarkThreadRead>());
      expect(chatInjection<CloseChatThread>(), isA<CloseChatThread>());
    });

    test('the repository and the use cases are SINGLETONS — resolving twice '
        'gives the same object', () {
      expect(chatInjection<ChatRepository>(),
          same(chatInjection<ChatRepository>()));
      expect(chatInjection<GetChatThreads>(),
          same(chatInjection<GetChatThreads>()));
    });

    test('§ 6.6 — `GetSupportChannels` is RE-EXPORTED, not re-implemented: it '
        'is the SAME instance help holds', () {
      expect(
        chatInjection<GetSupportChannels>(),
        same(helpInjection<GetSupportChannels>()),
        reason: 'a second instance would mean a second parse of '
            '/help/channels; `same` is what distinguishes a re-export from a '
            'duplicate (B9-AC-43)',
      );
    });

    test('the BLoC is a FACTORY — a fresh one per shell build', () {
      final ChatBloc first = chatInjection<ChatBloc>();
      final ChatBloc second = chatInjection<ChatBloc>();
      addTearDown(first.close);
      addTearDown(second.close);

      expect(first, isNot(same(second)),
          reason: 'the BLoC holds one citizen\'s transcript, composer text and '
              '`ended` set — and a live poll timer. A surviving instance would '
              'hand all four to whoever signs in next on the same device.');
    });

    test('the BLoC actually CONSTRUCTS — the check `isRegistered` cannot make',
        () {
      final ChatBloc bloc = chatInjection<ChatBloc>();
      addTearDown(bloc.close);

      // Its `getSupportChannels` closure reaches into the OTHER container, so
      // resolving it is what proves the cross-container wiring rather than the
      // registration.
      expect(bloc.getSupportChannels, same(helpInjection<GetSupportChannels>()));
      expect(bloc.state, const ChatState());
      expect(bloc.isPolling, isFalse, reason: 'no timer until the gate opens');
    });
  });

  group('the ordering constraint', () {
    test('registering chat BEFORE help leaves a container that registers fine '
        'and THROWS on first use — which is why the order is asserted rather '
        'than commented', () async {
      // Deliberately the wrong order. Nothing fails here: every registration
      // is lazy.
      await ChatFeatureInjection.init();
      expect(chatInjection.isRegistered<ChatBloc>(), isTrue,
          reason: 'registration succeeds — this is the trap');

      // The failure is deferred to the first citizen who taps the launcher.
      expect(
        () => chatInjection<ChatBloc>(),
        throwsA(isA<Error>()),
        reason: 'DI-6\'s "one alphabetical line" would put `chat` before '
            '`help`. The alphabetical rule yields, and `dependency_injection.'
            'dart` step 11 states the deviation at the call site.',
      );
    });

    test('the real `DependencyInjection.init()` puts them in the right order',
        () async {
      // The end-to-end check: boot the whole container graph the way the app
      // does and resolve the thing that depends on the order.
      await injection.reset();
      await helpInjection.reset();
      await chatInjection.reset();

      await const DependencyInjection().init();
      addTearDown(() async {
        await injection.reset();
        await helpInjection.reset();
        await chatInjection.reset();
      });

      final ChatBloc bloc = chatInjection<ChatBloc>();
      addTearDown(bloc.close);
      expect(bloc.getSupportChannels, same(helpInjection<GetSupportChannels>()));
    });
  });

  group('DI-1 — the root container is unchanged', () {
    setUp(() async {
      await HelpFeatureInjection.init();
      await ChatFeatureInjection.init();
    });

    test('nothing chat-shaped was registered on the root', () {
      expect(injection.isRegistered<ChatRepository>(), isFalse);
      expect(injection.isRegistered<ChatBloc>(), isFalse);
      expect(injection.isRegistered<GetChatThreads>(), isFalse);
    });
  });
}
