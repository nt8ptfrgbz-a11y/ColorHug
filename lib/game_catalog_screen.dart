import 'dart:async';

import 'package:flutter/material.dart';

import 'buddy_adventure_models.dart';
import 'buddy_adventure_screen.dart';
import 'buddy_bath_screen.dart';
import 'buddy_expedition/expedition_screen.dart';
import 'buddy_hide_screen.dart';
import 'buddy_home_screen.dart';
import 'buddy_juice_screen.dart';
import 'buddy_play/buddy_play_catalog.dart';
import 'buddy_play/buddy_play_routes.dart';
import 'color_detective_screen.dart';
import 'color_gallery_screen.dart';
import 'color_lab_screen.dart';
import 'dress_up/dress_screen.dart';
import 'fruit_slice_game_screen.dart';
import 'game_audio.dart';
import 'game_entry_navigation.dart';
import 'island_progress.dart';
import 'light_guardian_screen.dart';
import 'magic_studio_screen.dart';
import 'monster_planet_game.dart';
import 'rainbow_island_screen.dart';
import 'rainbow_repair_screen.dart';
import 'seed_lab/seed_screen.dart';
import 'shanhai/shanhai_screen.dart';
import 'silly_town/town_screen.dart';
import 'ultraman_training_camp_screen.dart';

class _CatalogGame {
  const _CatalogGame(
    this.id,
    this.title,
    this.detail,
    this.icon,
    this.color, [
    this.image,
  ]);

  final String id;
  final String title;
  final String detail;
  final String icon;
  final Color color;
  final String? image;
}

class _CatalogCategory {
  const _CatalogCategory(this.id, this.title, this.icon, this.games);

  final String id;
  final String title;
  final IconData icon;
  final List<_CatalogGame> games;
}

