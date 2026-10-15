import 'package:flutter/material.dart';
import '../../sdk/models/wiki_item.dart';

class WikiItemMetadata {
  final IconData icon;
  final String subType;
  final Color accentColor;

  const WikiItemMetadata({
    required this.icon,
    required this.subType,
    required this.accentColor,
  });
}

WikiItemMetadata getWikiItemMetadata(WikiItem item) {
  final id = item.id.toLowerCase();
  final cat = item.category.toLowerCase();

  // Vehicles
  if (cat.contains('vehicle') || id.startsWith('v_')) {
    // Supercars / Hypercars
    if (id == 'v_adder' ||
        id == 'v_t20' ||
        id == 'v_zentorno' ||
        id == 'v_entity_xf' ||
        id == 'v_turismo_r' ||
        id == 'v_cheetah' ||
        id == 'v_infernus' ||
        id == 'v_osiris') {
      return const WikiItemMetadata(
        icon: Icons.speed,
        subType: 'Supercar',
        accentColor: Color(0xFFFFB300), // Amber / Gold
      );
    }
    // Sports & Tuners
    if (id == 'v_elegy_rh8' ||
        id == 'v_banshee' ||
        id == 'v_comet' ||
        id == 'v_jester' ||
        id == 'v_sultan') {
      return const WikiItemMetadata(
        icon: Icons.directions_car,
        subType: 'Sports',
        accentColor: Color(0xFF00B0FF), // Light Blue
      );
    }
    // Muscle Cars
    if (id == 'v_dominator' || id == 'v_gauntlet' || id == 'v_sabre_turbo') {
      return const WikiItemMetadata(
        icon: Icons.local_fire_department,
        subType: 'Muscle',
        accentColor: Color(0xFFFF6D00), // Deep Orange
      );
    }
    // Motorcycles
    if (id == 'v_bati_801' || id == 'v_akuma' || id == 'v_sanchez') {
      return const WikiItemMetadata(
        icon: Icons.two_wheeler,
        subType: 'Motorcycle',
        accentColor: Color(0xFF00E676), // Green
      );
    }
    // Aircraft & Attack Choppers
    if (id == 'v_buzzard' || id == 'v_lazer' || id == 'v_hydra') {
      return const WikiItemMetadata(
        icon: Icons.flight,
        subType: 'Aircraft',
        accentColor: Color(0xFF40C4FF), // Cyan
      );
    }
    // Off-Road & SUVs
    if (id == 'v_sandking_xl' || id == 'v_dubsta' || id == 'v_karin_rebel') {
      return const WikiItemMetadata(
        icon: Icons.terrain,
        subType: 'Off-Road',
        accentColor: Color(0xFFA1887F), // Earth Brown
      );
    }

    return const WikiItemMetadata(
      icon: Icons.directions_car,
      subType: 'Vehicle',
      accentColor: Color(0xFFFFB300),
    );
  }

  // Weapons
  if (cat.contains('weapon') || id.startsWith('w_')) {
    // Handguns
    if (id == 'w_pistol' ||
        id == 'w_combat_pistol' ||
        id == 'w_ap_pistol' ||
        id == 'w_heavy_revolver') {
      return const WikiItemMetadata(
        icon: Icons.security,
        subType: 'Handgun',
        accentColor: Color(0xFF536DFE), // Indigo
      );
    }
    // Submachine Guns
    if (id == 'w_micro_smg' || id == 'w_smg' || id == 'w_combat_pdw') {
      return const WikiItemMetadata(
        icon: Icons.flash_on,
        subType: 'SMG',
        accentColor: Color(0xFFE040FB), // Purple
      );
    }
    // Shotguns
    if (id == 'w_pump_shotgun' ||
        id == 'w_sawed_off_shotgun' ||
        id == 'w_assault_shotgun') {
      return const WikiItemMetadata(
        icon: Icons.whatshot,
        subType: 'Shotgun',
        accentColor: Color(0xFFFF5722), // Flame Orange
      );
    }
    // Rifles
    if (id == 'w_carbine_rifle' ||
        id == 'w_assault_rifle' ||
        id == 'w_special_carbine' ||
        id == 'w_advanced_rifle') {
      return const WikiItemMetadata(
        icon: Icons.track_changes,
        subType: 'Rifle',
        accentColor: Color(0xFF00BFA5), // Teal
      );
    }
    // Snipers
    if (id == 'w_sniper_rifle' ||
        id == 'w_heavy_sniper' ||
        id == 'w_marksman_rifle') {
      return const WikiItemMetadata(
        icon: Icons.filter_center_focus,
        subType: 'Sniper',
        accentColor: Color(0xFF448AFF), // Blue
      );
    }
    // Heavy / Explosive
    if (id == 'w_rpg' || id == 'w_minigun' || id == 'w_sticky_bomb') {
      return const WikiItemMetadata(
        icon: Icons.rocket_launch,
        subType: 'Heavy',
        accentColor: Color(0xFFFF1744), // Crimson
      );
    }
    // Melee
    if (id == 'w_combat_knife') {
      return const WikiItemMetadata(
        icon: Icons.colorize,
        subType: 'Melee',
        accentColor: Color(0xFF78909C), // Steel
      );
    }

    return const WikiItemMetadata(
      icon: Icons.gps_fixed,
      subType: 'Weapon',
      accentColor: Color(0xFFFF5252),
    );
  }

  return const WikiItemMetadata(
    icon: Icons.category,
    subType: 'General',
    accentColor: Colors.grey,
  );
}
