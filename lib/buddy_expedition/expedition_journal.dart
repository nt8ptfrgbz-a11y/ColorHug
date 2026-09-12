import 'expedition_models.dart';
import 'chapters/orchard_controller.dart';
import 'chapters/cave_controller.dart';
import 'chapters/bay_controller.dart';

class ExpeditionJournal {
  ValleyCheckpoint _checkpoint = const ValleyCheckpoint();
  bool _edited = false;
  ValleyCheckpoint get checkpoint =>
      ValleyCheckpoint.fromJson(_checkpoint.toJson())!;
  bool save(ValleyCheckpoint value) {
    final checked = ValleyCheckpoint.fromJson(value.toJson());
    if (checked == null) return false;
    _checkpoint = checked;
    _edited = true;
    return true;
  }

  void merge(Object? raw) {
    if (_edited) return;
    final data = ValleyCheckpoint.fromJson(raw);
    if (data != null) {
      _checkpoint = data;
      return;
    }
    // Repair an isolated damaged chapter without discarding the rest of the trip.
    if (raw is Map && raw['adventure'] is Map) {
      final adventure = raw['adventure'] as Map;
      for (final entry in {
        'orchard': OrchardController().toJson(),
        'cave': CaveController().toJson(),
        'bay': BayController().toJson(),
      }.entries) {
        final repaired = ValleyCheckpoint.fromJson({
          ...raw,
          'adventure': {...adventure, entry.key: entry.value},
        });
        if (repaired != null) {
          _checkpoint = repaired;
          return;
        }
      }
      final legacy = Map<Object?, Object?>.from(raw)..remove('adventure');
      legacy['car'] = campX;
      final safe = ValleyCheckpoint.fromJson(legacy);
      if (safe != null) _checkpoint = safe;
    }
  }

  Map<String, dynamic> toJson() => _checkpoint.toJson();
}
