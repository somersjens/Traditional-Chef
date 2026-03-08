//
//  RecipeSharedImageLoader.swift
//  Traditional Chef
//

import Foundation
import UIKit

actor RecipeSharedImageLoader {
    static let shared = RecipeSharedImageLoader()

    nonisolated private static let memoryCache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 180
        cache.totalCostLimit = 180 * 1024 * 1024
        return cache
    }()

    private var inFlightTasks: [URL: Task<UIImage?, Never>] = [:]
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache.shared
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 90
        return URLSession(configuration: configuration)
    }()

    func cachedImage(for urlString: String?) -> UIImage? {
        guard let url = Self.validURL(from: urlString) else {
            return nil
        }
        return Self.memoryCache.object(forKey: url as NSURL)
    }


    func cache(_ image: UIImage, for urlString: String?) {
        guard let url = Self.validURL(from: urlString) else {
            return
        }
        Self.memoryCache.setObject(image, forKey: url as NSURL, cost: Self.cacheCost(for: image))
    }

    func image(for urlString: String?) async -> UIImage? {
        guard let url = Self.validURL(from: urlString) else {
            return nil
        }

        if let cachedImage = Self.memoryCache.object(forKey: url as NSURL) {
            return cachedImage
        }

        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 45
        )

        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let image = Self.decodeImage(from: cachedResponse.data) {
            Self.memoryCache.setObject(image, forKey: url as NSURL, cost: Self.cacheCost(for: image))
            return image
        }

        if let inFlightTask = inFlightTasks[url] {
            return await inFlightTask.value
        }

        let task = Task<UIImage?, Never> {
            do {
                let (data, response) = try await session.data(for: request)
                let hasSuccessfulStatusCode = (response as? HTTPURLResponse).map { (200...299).contains($0.statusCode) } ?? true
                guard hasSuccessfulStatusCode,
                      let image = Self.decodeImage(from: data)
                else {
                    return nil
                }

                Self.memoryCache.setObject(image, forKey: url as NSURL, cost: Self.cacheCost(for: image))
                return image
            } catch {
                return nil
            }
        }

        inFlightTasks[url] = task
        let image = await task.value
        inFlightTasks[url] = nil
        return image
    }

    nonisolated private static func validURL(from urlString: String?) -> URL? {
        guard let urlString = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty,
              let url = URL(string: urlString),
              url.scheme?.hasPrefix("http") == true
        else {
            return nil
        }
        return url
    }

    nonisolated private static func cacheCost(for image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            let width = Int(image.size.width * image.scale)
            let height = Int(image.size.height * image.scale)
            return max(1, width * height * 4)
        }

        return max(1, cgImage.bytesPerRow * cgImage.height)
    }

    nonisolated private static func decodeImage(from data: Data) -> UIImage? {
        guard !data.isEmpty,
              let image = UIImage(data: data)
        else {
            return nil
        }

        return image.preparingForDisplay() ?? image
    }
}
