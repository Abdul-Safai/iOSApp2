import SwiftUI

struct ItemListView: View {
    @EnvironmentObject var vm: HuntViewModel
    @State private var showSubmitAlert = false
    @State private var showResetConfirm = false

    var body: some View {
        List {
            Section {
                TextField("Search locations…", text: $vm.filterText)
                    .textFieldStyle(.roundedBorder)
            }

            Section(header: Text("Locations")) {
                ForEach(vm.filtered) { item in
                    NavigationLink(value: item) {
                        ItemRow(item: item, isFound: vm.isFound(item))
                    }
                }
            }
        }
        .navigationTitle("City Scavenger Hunt")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProgressBadge(found: vm.foundCount)
            }

            // Bottom bar with Reset on the left (now with background) and Submit on the right
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    // LEFT: Reset (with background)
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("Reset Results")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent) // gives a filled background
                    .tint(.red) // make it red (destructive style)

                    Spacer(minLength: 16)

                    // RIGHT: Submit
                    Button("Submit Results") { showSubmitAlert = true }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationDestination(for: HuntItem.self) { item in
            ItemDetailView(item: item)
        }
        // Submit summary with inline reset action
        .alert(vm.discountSummary().title, isPresented: $showSubmitAlert) {
            Button("OK", role: .cancel) { }
            Button("Reset Progress", role: .destructive) { vm.resetAll() }
        } message: {
            Text(vm.discountSummary().message)
        }
        // Dedicated Reset confirmation
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { vm.resetAll() }
        } message: {
            Text("This will clear all found items and photos. You can’t undo this.")
        }
    }
}

struct ItemRow: View {
    let item: HuntItem
    let isFound: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFound ? .green.opacity(0.15) : .gray.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: isFound ? "checkmark.seal.fill" : "magnifyingglass.circle")
                    .imageScale(.large)
                    .foregroundStyle(isFound ? .green : .secondary)
            }
            VStack(alignment: .leading) {
                Text(item.name).font(.headline)
                Text(item.address).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ProgressBadge: View {
    let found: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy")
            Text("\(found)/10").monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
