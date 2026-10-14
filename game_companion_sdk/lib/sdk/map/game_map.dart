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
        initialCenter: const LatLng.unsafe(-4096.0, 4096.0),
        initialZoom: 2.2,
        minZoom: 1.0,
        maxZoom: 5.0,
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