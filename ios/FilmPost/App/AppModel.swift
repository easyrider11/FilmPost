import FilmPostCore
import Foundation
import Observation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

@MainActor
@Observable
final class AppModel {
    private let apiClient: FilmPostAPIClientProtocol

    var subjectPhoto: SelectedPhoto?
    var backgroundPhoto: SelectedPhoto?
    var analysis: AnalysisResponse?
    var isAnalyzing = false
    var errorMessage: String?

    init(apiClient: FilmPostAPIClientProtocol = FilmPostAPIClient(baseURL: AppConfiguration.apiBaseURL)) {
        self.apiClient = apiClient
    }

    var canAnalyze: Bool {
        subjectPhoto != nil && backgroundPhoto != nil && !isAnalyzing
    }

    var currentScreen: Screen {
        if isAnalyzing { return .loading }
        if analysis != nil { return .results }
        return .upload
    }

    func loadPhoto(from item: PhotosPickerItem?, role: ImageRole) async {
        guard let item else {
            assign(nil, to: role)
            if analysis != nil { analysis = nil }
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let previewImage = UIImage(data: data) else {
                throw PhotoLoadError.invalidData
            }

            let contentType = item.supportedContentTypes.first ?? .jpeg
            let mimeType = contentType.preferredMIMEType ?? "image/jpeg"
            let fileExtension = contentType.preferredFilenameExtension ?? "jpg"
            let photo = SelectedPhoto(
                role: role,
                data: data,
                filename: "\(role.filenameStem).\(fileExtension)",
                mimeType: mimeType,
                previewImage: previewImage
            )

            assign(photo, to: role)
            analysis = nil
            errorMessage = nil
        } catch {
            errorMessage = "FilmPost couldn't load that \(role.title.lowercased()) image. Try a different photo."
        }
    }

    func analyze() async {
        guard let subjectPhoto, let backgroundPhoto else { return }

        isAnalyzing = true
        errorMessage = nil

        do {
            analysis = try await apiClient.analyze(
                subject: ImageUpload(
                    data: subjectPhoto.data,
                    filename: subjectPhoto.filename,
                    mimeType: subjectPhoto.mimeType
                ),
                background: ImageUpload(
                    data: backgroundPhoto.data,
                    filename: backgroundPhoto.filename,
                    mimeType: backgroundPhoto.mimeType
                )
            )
        } catch let error as FilmPostAPIError {
            errorMessage = error.errorDescription
            analysis = nil
        } catch {
            errorMessage = "FilmPost hit an unexpected problem. Please try again."
            analysis = nil
        }

        isAnalyzing = false
    }

    func loadDebugSamplesAndAnalyze() async {
        guard !isAnalyzing else { return }

        do {
            let loader = try DebugSamplePhotoLoader.bundled()
            let pair = try loader.loadPair()
            subjectPhoto = pair.subject
            backgroundPhoto = pair.background
            analysis = nil
            errorMessage = nil
            await analyze()
        } catch let error as DebugSamplePhotoLoader.LoadError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "FilmPost couldn't load the bundled demo photos."
        }
    }

    func startOver() {
        analysis = nil
        errorMessage = nil
    }

    func resetSelections() {
        subjectPhoto = nil
        backgroundPhoto = nil
        analysis = nil
        errorMessage = nil
    }

    private func assign(_ photo: SelectedPhoto?, to role: ImageRole) {
        switch role {
        case .subject:
            subjectPhoto = photo
        case .background:
            backgroundPhoto = photo
        }
    }
}

extension AppModel {
    enum Screen {
        case upload
        case loading
        case results
    }

    enum PhotoLoadError: Error {
        case invalidData
    }
}
