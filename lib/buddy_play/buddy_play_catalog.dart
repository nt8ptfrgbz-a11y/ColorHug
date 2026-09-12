import 'package:flutter/material.dart';

enum BuddyPlay {
  rolling,
  salon,
  water,
  delivery,
  squishy,
  soundTrain,
  shadows,
  tinyWorld,
}

class PlayWord {
  const PlayWord(this.english, this.chinese, this.icon);
  final String english, chinese, icon;
}

class PlayInfo {
  const PlayInfo(
    this.title,
    this.english,
    this.icon,
    this.hint,
    this.color,
    this.words,
  );
  final String title, english, icon, hint;
  final Color color;
  final List<PlayWord> words;
}

const playCatalog = <BuddyPlay, PlayInfo>{
  BuddyPlay.rolling: PlayInfo(
    '咕噜咕噜滚滚乐',
    'ROLL & WONDER',
    '🎢',
    '搭机关 · 放小球 · 看惊喜',
    Color(0xFFEFC477),
    [
      PlayWord('ball', '小球', '🔴'),
      PlayWord('bell', '铃铛', '🔔'),
      PlayWord('duck', '小鸭', '🦆'),
      PlayWord('roll', '滚动', '🎢'),
      PlayWord('go', '出发', '▶️'),
      PlayWord('stop', '停下', '✋'),
      PlayWord('big', '大', '🐘'),
      PlayWord('small', '小', '🐭'),
      PlayWord('up', '向上', '⬆️'),
      PlayWord('down', '向下', '⬇️'),
    ],
  ),
  BuddyPlay.salon: PlayInfo(
    '怪兽理发店',
    'SNIP & SMILE',
    '✂️',
    '剪一剪 · 吹一吹 · 长回来',
    Color(0xFFF0BBCC),
    [
      PlayWord('hair', '头发', '💇'),
      PlayWord('cut', '剪', '✂️'),
      PlayWord('comb', '梳', '🪮'),
      PlayWord('blow', '吹', '💨'),
      PlayWord('long', '长', '🦒'),
      PlayWord('short', '短', '🐥'),
      PlayWord('bow', '蝴蝶结', '🎀'),
      PlayWord('bird', '小鸟', '🐦'),
    ],
  ),
  BuddyPlay.water: PlayInfo(
    '小小水流实验室',
    'SPLASH LAB',
    '💧',
    '开闸门 · 转水管 · 漂小鸭',
    Color(0xFFA8D9E9),
    [
      PlayWord('water', '水', '💧'),
      PlayWord('open', '打开', '🔓'),
      PlayWord('close', '关上', '🔒'),
      PlayWord('full', '满', '🪣'),
      PlayWord('empty', '空', '🥣'),
      PlayWord('duck', '小鸭', '🦆'),
      PlayWord('flow', '流动', '🌊'),
      PlayWord('turn', '转动', '🔄'),
    ],
  ),
  BuddyPlay.delivery: PlayInfo(
    '胖胖快递车',
    'SPECIAL DELIVERY',
    '🚚',
    '装包裹 · 开小车 · 拆礼物',
    Color(0xFFF0C795),
    [
      PlayWord('car', '汽车', '🚚'),
      PlayWord('go', '开动', '▶️'),
      PlayWord('stop', '停下', '✋'),
      PlayWord('box', '盒子', '📦'),
      PlayWord('bridge', '桥', '🌉'),
      PlayWord('boat', '小船', '⛵'),
      PlayWord('wash', '洗', '🫧'),
      PlayWord('gift', '礼物', '🎁'),
    ],
  ),
  BuddyPlay.squishy: PlayInfo(
    '果冻小怪变变变',
    'SQUISH & GIGGLE',
    '🍮',
    '拉长长 · 捏扁扁 · 弹回来',
    Color(0xFFBFD6AC),
    [
      PlayWord('stretch', '拉长', '↕️'),
      PlayWord('squeeze', '挤压', '🤏'),
      PlayWord('bounce', '弹跳', '🏀'),
      PlayWord('soft', '软软的', '☁️'),
      PlayWord('happy', '开心', '😄'),
      PlayWord('sleepy', '困了', '😴'),
      PlayWord('eyes', '眼睛', '👀'),
      PlayWord('mouth', '嘴巴', '👄'),
    ],
  ),
  BuddyPlay.soundTrain: PlayInfo(
    '声音小火车',
    'MELODY EXPRESS',
    '🚂',
    '装声音 · 排车厢 · 开音乐会',
    Color(0xFFC4BBE3),
    [
      PlayWord('train', '火车', '🚂'),
      PlayWord('drum', '鼓', '🥁'),
      PlayWord('bell', '铃铛', '🔔'),
      PlayWord('frog', '青蛙', '🐸'),
      PlayWord('cat', '猫', '🐱'),
      PlayWord('fast', '快', '🐇'),
      PlayWord('slow', '慢', '🐢'),
      PlayWord('again', '再来', '🔁'),
    ],
  ),
  BuddyPlay.shadows: PlayInfo(
    '被窝里的影子朋友',
    'COZY SHADOWS',
    '🔦',
    '移灯光 · 摆玩具 · 变影子',
    Color(0xFFD3BEDC),
    [
      PlayWord('light', '光', '🔦'),
      PlayWord('shadow', '影子', '👤'),
      PlayWord('big', '大', '🐘'),
      PlayWord('small', '小', '🐭'),
      PlayWord('near', '近', '🤏'),
      PlayWord('far', '远', '🔭'),
      PlayWord('rabbit', '兔子', '🐰'),
      PlayWord('moon', '月亮', '🌙'),
    ],
  ),
  BuddyPlay.tinyWorld: PlayInfo(
    '巨人宝宝的小小世界',
    'LITTLE BIG WORLD',
    '🌱',
    '画小路 · 搭小家 · 看生活',
    Color(0xFFBEDBBE),
    [
      PlayWord('house', '房子', '🏠'),
      PlayWord('leaf', '叶子', '🍃'),
      PlayWord('bridge', '桥', '🌉'),
      PlayWord('road', '小路', '🛤️'),
      PlayWord('home', '家', '🏡'),
      PlayWord('rain', '雨', '🌧️'),
      PlayWord('water', '水', '💧'),
      PlayWord('rest', '休息', '🛏️'),
      PlayWord('cookie', '饼干', '🍪'),
      PlayWord('flower', '花', '🌸'),
    ],
  ),
};

PlayWord? playWord(String word) {
  for (final info in playCatalog.values) {
    for (final entry in info.words) {
      if (entry.english == word) return entry;
    }
  }
  return null;
}