final _categories = <_CatalogCategory>[
  const _CatalogCategory('adventure', '幻想冒险', Icons.explore_rounded, [
    _CatalogGame(
      'shanhai',
      '山海唤灵师',
      '唤醒青璃，御风穿行',
      '🐉',
      Color(0xFF427E84),
      'docs/shanhai/ui-companion-844.png',
    ),
    _CatalogGame(
      'expedition',
      '抱抱探险队',
      '去恐龙岛交新朋友',
      '🦕',
      Color(0xFF81A46E),
      'docs/images/expedition-home-844.png',
    ),
    _CatalogGame(
      'monster',
      '怪兽星球',
      '选择战士，开启冒险',
      '🚀',
      Color(0xFF8C75BA),
      'docs/images/color-hug-monster-select.png',
    ),
  ]),
  const _CatalogCategory('create', '创造与想象', Icons.auto_awesome_rounded, [
    _CatalogGame(
      'seed',
      '奇怪种子实验室',
      '培育独一无二的植物',
      '🌱',
      Color(0xFF90AE76),
      'docs/seed_lab/lab-844.png',
    ),
    _CatalogGame(
      'dress',
      '绒绒衣橱',
      '搭配衣服，留下作品',
      '👗',
      Color(0xFFDE9A9C),
      'docs/dress_up/garden.png',
    ),
    _CatalogGame(
      'town',
      '小怪兽的胡闹小镇',
      '走进 30 个有趣场景',
      '🏘️',
      Color(0xFFE0A95F),
      'docs/silly_town/home-1100.png',
    ),
    _CatalogGame(
      'studio',
      '魔法画室',
      '用彩虹画笔自由创作',
      '🎨',
      Color(0xFFD879A8),
      'docs/images/color-hug-studio.png',
    ),
  ]),
  const _CatalogCategory('colors', '颜色探索', Icons.palette_rounded, [
    _CatalogGame(
      'lab',
      '颜色实验室',
      '光与颜料的混色游戏',
      '🧪',
      Color(0xFF5D8AC7),
      'docs/images/color-hug-home.png',
    ),
    _CatalogGame(
      'island',
      '彩虹小岛',
      '探索颜色活动地图',
      '🏝️',
      Color(0xFF75BDB2),
      'docs/images/color-hug-island.png',
    ),
    _CatalogGame(
      'detective',
      '色彩侦探',
      '观察线索，找出颜色',
      '🔎',
      Color(0xFF64A99B),
      'docs/images/color-hug-detective.png',
    ),
    _CatalogGame(
      'repair',
      '彩虹修复师',
      '修复地图里的颜色',
      '🌈',
      Color(0xFFE6A456),
      'docs/images/color-hug-repair.png',
    ),
    _CatalogGame(
      'gallery',
      '色彩图鉴',
      '收藏颜色的小秘密',
      '📖',
      Color(0xFF7F99C9),
      'docs/images/color-hug-gallery.png',
    ),
  ]),
  _CatalogCategory('buddy', '抱抱的小世界', Icons.toys_rounded, [
    const _CatalogGame(
      'buddy',
      '小伙伴乐园',
      '抱抱的小家与全部玩具',
      '🌷',
      Color(0xFF84AA84),
      'docs/images/buddy-home.png',
    ),
    for (final game in BuddyPlay.values)
      _CatalogGame(
        'play-${game.name}',
        playCatalog[game]!.title,
        playCatalog[game]!.hint,
        playCatalog[game]!.icon,
        playCatalog[game]!.color,
        _playImages[game],
      ),
    const _CatalogGame(
      'juice',
      '怪兽果汁屋',
      '切水果，调一杯果汁',
      '🍹',
      Color(0xFFE5B66E),
      'docs/images/buddy-juice.png',
    ),
    const _CatalogGame(
      'bath',
      '小怪兽洗澡澡',
      '搓泡泡，换装扮',
      '🫧',
      Color(0xFF85BBB7),
      'docs/images/buddy-bath.png',
    ),
    const _CatalogGame(
      'hide',
      '英语躲猫猫',
      '听声音，找朋友',
      '🙈',
      Color(0xFFA49AC9),
      'docs/images/buddy-hide.png',
    ),
    for (final game in BuddyAdventure.values)
      _CatalogGame(
        'adventure-${game.name}',
        buddyAdventureTitles[game.index],
        const [
          '玩转天气',
          '照顾小恐龙',
          '搭桥过河',
          '教抱抱学生活',
          '编排动作故事',
          '画一场烟花',
        ][game.index],
        const ['☁️', '🦕', '🍮', '🎒', '🎭', '🎆'][game.index],
        const [
          Color(0xFF8DB9CA),
          Color(0xFFAABF7D),
          Color(0xFFD2A5BD),
          Color(0xFFE2A58A),
          Color(0xFFA9A7CE),
          Color(0xFFAF9BCB),
        ][game.index],
        _adventureImages[game],
      ),
  ]),
  const _CatalogCategory('heroes', '英雄训练', Icons.bolt_rounded, [
    _CatalogGame(
      'camp',
      '奥特曼训练营',
      '选择今天的训练',
      '🦸',
      Color(0xFF697EB8),
      'docs/images/color-hug-ultra-camp.png',
    ),
    _CatalogGame(
      'fruit',
      '水果切切乐',
      '一指划开水果',
      '🍉',
      Color(0xFFE8816B),
      'assets/fruit_game/fruit-training-bg.png',
    ),
    _CatalogGame(
      'radar',
      '怪兽雷达',
      '听特征，找怪兽',
      '📡',
      Color(0xFF8774BD),
      'docs/images/color-hug-ultra-radar.png',
    ),
    _CatalogGame(
      'beam',
      '光线发射',
      '看准时机发射',
      '✨',
      Color(0xFF6397CA),
      'docs/images/color-hug-ultra-beam.png',
    ),
    _CatalogGame(
      'rescue',
      '宇宙救援',
      '选择合适的救援工具',
      '🛸',
      Color(0xFF65B1A0),
      'docs/images/color-hug-ultra-rescue.png',
    ),
    _CatalogGame(
      'guardian',
      '互补色护盾',
      '用颜色能量守护宇宙',
      '🛡️',
      Color(0xFFC877A1),
      'docs/images/color-hug-guardian.png',
    ),
  ]),
];

