// iOSApp2/Views/Map/PlaceMapView.swift
import SwiftUI
import MapKit

struct PlaceMapView: View {
    let name: String
    let lat: Double?
    let lon: Double?

    var body: some View {
        if let lat, let lon {
            Map(position: .constant(.region(.init(center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                                  latitudinalMeters: 800,
                                                  longitudinalMeters: 800)))) {
                Marker(name, coordinate: .init(latitude: lat, longitude: lon))
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            EmptyView()
        }
    }
}
