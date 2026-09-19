import 'package:color_hug/game_audio.dart';
import 'package:color_hug/shanhai/shanhai_model.dart';
import 'package:color_hug/shanhai/shanhai_native.dart';
import 'package:color_hug/shanhai/shanhai_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> advance(WidgetTester t, double seconds) async {
  for (var i = 0; i < (seconds * 20).ceil(); i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> mount(
  WidgetTester t,
  ShanhaiModel m,
  GameAudioController a,
  Size size, {
  ShanhaiNativeController? native,
  double textScale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
    MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(
          c,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ShanhaiScreen(
        audio: a,
        model: m,
        nativeAudio: false,
        nativeController: native,
        stageBuilder: (c, v) => const ColoredBox(color: shanNight),
      ),
    ),
  );
  await t.pump();
}

Future<void> close(
  WidgetTester t,
  ShanhaiModel m,
  GameAudioController a,
) async {
  await t.pumpWidget(const SizedBox());
  await t.pump();
  m.dispose();
  a.dispose();
}

Future<void> wake(WidgetTester t) async {
  final rect = t.getRect(find.byKey(const ValueKey('shan-stage-touch')));
  for (final p in [
    const Offset(.28, .68),
    const Offset(.5, .77),
    const Offset(.73, .65),
  ]) {
    await t.tapAt(rect.topLeft + Offset(p.dx * rect.width, p.dy * rect.height));
    await t.pump();
  }
  await advance(t, 6);
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(640, 520),
    const Size(1024, 768),
    const Size(1280, 820),
  ]) {
    testWidgets('wake feed fly and return at $size', (t) async {
      final m = ShanhaiModel(), a = GameAudioController.silent();
      await mount(t, m, a, size);
      expect(t.takeException(), isNull);
      await wake(t);
      expect(m.phase, ShanPhase.companion);
      await t.tap(find.byKey(const ValueKey('shan-feed')));
      await t.pump();
      expect(m.feeds, 1);
      await t.tap(find.byKey(const ValueKey('shan-fly')));
      await t.pump();
      expect(m.phase, ShanPhase.flying);
      await t.tap(find.byKey(const ValueKey('shan-left')));
      await t.pump();
      expect(m.steering, lessThan(0));
      await t.tap(find.byKey(const ValueKey('shan-end-flight')));
      await t.pump();
      expect(m.phase, ShanPhase.companion);
      expect(t.takeException(), isNull);
      await close(t, m, a);
    });
  }
  testWidgets('one stroke passes three seals; a dragged pearl feeds once', (
    t,
  ) async {
    final m = ShanhaiModel(), a = GameAudioController.silent();
    await mount(t, m, a, const Size(1180, 820));
    final r = t.getRect(find.byKey(const ValueKey('shan-stage-touch')));
    Offset at(double x, double y) =>
        r.topLeft + Offset(r.width * x, r.height * y);
    final g = await t.startGesture(at(.28, .68));
    await g.moveTo(at(.5, .77));
    await t.pump();
    await g.moveTo(at(.73, .65));
    await g.up();
    await advance(t, 6);
    expect(m.phase, ShanPhase.companion);
    final from = t.getCenter(find.byKey(const ValueKey('shan-feed')));
    await t.dragFrom(from, r.center - from);
    await t.pump();
    expect(m.feeds, 1);
    expect(t.takeException(), isNull);
    await close(t, m, a);
  });
  testWidgets('journal and background pause native scene and flight time', (
    t,
  ) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('colorhug/shanhai3d/71');
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      c,
    ) async {
      calls.add(c);
      return null;
    });
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final m = ShanhaiModel(), a = GameAudioController.silent();
    await mount(
      t,
      m,
      a,
      const Size(1180, 820),
      native: ShanhaiNativeController(71),
    );
    await wake(t);
    await t.tap(find.byKey(const ValueKey('shan-fly')));
    await advance(t, 1);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final before = m.flight;
    await advance(t, 2);
    expect(m.flight, before);
    expect(calls.lastWhere((c) => c.method == 'active').arguments, false);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await advance(t, 1);
    expect(m.flight, greaterThan(before));
    await t.tap(find.byKey(const ValueKey('shan-journal')));
    await advance(t, .5);
    final frozen = m.flight;
    await advance(t, 1);
    expect(m.flight, frozen);
    await t.tap(find.byKey(const ValueKey('shan-close-journal')));
    await advance(t, 1);
    expect(m.flight, greaterThan(frozen));
    await close(t, m, a);
    expect(calls.last.method, 'dispose');
  });
  testWidgets('completed trip returns through result overlay and keeps stars', (
    t,
  ) async {
    final m = ShanhaiModel()..setReducedMotion(true),
        a = GameAudioController.silent();
    await mount(t, m, a, const Size(390, 844));
    await wake(t);
    m.startFlight();
    for (var i = 0; i < 850; i++) {
      var next = 0;
      while (next < 7 && ShanhaiModel.gateTime(next) <= m.flight) {
        next++;
      }
      if (next < 7) m.steer(ShanhaiModel.gateSteering(next));
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('星辉入怀，山海同归'), findsOneWidget);
    expect(m.flightStars, 7);
    await t.tap(find.byKey(const ValueKey('shan-return')));
    await t.pump();
    expect(m.phase, ShanPhase.companion);
    expect(m.totalStarlight, 7);
    expect(t.takeException(), isNull);
    await close(t, m, a);
  });
  testWidgets('large text keeps core controls accessible', (t) async {
    final m = ShanhaiModel(), a = GameAudioController.silent();
    await mount(t, m, a, const Size(390, 844), textScale: 1.6);
    await wake(t);
    expect(t.takeException(), isNull);
    await close(t, m, a);
  });
}
