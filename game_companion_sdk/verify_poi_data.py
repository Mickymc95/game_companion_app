#!/usr/bin/env python3
"""
GTA 5 Companion Map — End-to-End POI Data Verification Harness
==============================================================

Automated verification harness implementing the systematic 4-tier methodology:
  - Tier 1: Feature Coverage & Subcategory Counts (stunt jumps, spaceship parts, etc.)
  - Tier 2: Boundary & Corner Cases (coordinates [-4000, 4500] x [-4000, 8000], nulls, IDs)
  - Tier 3: Cross-Feature Combinations (category alignment, collectable flags, stunt fields)
  - Tier 4: Real-World Application Scenarios (Euclidean route sequencing & completion tracker)

Usages:
  python3 verify_poi_data.py
  python3 verify_poi_data.py --file path/to/gtav_map_pois.json
  python3 verify_poi_data.py --tier 1
  python3 verify_poi_data.py --self-test
"""

import sys
import os
import json
import math
import argparse
from typing import List, Dict, Any, Tuple, Optional, Set

# --- Canonical Constants & Thresholds ---
COORDINATE_BOUNDS = {
    "min_x": -4000.0,
    "max_x": 4500.0,
    "min_y": -4000.0,
    "max_y": 8000.0,
}

TARGET_SUBCATEGORY_COUNTS = {
    "stunt_jumps": 50,
    "spaceship_parts": 50,
    "letter_scraps": 50,
    "submarine_pieces": 30,
    "nuclear_waste": 30,
    "peyote_plants": 27,
    "under_the_bridge": 50,
    "knife_flights": 15,
}

REQUIRED_CURATED_SUBCATEGORIES = [
    "secrets_easter_eggs",
    "properties",  # or safehouses
    "vehicle_spawns",  # or encounters
]

CATEGORY_SUBCATEGORY_MAP = {
    "collectibles": {
        "spaceship_parts",
        "letter_scraps",
        "submarine_pieces",
        "nuclear_waste",
        "peyote_plants",
    },
    "stunts": {
        "stunt_jumps",
        "under_the_bridge",
        "knife_flights",
    },
    "services": {
        "properties",
        "safehouses",
        "commercial_properties",
        "ammunation",
        "los_santos_customs",
        "marina",
        "helipad",
    },
    "secrets_world": {
        "secrets_easter_eggs",
        "vehicle_spawns",
        "encounters",
        "rare_vehicles",
        "weapon_pickups",
    },
}

COLLECTABLE_SUBCATEGORIES = {
    "stunt_jumps",
    "spaceship_parts",
    "letter_scraps",
    "submarine_pieces",
    "nuclear_waste",
    "peyote_plants",
}

NON_COLLECTABLE_SUBCATEGORIES = {
    "under_the_bridge",
    "knife_flights",
    "secrets_easter_eggs",
    "properties",
    "safehouses",
    "commercial_properties",
    "ammunation",
    "los_santos_customs",
    "marina",
    "helipad",
    "vehicle_spawns",
    "encounters",
    "rare_vehicles",
    "weapon_pickups",
}

MANDATORY_STUNT_FIELDS = [
    "takeoffDirection",
    "landingZone",
    "vehicleRecommendation",
]


