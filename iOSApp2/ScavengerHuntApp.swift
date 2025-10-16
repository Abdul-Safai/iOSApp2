import SwiftUI

@main
struct ScavengerHuntApp: App {
    @StateObject private var vm = HuntViewModel()
    @StateObject private var locationManager = LocationManager()
    var body: some Scene {
        WindowGroup {
            NavigationStack { ItemListView() }
                .environmentObject(vm)
                .environmentObject(locationManager)
        }
    }
}
