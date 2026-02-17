//
//  ServingsCard.swift
//  Traditional Chef
//

import SwiftUI

struct ServingsCard: View {
    @Binding var servings: Int
    @State private var servingsInput: String
    @FocusState private var isServingsFocused: Bool
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    private let minServings = 1
    private let maxServings = 99

    init(servings: Binding<Int>) {
        _servings = servings
        _servingsInput = State(initialValue: "\(servings.wrappedValue)")
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "person")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryBlue)

            Text(AppLanguage.string("grocery.servings", locale: locale))
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            HStack(spacing: 12) {
                Button(action: decrementServings) {
                    Image(systemName: "minus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.primaryBlue.opacity(servings <= minServings ? 0.3 : 1))
                .disabled(servings <= minServings)

                ZStack {
                    if isServingsFocused {
                        TextField("", text: $servingsInput)
                            .focused($isServingsFocused)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title3.weight(.semibold))
                            .frame(width: 44)
                    } else {
                        Text("\(servings)")
                            .font(.title3.weight(.semibold))
                            .frame(width: 44)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isServingsFocused = true
                }

                Button(action: incrementServings) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.primaryBlue.opacity(servings >= maxServings ? 0.3 : 1))
                .disabled(servings >= maxServings)
            }
            .foregroundStyle(AppTheme.primaryBlue)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .onChange(of: isServingsFocused) { isFocused in
            if !isFocused {
                commitServingsInput()
            }
        }
        .onChange(of: servingsInput) { newValue in
            let filtered = newValue.filter { $0.isNumber }
            if filtered != newValue {
                servingsInput = filtered
            } else if filtered.count > 2 {
                servingsInput = String(filtered.prefix(2))
            }
        }
        .onChange(of: servings) { newValue in
            if !isServingsFocused {
                servingsInput = "\(newValue)"
            }
        }
    }

    private func incrementServings() {
        updateServings(to: servings + 1)
    }

    private func decrementServings() {
        updateServings(to: servings - 1)
    }

    private func updateServings(to newValue: Int) {
        let clamped = min(max(newValue, minServings), maxServings)
        servings = clamped
        servingsInput = "\(clamped)"
    }

    private func commitServingsInput() {
        let parsed = Int(servingsInput) ?? servings
        updateServings(to: parsed)
    }
}