def resolve_poi_file_path(custom_path: Optional[str] = None) -> str:
    """Locates the gtav_map_pois.json file across multiple standard directory layouts."""
    if custom_path:
        if os.path.exists(custom_path):
            return os.path.abspath(custom_path)
        raise FileNotFoundError(f"Specified POI dataset file not found: {custom_path}")

    cwd = os.getcwd()
    script_dir = os.path.dirname(os.path.abspath(__file__))

    search_candidates = [
        os.path.join(cwd, "assets", "data", "gtav_map_pois.json"),
        os.path.join(cwd, "game_companion_sdk", "assets", "data", "gtav_map_pois.json"),
        os.path.join(script_dir, "assets", "data", "gtav_map_pois.json"),
        os.path.join(script_dir, "..", "game_companion_sdk", "assets", "data", "gtav_map_pois.json"),
        os.path.join(script_dir, "game_companion_sdk", "assets", "data", "gtav_map_pois.json"),
        "/home/deck/game_companion_app/game_companion_sdk/assets/data/gtav_map_pois.json",
    ]

    for candidate in search_candidates:
        norm = os.path.normpath(candidate)
        if os.path.exists(norm) and os.path.isfile(norm):
            return norm

    raise FileNotFoundError(
        "Could not automatically locate 'gtav_map_pois.json'. "
        f"Searched paths:\n  " + "\n  ".join(search_candidates)
    )


