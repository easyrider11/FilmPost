import Foundation
import Testing
@testable import FilmPostCore


@Test("Multipart form builder encodes both images and boundary markers")
func multipartFormBuilderIncludesBothUploads() throws {
    let payload = try MultipartFormDataBuilder.makeAnalyzeBody(
        subjectData: Data("subject".utf8),
        subjectFilename: "subject.jpg",
        subjectMimeType: "image/jpeg",
        backgroundData: Data("background".utf8),
        backgroundFilename: "background.png",
        backgroundMimeType: "image/png",
        boundary: "Boundary-123"
    )

    let body = String(decoding: payload, as: UTF8.self)

    #expect(body.contains("name=\"subject_image\"; filename=\"subject.jpg\""))
    #expect(body.contains("name=\"background_image\"; filename=\"background.png\""))
    #expect(body.contains("Boundary-123--"))
}
