import 'dart:math';

import 'package:flutter/material.dart';

enum JuiceReaction { rosy, bubbles, sour, rainbow, snow }

enum JuiceStage { cutting, blending, serving, celebrated }

enum BathStage { soap, rinse, dry, dress, complete }

@immutable
class JuiceFruit {
  const JuiceFruit(this.id, this.name, this.emoji, this.color);
  final String id;
  final String name;
  final String emoji;
  final Color color;
}

const juiceFruits = [
  JuiceFruit('apple', '苹果', '🍎', Color(0xFFF47778)),
  JuiceFruit('banana', '香蕉', '🍌', Color(0xFFFFD769)),
  JuiceFruit('watermelon', '西瓜', '🍉', Color(0xFFFF8DAD)),
  JuiceFruit('lemon', '柠檬', '🍋', Color(0xFFF1D75F)),
  JuiceFruit('grape', '葡萄', '🍇', Color(0xFFAA88DB)),
  JuiceFruit('orange', '橙子', '🍊', Color(0xFFFFB16A)),
];

const buddyColors = [
  Color(0xFF80CBB2),
  Color(0xFFA89AE0),
  Color(0xFFF3ACB9),
  Color(0xFFF2C66D),
];
const buddyOutfits = ['bow', 'crown', 'star'];
const buddyOutfitEmojis = ['🎀', '👑', '⭐'];

@immutable
class JuiceRecipe {
  JuiceRecipe(Iterable<String> fruits, {this.iced = false})
    : fruits = List.unmodifiable(fruits);

  final List<String> fruits;
  final bool iced;
  String get id =>
      '${(fruits.toList()..sort()).join('+')}${iced ? ':ice' : ''}';
  List<JuiceFruit> get ingredients => fruits
      .map((id) => juiceFruits.firstWhere((fruit) => fruit.id == id))
      .toList(growable: false);
  String get label =>
      '${ingredients.map((fruit) => fruit.emoji).join()}${iced ? ' 🧊' : ''}';
  Color get color {
    final colors = ingredients.map((fruit) => fruit.color).toList();
    if (colors.isEmpty) return const Color(0xFFFCE8BF);
    return Color.fromARGB(
      255,
      (colors.fold<double>(0, (sum, c) => sum + c.r) / colors.length * 255)
          .round(),
      (colors.fold<double>(0, (sum, c) => sum + c.g) / colors.length * 255)
          .round(),
      (colors.fold<double>(0, (sum, c) => sum + c.b) / colors.length * 255)
          .round(),
    );
  }

  JuiceReaction get reaction {
    if (iced) return JuiceReaction.snow;
    if (fruits.toSet().length >= 3) return JuiceReaction.rainbow;
    if (fruits.contains('lemon')) return JuiceReaction.sour;
    if (fruits.contains('watermelon')) return JuiceReaction.bubbles;
    return JuiceReaction.rosy;
  }

  Map<String, Object> toJson() => {'fruits': fruits, 'iced': iced};

  static JuiceRecipe? fromJson(Object? value) {
    if (value is! Map || value['fruits'] is! List) return null;
    final fruits = (value['fruits'] as List).whereType<String>().toList();
    if (fruits.isEmpty ||
        fruits.length > 3 ||
        fruits.length != (value['fruits'] as List).length ||
        fruits.any((id) => !juiceFruits.any((fruit) => fruit.id == id))) {
      return null;
    }
    return JuiceRecipe(fruits, iced: value['iced'] == true);
  }
}

@immutable
class HideAnimal {
  const HideAnimal(this.word, this.name, this.emoji, this.clue);
  final String word;
  final String name;
  final String emoji;
  final String clue;
}

const hideAnimals = [
  HideAnimal('cat', '小猫', '🐱', '喵，喵！听听是谁藏起来了。'),
  HideAnimal('dog', '小狗', '🐶', '汪汪！有谁摇着尾巴躲起来了？'),
  HideAnimal('rabbit', '小兔', '🐰', '长耳朵轻轻动，是谁藏在那里？'),
  HideAnimal('duck', '小鸭', '🦆', '嘎嘎！找找扁嘴巴的朋友。'),
  HideAnimal('bear', '小熊', '🐻', '圆耳朵，胖肚子，朋友躲在哪里？'),
  HideAnimal('frog', '青蛙', '🐸', '呱呱！爱跳高的朋友藏起来啦。'),
];

@immutable
class HideRound {
  const HideRound({
    required this.animal,
    required this.target,
    required this.room,
  });
  factory HideRound.create(int round, Random random) => HideRound(
    animal: hideAnimals[round % hideAnimals.length],
    target: random.nextInt(3),
    room: (round ~/ 2) % 3,
  );
  final HideAnimal animal;
  final int target;
  final int room;
  String get question => 'Where is the ${animal.word}?';
  String get answer =>
      'The ${animal.word} is ${const ['in the box', 'behind the curtain', 'under the blanket'][target]}.';
}
