import 'expedition_world.dart';

class IslandStory {
  final Set<IslandRegion> visited = {IslandRegion.valley};
  bool rockCleared = false,
      picnicReady = false,
      caveOpen = false,
      lampFound = false;
  bool flyerRescued = false, sailedHome = false, celebrated = false;
  int memories = 0;
  bool get readyForHome =>
      picnicReady && lampFound && flyerRescued && sailedHome;
  bool exitOpen(IslandRegion region, bool joined) => switch (region) {
    IslandRegion.valley => joined,
    IslandRegion.orchard => rockCleared && picnicReady,
    IslandRegion.cave => caveOpen && lampFound,
    IslandRegion.bay => flyerRescued,
  };
  Map<String, dynamic> toJson() => {
    'visited': visited.map((v) => v.name).toList(),
    'rock': rockCleared,
    'picnic': picnicReady,
    'door': caveOpen,
    'lamp': lampFound,
    'flyer': flyerRescued,
    'sailed': sailedHome,
    'celebrated': celebrated,
    'memories': memories,
  };
  void restore(Map<String, dynamic> d) {
    visited
      ..clear()
      ..add(IslandRegion.valley);
    for (final name in (d['visited'] as List? ?? [])) {
      for (final r in IslandRegion.values) {
        if (r.name == name) visited.add(r);
      }
    }
    rockCleared = d['rock'] == true;
    picnicReady = d['picnic'] == true;
    caveOpen = d['door'] == true;
    lampFound = d['lamp'] == true;
    flyerRescued = d['flyer'] == true;
    sailedHome = d['sailed'] == true;
    celebrated = d['celebrated'] == true;
    final count = d['memories'];
    memories = count is int ? count.clamp(0, 999) : 0;
    if (picnicReady) rockCleared = true;
    if (lampFound) caveOpen = true;
    if (sailedHome) flyerRescued = true;
    if (celebrated && !readyForHome) celebrated = false;
  }

  void restart() {
    final keep = memories;
    restore({'memories': keep});
  }
}
