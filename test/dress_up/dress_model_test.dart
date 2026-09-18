import 'dart:async';
import 'dart:convert';
import 'package:color_hug/dress_up/dress_catalog.dart';
import 'package:color_hug/dress_up/dress_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every catalog item is selectable and separates replace one-piece outfits',
    () {
      final model = DressModel();
      expect(dressCatalog.length, 36);
      expect(dressItemsById.length, 36);
      for (final item in dressCatalog) {
        model.wear(item);
        expect(model.look.itemFor(item.category), item.id);
      }
      model.wear(dressItemsById['raincoat']!);
      model.wear(dressItemsById['knit']!);
      expect(model.look.outfit, isEmpty);
      expect(model.look.top, 'knit');
      expect(model.look.bottom, 'dungarees');
      model.undo();
      expect(model.look.outfit, 'raincoat');
      model.removeAccessory();
      expect(model.look.accessory, isEmpty);
      model.undo();
      expect(model.look.accessory, 'satchel');
      model.dispose();
    },
  );

  test(
    'look, scene, preferences and album survive restart with category validation',
    () {
      final model = DressModel();
      model.chooseCharacter(1);
      model.wear(dressItemsById['starlight']!);
      model.tint(3);
      model.visit(DressPlace.night);
      model.discover();
      model.setSound(false);
      model.setReducedMotion(true);
      const id = '1789712345678000';
      model.addMemory(
        DressMemory(
          id: id,
          look: model.look,
          place: model.place,
          photo: 'look_$id.png',
        ),
      );
      final restored = DressModel()..restore(model.encode());
      expect(restored.look.toJson(), model.look.toJson());
      expect(restored.place, DressPlace.night);
      expect(restored.sound, isFalse);
      expect(restored.reducedMotion, isTrue);
      expect(restored.memories.single.look.tint, 3);
      expect(restored.discoveries, {DressPlace.night});
      final invalid = DressLook.fromJson({
        'outfit': 'wellies',
        'shoes': 'petal',
        'hair': null,
        'tint': 77,
        'character': -1,
        'accessory': '',
      });
      expect(invalid.outfit, 'petal');
      expect(invalid.shoes, 'maryjane');
      expect(invalid.tint, -1);
      expect(invalid.character, 0);
      expect(invalid.accessory, '');
      model.dispose();
      restored.dispose();
    },
  );

  test(
    'invalid and future records are safe; photo paths cannot escape album directory',
    () {
      for (final record in [
        '{broken',
        '[]',
        'null',
        'true',
        '{"version":88,"look":{"character":1}}',
      ]) {
        final model = DressModel()..restore(record);
        expect(model.look.outfit, 'petal');
        model.dispose();
      }
      final model = DressModel()
        ..restore(
          jsonEncode({
            'version': 1,
            'memories': [
              {'id': '1789712345678000', 'photo': '../../secret.png'},
            ],
            'discoveries': 'bad',
            'look': {'top': 12},
            'place': 'unknown',
          }),
        );
      expect(model.memories, isEmpty);
      expect(model.place, DressPlace.studio);
      expect(model.look.top, 'blouse');
      model.dispose();
    },
  );

  test(
    'write queue preserves latest look after a failed save and disposal',
    () async {
      var attempts = 0;
      final gate = Completer<void>(), saved = <String>[];
      final model = DressModel(
        save: (value) async {
          attempts++;
          if (attempts == 1) throw StateError('disk full');
          await gate.future;
          saved.add(value);
        },
      );
      model.chooseCharacter(1);
      await model.saved;
      expect(model.saveFailed, isTrue);
      model.wear(dressItemsById['raincoat']!);
      model.wear(dressItemsById['sleepy']!);
      final writes = model.saved;
      model.dispose();
      gate.complete();
      await writes;
      expect((jsonDecode(saved.last) as Map)['look']['outfit'], 'sleepy');
    },
  );

  test(
    'album retains 24 photos, reports expired files, and restores a saved outfit',
    () {
      final model = DressModel();
      final expired = <String>[];
      for (var i = 0; i < 27; i++) {
        final id = '${1789712345678000 + i}';
        expired.addAll(
          model.addMemory(
            DressMemory(
              id: id,
              look: const DressLook(outfit: 'pinafore', hair: 'braids'),
              place: DressPlace.tea,
              photo: 'look_$id.png',
            ),
          ),
        );
      }
      expect(expired.length, 3);
      expect(model.memories.length, 24);
      model.restoreMemory(model.memories.last);
      expect(model.look.outfit, 'pinafore');
      expect(model.look.hair, 'braids');
      expect(model.place, DressPlace.tea);
      model.undo();
      expect(model.look.outfit, 'petal');
      model.dispose();
    },
  );
}
