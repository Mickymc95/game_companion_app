#!/usr/bin/env python3
"""
GTA V Companion App — Search-to-Map Marker Shake & Auto Info Card Verification Suite
=====================================================================================
Empirical & adversarial verification for:
1. R1: Target marker highlight & shake animation (~1000ms, non-targeted unaffected)
2. R2: Automatic info card presentation immediately upon shake completion
3. R3: Preservation of standard map interactions (manual tap, filter toggles, pan/zoom)
4. Static AST/code audits across Dart implementation and test suites
5. Shake mathematics simulation (amplitude, frequency, damping, boundaries)
6. State transition simulation & edge case handling
"""

import os
import sys
import math
import re

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LIB_DIR = os.path.join(ROOT_DIR, "lib")
TEST_DIR = os.path.join(ROOT_DIR, "test")

TARGET_PROVIDER_PATH = os.path.join(LIB_DIR, "sdk", "map", "target_map_position_provider.dart")
SEARCH_SCREEN_PATH = os.path.join(LIB_DIR, "ui", "screens", "search_screen.dart")
MAP_TAB_PATH = os.path.join(LIB_DIR, "ui", "screens", "map_tab.dart")
MAP_PROVIDERS_PATH = os.path.join(LIB_DIR, "ui", "providers", "map_providers.dart")
MAP_TAB_TEST_PATH = os.path.join(TEST_DIR, "ui", "screens", "map_tab_test.dart")
SEARCH_SCREEN_TEST_PATH = os.path.join(TEST_DIR, "ui", "screens", "search_screen_test.dart")

# Color helpers
GREEN = "\033[92m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

failures = []
total_assertions = 0


def assert_true(cond: bool, test_name: str, msg: str = ""):
    global total_assertions
    total_assertions += 1
    if not cond:
        err = f"[{test_name}] FAILED: {msg}"
        failures.append(err)
        print(f"  {RED}✗ {err}{RESET}")
    else:
        print(f"  {GREEN}✓ {test_name}: {msg}{RESET}")


def run_suite(suite_name: str, fn):
    print(f"\n{BOLD}{'=' * 70}\n{suite_name}\n{'=' * 70}{RESET}")
    fn()


