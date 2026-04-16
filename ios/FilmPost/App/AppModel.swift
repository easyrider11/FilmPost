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

    // Held so the loading screen's Cancel button can interrupt an in-flight
    // analyze request (cancelling the URLSession data task surfaces as a
    // URLError.cancelled, which the API client maps to FilmPostAPIError.cancelled
    // and we silently swallow rather than rendering as an error banner).
    private var analysisTask: Task<Void, Never>?

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
                  let originalImage = UIImage(data: data) else {
                throw PhotoLoadError.invalidData
            }

            // Upload-side compression: a modern iPhone HEIC/JPEG can run
            // 6–10 MB. The backend re-encodes to ~1568px on the long edge
            // anyway, so shipping the full original wastes bytes on cellular
            // and slows the round-trip. Downscaling to 2048px @ q=0.8 keeps
            // plenty of headroom for the backend's resize while typically
            // cutting upload bytes by 4–8x.
            let compressed = ImageUploadCompressor.compress(originalImage)
            let photo = SelectedPhoto(
                role: role,
                data: compressed.data,
                filename: "\(role.filenameStem).jpg",
                mimeType: "image/jpeg",
                previewImage: compressed.previewImage
            )

            assign(photo, to: role)
            analysis = nil
            errorMessage = nil
        } catch {
            errorMessage = "FilmPost couldn't load that \(role.title.lowercased()) image. Try a different photo."
        }
    }

    /// Adopts a freshly captured `UIImage` (typically from `CameraPicker`) into
    /// the same `SelectedPhoto` shape as the library-picker path. Re-encodes
    /// the image as JPEG so the upload pipeline stays format-agnostic.
    func loadPhoto(from image: UIImage, role: ImageRole) {
        let compressed = ImageUploadCompressor.compress(image)
        guard !compressed.data.isEmpty else {
            errorMessage = "FilmPost couldn't process that camera capture. Try again."
            return
        }

        let photo = SelectedPhoto(
            role: role,
            data: compressed.data,
            filename: "\(role.filenameStem).jpg",
            mimeType: "image/jpeg",
            previewImage: compressed.previewImage
        )

        assign(photo, to: role)
        analysis = nil
        errorMessage = nil
    }

    func analyze() async {
        guard let subjectPhoto, let backgroundPhoto else { return }

        // Belt-and-braces: if a previous task is somehow still around, drop it
        // before starting a new one so two requests can't race the same state.
        analysisTask?.cancel()

        isAnalyzing = true
        errorMessage = nil

        let subjectUpload = ImageUpload(
            data: subjectPhoto.data,
            filename: subjectPhoto.filename,
            mimeType: subjectPhoto.mimeType
        )
        let backgroundUpload = ImageUpload(
            data: backgroundPhoto.data,
            filename: backgroundPhoto.filename,
            mimeType: backgroundPhoto.mimeType
        )

        let task = Task { [apiClient] in
            await runAnalyze(
                client: apiClient,
                subject: subjectUpload,
                background: backgroundUpload
            )
        }
        analysisTask = task
        await task.value
        analysisTask = nil
    }

    /// Cancels an in-flight analyze request. The URLSession data task gets
    /// cancelled, which surfaces as `URLError.cancelled` -> `.cancelled` in
    /// the API client; we treat that as a user-initiated reset and silently
    /// drop back to the upload screen.
    func cancelAnalysis() {
        analysisTask?.cancel()
    }

    private func runAnalyze(
        client: FilmPostAPIClientProtocol,
        subject: ImageUpload,
        background: ImageUpload
    ) async {
        do {
            analysis = try await client.analyze(subject: subject, background: background)
        } catch FilmPostAPIError.cancelled {
            // User tapped Cancel — silently drop back to the upload screen
            // without surfacing a scary-looking error banner.
            analysis = nil
            errorMessage = nil
        } catch let error as FilmPostAPIError {
            errorMessage = error.errorDescription
            analysis = nil
        } catch is CancellationError {
            analysis = nil
            errorMessage = nil
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
