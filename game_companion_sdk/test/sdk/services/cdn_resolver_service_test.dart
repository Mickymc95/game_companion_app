import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/services/cdn_resolver_service.dart';

void main() {
  group('CdnResolverService Tests', () {
    test('Should resolve URLs using primary base URL by default', () {
      final service = CdnResolverService(
        primaryBaseUrl: 'https://primary.cdn/',
        fallbackBaseUrl: 'https://fallback.cdn/',
        useFallback: false,
      );

      expect(
        service.resolveVehicleImage('gtav', 'adder'),
        'https://primary.cdn/gtav/vehicles/adder.webp',
      );
      expect(
        service.resolveWeaponImage('gtav', 'pistol'),
        'https://primary.cdn/gtav/weapons/pistol.webp',
      );
      expect(
        service.resolvePoiImage('gtav', 'ammunation'),
        'https://primary.cdn/gtav/pois/ammunation.webp',
      );
    });

    test('Should resolve URLs using fallback base URL when useFallback is true', () {
      final service = CdnResolverService(
        primaryBaseUrl: 'https://primary.cdn/',
        fallbackBaseUrl: 'https://fallback.cdn/',
        useFallback: true,
      );

      expect(
        service.resolveVehicleImage('gtav', 'adder'),
        'https://fallback.cdn/gtav/vehicles/adder.webp',
      );
    });
  });
}