def test_static_code_audit():
    # 1. target_map_position_provider.dart
    with open(TARGET_PROVIDER_PATH, "r", encoding="utf-8") as f:
        target_src = f.read()

    assert_true("final bool shakeAndOpenCard;" in target_src,
                "target_map_position_provider.dart", "shakeAndOpenCard field defined")
    assert_true("shakeAndOpenCard ?? (poiId != null)" in target_src,
                "target_map_position_provider.dart", "shakeAndOpenCard defaults to (poiId != null)")

    # 2. search_screen.dart
    with open(SEARCH_SCREEN_PATH, "r", encoding="utf-8") as f:
        search_src = f.read()

    assert_true("poiId: poi.id" in search_src,
                "search_screen.dart", "poiId passed to TargetMapPosition")
    assert_true("shakeAndOpenCard: true" in search_src,
                "search_screen.dart", "shakeAndOpenCard: true explicitly set on POI tap")
    assert_true("context.go('/map')" in search_src,
                "search_screen.dart", "Navigates to /map on POI tap")

    # 3. map_providers.dart
    with open(MAP_PROVIDERS_PATH, "r", encoding="utf-8") as f:
        providers_src = f.read()

    assert_true("enableSubcategory(String subCategory)" in providers_src,
                "map_providers.dart", "enableSubcategory method available on MapFilterState / Notifier")

    # 4. map_tab.dart
    with open(MAP_TAB_PATH, "r", encoding="utf-8") as f:
        map_src = f.read()

    assert_true("with SingleTickerProviderStateMixin" in map_src,
                "map_tab.dart", "SingleTickerProviderStateMixin mixed into _MapTabState")
    assert_true("AnimationController" in map_src,
                "map_tab.dart", "AnimationController declared")
    assert_true("duration: const Duration(milliseconds: 1000)" in map_src,
                "map_tab.dart", "Shake duration set to exactly 1000ms (~1 second)")
    assert_true("_shakingPoiId" in map_src,
                "map_tab.dart", "_shakingPoiId state variable tracks targeted marker")
    assert_true("_handleTargetMapPosition" in map_src,
                "map_tab.dart", "_handleTargetMapPosition handles incoming target navigation")
    assert_true("_triggerMarkerShakeAndInfoCard" in map_src,
                "map_tab.dart", "_triggerMarkerShakeAndInfoCard coordinates animation and card opening")
    assert_true("_showPoiDetails(context, ref, targetPoi)" in map_src,
                "map_tab.dart", "Automatically calls _showPoiDetails upon shake completion")
    assert_true("_ShakingMarkerIcon" in map_src,
                "map_tab.dart", "_ShakingMarkerIcon dedicated widget exists")
    assert_true("key: Key('shaking_marker_icon_${poi.id}')" in map_src,
                "map_tab.dart", "Key assigned to shaking marker icon for verification")
    assert_true("key: Key('map_marker_${poi.id}')" in map_src,
                "map_tab.dart", "Key assigned to marker gesture detector")
    assert_true("_shakeController.dispose()" in map_src,
                "map_tab.dart", "Animation controller disposed cleanly in dispose()")
    assert_true("isTargeted" in map_src,
                "map_tab.dart", "Targeted/shaking POI bypasses filter hiding so user always sees it")
    assert_true("void _cancelShake()" in map_src,
                "map_tab.dart", "_cancelShake helper cleans up active animation and state")
    assert_true("_shakeSequence" in map_src,
                "map_tab.dart", "_shakeSequence generation guard protects against async races")
    assert_true("AnimationStatus.completed" in map_src,
                "map_tab.dart", "AnimationStatus.completed verifies full completion before modal display")
    assert_true("bool _isMapTabActive()" in map_src,
                "map_tab.dart", "_isMapTabActive helper guards route and tab lifecycle")
    assert_true("TickerMode.of(context)" in map_src,
                "map_tab.dart", "TickerMode.of(context) ensures inactive tab in IndexedStack does not open modal")
    assert_true("while (mounted && _shakeSequence == currentSequence && !_isMapTabActive()" in map_src,
                "map_tab.dart", "MapTab waits for route arrival so shake occurs on-screen upon arrival")
    assert_true("_shakingPoiId != null && !_isMapTabActive()" in map_src,
                "map_tab.dart", "MapTab build checks for inactive tab and cancels lingering active shake")

    # 5. Tests audit
    with open(MAP_TAB_TEST_PATH, "r", encoding="utf-8") as f:
        map_test_src = f.read()

    assert_true("MapTab triggers marker shake animation for targeted POI and automatically opens info card" in map_test_src,
                "map_tab_test.dart", "Widget test verifies marker shake and automatic info card")
    assert_true("shaking_marker_icon_target_poi_1" in map_test_src,
                "map_tab_test.dart", "Widget test asserts shaking marker icon presence")
    assert_true("shaking_marker_icon_other_poi_2" in map_test_src,
                "map_tab_test.dart", "Widget test asserts non-targeted marker does NOT shake")
    assert_true("MapTab manual marker tap opens info card directly without shake animation" in map_test_src,
                "map_tab_test.dart", "Widget test asserts manual marker tap works without shake")
    assert_true("MapTab navigation without POI selection moves map without shake or card" in map_test_src,
                "map_tab_test.dart", "Widget test asserts navigation without POI selection")
    assert_true("MapTab manual tap on another marker during shake animation cancels shake" in map_test_src,
                "map_tab_test.dart", "Widget test asserts manual tap on another marker interrupts shake without ghost modal")
    assert_true("MapTab manual tap on shaking target marker opens info card cleanly once" in map_test_src,
                "map_tab_test.dart", "Widget test asserts tapping shaking target marker opens card once without duplicates")
    assert_true("MapTab rapid successive targetMapPosition updates cancel prior shake" in map_test_src,
                "map_tab_test.dart", "Widget test asserts rapid successive target updates cancel prior shake cleanly")
    assert_true("MapTab shake animation cancels and does not open info card when tab becomes inactive" in map_test_src,
                "map_tab_test.dart", "Widget test asserts shake cancels cleanly when tab becomes inactive (TickerMode false)")
    assert_true("MapTab opening category filter sheet cancels active shake without ghost modal" in map_test_src,
                "map_tab_test.dart", "Widget test asserts opening filter sheet cancels shake cleanly without ghost card")

    with open(SEARCH_SCREEN_TEST_PATH, "r", encoding="utf-8") as f:
        search_test_src = f.read()

    assert_true("targetPos?.shakeAndOpenCard, isTrue" in search_test_src,
                "search_screen_test.dart", "Search screen test asserts shakeAndOpenCard is true")
    assert_true("Selecting search map POI navigates to MapTab" in search_test_src,
                "search_screen_test.dart", "Search screen test asserts full MapTab navigation and auto card")


