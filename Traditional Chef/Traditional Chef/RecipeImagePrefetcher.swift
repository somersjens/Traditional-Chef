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

        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 30
        )

        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           !cachedResponse.data.isEmpty {
            return
        }

        let task = URLSession.shared.dataTask(with: request) { _, _, _ in }
        task.priority = URLSessionTask.highPriority
        task.resume()
    }
}
