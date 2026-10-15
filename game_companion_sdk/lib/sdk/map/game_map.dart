import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GameMap extends StatelessWidget {
  final String tileUrlTemplate;
  final String fallbackAsset;
  final List<Marker> markers;
  final LatLngBounds? bounds;

  const GameMap({
    super.key,
    required this.tileUrlTemplate,
    required this.fallbackAsset,
    required this.markers,
    this.bounds,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(-45.0, 45.0),
        initialZoom: 2.2,
        minZoom: 1.0,
        maxZoom: 5.0,
        cameraConstraint: bounds != null
            ? CameraConstraint.contain(bounds: bounds!)
            : const CameraConstraint.unconstrained(),
        crs: const CrsSimple(),
      ),
      children: [
        if (bounds != null)
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                bounds: bounds!,
                imageProvider: AssetImage(fallbackAsset),
              )
            ]
          ),
        TileLayer(
          urlTemplate: tileUrlTemplate,
          fallbackUrl: tileUrlTemplate,
          errorImage: AssetImage(fallbackAsset),
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