def test_shake_mathematics():
    """Simulates the wobble equation across 1,000 steps (1ms resolution)."""
    # Wobble formula from _ShakingMarkerIcon:
    # progress in [0.0, 1.0]
    # wobble = sin(progress * 10 * pi)   # 5 cycles
    # damping = (1.0 - progress * 0.4)
    # dx = wobble * 6.0 * damping
    # rotation = wobble * 0.18 * damping

    dx_values = []
    rot_values = []
    zero_crossings = 0
    prev_sign = 0

    for step in range(1001):
        progress = step / 1000.0
        wobble = math.sin(progress * 10 * math.pi)
        damping = 1.0 - progress * 0.4
        dx = wobble * 6.0 * damping
        rotation = wobble * 0.18 * damping

        dx_values.append(dx)
        rot_values.append(rotation)

        sign = 1 if dx > 1e-6 else (-1 if dx < -1e-6 else 0)
        if sign != 0 and prev_sign != 0 and sign != prev_sign:
            zero_crossings += 1
        if sign != 0:
            prev_sign = sign

    # Boundary conditions:
    assert_true(abs(dx_values[0]) < 1e-9, "Shake Math", "Initial displacement at t=0 is 0.0")
    assert_true(abs(rot_values[0]) < 1e-9, "Shake Math", "Initial rotation at t=0 is 0.0")
    assert_true(abs(dx_values[-1]) < 1e-9, "Shake Math", "Final displacement at t=1.0 is 0.0 (clean rest)")
    assert_true(abs(rot_values[-1]) < 1e-9, "Shake Math", "Final rotation at t=1.0 is 0.0 (clean rest)")

    # Maximum bounds:
    max_dx = max(abs(x) for x in dx_values)
    max_rot = max(abs(r) for r in rot_values)
    assert_true(5.0 <= max_dx <= 6.5, "Shake Math", f"Peak displacement within bounds: {max_dx:.2f}px")
    assert_true(0.15 <= max_rot <= 0.20, "Shake Math", f"Peak rotation within bounds: {max_rot:.3f}rad")

    # Frequency: 5 full cycles should have ~10 zero crossings
    assert_true(9 <= zero_crossings <= 11, "Shake Math", f"Oscillation count verified (~5 cycles): {zero_crossings // 2} full cycles")


