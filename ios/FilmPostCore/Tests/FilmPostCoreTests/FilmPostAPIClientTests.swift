import Foundation
import Testing
@testable import FilmPostCore


// MARK: - URLProtocol stub plumbing

/// A `URLProtocol` subclass that resolves every request against a closure.
/// This lets us drive the real `FilmPostAPIClient` (URLSession + multipart
/// encoder + decoder) without a backend, hitting only the network seam.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) static var handler: Handler?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeStubbedClient(
    handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
) -> FilmPostAPIClient {
    StubURLProtocol.handler = handler
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    let session = URLSession(configuration: config)
    return FilmPostAPIClient(baseURL: URL(string: "https://stub.invalid")!, session: session)
}

private let validResponseJSON = """
{
  "context_summary": "Soft transit light, clean lines, restraint-friendly geometry.",
  "recommendations": [
    {
      "style": "Quiet Platform",
      "why_this_matches": "Geometry supports a calm, architectural portrait.",
      "director_note": "Play stillness as a withheld thought.",
      "emotional_goal": "Urban solitude with polished interior calm.",
      "pose": "One shoulder turned toward the tracks.",
      "composition": "Subject on the left third with rails leading right.",
      "color_direction": "Cool silver blues; gentle amber on skin.",
      "camera_distance": "Medium close so station texture still reads.",
      "lighting_tip": "Catch the soft overhead spill on the brow.",
      "reference_film_mood": "Measured city melancholy.",
      "cinema_reference": {
        "film_title": "Lost in Translation",
        "director": "Sofia Coppola",
        "scene_anchor": "Hotel-window pause before Tokyo arrives.",
        "why_it_connects": "Cool reflected light carries the same suspended urban loneliness.",
        "borrowed_technique": "Negative space + delayed gaze."
      }
    },
    {
      "style": "Late Commute Stillness",
      "why_this_matches": "Spare background keeps attention on posture.",
      "director_note": "Photograph the moment before deciding to stay.",
      "emotional_goal": "Tender hesitation held in public.",
      "pose": "Hands resting near coat seams; settled stance.",
      "composition": "Mid-torso framing; tile rhythm behind subject.",
      "color_direction": "Slate, cream, muted olive.",
      "camera_distance": "Medium shot, equal weight subject + environment.",
      "lighting_tip": "Step under the brightest ceiling patch's edge.",
      "reference_film_mood": "Subdued night-train mood.",
      "cinema_reference": {
        "film_title": "Brief Encounter",
        "director": "David Lean",
        "scene_anchor": "Railway-platform pause charged by restraint.",
        "why_it_connects": "Stations make distance and interruption legible.",
        "borrowed_technique": "Shared space and sidelong posture."
      }
    },
    {
      "style": "Centered Noir Calm",
      "why_this_matches": "Symmetrical perspective makes a still portrait feel deliberate.",
      "director_note": "Let the space discipline the body until stillness becomes tension.",
      "emotional_goal": "Formal control with underlying unease.",
      "pose": "Square stance; chin slightly lowered.",
      "composition": "Center the subject; tunnel lines pull inward.",
      "color_direction": "Cool graphite tones with a small warm lift.",
      "camera_distance": "Wider medium so architecture carries tension.",
      "lighting_tip": "Expose for face; let far practical lights bloom.",
      "reference_film_mood": "Controlled metropolitan noir.",
      "cinema_reference": {
        "film_title": "The Conformist",
        "director": "Bernardo Bertolucci",
        "scene_anchor": "Figure inside severe architectural symmetry.",
        "why_it_connects": "Receding lines create the same controlled visual pressure.",
        "borrowed_technique": "Centered framing + measured distance."
      }
    }
  ]
}
""".data(using: .utf8)!

private let pixel = ImageUpload(
    data: Data([0xFF, 0xD8, 0xFF, 0xD9]),
    filename: "subject.jpg",
    mimeType: "image/jpeg"
)

// MARK: - Tests

// `StubURLProtocol.handler` is shared (static) mutable state, so these tests
// must run serially — otherwise one test's handler can answer another test's
// request and assertions race.
@Suite(.serialized)
struct FilmPostAPIClientTests {

@Test("APIClient decodes a happy-path response into AnalysisResponse")
func apiClientDecodesHappyPath() async throws {
    let client = makeStubbedClient { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, validResponseJSON)
    }

    let analysis = try await client.analyze(subject: pixel, background: pixel)

    #expect(analysis.recommendations.count == 3)
    #expect(analysis.recommendations[0].cinemaReference.filmTitle == "Lost in Translation")
}

@Test("APIClient surfaces backend detail message on a 4xx")
func apiClientSurfacesBackendDetailOn4xx() async {
    let client = makeStubbedClient { request in
        let body = "{\"detail\": \"subject_image was empty.\"}".data(using: .utf8)!
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 400,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, body)
    }

    do {
        _ = try await client.analyze(subject: pixel, background: pixel)
        Issue.record("Expected analyze() to throw on a 400")
    } catch let FilmPostAPIError.server(message) {
        #expect(message == "subject_image was empty.")
    } catch {
        Issue.record("Expected .server, got \(error)")
    }
}

@Test("APIClient maps a notConnectedToInternet URLError to .offline")
func apiClientMapsOfflineURLError() async {
    let client = makeStubbedClient { _ in
        throw URLError(.notConnectedToInternet)
    }

    do {
        _ = try await client.analyze(subject: pixel, background: pixel)
        Issue.record("Expected analyze() to throw")
    } catch FilmPostAPIError.offline {
        // expected
    } catch {
        Issue.record("Expected .offline, got \(error)")
    }
}

@Test("APIClient maps a timedOut URLError to .timedOut")
func apiClientMapsTimedOutURLError() async {
    let client = makeStubbedClient { _ in
        throw URLError(.timedOut)
    }

    do {
        _ = try await client.analyze(subject: pixel, background: pixel)
        Issue.record("Expected analyze() to throw")
    } catch FilmPostAPIError.timedOut {
        // expected
    } catch {
        Issue.record("Expected .timedOut, got \(error)")
    }
}

@Test("APIClient surfaces .decodingFailed on non-JSON 2xx body")
func apiClientSurfacesDecodingFailureOnGarbageBody() async {
    let client = makeStubbedClient { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data("not json".utf8))
    }

    do {
        _ = try await client.analyze(subject: pixel, background: pixel)
        Issue.record("Expected analyze() to throw")
    } catch FilmPostAPIError.decodingFailed {
        // expected
    } catch {
        Issue.record("Expected .decodingFailed, got \(error)")
    }
}

}  // FilmPostAPIClientTests
