//
//  RecipeDetailView.swift
//  FamousChef
//

import SwiftUI
import Combine

struct RecipeDetailView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }
    @State private var isInfoExpanded: Bool = true
    @State private var isStepsExpanded: Bool = true
    @State private var servings: Int = 4

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                NutritionCard(recipe: recipe)

                DrinkPairingCard(recipe: recipe)

                KitchenToolsCard(recipe: recipe)

                GroceryListCard(recipe: recipe, servings: $servings)

                stepsCard
            }
            .padding(12)
        }
        .background(AppTheme.pageBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                let title = AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)
                Text("\(FlagEmoji.from(countryCode: recipe.countryCode)) \(title)")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                    .accessibilityLabel(Text("\(FlagEmoji.from(countryCode: recipe.countryCode)) \(title)"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    recipeStore.toggleFavorite(recipe)
                } label: {
                    Image(systemName: recipeStore.isFavorite(recipe) ? "heart.fill" : "heart")
                        .foregroundStyle(recipeStore.isFavorite(recipe) ? .red : AppTheme.primaryBlue)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut) {
                    isInfoExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "mappin")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.infoTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text(AppLanguage.string(String.LocalizationValue(recipe.infoSummaryKey), locale: locale))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))

                    Image(systemName: isInfoExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 24, height: 24, alignment: .center)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(Text(isInfoExpanded ? "Collapse info" : "Expand info"))

            if isInfoExpanded {
                Divider()
                    .overlay(AppTheme.hairline)
                    .transition(.opacity)

                Text(AppLanguage.string(String.LocalizationValue(recipe.infoKey), locale: locale))
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isInfoExpanded)
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private var stepsCard: some View {
        let format = AppLanguage.string("recipe.steps.summary", locale: locale)
        let summary = String(format: format, locale: locale, recipe.approximateMinutes)
        return VStack(alignment: .leading, spacing: 9) {
            Button {
                withAnimation(.easeInOut) {
                    isStepsExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.stepsTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))

                    Image(systemName: isStepsExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 24, height: 24, alignment: .center)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(Text(isStepsExpanded ? "Collapse steps" : "Expand steps"))

            if isStepsExpanded {
                Divider()
                    .overlay(AppTheme.hairline)

                ForEach(recipe.steps) { step in
                    StepRowView(step: step, ingredients: recipe.ingredients)
                    if step.id != recipe.steps.last?.id {
                        Divider().overlay(AppTheme.hairline)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isStepsExpanded)
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct StepRowView: View {
    let step: RecipeStep
    let ingredients: [Ingredient]

    @State private var showTimer: Bool = false
    @State private var isRunning: Bool = false
    @State private var secondsLeft: Int
    @State private var sessionInitialSeconds: Int
    @State private var baseInitialSeconds: Int
    @State private var didRing: Bool = false
    @State private var beepTaskRunning: Bool = false
    @State private var startDate: Date? = nil
    @State private var startSeconds: Int
    @State private var startToken: UUID = UUID()

    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }
    @Environment(\.scenePhase) private var scenePhase

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(step: RecipeStep, ingredients: [Ingredient]) {
        self.step = step
        self.ingredients = ingredients
        let initial = step.timerSeconds ?? 0
        _secondsLeft = State(initialValue: initial)
        _sessionInitialSeconds = State(initialValue: initial)
        _baseInitialSeconds = State(initialValue: initial)
        _startSeconds = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(step.stepNumber). ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primaryBlue)
                Text(AppLanguage.string(String.LocalizationValue(step.titleKey), locale: locale))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if step.timerSeconds != nil {
                    TimerBadgeView(
                        displayText: timerDisplayText,
                        isRunning: isRunning,
                        isOverdue: secondsLeft < 0
                    ) {
                        handleTimerTap()
                    }
                    .sheet(isPresented: $showTimer) {
                        CountdownTimerView(
                            initialSeconds: sessionInitialSeconds,
                            liveSeconds: secondsLeft,
                            isRunning: isRunning,
                            onReset: { resetTimer(to: sessionInitialSeconds) },
                            onPauseToggle: { toggleRun() },
                            onOverride: { overrideSeconds in
                                applyOverride(overrideSeconds)
                            }
                        )
                    }
                }
            }

            let raw = AppLanguage.string(String.LocalizationValue(step.bodyKey), locale: locale)
            Text(AttributedString.boldIngredients(
                in: raw,
                ingredientKeys: ingredients.map { $0.nameKey },
                locale: locale
            ))
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
        }
        .padding(.vertical, 1.5)
        .onReceive(tick) { _ in
            updateRemainingFromEndDate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                updateRemainingFromEndDate()
            }
        }
    }

    private var timerDisplayText: String {
        if !isRunning, secondsLeft == sessionInitialSeconds {
            let m = sessionInitialSeconds / 60
            return "\(m)m"
        }
        return timeText
    }

    private var timeText: String {
        if secondsLeft >= 0 {
            let m = secondsLeft / 60
            let s = secondsLeft % 60
            return String(format: "%d:%02d", m, s)
        } else {
            let over = abs(secondsLeft)
            let m = over / 60
            let s = over % 60
            return String(format: "-%d:%02d", m, s)
        }
    }

    private func handleTimerTap() {
        if isRunning {
            if secondsLeft > 0 {
                showTimer = true
            } else {
                resetTimer(to: baseInitialSeconds)
            }
            return
        }

        if secondsLeft <= 0 {
            resetTimer(to: baseInitialSeconds)
        } else {
            toggleRun()
        }
    }

    private func toggleRun() {
        if isRunning {
            updateRemainingFromEndDate()
            isRunning = false
            startDate = nil
            startToken = UUID()
        } else {
            let now = Date()
            startDate = now
            startSeconds = secondsLeft
            let token = UUID()
            startToken = token
            isRunning = true
            Haptics.light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard isRunning, startToken == token else { return }
                updateRemainingFromEndDate()
            }
        }
    }

    private func resetTimer(to seconds: Int) {
        isRunning = false
        sessionInitialSeconds = seconds
        secondsLeft = seconds
        didRing = false
        startDate = nil
        startSeconds = seconds
        startToken = UUID()
        Haptics.light()
    }

    private func applyOverride(_ overrideSeconds: Int) {
        sessionInitialSeconds = overrideSeconds
        secondsLeft = overrideSeconds
        didRing = false
        if isRunning {
            let now = Date()
            startDate = now
            startSeconds = overrideSeconds
            let token = UUID()
            startToken = token
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard isRunning, startToken == token else { return }
                updateRemainingFromEndDate()
            }
        } else {
            startDate = nil
            startSeconds = overrideSeconds
            startToken = UUID()
        }
        Haptics.light()
    }

    private func ringForThreeSeconds() {
        guard !beepTaskRunning else { return }
        beepTaskRunning = true
        Haptics.success()

        SoundPlayer.playBeepBurst(durationSeconds: 3.0) {
            beepTaskRunning = false
        }
    }

    private func updateRemainingFromEndDate() {
        guard isRunning, let startDate else { return }
        let elapsed = Int(Date().timeIntervalSince(startDate).rounded(.down))
        let remaining = startSeconds - elapsed
        if remaining != secondsLeft {
            secondsLeft = remaining
        }
        if remaining <= 0 && !didRing {
            didRing = true
            ringForThreeSeconds()
        }
    }
}
