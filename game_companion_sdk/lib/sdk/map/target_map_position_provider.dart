import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class TargetMapPosition {
  final LatLng position;
  final double zoom;
  final String? poiId;

  TargetMapPosition({
    required this.position,
    required this.zoom,
    this.poiId,
  });
}

final targetMapPositionProvider = StateProvider<TargetMapPosition?>((ref) => null);