class PoiValidator:
    """Systematic 4-tier verification validator."""

    def __init__(self, data: List[Dict[str, Any]], verbose: bool = False):
        self.data = data
        self.verbose = verbose
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.tier_results: Dict[str, Optional[bool]] = {
            "tier1": None,
            "tier2": None,
            "tier3": None,
            "tier4": None,
        }

    def _log_error(self, tier: str, message: str) -> None:
        self.errors.append(f"[{tier.upper()}] {message}")

    def _log_warning(self, tier: str, message: str) -> None:
        self.warnings.append(f"[{tier.upper()}] {message}")

    # =========================================================================
    # Tier 1: Feature Coverage & Subcategory Counts
    # =========================================================================
    def validate_tier1_counts(self) -> bool:
        """Validates exact counts for all 8 core subcategories and presence of curated POIs."""
        initial_error_count = len(self.errors)

        if not isinstance(self.data, list):
            self._log_error("tier1", f"Top-level JSON structure must be a list, got {type(self.data).__name__}")
            return False

        if len(self.data) == 0:
            self._log_error("tier1", "Dataset is empty (0 POIs found).")
            return False

        # Tally counts per subcategory
        subcat_counts: Dict[str, int] = {}
        for idx, item in enumerate(self.data):
            if not isinstance(item, dict):
                self._log_error("tier1", f"Item at index {idx} is not an object/dict")
                continue
            subcat = item.get("subCategory")
            if subcat:
                subcat_counts[subcat] = subcat_counts.get(subcat, 0) + 1

        # Check exact required counts
        for subcat, target in TARGET_SUBCATEGORY_COUNTS.items():
            actual = subcat_counts.get(subcat, 0)
            if actual != target:
                self._log_error(
                    "tier1",
                    f"Subcategory '{subcat}' count mismatch: expected exactly {target}, found {actual}."
                )

        # Check presence of curated single-player categories
        # Secrets
        secrets_count = subcat_counts.get("secrets_easter_eggs", 0)
        if secrets_count == 0:
            self._log_error("tier1", "Required curated category 'secrets_easter_eggs' is missing or has 0 items.")

        # Properties / Safehouses
        props_count = subcat_counts.get("properties", 0) + subcat_counts.get("safehouses", 0) + subcat_counts.get("commercial_properties", 0)
        if props_count == 0:
            self._log_error("tier1", "Required curated properties/safehouses are missing or have 0 items.")

        # World Spawns / Encounters
        spawns_count = (
            subcat_counts.get("vehicle_spawns", 0)
            + subcat_counts.get("encounters", 0)
            + subcat_counts.get("rare_vehicles", 0)
            + subcat_counts.get("weapon_pickups", 0)
        )
        if spawns_count == 0:
            self._log_error("tier1", "Required curated world spawns/encounters are missing or have 0 items.")

        success = len(self.errors) == initial_error_count
        self.tier_results["tier1"] = success
        return success

    # =========================================================================
    # Tier 2: Boundary & Corner Cases
    # =========================================================================
    def validate_tier2_boundaries_and_schema(self) -> bool:
        """Validates coordinates [-4000, 4500] x [-4000, 8000], unique IDs, and field types."""
        initial_error_count = len(self.errors)

        seen_ids: Set[str] = set()
        duplicate_ids: Dict[str, List[int]] = {}

        min_x = COORDINATE_BOUNDS["min_x"]
        max_x = COORDINATE_BOUNDS["max_x"]
        min_y = COORDINATE_BOUNDS["min_y"]
        max_y = COORDINATE_BOUNDS["max_y"]

        for idx, item in enumerate(self.data):
            if not isinstance(item, dict):
                continue

            item_id = item.get("id")

            # ID Validation
            if not item_id or not isinstance(item_id, str) or item_id.strip() == "":
                self._log_error("tier2", f"Item at index {idx} has invalid or empty 'id': {item_id!r}")
            else:
                if item_id in seen_ids:
                    duplicate_ids.setdefault(item_id, []).append(idx)
                else:
                    seen_ids.add(item_id)

            # Name Validation
            name = item.get("name")
            if not name or not isinstance(name, str) or name.strip() == "":
                self._log_error("tier2", f"Item {item_id or f'index {idx}'} has missing or empty 'name'")

            # Category Validation
            cat = item.get("category")
            if not cat or not isinstance(cat, str) or cat.strip() == "":
                self._log_error("tier2", f"Item {item_id or f'index {idx}'} has missing or empty 'category'")

            # SubCategory Validation
            subcat = item.get("subCategory")
            if not subcat or not isinstance(subcat, str) or subcat.strip() == "":
                self._log_error("tier2", f"Item {item_id or f'index {idx}'} has missing or empty 'subCategory'")

            # Description Validation
            desc = item.get("description")
            if not desc or not isinstance(desc, str) or desc.strip() == "":
                self._log_error("tier2", f"Item {item_id or f'index {idx}'} has missing or empty 'description'")

            # isCollectable Boolean Validation
            is_collectable = item.get("isCollectable")
            if not isinstance(is_collectable, bool):
                self._log_error(
                    "tier2",
                    f"Item {item_id or f'index {idx}'} 'isCollectable' must be a boolean, got {type(is_collectable).__name__}"
                )

            # Coordinate Validation (gameX, gameY)
            for coord_key, (c_min, c_max) in [("gameX", (min_x, max_x)), ("gameY", (min_y, max_y))]:
                val = item.get(coord_key)
                if val is None or isinstance(val, bool) or not isinstance(val, (int, float)):
                    self._log_error(
                        "tier2",
                        f"Item {item_id or f'index {idx}'} '{coord_key}' must be numeric, got {type(val).__name__} ({val!r})"
                    )
                elif math.isnan(val) or math.isinf(val):
                    self._log_error(
                        "tier2",
                        f"Item {item_id or f'index {idx}'} '{coord_key}' is NaN or Infinite: {val}"
                    )
                elif val < c_min or val > c_max:
                    self._log_error(
                        "tier2",
                        f"Item {item_id or f'index {idx}'} '{coord_key}' out of bounds: {val} not in [{c_min}, {c_max}]"
                    )

        # Duplicate ID Error reporting
        if duplicate_ids:
            for dup_id, indices in duplicate_ids.items():
                self._log_error(
                    "tier2",
                    f"Duplicate ID '{dup_id}' found at indices: {indices}"
                )

        success = len(self.errors) == initial_error_count
        self.tier_results["tier2"] = success
        return success

    # =========================================================================
    # Tier 3: Cross-Feature Combinations
    # =========================================================================
    def validate_tier3_cross_feature(self) -> bool:
        """Validates category-subCategory alignment, isCollectable semantics, and Stunt Jump attributes."""
        initial_error_count = len(self.errors)

        for idx, item in enumerate(self.data):
            if not isinstance(item, dict):
                continue

            item_id = item.get("id", f"index_{idx}")
            cat = item.get("category")
            subcat = item.get("subCategory")
            is_collectable = item.get("isCollectable")

            # 1. Category <-> SubCategory Alignment
            if cat in CATEGORY_SUBCATEGORY_MAP:
                allowed_subcats = CATEGORY_SUBCATEGORY_MAP[cat]
                if subcat not in allowed_subcats:
                    self._log_error(
                        "tier3",
                        f"Item '{item_id}': subCategory '{subcat}' is not permitted under category '{cat}'. "
                        f"Expected one of: {sorted(list(allowed_subcats))}"
                    )
            elif cat:
                self._log_error(
                    "tier3",
                    f"Item '{item_id}' has unrecognized top-level category '{cat}'."
                )

            # 2. isCollectable Flag Semantic Verification
            if subcat in COLLECTABLE_SUBCATEGORIES:
                if is_collectable is not True:
                    self._log_error(
                        "tier3",
                        f"Item '{item_id}' in collectible/challenge set '{subcat}' must have 'isCollectable: true', but got {is_collectable}"
                    )
            elif subcat in NON_COLLECTABLE_SUBCATEGORIES:
                if is_collectable is not False:
                    self._log_error(
                        "tier3",
                        f"Item '{item_id}' in non-collectable set '{subcat}' must have 'isCollectable: false', but got {is_collectable}"
                    )

            # 3. Stunt Jump Specific Fields
            if subcat == "stunt_jumps":
                # Check takeoffDirection, landingZone, vehicleRecommendation
                for field in MANDATORY_STUNT_FIELDS:
                    snake_field = "".join(["_" + c.lower() if c.isupper() else c for c in field]).lstrip("_")
                    val = item.get(field) or item.get(snake_field)
                    if not val or not isinstance(val, str) or val.strip() == "":
                        self._log_error(
                            "tier3",
                            f"Stunt Jump '{item_id}' missing mandatory field '{field}' (or '{snake_field}'): got {val!r}"
                        )

        success = len(self.errors) == initial_error_count
        self.tier_results["tier3"] = success
        return success

    # =========================================================================
    # Tier 4: Real-World Application Scenarios Simulation
    # =========================================================================
    def validate_tier4_simulations(self) -> bool:
        """Simulates Euclidean route sequencer nearest-neighbor calculations and completion tracker state mutations."""
        initial_error_count = len(self.errors)

        # 4.1 Route Sequencer Simulation
        # Verify Euclidean distance calculations across subcategories
        pois_by_subcat: Dict[str, List[Dict[str, Any]]] = {}
        for item in self.data:
            if isinstance(item, dict) and "subCategory" in item and "gameX" in item and "gameY" in item:
                pois_by_subcat.setdefault(item["subCategory"], []).append(item)

        def euclidean_distance(p1: Dict[str, Any], p2: Dict[str, Any]) -> float:
            dx = float(p2["gameX"]) - float(p1["gameX"])
            dy = float(p2["gameY"]) - float(p1["gameY"])
            return math.sqrt(dx * dx + dy * dy)

        # Simulate greedy nearest neighbor for each core subcategory
        for subcat, items in pois_by_subcat.items():
            if len(items) < 2:
                continue

            # Greedy traversal simulation from first element
            visited_ids: Set[str] = set()
            current = items[0]
            visited_ids.add(current["id"])

            for step in range(len(items) - 1):
                candidates = [p for p in items if p["id"] not in visited_ids]
                if not candidates:
                    break

                nearest = min(candidates, key=lambda c: euclidean_distance(current, c))
                dist = euclidean_distance(current, nearest)

                if dist < 0 or math.isnan(dist) or math.isinf(dist):
                    self._log_error(
                        "tier4",
                        f"Route sequencer simulation failed in subcat '{subcat}': invalid distance {dist} between {current['id']} and {nearest['id']}"
                    )
                    break

                visited_ids.add(nearest["id"])
                current = nearest

            if len(visited_ids) != len(items):
                self._log_error(
                    "tier4",
                    f"Route sequencer traversal for subcategory '{subcat}' was incomplete: visited {len(visited_ids)}/{len(items)}"
                )

        # 4.2 Completion Tracker State Persistence Simulation
        # Simulate SharedPreferences key-value store ('collected_<id>') and summary computations
        prefs_store: Dict[str, bool] = {}

        for subcat in COLLECTABLE_SUBCATEGORIES:
            subcat_items = pois_by_subcat.get(subcat, [])
            total_count = len(subcat_items)
            if total_count == 0:
                continue

            # Step 1: Initial state - 0 collected
            collected_count = sum(1 for p in subcat_items if prefs_store.get(f"collected_{p['id']}", False))
            if collected_count != 0:
                self._log_error("tier4", f"Initial collection count for {subcat} must be 0, got {collected_count}")

            # Step 2: Toggle 1 item on
            test_poi = subcat_items[0]
            test_id = test_poi["id"]
            pref_key = f"collected_{test_id}"

            prefs_store[pref_key] = True  # Toggle ON
            collected_count = sum(1 for p in subcat_items if prefs_store.get(f"collected_{p['id']}", False))
            remaining_count = total_count - collected_count
            percentage = (collected_count / total_count) * 100.0

            if collected_count != 1 or remaining_count != (total_count - 1):
                self._log_error(
                    "tier4",
                    f"Tracker toggle ON failed for {test_id}: collected={collected_count}, remaining={remaining_count}"
                )

            # Step 3: Toggle item off
            prefs_store.pop(pref_key, None)  # Toggle OFF
            collected_count = sum(1 for p in subcat_items if prefs_store.get(f"collected_{p['id']}", False))
            if collected_count != 0:
                self._log_error("tier4", f"Tracker toggle OFF failed for {test_id}: expected 0, got {collected_count}")

            # Step 4: Batch collection of all items in subcategory
            for p in subcat_items:
                prefs_store[f"collected_{p['id']}"] = True

            collected_count = sum(1 for p in subcat_items if prefs_store.get(f"collected_{p['id']}", False))
            remaining_count = total_count - collected_count
            percentage = (collected_count / total_count) * 100.0

            if collected_count != total_count or remaining_count != 0 or abs(percentage - 100.0) > 1e-6:
                self._log_error(
                    "tier4",
                    f"Batch completion simulation failed for {subcat}: {collected_count}/{total_count} ({percentage}%)"
                )

            # Clean up for subsequent runs
            for p in subcat_items:
                prefs_store.pop(f"collected_{p['id']}", None)

        success = len(self.errors) == initial_error_count
        self.tier_results["tier4"] = success
        return success

    # =========================================================================
    # Runner Orchestration
    # =========================================================================
    def run_all(self, target_tier: Optional[str] = None) -> Tuple[bool, List[str], List[str]]:
        """Executes all tiers or a specified target tier."""
        if target_tier in [None, "all", "1", "tier1"]:
            self.validate_tier1_counts()
        if target_tier in [None, "all", "2", "tier2"]:
            self.validate_tier2_boundaries_and_schema()
        if target_tier in [None, "all", "3", "tier3"]:
            self.validate_tier3_cross_feature()
        if target_tier in [None, "all", "4", "tier4"]:
            self.validate_tier4_simulations()

        is_success = len(self.errors) == 0
        return is_success, self.errors, self.warnings


