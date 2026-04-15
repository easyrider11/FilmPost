import Foundation

enum AppConfiguration {
    private static let fallbackBaseURL = URL(string: "http://127.0.0.1:8000")!

    static var apiBaseURL: URL {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "FilmPostAPIBaseURL") as? String,
            let url = URL(string: rawValue)
        else {
            return fallbackBaseURL
        }

        return url
    }
}
