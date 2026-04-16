import Foundation
import Observation

/// Loads a film's poster artwork from the Wikipedia REST summary API.
///
/// The Wikipedia REST endpoint `/page/summary/{title}` returns `originalimage`
/// and `thumbnail` references for the canonical page image — for film
/// articles this is almost always the poster shown in the page infobox.
/// We retry with the `(film)` disambiguation suffix if the bare title
/// resolves to a disambiguation page or 404s.
@Observable
final class FilmPosterLoader {
    struct Poster: Equatable, Sendable {
        let imageURL: URL
        /// The canonical Wikipedia article page (used for required CC-BY-SA
        /// attribution). May be nil if the summary response omitted it.
        let articleURL: URL?
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(Poster)
        case failed
    }

    var state: LoadState = .idle

    func load(filmTitle: String) async {
        let title = filmTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            state = .failed
            return
        }

        // Process-wide cache: the same film can be referenced from multiple
        // recommendation cards across a session, and revisits used to re-hit
        // Wikipedia every time. Cached hits land synchronously so the poster
        // appears without a flash of placeholder.
        if let cached = await FilmPosterCache.shared.poster(for: title) {
            state = .loaded(cached)
            return
        }

        state = .loading

        let candidates = [title, "\(title) (film)"]
        for candidate in candidates {
            if let poster = await fetch(title: candidate) {
                await FilmPosterCache.shared.store(poster, for: title)
                state = .loaded(poster)
                return
            }
        }

        state = .failed
    }

    private func fetch(title: String) async -> Poster? {
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
            guard let image = decoded.originalimage?.source ?? decoded.thumbnail?.source else { return nil }
            return Poster(imageURL: image, articleURL: decoded.content_urls?.desktop?.page)
        } catch {
            return nil
        }
    }

    private struct WikipediaSummary: Decodable {
        let type: String?
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

/// In-memory cache for resolved film posters. Keyed by the trimmed
/// user-facing title (the same key used by `load(filmTitle:)`), so two
/// recommendation cards referencing "Lost in Translation" hit the network
/// at most once per session.
private actor FilmPosterCache {
    static let shared = FilmPosterCache()

    private var entries: [String: FilmPosterLoader.Poster] = [:]

    func poster(for title: String) -> FilmPosterLoader.Poster? {
        entries[title]
    }

    func store(_ poster: FilmPosterLoader.Poster, for title: String) {
        entries[title] = poster
    }
}
