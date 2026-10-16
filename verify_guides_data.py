#!/usr/bin/env python3
"""
GTA 5 Companion App — End-to-End Guides Data & Integration Verification Harness
==============================================================================

Automated verification harness implementing the systematic 4-tier methodology:
  - Tier 1: Dataset Volume & Topic Coverage (12-15 guides, 5 required gameplay topics)
  - Tier 2: Schema & Boundary Integrity (IDs, markdown >= 400 chars, valid YouTube URLs, no rickroll)
  - Tier 3: Dart Source Static Integration Audit (search provider, screen slivers, thumbnail cards)
  - Tier 4: Built-in Self-Tests & Mutation Harness (--self-test synthetic defect injection)

Usages:
  python3 verify_guides_data.py
  python3 verify_guides_data.py --file path/to/gtav_guides.json
  python3 verify_guides_data.py --tier 1
  python3 verify_guides_data.py --self-test
  python3 verify_guides_data.py --verbose
"""

import sys
import os
import json
import re
import copy
import argparse
from typing import List, Dict, Any, Tuple, Optional, Set

# --- Canonical Constants & Thresholds ---
MIN_GUIDES_COUNT = 12
MAX_GUIDES_COUNT = 15
MIN_MARKDOWN_LENGTH = 400

REQUIRED_TOPIC_CATEGORIES = [
    "Money & Stock Market",
    "100% Completion",
    "Stunt Jumps",
    "Aerial & Flight Challenges",
    "Secrets, Weapons & Rare Vehicles",
]

ALLOWED_DIFFICULTIES = {
    "Beginner",
    "Intermediate",
    "Advanced",
}

PROHIBITED_YOUTUBE_IDS = {
    "dQw4w9WgXcQ",  # Prohibited Rickroll URL
}

GENERIC_PLACEHOLDERS = {
    "xxxxxxxxxxx",
    "12345678901",
    "placeholder",
    "00000000000",
}

YOUTUBE_URL_REGEX = re.compile(
    r"^https://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([A-Za-z0-9_-]{11})(?:[&?].*)?$"
)
MARKDOWN_HEADING_REGEX = re.compile(r"(?:^|\n)#{1,6}\s+\S+")
MARKDOWN_LIST_REGEX = re.compile(r"(?:^|\n)\s*(?:[-*+]|\d+\.)\s+\S+")


def resolve_guides_file_path(custom_path: Optional[str] = None) -> str:
    """Locates the gtav_guides.json file across multiple standard directory layouts."""
    if custom_path:
        if os.path.exists(custom_path):
            return os.path.abspath(custom_path)
        raise FileNotFoundError(f"Specified guides dataset file not found: {custom_path}")

    cwd = os.getcwd()
    script_dir = os.path.dirname(os.path.abspath(__file__))

    search_candidates = [
        os.path.join(cwd, "game_companion_sdk", "assets", "data", "gtav_guides.json"),
        os.path.join(cwd, "assets", "data", "gtav_guides.json"),
        os.path.join(script_dir, "assets", "data", "gtav_guides.json"),
        os.path.join(script_dir, "game_companion_sdk", "assets", "data", "gtav_guides.json"),
        os.path.join(script_dir, "..", "game_companion_sdk", "assets", "data", "gtav_guides.json"),
        "/home/deck/game_companion_app/game_companion_sdk/assets/data/gtav_guides.json",
    ]

    for candidate in search_candidates:
        norm = os.path.normpath(candidate)
        if os.path.exists(norm) and os.path.isfile(norm):
            return norm

    raise FileNotFoundError(
        "Could not automatically locate 'gtav_guides.json'. "
        f"Searched paths:\n  " + "\n  ".join(search_candidates)
    )


def resolve_sdk_lib_dir() -> Optional[str]:
    """Locates the lib/ directory of game_companion_sdk for static source auditing."""
    cwd = os.getcwd()
    script_dir = os.path.dirname(os.path.abspath(__file__))

    search_candidates = [
        os.path.join(cwd, "game_companion_sdk", "lib"),
        os.path.join(cwd, "lib"),
        os.path.join(script_dir, "game_companion_sdk", "lib"),
        os.path.join(script_dir, "lib"),
        os.path.join(script_dir, "..", "game_companion_sdk", "lib"),
        "/home/deck/game_companion_app/game_companion_sdk/lib",
    ]

    for candidate in search_candidates:
        norm = os.path.normpath(candidate)
        if os.path.exists(norm) and os.path.isdir(norm):
            return norm
    return None


