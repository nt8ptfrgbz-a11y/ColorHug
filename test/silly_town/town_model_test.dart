import 'dart:convert';
import 'package:color_hug/silly_town/town_catalog.dart';
import 'package:color_hug/silly_town/town_model.dart';
import 'package:color_hug/silly_town/town_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void advanceModel(TownModel m, TownLayout l, double seconds) {
  for (var i = 0; i < (seconds * 40).ceil(); i++) {
    m.step(.025, l);
  }
}

void tapModel(TownModel m, TownLayout l, Offset at) {
  m.down(at, l, 1);
  m.up(at, l, 1);
  advanceModel(m, l, .25);
}

void completeModel(TownModel m, TownLayout l) {
  if (m.usesProps) {
    for (var i = 0; i < 3; i++) {
      m.down(l.slot(i), l, 1);
      m.move(l.actor, l, 1);
      m.up(l.actor, l, 1);
      advanceModel(m, l, .3);
    }
  } else if (m.level.play == TownPlay.catchToy) {
    for (var i = 0; i < 6; i++) {
      tapModel(m, l, l.toy(i, m.time));
    }
  } else if (m.level.play == TownPlay.scrub) {
    for (var i = 0; i < 6; i++) {
      tapModel(m, l, l.mark(i));
    }
  } else if (m.level.play == TownPlay.inflate) {
    m.down(l.actor, l, 1);
    advanceModel(m, l, 5);
    m.up(l.actor, l, 1);
  } else if (m.level.play == TownPlay.music) {
    for (var i = 0; i < m.level.goal; i++) {
      tapModel(m, l, l.slot(i % 3));
    }
  } else {
    for (var i = 0; i < m.level.goal; i++) {
      tapModel(m, l, l.actor);
    }
  }
}

void main() {
  for (final size in [const Size(300, 370), const Size(1000, 560)]) {
    test('30 levels finish with real hit-tested gestures at $size', () {
      final l = TownLayout(size);
      for (final level in townLevels) {
        final m = TownModel(level);
        completeModel(m, l);
        expect(m.finished, isTrue, reason: '${level.id}: ${level.title}');
        expect(m.takeEvents().where((e) => e.finish).length, 1);
        expect(m.showNext, isFalse);
        advanceModel(m, l, 4);
        expect(m.showNext, isTrue);
        tapModel(m, l, l.actor);
        expect(m.takeEvents().where((e) => e.finish), isEmpty);
        expect(m.particles.length, lessThanOrEqualTo(90));
        m.dispose();
      }
    });
  }
  test('tap-select then tap-target works; outside drops do not count', () {
    final m = TownModel(townLevels[5]), l = TownLayout(const Size(390, 470));
    m.down(l.slot(0), l, 1);
    m.up(const Offset(0, 0), l, 1);
    expect(m.actionCount, 0);
    expect(m.selected, 0);
    tapModel(m, l, l.actor);
    expect(m.used, {0});
    tapModel(m, l, l.slot(1));
    tapModel(m, l, l.actor);
    tapModel(m, l, l.slot(2));
    tapModel(m, l, l.actor);
    expect(m.finished, true);
    m.dispose();
  });
  test(
    'cancel, pause, second finger and repeated touches cannot auto-complete',
    () {
      final m = TownModel(townLevels[11]), l = TownLayout(const Size(700, 500));
      m.down(l.actor, l, 1);
      m.down(l.actor, l, 2);
      m.up(l.actor, l, 2);
      expect(m.actionCount, 1);
      expect(m.pressing, true);
      m.cancel();
      advanceModel(m, l, 4);
      expect(m.actionCount, 1);
      m.paused = true;
      m.down(l.actor, l, 3);
      advanceModel(m, l, 9);
      expect(m.actionCount, 1);
      m.dispose();
    },
  );
  test(
    'scrubbing the same clean spot cannot satisfy the other dirt patches',
    () {
      final m = TownModel(townLevels[10]), l = TownLayout(const Size(390, 450));
      for (var i = 0; i < 10; i++) {
        tapModel(m, l, l.mark(0));
      }
      expect(m.cleaned.length, 1);
      expect(m.finished, false);
      m.dispose();
    },
  );
  test(
    'save restores completion, heard words, music, and validates corrupt fields',
    () async {
      final previous = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      final p = TownProgress.persistent();
      await p.ready;
      for (var i = 0; i < 8; i++) {
        p.finish(i);
        p.finish(i);
      }
      p.encounter('Apple');
      p.toggleMusic();
      await p.flush();
      p.dispose();
      final restored = TownProgress.persistent();
      await restored.ready;
      expect(restored.completed.length, 8);
      expect(restored.words, {'Apple'});
      expect(restored.music, false);
      expect(restored.nextLevel, 8);
      restored.dispose();
      await SharedPreferencesAsync().setString(
        TownProgress.storageKey,
        jsonEncode({
          'completed': [-1, 0, 29, 30, '3'],
          'words': ['Apple', 4, 'not a real lesson'],
          'music': 'bad',
        }),
      );
      final repaired = TownProgress.persistent();
      await repaired.ready;
      expect(repaired.completed, {0, 29});
      expect(repaired.words, {'Apple'});
      expect(repaired.music, true);
      repaired.dispose();
    },
  );
}
