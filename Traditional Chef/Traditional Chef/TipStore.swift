//
//  TipStore.swift
//  FamousChef
//

import Combine
import Foundation
import StoreKit
import SwiftUI

@MainActor
final class TipStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published var lastErrorMessage: String?

    private let productIDs: [String] = ["tip_1", "tip_2", "tip_5"]

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)
            products = fetched.sorted(by: { $0.displayPrice < $1.displayPrice })
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func buy(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                _ = try verification.payloadValue
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func product(for id: String) -> Product? {
        products.first(where: { $0.id == id })
    }
}