class GuidesValidator:
    """Systematic 4-tier verification validator for GTA V Single-Player Guides."""

    def __init__(
        self,
        data: List[Dict[str, Any]],
        sdk_lib_dir: Optional[str] = None,
        verbose: bool = False,
    ):
        self.data = data
        self.sdk_lib_dir = sdk_lib_dir
        self.verbose = verbose
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.tier_results: Dict[str, Optional[bool]] = {
            "tier1": None,
            "tier2": None,
            "tier3": None,
            "tier4": None,
        }

    # =========================================================================
    # Tier 1: Dataset Volume & Topic Coverage
    # =========================================================================
    def validate_tier1_dataset_volume_and_coverage(self) -> bool:
        """Verifies dataset volume bounds (12-15) and full coverage of all 5 topics."""
        tier_passed = True

        if not isinstance(self.data, list):
            self.errors.append("Dataset root must be a JSON array of guide objects.")
            self.tier_results["tier1"] = False
            return False

        count = len(self.data)
        if count < MIN_GUIDES_COUNT or count > MAX_GUIDES_COUNT:
            self.errors.append(
                f"Dataset count mismatch: expected between {MIN_GUIDES_COUNT} and "
                f"{MAX_GUIDES_COUNT} guides, but found {count}."
            )
            tier_passed = False

        categories_found: Set[str] = set()
        for idx, item in enumerate(self.data):
            if isinstance(item, dict) and "category" in item:
                cat = item["category"]
                if isinstance(cat, str) and cat.strip():
                    categories_found.add(cat.strip())

        missing_categories = [
            req for req in REQUIRED_TOPIC_CATEGORIES if req not in categories_found
        ]
        if missing_categories:
            self.errors.append(
                f"Missing required category topic coverage: {missing_categories}. "
                f"Present categories: {sorted(list(categories_found))}."
            )
            tier_passed = False

        if self.verbose:
            print(f"[Tier 1] Total guides loaded: {count}")
            print(f"[Tier 1] Categories present ({len(categories_found)}): {sorted(list(categories_found))}")

        self.tier_results["tier1"] = tier_passed
        return tier_passed

    # =========================================================================
    # Tier 2: Schema & Boundary Integrity
    # =========================================================================
    def validate_tier2_schema_and_boundary_integrity(self) -> bool:
        """Verifies strict field schemas, uniqueness, markdown length/syntax, and YouTube IDs."""
        tier_passed = True
        seen_ids: Set[str] = set()

        if not isinstance(self.data, list):
            self.tier_results["tier2"] = False
            return False

        for idx, item in enumerate(self.data):
            guide_ref = f"Guide[{idx}]"
            if not isinstance(item, dict):
                self.errors.append(f"{guide_ref}: Entry is not a valid JSON dictionary.")
                tier_passed = False
                continue

            # 1. Unique string id
            guide_id = item.get("id")
            if not isinstance(guide_id, str) or not guide_id.strip():
                self.errors.append(f"{guide_ref}: Missing or empty string 'id'.")
                tier_passed = False
            else:
                guide_id = guide_id.strip()
                guide_ref = f"Guide '{guide_id}'"
                if guide_id in seen_ids:
                    self.errors.append(f"{guide_ref}: Duplicate ID detected.")
                    tier_passed = False
                else:
                    seen_ids.add(guide_id)

            # 2. Non-empty title
            title = item.get("title")
            if not isinstance(title, str) or not title.strip():
                self.errors.append(f"{guide_ref}: Missing or empty string 'title'.")
                tier_passed = False

            # 3. Non-empty category
            category = item.get("category")
            if not isinstance(category, str) or not category.strip():
                self.errors.append(f"{guide_ref}: Missing or empty string 'category'.")
                tier_passed = False

            # 4. Tags: non-empty list of strings
            tags = item.get("tags")
            if not isinstance(tags, list) or len(tags) == 0:
                self.errors.append(f"{guide_ref}: 'tags' must be a non-empty list of strings.")
                tier_passed = False
            else:
                for t_idx, tag in enumerate(tags):
                    if not isinstance(tag, str) or not tag.strip():
                        self.errors.append(
                            f"{guide_ref}: Tag at index {t_idx} is not a valid non-empty string."
                        )
                        tier_passed = False

            # 5. Difficulty: one of Beginner, Intermediate, Advanced
            difficulty = item.get("difficulty")
            if difficulty not in ALLOWED_DIFFICULTIES:
                self.errors.append(
                    f"{guide_ref}: Invalid difficulty '{difficulty}'. "
                    f"Must be one of {sorted(list(ALLOWED_DIFFICULTIES))}."
                )
                tier_passed = False

            # 6. ReadTimeMinutes: positive integer > 0
            read_time = item.get("readTimeMinutes")
            if not isinstance(read_time, int) or isinstance(read_time, bool) or read_time <= 0:
                self.errors.append(
                    f"{guide_ref}: 'readTimeMinutes' must be a positive integer > 0 (got {read_time})."
                )
                tier_passed = False

            # 7. ContentMarkdown: length >= 400, contains # headings and lists
            content_md = item.get("contentMarkdown")
            if not isinstance(content_md, str):
                self.errors.append(f"{guide_ref}: 'contentMarkdown' must be a string.")
                tier_passed = False
            else:
                md_len = len(content_md)
                if md_len < MIN_MARKDOWN_LENGTH:
                    self.errors.append(
                        f"{guide_ref}: 'contentMarkdown' length ({md_len}) is below "
                        f"minimum {MIN_MARKDOWN_LENGTH} characters."
                    )
                    tier_passed = False

                if not MARKDOWN_HEADING_REGEX.search(content_md):
                    self.errors.append(
                        f"{guide_ref}: 'contentMarkdown' does not contain any '#' Markdown headings."
                    )
                    tier_passed = False

                if not MARKDOWN_LIST_REGEX.search(content_md):
                    self.errors.append(
                        f"{guide_ref}: 'contentMarkdown' does not contain any Markdown list items ('-' or '1.')."
                    )
                    tier_passed = False

            # 8. VideoUrl: valid YouTube URL, 11-char ID extraction, reject rickroll & placeholders
            video_url = item.get("videoUrl")
            if video_url is not None:
                if not isinstance(video_url, str) or not video_url.strip():
                    self.errors.append(f"{guide_ref}: 'videoUrl' if provided must be a non-empty string.")
                    tier_passed = False
                else:
                    v_url = video_url.strip()
                    match = YOUTUBE_URL_REGEX.match(v_url)
                    if not match:
                        self.errors.append(
                            f"{guide_ref}: 'videoUrl' '{v_url}' does not match canonical YouTube URL format."
                        )
                        tier_passed = False
                    else:
                        video_id = match.group(1)
                        if len(video_id) != 11:
                            self.errors.append(
                                f"{guide_ref}: YouTube video ID '{video_id}' length must be exactly 11 chars."
                            )
                            tier_passed = False

                        if video_id in PROHIBITED_YOUTUBE_IDS:
                            self.errors.append(
                                f"{guide_ref}: Prohibited Rickroll video ID '{video_id}' detected."
                            )
                            tier_passed = False

                        if video_id.lower() in GENERIC_PLACEHOLDERS or len(set(video_id)) <= 2:
                            self.errors.append(
                                f"{guide_ref}: Generic placeholder video ID '{video_id}' detected."
                            )
                            tier_passed = False

            if self.verbose:
                yt_info = item.get("videoUrl", "None")
                print(
                    f"[Tier 2] Verified {guide_ref} | Diff: {difficulty} | "
                    f"Read: {read_time}m | MD: {len(content_md) if isinstance(content_md, str) else 0} chars | YT: {yt_info}"
                )

        self.tier_results["tier2"] = tier_passed
        return tier_passed

    # =========================================================================
    # Tier 3: Dart Source Static Integration Audit
    # =========================================================================
    def validate_tier3_dart_static_integration_audit(self) -> bool:
        """Audits Dart source files in game_companion_sdk for contract compliance."""
        tier_passed = True
        lib_dir = self.sdk_lib_dir or resolve_sdk_lib_dir()

        if not lib_dir or not os.path.exists(lib_dir):
            self.errors.append(
                f"Could not locate SDK 'lib' directory for Tier 3 static audit (searched: {lib_dir})."
            )
            self.tier_results["tier3"] = False
            return False

        # File 1: lib/sdk/models/search_result_item.dart
        item_model_path = os.path.join(lib_dir, "sdk", "models", "search_result_item.dart")
        if not os.path.isfile(item_model_path):
            self.errors.append(f"Missing Dart source file: {item_model_path}")
            tier_passed = False
        else:
            with open(item_model_path, "r", encoding="utf-8") as f:
                content = f.read()
            if "guideArticle" not in content:
                self.errors.append(
                    "SearchResultType enum in 'search_result_item.dart' missing 'guideArticle' value."
                )
                tier_passed = False

        # File 2: lib/ui/providers/search_providers.dart
        search_prov_path = os.path.join(lib_dir, "ui", "providers", "search_providers.dart")
        if not os.path.isfile(search_prov_path):
            self.errors.append(f"Missing Dart source file: {search_prov_path}")
            tier_passed = False
        else:
            with open(search_prov_path, "r", encoding="utf-8") as f:
                content = f.read()
            required_snippets = [
                ("guidesProvider", "guidesProvider watch/fetch in unifiedSearchResultsProvider"),
                ("SearchResultType.guideArticle", "SearchResultType.guideArticle creation"),
                (".title.", "Title substring search match"),
                (".category.", "Category substring search match"),
                (".tags.", "Tags substring search match"),
                (".contentMarkdown.", "ContentMarkdown substring search match"),
            ]
            for snip, desc in required_snippets:
                if snip not in content:
                    self.errors.append(
                        f"'search_providers.dart' static audit failed: missing {desc} ('{snip}')."
                    )
                    tier_passed = False

        # File 3: lib/ui/screens/search_screen.dart
        search_screen_path = os.path.join(lib_dir, "ui", "screens", "search_screen.dart")
        if not os.path.isfile(search_screen_path):
            self.errors.append(f"Missing Dart source file: {search_screen_path}")
            tier_passed = False
        else:
            with open(search_screen_path, "r", encoding="utf-8") as f:
                content = f.read()
            if "Guides & Tutorials" not in content:
                self.errors.append(
                    "'search_screen.dart' static audit failed: missing 'Guides & Tutorials' section header."
                )
                tier_passed = False
            if "/guides" not in content:
                self.errors.append(
                    "'search_screen.dart' static audit failed: missing navigation to '/guides' route on tap."
                )
                tier_passed = False

        # File 4: lib/ui/screens/guides_tab.dart
        guides_tab_path = os.path.join(lib_dir, "ui", "screens", "guides_tab.dart")
        helper_path = os.path.join(lib_dir, "ui", "utils", "guide_style_helper.dart")
        if not os.path.isfile(guides_tab_path):
            self.errors.append(f"Missing Dart source file: {guides_tab_path}")
            tier_passed = False
        else:
            with open(guides_tab_path, "r", encoding="utf-8") as f:
                tab_content = f.read()
            helper_content = ""
            if os.path.isfile(helper_path):
                with open(helper_path, "r", encoding="utf-8") as f:
                    helper_content = f.read()
            combined_guides_code = tab_content + "\n" + helper_content

            if "guidesScrollControllerProvider" not in tab_content:
                self.errors.append(
                    "'guides_tab.dart' static audit failed: missing 'guidesScrollControllerProvider' wiring."
                )
                tier_passed = False
            if "FilterChip" not in tab_content:
                self.errors.append(
                    "'guides_tab.dart' static audit failed: missing 'FilterChip' category filter bar."
                )
                tier_passed = False
            if "buildGuideBadge" not in combined_guides_code:
                self.errors.append(
                    "'guides_tab.dart' static audit failed: missing 'buildGuideBadge' metadata badge generator."
                )
                tier_passed = False
            if "LaunchMode.externalApplication" not in combined_guides_code:
                self.errors.append(
                    "'guides_tab.dart' / helper static audit failed: missing 'LaunchMode.externalApplication'."
                )
                tier_passed = False
            if "showSnackBar" not in combined_guides_code and "SnackBar" not in combined_guides_code:
                self.errors.append(
                    "'guides_tab.dart' / helper static audit failed: missing SnackBar fallback feedback."
                )
                tier_passed = False

        # File 5: lib/ui/widgets/youtube_thumbnail_card.dart
        card_path = os.path.join(lib_dir, "ui", "widgets", "youtube_thumbnail_card.dart")
        if not os.path.isfile(card_path):
            self.errors.append(f"Missing Dart source file: {card_path}")
            tier_passed = False
        else:
            with open(card_path, "r", encoding="utf-8") as f:
                card_content = f.read()
            if "16 / 9" not in card_content and "16/9" not in card_content:
                self.errors.append(
                    "'youtube_thumbnail_card.dart' static audit failed: missing 16:9 AspectRatio."
                )
                tier_passed = False
            if "0xFF1E2026" not in card_content and "_buildOfflineFallback" not in card_content:
                self.errors.append(
                    "'youtube_thumbnail_card.dart' static audit failed: missing dark offline fallback styling."
                )
                tier_passed = False

        if self.verbose and tier_passed:
            print("[Tier 3] Dart source static integration audit passed across all 5 source targets.")

        self.tier_results["tier3"] = tier_passed
        return tier_passed

    # =========================================================================
    # Tier 4: Built-in Self-Tests & Mutation Testing
    # =========================================================================
    def validate_tier4_built_in_self_tests(self) -> bool:
        """Executes verification harness self-tests across synthetic valid & mutated fixtures."""
        self.tier_results["tier4"] = run_self_tests(sdk_lib_dir=self.sdk_lib_dir, verbose=self.verbose)
        if not self.tier_results["tier4"]:
            self.errors.append("Tier 4 self-test suite failed.")
            return False
        return True

    # =========================================================================
    # Runner
    # =========================================================================
    def run_all(self, target_tier: str = "all") -> Tuple[bool, List[str], List[str]]:
        """Runs the requested tiers and returns (success, errors, warnings)."""
        t = target_tier.lower().strip()

        if t in ("1", "all"):
            self.validate_tier1_dataset_volume_and_coverage()
        if t in ("2", "all"):
            self.validate_tier2_schema_and_boundary_integrity()
        if t in ("3", "all"):
            self.validate_tier3_dart_static_integration_audit()
        if t in ("4", "all"):
            self.validate_tier4_built_in_self_tests()

        is_success = len(self.errors) == 0
        return is_success, self.errors, self.warnings


