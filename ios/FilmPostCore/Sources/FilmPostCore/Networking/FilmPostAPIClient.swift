import Foundation

public struct ImageUpload: Sendable {
    public let data: Data
    public let filename: String
    public let mimeType: String

    public init(data: Data, filename: String, mimeType: String) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
    }
}

public protocol FilmPostAPIClientProtocol: Sendable {
    func analyze(subject: ImageUpload, background: ImageUpload) async throws -> AnalysisResponse
}

public enum FilmPostAPIError: LocalizedError, Equatable, Sendable {
    case invalidBaseURL
    case invalidResponse
    case decodingFailed
    case server(String)
    case transport(String)
    case offline
    case timedOut
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "FilmPost could not find a valid backend URL."
        case .invalidResponse:
            return "FilmPost received an invalid response from the backend."
        case .decodingFailed:
            return "FilmPost could not decode the analysis response."
        case .server(let message):
            return message
        case .transport(let message):
            return "FilmPost could not reach the backend (\(message)). Check that the API is running and reachable."
        case .offline:
            return "FilmPost can't reach the network. Check your connection and try again."
        case .timedOut:
            return "FilmPost is taking longer than expected. Please try again in a moment."
        case .cancelled:
            return "Analysis cancelled."
        }
    }
}

private struct APIErrorEnvelope: Decodable {
    let detail: String
}

public struct FilmPostAPIClient: FilmPostAPIClientProtocol {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func analyze(subject: ImageUpload, background: ImageUpload) async throws -> AnalysisResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: "v1").appending(path: "analyze"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // The OpenAI vision call typically settles in 6–14s; the backend itself
        // caps at 30s. 45s gives the slowest legitimate path room without
        // letting the user stare at a spinner forever if the server is wedged.
        request.timeoutInterval = 45
        request.httpBody = try MultipartFormDataBuilder.makeAnalyzeBody(
            subjectData: subject.data,
            subjectFilename: subject.filename,
            subjectMimeType: subject.mimeType,
            backgroundData: background.data,
            backgroundFilename: background.filename,
            backgroundMimeType: background.mimeType,
            boundary: boundary
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            // Map system-level network failures to specific cases so the UI
            // can show the right thing (offline banner vs. retry hint vs.
            // silent dismiss on user-cancelled).
            switch urlError.code {
            case .cancelled:
                throw FilmPostAPIError.cancelled
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw FilmPostAPIError.offline
            case .timedOut:
                throw FilmPostAPIError.timedOut
            default:
                throw FilmPostAPIError.transport(urlError.localizedDescription)
            }
        } catch is CancellationError {
            throw FilmPostAPIError.cancelled
        } catch {
            throw FilmPostAPIError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FilmPostAPIError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
                throw FilmPostAPIError.server(envelope.detail)
            }
            throw FilmPostAPIError.server("FilmPost couldn't finish the analysis right now.")
        }

        do {
            return try JSONDecoder().decode(AnalysisResponse.self, from: data)
        } catch {
            throw FilmPostAPIError.decodingFailed
        }
    }
}
