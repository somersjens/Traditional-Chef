#!/usr/bin/env python3
"""Convert recipe CSVs into app-ready JSON and Localizable.strings.

Inputs (default):
  recipe_import/recipes.csv (includes optional recipe_url column)
  recipe_import/groceries.csv
  recipe_import/steps.csv
  recipe_import/tools.csv

Outputs:
  recipe_import/output/recipes.json
  recipe_import/output/en.lproj/Localizable.strings
  recipe_import/output/nl.lproj/Localizable.strings
"""

from __future__ import annotations

import csv
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional

BASE_DIR = Path(__file__).resolve().parent
DEFAULT_RECIPES = BASE_DIR / "recipes.csv"
DEFAULT_GROCERIES = BASE_DIR / "groceries.csv"
DEFAULT_STEPS = BASE_DIR / "steps.csv"
DEFAULT_TOOLS = BASE_DIR / "tools.csv"
APP_DIR = BASE_DIR.parent / "Traditional Chef" / "Traditional Chef"
LOCALIZATION_DIR = APP_DIR
RECIPES_JSON_PATH = APP_DIR / "recipes.json"

LANGUAGES = ["en", "nl", "de", "fr"]
LOCALIZATION_MARKER = "// === AUTO-GENERATED RECIPES BELOW ==="
GRAMS_PER_OUNCE = 28.349523125


@dataclass
class LocalizedStrings:
    values: Dict[str, Dict[str, str]]

    def __init__(self) -> None:
        self.values = {lang: {} for lang in LANGUAGES}

    def add(self, key: str, lang: str, value: Optional[str]) -> None:
        if not value:
            return
        self.values[lang][key] = capitalize_first_text_character(value)

    def write(self, output_dir: Path) -> None:
        for lang, entries in self.values.items():
            lang_dir = output_dir / f"{lang}.lproj"
            lang_dir.mkdir(parents=True, exist_ok=True)
            output_path = lang_dir / "Localizable.strings"
            prefix_lines: List[str] = []
            if output_path.exists():
                existing_lines = output_path.read_text(encoding="utf-8").splitlines()
                if LOCALIZATION_MARKER in existing_lines:
                    marker_index = existing_lines.index(LOCALIZATION_MARKER)
                    prefix_lines = existing_lines[:marker_index]
                else:
                    prefix_lines = existing_lines

            with output_path.open("w", encoding="utf-8") as handle:
                for line in prefix_lines:
                    handle.write(f"{line}\n")
                if prefix_lines and prefix_lines[-1].strip():
                    handle.write("\n")
                handle.write(f"{LOCALIZATION_MARKER}\n")
                for key in sorted(entries.keys()):
                    value = entries[key].replace("\"", "\\\"")
                    handle.write(f"\"{key}\" = \"{value}\";\n")


def parse_bool(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "y"}


def capitalize_first_text_character(value: str) -> str:
    for index, char in enumerate(value):
        if char.isalpha():
            if char.islower():
                return f"{value[:index]}{char.upper()}{value[index + 1:]}"
            return value
    return value


def parse_int(value: str) -> Optional[int]:
    value = (value or "").strip()
    if not value:
        return None
    try:
        return int(value)
    except ValueError:
        parsed_float = parse_float(value)
        if parsed_float is None:
            return None
        return int(parsed_float)


def parse_sort_index(value: str) -> Optional[int]:
    value = (value or "").strip().lower()
    if not value:
        return None
    digits = "".join(ch for ch in value if ch.isdigit())
    if not digits:
        return None
    return int(digits)


def normalize_prefixed_id(value: str, prefix: str, fallback_number: int) -> str:
    raw = (value or "").strip()
    if not raw:
        return f"{prefix}{fallback_number}"
    if re.fullmatch(fr"{prefix}\d+", raw):
        return raw
    if raw.isdigit():
        return f"{prefix}{raw}"
    return raw

def parse_float(value: str) -> Optional[float]:
    value = (value or "").strip().replace(" ", "")
    if not value:
        return None
    if "," in value and "." in value:
        value = value.replace(".", "").replace(",", ".")
    elif "," in value:
        value = value.replace(",", ".")
    try:
        return float(value)
    except ValueError:
        return None


def split_list(value: str) -> List[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(";") if item.strip()]


