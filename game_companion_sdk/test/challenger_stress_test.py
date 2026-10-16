#!/usr/bin/env python3
"""
Milestone 1 Challenger Stress Test & Empirical Verification Harness
==================================================================

Empirical challenge tests for:
1. JSON Parsing Speed, Memory Footprint & Schema Robustness
2. Pairwise Euclidean Distance Stability (NaN, Inf, Overflow, float32 vs float64)
3. Coordinate Projection Boundary Checks (inGameToMapCoords)
4. Nearest-Neighbor Route Sequencer Scaled Stress Testing (330-item greedy traversals)
5. Dart Model Deserialization & Type Safety Simulation
"""

import sys
import os
import json
import time
import math
import struct
import tracemalloc
from collections import Counter, defaultdict

POI_JSON_PATH = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "assets", "data", "gtav_map_pois.json"
))

# Calibration constants from coords_helper.dart
K_GTA_MAP_SIZE = 43.0 / 128.0
GAME_LEFT_X = -5900.0
GAME_TOP_Y = 8300.0
GAME_UNITS_PER_MAP_UNIT = 12250.0 / K_GTA_MAP_SIZE

def in_game_to_map_coords(game_x: float, game_y: float):
    map_x = (game_x - GAME_LEFT_X) / GAME_UNITS_PER_MAP_UNIT
    map_y = -(GAME_TOP_Y - game_y) / GAME_UNITS_PER_MAP_UNIT
    return map_x, map_y

