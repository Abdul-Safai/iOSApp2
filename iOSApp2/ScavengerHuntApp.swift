// ScavengerHuntApp.swift
import SwiftUI

@main
struct ScavengerHuntApp: App {
    @StateObject private var vm = HuntViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ItemListView()
            }
            .environmentObject(vm)   // <- inject once at the root
        }
    }
}