# =============================================================================
# Built-In Self-Tests (Verifies the Verification Engine itself)
# =============================================================================
def generate_synthetic_valid_dataset() -> List[Dict[str, Any]]:
    """Generates a complete, compliant synthetic dataset satisfying all 4 tiers."""
    dataset: List[Dict[str, Any]] = []

    # 1. 50 Stunt Jumps
    for i in range(1, 51):
        dataset.append({
            "id": f"synth_stunt_jump_{i:02d}",
            "name": f"Synthetic Stunt Jump #{i}",
            "category": "stunts",
            "subCategory": "stunt_jumps",
            "gameX": -2000.0 + (i * 50.0),
            "gameY": -1000.0 + (i * 70.0),
            "description": f"Launch off ramp #{i} over the highway.",
            "takeoffDirection": "North-East 045°",
            "landingZone": "Lower roadway lane",
            "vehicleRecommendation": "Sports Motorcycle (Pegassi Bati 801)",
            "isCollectable": True,
        })

    # 2. 50 Spaceship Parts
    for i in range(1, 51):
        dataset.append({
            "id": f"synth_spaceship_part_{i:02d}",
            "name": f"Synthetic Spaceship Part #{i}",
            "category": "collectibles",
            "subCategory": "spaceship_parts",
            "gameX": -1500.0 + (i * 60.0),
            "gameY": 1000.0 + (i * 80.0),
            "description": f"Glowing green alien component #{i}.",
            "isCollectable": True,
        })

    # 3. 50 Letter Scraps
    for i in range(1, 51):
        dataset.append({
            "id": f"synth_letter_scrap_{i:02d}",
            "name": f"Synthetic Letter Scrap #{i}",
            "category": "collectibles",
            "subCategory": "letter_scraps",
            "gameX": -1000.0 + (i * 40.0),
            "gameY": -500.0 + (i * 60.0),
            "description": f"Confession scrap #{i} solving Leonora Johnson murder.",
            "isCollectable": True,
        })

    # 4. 30 Submarine Pieces
    for i in range(1, 31):
        dataset.append({
            "id": f"synth_submarine_piece_{i:02d}",
            "name": f"Synthetic Submarine Piece #{i}",
            "category": "collectibles",
            "subCategory": "submarine_pieces",
            "gameX": -3000.0 + (i * 100.0),
            "gameY": -2000.0 + (i * 120.0),
            "description": f"Submerged submarine piece #{i} on seabed.",
            "isCollectable": True,
        })

    # 5. 30 Nuclear Waste
    for i in range(1, 31):
        dataset.append({
            "id": f"synth_nuclear_waste_{i:02d}",
            "name": f"Synthetic Nuclear Waste #{i}",
            "category": "collectibles",
            "subCategory": "nuclear_waste",
            "gameX": 2000.0 + (i * 50.0),
            "gameY": -3000.0 + (i * 150.0),
            "description": f"Yellow radioactive waste barrel #{i}.",
            "isCollectable": True,
        })

    # 6. 27 Peyote Plants
    for i in range(1, 28):
        dataset.append({
            "id": f"synth_peyote_plant_{i:02d}",
            "name": f"Synthetic Peyote Plant #{i}",
            "category": "collectibles",
            "subCategory": "peyote_plants",
            "gameX": -500.0 + (i * 80.0),
            "gameY": 3000.0 + (i * 90.0),
            "description": f"Wild hallucinogenic peyote cactus #{i}.",
            "isCollectable": True,
        })

    # 7. 50 Under the Bridge
    for i in range(1, 51):
        dataset.append({
            "id": f"synth_under_the_bridge_{i:02d}",
            "name": f"Synthetic Under the Bridge #{i}",
            "category": "stunts",
            "subCategory": "under_the_bridge",
            "gameX": -800.0 + (i * 35.0),
            "gameY": -1500.0 + (i * 45.0),
            "description": f"Fly aircraft cleanly under bridge span #{i}.",
            "isCollectable": False,
        })

    # 8. 15 Knife Flights
    for i in range(1, 16):
        dataset.append({
            "id": f"synth_knife_flight_{i:02d}",
            "name": f"Synthetic Knife Flight #{i}",
            "category": "stunts",
            "subCategory": "knife_flights",
            "gameX": -100.0 + (i * 30.0),
            "gameY": -600.0 + (i * 40.0),
            "description": f"Perform side-on knife flight between skyscrapers #{i}.",
            "isCollectable": False,
        })

    # Curated Secrets, Properties, Spawns
    dataset.append({
        "id": "synth_secret_chiliad_ufo",
        "name": "Mount Chiliad UFO & Mural",
        "category": "secrets_world",
        "subCategory": "secrets_easter_eggs",
        "gameX": 450.0,
        "gameY": 5600.0,
        "description": "Holographic UFO atop Mt. Chiliad observation deck.",
        "isCollectable": False,
    })
    dataset.append({
        "id": "synth_property_micheal_mansion",
        "name": "Michael's De Santa Mansion",
        "category": "services",
        "subCategory": "properties",
        "gameX": -812.5,
        "gameY": 182.3,
        "description": "Rockford Hills luxury family residence.",
        "isCollectable": False,
    })
    dataset.append({
        "id": "synth_spawn_adder_portola",
        "name": "Truffade Adder Rare Spawn",
        "category": "secrets_world",
        "subCategory": "vehicle_spawns",
        "gameX": -680.2,
        "gameY": -230.4,
        "description": "Fixed spawn of the Truffade Adder on Portola Drive.",
        "isCollectable": False,
    })

    return dataset


