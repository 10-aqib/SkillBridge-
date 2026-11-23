// Loading placeholders: shared left-to-right shimmer, content-shaped blocks,
// smooth hand-over to real content, and reduced motion.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

import '../helpers/test_app.dart';

void main() {
  Widget host(Widget child, {bool reduce = false, TextDirection dir = TextDirection.ltr}) => testApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: Directionality(textDirection: dir, child: Scaffold(body: child)),
          ),
        ),
      );

  testWidgets('a block without a width fills its row, like the content it stands in for', (tester) async {
    await tester.pumpWidget(host(const SizedBox(
      width: 300,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SbSkeleton(height: 12),
        SbSkeleton(width: 120, height: 12),
        SbSkeleton.circle(size: 40),
      ]),
    )));
    final sizes = tester.renderObjectList<RenderBox>(find.byType(SbSkeleton)).map((b) => b.size).toList();
    expect(sizes[0], const Size(300, 12));
    expect(sizes[1], const Size(120, 12));
    expect(sizes[2], const Size(40, 40));
  });

  testWidgets('blocks in a group share one shimmer that moves left to right', (tester) async {
    await tester.pumpWidget(host(const SbSkeletonGroup(
      child: Column(children: [SbSkeleton(height: 12), SbSkeleton(height: 12)]),
    )));
    final shimmers = tester.stateList<SbShimmerState>(find.byType(SbShimmer));
    expect(shimmers, hasLength(1), reason: 'one wave for the whole group');
    final s = shimmers.single;
    await tester.pump(const Duration(milliseconds: 100));
    final p1 = s.progress!;
    await tester.pump(const Duration(milliseconds: 400));
    final p2 = s.progress!;
    expect(p2, greaterThan(p1), reason: 'the highlight travels forward (reading direction)');
  });

  testWidgets('a group announces "Loading" once; blocks are silent', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(SbSkeletonList(item: const SbListRowSkeleton(), count: 3, label: 'Loading')));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('reduced motion: the shimmer stands still', (tester) async {
    await tester.pumpWidget(host(const SbSkeletonGroup(child: SbSkeleton(height: 12)), reduce: true));
    expect(tester.state<SbShimmerState>(find.byType(SbShimmer)).progress, isNull);
    await tester.pumpAndSettle(); // settles: nothing is animating
  });

  testWidgets('a standalone card keeps all its blocks on one shimmer', (tester) async {
    await tester.pumpWidget(host(const SbListRowSkeleton()));
    expect(find.byType(SbShimmer), findsOneWidget);
  });

  testWidgets('content cross-fades in over the placeholder, in the same slot', (tester) async {
    Widget page(bool loading) => host(SbLoadSwitcher(
          loading: loading,
          child: loading ? const SbSkeleton(height: 40) : const Text('Loaded content'),
        ));
    await tester.pumpWidget(page(true));
    await tester.pumpWidget(page(false));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-fade: both are on screen, the old one fading out.
    expect(find.text('Loaded content'), findsOneWidget);
    expect(find.byType(SbSkeleton), findsOneWidget);
    expect(tester.getTopLeft(find.text('Loaded content')).dy, tester.getTopLeft(find.byType(SbSkeleton)).dy);
    await tester.pump(SbLoadSwitcher.duration);
    expect(find.byType(SbSkeleton), findsNothing);
    expect(find.text('Loaded content'), findsOneWidget);
  });

  testWidgets('page placeholders keep short bars short (a title bar is not a full line)', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const SbDetailSkeleton()));
    final first = tester.renderObjectList<RenderBox>(find.byType(SbSkeleton)).first;
    expect(first.size.width, 90);
    await tester.pumpWidget(host(const SbProfileSkeleton()));
    final name = tester.renderObjectList<RenderBox>(find.byType(SbSkeleton)).elementAt(1);
    expect(name.size.width, 170);
  });

  testWidgets('presets build in light and dark without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final b in Brightness.values) {
      await tester.pumpWidget(testApp(
        brightness: b,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              SbNotificationSkeleton(),
              SbListRowSkeleton(),
              SizedBox(height: 520, child: SbDetailSkeleton()),
              SizedBox(height: 520, child: SbProfileSkeleton()),
            ]),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: b.name);
    }
  });
}