def validate_row(row: Dict[str, Optional[str]], required_fields: List[str], source: str) -> None:
    if None in row and row[None]:
        extra = ", ".join(str(value) for value in row[None])
        raise ValueError(
            f"{source} has too many columns. Did you forget to quote commas? Extra data: {extra}"
        )
    missing = [field for field in required_fields if row.get(field) is None]
    if missing:
        raise ValueError(f"{source} is missing columns: {', '.join(missing)}")


def load_recipes(path: Path, strings: LocalizedStrings) -> Dict[str, dict]:
    recipes: Dict[str, dict] = {}
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            validate_row(
                row,
                [
                    "recipe_id",
                    "country_code",
                    "category",
                    "name_en",
                    "name_nl",
                    "name_de",
                    "name_fr",
                ],
                "recipes.csv",
            )
            recipe_id = row["recipe_id"].strip()
            if not recipe_id:
                continue
            name_key = f"recipe.{recipe_id}.name"
            info_key = f"recipe.{recipe_id}.info"
            info_summary_key = f"recipe.{recipe_id}.info.summary"
            drink_body_key = f"recipe.{recipe_id}.drink.body"
            drink_summary_key = f"recipe.{recipe_id}.drink.summary"

            for lang in LANGUAGES:
                strings.add(name_key, lang, row.get(f"name_{lang}"))
                strings.add(info_key, lang, row.get(f"info_long_{lang}"))
                strings.add(info_summary_key, lang, row.get(f"info_short_{lang}"))
                strings.add(drink_body_key, lang, row.get(f"wine_long_{lang}"))
                strings.add(drink_summary_key, lang, row.get(f"wine_short_{lang}"))

            recipe = {
                "id": recipe_id,
                "countryCode": row.get("country_code", "").strip(),
                "nameKey": name_key,
                "category": row.get("category", "").strip(),
                "infoKey": info_key,
                "infoSummaryKey": info_summary_key,
                "imageURL": (row.get("recipe_url") or "").strip() or None,
                "approximateMinutes": 0,
                "totalMinutes": 0,
                "totalActiveMinutes": 0,
                "calories": 0,
                "ingredientsCountForList": 0,
                "ingredients": [],
                "tools": [],
                "steps": [],
                "drinkPairingKey": drink_body_key
                if any(row.get(f"wine_long_{lang}") for lang in LANGUAGES)
                else None,
                "drinkPairingSummaryKey": drink_summary_key
                if any(row.get(f"wine_short_{lang}") for lang in LANGUAGES)
                else None,
                "drinkPairingBoldPhraseKeys": [],
                "nutrition": {
                    "energyKcal": 0,
                    "proteinGrams": 0.0,
                    "carbohydratesGrams": 0.0,
                    "sugarsGrams": 0.0,
                    "fatGrams": 0.0,
                    "saturatedFatGrams": 0.0,
                    "sodiumMilligrams": 0.0,
                    "fiberGrams": 0.0,
                },
            }

            recipes[recipe_id] = recipe

    return recipes


