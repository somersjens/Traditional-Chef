//
//  RecipeImagePrefetcher.swift
//  Traditional Chef
//

import Foundation

actor RecipeImagePrefetchTracker {
    static let shared = RecipeImagePrefetchTracker()

    private var inFlightURLs: Set<URL> = []

    func begin(_ url: URL) -> Bool {
        let inserted = inFlightURLs.insert(url).inserted
        return inserted
    }

    func end(_ url: URL) {
        inFlightURLs.remove(url)
    }
}

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

        Task {
            let shouldStart = await RecipeImagePrefetchTracker.shared.begin(url)
            guard shouldStart else { return }

            let task = URLSession.shared.dataTask(with: request) { _, _, _ in
                Task {
                    await RecipeImagePrefetchTracker.shared.end(url)
                }
            }
            task.priority = URLSessionTask.lowPriority
            task.resume()
        }
    }
}
