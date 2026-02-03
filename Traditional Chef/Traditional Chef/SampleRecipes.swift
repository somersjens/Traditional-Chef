//
//  SampleRecipes.swift
//  FamousChef
//

import Foundation

enum SampleRecipes {
    static let all: [Recipe] = [
        pastaBolognese
    ]

    static let pastaBolognese = Recipe(
        id: "it_pasta_bolognese",
        countryCode: "IT",
        nameKey: "recipe.it.bolognese.name",
        category: .main,
        infoKey: "recipe.it.bolognese.info",
        infoSummaryKey: "recipe.it.bolognese.info.summary",
        approximateMinutes: 90,
        calories: 635,
        ingredientsCountForList: 10,
        ingredients: [
            Ingredient(id: "pasta", nameKey: "ingredient.pasta", grams: 400, isOptional: false, aisle: .pantry, useOrder: 7),
            Ingredient(id: "minced_meat", nameKey: "ingredient.minced_meat", grams: 500, isOptional: false, aisle: .meat, useOrder: 3),
            Ingredient(id: "onion", nameKey: "ingredient.onion", grams: 150, isOptional: false, aisle: .vegetables, useOrder: 1),
            Ingredient(id: "carrot", nameKey: "ingredient.carrot", grams: 150, isOptional: false, aisle: .vegetables, useOrder: 1),
            Ingredient(id: "celery", nameKey: "ingredient.celery", grams: 100, isOptional: false, aisle: .vegetables, useOrder: 1),
            Ingredient(id: "garlic", nameKey: "ingredient.garlic_optional", grams: 6, isOptional: true, aisle: .aromatics, useOrder: 1),

            Ingredient(id: "tomatoes", nameKey: "ingredient.canned_tomatoes", grams: 800, isOptional: false, aisle: .canned, useOrder: 6),
            Ingredient(id: "tomato_paste", nameKey: "ingredient.tomato_paste", grams: 33, isOptional: false, aisle: .canned, useOrder: 4),
            Ingredient(id: "stock", nameKey: "ingredient.beef_stock", grams: 250, isOptional: false, aisle: .pantry, useOrder: 6),
            Ingredient(id: "red_wine", nameKey: "ingredient.red_wine_optional", grams: 150, isOptional: true, aisle: .pantry, useOrder: 5),

            Ingredient(id: "olive_oil", nameKey: "ingredient.olive_oil", grams: 27, isOptional: false, aisle: .pantry, useOrder: 2),
            Ingredient(id: "bay_leaf", nameKey: "ingredient.bay_leaf", grams: 0.2, isOptional: false, aisle: .spices, useOrder: 6),
            Ingredient(id: "oregano", nameKey: "ingredient.oregano", grams: 1, isOptional: false, aisle: .spices, useOrder: 6),
            Ingredient(id: "salt", nameKey: "ingredient.salt_total", grams: 38, isOptional: false, aisle: .spices, useOrder: 6),
            Ingredient(id: "pepper", nameKey: "ingredient.black_pepper", grams: 2, isOptional: false, aisle: .spices, useOrder: 6),

            Ingredient(id: "butter", nameKey: "ingredient.butter_optional", grams: 14, isOptional: true, aisle: .dairy, useOrder: 8),
            Ingredient(id: "parmesan", nameKey: "ingredient.parmesan_to_serve", grams: 60, isOptional: false, aisle: .dairy, useOrder: 8),
        ],
        tools: [
            RecipeTool(id: "large_pot", nameKey: "recipe.it.bolognese.tool.large_pot", isOptional: false),
            RecipeTool(id: "pasta_pot", nameKey: "recipe.it.bolognese.tool.pasta_pot", isOptional: false),
            RecipeTool(id: "wooden_spoon", nameKey: "recipe.it.bolognese.tool.wooden_spoon", isOptional: false),
            RecipeTool(id: "cutting_board", nameKey: "recipe.it.bolognese.tool.cutting_board", isOptional: false),
            RecipeTool(id: "sharp_knife", nameKey: "recipe.it.bolognese.tool.sharp_knife", isOptional: false),
            RecipeTool(id: "colander", nameKey: "recipe.it.bolognese.tool.colander", isOptional: false),
            RecipeTool(id: "measuring_cup", nameKey: "recipe.it.bolognese.tool.measuring_cup", isOptional: false),
            RecipeTool(id: "cheese_grater", nameKey: "recipe.it.bolognese.tool.cheese_grater", isOptional: true),
        ],
        steps: [
            RecipeStep(
                id: "s1", stepNumber: 1,
                titleKey: "recipe.it.bolognese.step1.title",
                bodyKey: "recipe.it.bolognese.step1.body",
                timerSeconds: 10 * 60
            ),
            RecipeStep(
                id: "s2", stepNumber: 2,
                titleKey: "recipe.it.bolognese.step2.title",
                bodyKey: "recipe.it.bolognese.step2.body",
                timerSeconds: 8 * 60
            ),
            RecipeStep(
                id: "s3", stepNumber: 3,
                titleKey: "recipe.it.bolognese.step3.title",
                bodyKey: "recipe.it.bolognese.step3.body",
                timerSeconds: 8 * 60
            ),
            RecipeStep(
                id: "s4", stepNumber: 4,
                titleKey: "recipe.it.bolognese.step4.title",
                bodyKey: "recipe.it.bolognese.step4.body",
                timerSeconds: 2 * 60
            ),
            RecipeStep(
                id: "s5", stepNumber: 5,
                titleKey: "recipe.it.bolognese.step5.title",
                bodyKey: "recipe.it.bolognese.step5.body",
                timerSeconds: 3 * 60
            ),
            RecipeStep(
                id: "s6", stepNumber: 6,
                titleKey: "recipe.it.bolognese.step6.title",
                bodyKey: "recipe.it.bolognese.step6.body",
                timerSeconds: 45 * 60
            ),
            RecipeStep(
                id: "s7", stepNumber: 7,
                titleKey: "recipe.it.bolognese.step7.title",
                bodyKey: "recipe.it.bolognese.step7.body",
                // 10–12 min: we default to 10; you can later let users choose
                timerSeconds: 10 * 60
            ),
            RecipeStep(
                id: "s8", stepNumber: 8,
                titleKey: "recipe.it.bolognese.step8.title",
                bodyKey: "recipe.it.bolognese.step8.body",
                timerSeconds: 2 * 60
            ),
        ],
        drinkPairingKey: "recipe.it.bolognese.drink.body",
        drinkPairingSummaryKey: "recipe.it.bolognese.drink.summary",
        drinkPairingBoldPhraseKeys: ["recipe.drink.redWine"],
        nutrition: RecipeNutrition(
            energyKcal: 635,
            proteinGrams: 23,
            carbohydratesGrams: 66,
            sugarsGrams: 7,
            fatGrams: 28,
            saturatedFatGrams: 4,
            sodiumMilligrams: 760,
            fiberGrams: 15
        )
    )
}
