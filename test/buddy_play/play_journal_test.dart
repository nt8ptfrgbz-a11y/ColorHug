import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/buddy_models.dart';
import 'package:color_hug/buddy_play/buddy_play_catalog.dart';
import 'package:color_hug/buddy_play/buddy_play_journal.dart';
import 'package:color_hug/buddy_play/rolling/rolling_model.dart';
import 'package:color_hug/buddy_play/salon/salon_model.dart';
import 'package:color_hug/buddy_play/water/water_model.dart';
import 'package:color_hug/buddy_play/delivery/delivery_model.dart';
import 'package:color_hug/buddy_play/squishy/squishy_model.dart';
import 'package:color_hug/buddy_play/sound_train/sound_train_model.dart';
import 'package:color_hug/buddy_play/shadows/shadows_model.dart';
import 'package:color_hug/buddy_play/tiny_world/tiny_world_model.dart';

Map<BuddyPlay, Map<String, dynamic>> examples() => {
  BuddyPlay.rolling: RollingModel().toJson(),
  BuddyPlay.salon: SalonModel().toJson(),
  BuddyPlay.water: WaterModel().toJson(),
  BuddyPlay.delivery: DeliveryModel().toJson(),
  BuddyPlay.squishy: SquishyModel().toJson(),
  BuddyPlay.soundTrain: SoundTrainModel().toJson(),
  BuddyPlay.shadows: ShadowsModel().toJson(),
  BuddyPlay.tinyWorld: TinyWorldModel().toJson(),
};
void main() {
  test('八款作品严格校验、隔离外部修改、未知字段丢弃与往返', () {
    final journal = BuddyPlayJournal();
    for (final e in examples().entries) {
      expect(validPlayData(e.key, e.value), true, reason: e.key.name);
      expect(
        journal.save(e.key, {
          ...e.value,
          'future': DateTime.now(),
        }, collect: true),
        true,
      );
      final draft = journal.draft(e.key)!;
      expect(draft.containsKey('future'), false);
      draft['v'] = 99;
      expect(journal.draft(e.key)!['v'], 1);
      expect(journal.save(e.key, {'v': 1}), false);
    }
    final restore = BuddyPlayJournal()
      ..merge(jsonDecode(jsonEncode(journal.toJson())));
    for (final e in examples().entries) {
      expect(restore.draft(e.key), e.value);
      expect(restore.album(e.key).length, 1);
    }
  });
  test('容量限制、去重、加载竞态保留新编辑也保留旧收藏', () {
    final old = BuddyPlayJournal();
    final model = RollingModel();
    for (var i = 0; i < 9; i++) {
      model.parts = [i % 5, i ~/ 5, 3];
      old.save(BuddyPlay.rolling, model.toJson(), collect: true);
    }
    expect(old.album(BuddyPlay.rolling).length, 6);
    final newJournal = BuddyPlayJournal();
    model.parts = [4, 4, 4];
    newJournal.save(BuddyPlay.rolling, model.toJson());
    newJournal.merge(old.toJson());
    expect(newJournal.draft(BuddyPlay.rolling)!['parts'], [4, 4, 4]);
    expect(newJournal.album(BuddyPlay.rolling).length, 6);
    newJournal.save(BuddyPlay.rolling, model.toJson(), collect: true);
    newJournal.save(BuddyPlay.rolling, model.toJson(), collect: true);
    expect(newJournal.album(BuddyPlay.rolling).length, 6);
  });
  test('损坏数据不跨游戏传播，拒绝无限值、越界位置与池塘里的房子', () {
    final journal = BuddyPlayJournal();
    final d = examples();
    d[BuddyPlay.shadows]!['light'] = [double.nan, .95];
    d[BuddyPlay.salon]!['looks'][0]['lengths'][0] = double.infinity;
    d[BuddyPlay.tinyWorld]!['objects'] = [
      {'kind': 2, 'cell': 4},
    ];
    for (final game in [
      BuddyPlay.shadows,
      BuddyPlay.salon,
      BuddyPlay.tinyWorld,
    ]) {
      expect(validPlayData(game, d[game]), false);
    }
    journal.merge({
      'v': 1,
      for (final e in d.entries)
        e.key.name: {
          'draft': e.value,
          'album': [null, e.value],
        },
    });
    expect(journal.draft(BuddyPlay.rolling), isNotNull);
    expect(journal.draft(BuddyPlay.shadows), isNull);
    expect(journal.album(BuddyPlay.salon), isEmpty);
  });
  test('持久化重启保留旧配方星星与八款作品，重复发现不刷星', () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final p = IslandProgress.persistent();
    await p.ready;
    p.saveJuiceRecipe(JuiceRecipe(['apple']));
    p.dressBuddy(color: 2);
    p.recordDetectiveWin(0, '黄色');
    for (final e in examples().entries) {
      p.savePlay(e.key, e.value, collect: true);
      p.discoverPlay(e.key, 'first');
      p.discoverPlay(e.key, 'first');
      p.encounterPlayWord(e.key, playCatalog[e.key]!.words.first.english);
    }
    final stars = p.stars;
    await p.ready;
    p.dispose();
    final restored = IslandProgress.persistent();
    await restored.ready;
    expect(restored.stars, stars);
    expect(restored.buddyColor, 2);
    expect(restored.juiceRecipes.length, 1);
    for (final e in examples().entries) {
      expect(restored.playJournal.draft(e.key), e.value);
      expect(restored.playDiscoveries(e.key), 1);
    }
    await SharedPreferencesAsync().setString(
      'color_hug.play_journal_v1',
      '{broken',
    );
    restored.dispose();
    final damaged = IslandProgress.persistent();
    await damaged.ready;
    expect(damaged.juiceRecipes.length, 1);
    expect(damaged.stars, stars);
    damaged.dispose();
  });
}
