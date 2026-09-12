import 'expedition_models.dart';

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
    if (data != null) _checkpoint = data;
  }

  Map<String, dynamic> toJson() => _checkpoint.toJson();
}
