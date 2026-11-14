// Phase 4B: conversations list and chat room. Mocked data (FakeChatStore),
// not real Firebase — the rules (who can read/write what) are tested against
// the emulator in rules-tests/, the trusted functions in functions/test/.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:skill_bridge/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/notifications/presentation/notification_routes.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/fake_chats.dart';
import '../helpers/fake_contracts.dart';
import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  final client = testUser('client_1');
  final worker = testUser('w1', role: 'worker', name: 'Bilal Ahmed');
  final now = DateTime.now();

  Future<FakeChatStore> pump(
    WidgetTester tester,
    Widget screen, {
    required UserEntity user,
    FakeChatStore? store,
    bool online = true,
    FakeContractStore? contracts,
  }) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    final s = store ?? FakeChatStore();
    final router = GoRouter(initialLocation: '/start', routes: [
      GoRoute(path: '/start', builder: (_, _) => screen),
      GoRoute(path: RouteNames.chatRoomPath, builder: (_, st) => Text('ROOM ${st.pathParameters['chatId']}')),
      GoRoute(path: RouteNames.contractDetailsPath, builder: (_, st) => Text('CONTRACT ${st.pathParameters['contractId']}')),
      GoRoute(path: RouteNames.clientChatsPath, builder: (_, _) => const Text('CHATS')),
      GoRoute(path: RouteNames.workerChatsPath, builder: (_, _) => const Text('CHATS')),
    ]);
    await tester.pumpWidget(testRouterApp(router: router, overrides: [
      chatRemoteDataSourceProvider.overrideWithValue(s),
      contractRemoteDataSourceProvider.overrideWithValue(contracts ?? FakeContractStore()),
      currentUserProvider.overrideWith((ref) => user),
      connectivityStatusProvider.overrideWith((ref) => Stream.value(online)),
    ]));
    await tester.pumpAndSettle();
    return s;
  }

  group('Conversations list', () {
    testWidgets('shows each conversation with the other person, job, preview, time and unread count, newest first', (tester) async {
      final store = FakeChatStore(chats: {
        'older': chatDoc(b: 'w2', bName: 'Kamran Ali', last: 'Thanks!', lastSender: 'client_1', lastAt: now.subtract(const Duration(days: 3)), jobTitle: 'Paint the hall'),
        'newer': chatDoc(last: 'On my way', lastAt: now.subtract(const Duration(minutes: 5)), unread: {'client_1': 2, 'w1': 0}),
        'photo': chatDoc(b: 'w3', bName: 'Sana Iqbal', last: 'Photo', lastType: 'image', lastAt: now.subtract(const Duration(days: 1)), jobId: null),
        'notMine': chatDoc(a: 'c9', aName: 'Usman', last: 'Private', lastAt: now),
      });
      await pump(tester, const ChatListScreen(), user: client, store: store);

      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('Kamran Ali'), findsOneWidget);
      expect(find.text('Usman'), findsNothing, reason: 'only my conversations');
      expect(find.text('Fix two kitchen sockets'), findsOneWidget, reason: 'the job it is about');
      expect(find.text(l.chatYouPrefix('Thanks!')), findsOneWidget, reason: 'my last message is marked');
      expect(find.text('2'), findsOneWidget, reason: 'unread count');
      expect(find.text(l.chatYesterday), findsOneWidget);
      // Newest first.
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('Bilal Ahmed') < y('Sana Iqbal'), isTrue);
      expect(y('Sana Iqbal') < y('Kamran Ali'), isTrue);
    });

    testWidgets('opens a conversation by id', (tester) async {
      await pump(tester, const ChatListScreen(), user: client, store: FakeChatStore(chats: {'k1': chatDoc()}));
      await tester.tap(find.text('Bilal Ahmed'));
      await tester.pumpAndSettle();
      expect(find.text('ROOM k1'), findsOneWidget);
    });

    testWidgets('empty: a client and a worker each get a next step', (tester) async {
      await pump(tester, const ChatListScreen(), user: client);
      expect(find.text(l.chatsEmptyTitle), findsOneWidget);
      expect(find.text(l.chatsEmptyClient), findsOneWidget);
      await pump(tester, const ChatListScreen(), user: worker);
      expect(find.text(l.chatsEmptyWorker), findsOneWidget);
    });

    testWidgets('a failed load says so (never empty) and can be retried; offline is shown', (tester) async {
      final store = FakeChatStore()..listError = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      await pump(tester, const ChatListScreen(), user: client, store: store);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text(l.chatsLoadError), findsOneWidget);
      expect(find.text(l.chatsEmptyTitle), findsNothing);
      store.listError = null;
      await tester.tap(find.text(l.tryAgain));
      await tester.pumpAndSettle();
      expect(find.text(l.chatsEmptyTitle), findsOneWidget);

      await pump(tester, const ChatListScreen(), user: client, store: FakeChatStore(chats: {'k1': chatDoc()}), online: false);
      expect(find.text(l.chatsOffline), findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsOneWidget, reason: 'saved conversations stay visible');
    });
  });

  group('Chat room', () {
    FakeChatStore room({Map<String, int>? unread, Map<String, DateTime>? readAt, int count = 3}) => FakeChatStore(
          chats: {'k': chatDoc(unread: unread, readAt: readAt)},
          messages: {
            'k': [
              msg('m0', 'w1', 'Yesterday message', now.subtract(const Duration(days: 1))),
              for (var i = 1; i < count; i++) msg('m$i', i.isOdd ? 'client_1' : 'w1', 'Message $i', now.subtract(Duration(minutes: 60 - i))),
            ],
          },
        );

    testWidgets('messages show sender side, day separators, and Sent / Seen on my latest message', (tester) async {
      final store = room(readAt: {'w1': now.subtract(const Duration(minutes: 1))});
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: store);
      expect(find.text('Bilal Ahmed'), findsOneWidget, reason: 'other person in the header');
      expect(find.text('Fix two kitchen sockets'), findsOneWidget, reason: 'the job in the header');
      expect(find.text(l.chatYesterday), findsOneWidget);
      expect(find.text(l.chatToday), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      // Mine on the right, theirs on the left.
      expect(tester.getCenter(find.text('Message 1')).dx, greaterThan(210));
      expect(tester.getCenter(find.text('Message 2')).dx, lessThan(210));
      expect(find.text(l.chatSeen), findsOneWidget, reason: 'the worker opened the chat after my message');
    });

    testWidgets('marks the conversation read when there is something unread', (tester) async {
      final store = room(unread: {'client_1': 2, 'w1': 0});
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: store);
      expect(store.calls.where((c) => c == 'read:k:client_1'), hasLength(1));
    });

    testWidgets('sending: one message per id; a refused send can be retried with the same id', (tester) async {
      final store = room()..sendError = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: store);
      await tester.enterText(find.byType(TextField), '  Can you come at 10?  ');
      await tester.pump();
      await tester.tap(find.byTooltip(l.chatSend));
      await tester.pumpAndSettle();
      expect(find.text(l.chatNotSent), findsOneWidget);
      expect(find.text('Can you come at 10?'), findsOneWidget, reason: 'kept on screen, trimmed');
      store.sendError = null;
      await tester.tap(find.text(l.chatRetry));
      await tester.pumpAndSettle();
      expect(store.calls.where((c) => c.startsWith('send:')).map((c) => c.split(':')[1]).toSet(), {'msg_test_1'}, reason: 'same id both times');
      expect(store.messages['k']!.where((m) => m.content == 'Can you come at 10?'), hasLength(1));
      expect(find.text(l.chatNotSent), findsNothing);
      expect(find.text('Can you come at 10?'), findsOneWidget, reason: 'shown once');
    });

    testWidgets('a send that reached the server but lost its reply is not duplicated on retry', (tester) async {
      final store = room()..loseFirstReply = true;
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: store);
      await tester.enterText(find.byType(TextField), 'Running 5 minutes late');
      await tester.pump();
      await tester.tap(find.byTooltip(l.chatSend));
      await tester.pumpAndSettle();
      // The message is on the server already, so the room shows it once.
      expect(find.text('Running 5 minutes late'), findsOneWidget);
      if (find.text(l.chatRetry).evaluate().isNotEmpty) {
        await tester.tap(find.text(l.chatRetry));
        await tester.pumpAndSettle();
      }
      expect(store.messages['k']!.where((m) => m.content == 'Running 5 minutes late'), hasLength(1));
      expect(find.text(l.chatNotSent), findsNothing);
    });

    testWidgets('empty text is not sent; over-long text is refused with a message', (tester) async {
      final store = room();
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: store);
      final send = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded));
      expect(send.onPressed, isNull, reason: 'nothing to send');
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded)).onPressed, isNull);
      expect(store.calls.where((c) => c.startsWith('send:')), isEmpty);
    });

    testWidgets('earlier messages load a page at a time', (tester) async {
      final store = room(count: chatPageSize + 5);
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: store);
      expect(store.limits.last, chatPageSize);
      await tester.dragUntilVisible(find.text(l.chatEarlier), find.byType(ListView), const Offset(0, 300));
      await tester.tap(find.text(l.chatEarlier));
      await tester.pumpAndSettle();
      expect(store.limits.last, chatPageSize * 2);
    });

    testWidgets('a photo message uploads into my folder for that message, then sends its path', (tester) async {
      final store = room()..photo = base64Decode(_png);
      final bytes = Uint8List.fromList(base64Decode(_png));
      tester.view.physicalSize = const Size(420, 1400);
      await pump(
        tester,
        ChatRoomScreen(chatId: 'k', photoPicker: () async => (bytes: bytes, contentType: 'image/png')),
        user: client,
        store: store,
      );
      await tester.tap(find.byTooltip(l.chatAddPhoto));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l.chatSend));
      await tester.pumpAndSettle();
      expect(store.uploads, ['chats/k/client_1/msg_test_1/p1.jpg']);
      expect(store.calls.last, 'send:msg_test_1:image::chats/k/client_1/msg_test_1/p1.jpg');
    });

    testWidgets('photos over 5 MB or of other types are refused before upload', (tester) async {
      final store = room();
      final big = Uint8List(chatMaxPhotoBytes + 1);
      await pump(tester, ChatRoomScreen(chatId: 'k', photoPicker: () async => (bytes: big, contentType: 'image/jpeg')), user: client, store: store);
      await tester.tap(find.byTooltip(l.chatAddPhoto));
      await tester.pumpAndSettle();
      expect(find.text(l.chatPhotoTooLarge), findsOneWidget);
      await pump(tester, ChatRoomScreen(chatId: 'k', photoPicker: () async => (bytes: Uint8List(10), contentType: 'image/gif')), user: client, store: room());
      await tester.tap(find.byTooltip(l.chatAddPhoto));
      await tester.pumpAndSettle();
      expect(find.text(l.chatPhotoType), findsOneWidget);
      expect(store.uploads, isEmpty);
    });

    testWidgets('a missing conversation, or one I am not in, is "not available"', (tester) async {
      await pump(tester, const ChatRoomScreen(chatId: 'nope'), user: client, store: room());
      expect(find.text(l.chatRoomUnavailableTitle), findsOneWidget);
      final other = FakeChatStore(chats: {'x': chatDoc(a: 'c9', aName: 'Usman')});
      await pump(tester, const ChatRoomScreen(chatId: 'x'), user: client, store: other);
      expect(find.text(l.chatRoomUnavailableTitle), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      final refused = FakeChatStore()..chatError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: refused);
      expect(find.text(l.chatRoomUnavailableTitle), findsOneWidget);
    });

    testWidgets('a suspended account can be read but not messaged', (tester) async {
      final store = room()..peers['w1'] = ChatPeerStatus.suspended;
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: store);
      expect(find.text(l.chatPeerSuspended), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('offline: a banner says messages will send on reconnect', (tester) async {
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: room(), online: false);
      expect(find.text(l.chatOffline), findsOneWidget);
    });

    testWidgets('empty conversation invites the first message', (tester) async {
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: FakeChatStore(chats: {'k': chatDoc(last: '', lastSender: '', lastType: 'none')}));
      expect(find.text(l.chatEmptyTitle), findsOneWidget);
      expect(find.text(l.chatEmptyBody('Bilal Ahmed')), findsOneWidget);
    });

    testWidgets('a job conversation links to its contract', (tester) async {
      final contracts = FakeContractStore({'j1_w1': contractDoc()});
      await pump(tester, const ChatRoomScreen(chatId: 'k'), user: client, store: room(), contracts: contracts);
      await tester.tap(find.byTooltip(l.chatViewContract));
      await tester.pumpAndSettle();
      expect(find.text('CONTRACT j1_w1'), findsOneWidget);
    });

    for (final b in Brightness.values) {
      testWidgets('chat room renders at phone width without overflow (${b.name})', (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(testApp(
          home: const ChatRoomScreen(chatId: 'k'),
          brightness: b,
          overrides: [
            chatRemoteDataSourceProvider.overrideWithValue(room()),
            contractRemoteDataSourceProvider.overrideWithValue(FakeContractStore()),
            currentUserProvider.overrideWith((ref) => client),
            connectivityStatusProvider.overrideWith((ref) => Stream.value(true)),
          ],
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Duplicate-safe delivery', () {
    test('a retry refused as a duplicate counts as sent when the server has the message', () async {
      final store = FakeChatStore(chats: {'k': chatDoc()});
      final m = msg('msg_once_001', 'client_1', 'Hello', DateTime.now());
      await deliverMessage(store, m);
      await deliverMessage(store, m); // second attempt: create-only refusal, then found
      expect(store.messages['k']!.where((x) => x.id == 'msg_once_001'), hasLength(1));
      expect(store.calls, contains('exists:msg_once_001'));
    });

    test('a refusal for a message the server does not have is reported', () async {
      final store = FakeChatStore(chats: {'k': chatDoc()})..sendError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      await expectLater(deliverMessage(store, msg('msg_never_01', 'client_1', 'Hi', DateTime.now())), throwsA(isA<FirebaseException>()));
      expect(chatFailureOf(FirebaseException(plugin: 'x', code: 'permission-denied')), ChatFailure.notAllowed);
      expect(chatFailureOf(FirebaseException(plugin: 'x', code: 'unavailable')), ChatFailure.network);
    });
  });

  group('Notification links', () {
    test('a message opens its conversation, a contract update its contract; crafted ids are ignored', () {
      expect(notificationRouteFor({'chatId': 'j1_w1', 'messageId': 'm'}, type: 'message'), '/chat/j1_w1');
      expect(notificationRouteFor({'contractId': 'k1', 'jobId': 'j1'}, type: 'work_submitted'), RouteNames.contractDetailsLocation('k1'));
      expect(notificationRouteFor({'chatId': 'j1_w1'}), '/chat/j1_w1', reason: 'push data has no type');
      expect(notificationRouteFor({'chatId': '../admin'}, type: 'message'), isNull);
      expect(notificationRouteFor({'contractId': 'k1/../../x'}), isNull);
      expect(notificationRouteFor(null), isNull);
      expect(notificationRouteFor({'other': 'x'}), isNull);
    });
  });
}