const _playImages = <BuddyPlay, String>{
  BuddyPlay.rolling: 'docs/images/play-rolling-phone.png',
  BuddyPlay.salon: 'docs/images/play-salon-phone.png',
  BuddyPlay.water: 'docs/images/play-water-phone.png',
  BuddyPlay.delivery: 'docs/images/play-delivery-phone.png',
  BuddyPlay.squishy: 'docs/images/play-squishy-phone.png',
  BuddyPlay.soundTrain: 'docs/images/play-soundTrain-phone.png',
  BuddyPlay.shadows: 'docs/images/play-shadows-phone.png',
  BuddyPlay.tinyWorld: 'docs/images/play-tinyWorld-phone.png',
};

const _adventureImages = <BuddyAdventure, String>{
  BuddyAdventure.weather: 'docs/images/buddy-weather.png',
  BuddyAdventure.dinosaur: 'docs/images/buddy-dinosaur.png',
  BuddyAdventure.building: 'docs/images/buddy-building.png',
  BuddyAdventure.silly: 'docs/images/buddy-silly.png',
  BuddyAdventure.theater: 'docs/images/buddy-theater.png',
  BuddyAdventure.fireworks: 'docs/images/buddy-fireworks.png',
};

class GameCatalogScreen extends StatefulWidget {
  const GameCatalogScreen({
    super.key,
    required this.progress,
    required this.audio,
    required this.nativeAudio,
  });

  final IslandProgress progress;
  final GameAudioController audio;
  final bool nativeAudio;

  @override
  State<GameCatalogScreen> createState() => _GameCatalogScreenState();
}

