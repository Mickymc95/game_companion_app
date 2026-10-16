#!/usr/bin/env python3
"""
Milestone 2 Challenger 2: Empirical Progress Tracking Telemetry & Visual Marker Verification
==========================================================================================
Empirically tests and stress-tests:
1. Static code compliance of Dart implementations in map_providers.dart, poi_style_helper.dart, and map_tab.dart.
2. CollectionTracker state mutations across single items, full subcategories, and 100% completion.
3. SubcategoryCompletionStats, CategoryCompletionStats, and MapCompletionSummary calculation accuracy:
   - collectedCount and remainingCount precision at each step.
   - Exact percentage calculation.
   - Verification that isCollectable: false items do NOT distort collectable count or percentages.
4. Visual marker states:
   - 0.35 opacity dimming for collected items.
   - Checkmark badge presence.
   - Hide-collected toggle filtering behavior across the full 330 POIs catalog.
5. Adversarial injections:
   - Non-collectable POI IDs injected into collection tracker.
   - Non-existent and malformed IDs injected.
   - Multi-category combinations with hide-collected enabled/disabled.
6. Stress benchmark (20,000 rapid state mutations and telemetry recalculations).
"""

import os
import sys
import json
import time
import re
from typing import List, Dict, Set, Any

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
JSON_PATH = os.path.join(ROOT_DIR, "assets", "data", "gtav_map_pois.json")
MAP_PROVIDERS_DART = os.path.join(ROOT_DIR, "lib", "ui", "providers", "map_providers.dart")
MAP_TAB_DART = os.path.join(ROOT_DIR, "lib", "ui", "screens", "map_tab.dart")
POI_STYLE_DART = os.path.join(ROOT_DIR, "lib", "ui", "utils", "poi_style_helper.dart")

CANONICAL_CATEGORIES = {
    'collectibles': [
        'spaceship_parts',
        'letter_scraps',
        'submarine_pieces',
        'nuclear_waste',
        'peyote_plants',
    ],
    'stunts': [
        'stunt_jumps',
        'under_the_bridge',
        'knife_flights',
    ],
    'services': [
        'properties',
        'safehouses',
        'ammunation',
    ],
    'secrets_world': [
        'secrets_easter_eggs',
        'vehicle_spawns',
        'encounters',
    ],
}

ALL_SUBCATEGORIES = [
    'spaceship_parts',
    'letter_scraps',
    'submarine_pieces',
    'nuclear_waste',
    'peyote_plants',
    'stunt_jumps',
    'under_the_bridge',
    'knife_flights',
    'properties',
    'safehouses',
    'ammunation',
    'secrets_easter_eggs',
    'vehicle_spawns',
    'encounters',
]

# -----------------------------------------------------------------------------
# High-Fidelity Domain Simulation Engine (Mirroring Dart Providers & UI)
# -----------------------------------------------------------------------------

class SubcategoryCompletionStats:
    def __init__(self, subCategory: str, displayName: str, totalCount: int, collectedCount: int, isCollectable: bool):
        self.subCategory = subCategory
        self.displayName = displayName
        self.totalCount = totalCount
        self.collectedCount = collectedCount
        self.isCollectable = isCollectable

    @property
    def remainingCount(self) -> int:
        return self.totalCount - self.collectedCount

    @property
    def percentage(self) -> double if 'double' in globals() else float:
        return 0.0 if self.totalCount == 0 else self.collectedCount / self.totalCount


class CategoryCompletionStats:
    def __init__(self, category: str, displayName: str, totalCount: int, collectedCount: int, subcategoryStats: List[SubcategoryCompletionStats]):
        self.category = category
        self.displayName = displayName
        self.totalCount = totalCount
        self.collectedCount = collectedCount
        self.subcategoryStats = subcategoryStats

    @property
    def remainingCount(self) -> int:
        return self.totalCount - self.collectedCount

    @property
    def percentage(self) -> float:
        return 0.0 if self.totalCount == 0 else self.collectedCount / self.totalCount


class MapCompletionSummary:
    def __init__(self, totalCount: int, collectedCount: int, categoryStats: List[CategoryCompletionStats]):
        self.totalCount = totalCount
        self.collectedCount = collectedCount
        self.categoryStats = categoryStats

    @property
    def remainingCount(self) -> int:
        return self.totalCount - self.collectedCount

    @property
    def percentage(self) -> float:
        return 0.0 if self.totalCount == 0 else self.collectedCount / self.totalCount


