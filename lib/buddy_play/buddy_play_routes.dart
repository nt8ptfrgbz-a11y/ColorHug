import 'package:flutter/material.dart';
import '../game_audio.dart';
import '../island_progress.dart';
import 'buddy_play_catalog.dart';
import 'rolling/rolling_screen.dart';
import 'salon/salon_screen.dart';
import 'water/water_screen.dart';
import 'delivery/delivery_screen.dart';
import 'squishy/squishy_screen.dart';
import 'sound_train/sound_train_screen.dart';
import 'shadows/shadows_screen.dart';
import 'tiny_world/tiny_world_screen.dart';

Widget buddyPlayScreen(
  BuddyPlay game,
  IslandProgress progress,
  GameAudioController audio,
) => switch (game) {
  BuddyPlay.rolling => RollingScreen(progress: progress, audio: audio),
  BuddyPlay.salon => SalonScreen(progress: progress, audio: audio),
  BuddyPlay.water => WaterScreen(progress: progress, audio: audio),
  BuddyPlay.delivery => DeliveryScreen(progress: progress, audio: audio),
  BuddyPlay.squishy => SquishyScreen(progress: progress, audio: audio),
  BuddyPlay.soundTrain => SoundTrainScreen(progress: progress, audio: audio),
  BuddyPlay.shadows => ShadowsScreen(progress: progress, audio: audio),
  BuddyPlay.tinyWorld => TinyWorldScreen(progress: progress, audio: audio),
};
