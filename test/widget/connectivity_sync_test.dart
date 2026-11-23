import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:skill_bridge/shared/widgets/connectivity_sync.dart';

import '../helpers/test_app.dart';

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;
  @override
  Widget build(BuildContext context) => TextButton(onPressed: () => setState(() => taps++), child: Text('Taps $taps'));
}

void main() {
  testWidgets('offline: one plain "You\'re offline" line (no yellow); queued actions resend on reconnect', (tester) async {
    final online = StreamController<bool>.broadcast();
    addTearDown(online.close);
    var syncs = 0;

    await tester.pumpWidget(testApp(
      overrides: [connectivityStatusProvider.overrideWith((ref) => online.stream)],
      home: Builder(
        builder: (context) => ConnectivitySync(
          onReconnect: () => syncs++,
          child: const Scaffold(body: Center(child: _Counter())),
        ),
      ),
    ));

    online.add(true);
    await tester.pumpAndSettle();
    expect(syncs, 1, reason: 'first connection sends anything left from last time');
    expect(find.text("You're offline"), findsNothing);

    await tester.tap(find.text('Taps 0'));
    await tester.pump();

    online.add(false);
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.textContaining('No internet connection'), findsNothing);

    // Plain: normal text colour on the normal surface, no warning colours.
    final context = tester.element(find.text("You're offline"));
    final sb = context.sb;
    final text = tester.widget<Text>(find.text("You're offline"));
    expect(text.style!.color, Colors.black);
    final bg = tester.widget<Material>(find.ancestor(of: find.text("You're offline"), matching: find.byType(Material)).first);
    expect(bg.color, sb.surface);
    expect(bg.color, isNot(sb.warningSubtle));

    // The screen underneath keeps its state (nothing is rebuilt from scratch).
    expect(find.text('Taps 1'), findsOneWidget);

    online.add(true);
    await tester.pumpAndSettle();
    expect(syncs, 2);
    expect(find.text("You're offline"), findsNothing);
    expect(find.text('Taps 1'), findsOneWidget);

    online.add(true);
    await tester.pumpAndSettle();
    expect(syncs, 2, reason: 'staying online does not resend');
  });

  testWidgets('screen-level offline notes are plain text too', (tester) async {
    await tester.pumpWidget(testApp(home: const Scaffold(body: SbOfflineNote(message: 'Messages will send when you reconnect.'))));
    final context = tester.element(find.byType(SbOfflineNote));
    final text = tester.widget<Text>(find.text('Messages will send when you reconnect.'));
    expect(text.style!.color, Colors.black);
    expect(context.mounted, isTrue);
    expect(find.descendant(of: find.byType(SbOfflineNote), matching: find.byType(DecoratedBox)), findsNothing);
  });
}
