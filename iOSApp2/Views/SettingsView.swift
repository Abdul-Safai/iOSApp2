import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: HuntViewModel
    @State private var hapticsOn: Bool = Haptics.enabled

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsOn)
                        .onChange(of: hapticsOn) { _, v in
                            Haptics.enabled = v
                        }
                }
                Section {
                    Button(role: .destructive) {
                        vm.resetAll()
                    } label: {
                        Label("Clear all progress", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
