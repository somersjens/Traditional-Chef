//
//  RecipeDetailView.swift
//  FamousChef
//

import SwiftUI
import Combine
import ImageIO
import UIKit

struct RecipeDetailView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @AppStorage("defaultServings") private var defaultServings: Int = 4
    private var locale: Locale { Locale(identifier: appLanguage) }
    @State private var isInfoExpanded: Bool = true
    @State private var isStepsExpanded: Bool = true
    @State private var servings: Int = 4
    @State private var stepTimerSnapshots: [String: StepTimerSnapshot] = [:]
    @State private var heroUIImage: UIImage?
    @State private var heroImageFailed = false
    @State private var heroTargetPixelSize: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                let heroSize = proxy.size.width
                let heroPixelSize = heroSize * displayScale
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        heroSection(height: heroSize + proxy.safeAreaInsets.top, targetPixelSize: heroPixelSize)
                            .padding(.top, -proxy.safeAreaInsets.top)

                        VStack(alignment: .leading, spacing: 14) {
                            header

                            NutritionCard(recipe: recipe)

                            DrinkPairingCard(recipe: recipe)

                            KitchenToolsCard(recipe: recipe)

                            GroceryListCard(recipe: recipe, servings: $servings)

                            stepsCard
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.bottom, 12)
                }
                .ignoresSafeArea(edges: .top)
            }

            detailTopBar
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .zIndex(3)
        }
        .background(AppTheme.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            servings = defaultServings
        }
    }

    private var detailTopBar: some View {
        return HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.pageBackground)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Back"))

            Spacer()

            Button {
                recipeStore.toggleFavorite(recipe)
            } label: {
                Image(systemName: recipeStore.isFavorite(recipe) ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .scaleEffect(1.2)
                    .offset(x: -6)
                    .foregroundStyle(recipeStore.isFavorite(recipe) ? .red : AppTheme.pageBackground)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Favorite"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func heroSection(height: CGFloat, targetPixelSize: CGFloat) -> some View {
        heroImage(targetPixelSize: targetPixelSize)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay(imageFadeOverlay)
            .overlay(alignment: .bottomLeading) {
                titleOverlay
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
            }
            .clipped()
            .background(AppTheme.secondaryOffWhite)
            .ignoresSafeArea(edges: .top)
    }

    private var imageFadeOverlay: some View {
        LinearGradient(
            colors: [
                AppTheme.pageBackground.opacity(0.0),
                AppTheme.pageBackground.opacity(0.35)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleOverlay: some View {
        let title = AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)
        return HStack(spacing: 6) {
            Text("\(FlagEmoji.from(countryCode: recipe.countryCode))")
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppTheme.cardBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private func heroImage(targetPixelSize: CGFloat) -> some View {
        ZStack {
            if let image = heroUIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                heroPlaceholder
            }
        }
        .accessibilityLabel(Text("Recipe image"))
        .task {
            RecipeImagePrefetcher.prefetch(urlString: recipe.imageURL)
            await loadHeroImage(targetPixelSize: targetPixelSize)
        }
    }

    private var heroPlaceholder: some View {
        ZStack {
            AppTheme.secondaryOffWhite
            Image(systemName: "photo")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.35))
        }
    }

    private var heroImageURL: URL? {
        guard let imageURL = recipe.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !imageURL.isEmpty
        else {
            return nil
        }
        return URL(string: imageURL)
    }

    @MainActor
    private func loadHeroImage(targetPixelSize: CGFloat) async {
        guard heroUIImage == nil, !heroImageFailed, let url = heroImageURL else {
            return
        }

        let targetPixelSize = max(targetPixelSize, 1)
        if heroTargetPixelSize == targetPixelSize {
            return
        }

        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 30
        )

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                heroImageFailed = true
                return
            }

            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: targetPixelSize
            ]

            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                heroUIImage = UIImage(cgImage: cgImage, scale: displayScale, orientation: .up)
                heroTargetPixelSize = targetPixelSize
            } else {
                heroImageFailed = true
            }
        } catch {
            heroImageFailed = true
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
        let headerText = stepsHeaderText(summary: summary)
        return VStack(alignment: .leading, spacing: 9) {
            Button {
                withAnimation(.easeInOut) {
                    isStepsExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "frying.pan")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.stepsTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text(headerText)
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

            VStack(spacing: 9) {
                Divider()
                    .overlay(AppTheme.hairline)

                ForEach(recipe.steps) { step in
                    StepRowView(
                        step: step,
                        ingredients: recipe.ingredients,
                        onTimerUpdate: { snapshot in
                            stepTimerSnapshots[snapshot.id] = snapshot
                        }
                    )
                    if step.id != recipe.steps.last?.id {
                        Divider().overlay(AppTheme.hairline)
                    }
                }
            }
            .opacity(isStepsExpanded ? 1 : 0)
            .frame(maxHeight: isStepsExpanded ? .infinity : 0)
            .clipped()
            .accessibilityHidden(!isStepsExpanded)
        }
        .animation(.easeInOut(duration: 0.25), value: isStepsExpanded)
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private func stepsHeaderText(summary: String) -> String {
        guard !isStepsExpanded,
              let shortestRunning = stepTimerSnapshots.values
                .filter({ $0.isRunning })
                .map(\.secondsLeft)
                .min()
        else {
            return summary
        }
        return formatTimerText(seconds: shortestRunning)
    }

    private func formatTimerText(seconds: Int) -> String {
        if seconds >= 0 {
            let m = seconds / 60
            let s = seconds % 60
            return String(format: "%d:%02d", m, s)
        } else {
            let over = abs(seconds)
            let m = over / 60
            let s = over % 60
            return String(format: "-%d:%02d", m, s)
        }
    }
}

private struct StepTimerSnapshot {
    let id: String
    let isRunning: Bool
    let secondsLeft: Int
    let sessionInitialSeconds: Int
}

private struct StepRowView: View {
    let step: RecipeStep
    let ingredients: [Ingredient]
    let onTimerUpdate: (StepTimerSnapshot) -> Void

    @State private var showTimer: Bool = false
    @State private var isRunning: Bool = false
    @State private var secondsLeft: Int
    @State private var sessionInitialSeconds: Int
    @State private var baseInitialSeconds: Int
    @State private var didRing: Bool = false
    @State private var beepTaskRunning: Bool = false
    @State private var continuousBeepID: UUID? = nil
    @State private var startDate: Date? = nil
    @State private var startSeconds: Int
    @State private var startToken: UUID = UUID()

    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @AppStorage("timerAutoStop") private var timerAutoStop: Bool = true
    private var locale: Locale { Locale(identifier: appLanguage) }
    @Environment(\.scenePhase) private var scenePhase

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(step: RecipeStep, ingredients: [Ingredient], onTimerUpdate: @escaping (StepTimerSnapshot) -> Void) {
        self.step = step
        self.ingredients = ingredients
        self.onTimerUpdate = onTimerUpdate
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
        .onAppear {
            notifyTimerUpdate()
        }
        .onChange(of: isRunning) { _, _ in
            notifyTimerUpdate()
        }
        .onChange(of: secondsLeft) { _, _ in
            notifyTimerUpdate()
        }
        .onChange(of: sessionInitialSeconds) { _, _ in
            notifyTimerUpdate()
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
            stopContinuousBeep()
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
        stopContinuousBeep()
        startDate = nil
        startSeconds = seconds
        startToken = UUID()
        Haptics.light()
    }

    private func applyOverride(_ overrideSeconds: Int) {
        sessionInitialSeconds = overrideSeconds
        secondsLeft = overrideSeconds
        didRing = false
        stopContinuousBeep()
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

    private func startContinuousBeep() {
        guard continuousBeepID == nil else { return }
        Haptics.success()
        continuousBeepID = SoundPlayer.startContinuousBeep()
    }

    private func stopContinuousBeep() {
        SoundPlayer.stopBeep(id: continuousBeepID)
        continuousBeepID = nil
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
            if timerAutoStop {
                ringForThreeSeconds()
            } else {
                startContinuousBeep()
            }
        }
    }

    private func notifyTimerUpdate() {
        onTimerUpdate(StepTimerSnapshot(
            id: step.id,
            isRunning: isRunning,
            secondsLeft: secondsLeft,
            sessionInitialSeconds: sessionInitialSeconds
        ))
    }
}