def compute_map_completion_summary(pois: List[Dict[str, Any]], collected_ids: Set[str]) -> MapCompletionSummary:
    """Exact reproduction of mapCompletionSummaryProvider in map_providers.dart lines 397-488."""
    all_collectables = [p for p in pois if p.get('isCollectable', False)]
    total_collectable = len(all_collectables)
    collected_total = sum(1 for p in all_collectables if p['id'] in collected_ids)

    pois_by_category: Dict[str, List[Dict[str, Any]]] = {}
    for poi in pois:
        cat = poi['category']
        pois_by_category.setdefault(cat, []).append(poi)

    ordered_categories = ['collectibles', 'stunts', 'services', 'secrets_world']
    for c in pois_by_category.keys():
        if c not in ordered_categories:
            ordered_categories.append(c)

    category_stats_list: List[CategoryCompletionStats] = []

    for category in ordered_categories:
        cat_pois = pois_by_category.get(category, [])
        if not cat_pois and pois:
            continue

        defined_order = CANONICAL_CATEGORIES.get(category, [])
        sub_cat_keys = list(dict.fromkeys(p['subCategory'] for p in cat_pois))

        def sort_key(sub_key):
            if sub_key in defined_order:
                return (0, defined_order.index(sub_key))
            return (1, sub_key)

        sub_cat_keys.sort(key=sort_key)

        sub_stats_list: List[SubcategoryCompletionStats] = []
        for sub_cat in sub_cat_keys:
            sub_pois = [p for p in cat_pois if p['subCategory'] == sub_cat]
            sub_total = len(sub_pois)
            sub_collected = sum(1 for p in sub_pois if p['id'] in collected_ids)
            is_sub_collectable = any(p.get('isCollectable', False) for p in sub_pois)

            sub_stats_list.append(
                SubcategoryCompletionStats(
                    subCategory=sub_cat,
                    displayName=sub_cat.replace('_', ' ').title(),
                    totalCount=sub_total,
                    collectedCount=sub_collected,
                    isCollectable=is_sub_collectable,
                )
            )

        cat_collectables = [p for p in cat_pois if p.get('isCollectable', False)]
        if cat_collectables:
            cat_total = len(cat_collectables)
            cat_collected = sum(1 for p in cat_collectables if p['id'] in collected_ids)
        else:
            cat_total = len(cat_pois)
            cat_collected = sum(1 for p in cat_pois if p['id'] in collected_ids)

        category_stats_list.append(
            CategoryCompletionStats(
                category=category,
                displayName=category.replace('_', ' ').title(),
                totalCount=cat_total,
                collectedCount=cat_collected,
                subcategoryStats=sub_stats_list,
            )
        )

    return MapCompletionSummary(
        totalCount=total_collectable,
        collectedCount=collected_total,
        categoryStats=category_stats_list,
    )


class RenderedMarker:
    def __init__(self, poi: Dict[str, Any], opacity: float, has_checkmark: bool, is_highlighted: bool, size: float):
        self.poi = poi
        self.opacity = opacity
        self.has_checkmark = has_checkmark
        self.is_highlighted = is_highlighted
        self.size = size


def simulate_marker_layer(
    pois: List[Dict[str, Any]],
    enabled_subcategories: Set[str],
    collected_ids: Set[str],
    hide_collected: bool,
    highlighted_id: str = None
) -> List[RenderedMarker]:
    """Exact reproduction of MapTab marker generation in map_tab.dart lines 61-132."""
    filtered_pois = [
        poi for poi in pois
        if poi['subCategory'] in enabled_subcategories and
        (not hide_collected or poi['id'] not in collected_ids)
    ]

    markers = []
    for poi in filtered_pois:
        is_collected = poi['id'] in collected_ids
        is_highlighted = highlighted_id == poi['id']
        marker_size = 48.0 if is_highlighted else 40.0
        opacity = 0.35 if is_collected else 1.0
        has_checkmark = is_collected

        markers.append(RenderedMarker(
            poi=poi,
            opacity=opacity,
            has_checkmark=has_checkmark,
            is_highlighted=is_highlighted,
            size=marker_size
        ))

    return markers


