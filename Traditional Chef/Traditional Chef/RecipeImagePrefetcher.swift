//
//  RecipeImagePrefetcher.swift
//  Traditional Chef
//

import Foundation

enum RecipeImagePrefetcher {
    static func prefetch(urlString: String?) {
        guard let urlString,
              let url = URL(string: urlString),
              url.scheme?.hasPrefix("http") == true
        else {
            return
        }

        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
           !cachedResponse.data.isEmpty {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { _, _, _ in }
        task.priority = URLSessionTask.lowPriority
        task.resume()
    }
}
