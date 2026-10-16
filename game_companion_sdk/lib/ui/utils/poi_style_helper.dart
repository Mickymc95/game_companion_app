import 'package:flutter/material.dart';
import '../../sdk/models/map_poi.dart';

/// Presentation styling metadata for a POI marker.
class PoiStyle {
  final IconData icon;
  final Color color;
  final String label;

  const PoiStyle({
    required this.icon,
    required this.color,
    required this.label,
  });
}

/// Returns the visual style (distinct icon, color, and label) for a given POI.
PoiStyle getPoiStyle(MapPointOfInterest poi) {
  return getPoiStyleForSubcategory(poi.subCategory);
}

/// Returns the visual style for a subcategory identifier.
PoiStyle getPoiStyleForSubcategory(String subCategory) {
  switch (subCategory) {
    case 'spaceship_parts':
      return const PoiStyle(
        icon: Icons.rocket_launch,
        color: Color(0xFF00E676),
        label: 'Spaceship Part',
      );
    case 'letter_scraps':
      return const PoiStyle(
        icon: Icons.mark_email_unread,
        color: Color(0xFFFFD600),
        label: 'Letter Scrap',
      );
    case 'submarine_pieces':
      return const PoiStyle(
        icon: Icons.sailing,
        color: Color(0xFF00B0FF),
        label: 'Submarine Piece',
      );
    case 'nuclear_waste':
      return const PoiStyle(
        icon: Icons.warning_amber,
        color: Color(0xFFAEEA00),
        label: 'Nuclear Waste',
      );
    case 'peyote_plants':
      return const PoiStyle(
        icon: Icons.eco,
        color: Color(0xFF76FF03),
        label: 'Peyote Plant',
      );
    case 'stunt_jumps':
      return const PoiStyle(
        icon: Icons.sports_motorsports,
        color: Color(0xFFFF6D00),
        label: 'Stunt Jump',
      );
    case 'under_the_bridge':
      return const PoiStyle(
        icon: Icons.flight,
        color: Color(0xFF7C4DFF),
        label: 'Under the Bridge',
      );
    case 'knife_flights':
      return const PoiStyle(
        icon: Icons.airplanemode_active,
        color: Color(0xFFE040FB),
        label: 'Knife Flight',
      );
    case 'properties':
      return const PoiStyle(
        icon: Icons.apartment,
        color: Color(0xFF26A69A),
        label: 'Property / Safehouse',
      );
    case 'safehouses':
      return const PoiStyle(
        icon: Icons.home,
        color: Color(0xFF00897B),
        label: 'Safehouse',
      );
    case 'ammunation':
      return const PoiStyle(
        icon: Icons.shield,
        color: Color(0xFFFF5252),
        label: 'Ammu-Nation',
      );
    case 'secrets_easter_eggs':
    case 'easter_eggs':
      return const PoiStyle(
        icon: Icons.auto_awesome,
        color: Color(0xFFFF4081),
        label: 'Secret / Easter Egg',
      );
    case 'vehicle_spawns':
      return const PoiStyle(
        icon: Icons.directions_car,
        color: Color(0xFFFF9100),
        label: 'Rare Vehicle Spawn',
      );
    case 'encounters':
      return const PoiStyle(
        icon: Icons.person_pin_circle,
        color: Color(0xFF40C4FF),
        label: 'World Encounter',
      );
    default:
      return const PoiStyle(
        icon: Icons.location_on,
        color: Color(0xFF448AFF),
        label: 'Location',
      );
  }
}