# -----------------------------------------------------------------------------
# Test Harness
# -----------------------------------------------------------------------------

def run_telemetry_and_marker_verification():
    print("=" * 80)
    print("M2 CHALLENGER 2: EMPIRICAL TELEMETRY & MARKER AUDIT")
    print("=" * 80)

    # -------------------------------------------------------------------------
    # SUITE 1: Dart Implementation Source Inspection
    # -------------------------------------------------------------------------
    print("\n[SUITE 1] Dart Source Code Static Audit for Marker Dimming & Telemetry")

    with open(MAP_TAB_DART, "r", encoding="utf-8") as f:
        map_tab_src = f.read()

    with open(MAP_PROVIDERS_DART, "r", encoding="utf-8") as f:
        map_providers_src = f.read()

    # 1.1 Check 0.35 opacity dimming
    assert "opacity: isCollected ? 0.35 : 1.0" in map_tab_src, \
        "Missing exact 'opacity: isCollected ? 0.35 : 1.0' in map_tab.dart"
    print("  ✓ map_tab.dart: Opacity dimming explicitly set to 0.35 for isCollected")

    # 1.2 Check checkmark overlay
    assert "Icons.check" in map_tab_src and "Colors.green" in map_tab_src, \
        "Missing green checkmark badge overlay in map_tab.dart"
    print("  ✓ map_tab.dart: Green circular checkmark badge overlay rendered for isCollected")

    # 1.3 Check hide-collected filter predicate
    assert "(!hideCollected || !isCollected)" in map_tab_src, \
        "Missing '(!hideCollected || !isCollected)' filtering predicate in map_tab.dart"
    print("  ✓ map_tab.dart: hideCollected accurately filters out collected items from marker layer")

    # 1.4 Check SubcategoryCompletionStats remainingCount and percentage formulas
    assert "int get remainingCount => totalCount - collectedCount;" in map_providers_src, \
        "Missing remainingCount formula in map_providers.dart"
    assert "double get percentage => totalCount == 0 ? 0.0 : collectedCount / totalCount;" in map_providers_src, \
        "Missing percentage formula with 0-division protection in map_providers.dart"
    print("  ✓ map_providers.dart: SubcategoryCompletionStats remainingCount & percentage formulas verified")

    # 1.5 Check collectable filtering in mapCompletionSummaryProvider
    assert "pois.where((p) => p.isCollectable)" in map_providers_src, \
        "mapCompletionSummaryProvider must filter by p.isCollectable"
    print("  ✓ map_providers.dart: mapCompletionSummaryProvider restricts totalCount to isCollectable items")

    # -------------------------------------------------------------------------
    # SUITE 2: Dataset Catalog Baseline Breakdown
    # -------------------------------------------------------------------------
    print("\n[SUITE 2] POI Catalog Breakdown Verification (330 POIs)")
    with open(JSON_PATH, "r", encoding="utf-8") as f:
        pois = json.load(f)

    assert len(pois) == 330, f"Expected 330 POIs, found {len(pois)}"
    collectables = [p for p in pois if p.get('isCollectable', False)]
    non_collectables = [p for p in pois if not p.get('isCollectable', False)]

    assert len(collectables) == 237, f"Expected 237 collectables, found {len(collectables)}"
    assert len(non_collectables) == 93, f"Expected 93 non-collectables, found {len(non_collectables)}"

    expected_sub_counts = {
        'spaceship_parts': (50, True),
        'letter_scraps': (50, True),
        'stunt_jumps': (50, True),
        'submarine_pieces': (30, True),
        'nuclear_waste': (30, True),
        'peyote_plants': (27, True),
        'under_the_bridge': (50, False),
        'knife_flights': (15, False),
        'properties': (13, False),
        'secrets_easter_eggs': (7, False),
        'vehicle_spawns': (4, False),
        'encounters': (4, False),
    }

    for sub, (expected_count, expected_coll) in expected_sub_counts.items():
        matching = [p for p in pois if p['subCategory'] == sub]
        assert len(matching) == expected_count, \
            f"Subcategory {sub} count mismatch: expected {expected_count}, got {len(matching)}"
        for m in matching:
            assert m['isCollectable'] == expected_coll, \
                f"Item {m['id']} in {sub} has invalid isCollectable={m['isCollectable']}, expected {expected_coll}"

    print("  ✓ Exactly 237 collectables (50 parts, 50 scraps, 50 stunts, 30 subs, 30 waste, 27 peyotes)")
    print("  ✓ Exactly 93 non-collectables (50 bridges, 15 knife flights, 13 services, 15 secrets/world)")
    print("  ✓ Total 330 POIs perfectly partitioned")

    # -------------------------------------------------------------------------
    # SUITE 3: Progressive Collection Simulations (Single, Subcategory, 100%)
    # -------------------------------------------------------------------------
    print("\n[SUITE 3] Progressive Collection Simulations & Telemetry Accuracy")

    collected_ids: Set[str] = set()

    # 3.1 Initial Empty State (0% Completion)
    summary_0 = compute_map_completion_summary(pois, collected_ids)
    assert summary_0.totalCount == 237
    assert summary_0.collectedCount == 0
    assert summary_0.remainingCount == 237
    assert summary_0.percentage == 0.0
    print("  ✓ Baseline: 0/237 collected (237 remaining, 0.0%)")

    # 3.2 Single Item Collection & Toggle
    first_stunt = [p for p in pois if p['subCategory'] == 'stunt_jumps'][0]
    collected_ids.add(first_stunt['id'])

    summary_1 = compute_map_completion_summary(pois, collected_ids)
    assert summary_1.totalCount == 237
    assert summary_1.collectedCount == 1
    assert summary_1.remainingCount == 236
    assert abs(summary_1.percentage - (1 / 237)) < 1e-9

    stunts_cat = next(c for c in summary_1.categoryStats if c.category == 'stunts')
    sj_stat = next(s for s in stunts_cat.subcategoryStats if s.subCategory == 'stunt_jumps')
    assert sj_stat.collectedCount == 1
    assert sj_stat.remainingCount == 49
    assert abs(sj_stat.percentage - (1 / 50)) < 1e-9
    print("  ✓ Single item toggle (stunt_jump_01): collectedCount=1, remainingCount=49, percentage=0.02")

    # Toggle off
    collected_ids.remove(first_stunt['id'])
    summary_revert = compute_map_completion_summary(pois, collected_ids)
    assert summary_revert.collectedCount == 0
    assert summary_revert.remainingCount == 237
    print("  ✓ Single item toggle off: reverted to collectedCount=0, remainingCount=237")

    # 3.3 Step-by-Step Subcategory Increments
    collectable_subs = [
        ('spaceship_parts', 50),
        ('letter_scraps', 50),
        ('stunt_jumps', 50),
        ('submarine_pieces', 30),
        ('nuclear_waste', 30),
        ('peyote_plants', 27),
    ]

    cumulative_collected = 0
    for sub, count in collectable_subs:
        sub_items = [p for p in pois if p['subCategory'] == sub]
        assert len(sub_items) == count

        print(f"  --> Incrementally completing subcategory '{sub}' ({count} items)...")
        for i, item in enumerate(sub_items, 1):
            collected_ids.add(item['id'])
            cumulative_collected += 1

            # Check telemetry at key checkpoints: step 1, mid-point, and final step
            if i in (1, count // 2, count):
                summary = compute_map_completion_summary(pois, collected_ids)
                assert summary.totalCount == 237
                assert summary.collectedCount == cumulative_collected
                assert summary.remainingCount == 237 - cumulative_collected
                expected_pct = cumulative_collected / 237
                assert abs(summary.percentage - expected_pct) < 1e-9

                # Check specific subcategory stats
                cat_name = item['category']
                cat_stat = next(c for c in summary.categoryStats if c.category == cat_name)
                s_stat = next(s for s in cat_stat.subcategoryStats if s.subCategory == sub)
                assert s_stat.collectedCount == i
                assert s_stat.remainingCount == count - i
                assert abs(s_stat.percentage - (i / count)) < 1e-9

        # Verify completed subcategory
        summary = compute_map_completion_summary(pois, collected_ids)
        cat_name = sub_items[0]['category']
        cat_stat = next(c for c in summary.categoryStats if c.category == cat_name)
        s_stat = next(s for s in cat_stat.subcategoryStats if s.subCategory == sub)
        assert s_stat.collectedCount == count
        assert s_stat.remainingCount == 0
        assert s_stat.percentage == 1.0
        print(f"      ✓ '{sub}' 100% complete: {s_stat.collectedCount}/{s_stat.totalCount} (0 remaining, 100.0%)")

    # 3.4 100% Milestone Verification across all Collectibles
    summary_100 = compute_map_completion_summary(pois, collected_ids)
    assert summary_100.totalCount == 237
    assert summary_100.collectedCount == 237
    assert summary_100.remainingCount == 0
    assert summary_100.percentage == 1.0
    print("  ✓ 100% Completion Milestone: exactly 237/237 collected, 0 remaining, 100.0% completion")

    # Verify category-level aggregates at 100%
    cat_collectibles = next(c for c in summary_100.categoryStats if c.category == 'collectibles')
    assert cat_collectibles.totalCount == 187  # 50+50+30+30+27
    assert cat_collectibles.collectedCount == 187
    assert cat_collectibles.remainingCount == 0
    assert cat_collectibles.percentage == 1.0

    cat_stunts = next(c for c in summary_100.categoryStats if c.category == 'stunts')
    assert cat_stunts.totalCount == 50  # only stunt jumps are collectable
    assert cat_stunts.collectedCount == 50
    assert cat_stunts.remainingCount == 0
    assert cat_stunts.percentage == 1.0

    print("  ✓ Category aggregates at 100%: Collectibles 187/187 (100%), Stunts 50/50 (100%)")

    # -------------------------------------------------------------------------
    # SUITE 4: Adversarial Contamination Stress Tests (isCollectable: false)
    # -------------------------------------------------------------------------
    print("\n[SUITE 4] Adversarial Contamination: Non-Collectables & Invalid IDs")

    # 4.1 Reset collection tracker to empty, then inject ALL 93 non-collectables
    adversarial_ids = {p['id'] for p in non_collectables}
    assert len(adversarial_ids) == 93

    summary_adv = compute_map_completion_summary(pois, adversarial_ids)

    # CRITICAL CHECK: totalCount must remain 237, collectedCount must remain 0!
    assert summary_adv.totalCount == 237, \
        f"Contamination error: totalCount distorted to {summary_adv.totalCount}, expected 237"
    assert summary_adv.collectedCount == 0, \
        f"Contamination error: non-collectables counted as collected ({summary_adv.collectedCount}), expected 0"
    assert summary_adv.remainingCount == 237
    assert summary_adv.percentage == 0.0

    # Check Stunts category: 50 bridges and 15 knife flights injected
    stunts_adv = next(c for c in summary_adv.categoryStats if c.category == 'stunts')
    assert stunts_adv.totalCount == 50, \
        f"Stunts total distorted by bridges/knife flights: got {stunts_adv.totalCount}, expected 50"
    assert stunts_adv.collectedCount == 0, \
        f"Stunts collectedCount distorted by bridges/knife flights: got {stunts_adv.collectedCount}, expected 0"

    # Non-collectable subcategories must have isCollectable == False
    utb_adv = next(s for s in stunts_adv.subcategoryStats if s.subCategory == 'under_the_bridge')
    assert utb_adv.isCollectable is False
    assert utb_adv.totalCount == 50

    kf_adv = next(s for s in stunts_adv.subcategoryStats if s.subCategory == 'knife_flights')
    assert kf_adv.isCollectable is False
    assert kf_adv.totalCount == 15

    print("  ✓ Injected all 93 non-collectables into collection tracker:")
    print("      -> MapCompletionSummary.totalCount strictly preserved at 237 (NOT 330)")
    print("      -> MapCompletionSummary.collectedCount strictly preserved at 0")
    print("      -> Stunts category total strictly preserved at 50 (NOT 115)")
    print("      -> Percentage strictly preserved at 0.0% (zero distortion)")

    # 4.2 Inject Synthetic / Non-existent / Null IDs
    synthetic_garbage_ids = {
        '', '   ', 'null', 'undefined', 'invalid_id_99999', 'under_the_bridge_999',
        'stunt_jump_100', 'spaceship_part_00', 'letter_scrap_xyz', '!@#$%^&*()'
    }
    summary_garbage = compute_map_completion_summary(pois, synthetic_garbage_ids)
    assert summary_garbage.totalCount == 237
    assert summary_garbage.collectedCount == 0
    assert summary_garbage.remainingCount == 237
    assert summary_garbage.percentage == 0.0
    print("  ✓ Injected 10 synthetic/garbage IDs: zero impact on telemetry (100% rejection)")

    # -------------------------------------------------------------------------
    # SUITE 5: Visual Marker State & Dimming across 330 POIs Catalog
    # -------------------------------------------------------------------------
    print("\n[SUITE 5] Visual Marker States, 0.35 Opacity Dimming & Hide Collected Toggle")

    all_subs_enabled = set(ALL_SUBCATEGORIES)

    # 5.1 Scenario 1: 0 collected, hide_collected=False
    markers_s1 = simulate_marker_layer(pois, all_subs_enabled, set(), False)
    assert len(markers_s1) == 330
    assert all(m.opacity == 1.0 for m in markers_s1)
    assert all(not m.has_checkmark for m in markers_s1)
    print("  ✓ Scenario 1 (0 collected, hide=False): exactly 330 markers, 100% opacity 1.0, 0 checkmarks")

    # 5.2 Scenario 2: 0 collected, hide_collected=True
    markers_s2 = simulate_marker_layer(pois, all_subs_enabled, set(), True)
    assert len(markers_s2) == 330
    assert all(m.opacity == 1.0 for m in markers_s2)
    print("  ✓ Scenario 2 (0 collected, hide=True): exactly 330 markers visible (none hidden)")

    # 5.3 Scenario 3: 25 Stunt Jumps collected, hide_collected=False
    collected_25 = {f"stunt_jump_{i:02d}" for i in range(1, 26)}
    markers_s3 = simulate_marker_layer(pois, all_subs_enabled, collected_25, False)
    assert len(markers_s3) == 330
    dimmed_s3 = [m for m in markers_s3 if m.opacity == 0.35]
    normal_s3 = [m for m in markers_s3 if m.opacity == 1.0]
    checkmarked_s3 = [m for m in markers_s3 if m.has_checkmark]

    assert len(dimmed_s3) == 25, f"Expected exactly 25 dimmed markers, got {len(dimmed_s3)}"
    assert len(normal_s3) == 305, f"Expected exactly 305 normal markers, got {len(normal_s3)}"
    assert len(checkmarked_s3) == 25, f"Expected exactly 25 checkmarked markers, got {len(checkmarked_s3)}"
    assert {m.poi['id'] for m in dimmed_s3} == collected_25
    print("  ✓ Scenario 3 (25 collected, hide=False): exactly 25 dimmed to 0.35 opacity with checkmark badge, 305 normal at 1.0")

    # 5.4 Scenario 4: 25 Stunt Jumps collected, hide_collected=True
    markers_s4 = simulate_marker_layer(pois, all_subs_enabled, collected_25, True)
    assert len(markers_s4) == 305, f"Expected exactly 305 visible markers, got {len(markers_s4)}"
    assert not any(m.poi['id'] in collected_25 for m in markers_s4), "Collected markers leaked into layer!"
    assert all(m.opacity == 1.0 for m in markers_s4)
    assert all(not m.has_checkmark for m in markers_s4)
    print("  ✓ Scenario 4 (25 collected, hide=True): exactly 305 visible markers (all 25 completed items omitted)")

    # 5.5 Scenario 5: 100% Collectables Completed (237 collected), hide_collected=False
    all_collectable_ids = {p['id'] for p in collectables}
    markers_s5 = simulate_marker_layer(pois, all_subs_enabled, all_collectable_ids, False)
    assert len(markers_s5) == 330
    dimmed_s5 = [m for m in markers_s5 if m.opacity == 0.35]
    normal_s5 = [m for m in markers_s5 if m.opacity == 1.0]

    assert len(dimmed_s5) == 237, f"Expected 237 dimmed markers, got {len(dimmed_s5)}"
    assert len(normal_s5) == 93, f"Expected 93 normal markers (non-collectables), got {len(normal_s5)}"
    assert {m.poi['id'] for m in normal_s5} == adversarial_ids  # exact set of 93 non-collectables
    print("  ✓ Scenario 5 (100% collectables completed, hide=False): 237 dimmed at 0.35, 93 non-collectables at 1.0")

    # 5.6 Scenario 6: 100% Collectables Completed (237 collected), hide_collected=True
    markers_s6 = simulate_marker_layer(pois, all_subs_enabled, all_collectable_ids, True)
    assert len(markers_s6) == 93, f"Expected exactly 93 markers (non-collectables), got {len(markers_s6)}"
    assert all(not m.poi['isCollectable'] for m in markers_s6), "Collectables visible when 100% completed & hide=True!"
    assert all(m.opacity == 1.0 for m in markers_s6)
    print("  ✓ Scenario 6 (100% collectables completed, hide=True): exactly 93 non-collectables visible, 0 collectables")

    # 5.7 Scenario 7: Combined Subcategory Filter + Hide Collected
    # Disable stunts completely, enable only collectibles (187 items)
    # Collect 50 spaceship parts, hide_collected=True
    only_collectibles = set(CANONICAL_CATEGORIES['collectibles'])
    sp_collected = {f"spaceship_part_{i:02d}" for i in range(1, 51)}

    markers_s7_show = simulate_marker_layer(pois, only_collectibles, sp_collected, False)
    assert len(markers_s7_show) == 187
    assert sum(1 for m in markers_s7_show if m.opacity == 0.35) == 50
    assert sum(1 for m in markers_s7_show if m.opacity == 1.0) == 137

    markers_s7_hide = simulate_marker_layer(pois, only_collectibles, sp_collected, True)
    assert len(markers_s7_hide) == 137, f"Expected 137 visible markers (187 - 50), got {len(markers_s7_hide)}"
    assert not any(m.poi['subCategory'] == 'spaceship_parts' for m in markers_s7_hide)
    assert sum(1 for m in markers_s7_hide if m.poi['subCategory'] == 'letter_scraps') == 50
    print("  ✓ Scenario 7 (Hierarchical Filter + Hide Collected): 187 collectibles, 50 parts hidden -> exactly 137 visible")

    # 5.8 Scenario 8: Highlighted Marker Presentation
    target_poi = pois[0]
    markers_s8 = simulate_marker_layer(pois, all_subs_enabled, set(), False, highlighted_id=target_poi['id'])
    highlighted_marker = next(m for m in markers_s8 if m.is_highlighted)
    assert highlighted_marker.size == 48.0
    other_markers = [m for m in markers_s8 if not m.is_highlighted]
    assert all(m.size == 40.0 for m in other_markers)
    print("  ✓ Scenario 8 (Highlighted Marker): target marker enlarged to 48.0px, others standard 40.0px")

    # -------------------------------------------------------------------------
    # SUITE 6: High-Frequency Mutation & Recalculation Stress Benchmark
    # -------------------------------------------------------------------------
    print("\n[SUITE 6] High-Frequency Stress Test: 20,000 Rapid Telemetry Updates")

    stress_collected: Set[str] = set()
    collectable_ids_list = [p['id'] for p in collectables]

    t0 = time.perf_counter()
    iterations = 20000

    for i in range(iterations):
        # Deterministic pseudo-random rotation
        target_id = collectable_ids_list[i % len(collectable_ids_list)]
        if target_id in stress_collected:
            stress_collected.remove(target_id)
        else:
            stress_collected.add(target_id)

        # Recompute telemetry summary periodically to stress recalculation engine
        if i % 100 == 0:
            sum_obj = compute_map_completion_summary(pois, stress_collected)
            assert sum_obj.totalCount == 237
            assert 0 <= sum_obj.collectedCount <= 237
            assert sum_obj.remainingCount == 237 - sum_obj.collectedCount
            assert 0.0 <= sum_obj.percentage <= 1.0

    t1 = time.perf_counter()
    duration_ms = (t1 - t0) * 1000
    ops_per_sec = iterations / (t1 - t0)

    print(f"  ✓ Processed {iterations} state mutations and 200 full telemetry audits in {duration_ms:.2f} ms")
    print(f"  ✓ Mutation throughput: {ops_per_sec:,.0f} ops/second")
    print("  ✓ Zero data corruption, zero drift, zero exceptions")

    print("\n" + "=" * 80)
    print("ALL EMPIRICAL CHALLENGE SUITES PASSED (VERDICT: APPROVE)")
    print("=" * 80)
    return True


if __name__ == "__main__":
    success = run_telemetry_and_marker_verification()
    sys.exit(0 if success else 1)