# =============================================================================
# Synthetic Fixture & Self-Test Suite
# =============================================================================
def generate_synthetic_valid_dataset() -> List[Dict[str, Any]]:
    """Generates a clean, 100% compliant synthetic dataset of 13 guides covering all 5 topics."""
    categories = list(REQUIRED_TOPIC_CATEGORIES)
    difficulties = ["Beginner", "Intermediate", "Advanced"]
    dataset = []

    for i in range(1, 14):
        cat = categories[(i - 1) % len(categories)]
        diff = difficulties[(i - 1) % len(difficulties)]

        md = (
            f"# Synthetic Master Guide #{i:02d}: Full Guide to {cat}\n\n"
            f"This is an extensive single-player walkthrough for Grand Theft Auto V covering {cat}. "
            f"Players exploring Los Santos and Blaine County can follow these detailed guidelines "
            f"to optimize mission progression, maximize wealth acquisition, and unlock secrets.\n\n"
            f"## Core Objectives & Mechanics\n"
            f"Before starting this walkthrough, ensure you meet the following baseline requirements:\n"
            f"- Verify that all 3 playable characters (Michael, Franklin, Trevor) have sufficient health and body armor.\n"
            f"- Upgrade your selected vehicle's engine, brakes, and bulletproof tires at Los Santos Customs.\n"
            f"- Maintain a manual backup save at your safehouse bed before attempting complex milestones.\n\n"
            f"## Step-by-Step Walkthrough\n"
            f"1. Navigate to the marked coordinates indicated on your world map during daylight hours.\n"
            f"2. Engage Franklin's special driving ability or use aircraft rudder pedals for precise alignment.\n"
            f"3. Secure the objective, escape any lingering police heat, and collect your rewards.\n"
        )
        assert len(md) >= MIN_MARKDOWN_LENGTH

        yt_id = f"ValidVid{i:02d}X"
        dataset.append({
            "id": f"synth_guide_{i:02d}",
            "title": f"Synthetic Master Guide #{i:02d} - {cat}",
            "category": cat,
            "tags": [cat.split()[0], "Tutorial", f"Tag{i}"],
            "difficulty": diff,
            "readTimeMinutes": 5 + (i % 6),
            "contentMarkdown": md,
            "videoUrl": f"https://www.youtube.com/watch?v={yt_id}",
        })

    return dataset


