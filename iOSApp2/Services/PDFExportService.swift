import Foundation
import UIKit
import MapKit

enum PDFExportService {

    // MARK: - Public (WITH MAP)
    static func createReportWithMap(items: [HuntItem],
                                    progress: [UUID: HuntProgress],
                                    author: String = "Scavenger Hunt") async throws -> URL {

        // Preload map snapshots for all items that have coords
        var mapImages: [UUID: UIImage] = [:]
        for item in items {
            if let hp = progress[item.id],
               let lat = hp.latitude, let lon = hp.longitude {
                if let img = try? await snapshot(lat: lat, lon: lon) {
                    mapImages[item.id] = img
                }
            }
        }

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

                    // Details (include address + coordinates)
                    let coordText: String
                    if let la = hp.latitude, let lo = hp.longitude {
                        coordText = String(format: "%.5f, %.5f", la, lo)
                    } else {
                        coordText = "—"
                    }
                    let details = """
                    Address: \(hp.address ?? item.address)
                    Clue: \(item.clue)
                    Photo Date: \(df.string(from: hp.foundDate ?? Date()))
                    Coordinates: \(coordText)
                    """
                    (details as NSString).draw(in: CGRect(x: 24, y: 56, width: pageW-48, height: 110), withAttributes: bodyAttrs)

                    // Photo
                    let top: CGFloat = 180
                    let maxW = pageW - 48, maxH = pageH - (top + 36 + 210) // leave room for map
                    let ratio = max(image.size.width, 1) / max(image.size.height, 1)
                    var w = maxW, h = w / ratio
                    if h > maxH { h = maxH; w = h * ratio }
                    let photoRect = CGRect(x: (pageW - w)/2, y: top, width: w, height: h)
                    image.draw(in: photoRect)

                    // Map (if available)
                    if let map = mapImages[item.id] {
                        let mapSize = CGSize(width: 300, height: 200)
                        let mapRect = CGRect(x: (pageW - mapSize.width)/2,
                                             y: photoRect.maxY + 10,
                                             width: mapSize.width,
                                             height: mapSize.height)
                        map.draw(in: mapRect)
                    }
                }
            }
        }

        let ts = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ScavengerReport-\(ts).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func createSingleItemReportWithMap(item: HuntItem, hp: HuntProgress) async throws -> URL {
        let pageW: CGFloat = 612, pageH: CGFloat = 792

        // Snapshot if we have coordinates
        var mapImage: UIImage? = nil
        if let la = hp.latitude, let lo = hp.longitude {
            mapImage = try? await snapshot(lat: la, lon: lo)
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let title: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 20)]
            (item.name as NSString).draw(in: CGRect(x:24, y:24, width: pageW-48, height: 26), withAttributes: title)

            let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short
            let coordText: String = {
                if let la = hp.latitude, let lo = hp.longitude {
                    return String(format: "%.5f, %.5f", la, lo)
                }
                return "—"
            }()

            let body = """
            Address: \(hp.address ?? item.address)
            Clue: \(item.clue)
            Photo Date: \(df.string(from: hp.foundDate ?? Date()))
            Coordinates: \(coordText)
            """
            (body as NSString).draw(in: CGRect(x:24, y:56, width: pageW-48, height: 110),
                                    withAttributes: [.font: UIFont.systemFont(ofSize: 14)])

            // Photo
            if let b64 = hp.imageDataBase64, let data = Data(base64Encoded: b64),
               let img = UIImage(data: data) {
                let top: CGFloat = 180
                let maxW = pageW - 48, maxH = pageH - (top + 36 + 210) // leave space for map
                let r = max(img.size.width,1)/max(img.size.height,1)
                var w = maxW, h = w / r
                if h > maxH { h = maxH; w = h * r }
                let photoRect = CGRect(x: (pageW - w)/2, y: top, width: w, height: h)
                img.draw(in: photoRect)

                // Map below photo
                if let mapImage {
                    let mapSize = CGSize(width: 300, height: 200)
                    let mapRect = CGRect(x: (pageW - mapSize.width)/2,
                                         y: photoRect.maxY + 10,
                                         width: mapSize.width,
                                         height: mapSize.height)
                    mapImage.draw(in: mapRect)
                }
            } else {
                let placeholder = "No image captured yet."
                (placeholder as NSString).draw(at: CGPoint(x: 24, y: 180),
                                               withAttributes: [.font: UIFont.italicSystemFont(ofSize: 14)])
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Item-\(item.id).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Legacy (no map) — keep if other code still calls these
    static func createReport(items: [HuntItem], progress: [UUID: HuntProgress], author: String = "Scavenger Hunt") throws -> URL {
        // simple wrapper that calls the map version synchronously using a Task
        var outURL: URL!
        let sema = DispatchSemaphore(value: 0)
        Task {
            outURL = try? await createReportWithMap(items: items, progress: progress, author: author)
            sema.signal()
        }
        sema.wait()
        return outURL
    }

    static func createSingleItemReport(item: HuntItem, hp: HuntProgress) throws -> URL {
        var outURL: URL!
        let sema = DispatchSemaphore(value: 0)
        Task {
            outURL = try? await createSingleItemReportWithMap(item: item, hp: hp)
            sema.signal()
        }
        sema.wait()
        return outURL
    }

    // MARK: - Helpers
    private static func snapshot(lat: Double, lon: Double) async throws -> UIImage {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        options.size = CGSize(width: 300, height: 200)
        let shot = MKMapSnapshotter(options: options)
        let snap = try await shot.start()
        return snap.image
    }
}
