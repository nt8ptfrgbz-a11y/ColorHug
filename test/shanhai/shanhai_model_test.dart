import 'dart:convert';
import 'package:color_hug/shanhai/shanhai_model.dart';
import 'package:flutter_test/flutter_test.dart';

void advance(ShanhaiModel m, double seconds) {
  for (var i = 0; i < (seconds * 20).ceil(); i++) {
    m.advance(.05);
  }
}

void wake(ShanhaiModel m) {
  for (var i = 0; i < 3; i++) {
    m.traceSeal(i);
  }
  advance(m, 6);
}

void main() {
  test('three distinct seals wake the dragon exactly once', () {
    final m = ShanhaiModel();
    expect(m.traceSeal(-1), isFalse);
    expect(m.traceSeal(0), isTrue);
    expect(m.traceSeal(0), isFalse);
    m.traceSeal(2);
    expect(m.phase, ShanPhase.sleeping);
    m.traceSeal(1);
    expect(m.phase, ShanPhase.awakening);
    advance(m, 6);
    expect(m.phase, ShanPhase.companion);
    expect(m.awakened, isTrue);
    expect(m.visited, {ShanRealm.moon});
    expect(m.traceSeal(0), isFalse);
    m.dispose();
  });

  test('pet and feed cooldowns protect rapid repeated input', () {
    final m = ShanhaiModel();
    expect(m.feed(), isFalse);
    wake(m);
    expect(m.feed(), isTrue);
    expect(m.feed(), isFalse);
    expect(m.pet(), isTrue);
    expect(m.pet(), isFalse);
    expect(m.affection, 4);
    advance(m, 3);
    expect(m.feed(), isTrue);
    expect(m.feeds, 2);
    m.dispose();
  });

  test(
    'all seven real gates are reachable and a completed flight counts once',
    () {
      final m = ShanhaiModel();
      wake(m);
      m.startFlight();
      for (var step = 0; step < 850; step++) {
        var next = 0;
        while (next < 7 && ShanhaiModel.gateTime(next) <= m.flight) {
          next++;
        }
        if (next < 7) m.steer(ShanhaiModel.gateSteering(next));
        m.advance(.05);
      }
      expect(m.phase, ShanPhase.arrival);
      expect(m.flightStars, 7);
      expect(m.totalStarlight, 7);
      expect(m.flights, 1);
      advance(m, 20);
      expect(m.flights, 1);
      m.returnToLake();
      expect(m.phase, ShanPhase.companion);
      expect(m.steering, 0);
      m.dispose();
    },
  );

  test(
    'missed gates are not credited and early return does not award a full flight',
    () {
      final m = ShanhaiModel();
      wake(m);
      m.startFlight();
      m.steer(-1);
      advance(m, 3);
      expect(m.flightStars, 0);
      m.returnToLake();
      expect(m.flights, 0);
      expect(m.totalStarlight, 0);
      m.dispose();
    },
  );

  test(
    'realm changes are blocked during flight; progress survives a restart',
    () {
      final m = ShanhaiModel();
      wake(m);
      m.setRealm(ShanRealm.stars);
      m.feed();
      m.startFlight();
      m.setRealm(ShanRealm.dawn);
      expect(m.realm, ShanRealm.stars);
      advance(m, 43);
      final restored = ShanhaiModel()..restore(m.encode());
      expect(restored.phase, ShanPhase.companion);
      expect(restored.flights, 1);
      expect(restored.visited, contains(ShanRealm.stars));
      expect(restored.feeds, 1);
      m.dispose();
      restored.dispose();
    },
  );

  test('invalid saves and nonfinite controls cannot break scene values', () {
    final m = ShanhaiModel();
    m.restore('{');
    m.restore('null');
    m.restore(
      jsonEncode({
        'version': 1,
        'awakened': true,
        'realm': 999,
        'flights': -12,
        'visited': [8, null, 1],
      }),
    );
    expect(m.realm, ShanRealm.dawn);
    expect(m.flights, 0);
    expect(m.visited, {ShanRealm.stars});
    m.turn(double.nan);
    m.startFlight();
    m.steer(double.infinity);
    m.advance(double.nan);
    expect(m.steering, 0);
    expect(m.flight, 0);
    m.dispose();
  });

  test('pending writes stay ordered after a storage failure', () async {
    final writes = <String>[];
    final m = ShanhaiModel(
      save: (s) async {
        writes.add(s);
        if (writes.length == 1) throw StateError('unavailable');
      },
    );
    wake(m);
    m.feed();
    m.setReducedMotion(true);
    await m.flush();
    final restored = ShanhaiModel()..restore(writes.last);
    expect(restored.feeds, 1);
    expect(restored.reducedMotion, isTrue);
    m.dispose();
    restored.dispose();
  });
}
