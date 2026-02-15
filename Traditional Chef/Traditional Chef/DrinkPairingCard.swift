//
//  DrinkPairingCard.swift
//  FamousChef
//

import SwiftUI

struct DrinkPairingCard: View {
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }
    @State private var isExpanded: Bool = false
    @StateObject private var cardSpeaker = CardReadAloudSpeaker()

    var body: some View {
        Group {
            if let bodyKey = recipe.drinkPairingKey {
                let headerIconWidth: CGFloat = 24
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Button {
                            if isExpanded {
                                cardSpeaker.toggleRead(
                                    text: AppLanguage.string(String.LocalizationValue(bodyKey), locale: locale),
                                    languageCode: locale.identifier
                                )
                            } else {
                                withAnimation(.easeInOut) {
                                    isExpanded = true
                                }
                            }
                        } label: {
                            Image(systemName: "wineglass")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryBlue)
                                .frame(width: headerIconWidth, alignment: .center)

                            Text(AppLanguage.string("recipe.drinkTitle", locale: locale))
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            Text(isExpanded ? AppLanguage.string("recipe.card.readAloud", locale: locale) : "Expand drink recommendation")
                        )

                        if isExpanded && cardSpeaker.isSpeaking {
                            Button {
                                cardSpeaker.toggleRead(
                                    text: AppLanguage.string(String.LocalizationValue(bodyKey), locale: locale),
                                    languageCode: locale.identifier
                                )
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.primaryBlue)
                                    .frame(width: 18, height: 18, alignment: .center)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        if let summaryKey = recipe.drinkPairingSummaryKey {
                            Button {
                                withAnimation(.easeInOut) {
                                    isExpanded.toggle()
                                }
                            } label: {
                                Text(AppLanguage.string(String.LocalizationValue(summaryKey), locale: locale))
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                                    .lineLimit(1)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            withAnimation(.easeInOut) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryBlue)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
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
                    .accessibilityLabel(Text(isExpanded ? "Collapse drink recommendation" : "Expand drink recommendation"))

                    if isExpanded {
                        Divider()
                            .overlay(AppTheme.hairline)
                            .transition(.opacity)

                        let raw = AppLanguage.string(String.LocalizationValue(bodyKey), locale: locale)
                        let boldPhrases = recipe.drinkPairingBoldPhraseKeys.map {
                            AppLanguage.string(String.LocalizationValue($0), locale: locale)
                        }

                        Text(AttributedString.boldPhrases(in: raw, phrases: boldPhrases))
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
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
                .onChange(of: isExpanded) { _, expanded in
                    if !expanded {
                        cardSpeaker.stop()
                    }
                }
            }
        }
    }
}
