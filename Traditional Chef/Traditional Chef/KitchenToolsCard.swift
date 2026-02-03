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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.toolsTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 24, height: 24, alignment: .center)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
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
                Text(AppLanguage.string("grocery.optional", locale: locale))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primaryBlue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}
