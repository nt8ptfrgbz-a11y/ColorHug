import 'dart:convert';
import 'package:color_hug/seed_lab/seed_model.dart';
import 'package:flutter_test/flutter_test.dart';

PlantDiscovery grow(SeedLabModel m, SeedKind seed, Nutrient a, Nutrient b) {
  m.newPot();
  m.selectSeed(seed);
  m.add(a);
  m.add(b);
  expect(m.startGrowing(), isTrue);
  m.finishGrowing();
  return m.result!;
}

void main() {
  test(
    'all 30 recipes are discoverable and reverse order does not duplicate',
    () {
      final m = SeedLabModel();
      for (final seed in SeedKind.values) {
        for (final a in Nutrient.values) {
          for (final b in Nutrient.values) {
            grow(m, seed, a, b);
          }
        }
      }
      expect(m.baseCount, 30);
      expect(m.discoveries.map((p) => p.name).toSet(), hasLength(30));
      expect(m.experiments, 48);
      final a = grow(m, SeedKind.tree, Nutrient.music, Nutrient.moon);
      final b = grow(m, SeedKind.tree, Nutrient.moon, Nutrient.music);
      expect(a.toJson(), b.toJson());
      m.dispose();
    },
  );

  test(
    'requires two ingredients, rejects actions during growth and finishes once',
    () {
      final m = SeedLabModel();
      expect(m.startGrowing(), isFalse);
      m.add(Nutrient.moon);
      expect(m.startGrowing(), isFalse);
      m.add(Nutrient.soda);
      expect(m.add(Nutrient.music), isFalse);
      expect(m.startGrowing(), isTrue);
      m.selectSeed(SeedKind.tree);
      m.removeLast();
      m.newPot();
      expect(m.seed, SeedKind.mushroom);
      expect(m.ingredients, hasLength(2));
      expect(m.phase, LabPhase.growing);
      expect(m.finishGrowing(), isTrue);
      expect(m.finishGrowing(), isFalse);
      expect(m.experiments, 1);
      m.dispose();
    },
  );

  test(
    'restores discoveries, recipe and reduced motion; incomplete growth is resumable',
    () {
      final m = SeedLabModel();
      grow(m, SeedKind.flower, Nutrient.rainbow, Nutrient.music);
      m.setReducedMotion(true);
      final restored = SeedLabModel()..restore(m.encode());
      expect(restored.result!.id, m.result!.id);
      expect(restored.phase, LabPhase.grown);
      expect(restored.discoveries, hasLength(1));
      expect(restored.reducedMotion, isTrue);
      m.newPot();
      m.add(Nutrient.soda);
      m.add(Nutrient.soda);
      m.startGrowing();
      restored.restore(m.encode());
      expect(restored.ready, isTrue);
      expect(restored.phase, LabPhase.planting);
      expect(restored.discoveries, hasLength(1));
      m.dispose();
      restored.dispose();
    },
  );

  test(
    'crossing requires known distinct base plants and has stable identity',
    () {
      final m = SeedLabModel();
      final a = grow(m, SeedKind.tree, Nutrient.moon, Nutrient.moon);
      final b = grow(m, SeedKind.flower, Nutrient.music, Nutrient.rainbow);
      expect(m.cross(a, a), isFalse);
      expect(m.cross(a, b), isTrue);
      expect(m.ready, isTrue);
      expect(m.isHybrid, isTrue);
      final hybridId = m.result!.id;
      m.startGrowing();
      m.finishGrowing();
      final hybrid = m.result!;
      expect(m.cross(a, hybrid), isFalse);
      m.newPot();
      expect(m.cross(b, a), isTrue);
      expect(m.result!.id, hybridId);
      m.startGrowing();
      expect(m.finishGrowing(), isFalse);
      expect(m.baseCount, 2);
      expect(m.discoveries, hasLength(3));
      final restored = SeedLabModel()..restore(m.encode());
      expect(restored.isHybrid, isTrue);
      expect(restored.result!.id, hybridId);
      m.dispose();
      restored.dispose();
    },
  );

  test(
    'corrupted and out-of-range saves cannot crash or unlock invalid discoveries',
    () {
      final m = SeedLabModel();
      m.restore('{broken');
      m.restore('[]');
      m.restore(
        jsonEncode({
          'version': 1,
          'seed': 999,
          'ingredients': [null, -1, 90, 2],
          'discoveries': [
            {'seed': 8, 'first': 0, 'second': 0},
            null,
          ],
          'parents': ['unknown', 'other'],
          'experiments': -8,
          'grown': true,
        }),
      );
      expect(m.seed, SeedKind.mushroom);
      expect(m.ingredients, [Nutrient.soda]);
      expect(m.phase, LabPhase.planting);
      expect(m.experiments, 0);
      expect(m.discoveries, isEmpty);
      expect(m.isHybrid, isFalse);
      m.dispose();
    },
  );

  test('writes remain ordered after a storage error', () async {
    final writes = <String>[];
    final m = SeedLabModel(
      save: (data) async {
        writes.add(data);
        if (writes.length == 1) throw StateError('disk unavailable');
      },
    );
    m.add(Nutrient.moon);
    m.add(Nutrient.music);
    m.startGrowing();
    m.finishGrowing();
    await m.flush();
    expect(writes, hasLength(4));
    final restored = SeedLabModel()..restore(writes.last);
    expect(restored.phase, LabPhase.grown);
    expect(restored.discoveries, hasLength(1));
    m.dispose();
    restored.dispose();
  });
}
