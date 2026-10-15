import 'package:flutter_riverpod/flutter_riverpod.dart';

final cdnResolverProvider = Provider<CdnResolverService>((ref) {
  return CdnResolverService();
});

class CdnResolverService {
  final String primaryBaseUrl;
  final String fallbackBaseUrl;
  final bool useFallback;

  CdnResolverService({
    this.primaryBaseUrl = 'https://mickymc95.github.io/game_companion_app/media/',
    this.fallbackBaseUrl = 'https://cdn.jsdelivr.net/gh/Mickymc95/game_companion_app@main/web/media/',
    this.useFallback = false,
  });

  String get _baseUrl => useFallback ? fallbackBaseUrl : primaryBaseUrl;

  String resolveVehicleImage(String gameId, String vehicleId) {
    return '$_baseUrl$gameId/vehicles/$vehicleId.webp';
  }

  String resolveWeaponImage(String gameId, String weaponId) {
    return '$_baseUrl$gameId/weapons/$weaponId.webp';
  }

  String resolvePoiImage(String gameId, String poiId) {
    return '$_baseUrl$gameId/pois/$poiId.webp';
  }
}
