import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:skill_bridge/features/notifications/data/models/notification_model.dart';
import 'package:skill_bridge/features/notifications/data/services/push_notification_service.dart';
import 'package:skill_bridge/features/notifications/presentation/notification_routes.dart';
import 'package:skill_bridge/features/notifications/presentation/providers/notification_providers.dart';
import 'package:skill_bridge/features/notifications/presentation/screens/notification_screen.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

import '../helpers/job_fixtures.dart';
import '../helpers/test_app.dart';

// Notification centre and push routing (Phase G5).

class _Source extends Fake implements NotificationRemoteDataSource {
  final calls = <String>[];
  @override
  Future<void> markAsRead(String notificationId) async => calls.add('read:$notificationId');
  @override
  Future<int> markAllAsRead(String userId) async {
    calls.add('readAll:$userId');
    return 1;
  }

  @override
  Future<void> delete(String notificationId) async => calls.add('delete:$notificationId');
}

NotificationModel _n(String id, {bool read = false, String type = 'message', Map<String, dynamic>? payload}) => NotificationModel(
      id: id,
      userId: 'w1',
      title: 'Title $id',
      body: 'Body $id',
      payload: payload ?? {'chatId': 'j1_w1'},
      createdAt: DateTime(2026, 11, 20, 10),
      isRead: read,
      type: type,
    );

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await englishStrings());

  group('where a notification leads', () {
    test('message → chat; contract step → contract; proposal → the job\'s proposals; job update → the job', () {
      expect(notificationRouteFor({'chatId': 'j1_w1'}, type: 'message'), RouteNames.chatRoomLocation('j1_w1'));
      expect(notificationRouteFor({'contractId': 'k1', 'jobId': 'j1'}, type: 'work_started'), RouteNames.contractDetailsLocation('k1'));
      expect(notificationRouteFor({'jobId': 'j1', 'proposalId': 'j1_w1'}, type: 'proposal'), RouteNames.jobProposalsLocation('j1'));
      expect(notificationRouteFor({'jobId': 'j1', 'proposalId': 'j1_w1'}), RouteNames.jobProposalsLocation('j1'), reason: 'old item, no type');
      expect(notificationRouteFor({'jobId': 'j1'}, type: 'job'), RouteNames.jobDetailsLocation('j1'));
    });

    test('crafted ids never build a route', () {
      expect(notificationRouteFor({'jobId': '../admin'}), isNull);
      expect(notificationRouteFor({'chatId': 'a/b'}, type: 'message'), isNull);
      expect(notificationRouteFor(null), isNull);
      expect(notificationRouteFor({}), isNull);
    });
  });

  group('push tokens per device', () {
    test('adds this device, replaces a refreshed token, keeps at most 10 (newest first)', () {
      final now = Timestamp.fromMillisecondsSinceEpoch(5000);
      expect(PushTokenStore.nextTokens(null, 'T1', now: now).keys, ['T1']);
      final current = {
        for (var i = 0; i < 12; i++) 'old$i': {'platform': 'android', 'updatedAt': Timestamp.fromMillisecondsSinceEpoch(i * 100)},
      };
      final next = PushTokenStore.nextTokens(current, 'NEW', now: now);
      expect(next.length, PushTokenStore.maxDevices);
      expect(next.containsKey('NEW'), isTrue);
      expect(next.containsKey('old11'), isTrue, reason: 'most recent kept');
      expect(next.containsKey('old0'), isFalse, reason: 'oldest dropped');
      final refreshed = PushTokenStore.nextTokens({'A': {'platform': 'android'}, 'B': {'platform': 'android'}}, 'C', previous: 'A', now: now);
      expect(refreshed.keys.toSet(), {'B', 'C'});
    });
  });

  group('notification centre', () {
    late _Source source;
    late StreamController<List<NotificationModel>> items;

    Future<void> open(WidgetTester tester) async {
      source = _Source();
      items = StreamController<List<NotificationModel>>();
      addTearDown(() {
        items.close();
      });
      final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => NotificationScreen())]);
      addTearDown(router.dispose);
      await tester.pumpWidget(testRouterApp(
        router: router,
        overrides: [
          currentUserProvider.overrideWith((ref) => testUser('w1', role: 'worker')),
          notificationRemoteDataSourceProvider.overrideWithValue(source),
          userNotificationsStreamProvider('w1').overrideWith((ref) => items.stream),
        ],
      ));
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('empty, then items; "mark all as read" only while something is unread', (tester) async {
      await open(tester);
      items.add([]);
      await settle(tester);
      expect(find.text('No Notifications Yet'), findsOneWidget);
      expect(find.byTooltip('Mark all as read'), findsNothing);
      items.add([_n('a'), _n('b', read: true)]);
      await settle(tester);
      expect(find.text('Title a'), findsOneWidget);
      await tester.tap(find.byTooltip('Mark all as read'));
      await settle(tester);
      expect(source.calls, ['readAll:w1']);
      items.add([_n('a', read: true), _n('b', read: true)]);
      await settle(tester);
      expect(find.byTooltip('Mark all as read'), findsNothing);
    });

    testWidgets('swipe deletes that notification', (tester) async {
      await open(tester);
      items.add([_n('a'), _n('b')]);
      await settle(tester);
      await tester.drag(find.text('Title a'), const Offset(-600, 0));
      await settle(tester);
      expect(source.calls, ['delete:a']);
      expect(find.text('Title a'), findsNothing);
    });

    testWidgets('a load error offers to try again', (tester) async {
      await open(tester);
      items.addError(Exception('offline'));
      await settle(tester);
      expect(find.text(l.errNetwork), findsOneWidget);
      expect(find.text(l.tryAgain), findsOneWidget);
    });
  });
}