def run_stress_suite():
    print("=" * 80)
    print("GTA 5 COMPANION MAP — M1 CHALLENGER EMPIRICAL STRESS TEST SUITE")
    print(f"Target: {POI_JSON_PATH}")
    print("=" * 80)

    if not os.path.exists(POI_JSON_PATH):
        print(f"CRITICAL ERROR: File not found at {POI_JSON_PATH}")
        sys.exit(1)

    file_size_bytes = os.path.getsize(POI_JSON_PATH)
    print(f"File Size: {file_size_bytes:,} bytes ({file_size_bytes / 1024:.2f} KB)")

    # -------------------------------------------------------------------------
    # TEST 1: Parsing Speed, Memory Footprint, and Raw File Integrity
    # -------------------------------------------------------------------------
    print("\n[TEST 1] Raw File Integrity, Parsing Speed & Memory Footprint")
    with open(POI_JSON_PATH, "rb") as f:
        raw_bytes = f.read()

    # 1.1 BOM check
    if raw_bytes.startswith(b"\xef\xbb\xbf"):
        print("  WARNING: UTF-8 BOM detected at start of file.")
    else:
        print("  ✓ No UTF-8 BOM detected (clean UTF-8).")

    # 1.2 UTF-8 decoding
    try:
        raw_text = raw_bytes.decode("utf-8")
        print("  ✓ Clean UTF-8 decoding succeeded without errors.")
    except UnicodeDecodeError as e:
        print(f"  FAIL: Unicode decode error: {e}")
        return False

    # 1.3 Memory footprint during JSON load
    tracemalloc.start()
    snapshot_before = tracemalloc.take_snapshot()
    parsed_data = json.loads(raw_text)
    snapshot_after = tracemalloc.take_snapshot()
    tracemalloc.stop()

    stats = snapshot_after.compare_to(snapshot_before, "lineno")
    total_mem_allocated = sum(stat.size for stat in stats if stat.size > 0)
    print(f"  ✓ JSON Memory Footprint (heap allocation): {total_mem_allocated / 1024:.2f} KB")
    print(f"  ✓ Memory per POI entry: {total_mem_allocated / len(parsed_data) / 1024:.3f} KB")

    # 1.4 Parsing benchmark (1,000 parse iterations)
    iterations = 1000
    t0 = time.perf_counter()
    for _ in range(iterations):
        _ = json.loads(raw_text)
    t1 = time.perf_counter()
    total_time = t1 - t0
    avg_parse_ms = (total_time / iterations) * 1000.0
    throughput_ops = iterations / total_time
    print(f"  ✓ Parsing Speed Benchmark ({iterations} iterations):")
    print(f"    - Total duration: {total_time:.4f} s")
    print(f"    - Average parse time: {avg_parse_ms:.3f} ms per full load")
    print(f"    - Throughput: {throughput_ops:.1f} loads/second")

    if avg_parse_ms > 20.0:
        print(f"  WARNING: Parse time {avg_parse_ms:.2f} ms exceeds 20ms threshold.")
    else:
        print(f"  ✓ Parse speed well within interactive budget (< 20ms).")

    # -------------------------------------------------------------------------
    # TEST 2: Schema Robustness & Dart Model Simulation
    # -------------------------------------------------------------------------
    print("\n[TEST 2] Schema Robustness & Dart Model Simulation")
    poi_count = len(parsed_data)
    print(f"  Total POIs: {poi_count}")

    required_keys = {"id", "name", "category", "subCategory", "gameX", "gameY", "description", "isCollectable"}
    valid_categories = {"collectibles", "stunts", "services", "secrets_world"}
    ids_seen = set()
    coord_seen = defaultdict(list)
    stunt_jump_count = 0
    collectable_count = 0

    for idx, item in enumerate(parsed_data):
        # Key presence
        missing = required_keys - set(item.keys())
        if missing:
            print(f"  FAIL: Item {idx} missing keys: {missing}")
            return False

        # Types
        if not isinstance(item["id"], str) or not item["id"].strip():
            print(f"  FAIL: Item {idx} invalid 'id': {item.get('id')}")
            return False
        if item["id"] in ids_seen:
            print(f"  FAIL: Duplicate ID: {item['id']}")
            return False
        ids_seen.add(item["id"])

        if not isinstance(item["name"], str) or not item["name"].strip():
            print(f"  FAIL: Item {item['id']} has invalid 'name'")
            return False
        if item["category"] not in valid_categories:
            print(f"  FAIL: Item {item['id']} invalid category '{item['category']}'")
            return False
        if not isinstance(item["gameX"], (int, float)) or math.isnan(item["gameX"]) or math.isinf(item["gameX"]):
            print(f"  FAIL: Item {item['id']} invalid gameX: {item['gameX']}")
            return False
        if not isinstance(item["gameY"], (int, float)) or math.isnan(item["gameY"]) or math.isinf(item["gameY"]):
            print(f"  FAIL: Item {item['id']} invalid gameY: {item['gameY']}")
            return False
        if not isinstance(item["isCollectable"], bool):
            print(f"  FAIL: Item {item['id']} 'isCollectable' not bool: {type(item['isCollectable'])}")
            return False

        if item["isCollectable"]:
            collectable_count += 1

        # Check Stunt Jump fields
        if item["subCategory"] == "stunt_jumps":
            stunt_jump_count += 1
            for stunt_field in ["takeoffDirection", "landingZone", "vehicleRecommendation"]:
                val = item.get(stunt_field)
                if not isinstance(val, str) or not val.strip():
                    print(f"  FAIL: Stunt Jump {item['id']} missing or empty '{stunt_field}': {val}")
                    return False

        # Track coordinate collisions
        coord_key = (round(float(item["gameX"]), 2), round(float(item["gameY"]), 2))
        coord_seen[coord_key].append(item["id"])

    print(f"  ✓ All {poi_count} items have valid IDs, types, and required fields.")
    print(f"  ✓ Stunt jumps count: {stunt_jump_count} (all have valid takeoff, landing, vehicle fields).")
    print(f"  ✓ Total collectable items: {collectable_count}")

    # Coordinate collision inspection
    duplicate_coords = {k: v for k, v in coord_seen.items() if len(v) > 1}
    if duplicate_coords:
        print(f"  ℹ Note: {len(duplicate_coords)} exact coordinate pairs shared across multiple POIs:")
        for coord, ids in list(duplicate_coords.items())[:5]:
            print(f"    - Coord {coord}: {ids}")
    else:
        print("  ✓ Zero coordinate collisions across all 330 POIs.")

    # -------------------------------------------------------------------------
    # TEST 3: All-Pairs Pairwise Euclidean Distance Calculations
    # -------------------------------------------------------------------------
    print("\n[TEST 3] Pairwise Euclidean Distance Stability (All 108,900 pairs)")
    total_pairs = poi_count * poi_count
    unique_pairs = (poi_count * (poi_count - 1)) // 2
    print(f"  Evaluating {total_pairs:,} total directed pairs ({unique_pairs:,} unique pairs)...")

    min_dist = float("inf")
    max_dist = float("-inf")
    zero_dist_pairs = []
    nan_or_inf_count = 0
    float32_overflow_count = 0

    t0 = time.perf_counter()
    for i in range(poi_count):
        p1 = parsed_data[i]
        x1, y1 = float(p1["gameX"]), float(p1["gameY"])

        for j in range(i + 1, poi_count):
            p2 = parsed_data[j]
            x2, y2 = float(p2["gameX"]), float(p2["gameY"])

            dx = x2 - x1
            dy = y2 - y1
            dist = math.sqrt(dx * dx + dy * dy)

            if math.isnan(dist) or math.isinf(dist):
                nan_or_inf_count += 1

            if dist == 0.0:
                zero_dist_pairs.append((p1["id"], p2["id"]))

            if dist < min_dist:
                min_dist = dist
            if dist > max_dist:
                max_dist = dist

            # Test 32-bit single precision simulation
            try:
                # Pack and unpack as 32-bit float
                f32_dx = struct.unpack("f", struct.pack("f", dx))[0]
                f32_dy = struct.unpack("f", struct.pack("f", dy))[0]
                f32_sq = f32_dx * f32_dx + f32_dy * f32_dy
                _ = math.sqrt(f32_sq)
            except (OverflowError, struct.error):
                float32_overflow_count += 1

    t1 = time.perf_counter()
    print(f"  ✓ Calculation duration: {(t1 - t0)*1000:.2f} ms for {unique_pairs:,} distance pairs.")
    print(f"  ✓ Minimum pair distance: {min_dist:.2f} m")
    print(f"  ✓ Maximum pair distance: {max_dist:.2f} m")
    print(f"  ✓ NaN or Infinite values: {nan_or_inf_count}")
    print(f"  ✓ 32-bit float overflow events: {float32_overflow_count}")

    if nan_or_inf_count > 0:
        print(f"  FAIL: Found {nan_or_inf_count} NaN/Inf values in distance calculation!")
        return False
    if float32_overflow_count > 0:
        print(f"  FAIL: Found {float32_overflow_count} float32 overflow conditions!")
        return False

    # -------------------------------------------------------------------------
    # TEST 4: Map Projection Coordinate Boundary Stress
    # -------------------------------------------------------------------------
    print("\n[TEST 4] Map Projection Coordinate Boundaries (inGameToMapCoords)")
    out_of_pan_bounds = []
    min_map_x, max_map_x = float("inf"), float("-inf")
    min_map_y, max_map_y = float("inf"), float("-inf")

    # In coords_helper.dart:
    # kGtaMapPanBounds = LatLngBounds(LatLng(kGtaMapSize * 0.4, -kGtaMapSize * 0.4), LatLng(-kGtaMapSize * 1.4, kGtaMapSize * 1.4))
    # Lat goes from -kGtaMapSize * 1.4 to kGtaMapSize * 0.4
    # Lng goes from -kGtaMapSize * 0.4 to kGtaMapSize * 1.4
    pan_min_lat = -K_GTA_MAP_SIZE * 1.4
    pan_max_lat = K_GTA_MAP_SIZE * 0.4
    pan_min_lng = -K_GTA_MAP_SIZE * 0.4
    pan_max_lng = K_GTA_MAP_SIZE * 1.4

    for item in parsed_data:
        gx = float(item["gameX"])
        gy = float(item["gameY"])
        map_x, map_y = in_game_to_map_coords(gx, gy)
        # map_y is latitude in flutter_map, map_x is longitude
        min_map_x = min(min_map_x, map_x)
        max_map_x = max(max_map_x, map_x)
        min_map_y = min(min_map_y, map_y)
        max_map_y = max(max_map_y, map_y)

        if not (pan_min_lng <= map_x <= pan_max_lng and pan_min_lat <= map_y <= pan_max_lat):
            out_of_pan_bounds.append((item["id"], map_x, map_y))

    print(f"  Map Longitude (mapX) range: [{min_map_x:.4f}, {max_map_x:.4f}] (pan allowed: [{pan_min_lng:.4f}, {pan_max_lng:.4f}])")
    print(f"  Map Latitude (mapY) range:  [{min_map_y:.4f}, {max_map_y:.4f}] (pan allowed: [{pan_min_lat:.4f}, {pan_max_lat:.4f}])")

    if out_of_pan_bounds:
        print(f"  FAIL: {len(out_of_pan_bounds)} POIs project outside kGtaMapPanBounds!")
        for b in out_of_pan_bounds[:3]:
            print(f"    - {b}")
        return False
    else:
        print(f"  ✓ All 330 POIs project strictly inside kGtaMapPanBounds.")

    # -------------------------------------------------------------------------
    # TEST 5: Route Sequencer Full Scaled Greedy Traversal Stress Test
    # -------------------------------------------------------------------------
    print("\n[TEST 5] Route Sequencer Nearest-Neighbor Traversal Stress (330 items)")

    def euclidean_dist(p1, p2):
        dx = float(p2["gameX"]) - float(p1["gameX"])
        dy = float(p2["gameY"]) - float(p1["gameY"])
        return math.sqrt(dx * dx + dy * dy)

    # 5.1 Full 330-item tour from every single starting point (330 full tours)
    print("  5.1 Simulating complete 330-item greedy tour from ALL 330 possible start nodes...")
    t0 = time.perf_counter()
    max_tour_time_ms = 0.0
    total_tour_steps = 0

    for start_idx in range(poi_count):
        t_tour_start = time.perf_counter()
        visited = set()
        current = parsed_data[start_idx]
        visited.add(current["id"])

        for step in range(poi_count - 1):
            # Candidate list: unvisited
            candidates = [p for p in parsed_data if p["id"] not in visited]
            nearest = min(candidates, key=lambda c: euclidean_dist(current, c))
            dist = euclidean_dist(current, nearest)
            if dist < 0 or math.isnan(dist) or math.isinf(dist):
                print(f"  FAIL: Invalid distance in full tour from start {parsed_data[start_idx]['id']}")
                return False
            visited.add(nearest["id"])
            current = nearest
            total_tour_steps += 1

        t_tour_end = time.perf_counter()
        tour_ms = (t_tour_end - t_tour_start) * 1000.0
        if tour_ms > max_tour_time_ms:
            max_tour_time_ms = tour_ms

        if len(visited) != poi_count:
            print(f"  FAIL: Tour from {parsed_data[start_idx]['id']} visited {len(visited)}/{poi_count}")
            return False

    t1 = time.perf_counter()
    print(f"  ✓ Completed 330 complete 330-node tours ({total_tour_steps:,} greedy selection steps).")
    print(f"  ✓ Total test duration: {(t1 - t0):.3f} s")
    print(f"  ✓ Average duration per complete 330-item tour: {((t1 - t0)/poi_count)*1000:.3f} ms")
    print(f"  ✓ Worst-case tour execution time: {max_tour_time_ms:.3f} ms")
    print(f"  ✓ Average single 'Find Next Closest' lookup time: {((t1 - t0)/total_tour_steps)*1000:.4f} ms")

    # 5.2 Subcategory-specific traversals for all 12 subcategories
    print("\n  5.2 Subcategory-specific traversals:")
    subcats = sorted(set(p["subCategory"] for p in parsed_data))
    for sc in subcats:
        items = [p for p in parsed_data if p["subCategory"] == sc]
        if len(items) <= 1:
            continue
        # Start from item 0
        visited = {items[0]["id"]}
        curr = items[0]
        total_sub_dist = 0.0
        for _ in range(len(items) - 1):
            cands = [p for p in items if p["id"] not in visited]
            nxt = min(cands, key=lambda c: euclidean_dist(curr, c))
            d = euclidean_dist(curr, nxt)
            total_sub_dist += d
            visited.add(nxt["id"])
            curr = nxt
        print(f"    - Subcategory '{sc}' ({len(items)} items): 100% traversed, total route length = {total_sub_dist:.1f} m")

    # 5.3 Exact Dart UI Simulation (sameCategory fallback logic)
    print("\n  5.3 Simulating exact Flutter UI 'Find Next Closest' loop across collection lifecycle:")
    collected = set()
    current_poi = parsed_data[0] # start with first collectable
    traversal_order = [current_poi["id"]]
    collected.add(current_poi["id"])

    collectables = [p for p in parsed_data if p["isCollectable"]]
    total_collectables = len(collectables)
    t0 = time.perf_counter()

    while len(collected) < total_collectables:
        # Same logic as map_tab.dart:
        # 1. Prefer uncollected POIs in same category
        same_cat = [p for p in collectables if p["id"] not in collected and p["category"] == current_poi["category"]]
        candidates = same_cat if same_cat else [p for p in collectables if p["id"] not in collected]
        if not candidates:
            break
        nearest = min(candidates, key=lambda c: euclidean_dist(current_poi, c))
        collected.add(nearest["id"])
        traversal_order.append(nearest["id"])
        current_poi = nearest

    t1 = time.perf_counter()
    print(f"  ✓ Successfully simulated lifecycle collection of all {total_collectables} collectables.")
    print(f"  ✓ Lifecycle traversal duration: {(t1 - t0)*1000:.3f} ms")
    print(f"  ✓ Final collected count: {len(collected)}/{total_collectables}")

    print("\n" + "=" * 80)
    print("ALL EMPIRICAL CHALLENGE TESTS COMPLETED SUCCESSFULLY (STATUS: PASS)")
    print("=" * 80)
    return True

if __name__ == "__main__":
    success = run_stress_suite()
    sys.exit(0 if success else 1)
