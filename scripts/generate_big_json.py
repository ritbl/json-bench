#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import random
from datetime import datetime, timezone
from pathlib import Path


ADJECTIVES = [
    "amber",
    "brisk",
    "crimson",
    "dense",
    "ember",
    "frozen",
    "golden",
    "hidden",
    "ivory",
    "jagged",
    "lunar",
    "misty",
    "navy",
    "oak",
    "polar",
    "quiet",
    "rising",
    "silver",
    "tidal",
    "urban",
    "velvet",
    "wild",
]

NOUNS = [
    "anchor",
    "beacon",
    "canyon",
    "delta",
    "engine",
    "forest",
    "galaxy",
    "harbor",
    "island",
    "journey",
    "kernel",
    "lantern",
    "market",
    "needle",
    "orchard",
    "planet",
    "quartz",
    "rocket",
    "summit",
    "temple",
    "valley",
    "window",
]

CATEGORIES = [
    "analytics",
    "audio",
    "books",
    "cloud",
    "gaming",
    "garden",
    "health",
    "home",
    "industrial",
    "kitchen",
    "mobile",
    "networking",
    "office",
    "outdoor",
    "security",
    "storage",
]

TAGS = [
    "bestseller",
    "bulk",
    "eco",
    "flash-sale",
    "limited",
    "new",
    "premium",
    "seasonal",
    "staff-pick",
    "warehouse-a",
    "warehouse-b",
    "warehouse-c",
]

COLORS = ["black", "blue", "bronze", "green", "red", "silver", "white"]
SIZES = ["xs", "s", "m", "l", "xl", "xxl"]
COUNTRIES = ["DE", "FR", "GB", "JP", "PL", "SE", "US"]
CITIES = ["Austin", "Berlin", "Gdansk", "London", "Osaka", "Paris", "Stockholm"]
STATUSES = ["active", "backorder", "discontinued", "preview"]


def short_text(rng: random.Random, words: int) -> str:
    return " ".join(
        f"{ADJECTIVES[rng.randrange(len(ADJECTIVES))]} {NOUNS[rng.randrange(len(NOUNS))]}"
        for _ in range(words)
    )


def seller(rng: random.Random, item_index: int) -> dict[str, object]:
    return {
        "id": f"seller-{item_index % 97:03d}",
        "name": short_text(rng, 2).title(),
        "country": COUNTRIES[rng.randrange(len(COUNTRIES))],
        "rating": round(rng.uniform(3.6, 5.0), 3),
        "priority": rng.randrange(1, 6),
        "contact": {
            "email": f"seller{item_index % 97:03d}@example.test",
            "phone": f"+1-555-{item_index % 10000:04d}",
        },
    }


def attribute(rng: random.Random, index: int) -> dict[str, object]:
    return {
        "name": f"attr-{index:02d}",
        "value": short_text(rng, 2),
        "score": round(rng.uniform(0.0, 1.0), 6),
    }


def variant(rng: random.Random, item_index: int, variant_index: int) -> dict[str, object]:
    return {
        "id": f"var-{item_index:06d}-{variant_index:02d}",
        "sku": f"SKU-{item_index:06d}-{variant_index:02d}",
        "color": COLORS[(item_index + variant_index) % len(COLORS)],
        "size": SIZES[(item_index + variant_index * 2) % len(SIZES)],
        "status": STATUSES[(item_index + variant_index) % len(STATUSES)],
        "priceDelta": round(rng.uniform(-15.0, 25.0), 2),
        "stock": rng.randrange(0, 600),
        "barcode": f"{item_index:06d}{variant_index:02d}{rng.randrange(100000, 999999)}",
        "attributes": [attribute(rng, i) for i in range(3)],
    }