def run_self_tests(sdk_lib_dir: Optional[str] = None, verbose: bool = False) -> bool:
    """Executes the verification harness self-tests across valid fixtures and 14 mutation scenarios."""
    print("================================================================================")
    print("RUNNING VERIFICATION HARNESS SELF-TESTS (Synthetic Fixture Suite)")
    print("================================================================================")

    # 1. Clean Synthetic Fixture Test
    clean_data = generate_synthetic_valid_dataset()
    validator = GuidesValidator(clean_data, sdk_lib_dir=sdk_lib_dir, verbose=verbose)
    v1_ok = validator.validate_tier1_dataset_volume_and_coverage()
    v2_ok = validator.validate_tier2_schema_and_boundary_integrity()

    if not (v1_ok and v2_ok and len(validator.errors) == 0):
        print("FAIL: Clean synthetic fixture failed baseline validation!", file=sys.stderr)
        for err in validator.errors:
            print(f"  [-] {err}", file=sys.stderr)
        return False

    print("✓ PASS: Synthetic valid dataset (13 guides) passed Tier 1 and Tier 2 cleanly.")

    # 2. Defect Injections - Validate Precise Interception
    defect_scenarios = [
        (
            "Duplicate ID Injection",
            lambda d: d[1].update({"id": d[0]["id"]}),
            "duplicate",
        ),
        (
            "Count Deficit (< 12 items)",
            lambda d: [d.pop(), d.pop()],
            "count mismatch",
        ),
        (
            "Count Surplus (> 15 items)",
            lambda d: d.extend([
                copy.deepcopy(d[0]),
                copy.deepcopy(d[1]),
                copy.deepcopy(d[2]),
            ]) or [
                d[-3].update({"id": "extra_1"}),
                d[-2].update({"id": "extra_2"}),
                d[-1].update({"id": "extra_3"}),
            ],
            "count mismatch",
        ),
        (
            "Missing Category Coverage",
            lambda d: [item.update({"category": "Stunt Jumps"}) for item in d if item["category"] == "Money & Stock Market"],
            "missing required category",
        ),
        (
            "Empty Title String",
            lambda d: d[0].update({"title": "   "}),
            "empty string 'title'",
        ),
        (
            "Missing / Empty Category",
            lambda d: d[0].update({"category": ""}),
            "empty string 'category'",
        ),
        (
            "Invalid Difficulty Level",
            lambda d: d[0].update({"difficulty": "Extreme"}),
            "invalid difficulty",
        ),
        (
            "Non-Positive Read Time (Zero)",
            lambda d: d[0].update({"readTimeMinutes": 0}),
            "positive integer",
        ),
        (
            "Non-Positive Read Time (Negative)",
            lambda d: d[0].update({"readTimeMinutes": -3}),
            "positive integer",
        ),
        (
            "Markdown Sub-400 Characters",
            lambda d: d[0].update({"contentMarkdown": "# Short Guide\n- Quick tip"}),
            "minimum 400 characters",
        ),
        (
            "Markdown Missing Headings",
            lambda d: d[0].update({
                "contentMarkdown": d[0]["contentMarkdown"].replace("#", " ")
            }),
            "markdown headings",
        ),
        (
            "Markdown Missing Lists",
            lambda d: d[0].update({
                "contentMarkdown": re.sub(r"(?:^|\n)\s*(?:[-*+]|\d+\.)\s+", "\nParagraph: ", d[0]["contentMarkdown"])
            }),
            "markdown list",
        ),
        (
            "Invalid YouTube URL Host / Format",
            lambda d: d[0].update({"videoUrl": "https://vimeo.com/123456789"}),
            "youtube url format",
        ),
        (
            "YouTube Video ID Length Not 11",
            lambda d: d[0].update({"videoUrl": "https://www.youtube.com/watch?v=short_id"}),
            "canonical youtube url format",
        ),
        (
            "Prohibited Rickroll Video ID Rejection",
            lambda d: d[0].update({"videoUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"}),
            "rickroll",
        ),
        (
            "Empty Tags List",
            lambda d: d[0].update({"tags": []}),
            "non-empty list of strings",
        ),
    ]

    for name, mutator, expected_err_sub in defect_scenarios:
        mutated_data = generate_synthetic_valid_dataset()
        mutator(mutated_data)
        mut_validator = GuidesValidator(mutated_data, sdk_lib_dir=sdk_lib_dir, verbose=verbose)
        mut_validator.validate_tier1_dataset_volume_and_coverage()
        mut_validator.validate_tier2_schema_and_boundary_integrity()

        if len(mut_validator.errors) == 0:
            print(f"FAIL: Defect scenario '{name}' unexpectedly PASSED verification!", file=sys.stderr)
            return False

        matched = any(expected_err_sub.lower() in err.lower() for err in mut_validator.errors)
        if not matched:
            print(
                f"FAIL: Defect scenario '{name}' failed but did not contain expected diagnostic '{expected_err_sub}'",
                file=sys.stderr,
            )
            print("  Actual errors:", mut_validator.errors[:3], file=sys.stderr)
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
        description="GTA 5 Companion App — End-to-End Guides Data & Integration Verification Harness"
    )
    parser.add_argument(
        "--file", "-f",
        type=str,
        default=None,
        help="Path to gtav_guides.json file (auto-discovered if omitted)"
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

    # If --self-test requested, run self-tests directly
    if args.self_test:
        success = run_self_tests(verbose=args.verbose)
        return 0 if success else 1

    # Locate and load the guides dataset
    try:
        guides_file_path = resolve_guides_file_path(args.file)
    except FileNotFoundError as err:
        print(f"ERROR: {err}", file=sys.stderr)
        return 1

    sdk_lib = resolve_sdk_lib_dir()

    print("================================================================================")
    print("GTA 5 COMPANION APP — GUIDES DATASET E2E VERIFICATION")
    print("================================================================================")
    print(f"Dataset Path : {guides_file_path}")
    print(f"SDK Lib Path : {sdk_lib or 'Not Found'}")
    print(f"Target Tier  : {args.tier}")
    print("--------------------------------------------------------------------------------")

    try:
        with open(guides_file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as err:
        print(
            f"FATAL: Malformed JSON syntax in '{guides_file_path}':\n  "
            f"Line {err.lineno}, Col {err.colno}: {err.msg}",
            file=sys.stderr,
        )
        return 1
    except Exception as err:
        print(f"FATAL: Failed to read guides dataset file: {err}", file=sys.stderr)
        return 1

    total_guides = len(data) if isinstance(data, list) else 0
    print(f"Total Guides Loaded : {total_guides}")
    print("--------------------------------------------------------------------------------")

    validator = GuidesValidator(data, sdk_lib_dir=sdk_lib, verbose=args.verbose)
    is_success, errors, warnings = validator.run_all(target_tier=args.tier)

    # Print Tier Results Summary Table
    print(f"{'Tier':<10} | {'Description':<48} | {'Result':<10}")
    print("-" * 75)
    tier_meta = [
        ("Tier 1", "Dataset Volume & Topic Coverage", validator.tier_results["tier1"]),
        ("Tier 2", "Schema & Boundary Integrity", validator.tier_results["tier2"]),
        ("Tier 3", "Dart Source Static Integration Audit", validator.tier_results["tier3"]),
        ("Tier 4", "Built-in Self-Tests & Mutation Harness", validator.tier_results["tier4"]),
    ]

    for t_id, desc, passed in tier_meta:
        if passed is None:
            res_str = "SKIPPED -"
        elif passed:
            res_str = "PASS ✓"
        else:
            res_str = "FAIL ✗"
        print(f"{t_id:<10} | {desc:<48} | {res_str:<10}")

    print("================================================================================")

    if warnings:
        print(f"\nWARNINGS ({len(warnings)}):")
        for w in warnings:
            print(f"  [!] {w}")

    if not is_success:
        print(f"\nFAILURES ENCOUNTERED ({len(errors)} errors):", file=sys.stderr)
        for e in errors[:25]:
            print(f"  [-] {e}", file=sys.stderr)
        if len(errors) > 25:
            print(f"  ... and {len(errors) - 25} additional errors.", file=sys.stderr)
        print("\nOVERALL STATUS: FAILED (Exit Code 1)", file=sys.stderr)
        return 1

    print("\nOVERALL STATUS: ALL CHECKS PASSED (Exit Code 0)")
    print("Zero errors found. Guides dataset & app integration fully satisfy GTA V requirements!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
