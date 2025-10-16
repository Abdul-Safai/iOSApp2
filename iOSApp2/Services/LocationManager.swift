import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentAddress: String? = nil
    @Published var lastLocation: CLLocation? = nil

    // one-shot continuation used by getFreshAddress()
    private var continuation: CheckedContinuation<(String?, Double?, Double?), Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func requestLocation() { manager.requestLocation() }

    /// Ask Core Location for a fresh fix and return (address, lat, lon) when ready.
    @MainActor
    func getFreshAddress() async -> (String?, Double?, Double?) {
        // If we already have something, return immediately while also requesting an update
        if let loc = lastLocation {
            requestLocation()
            return (currentAddress, loc.coordinate.latitude, loc.coordinate.longitude)
        }

        // Otherwise wait for the next update (reverse-geocoded)
        return await withCheckedContinuation { (cont: CheckedContinuation<(String?, Double?, Double?), Never>) in
            self.continuation = cont
            self.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate (Swift 6 requires nonisolated)
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        // Save on main actor
        Task { @MainActor in
            self.lastLocation = loc
        }

        // Reverse geocode, then resume continuation if someone is waiting
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
            let p = placemarks?.first
            var parts: [String] = []
            if let street = p?.thoroughfare { parts.append(street) }
            if let city   = p?.locality { parts.append(city) }
            if let state  = p?.administrativeArea { parts.append(state) }
            if let zip    = p?.postalCode { parts.append(zip) }
            let addr = parts.isEmpty ? nil : parts.joined(separator: ", ")

            Task { @MainActor in
                self.currentAddress = addr

                if let cont = self.continuation {
                    self.continuation = nil
                    cont.resume(returning: (addr, loc.coordinate.latitude, loc.coordinate.longitude))
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
        Task { @MainActor in
            if let cont = self.continuation {
                self.continuation = nil
                cont.resume(returning: (nil, nil, nil))
            }
        }
    }
}
