import Foundation
import UIKit

struct DebugSamplePhotoLoader {
    let subjectURL: URL
    let backgroundURL: URL

    init(subjectURL: URL, backgroundURL: URL) {
        self.subjectURL = subjectURL
        self.backgroundURL = backgroundURL
    }

    static func bundled(in bundle: Bundle = .main) throws -> DebugSamplePhotoLoader {
        guard let subjectURL = bundle.url(forResource: "debug-subject", withExtension: "jpg") else {
            throw LoadError.missingResource(.subject)
        }

        guard let backgroundURL = bundle.url(forResource: "debug-background", withExtension: "jpg") else {
            throw LoadError.missingResource(.background)
        }

        return DebugSamplePhotoLoader(subjectURL: subjectURL, backgroundURL: backgroundURL)
    }

    func loadPair() throws -> (subject: SelectedPhoto, background: SelectedPhoto) {
        (
            subject: try loadPhoto(at: subjectURL, role: .subject),
            background: try loadPhoto(at: backgroundURL, role: .background)
        )
    }

    private func loadPhoto(at url: URL, role: ImageRole) throws -> SelectedPhoto {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw LoadError.missingResource(role)
        }

        let data = try Data(contentsOf: url)

        guard let previewImage = UIImage(data: data) else {
            throw LoadError.invalidImageData(role)
        }

        return SelectedPhoto(
            role: role,
            data: data,
            filename: "\(role.filenameStem).jpg",
            mimeType: "image/jpeg",
            previewImage: previewImage
        )
    }
}

extension DebugSamplePhotoLoader {
    enum LoadError: LocalizedError, Equatable {
        case missingResource(ImageRole)
        case invalidImageData(ImageRole)

        var errorDescription: String? {
            switch self {
            case .missingResource(let role):
                return "FilmPost couldn't find the bundled \(role.title.lowercased()) sample."
            case .invalidImageData(let role):
                return "FilmPost couldn't read the bundled \(role.title.lowercased()) sample."
            }
        }
    }
}
