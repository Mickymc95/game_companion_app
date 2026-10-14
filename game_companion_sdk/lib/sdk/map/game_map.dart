import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GameMap extends StatelessWidget {
  final String tileUrlTemplate;
  final String fallbackAsset;
  final List<Marker> markers;
  final LatLngBounds bounds;

  const GameMap({
    super.key,
    required this.tileUrlTemplate,
    required this.fallbackAsset,
    required this.markers,
    required this.bounds,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(0, 0),
        initialZoom: 1,
        minZoom: 0,
        maxZoom: 5,
        cameraConstraint: CameraConstraint.contain(bounds: bounds),
        crs: const CrsSimple(),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrlTemplate,
          fallbackUrl: tileUrlTemplate,
          errorImage: AssetImage(fallbackAsset),
          errorTileCallback: (tile, error, stackTrace) {
              // Log or handle error if needed
          },
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
