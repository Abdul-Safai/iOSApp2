import SwiftUI
import MapKit

struct PlaceMapView: View {
    let name: String
    let lat: Double?
    let lon: Double?

    var body: some View {
        if let lat, let lon {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            Map(initialPosition: .region(.init(center: coord,
                                               span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
                Marker(name, coordinate: coord)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("\(name) map preview")
        }
    }
}
