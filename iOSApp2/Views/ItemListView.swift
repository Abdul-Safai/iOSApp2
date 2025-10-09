import SwiftUI
import UIKit

struct ItemListView: View {
    @EnvironmentObject var vm: HuntViewModel
    @State private var showSubmitAlert = false
    @State private var showResetConfirm = false
    @State private var shareURL: URL? = nil
    @State private var showShare = false
    @State private var showSettings = false
    @State private var showCongrats = false

    private var tierLabel: String {
        let n = vm.foundCount
        return n >= 10 ? "20% + Grand Prize"
             : n >= 7  ? "20%"
             : n >= 5  ? "10%"
             : "—"
    }

    var body: some View {
        Group {
            if vm.filtered.isEmpty {
                ContentUnavailableView("No matches",
                                       systemImage: "magnifyingglass",
                                       description: Text("Try a different search."))
                    .padding(.top, 40)
            } else {
                List {
                    Section(header: Text("Locations")) {
                        ForEach(vm.filtered) { item in
                            NavigationLink(value: item) {
                                ItemRow(item: item,
                                        isFound: vm.isFound(item),
                                        thumb: vm.image(for: item))
                            }
                            // Swipe to clear photo
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if vm.isFound(item) {
                                    Button(role: .destructive) { vm.clearFound(item) } label: {
                                        Label("Clear Photo", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .environment(\.defaultMinListRowHeight, 56)
            }
        }
        .navigationTitle("City Scavenger Hunt")
        .searchable(text: $vm.filterText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search locations…")
        .toolbar(content: {
            // TOP RIGHT: Save as PDF + progress ring + settings
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button("Save as PDF") {
                        do {
                            let url = try PDFExportService.createReport(items: vm.items, progress: vm.progress)
                            shareURL = url
                            showShare = true
                        } catch {
                            print("PDF export failed:", error.localizedDescription)
                        }
                    }
                    .fontWeight(.semibold)

                    ProgressRing(progress: Double(vm.foundCount) / 10.0)

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }

            // BOTTOM BAR: Reset left, Submit right (smart label + disabled when 0)
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("Reset Results").fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Spacer(minLength: 16)

                    Button(vm.foundCount > 0 ? "Submit Results (\(tierLabel))" : "Submit Results") {
                        showSubmitAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.foundCount == 0)
                }
                .frame(maxWidth: .infinity)
            }
        })
        .navigationDestination(for: HuntItem.self) { item in
            ItemDetailView(item: item)
        }
        // Share sheet for the full report
        .sheet(isPresented: $showShare) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        // Settings sheet
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(vm)
        }
        // Submit summary with "Copy Code" + inline reset action
        .alert(vm.discountSummary().title, isPresented: $showSubmitAlert) {
            Button("OK", role: .cancel) { }
            if vm.foundCount >= 5 {
                Button("Copy Code") {
                    let msg = vm.discountSummary().message
                    if let code = msg.components(separatedBy: "code: ").last?.split(separator: ".").first {
                        UIPasteboard.general.string = String(code)
                    }
                }
            }
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
        // Simple congrats banner when hitting 10/10
        .onChange(of: vm.foundCount) { _, new in
            if new == 10 {
                showCongrats = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showCongrats = false }
                }
            }
        }
        .overlay(alignment: .top) {
            if showCongrats {
                Text("🎉 All items found! 🎉")
                    .padding(10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showCongrats)
    }
}

struct ItemRow: View {
    let item: HuntItem
    let isFound: Bool
    let thumb: UIImage?

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
            if let thumb {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 0.5))
                    .accessibilityLabel("Photo for \(item.name)")
            }
        }
        .padding(.vertical, 4)
    }
}
