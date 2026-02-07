# Recipe CSV Import

This folder contains CSV templates and a conversion script that turn your recipe data into:

- `recipes.json` (language-neutral data for the app model)
- `Localizable.strings` (per-language text)

## Files

- `recipes.csv` — core recipe metadata + localized text (name/info/drink)
- `groceries.csv` — ingredients + nutrition columns per ingredient + localized ingredient names
- `steps.csv` — step data + localized titles/bodies
- `tools.csv` — tool rows per recipe + localized tool names
- `csv_to_app_data.py` — converter that builds JSON + localized strings

## Usage

```bash
python3 recipe_import/csv_to_app_data.py
```

Outputs overwrite the app bundle directly:

- `Traditional Chef/Traditional Chef/recipes.json`
- `Traditional Chef/Traditional Chef/<lang>.lproj/Localizable.strings`

## Notes

- The generated keys follow the same pattern as the current app:
  - `recipe.<id>.name`
  - `recipe.<id>.info` / `.info.summary`
  - `recipe.<id>.step<step>.title` / `.body`
  - `recipe.<id>.tool.<tool_id>`
  - `ingredient.<ingredient_id>`

- `drink_bold_phrase_keys` is a semicolon-separated list of existing localization keys (e.g., `recipe.drink.redWine`).
- Category values must match the app enum: `starter`, `main`, `dessert`.
- Aisle values must match the app enum: `vegetables`, `aromatics`, `meat`, `canned`, `dairy`, `pantry`, `spices`, `other`. Unknown values are treated as `other`.
- Group values are recipe-specific and can be any component name.
- Translation columns are grouped per language (all `nl` columns together, then `en`, then `de`) so new languages can be appended easily.
- Nutrition totals are calculated by summing the per-ingredient nutrition columns in `groceries.csv` (the `recipes.csv` sheet no longer carries nutrition fields). Total minutes and active minutes are calculated from `steps.csv`, and ingredient counts are derived from unique grocery items.
- Custom amounts for groceries can be stored using `amount_custom_value` plus per-language labels (e.g., `tbsp`, `leaf`, `grams`). `amount_ounces` is recorded separately and defaults to the gram value if left blank.
- Tools can include optional-label translations via `optional_label_{lang}` columns (only needed when `is_optional` is true).
- The script preserves any existing localization keys above the `// === AUTO-GENERATED RECIPES BELOW ===` marker and rewrites everything after it.
- If any text includes commas, wrap the field in double quotes so columns stay aligned (e.g., `"Traditioneel, zoals Sangiovese"`). The importer will error if a row has extra columns.
- `groceries.csv` supports an optional `group_id` integer to control the display order of ingredient groups (lower numbers come first).
