import json
import os
import sys

import requests
from PIL import Image
from io import BytesIO

def process_image(url, output_path):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    img = Image.open(BytesIO(response.content))

    # Calculate aspect ratio
    width, height = img.size
    max_dim = 800
    if width > max_dim or height > max_dim:
        if width > height:
            new_width = max_dim
            new_height = int(max_dim * height / width)
        else:
            new_height = max_dim
            new_width = int(max_dim * width / height)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # Ensure directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Convert and compress
    img.save(output_path, "WEBP", quality=80)


def process_json_file(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    filename = os.path.basename(file_path)
    default_category = filename.replace("gtav_", "").replace(".json", "")

    total_downloads = 0
    failed_downloads = 0

    for item in data:
        original_url = item.get("originalImageUrl")
        if not original_url:
            continue

        item_id = item.get("item_id")
        if not item_id:
            print(f"Skipping item missing item_id in {file_path}")
            continue

        category = item.get("category", default_category)

        output_relative_path = f"web/media/gtav/{category}/{item_id}.webp"
        output_path = os.path.join("game_companion_sdk", output_relative_path)

        cdn_url = f"https://mickymc95.github.io/game_companion_app/media/gtav/{category}/{item_id}.webp"

        total_downloads += 1
        try:
            print(f"Downloading {original_url} to {output_path}...")
            process_image(original_url, output_path)
            item["imageUrl"] = cdn_url
            print(f"Successfully processed {item_id}")
        except Exception as e:
            failed_downloads += 1
            print(f"Failed to process {item_id} from {original_url}: {e}")

    # Write changes back to json
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    return total_downloads, failed_downloads

def main():
    json_files = [
        "game_companion_sdk/assets/data/gtav_vehicles.json",
        "game_companion_sdk/assets/data/gtav_weapons.json"
    ]

    total = 0
    failed = 0

    for f in json_files:
        if os.path.exists(f):
            t, f_c = process_json_file(f)
            total += t
            failed += f_c
        else:
            print(f"Warning: File {f} does not exist.")

    print(f"\nProcessing complete. Total: {total}, Failed: {failed}")
    if total > 0 and failed == total:
        print("All downloads failed. Exiting with error.")
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
