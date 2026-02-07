#!/usr/bin/env python3
"""Convert recipe CSVs into app-ready JSON and Localizable.strings.

Inputs (default):
  recipe_import/recipes.csv
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

LANGUAGES = ["nl", "en", "de"]
LOCALIZATION_MARKER = "// === AUTO-GENERATED RECIPES BELOW ==="


@dataclass
class LocalizedStrings:
    values: Dict[str, Dict[str, str]]

    def __init__(self) -> None:
        self.values = {lang: {} for lang in LANGUAGES}

    def add(self, key: str, lang: str, value: Optional[str]) -> None:
        if not value:
            return
        self.values[lang][key] = value

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


def parse_int(value: str) -> Optional[int]:
    value = value.strip()
    if not value:
        return None
    return int(value)


def parse_float(value: str) -> Optional[float]:
    value = (value or "").strip()
    if not value:
        return None
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
                    "group",
                    "group_id",
                    "aisle",
                    "amount_grams",
                    "use_order",
                    "name_nl",
                    "name_en",
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
            ingredient_key = f"ingredient.{ingredient_id}"
            for lang in LANGUAGES:
                strings.add(ingredient_key, lang, row.get(f"name_{lang}"))

            custom_value = (row.get("amount_custom_value") or "").strip()
            custom_label_key = None
            custom_labels = {
                "nl": (row.get("amount_custom_label_nl") or "").strip(),
                "en": (row.get("amount_custom_label_en") or "").strip(),
                "de": (row.get("amount_custom_label_de") or "").strip(),
            }
            if any(custom_labels.values()):
                custom_label_key = f"ingredient.{ingredient_id}.amount.custom"
                for lang, label in custom_labels.items():
                    if label:
                        strings.add(custom_label_key, lang, label)
            recipe["ingredients"].append({
                "id": ingredient_id,
                "nameKey": ingredient_key,
                "grams": parse_float(row.get("amount_grams", "")) or 0.0,
                "ounces": (
                    parse_float(row.get("amount_ounces", ""))
                    or parse_float(row.get("amount_grams", ""))
                    or 0.0
                ),
                "isOptional": False,
                "group": row.get("group", "").strip(),
                "groupId": parse_int(row.get("group_id", "")),
                "aisle": normalize_aisle(row.get("aisle", "")),
                "useOrder": parse_int(row.get("use_order", "")) or 0,
                "customAmountValue": custom_value or None,
                "customAmountLabelKey": custom_label_key,
            })
            recipe["nutrition"]["energyKcal"] += parse_int(row.get("kcal", "")) or 0
            recipe["nutrition"]["proteinGrams"] += parse_float(row.get("protein", "")) or 0.0
            recipe["nutrition"]["carbohydratesGrams"] += parse_float(row.get("carbs", "")) or 0.0
            recipe["nutrition"]["sugarsGrams"] += parse_float(row.get("sugars", "")) or 0.0
            recipe["nutrition"]["fatGrams"] += parse_float(row.get("fat", "")) or 0.0
            recipe["nutrition"]["saturatedFatGrams"] += parse_float(row.get("saturated_fat", "")) or 0.0
            recipe["nutrition"]["sodiumMilligrams"] += parse_float(row.get("sodium", "")) or 0.0
            recipe["nutrition"]["fiberGrams"] += parse_float(row.get("fiber", "")) or 0.0


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
                    "title_nl",
                    "body_nl",
                    "title_en",
                    "body_en",
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
        recipe["calories"] = nutrition.get("energyKcal") or recipe.get("calories", 0)


def finalize_recipes(recipes: Iterable[dict]) -> None:
    for recipe in recipes:
        unique_ids = {ingredient["id"] for ingredient in recipe.get("ingredients", [])}
        recipe["ingredientsCountForList"] = len(unique_ids)
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
                    "name_nl",
                    "name_en",
                ],
                "tools.csv",
            )
            recipe_id = row.get("recipe_id", "").strip()
            if not recipe_id:
                continue
            recipe = recipes.get(recipe_id)
            if not recipe:
                raise ValueError(f"Unknown recipe_id in tools.csv: {recipe_id}")
            tool_id = row.get("tool_id", "").strip()
            if not tool_id:
                continue
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
