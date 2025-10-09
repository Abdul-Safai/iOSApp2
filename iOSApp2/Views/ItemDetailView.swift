import SwiftUI
import PhotosUI
import UIKit

struct ItemDetailView: View {
    @EnvironmentObject var vm: HuntViewModel
    let item: HuntItem

    @State private var flipped = false
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?

    @State private var shareURL: URL?
    @State private var showShare = false

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        ScrollView {
            FlipCardView(isFlipped: $flipped) {
                // FRONT
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name).font(.title2.bold())
                    Text(item.address).font(.subheadline).foregroundStyle(.secondary)
                    // Small map preview if you have coordinates
                    PlaceMapView(name: item.name, lat: item.lat, lon: item.lon)

                    Divider()
                    Text("About").font(.headline)
                    Text(item.description)
                    Divider()
                    Text("Clue").font(.headline)
                    Text(item.clue).italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } back: {
                // BACK
                VStack(spacing: 12) {
                    if let img = vm.image(for: item) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.separator, lineWidth: 0.5))
                            .accessibilityLabel("Saved photo for \(item.name)")
                    } else {
                        ContentUnavailableView("No Photo Yet",
                                               systemImage: "photo.on.rectangle",
                                               description: Text("Pick from library or take a photo."))
                            .frame(height: 220)
                    }

                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            Label("Pick from Library", systemImage: "photo")
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Pick photo from library")

                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!isCameraAvailable)
                        .help(isCameraAvailable ? "" : "Camera not available in Simulator")
                        .accessibilityLabel("Take a photo")
                    }

                    if vm.isFound(item) {
                        Button(role: .destructive) {
                            vm.clearFound(item)
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                        .accessibilityLabel("Remove saved photo")
                    }
                }
            }
            .contentShape(Rectangle()) // tap anywhere on the card
            .onTapGesture {
                Haptics.flip()
                withAnimation(.easeInOut) { flipped.toggle() }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(flipped ? "Back of card" : "Front of card")
            .accessibilityHint("Double-tap to flip the card.")
            .padding()
        }
        .navigationTitle(item.name)
        .toolbar {
            // Export a single-item PDF if a photo exists
            ToolbarItem(placement: .navigationBarTrailing) {
                if vm.isFound(item), let hp = vm.progress[item.id] {
                    Button("Save as PDF") {
                        do {
                            shareURL = try PDFExportService.createSingleItemReport(item: item, hp: hp)
                            showShare = true
                        } catch {
                            print("PDF export failed:", error.localizedDescription)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image in
                if let image {
                    vm.markFound(item, image: image)
                    Haptics.marked()
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                guard let newValue else { return }
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    vm.markFound(item, image: ui)
                    Haptics.marked()
                }
            }
        }
    }
}