def run_self_tests() -> bool:
    """Executes verification harness self-tests across valid and mutated invalid datasets."""
    print("================================================================================")
    print("RUNNING VERIFICATION HARNESS SELF-TESTS (Synthetic Fixture Suite)")
    print("================================================================================")

    # 1. Test Valid Dataset
    valid_data = generate_synthetic_valid_dataset()
    validator = PoiValidator(valid_data)
    ok, errors, _ = validator.run_all()
    if not ok:
        print("FAIL: Synthetic valid dataset did not pass verification!")
        for e in errors:
            print("  ", e)
        return False
    print("✓ PASS: Synthetic valid dataset (305 items) passed all 4 tiers cleanly.")

    # 2. Defect Injections - Validate Failure Detections
    defect_scenarios = [
        ("Duplicate ID Injection", lambda d: d[0].update({"id": d[1]["id"]}), "Duplicate ID"),
        ("X Out of Bounds (>4500)", lambda d: d[0].update({"gameX": 4900.0}), "out of bounds"),
        ("Y Out of Bounds (<-4000)", lambda d: d[0].update({"gameY": -4500.0}), "out of bounds"),
        ("Missing Takeoff Direction", lambda d: d[0].pop("takeoffDirection", None), "missing mandatory field"),
        ("Subcategory Count Deficit", lambda d: d.pop(0), "count mismatch"),
        ("isCollectable Non-Bool", lambda d: d[0].update({"isCollectable": "yes"}), "must be a boolean"),
        ("Category Mismatch", lambda d: d[0].update({"category": "collectibles"}), "not permitted under category"),
        ("Empty Description", lambda d: d[0].update({"description": "   "}), "empty 'description'"),
    ]

    for name, mutator, expected_err_sub in defect_scenarios:
        mutated_data = generate_synthetic_valid_dataset()
        mutator(mutated_data)
        mut_validator = PoiValidator(mutated_data)
        mut_ok, mut_errors, _ = mut_validator.run_all()

        if mut_ok:
            print(f"FAIL: Defect scenario '{name}' unexpectedly PASSED verification!")
            return False

        matched = any(expected_err_sub.lower() in err.lower() for err in mut_errors)
        if not matched:
            print(f"FAIL: Defect scenario '{name}' failed but did not contain expected diagnostic '{expected_err_sub}'")
            print("  Actual errors:", mut_errors[:3])
            return False

        print(f"✓ PASS: Defect scenario '{name}' correctly intercepted with diagnostic.")

    print("================================================================================")
    print("ALL VERIFICATION HARNESS SELF-TESTS PASSED (Engine Integrity Verified 100%)")
    print("================================================================================\n")
    return True


