import Foundation
import UIKit

struct SelectedPhoto: Identifiable {
    let id = UUID()
    let role: ImageRole
    let data: Data
    let filename: String
    let mimeType: String
    let previewImage: UIImage
}

enum ImageRole: String {
    case subject
    case background

    var title: String {
        switch self {
        case .subject:
            return "Subject"
        case .background:
            return "Background"
        }
    }

    var subtitle: String {
        switch self {
        case .subject:
            return "Portrait or person"
        case .background:
            return "Environment or location"
        }
    }

    var filenameStem: String {
        rawValue
    }
}