class _GameCatalogScreenState extends State<GameCatalogScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _category = 'all';

  @override
  void initState() {
    super.initState();
    _search.addListener(_filterChanged);
  }

  void _filterChanged() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, String id, {String? from}) async {
    FocusScope.of(context).unfocus();
    unawaited(widget.audio.stopSpeech());
    unawaited(widget.audio.play(GameSound.tap));
    final backLabel = ModalRoute.of(context)?.isFirst == true
        ? '返回游戏目录'
        : '返回上一页';
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => GameEntryNavigation(
          backLabel: backLabel,
          child: _destination(routeContext, id, from: from),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, String id, {String? from}) {
    final progress = widget.progress;
    final audio = widget.audio;
    void back() => Navigator.of(context).pop();
    Future<void> next(String game) => _open(context, game, from: id);
    if (id.startsWith('play-')) {
      final game = BuddyPlay.values.byName(id.substring(5));
      return buddyPlayScreen(game, progress, audio);
    }
    if (id.startsWith('adventure-')) {
      return BuddyAdventureScreen(
        adventure: BuddyAdventure.values.byName(id.substring(10)),
        progress: progress,
        audio: audio,
      );
    }
    return switch (id) {
      'shanhai' => ShanhaiScreen(
        audio: audio,
        nativeAudio: widget.nativeAudio,
        onBack: back,
        onOpenGames: () async => back(),
      ),
      'expedition' => ExpeditionScreen(progress: progress, audio: audio),
      'monster' => MonsterPlanetSelectScreen(progress: progress, audio: audio),
      'seed' => SeedLabScreen(
        audio: audio,
        nativeAudio: widget.nativeAudio,
        onBack: back,
        onOpenWardrobe: () => next('dress'),
      ),
      'dress' => DressUpScreen(
        audio: audio,
        onBack: back,
        onOpenTown: () => next('town'),
      ),
      'town' => TownHomeScreen(
        audio: audio,
        nativeAudio: widget.nativeAudio,
        onBack: back,
        onOpenClassic: () => next('lab'),
      ),
      'studio' => MagicStudioScreen(progress: progress, audio: audio),
      'lab' => ColorLabScreen(
        progress: progress,
        audio: audio,
        onBack: back,
        onOpenIsland: () =>
            from == 'island' ? back() : unawaited(next('island')),
      ),
      'island' => RainbowIslandScreen(
        progress: progress,
        audio: audio,
        onOpenLab: () => from == 'lab' ? back() : unawaited(next('lab')),
      ),
      'detective' => ColorDetectiveScreen(progress: progress, audio: audio),
      'repair' => RainbowRepairScreen(progress: progress, audio: audio),
      'gallery' => ColorGalleryScreen(progress: progress, audio: audio),
      'buddy' => BuddyHomeScreen(progress: progress, audio: audio),
      'juice' => BuddyJuiceScreen(progress: progress, audio: audio),
      'bath' => BuddyBathScreen(progress: progress, audio: audio),
      'hide' => BuddyHideScreen(progress: progress, audio: audio),
      'camp' => UltramanTrainingCampScreen(progress: progress, audio: audio),
      'fruit' => FruitSliceGameScreen(progress: progress, audio: audio),
      'radar' => MonsterRadarScreen(progress: progress, audio: audio),
      'beam' => BeamTrainingScreen(progress: progress, audio: audio),
      'rescue' => SpaceRescueScreen(progress: progress, audio: audio),
      'guardian' => LightGuardianScreen(progress: progress, audio: audio),
      _ => throw ArgumentError.value(id, 'id', 'Unknown game'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = [
      for (final category in _categories)
        if (_category == 'all' || category.id == _category)
          (
            category: category,
            games: category.games
                .where(
                  (game) =>
                      query.isEmpty ||
                      game.title.toLowerCase().contains(query) ||
                      game.detail.toLowerCase().contains(query),
                )
                .toList(),
          ),
    ].where((section) => section.games.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: LayoutBuilder(
              builder: (context, bounds) {
                final compact = bounds.maxWidth < 600;
                final side = compact ? 16.0 : 28.0;
                final width = bounds.maxWidth - side * 2;
                final columns = width >= 1060
                    ? 5
                    : width >= 820
                    ? 4
                    : width >= 570
                    ? 3
                    : 2;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        side,
                        compact ? 14 : 24,
                        side,
                        12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F0E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.sports_esports_rounded,
                              color: Color(0xFF2F7C71),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '颜色抱抱',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF58716A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '游戏乐园',
                                  style: TextStyle(
                                    fontSize: 27,
                                    color: Color(0xFF203B35),
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_categories.fold<int>(0, (sum, category) => sum + category.games.length)} 个入口',
                            style: const TextStyle(
                              color: Color(0xFF61736C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: side),
                      child: TextField(
                        key: const ValueKey('catalog-search'),
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: '找游戏',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: '清除搜索',
                                  onPressed: _search.clear,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8E2DB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFD8E2DB),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 66,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: side,
                          vertical: 12,
                        ),
                        children: [
                          _filter('all', '全部', Icons.apps_rounded),
                          for (final category in _categories)
                            _filter(category.id, category.title, category.icon),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(
                                '没有找到相关游戏',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 17,
                                ),
                              ),
                            )
                          : CustomScrollView(
                              key: const ValueKey('catalog-list'),
                              controller: _scroll,
                              slivers: [
                                for (final section in visible) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        side,
                                        8,
                                        side,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            section.category.icon,
                                            color: const Color(0xFF397B70),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            section.category.title,
                                            style: const TextStyle(
                                              color: Color(0xFF203B35),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${section.games.length}',
                                            style: const TextStyle(
                                              color: Color(0xFF77877E),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      side,
                                      0,
                                      side,
                                      18,
                                    ),
                                    sliver: SliverGrid.builder(
                                      itemCount: section.games.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent: compact ? 205 : 218,
                                          ),
                                      itemBuilder: (context, index) {
                                        final game = section.games[index];
                                        return _GameTile(
                                          game: game,
                                          onTap: () => unawaited(
                                            _open(context, game.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _filter(String id, String title, IconData icon) {
    final selected = _category == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: ValueKey('catalog-category-$id'),
        selected: selected,
        label: Text(title),
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : const Color(0xFF47766D),
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF365D54),
          fontWeight: FontWeight.w700,
        ),
        selectedColor: const Color(0xFF32796D),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF32796D) : const Color(0xFFD5E1D9),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        onSelected: (_) {
          _category = id;
          _filterChanged();
        },
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.onTap});

  final _CatalogGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('catalog-game-${game.id}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE1E8E2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: game.color),
                    if (game.image != null)
                      Image.asset(
                        game.image!,
                        fit: BoxFit.cover,
                        cacheWidth: 560,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            game.icon,
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          game.icon,
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                    Positioned(
                      right: 9,
                      bottom: 9,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 17,
                          color: Color(0xFF274D44),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Text(
                        game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263E38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      game.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64746D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
