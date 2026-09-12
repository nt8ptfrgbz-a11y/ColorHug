import 'package:flutter/painting.dart';

enum IslandRegion { valley, orchard, cave, bay }

class RegionInfo {
  const RegionInfo(this.title, this.english, this.end, this.sky, this.ground);
  final String title, english;
  final double end;
  final Color sky, ground;
}

const islandRegions = {
  IslandRegion.valley: RegionInfo(
    '朋友河谷',
    'Friendship Valley',
    2250,
    Color(0xFFE2EEDD),
    Color(0xFFABC195),
  ),
  IslandRegion.orchard: RegionInfo(
    '丰收果林',
    'Apple Orchard',
    1900,
    Color(0xFFFAE3BE),
    Color(0xFFD3C58F),
  ),
  IslandRegion.cave: RegionInfo(
    '萤火山洞',
    'Firefly Cave',
    1550,
    Color(0xFF39465F),
    Color(0xFF687B85),
  ),
  IslandRegion.bay: RegionInfo(
    '贝壳海湾',
    'Shell Bay',
    1950,
    Color(0xFFCDEBE5),
    Color(0xFFE4D3AC),
  ),
};

class IslandTarget {
  const IslandTarget(this.id, this.at, this.label, {this.radius = 45});
  final String id, label;
  final Offset at;
  final double radius;
}
