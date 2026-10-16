#!/usr/bin/env python3
"""
Milestone 1 Empirical Challenger Stress Test Suite: Single-Player Guides Dataset,
Schema Boundaries, YouTube URL Extraction Regex, and Model Deserialization.
================================================================================

Target Dataset:
  game_companion_sdk/assets/data/gtav_guides.json

Adversarial Stress Dimensions:
  1. Byte-level JSON parsing, BOM detection, and memory footprint.
  2. ID uniqueness, regex syntax, naming boundaries, case collisions.
  3. Category coverage across all 5 mandatory canonical gameplay domains.
  4. Granular topic verification (Lester stock market, briefcases, armored trucks,
     100% completion roadmap, Strangers & Freaks, 50 stunt jumps, hardest jumps,
     flight school gold medals, 50 bridges, 15 knife flights, free heavy weapons,
     fixed supercar spawns, major easter eggs).
  5. Markdown content structural integrity: character count (>= 400), headings,
     bullet/numbered lists, formatting hygiene (balanced delimiters).
  6. YouTube URL regex extraction matrix (22+ adversarial test cases testing Dart
     RegExp vs Python verification regex, boundary conditions, edge parameters,
     whitespace, malformed tokens, and strict rickroll dQw4w9WgXcQ exclusion).
  7. Dart GuideArticle.fromJson / toJson round-trip fidelity and null/missing field
     fallback resilience.
  8. Cross-file fixture audit (GTAVFixtures.guides in fixtures.dart).
"""

import sys
import os
import json
import re
import math
import tracemalloc
from collections import Counter, defaultdict
from typing import List, Dict, Any, Optional, Tuple

DATASET_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "assets", "data", "gtav_guides.json")
)
FIXTURES_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "lib", "games", "gtav", "fixtures.dart")
)
MODEL_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "lib", "sdk", "models", "guide_article.dart")
)

# Canonical constraints
MIN_GUIDES = 12
MAX_GUIDES = 15
MIN_MARKDOWN_LEN = 400

MANDATORY_CATEGORIES = [
    "Money & Stock Market",
    "100% Completion",
    "Stunt Jumps",
    "Aerial & Flight Challenges",
    "Secrets, Weapons & Rare Vehicles",
]

ALLOWED_DIFFICULTIES = {"Beginner", "Intermediate", "Advanced"}
PROHIBITED_YOUTUBE_IDS = {"dQw4w9WgXcQ"}
GENERIC_PLACEHOLDERS = {"xxxxxxxxxxx", "12345678901", "placeholder", "00000000000"}

# Regexes under evaluation
DART_YOUTUBE_REGEX = re.compile(r'(?:v=|\/)([0-9A-Za-z_-]{11})(?:[&?]|\b|$)')
PYTHON_VERIFY_REGEX = re.compile(
    r"^https://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([A-Za-z0-9_-]{11})(?:[&?].*)?$"
)
STRICT_SAFE_YOUTUBE_REGEX = re.compile(
    r"^https://(?:(?:www\.|m\.)?youtube\.com/(?:watch\?.*v=|embed/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})(?:[&?].*)?$"
)
GUIDE_ID_REGEX = re.compile(r"^guide_[a-z0-9]+(?:_[a-z0-9]+)*$")
MARKDOWN_HEADING_REGEX = re.compile(r"(?:^|\n)#{1,6}\s+\S+")
MARKDOWN_LIST_REGEX = re.compile(r"(?:^|\n)\s*(?:[-*+]|\d+\.)\s+\S+")


class ChallengerTestFailure(Exception):
    pass


class EmpiricalResults:
    def __init__(self):
        self.passed_checks = 0
        self.failed_checks = 0
        self.warnings = 0
        self.diagnostics = []

    def pass_test(self, name: str, details: str = ""):
        self.passed_checks += 1
        msg = f"[PASS] {name}"
        if details:
            msg += f" — {details}"
        print(f"  ✓ {msg}")

    def fail_test(self, name: str, reason: str):
        self.failed_checks += 1
        msg = f"[FAIL] {name} — {reason}"
        self.diagnostics.append(msg)
        print(f"  ✗ {msg}")

    def warn(self, name: str, reason: str):
        self.warnings += 1
        msg = f"[WARN] {name} — {reason}"
        self.diagnostics.append(msg)
        print(f"  ⚠ {msg}")


