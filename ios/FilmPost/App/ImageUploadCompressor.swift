import UIKit

/// Downscales + JPEG-encodes a `UIImage` for upload to the FilmPost backend.
///
/// **Why both ends compress.** The backend already re-encodes through Pillow
/// at ~1568px on the long edge for OpenAI, but if the iPhone ships a 12 MP
/// HEIC unchanged the upload itself becomes the slow leg of the request —
/// especially on cellular. Capping at 2048px @ q=0.8 keeps comfortable
/// headroom above the backend's 1568px target while typically cutting upload
/// bytes by 4–8x. A 2048px JPEG is also visually indistinguishable from the
/// original at OpenAI's "high" detail tier.
///
/// **Why we re-encode the preview too.** `previewImage` drives all on-screen
/// thumbnails. Holding a 12 MP `UIImage` in memory just to render a 96-pt
/// preview is wasteful; the downscaled image is plenty for the carousel and
/// loading-screen "developing frame" overlays.
enum ImageUploadCompressor {
    static let maxLongEdge: CGFloat = 2048
    static let jpegQuality: CGFloat = 0.8

    struct Output {
        let data: Data
        let previewImage: UIImage
    }

    static func compress(_ image: UIImage) -> Output {
        let resized = downscale(image, maxLongEdge: maxLongEdge)
        let data = resized.jpegData(compressionQuality: jpegQuality) ?? Data()
        return Output(data: data, previewImage: resized)
    }

    private static func downscale(_ image: UIImage, maxLongEdge: CGFloat) -> UIImage {
        // `UIImage.size` is in points; for upload-byte purposes we care about
        // pixels, so multiply by `scale` to get the true long-edge dimension.
        let pixelLongEdge = max(image.size.width, image.size.height) * image.scale
        guard pixelLongEdge > maxLongEdge else { return image }

        let scaleFactor = maxLongEdge / pixelLongEdge
        let targetSize = CGSize(
            width: image.size.width * scaleFactor * image.scale,
            height: image.size.height * scaleFactor * image.scale
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        // We don't need an alpha channel for a JPEG output; opaque rendering
        // is faster and keeps the byte count down.
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
