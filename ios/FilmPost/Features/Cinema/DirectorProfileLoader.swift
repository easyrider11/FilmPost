import Foundation
import Observation

/// Loads a director's portrait + brief biography from the Wikipedia REST summary API.
///
/// The Wikipedia REST endpoint `/page/summary/{title}` returns the page's lead
/// image (almost always a headshot for biographical pages) plus a short plain-text
/// `extract` — typically the opening 1–3 sentences of the article. We fall back
/// through `(director)` and `(filmmaker)` disambiguation suffixes when the bare
/// name resolves to a disambiguation page or 404s.
@Observable
final class DirectorProfileLoader {
    struct Profile: Equatable, Sendable {
        let portraitURL: URL?
        let bio: String
        /// The canonical Wikipedia article page (used for required CC-BY-SA
        /// attribution on the biography blurb). May be nil if the summary
        /// response omitted it.
        let articleURL: URL?
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(Profile)
        case failed
    }

    var state: LoadState = .idle

    func load(directorName: String) async {
        let name = directorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            state = .failed
            return
        }

        // Process-wide cache: same director can appear across multiple
        // recommendation cards, and revisits used to re-hit Wikipedia each
        // time. Cached hits land synchronously so the portrait + bio appear
        // without the placeholder flash.
        if let cached = await DirectorProfileCache.shared.profile(for: name) {
            state = .loaded(cached)
            return
        }

        state = .loading

        let candidates = [name, "\(name) (director)", "\(name) (filmmaker)"]
        for candidate in candidates {
            if let profile = await fetch(title: candidate) {
                await DirectorProfileCache.shared.store(profile, for: name)
                state = .loaded(profile)
                return
            }
        }

        state = .failed
    }

    private func fetch(title: String) async -> Profile? {
        let normalized = title.replacingOccurrences(of: " ", with: "_")
        guard let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("FilmPost/1.0 (https://github.com/easyrider11/FilmPost)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let decoded = try JSONDecoder().decode(WikipediaSummary.self, from: data)
            if decoded.type == "disambiguation" { return nil }

            let portrait = decoded.originalimage?.source ?? decoded.thumbnail?.source
            let bio = (decoded.extract ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            // Require either a portrait or a meaningful extract — otherwise the page
            // is unlikely to be the director we're after.
            guard portrait != nil || bio.count >= 40 else { return nil }

            return Profile(
                portraitURL: portrait,
                bio: bio,
                articleURL: decoded.content_urls?.desktop?.page
            )
        } catch {
            return nil
        }
    }

    private struct WikipediaSummary: Decodable {
        let type: String?
        let extract: String?
        let originalimage: ImageRef?
        let thumbnail: ImageRef?
        let content_urls: ContentURLs?
    }

    private struct ContentURLs: Decodable {
        let desktop: Variant?

        struct Variant: Decodable {
            let page: URL?
        }
    }

    private struct ImageRef: Decodable {
        let source: URL
    }
}

/// In-memory cache for resolved director profiles. Keyed by the trimmed
/// user-facing name (the same key used by `load(directorName:)`), so the
/// same director referenced across multiple recommendation cards hits the
/// network at most once per session.
private actor DirectorProfileCache {
    static let shared = DirectorProfileCache()

    private var entries: [String: DirectorProfileLoader.Profile] = [:]

    func profile(for name: String) -> DirectorProfileLoader.Profile? {
        entries[name]
    }

    func store(_ profile: DirectorProfileLoader.Profile, for name: String) {
        entries[name] = profile
    }
}