def load_groceries(path: Path, recipes: Dict[str, dict], strings: LocalizedStrings) -> None:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            validate_row(
                row,
                [
                    "recipe_id",
                    "ingredient_id",
                    "group_id",
                    "use_order",
                    "aisle",
                    "display_mode",
                    "amount_g",
                    "allow_cup",
                    "pct_in_end_product",
                    "is_invisible",
                    "group_en",
                    "group_nl",
                    "group_de",
                    "group_fr",
                    "name_en",
                    "name_nl",
                    "name_de",
                    "name_fr",
                ],
                "groceries.csv",
            )
            recipe_id = row.get("recipe_id", "").strip()
            if not recipe_id:
                continue
            recipe = recipes.get(recipe_id)
            if not recipe:
                raise ValueError(f"Unknown recipe_id in groceries.csv: {recipe_id}")
            ingredient_id = row.get("ingredient_id", "").strip()
            if not ingredient_id:
                continue
            ingredient_key = f"ingredient.{recipe_id}.{ingredient_id}"
            raw_group_id = row.get("group_id", "").strip()
            group_id = normalize_prefixed_id(raw_group_id, "g", 0)
            group_key = f"grocery.group.{recipe_id}.{group_id}"

            for lang in LANGUAGES:
                strings.add(group_key, lang, row.get(f"group_{lang}"))
            for lang in LANGUAGES:
                strings.add(ingredient_key, lang, row.get(f"name_{lang}"))

            custom_value = None
            custom_label_key = None
            grams_value = parse_float(row.get("amount_g", "")) or 0.0
            display_mode = infer_display_mode(row)
            ounces_value = parse_float(row.get("amount_ounces", ""))
            if ounces_value is None:
                ounces_value = grams_value / GRAMS_PER_OUNCE
            recipe["ingredients"].append({
                "id": ingredient_id,
                "nameKey": ingredient_key,
                "grams": grams_value,
                "ounces": ounces_value,
                "isOptional": False,
                "group": f"{recipe_id}.{group_id}",
                "groupId": group_id,
                "groupSortOrder": parse_sort_index(group_id) or 0,
                "aisle": normalize_aisle(row.get("aisle", "")),
                "useOrder": parse_int(row.get("use_order", "")) or 0,
                "customAmountValue": custom_value or None,
                "customAmountLabelKey": custom_label_key,
                "displayMode": display_mode,
                "gramsPerMl": parse_float(row.get("g_per_ml", "")),
                "gramsPerTsp": parse_float(row.get("g_per_tsp", "")),
                "gramsPerCount": parse_float(row.get("g_per_count", "")),
                "allowCup": parse_bool(row.get("allow_cup", "")),
                "isInvisible": parse_bool(row.get("is_invisible", "")),
            })
            pct_in_end_product = parse_float(row.get("pct_in_end_product", ""))
            nutrition_factor = (pct_in_end_product if pct_in_end_product is not None else 100.0) / 100.0

            recipe["nutrition"]["energyKcal"] += (parse_float(row.get("kcal", "")) or 0.0) * nutrition_factor
            recipe["nutrition"]["proteinGrams"] += (parse_float(row.get("protein", "")) or 0.0) * nutrition_factor
            recipe["nutrition"]["carbohydratesGrams"] += (parse_float(row.get("carbs", "")) or 0.0) * nutrition_factor
            recipe["nutrition"]["sugarsGrams"] += (parse_float(row.get("sugars", "")) or 0.0) * nutrition_factor
            recipe["nutrition"]["fatGrams"] += (parse_float(row.get("fat", "")) or 0.0) * nutrition_factor
            recipe["nutrition"]["saturatedFatGrams"] += (parse_float(row.get("saturated_fat", "")) or 0.0) * nutrition_factor
            recipe["nutrition"]["sodiumMilligrams"] += (parse_float(row.get("sodium", "")) or 0.0) * nutrition_factor
            recipe["nutrition"]["fiberGrams"] += (parse_float(row.get("fiber", "")) or 0.0) * nutrition_factor


def infer_display_mode(row: Dict[str, str]) -> str:
    explicit_mode = (row.get("display_mode") or "").strip()
    if explicit_mode:
        return explicit_mode

    grams_per_count = parse_float(row.get("g_per_count", ""))
    grams_per_ml = parse_float(row.get("g_per_ml", ""))
    grams_per_tsp = parse_float(row.get("g_per_tsp", ""))

    if grams_per_count and grams_per_count > 0:
        return "pcs"
    if (grams_per_ml and grams_per_ml > 0) or (grams_per_tsp and grams_per_tsp > 0):
        return "liquid"
    return "weight"


def load_steps(path: Path, recipes: Dict[str, dict], strings: LocalizedStrings) -> None:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            validate_row(
                row,
                [
                    "recipe_id",
                    "step_id",
                    "step_number",
                    "timer_seconds",
                    "title_en",
                    "body_en",
                    "title_nl",
                    "body_nl",
                    "title_de",
                    "body_de",
                    "title_fr",
                    "body_fr",
                ],
                "steps.csv",
            )
            recipe_id = row.get("recipe_id", "").strip()
            if not recipe_id:
                continue
            recipe = recipes.get(recipe_id)
            if not recipe:
                raise ValueError(f"Unknown recipe_id in steps.csv: {recipe_id}")
            step_number = parse_int(row.get("step_number", ""))
            if not step_number:
                continue
            step_id = row.get("step_id", "").strip() or f"s{step_number}"
            title_key = f"recipe.{recipe_id}.step{step_number}.title"
            body_key = f"recipe.{recipe_id}.step{step_number}.body"

            for lang in LANGUAGES:
                strings.add(title_key, lang, row.get(f"title_{lang}"))
                strings.add(body_key, lang, row.get(f"body_{lang}"))

            is_passive = parse_bool(row.get("is_passive", ""))
            recipe["steps"].append({
                "id": step_id,
                "stepNumber": step_number,
                "titleKey": title_key,
                "bodyKey": body_key,
                "timerSeconds": parse_int(row.get("timer_seconds", "")),
                "isPassive": is_passive,
            })
            step_seconds = parse_int(row.get("timer_seconds", "")) or 0
            recipe["totalMinutes"] += step_seconds // 60
            if not is_passive:
                recipe["totalActiveMinutes"] += step_seconds // 60


