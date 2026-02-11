//
//  KitchenToolsCard.swift
//  FamousChef
//

import SwiftUI

struct KitchenToolsCard: View {
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }
    @State private var isExpanded: Bool = true
    @StateObject private var cardSpeaker = CardReadAloudSpeaker()

    var body: some View {
        let headerIconWidth: CGFloat = 24
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Button {
                    if isExpanded {
                        cardSpeaker.toggleRead(text: readAloudText, languageCode: locale.identifier)
                    } else {
                        withAnimation(.easeInOut) {
                            isExpanded = true
                        }
                    }
                } label: {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: headerIconWidth, alignment: .center)

                    Text(AppLanguage.string("recipe.toolsTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(isExpanded ? AppLanguage.string("recipe.card.readAloud", locale: locale) : "Expand kitchen tools")
                )

                if isExpanded {
                    Button {
                        cardSpeaker.toggleRead(text: readAloudText, languageCode: locale.identifier)
                    } label: {
                        Image(systemName: cardSpeaker.isSpeaking ? "speaker.wave.2.fill" : "speaker.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryBlue)
                            .frame(width: 24, height: 24, alignment: .center)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 24, height: 24, alignment: .center)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isExpanded else { return }
                withAnimation(.easeInOut) {
                    isExpanded = true
                }
            }
            .accessibilityLabel(Text(isExpanded ? "Collapse kitchen tools" : "Expand kitchen tools"))

            if isExpanded {
                Divider()
                    .overlay(AppTheme.hairline)
                    .transition(.opacity)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recipe.tools) { tool in
                        toolRow(tool)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .onDisappear {
            cardSpeaker.stop()
        }
    }

    private var summaryText: String {
        let format = AppLanguage.string("recipe.tools.summary", locale: locale)
        let requiredCount = recipe.tools.filter { !$0.isOptional }.count
        let optionalCount = recipe.tools.filter { $0.isOptional }.count
        return String(format: format, locale: locale, requiredCount, optionalCount)
    }

    private func toolRow(_ tool: RecipeTool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue)

            Text(AppLanguage.string(String.LocalizationValue(tool.nameKey), locale: locale))
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)

            if tool.isOptional {
                let labelKey = tool.optionalLabelKey ?? "grocery.optional"
                Text(AppLanguage.string(labelKey, locale: locale))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primaryBlue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private var readAloudText: String {
        let introKey = locale.identifier.lowercased().hasPrefix("nl")
            ? "recipe.tools.readAloud.intro.nl"
            : "recipe.tools.readAloud.intro.en"
        let intro = AppLanguage.string(introKey, locale: locale)
        let tools = recipe.tools.map { AppLanguage.string(String.LocalizationValue($0.nameKey), locale: locale) }
        let toolsText = joinedForSpeech(tools, locale: locale)
        return "\(intro) \(toolsText)"
    }
}
