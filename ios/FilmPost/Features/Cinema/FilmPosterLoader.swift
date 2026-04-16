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
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(URL)
        case failed
    }

    var state: LoadState = .idle

    func load(filmTitle: String) async {
        let title = filmTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            state = .failed
            return
        }

        state = .loading

        let candidates = [title, "\(title) (film)"]
        for candidate in candidates {
            if let url = await fetch(title: candidate) {
                state = .loaded(url)
                return
            }
        }

        state = .failed
    }

    private func fetch(title: String) async -> URL? {
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
            return decoded.originalimage?.source ?? decoded.thumbnail?.source
        } catch {
            return nil
        }
    }

    private struct WikipediaSummary: Decodable {
        let type: String?
        let originalimage: ImageRef?
        let thumbnail: ImageRef?
    }

    private struct ImageRef: Decodable {
        let source: URL
    }
}