def review(rng: random.Random, item_index: int, review_index: int) -> dict[str, object]:
    return {
        "userId": f"user-{item_index:06d}-{review_index:02d}",
        "rating": rng.randrange(1, 6),
        "title": short_text(rng, 3).title(),
        "body": short_text(rng, 14),
        "verified": rng.choice([True, False]),
        "helpfulVotes": rng.randrange(0, 500),
        "createdAt": f"2025-{(review_index % 12) + 1:02d}-{(review_index % 28) + 1:02d}T12:34:56Z",
    }


def item(rng: random.Random, item_index: int, variants: int, reviews: int) -> dict[str, object]:
    category_count = 3 + (item_index % 3)
    tag_count = 3 + (item_index % 4)
    attribute_count = 5 + (item_index % 4)
    related_count = 6 + (item_index % 5)
    base_price = round(10.0 + item_index * 0.07 + rng.uniform(0.0, 50.0), 2)
    return {
        "id": item_index,
        "sku": f"SKU-{item_index:08d}",
        "name": short_text(rng, 4).title(),
        "description": short_text(rng, 24),
        "price": base_price,
        "quantity": rng.randrange(0, 5000),
        "active": rng.choice([True, True, True, False]),
        "categories": [CATEGORIES[(item_index + i) % len(CATEGORIES)] for i in range(category_count)],
        "tags": [TAGS[(item_index + i * 2) % len(TAGS)] for i in range(tag_count)],
        "seller": seller(rng, item_index),
        "dimensions": {
            "width": round(rng.uniform(1.0, 150.0), 3),
            "height": round(rng.uniform(1.0, 150.0), 3),
            "depth": round(rng.uniform(1.0, 150.0), 3),
            "weight": round(rng.uniform(0.1, 80.0), 3),
        },
        "warehouse": {
            "id": f"wh-{item_index % 31:02d}",
            "city": CITIES[item_index % len(CITIES)],
            "aisle": f"A-{(item_index * 7) % 128:03d}",
            "bin": f"B-{(item_index * 13) % 2048:04d}",
            "temperatureControlled": rng.choice([True, False]),
        },
        "attributes": [attribute(rng, i) for i in range(attribute_count)],
        "variants": [variant(rng, item_index, i) for i in range(variants)],
        "reviews": [review(rng, item_index, i) for i in range(reviews)],
        "relatedIds": [item_index + 100000 + i for i in range(related_count)],
        "metrics": {
            "views": rng.randrange(50, 5_000_000),
            "sales": rng.randrange(0, 250_000),
            "returns": rng.randrange(0, 8000),
            "conversionRate": round(rng.uniform(0.0001, 0.75), 6),
        },
    }


def generate(output: Path, items: int, variants: int, reviews: int, seed: int) -> None:
    rng = random.Random(seed)
    output.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    with output.open("w", encoding="utf-8") as handle:
        handle.write("{")
        handle.write('"dataset":"json-bench-big-payload",')
        handle.write(f'"generatedAt":{json.dumps(timestamp)},')
        handle.write(f'"seed":{seed},')
        handle.write(f'"itemCount":{items},')
        handle.write(f'"variantCount":{items * variants},')
        handle.write(f'"reviewCount":{items * reviews},')
        handle.write('"items":[')
        for index in range(items):
            if index:
                handle.write(",")
            json.dump(item(rng, index, variants, reviews), handle, separators=(",", ":"), ensure_ascii=True)
        handle.write("]}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a large nested JSON payload for benchmarks.")
    parser.add_argument("--output", type=Path, required=True, help="Output JSON file path")
    parser.add_argument("--items", type=int, default=8000, help="Number of top-level items")
    parser.add_argument("--variants", type=int, default=4, help="Variants per item")
    parser.add_argument("--reviews", type=int, default=6, help="Reviews per item")
    parser.add_argument("--seed", type=int, default=20260407, help="Deterministic RNG seed")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    generate(args.output, args.items, args.variants, args.reviews, args.seed)
    size_bytes = args.output.stat().st_size
    print(
        f"wrote {args.output} "
        f"items={args.items} variants={args.variants} reviews={args.reviews} "
        f"size_bytes={size_bytes}"
    )


if __name__ == "__main__":
    main()

