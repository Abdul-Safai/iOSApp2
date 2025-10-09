import Foundation
import UIKit

enum PDFExportService {
    /// Builds a PDF of all FOUND items and returns a temp file URL.
    static func createReport(items: [HuntItem],
                             progress: [UUID: HuntProgress],
                             author: String = "Scavenger Hunt") throws -> URL {
        let found = items.compactMap { item -> (HuntItem, HuntProgress, UIImage)? in
            guard let hp = progress[item.id], hp.found,
                  let b64 = hp.imageDataBase64, let data = Data(base64Encoded: b64),
                  let img = UIImage(data: data) else { return nil }
            return (item, hp, img)
        }

        let pageW: CGFloat = 612, pageH: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageW, height: pageH)

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Scavenger Hunt",
            kCGPDFContextAuthor  as String: author
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { ctx in
            if found.isEmpty {
                ctx.beginPage()
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22)]
                let msg = "No items found yet.\nTake some photos, then export again."
                (msg as NSString).draw(in: CGRect(x: 32, y: 40, width: pageW-64, height: 200), withAttributes: attrs)
            } else {
                let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 20)]
                let bodyAttrs:  [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
                let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short

                for (item, hp, image) in found {
                    ctx.beginPage()

                    // Title
                    (item.name as NSString).draw(in: CGRect(x: 24, y: 24, width: pageW-48, height: 26), withAttributes: titleAttrs)

                    // Details
                    let details = """
                    Address: \(item.address)
                    Clue: \(item.clue)
                    Photo Date: \(df.string(from: hp.foundDate ?? Date()))
                    """
                    (details as NSString).draw(in: CGRect(x: 24, y: 56, width: pageW-48, height: 110), withAttributes: bodyAttrs)

                    // Image (fit)
                    let top: CGFloat = 180
                    let maxW = pageW - 48, maxH = pageH - (top + 36)
                    let ratio = max(image.size.width, 1) / max(image.size.height, 1)
                    var w = maxW, h = w / ratio
                    if h > maxH { h = maxH; w = h * ratio }
                    image.draw(in: CGRect(x: (pageW - w)/2, y: top, width: w, height: h))
                }
            }
        }

        let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ScavengerReport-\(ts).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// One-item PDF (detail screen).
    static func createSingleItemReport(item: HuntItem, hp: HuntProgress) throws -> URL {
        let pageW: CGFloat = 612, pageH: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageW, height: pageH)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let dataOut = renderer.pdfData { ctx in
            ctx.beginPage()
            let title: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 20)]
            (item.name as NSString).draw(in: CGRect(x:24, y:24, width: pageW-48, height: 26), withAttributes: title)

            let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short
            let body = """
            Address: \(item.address)
            Clue: \(item.clue)
            Photo Date: \(df.string(from: hp.foundDate ?? Date()))
            """
            (body as NSString).draw(in: CGRect(x:24, y:56, width: pageW-48, height: 110),
                                    withAttributes: [.font: UIFont.systemFont(ofSize: 14)])

            if let b64 = hp.imageDataBase64, let data = Data(base64Encoded: b64),
               let img = UIImage(data: data) {
                let top: CGFloat = 180
                let maxW = pageW - 48, maxH = pageH - (top + 36)
                let r = max(img.size.width,1)/max(img.size.height,1)
                var w = maxW, h = w / r
                if h > maxH { h = maxH; w = h * r }
                img.draw(in: CGRect(x: (pageW - w)/2, y: top, width: w, height: h))
            } else {
                let placeholder = "No image captured yet."
                (placeholder as NSString).draw(at: CGPoint(x: 24, y: 180), withAttributes: [.font: UIFont.italicSystemFont(ofSize: 14)])
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Item-\(item.id).pdf")
        try dataOut.write(to: url, options: .atomic)
        return url
    }
}