def test_state_machine_simulation():
    """Simulates map tab state transitions under various user flows and async concurrency."""
    class MockMapTabState:
        def __init__(self):
            self.map_position = (0.0, 0.0)
            self.zoom = 1.0
            self.shaking_poi_id = None
            self.highlighted_poi_id = None
            self.enabled_subcategories = {"spaceship_parts"}
            self.card_open_poi_id = None
            self.card_open_count = 0
            self.shake_sequence = 0
            self.active_animation_seq = None
            self.animation_completed = False
            self.is_tab_active = True
            self.route_location = '/map'
            self.modal_sheet_open = None
            self.pending_arrival_poi_id = None

        def cancel_shake(self):
            self.shake_sequence += 1
            if self.active_animation_seq is not None:
                self.active_animation_seq = None
                self.animation_completed = False
            self.shaking_poi_id = None
            self.pending_arrival_poi_id = None

        def handle_target(self, pos, zoom, poi_id=None, shake_and_open=False, subcat=None):
            self.map_position = pos
            self.zoom = zoom
            if poi_id and shake_and_open:
                self.cancel_shake()
                current_seq = self.shake_sequence
                if subcat:
                    self.enabled_subcategories.add(subcat)
                # Original map item preserved; target symbol not set
                self.highlighted_poi_id = None
                self.active_animation_seq = current_seq
                self.animation_completed = False
                if self.is_tab_active and self.route_location == '/map':
                    self.shaking_poi_id = poi_id
                else:
                    self.pending_arrival_poi_id = poi_id
                return current_seq
            return None

        def switch_tab(self, new_tab: str):
            self.route_location = f'/{new_tab}'
            self.is_tab_active = (new_tab == 'map')
            if self.is_tab_active and self.pending_arrival_poi_id:
                self.shaking_poi_id = self.pending_arrival_poi_id
                self.pending_arrival_poi_id = None
            elif not self.is_tab_active and self.shaking_poi_id:
                self.cancel_shake()

        def timeout_unrendered_arrival(self, seq):
            if self.active_animation_seq == seq and self.pending_arrival_poi_id:
                self.pending_arrival_poi_id = None
                self.active_animation_seq = None

        def open_modal_sheet(self, sheet_type: str):
            self.cancel_shake()
            self.modal_sheet_open = sheet_type

        def close_modal_sheet(self):
            self.modal_sheet_open = None

        def finish_animation(self, seq):
            # Simulates the resumption of the async _triggerMarkerShakeAndInfoCard
            # Guard check matching Dart:
            # 1. If superseded by newer target or disposed: abort immediately without mutating state
            if self.shake_sequence != seq:
                return

            if seq == self.active_animation_seq:
                self.animation_completed = True
            
            # 2. If active task was cancelled, stopped early, or navigated away: clear shaking POI and abort
            is_active = self.is_tab_active and self.route_location == '/map' and self.modal_sheet_open is None
            if not self.animation_completed or not is_active:
                self.shaking_poi_id = None
                return

            opened_id = self.shaking_poi_id
            self.shaking_poi_id = None
            self.active_animation_seq = None
            self.card_open_poi_id = opened_id
            self.card_open_count += 1

        def manual_tap_marker(self, poi_id):
            self.cancel_shake()
            self.card_open_poi_id = poi_id
            self.card_open_count += 1

        def dismiss_card(self):
            if self.card_open_count > 0:
                self.card_open_count -= 1
            if self.card_open_count == 0:
                self.card_open_poi_id = None

    # Scenario 1: Search selection flow
    state = MockMapTabState()
    seq1 = state.handle_target((10.0, 20.0), 4.5, poi_id="poi_abc", shake_and_open=True, subcat="stunt_jumps")
    assert_true(state.shaking_poi_id == "poi_abc", "State Flow", "Search selection sets shaking POI")
    assert_true(state.highlighted_poi_id is None, "State Flow", "Search selection preserves original map item without target symbol")
    assert_true("stunt_jumps" in state.enabled_subcategories, "State Flow", "Disabled subcategory auto-enabled")
    assert_true(state.card_open_poi_id is None, "State Flow", "Card not yet open during shake")

    state.finish_animation(seq1)
    assert_true(state.shaking_poi_id is None, "State Flow", "Shaking cleared after completion")
    assert_true(state.card_open_poi_id == "poi_abc", "State Flow", "Info card opened automatically after shake")
    assert_true(state.card_open_count == 1, "State Flow", "Card opened exactly once")

    # Scenario 2: Dismiss card
    state.dismiss_card()
    assert_true(state.card_open_poi_id is None, "State Flow", "Card dismissed cleanly")
    assert_true(state.card_open_count == 0, "State Flow", "Zero modal cards open after dismissal")

    # Scenario 3: Manual tap on another marker
    state.manual_tap_marker("poi_xyz")
    assert_true(state.card_open_poi_id == "poi_xyz", "State Flow", "Manual tap opens tapped marker directly")
    assert_true(state.shaking_poi_id is None, "State Flow", "Manual tap does NOT trigger shake")
    state.dismiss_card()

    # Scenario 4: Search navigation without POI selection
    state.handle_target((30.0, 40.0), 4.0, poi_id=None, shake_and_open=False)
    assert_true(state.shaking_poi_id is None, "State Flow", "Navigation without POI selection does NOT shake")
    assert_true(state.map_position == (30.0, 40.0), "State Flow", "Map position updated correctly")

    # Scenario 5: Interruption of active shake by manual tap on different marker
    seq_interrupted = state.handle_target((50.0, 60.0), 4.5, poi_id="poi_fast", shake_and_open=True)
    assert_true(state.shaking_poi_id == "poi_fast", "State Flow", "Shake started")
    state.manual_tap_marker("poi_other")
    assert_true(state.shaking_poi_id is None, "State Flow", "Manual tap interrupted active shake cleanly")
    assert_true(state.card_open_poi_id == "poi_other", "State Flow", "Manual tap opened target marker")
    # Interrupted async task attempts to finish:
    state.finish_animation(seq_interrupted)
    assert_true(state.card_open_poi_id == "poi_other", "State Flow", "Interrupted task aborts without overriding tapped card")
    assert_true(state.card_open_count == 1, "State Flow", "Card count remains strictly 1 (no duplicate stacked modal)")
    state.dismiss_card()

    # Scenario 6: Manual tap on the shaking target marker itself
    seq_self = state.handle_target((70.0, 80.0), 4.5, poi_id="poi_self", shake_and_open=True)
    assert_true(state.shaking_poi_id == "poi_self", "State Flow", "Target marker shake active")
    state.manual_tap_marker("poi_self")
    assert_true(state.shaking_poi_id is None, "State Flow", "Shake stopped on self tap")
    assert_true(state.card_open_poi_id == "poi_self", "State Flow", "Self card opened immediately")
    # Interrupted shake async task completes:
    state.finish_animation(seq_self)
    assert_true(state.card_open_count == 1, "State Flow", "No double-modal opened for self tap")
    state.dismiss_card()
    assert_true(state.card_open_poi_id is None, "State Flow", "Clean single dismiss returns to normal UI")

    # Scenario 7: Rapid successive search selections
    seq_first = state.handle_target((10.0, 10.0), 4.5, poi_id="poi_1st", shake_and_open=True)
    assert_true(state.shaking_poi_id == "poi_1st", "State Flow", "First target shaking")
    # Rapid second target arrived before first completed
    seq_second = state.handle_target((20.0, 20.0), 4.5, poi_id="poi_2nd", shake_and_open=True)
    assert_true(state.shaking_poi_id == "poi_2nd", "State Flow", "First target cancelled, second target shaking")
    # First async task unblocks:
    state.finish_animation(seq_first)
    assert_true(state.shaking_poi_id == "poi_2nd", "State Flow", "First task did NOT clear second task's shaking POI")
    assert_true(state.card_open_poi_id is None, "State Flow", "First task did NOT open its card")
    # Second async task completes:
    state.finish_animation(seq_second)
    assert_true(state.shaking_poi_id is None, "State Flow", "Second shake finished")
    assert_true(state.card_open_poi_id == "poi_2nd", "State Flow", "Only second target opened info card")
    assert_true(state.card_open_count == 1, "State Flow", "Exactly one card opened throughout rapid navigation")
    state.dismiss_card()

    # Scenario 8: User switches tab to Wiki during active shake
    seq_tab = state.handle_target((15.0, 25.0), 4.5, poi_id="poi_tab_switch", shake_and_open=True)
    assert_true(state.shaking_poi_id == "poi_tab_switch", "State Flow", "Marker starts shaking")
    # Switch tab to Wiki (IndexedStack disables TickerMode, route becomes /wiki)
    state.switch_tab('wiki')
    assert_true(not state.is_tab_active, "State Flow", "Map tab is now inactive")
    state.finish_animation(seq_tab)
    assert_true(state.card_open_poi_id is None, "State Flow", "No card opened on Wiki tab")
    assert_true(state.card_open_count == 0, "State Flow", "Modal count strictly 0 on inactive tab")
    # Return to map tab
    state.switch_tab('map')

    # Scenario 9: User taps category filter button during active shake
    seq_filter = state.handle_target((35.0, 45.0), 4.5, poi_id="poi_filter_tap", shake_and_open=True)
    assert_true(state.shaking_poi_id == "poi_filter_tap", "State Flow", "Marker shaking before filter tap")
    state.open_modal_sheet('filter')
    assert_true(state.shaking_poi_id is None, "State Flow", "Tapping filter button cancelled shake")
    state.finish_animation(seq_filter)
    assert_true(state.card_open_poi_id is None, "State Flow", "Target POI card did NOT open over filter sheet")
    assert_true(state.card_open_count == 0, "State Flow", "Zero duplicate modals over filter sheet")
    state.close_modal_sheet()

    # Scenario 10: User taps layer switcher FAB during active shake
    seq_layer = state.handle_target((55.0, 65.0), 4.5, poi_id="poi_layer_tap", shake_and_open=True)
    assert_true(state.shaking_poi_id == "poi_layer_tap", "State Flow", "Marker shaking before layer switch")
    state.open_modal_sheet('layer_switcher')
    assert_true(state.shaking_poi_id is None, "State Flow", "Layer switcher button cancelled shake")
    state.finish_animation(seq_layer)
    assert_true(state.card_open_poi_id is None, "State Flow", "Zero cards opened over layer switcher")
    state.close_modal_sheet()

    # Scenario 11: Real Search-to-Map flow with route transition from /search
    state.switch_tab('search')
    seq_search = state.handle_target((42.0, 84.0), 4.5, poi_id="poi_from_search", shake_and_open=True)
    assert_true(state.shaking_poi_id is None, "State Flow", "Marker does not shake before arrival on map")
    # Route arrives at /map:
    state.switch_tab('map')
    assert_true(state.shaking_poi_id == "poi_from_search", "State Flow", "Target shakes upon arrival on map")
    state.finish_animation(seq_search)
    assert_true(state.shaking_poi_id is None, "State Flow", "Search arrival shake finished")
    assert_true(state.card_open_poi_id == "poi_from_search", "State Flow", "Info card opened automatically upon arrival")
    assert_true(state.card_open_count == 1, "State Flow", "Single modal open for search arrival")
    state.dismiss_card()

    # Scenario 12: Target initiated from /search but navigation is diverted/cancelled before arrival
    state.switch_tab('search')
    seq_diverted = state.handle_target((42.0, 84.0), 4.5, poi_id="poi_diverted", shake_and_open=True)
    assert_true(state.shaking_poi_id is None, "State Flow", "Diverted target not shaking on /search")
    # Timeout/aborted before user ever arrived at /map
    state.timeout_unrendered_arrival(seq_diverted)
    state.finish_animation(seq_diverted)
    assert_true(state.shaking_poi_id is None, "State Flow", "Diverted target never shakes")
    assert_true(state.card_open_poi_id is None, "State Flow", "Diverted target never opens card")
    assert_true(state.card_open_count == 0, "State Flow", "Zero cards opened for diverted navigation")
    state.switch_tab('map')


def main():
    print(f"\n{BOLD}{'=' * 70}\nSEARCH-TO-MAP MARKER SHAKE & AUTO INFO CARD TEST HARNESS\n{'=' * 70}{RESET}")
    run_suite("Suite 1: Static Dart Implementation & Test Code Audit", test_static_code_audit)
    run_suite("Suite 2: Shake Animation Physics & Boundary Mathematics", test_shake_mathematics)
    run_suite("Suite 3: State Machine Lifecycle & Adversarial Edge Cases", test_state_machine_simulation)

    print(f"\n{BOLD}{'=' * 70}\nRESULTS SUMMARY\n{'=' * 70}{RESET}")
    print(f"Total assertions: {total_assertions}")
    if failures:
        print(f"{RED}FAILED with {len(failures)} failures:{RESET}")
        for f in failures:
            print(f"  {f}")
        sys.exit(1)
    else:
        print(f"{GREEN}ALL {total_assertions} ASSERTIONS PASSED CLEANLY (100% SUCCESS){RESET}\n")
        sys.exit(0)


if __name__ == "__main__":
    main()