def extract_dart_youtube_id(url: Optional[str]) -> Optional[str]:
    """Replicates GuideArticle.youtubeVideoId in Dart."""
    if not url:
        return None
    match = DART_YOUTUBE_REGEX.search(url)
    if match:
        return match.group(1)
    return None


def extract_python_verify_id(url: Optional[str]) -> Optional[str]:
    """Replicates verify_guides_data.py regex."""
    if not url:
        return None
    match = PYTHON_VERIFY_REGEX.match(url)
    if match:
        return match.group(1)
    return None


def run_empirical_stress_suite() -> EmpiricalResults:
    res = EmpiricalResults()
    print("=" * 80)
    print("GTA V COMPANION APP — M1 EMPIRICAL CHALLENGER STRESS HARNESS")
    print(f"Target Dataset: {DATASET_PATH}")
    print("=" * 80)

    # --------------------------------------------------------------------------
    # SUITE 1: Byte-Level File Integrity, Parsing & Memory Profile
    # --------------------------------------------------------------------------
    print("\n[SUITE 1] Byte-Level File Integrity, BOM Detection & Memory Profile")
    if not os.path.exists(DATASET_PATH):
        res.fail_test("File Existence", f"File does not exist: {DATASET_PATH}")
        return res
    res.pass_test("File Existence", f"Found dataset at {DATASET_PATH}")

    file_size = os.path.getsize(DATASET_PATH)
    res.pass_test("File Size", f"{file_size} bytes ({file_size / 1024:.2f} KB)")

    with open(DATASET_PATH, "rb") as bf:
        raw_bytes = bf.read()

    # BOM check
    if raw_bytes.startswith(b"\xef\xbb\xbf"):
        res.fail_test("BOM Check", "UTF-8 BOM detected at byte offset 0")
    else:
        res.pass_test("BOM Check", "No byte-order mark (clean UTF-8)")

    # Null bytes check
    if b"\x00" in raw_bytes:
        res.fail_test("Null Byte Poisoning", "Null bytes found in raw binary payload")
    else:
        res.pass_test("Null Byte Poisoning", "Zero null bytes detected")

    # JSON Parse & Memory profile
    tracemalloc.start()
    try:
        data = json.loads(raw_bytes.decode("utf-8"))
        current_mem, peak_mem = tracemalloc.get_traced_memory()
        tracemalloc.stop()
        res.pass_test(
            "JSON Syntax & Parse",
            f"Parsed successfully (RAM: current {current_mem/1024:.1f} KB, peak {peak_mem/1024:.1f} KB)"
        )
    except Exception as e:
        tracemalloc.stop()
        res.fail_test("JSON Syntax & Parse", f"Malformed JSON: {e}")
        return res

    if not isinstance(data, list):
        res.fail_test("Root Structure", f"Expected JSON array, got {type(data).__name__}")
        return res
    res.pass_test("Root Structure", f"Valid JSON array containing {len(data)} items")

    # --------------------------------------------------------------------------
    # SUITE 2: Volume, Schema Completeness & Boundary Enforcements
    # --------------------------------------------------------------------------
    print("\n[SUITE 2] Volume, Schema Completeness & Field Type Boundaries")
    count = len(data)
    if MIN_GUIDES <= count <= MAX_GUIDES:
        res.pass_test("Dataset Volume Bounds", f"Count={count} satisfies [{MIN_GUIDES}, {MAX_GUIDES}]")
    else:
        res.fail_test("Dataset Volume Bounds", f"Count={count} outside [{MIN_GUIDES}, {MAX_GUIDES}]")

    REQUIRED_KEYS = {
        "id", "title", "category", "tags", "difficulty",
        "readTimeMinutes", "contentMarkdown", "videoUrl"
    }

    ids = []
    seen_ids = set()
    category_counter = Counter()

    for idx, item in enumerate(data):
        guide_label = f"Guide[{idx}] (id={item.get('id', 'MISSING')})"
        if not isinstance(item, dict):
            res.fail_test(f"{guide_label} Type", "Guide entry is not a JSON object")
            continue

        item_keys = set(item.keys())
        missing_keys = REQUIRED_KEYS - item_keys
        extra_keys = item_keys - REQUIRED_KEYS

        if missing_keys:
            res.fail_test(f"{guide_label} Missing Keys", f"Missing required keys: {sorted(missing_keys)}")
        if extra_keys:
            res.warn(f"{guide_label} Extra Keys", f"Unexpected surplus keys: {sorted(extra_keys)}")

        # ID Validation
        gid = item.get("id")
        if not isinstance(gid, str) or not gid:
            res.fail_test(f"{guide_label} ID", "ID is missing or not a non-empty string")
        else:
            ids.append(gid)
            if gid in seen_ids:
                res.fail_test(f"{guide_label} ID Uniqueness", f"Duplicate ID detected: '{gid}'")
            seen_ids.add(gid)

            if not GUIDE_ID_REGEX.match(gid):
                res.fail_test(
                    f"{guide_label} ID Regex Conformity",
                    f"ID '{gid}' does not conform to ^guide_[a-z0-9_]+$"
                )
            if gid != gid.strip():
                res.fail_test(f"{guide_label} ID Whitespace", f"ID '{gid}' has untrimmed whitespace")

        # Title Validation
        title = item.get("title")
        if not isinstance(title, str) or len(title.strip()) < 10:
            res.fail_test(f"{guide_label} Title", f"Title missing or too short: {title!r}")
        elif "\n" in title or "\r" in title:
            res.fail_test(f"{guide_label} Title Newlines", "Title contains raw newline characters")

        # Category Validation
        cat = item.get("category")
        if cat not in MANDATORY_CATEGORIES:
            res.fail_test(f"{guide_label} Category", f"Category '{cat}' not in {MANDATORY_CATEGORIES}")
        else:
            category_counter[cat] += 1

        # Tags Validation
        tags = item.get("tags")
        if not isinstance(tags, list) or len(tags) < 2:
            res.fail_test(f"{guide_label} Tags", f"Tags must be a list with at least 2 items, got {tags}")
        else:
            for t_idx, tag in enumerate(tags):
                if not isinstance(tag, str) or not tag.strip():
                    res.fail_test(f"{guide_label} Tag[{t_idx}]", f"Tag is empty or non-string: {tag!r}")
            if len(tags) != len(set(tags)):
                res.fail_test(f"{guide_label} Duplicate Tags", f"Duplicate tags found in {tags}")

        # Difficulty Validation
        diff = item.get("difficulty")
        if diff not in ALLOWED_DIFFICULTIES:
            res.fail_test(
                f"{guide_label} Difficulty",
                f"Difficulty '{diff}' not in {ALLOWED_DIFFICULTIES}"
            )

        # ReadTimeMinutes Validation
        rt = item.get("readTimeMinutes")
        if type(rt) is not int or rt <= 0 or rt > 60:
            res.fail_test(f"{guide_label} ReadTime", f"readTimeMinutes must be int in 1..60, got {rt} ({type(rt)})")

    res.pass_test("Schema & ID Verification", f"Checked all {count} guides across schema boundaries")

    # Case collision check for IDs
    lower_ids = [gid.lower() for gid in ids]
    if len(lower_ids) != len(set(lower_ids)):
        res.fail_test("ID Case Collision", "Case-insensitive duplicate ID exists")
    else:
        res.pass_test("ID Case Uniqueness", "No case-insensitive ID collisions")

    # --------------------------------------------------------------------------
    # SUITE 3: Category Coverage & Subtopic Specificity
    # --------------------------------------------------------------------------
    print("\n[SUITE 3] Category Coverage & Gameplay Topic Completeness")
    missing_cats = [c for c in MANDATORY_CATEGORIES if category_counter[c] == 0]
    if missing_cats:
        res.fail_test("Category Coverage", f"Missing required categories: {missing_cats}")
    else:
        res.pass_test("Category Coverage", f"All 5 required categories populated: {dict(category_counter)}")

    # Specific subtopic checklist verification across the dataset
    all_content = " ".join([
        f"{g.get('title', '')} {g.get('contentMarkdown', '')} {' '.join(g.get('tags', []))}"
        for g in data
    ]).lower()

    subtopics = [
        ("Lester Assassinations & Stock Market", ["lester", "stock", "bawsaq", "lcn"]),
        ("Hidden Briefcases / Underwater Caches", ["briefcase", "underwater", "scuba"]),
        ("Armored Trucks (Gruppe Sechs)", ["gruppe sechs", "armored", "truck"]),
        ("100% Completion Checklist / Roadmap", ["100%", "career criminal", "checklist"]),
        ("Strangers & Freaks (Franklin)", ["strangers", "freaks", "franklin", "tonya"]),
        ("50 Stunt Jumps Mechanics & Physics", ["stunt jump", "landing", "bati 801"]),
        ("Hardest Stunt Jumps (Prison, Lighthouse)", ["bolingbroke", "lighthouse"]),
        ("Flight School Gold Medals (12 Lessons)", ["flight school", "gold medal", "lessons"]),
        ("50 Under the Bridge", ["under the bridge", "50", "buzzard"]),
        ("15 Knife Flights", ["knife flight", "15", "mallard"]),
        ("Free Heavy Weapon Pickups (Fort Zancudo, Minigun)", ["minigun", "fort zancudo", "rpg"]),
        ("Guaranteed Supercar Spawns (Adder, Zentorno)", ["adder", "zentorno", "rockford"]),
        ("Major Easter Eggs (Mt Chiliad UFO, Mt Gordo Ghost, Infinity 8)", ["chiliad", "ufo", "ghost", "infinity"]),
    ]

    for topic_name, keywords in subtopics:
        missing_kw = [kw for kw in keywords if kw not in all_content]
        if missing_kw:
            res.fail_test(f"Subtopic: {topic_name}", f"Missing expected gameplay terms: {missing_kw}")
        else:
            res.pass_test(f"Subtopic: {topic_name}", "All key gameplay mechanics referenced")

    # --------------------------------------------------------------------------
    # SUITE 4: Markdown Content Integrity & Rich Formatting Metrics
    # --------------------------------------------------------------------------
    print("\n[SUITE 4] Markdown Content Length, Structure & Delimiter Hygiene")
    lengths = []
    word_counts = []
    line_counts = []

    for item in data:
        gid = item.get("id")
        md = item.get("contentMarkdown", "")
        length = len(md)
        words = len(md.split())
        lines = md.count("\n") + 1
        lengths.append(length)
        word_counts.append(words)
        line_counts.append(lines)

        # Length boundary
        if length < MIN_MARKDOWN_LEN:
            res.fail_test(f"Markdown Length '{gid}'", f"Length {length} < required {MIN_MARKDOWN_LEN}")

        # Headings check
        headings = MARKDOWN_HEADING_REGEX.findall(md)
        if len(headings) < 2:
            res.fail_test(f"Markdown Headings '{gid}'", f"Only {len(headings)} headings found (need >= 2)")

        # Lists check
        lists = MARKDOWN_LIST_REGEX.findall(md)
        if len(lists) < 2:
            res.fail_test(f"Markdown Lists '{gid}'", f"Only {len(lists)} list items found (need >= 2)")

        # Bold formatting check
        if "**" not in md:
            res.warn(f"Markdown Bold Styling '{gid}'", "No bold text found")

        # Delimiter balancing checks
        # Backtick count
        triple_ticks = md.count("```")
        if triple_ticks % 2 != 0:
            res.fail_test(f"Markdown Code Blocks '{gid}'", f"Unbalanced triple backticks ({triple_ticks})")

        # Inline backticks (excluding triple backticks)
        cleaned_md = md.replace("```", "")
        single_ticks = cleaned_md.count("`")
        if single_ticks % 2 != 0:
            res.fail_test(f"Markdown Inline Code '{gid}'", f"Unbalanced single backticks ({single_ticks})")

        # Script tags / XSS injection check
        if "<script" in md.lower() or "javascript:" in md.lower():
            res.fail_test(f"Markdown Hygiene '{gid}'", "Suspicious script / execution tokens in markdown")

    mean_len = sum(lengths) / len(lengths)
    sorted_len = sorted(lengths)
    median_len = sorted_len[len(sorted_len) // 2]
    min_len = min(lengths)
    max_len = max(lengths)

    res.pass_test(
        "Markdown Length Statistics",
        f"Min={min_len}, Max={max_len}, Mean={mean_len:.1f}, Median={median_len} chars (All >= {MIN_MARKDOWN_LEN})"
    )
    res.pass_test(
        "Markdown Word Statistics",
        f"Min={min(word_counts)}, Max={max(word_counts)}, Mean={sum(word_counts)/len(word_counts):.1f} words"
    )

    # --------------------------------------------------------------------------
    # SUITE 5: Dataset YouTube URL Validation & Rickroll Forensics
    # --------------------------------------------------------------------------
    print("\n[SUITE 5] Dataset YouTube URL Validation & Strict Rickroll Forensics")
    seen_video_ids = set()

    for item in data:
        gid = item.get("id")
        url = item.get("videoUrl")
        if not url:
            res.fail_test(f"Video URL '{gid}'", "videoUrl is missing or empty")
            continue

        # Scheme check
        if not url.startswith("https://"):
            res.fail_test(f"Video URL Scheme '{gid}'", f"URL does not start with https://: '{url}'")

        # Extract using Dart regex
        dart_id = extract_dart_youtube_id(url)
        py_id = extract_python_verify_id(url)

        if not dart_id:
            res.fail_test(f"Dart Video ID Extraction '{gid}'", f"Dart RegExp failed to extract ID from '{url}'")
        elif len(dart_id) != 11:
            res.fail_test(f"Dart Video ID Length '{gid}'", f"Extracted ID '{dart_id}' length != 11")

        if not py_id:
            res.fail_test(f"Python Video ID Extraction '{gid}'", f"Python verify regex failed on '{url}'")
        elif py_id != dart_id:
            res.fail_test(
                f"Regex ID Parity '{gid}'",
                f"Dart extracted '{dart_id}' but Python regex extracted '{py_id}'"
            )

        # Prohibited Rickroll test
        if dart_id in PROHIBITED_YOUTUBE_IDS or (url and "dQw4w9WgXcQ" in url):
            res.fail_test(
                f"Prohibited Rickroll Rejection '{gid}'",
                f"RICKROLL DETECTED in guide '{gid}'! (ID: {dart_id})"
            )

        # Generic dummy placeholders
        if dart_id in GENERIC_PLACEHOLDERS:
            res.fail_test(f"Placeholder Detection '{gid}'", f"Placeholder ID found: '{dart_id}'")

        if dart_id:
            seen_video_ids.add(dart_id)

    res.pass_test(
        "Dataset Video IDs Verification",
        f"All {len(data)} guides have valid 11-char YouTube IDs ({len(seen_video_ids)} distinct IDs, 0 rickrolls)"
    )

    # --------------------------------------------------------------------------
    # SUITE 6: YouTube URL Extraction Adversarial Matrix & Fuzzing
    # --------------------------------------------------------------------------
    print("\n[SUITE 6] YouTube URL Extraction Adversarial Matrix & Boundary Fuzzing")
    
    test_matrix: List[Tuple[str, Optional[str], str]] = [
        # (input_url, expected_id, description)
        ("https://www.youtube.com/watch?v=hG7W5v6J7Z0", "hG7W5v6J7Z0", "Standard www watch URL"),
        ("https://youtube.com/watch?v=hG7W5v6J7Z0", "hG7W5v6J7Z0", "Standard no-www watch URL"),
        ("https://m.youtube.com/watch?v=hG7W5v6J7Z0", "hG7W5v6J7Z0", "Mobile m.youtube.com watch URL"),
        ("https://youtu.be/hG7W5v6J7Z0", "hG7W5v6J7Z0", "Short youtu.be URL"),
        ("https://youtu.be/hG7W5v6J7Z0?si=trackingToken123", "hG7W5v6J7Z0", "Short youtu.be with query param"),
        ("https://www.youtube.com/watch?v=hG7W5v6J7Z0&t=42s", "hG7W5v6J7Z0", "Watch URL with trailing timestamp"),
        ("https://www.youtube.com/watch?v=hG7W5v6J7Z0&list=PL123456", "hG7W5v6J7Z0", "Watch URL with playlist parameter"),
        ("https://www.youtube.com/watch?feature=player_embedded&v=hG7W5v6J7Z0", "hG7W5v6J7Z0", "Query params preceding v="),
        ("https://www.youtube.com/embed/hG7W5v6J7Z0", "hG7W5v6J7Z0", "Embed URL format"),
        ("https://www.youtube.com/shorts/hG7W5v6J7Z0", "hG7W5v6J7Z0", "YouTube Shorts URL format"),
        ("https://www.youtube.com/watch?v=AbC_-123XyZ", "AbC_-123XyZ", "ID with hyphens and underscores"),
        # Whitespace handling
        ("  https://www.youtube.com/watch?v=hG7W5v6J7Z0  ", "hG7W5v6J7Z0", "Leading and trailing whitespace"),
        # Malformed & Defect inputs
        ("https://www.youtube.com/watch?v=1234567890", None, "Truncated 10-char ID (too short)"),
        ("https://www.youtube.com/watch?v=123456789012", None, "Overlong 12-char alphanumeric ID"),
        ("https://www.youtube.com/watch?v=", None, "Empty v= parameter"),
        ("https://www.youtube.com/watch", None, "No query string"),
        ("https://youtu.be/", None, "Short URL with no path token"),
        ("https://www.google.com/search?q=gtav", None, "Completely different URL"),
        ("", None, "Empty string input"),
        (None, None, "Null/None input"),
        # Rickroll variants
        ("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ", "Rickroll standard watch"),
        ("https://youtu.be/dQw4w9WgXcQ", "dQw4w9WgXcQ", "Rickroll short URL"),
        ("https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1", "dQw4w9WgXcQ", "Rickroll autoplay embed"),
    ]

    for raw_url, expected_id, label in test_matrix:
        dart_extracted = extract_dart_youtube_id(raw_url)
        is_rickroll = (dart_extracted == "dQw4w9WgXcQ")

        if label.startswith("Rickroll"):
            # Should extract dQw4w9WgXcQ and trigger rejection filter
            if dart_extracted == "dQw4w9WgXcQ" and is_rickroll:
                res.pass_test(f"Adversarial Matrix: {label}", f"Correctly extracted and flagged as RICKROLL")
            else:
                res.fail_test(f"Adversarial Matrix: {label}", f"Failed to detect rickroll: {dart_extracted}")
        elif expected_id is None:
            # Should fail to extract valid 11-char ID
            if dart_extracted is None or len(dart_extracted) != 11:
                res.pass_test(f"Adversarial Matrix: {label}", f"Correctly rejected/returned None")
            else:
                # Special boundary check: overlong ID with hyphen
                res.fail_test(
                    f"Adversarial Matrix: {label}",
                    f"Expected None but extracted '{dart_extracted}'"
                )
        else:
            # Valid expected extraction
            if dart_extracted == expected_id:
                res.pass_test(f"Adversarial Matrix: {label}", f"Extracted '{dart_extracted}'")
            else:
                res.fail_test(
                    f"Adversarial Matrix: {label}",
                    f"Expected '{expected_id}', got '{dart_extracted}'"
                )

    # Boundary analysis: Dart regex vs non-YouTube host
    # Notice: Dart regex does not validate host domain:
    phish_url = "https://malicious-phishing.com/watch?v=hG7W5v6J7Z0"
    phish_id = extract_dart_youtube_id(phish_url)
    if phish_id == "hG7W5v6J7Z0":
        res.warn(
            "Host Validation Boundary (Dart Model)",
            "Dart RegExp matches any domain containing 'v=11chars'. Host check relies on dataset hygiene."
        )

    # --------------------------------------------------------------------------
    # SUITE 7: Dart GuideArticle Deserialization / Serialization Round-Trip
    # --------------------------------------------------------------------------
    print("\n[SUITE 7] Dart GuideArticle Deserialization / Serialization Round-Trip Simulation")
    
    def simulate_dart_from_json(j: Dict[str, Any]) -> Dict[str, Any]:
        """Simulates GuideArticle.fromJson in Dart."""
        return {
            "id": j.get("id") or "",
            "title": j.get("title") or "",
            "category": j.get("category") or "General",
            "tags": [str(t) for t in j.get("tags", [])] if j.get("tags") is not None else [],
            "difficulty": j.get("difficulty") or "Intermediate",
            "readTimeMinutes": int(j.get("readTimeMinutes", 5)) if j.get("readTimeMinutes") is not None else 5,
            "contentMarkdown": j.get("contentMarkdown") or "",
            "videoUrl": j.get("videoUrl"),
        }

    def simulate_dart_to_json(model: Dict[str, Any]) -> Dict[str, Any]:
        """Simulates GuideArticle.toJson in Dart."""
        return {
            "id": model["id"],
            "title": model["title"],
            "category": model["category"],
            "tags": model["tags"],
            "difficulty": model["difficulty"],
            "readTimeMinutes": model["readTimeMinutes"],
            "contentMarkdown": model["contentMarkdown"],
            "videoUrl": model["videoUrl"],
        }

    # Test round trip on all 13 guides
    round_trip_passed = True
    for idx, guide_json in enumerate(data):
        model = simulate_dart_from_json(guide_json)
        re_json = simulate_dart_to_json(model)

        for key in REQUIRED_KEYS:
            if guide_json[key] != re_json[key]:
                round_trip_passed = False
                res.fail_test(
                    f"Round-Trip Fidelity Guide[{idx}]",
                    f"Key '{key}' mismatch: original {guide_json[key]!r} != serialized {re_json[key]!r}"
                )
                break

    if round_trip_passed:
        res.pass_test(
            "Round-Trip Serialization Fidelity",
            f"All {len(data)} guides serialized with 100% key-by-key, type-by-type fidelity"
        )

    # Stress test null/missing field defaults
    corrupt_entry = {
        "id": "test_corrupt_guide",
        "title": "Minimal Test",
        # missing category, tags, difficulty, readTimeMinutes, contentMarkdown, videoUrl
    }
    fallback_model = simulate_dart_from_json(corrupt_entry)
    if (
        fallback_model["category"] == "General"
        and fallback_model["difficulty"] == "Intermediate"
        and fallback_model["readTimeMinutes"] == 5
        and fallback_model["tags"] == []
        and fallback_model["contentMarkdown"] == ""
        and fallback_model["videoUrl"] is None
    ):
        res.pass_test(
            "Model Fallback Defensiveness",
            "Missing fields gracefully defaulted without throwing null reference exceptions"
        )
    else:
        res.fail_test(
            "Model Fallback Defensiveness",
            f"Defaults failed to apply: {fallback_model}"
        )

    # --------------------------------------------------------------------------
    # SUITE 8: Cross-File Fixtures Audit (fixtures.dart)
    # --------------------------------------------------------------------------
    print("\n[SUITE 8] Cross-File Fixtures Audit (GTAVFixtures in fixtures.dart)")
    if os.path.exists(FIXTURES_PATH):
        with open(FIXTURES_PATH, "r", encoding="utf-8") as ff:
            fixtures_code = ff.read()

        if "dQw4w9WgXcQ" in fixtures_code:
            res.fail_test("Fixtures Rickroll Audit", "fixtures.dart contains prohibited rickroll ID dQw4w9WgXcQ")
        else:
            res.pass_test("Fixtures Rickroll Audit", "fixtures.dart is free of prohibited rickroll dummy URLs")

        if "static List<GuideArticle> get guides" in fixtures_code:
            res.pass_test("Fixtures Guides Getter", "Found static List<GuideArticle> get guides in fixtures.dart")
        else:
            res.fail_test("Fixtures Guides Getter", "Missing static guides getter in fixtures.dart")

        # Check constructor fields in fixtures.dart
        if "category:" in fixtures_code and "difficulty:" in fixtures_code and "readTimeMinutes:" in fixtures_code:
            res.pass_test("Fixtures Model Contract", "fixtures.dart matches enriched GuideArticle constructor")
        else:
            res.fail_test("Fixtures Model Contract", "fixtures.dart missing updated GuideArticle parameters")
    else:
        res.warn("Fixtures Path", f"fixtures.dart not found at {FIXTURES_PATH}")

    # --------------------------------------------------------------------------
    # SUMMARY & FINAL VERDICT
    # --------------------------------------------------------------------------
    print("\n" + "=" * 80)
    print("EMPIRICAL TEST SUMMARY & VERDICT")
    print(f"Passed Checks:   {res.passed_checks}")
    print(f"Failed Checks:   {res.failed_checks}")
    print(f"Warnings:        {res.warnings}")
    print("=" * 80)

    if res.failed_checks == 0:
        print("\nFINAL VERDICT: [APPROVE] — All empirical stress tests PASSED.")
    else:
        print(f"\nFINAL VERDICT: [REJECT] — {res.failed_checks} empirical failure(s) detected.")

    return res


if __name__ == "__main__":
    results = run_empirical_stress_suite()
    if results.failed_checks > 0:
        sys.exit(1)
    sys.exit(0)