def cleanup_nutrition(recipes: Iterable[dict]) -> None:
    for recipe in recipes:
        nutrition = recipe.get("nutrition")
        if not nutrition:
            recipe["nutrition"] = None
            continue
        if all(value in (0, 0.0, None) for value in nutrition.values()):
            recipe["nutrition"] = None
            continue
        nutrition["energyKcal"] = int(round(nutrition.get("energyKcal") or 0))
        recipe["calories"] = nutrition.get("energyKcal") or recipe.get("calories", 0)


def finalize_recipes(recipes: Iterable[dict]) -> None:
    for recipe in recipes:
        unique_ids = {
            ingredient["id"]
            for ingredient in recipe.get("ingredients", [])
            if not ingredient.get("isInvisible", False)
        }
        recipe["ingredientsCountForList"] = len(unique_ids)
        recipe["tools"] = sorted(
            recipe.get("tools", []),
            key=lambda tool: (parse_sort_index(tool.get("id", "")) is None, parse_sort_index(tool.get("id", "")) or 0),
        )
        if recipe.get("approximateMinutes", 0) == 0:
            recipe["approximateMinutes"] = recipe.get("totalMinutes", 0)


def normalize_aisle(value: str) -> str:
    normalized = value.strip()
    if normalized in {
        "vegetables",
        "aromatics",
        "meat",
        "canned",
        "dairy",
        "pantry",
        "spices",
        "other",
    }:
        return normalized
    return "other"


def load_tools(path: Path, recipes: Dict[str, dict], strings: LocalizedStrings) -> None:
    if not path.exists():
        return
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            validate_row(
                row,
                [
                    "recipe_id",
                    "tool_id",
                    "is_optional",
                    "name_en",
                    "name_nl",
                    "name_de",
                    "name_fr",
                    "optional_label_en",
                    "optional_label_nl",
                    "optional_label_de",
                    "optional_label_fr",
                ],
                "tools.csv",
            )
            recipe_id = row.get("recipe_id", "").strip()
            if not recipe_id:
                continue
            recipe = recipes.get(recipe_id)
            if not recipe:
                raise ValueError(f"Unknown recipe_id in tools.csv: {recipe_id}")
            tool_id = normalize_prefixed_id(row.get("tool_id", ""), "t", len(recipe["tools"]) + 1)
            is_optional = parse_bool(row.get("is_optional", ""))
            tool_key = f"recipe.{recipe_id}.tool.{tool_id}"
            optional_key = f"recipe.{recipe_id}.tool.{tool_id}.optional"
            for lang in LANGUAGES:
                strings.add(tool_key, lang, row.get(f"name_{lang}"))
                strings.add(optional_key, lang, row.get(f"optional_label_{lang}"))
            recipe["tools"].append({
                "id": tool_id,
                "nameKey": tool_key,
                "isOptional": is_optional,
                "optionalLabelKey": optional_key if any(row.get(f"optional_label_{lang}") for lang in LANGUAGES) else None,
            })


def main() -> None:
    strings = LocalizedStrings()
    recipes = load_recipes(DEFAULT_RECIPES, strings)
    load_groceries(DEFAULT_GROCERIES, recipes, strings)
    load_steps(DEFAULT_STEPS, recipes, strings)
    load_tools(DEFAULT_TOOLS, recipes, strings)
    cleanup_nutrition(recipes.values())
    finalize_recipes(recipes.values())

    APP_DIR.mkdir(parents=True, exist_ok=True)
    with RECIPES_JSON_PATH.open("w", encoding="utf-8") as handle:
        json.dump(list(recipes.values()), handle, ensure_ascii=False, indent=2)

    strings.write(LOCALIZATION_DIR)

    print(f"Wrote {RECIPES_JSON_PATH}")


if __name__ == "__main__":
    main()
