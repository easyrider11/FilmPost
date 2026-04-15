import Foundation
import Testing
import UIKit
@testable import FilmPost

struct DebugSamplePhotoLoaderTests {
    @Test("Detects the debug auto-demo launch argument")
    func detectsAutoDemoFlag() {
        #expect(DebugLaunchOptions.shouldAutoRunDemo(arguments: ["FilmPost", "-auto-demo"]))
        #expect(!DebugLaunchOptions.shouldAutoRunDemo(arguments: ["FilmPost"]))
    }

    @Test("Loads a subject/background pair from provided JPEG files")
    func loadsPairFromDisk() throws {
        let fixtureDirectory = try makeFixtureDirectory()
        let subjectURL = fixtureDirectory.appendingPathComponent("debug-subject.jpg")
        let backgroundURL = fixtureDirectory.appendingPathComponent("debug-background.jpg")

        try makeJPEG(color: .systemBlue).write(to: subjectURL)
        try makeJPEG(color: .systemOrange).write(to: backgroundURL)

        let loader = DebugSamplePhotoLoader(subjectURL: subjectURL, backgroundURL: backgroundURL)
        let pair = try loader.loadPair()

        #expect(pair.subject.role == .subject)
        #expect(pair.subject.filename == "subject.jpg")
        #expect(pair.subject.mimeType == "image/jpeg")
        #expect(pair.subject.previewImage.size.width > 0)

        #expect(pair.background.role == .background)
        #expect(pair.background.filename == "background.jpg")
        #expect(pair.background.mimeType == "image/jpeg")
        #expect(pair.background.previewImage.size.height > 0)
    }

    @Test("Throws a missing resource error when a sample file is absent")
    func throwsMissingResource() throws {
        let fixtureDirectory = try makeFixtureDirectory()
        let backgroundURL = fixtureDirectory.appendingPathComponent("debug-background.jpg")
        try makeJPEG(color: .systemOrange).write(to: backgroundURL)

        let loader = DebugSamplePhotoLoader(
            subjectURL: fixtureDirectory.appendingPathComponent("missing-subject.jpg"),
            backgroundURL: backgroundURL
        )

        #expect(throws: DebugSamplePhotoLoader.LoadError.missingResource(.subject)) {
            try loader.loadPair()
        }
    }

    private func makeFixtureDirectory() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeJPEG(color: UIColor) throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20))
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw FixtureError.failedToBuildJPEG
        }

        return data
    }
}

private enum FixtureError: Error {
    case failedToBuildJPEG
}
