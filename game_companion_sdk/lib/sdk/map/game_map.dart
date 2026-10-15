import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GameMap extends StatelessWidget {
  final String tileUrlTemplate;
  final String fallbackAsset;
  final List<Marker> markers;
  final LatLngBounds? bounds;
  final MapController? mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final TileProvider? tileProvider;

  /// Highest zoom level the tile server actually provides. Beyond this the
  /// tiles from this level are upscaled instead of requesting missing tiles.
  final int maxNativeZoom;

  /// Colour shown behind/around the tiles (e.g. the ocean colour of the map).
  final Color backgroundColor;

  const GameMap({
    super.key,
    required this.tileUrlTemplate,
    required this.fallbackAsset,
    required this.markers,
    this.bounds,
    this.mapController,
    this.initialCenter = const LatLng(0, 0),
    this.initialZoom = 2.8,
    this.minZoom = 1.5,
    this.maxZoom = 7.0,
    this.maxNativeZoom = 7,
    this.backgroundColor = const Color(0xFF1E5AA0),
    this.tileProvider,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        backgroundColor: backgroundColor,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          enableMultiFingerGestureRace: true,
        ),
        cameraConstraint: bounds != null
            ? CameraConstraint.containCenter(bounds: bounds!)
            : const CameraConstraint.unconstrained(),
        crs: const CrsSimple(),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrlTemplate,
          maxNativeZoom: maxNativeZoom,
          tileProvider: tileProvider ?? NetworkTileProvider(silenceExceptions: true),
          panBuffer: 1,
          keepBuffer: 3,
          tileDisplay: const TileDisplay.fadeIn(
            duration: Duration(milliseconds: 100),
          ),
          errorImage: AssetImage(fallbackAsset),
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}