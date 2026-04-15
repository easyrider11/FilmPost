import Foundation

public enum MultipartFormDataBuilder {
    public static func makeAnalyzeBody(
        subjectData: Data,
        subjectFilename: String,
        subjectMimeType: String,
        backgroundData: Data,
        backgroundFilename: String,
        backgroundMimeType: String,
        boundary: String
    ) throws -> Data {
        var data = Data()

        appendField(
            named: "subject_image",
            filename: subjectFilename,
            mimeType: subjectMimeType,
            value: subjectData,
            boundary: boundary,
            into: &data
        )

        appendField(
            named: "background_image",
            filename: backgroundFilename,
            mimeType: backgroundMimeType,
            value: backgroundData,
            boundary: boundary,
            into: &data
        )

        data.append("--\(boundary)--\r\n".utf8Data)
        return data
    }

    private static func appendField(
        named name: String,
        filename: String,
        mimeType: String,
        value: Data,
        boundary: String,
        into data: inout Data
    ) {
        data.append("--\(boundary)\r\n".utf8Data)
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".utf8Data)
        data.append("Content-Type: \(mimeType)\r\n\r\n".utf8Data)
        data.append(value)
        data.append("\r\n".utf8Data)
    }
}

private extension String {
    var utf8Data: Data {
        Data(utf8)
    }
}