# =============================================================================
# Main CLI Entry Point
# =============================================================================
def main() -> int:
    parser = argparse.ArgumentParser(
        description="GTA 5 Companion Map — End-to-End POI Data Verification Harness"
    )
    parser.add_argument(
        "--file", "-f",
        type=str,
        default=None,
        help="Path to gtav_map_pois.json file (auto-discovered if omitted)"
    )
    parser.add_argument(
        "--tier", "-t",
        type=str,
        default="all",
        choices=["1", "2", "3", "4", "all"],
        help="Execute only a specific tier or all tiers (default: all)"
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run verification harness self-tests using synthetic compliant and defect fixtures"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Display detailed per-item diagnostics"
    )

    args = parser.parse_args()

    # If self-test requested, run self-tests
    if args.self_test:
        success = run_self_tests()
        return 0 if success else 1

    # Locate and load the POI dataset
    try:
        poi_file_path = resolve_poi_file_path(args.file)
    except FileNotFoundError as err:
        print(f"ERROR: {err}", file=sys.stderr)
        return 1

    print("================================================================================")
    print("GTA 5 COMPANION MAP — POI DATASET E2E VERIFICATION")
    print("================================================================================")
    print(f"Dataset Path : {poi_file_path}")
    print(f"Target Tier  : {args.tier}")
    print("--------------------------------------------------------------------------------")

    try:
        with open(poi_file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as err:
        print(f"FATAL: Malformed JSON syntax in '{poi_file_path}':\n  Line {err.lineno}, Col {err.colno}: {err.msg}", file=sys.stderr)
        return 1
    except Exception as err:
        print(f"FATAL: Failed to read POI dataset file: {err}", file=sys.stderr)
        return 1

    total_pois = len(data) if isinstance(data, list) else 0
    print(f"Total POIs Loaded : {total_pois}")
    print("--------------------------------------------------------------------------------")

    validator = PoiValidator(data, verbose=args.verbose)
    is_success, errors, warnings = validator.run_all(target_tier=args.tier)

    # Print Tier Results Summary Table
    print(f"{'Tier':<10} | {'Description':<45} | {'Result':<10}")
    print("-" * 72)
    tier_meta = [
        ("Tier 1", "Feature Coverage & Subcategory Counts", validator.tier_results["tier1"]),
        ("Tier 2", "Boundary & Corner Cases (Coords, IDs, Schema)", validator.tier_results["tier2"]),
        ("Tier 3", "Cross-Feature Combinations & Stunt Jump Specs", validator.tier_results["tier3"]),
        ("Tier 4", "Real-World Scenarios (Routing & Tracker Sim)", validator.tier_results["tier4"]),
    ]

    for t_id, desc, passed in tier_meta:
        if passed is None:
            res_str = "SKIPPED -"
        elif passed:
            res_str = "PASS ✓"
        else:
            res_str = "FAIL ✗"
        print(f"{t_id:<10} | {desc:<45} | {res_str:<10}")

    print("================================================================================")

    if warnings:
        print(f"\nWARNINGS ({len(warnings)}):")
        for w in warnings[:15]:
            print(f"  [!] {w}")
        if len(warnings) > 15:
            print(f"  ... and {len(warnings) - 15} more warnings.")

    if not is_success:
        print(f"\nFAILURES ENCOUNTERED ({len(errors)} errors):", file=sys.stderr)
        for e in errors[:25]:
            print(f"  [-] {e}", file=sys.stderr)
        if len(errors) > 25:
            print(f"  ... and {len(errors) - 25} additional errors.", file=sys.stderr)
        print("\nOVERALL STATUS: FAILED (Exit Code 1)", file=sys.stderr)
        return 1

    print("\nOVERALL STATUS: ALL CHECKS PASSED (Exit Code 0)")
    print("Zero errors found. POI dataset fully satisfies GTA V Single-Player requirements!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
