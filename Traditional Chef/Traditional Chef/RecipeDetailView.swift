//
//  RecipeDetailView.swift
//  FamousChef
//

import SwiftUI
import Combine
import ImageIO
import UIKit
import AVFoundation

struct RecipeDetailView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.openURL) private var openURL
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
    @State private var isTopBarHidden = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isHeroImageDark: Bool = false
    @State private var highlightFooterLinks = false
    @State private var selectedStepID: String? = nil
    @StateObject private var stepSpeaker = StepSpeaker()
    @StateObject private var cardSpeaker = CardReadAloudSpeaker()
    private let footerLinksID = "footerLinksID"

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height
                let heroSize = proxy.size.width
                let heroHeight = isLandscape ? proxy.size.height * 0.45 : heroSize
                let heroPixelSize = max(heroSize, heroHeight) * displayScale
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        heroSection(
                            height: heroHeight,
                            width: proxy.size.width,
                            safeAreaInsets: proxy.safeAreaInsets,
                            targetPixelSize: heroPixelSize,
                            isLandscape: isLandscape
                        )

                        VStack(alignment: .leading, spacing: 14) {
                            header

                            NutritionCard(recipe: recipe)

                            DrinkPairingCard(recipe: recipe)

                            KitchenToolsCard(recipe: recipe)

                            GroceryListCard(recipe: recipe, servings: $servings)

                            stepsCard

                            footerLinks
                        }
                        .padding(.leading, 12 + proxy.safeAreaInsets.leading)
                        .padding(.trailing, 12 + proxy.safeAreaInsets.trailing)
                    }
                    .padding(.bottom, 12)
                    .background(ScrollOffsetReader(offset: $scrollOffset).frame(height: 0))
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .ignoresSafeArea(edges: .top)
                .onChange(of: scrollOffset) { _, offset in
                    let shouldHide = offset > (heroHeight * 0.5)
                    if shouldHide != isTopBarHidden {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTopBarHidden = shouldHide
                        }
                    }
                }
            }

            detailTopBar
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .zIndex(3)
                .opacity(isTopBarHidden ? 0 : 1)
                .allowsHitTesting(!isTopBarHidden)
        }
        .background(AppTheme.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            servings = defaultServings
        }
    }

    private var detailTopBar: some View {
        let iconColor = isHeroImageDark ? AppTheme.pageBackground : AppTheme.primaryBlue
        let iconScale: CGFloat = 1.2
        let baseIconSize: CGFloat = 17
        let heartIconSize: CGFloat = 18
        let iconSpacing: CGFloat = 12
        return HStack(spacing: iconSpacing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: baseIconSize * iconScale, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AppLanguage.string("recipe.detail.back", locale: locale)))

            Spacer()

            Button {
                recipeStore.toggleFavorite(recipe)
            } label: {
                Image(systemName: recipeStore.isFavorite(recipe) ? "heart.fill" : "heart")
                    .font(.system(size: heartIconSize * iconScale, weight: .semibold))
                    .offset(x: -6)
                    .foregroundStyle(recipeStore.isFavorite(recipe) ? .red : iconColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AppLanguage.string("recipe.detail.favorite", locale: locale)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var shareRecipeURL: URL {
        URL(string: "https://traditionalchef.app/recipes/\(recipe.id)") ?? URL(string: "https://traditionalchef.app")!
    }

    private var shareRecipeTitle: String {
        AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)
    }

    private var shareRecipeMessage: String {
        AppLanguage.string("recipe.detail.shareText", locale: locale)
    }

    private var appStoreID: String {
        "0000000000"
    }

    private var appStoreProductURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }

    private var appStoreReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }

    private var feedbackMailURL: URL {
        URL(string: "mailto:hello@traditionalchef.app")!
    }

    private func heroSection(
        height: CGFloat,
        width: CGFloat,
        safeAreaInsets: EdgeInsets,
        targetPixelSize: CGFloat,
        isLandscape: Bool
    ) -> some View {
        let horizontalInset = safeAreaInsets.leading + safeAreaInsets.trailing
        return heroImage(targetPixelSize: targetPixelSize, isLandscape: isLandscape)
            .frame(height: height)
            .frame(width: width + horizontalInset)
            .padding(.leading, -safeAreaInsets.leading)
            .padding(.trailing, -safeAreaInsets.trailing)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                imageFadeOverlay
            }
            .overlay(alignment: .bottomLeading) {
                let contentLeadingPadding = 12 + safeAreaInsets.leading
                let titleLeadingPadding = contentLeadingPadding + (isLandscape ? safeAreaInsets.leading : 0)
                titleOverlay
                    .padding(.leading, titleLeadingPadding)
                    .padding(.bottom, 16)
            }
            .clipped()
            .background(AppTheme.secondaryOffWhite)
            .ignoresSafeArea(edges: isLandscape ? [.top, .horizontal] : .top)
    }

    private var imageFadeOverlay: some View {
        LinearGradient(
            colors: [
                AppTheme.pageBackground.opacity(0.0),
                AppTheme.pageBackground.opacity(0.12)
            ],
            startPoint: .center,
            endPoint: .bottom
        )
        .frame(height: 140)
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
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private func heroImage(targetPixelSize: CGFloat, isLandscape: Bool) -> some View {
        ZStack {
            if let image = heroUIImage {
                if isLandscape {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            } else {
                heroPlaceholder
            }
        }
        .accessibilityLabel(Text(AppLanguage.string("recipe.detail.image", locale: locale)))
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
                isHeroImageDark = isImageDark(cgImage)
            } else {
                heroImageFailed = true
            }
        } catch {
            heroImageFailed = true
        }
    }

    private func isImageDark(_ image: CGImage) -> Bool {
        let width = 1
        let height = 1
        let bytesPerPixel = 4
        var pixelData = [UInt8](repeating: 0, count: bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerPixel * width,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return false
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let red = CGFloat(pixelData[0]) / 255
        let green = CGFloat(pixelData[1]) / 255
        let blue = CGFloat(pixelData[2]) / 255
        let luminance = (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
        return luminance < 0.5
    }

    private var header: some View {
        let headerIconWidth: CGFloat = 24
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Button {
                    if isInfoExpanded {
                        cardSpeaker.toggleRead(
                            text: AppLanguage.string(String.LocalizationValue(recipe.infoKey), locale: locale),
                            languageCode: locale.identifier
                        )
                    } else {
                        withAnimation(.easeInOut) {
                            isInfoExpanded = true
                        }
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: headerIconWidth, alignment: .center)

                    Text(AppLanguage.string("recipe.infoTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(
                        AppLanguage.string(
                            isInfoExpanded ? "recipe.card.readAloud" : "recipe.detail.info.expand",
                            locale: locale
                        )
                    )
                )

                if isInfoExpanded {
                    Button {
                        cardSpeaker.toggleRead(
                            text: AppLanguage.string(String.LocalizationValue(recipe.infoKey), locale: locale),
                            languageCode: locale.identifier
                        )
                    } label: {
                        ReadAloudIcon(isSpeaking: cardSpeaker.isSpeaking)
                            .foregroundStyle(AppTheme.primaryBlue)
                            .frame(width: 18, height: 18, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        Text(AppLanguage.string("recipe.card.readAloud", locale: locale))
                    )
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut) {
                        isInfoExpanded.toggle()
                    }
                } label: {
                    Text(AppLanguage.string(String.LocalizationValue(recipe.infoSummaryKey), locale: locale))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(
                        AppLanguage.string(
                            isInfoExpanded ? "recipe.detail.info.collapse" : "recipe.detail.info.expand",
                            locale: locale
                        )
                    )
                )

                Button {
                    withAnimation(.easeInOut) {
                        isInfoExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isInfoExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 24, height: 24, alignment: .center)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isInfoExpanded else { return }
                withAnimation(.easeInOut) {
                    isInfoExpanded = true
                }
            }
            .accessibilityLabel(
                Text(
                    AppLanguage.string(
                        isInfoExpanded ? "recipe.detail.info.collapse" : "recipe.detail.info.expand",
                        locale: locale
                    )
                )
            )

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
        let contentSpacing: CGFloat = isStepsExpanded ? 9 : 0

        return VStack(alignment: .leading, spacing: contentSpacing) {
            stepsHeaderRow(headerText: headerText)
            stepsContent
        }
        .animation(.easeInOut(duration: 0.25), value: isStepsExpanded)
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .onDisappear {
            stepSpeaker.stop()
            cardSpeaker.stop()
        }
    }

    @ViewBuilder
    private func stepsHeaderRow(headerText: String) -> some View {
        let headerIconWidth: CGFloat = 24

        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Button {
                withAnimation(.easeInOut) {
                    isStepsExpanded.toggle()
                }
            } label: {
                Image(systemName: "list.number")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: headerIconWidth, alignment: .center)

                Text(AppLanguage.string("recipe.stepsTitle", locale: locale))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    AppLanguage.string(
                        isStepsExpanded ? "recipe.detail.steps.collapse" : "recipe.detail.steps.expand",
                        locale: locale
                    )
                )
            )

            if isStepsExpanded {
                Button {
                    readAllSteps()
                } label: {
                    Image(systemName: stepSpeaker.isSpeakingAllSteps ? "speaker.wave.2.fill" : "speaker.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(AppLanguage.string(
                    stepSpeaker.isSpeakingAllSteps ? "recipe.steps.stopReadAloud" : "recipe.steps.readAllAloud",
                    locale: locale
                )))
            }

            Spacer()

            Text(headerText)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))

            Button {
                withAnimation(.easeInOut) {
                    isStepsExpanded.toggle()
                }
            } label: {
                Image(systemName: isStepsExpanded ? "chevron.down" : "chevron.right")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 24, height: 24, alignment: .center)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    AppLanguage.string(
                        isStepsExpanded ? "recipe.detail.steps.collapse" : "recipe.detail.steps.expand",
                        locale: locale
                    )
                )
            )
        }
    }

    private var stepsContent: some View {
        VStack(spacing: 9) {
            Divider()
                .overlay(AppTheme.hairline)

            ForEach(recipe.steps) { step in
                StepRowView(
                    step: step,
                    ingredients: recipe.ingredients,
                    isDimmed: selectedStepID != nil && selectedStepID != step.id,
                    isSelected: selectedStepID == step.id,
                    onStepTap: {
                        if selectedStepID == step.id {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStepID = nil
                            }
                            stopStepReadAloud()
                        } else {
                            stopStepReadAloud()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStepID = step.id
                            }
                            readStep(step)
                        }
                    },
                    onTimerUpdate: { snapshot in
                        stepTimerSnapshots[snapshot.id] = snapshot
                    }
                )
                if step.id != recipe.steps.last?.id {
                    Divider().overlay(AppTheme.hairline)
                }
            }
        }
        .frame(height: isStepsExpanded ? nil : 0, alignment: .top)
        .clipped()
        .opacity(isStepsExpanded ? 1 : 0)
        .allowsHitTesting(isStepsExpanded)
        .accessibilityHidden(!isStepsExpanded)
    }

    private func readAllSteps() {
        if stepSpeaker.isSpeakingAllSteps {
            stepSpeaker.stop()
            return
        }
        let spokenSteps = recipe.steps.map { step in
            let body = AppLanguage.string(String.LocalizationValue(step.bodyKey), locale: locale)
            return SpokenStep(number: step.stepNumber, text: body)
        }
        let recipeName = AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)
        stepSpeaker.speakSteps(
            spokenSteps,
            recipeName: recipeName,
            locale: locale,
            languageCode: locale.identifier
        )
    }

    private func readStep(_ step: RecipeStep) {
        let body = AppLanguage.string(String.LocalizationValue(step.bodyKey), locale: locale)
        stepSpeaker.speakStep(text: body, languageCode: locale.identifier)
    }

    private func stopStepReadAloud() {
        stepSpeaker.stop()
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

    private var footerLinks: some View {
        VStack {
            HStack(spacing: 6) {
                footerLinkButton(titleKey: "footer.review", url: appStoreReviewURL)
                Text(" | ")
                footerShareLink
                Text(" | ")
                footerLinkButton(titleKey: "footer.feedback", url: feedbackMailURL)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .font(.footnote.weight(.medium))
        .foregroundStyle(highlightFooterLinks ? Color.orange : AppTheme.primaryBlue)
        .animation(.easeInOut(duration: 0.2), value: highlightFooterLinks)
        .id(footerLinksID)
        .padding(.top, -7)
        .padding(.vertical, 8)
    }

    private func footerLinkButton(titleKey: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Text(AppLanguage.string(titleKey, locale: locale))
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var footerShareLink: some View {
        ShareLink(item: shareRecipeURL, subject: Text(shareRecipeTitle), message: Text(shareRecipeMessage)) {
            Text(AppLanguage.string("footer.share", locale: locale))
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

private struct ScrollOffsetReader: UIViewRepresentable {
    @Binding var offset: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $offset)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            context.coordinator.attach(to: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attach(to: uiView)
        }
    }

    final class Coordinator {
        private var observation: NSKeyValueObservation?
        private var offset: Binding<CGFloat>

        init(offset: Binding<CGFloat>) {
            self.offset = offset
        }

        func attach(to view: UIView) {
            guard observation == nil, let scrollView = view.enclosingScrollView else {
                return
            }
            observation = scrollView.observe(\.contentOffset, options: [.initial, .new]) { [weak self] scrollView, _ in
                let newOffset = scrollView.contentOffset.y
                DispatchQueue.main.async {
                    guard let self else { return }
                    if self.offset.wrappedValue != newOffset {
                        self.offset.wrappedValue = newOffset
                    }
                }
            }
        }
    }
}

private extension UIView {
    var enclosingScrollView: UIScrollView? {
        var current: UIView? = self
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
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
    let isDimmed: Bool
    let isSelected: Bool
    let onStepTap: () -> Void
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

    init(
        step: RecipeStep,
        ingredients: [Ingredient],
        isDimmed: Bool,
        isSelected: Bool,
        onStepTap: @escaping () -> Void,
        onTimerUpdate: @escaping (StepTimerSnapshot) -> Void
    ) {
        self.step = step
        self.ingredients = ingredients
        self.isDimmed = isDimmed
        self.isSelected = isSelected
        self.onStepTap = onStepTap
        self.onTimerUpdate = onTimerUpdate
        let initial = step.timerSeconds ?? 0
        _secondsLeft = State(initialValue: initial)
        _sessionInitialSeconds = State(initialValue: initial)
        _baseInitialSeconds = State(initialValue: initial)
        _startSeconds = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 0) {
                Text("\(step.stepNumber). ")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryBlue)
                Text(AppLanguage.string(String.LocalizationValue(step.titleKey), locale: locale))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                if isSelected {
                    readAloudIcon
                        .padding(.leading, 6)
                }

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
            HStack(alignment: .top, spacing: 0) {
                Text("\(step.stepNumber). ")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryBlue)
                    .opacity(0)
                    .accessibilityHidden(true)
                Text(raw)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
                Spacer(minLength: 0)
                if step.timerSeconds != nil {
                    TimerBadgeView(
                        displayText: timerDisplayText,
                        isRunning: isRunning,
                        isOverdue: secondsLeft < 0
                    ) {}
                    .hidden()
                    .accessibilityHidden(true)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if step.timerSeconds != nil {
                Color.clear
                    .frame(width: 82, height: 28)
                    .contentShape(Rectangle())
                    .offset(y: 26)
                    .onTapGesture {
                        handleTimerTap()
                    }
            }
        }
        .padding(.vertical, 1.5)
        .opacity(isDimmed ? 0.45 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onStepTap()
        }
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
            return formattedTimerText(sessionInitialSeconds)
        }
        return timeText
    }

    private var timeText: String {
        formattedTimerText(secondsLeft)
    }

    private func formattedTimerText(_ totalSeconds: Int) -> String {
        if totalSeconds >= 0 {
            let m = totalSeconds / 60
            let s = totalSeconds % 60
            return String(format: "%d:%02d", m, s)
        } else {
            let over = abs(totalSeconds)
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

    private var readAloudIcon: some View {
        Image(systemName: "speaker.wave.2.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.primaryBlue)
            .accessibilityLabel(
                Text(AppLanguage.string("recipe.steps.readSelectedAloud", locale: locale))
            )
    }
}

private struct SpokenStep {
    let number: Int
    let text: String
}

private final class StepSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeakingAllSteps = false

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    private let speakerID = UUID().uuidString
    private var queuedUtteranceCount = 0
    private lazy var availableVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()
    private lazy var preferredVoicesByLanguage: [String: AVSpeechSynthesisVoice] = buildPreferredVoices()

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSessionForReadAloud()
        warmUpVoiceSelection()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalReadAloudStart(_:)),
            name: .readAloudDidStart,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func speakSteps(_ steps: [SpokenStep], recipeName: String, locale: Locale, languageCode: String) {
        stop()
        isSpeakingAllSteps = true
        activateAudioSession()
        notifyReadAloudStart()

        let intro = makeUtterance(
            text: introText(recipeName: recipeName, locale: locale),
            languageCode: languageCode,
            postDelay: 0.2
        )
        queuedUtteranceCount += 1
        synthesizer.speak(intro)

        for step in steps {
            let utterance = makeUtterance(
                text: "\(step.number). \(step.text)",
                languageCode: languageCode,
                postDelay: 0.2
            )
            queuedUtteranceCount += 1
            synthesizer.speak(utterance)
        }

        let outro = makeUtterance(text: outroText(locale: locale), languageCode: languageCode)
        outro.preUtteranceDelay = 0.5
        queuedUtteranceCount += 1
        synthesizer.speak(outro)
    }


    private func introText(recipeName: String, locale: Locale) -> String {
        let format = AppLanguage.string("recipe.steps.readAloud.intro", locale: locale)
        return String(format: format, locale: locale, recipeName)
    }

    private func outroText(locale: Locale) -> String {
        AppLanguage.string("recipe.steps.readAloud.outro", locale: locale)
    }

    func speakStep(text: String, languageCode: String) {
        stop()
        isSpeakingAllSteps = false
        activateAudioSession()
        notifyReadAloudStart()
        let utterance = makeUtterance(text: text, languageCode: languageCode)
        synthesizer.speak(utterance)
    }

    func stop() {
        queuedUtteranceCount = 0
        isSpeakingAllSteps = false
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard queuedUtteranceCount > 0 else { return }
        queuedUtteranceCount -= 1
        if queuedUtteranceCount == 0 {
            isSpeakingAllSteps = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if queuedUtteranceCount > 0 {
            queuedUtteranceCount -= 1
        }
        if queuedUtteranceCount == 0 {
            isSpeakingAllSteps = false
        }
    }

    private func makeUtterance(text: String, languageCode: String, postDelay: TimeInterval = 0) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice(for: languageCode)
        utterance.rate = 0.46
        utterance.pitchMultiplier = 0.95
        utterance.postUtteranceDelay = postDelay
        return utterance
    }

    private func configureAudioSessionForReadAloud() {
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
        } catch {
            assertionFailure("Failed to configure read-aloud audio session: \(error.localizedDescription)")
        }
    }

    private func activateAudioSession() {
        do {
            try audioSession.setActive(true, options: [])
        } catch {
            assertionFailure("Failed to activate read-aloud audio session: \(error.localizedDescription)")
        }
    }

    private func warmUpVoiceSelection() {
        _ = preferredVoicesByLanguage
    }

    private func preferredVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let baseCode = baseLanguageCode(for: languageCode)
        if let cached = preferredVoicesByLanguage[baseCode] {
            return cached
        }
        if let fallback = AVSpeechSynthesisVoice(language: languageCode) {
            return fallback
        }
        return AVSpeechSynthesisVoice(language: baseCode)
    }

    private func buildPreferredVoices() -> [String: AVSpeechSynthesisVoice] {
        let preferredMaleNamesByLanguage: [String: [String]] = [
            "en": ["Daniel", "Alex", "Arthur", "Aaron", "Nathan", "Tom"],
            "nl": ["Xander", "Daan"]
        ]

        var selected: [String: AVSpeechSynthesisVoice] = [:]

        for (language, names) in preferredMaleNamesByLanguage {
            let candidates = availableVoices.filter { baseLanguageCode(for: $0.language) == language }
            let maleCandidates = candidates.filter { voice in
                names.contains(where: { maleName in
                    voice.name.localizedCaseInsensitiveContains(maleName)
                })
            }

            if let voice = bestVoice(from: maleCandidates) ?? bestVoice(from: candidates) {
                selected[language] = voice
            }
        }

        return selected
    }

    private func bestVoice(from voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        voices.max(by: { voiceRank($0.quality) < voiceRank($1.quality) })
    }

    private func voiceRank(_ quality: AVSpeechSynthesisVoiceQuality) -> Int {
        switch quality {
        case .premium:
            return 3
        case .enhanced:
            return 2
        default:
            return 1
        }
    }

    private func baseLanguageCode(for languageCode: String) -> String {
        languageCode
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? languageCode
    }

    private func notifyReadAloudStart() {
        NotificationCenter.default.post(name: .readAloudDidStart, object: speakerID)
    }

    @objc
    private func handleExternalReadAloudStart(_ notification: Notification) {
        guard let sourceSpeakerID = notification.object as? String, sourceSpeakerID != speakerID else { return }
        stop()
    }
}
