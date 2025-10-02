import SwiftUI
import PhotosUI
import UIKit

struct ItemDetailView: View {
    @EnvironmentObject var vm: HuntViewModel
    let item: HuntItem
    @State private var flipped = false
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        ScrollView {
            // Tap anywhere on the card to flip
            FlipCardView(isFlipped: $flipped) {
                // FRONT
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.name).font(.title2.bold())
                    Text(item.address).font(.subheadline).foregroundStyle(.secondary)
                    Divider()
                    Text("About").font(.headline)
                    Text(item.description)
                    Divider()
                    Text("Clue").font(.headline)
                    Text(item.clue).italic()
                }
                .padding()
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
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .imageScale(.large)
                            Text("No Photo Yet").font(.headline)
                            Text("Pick from library or take a photo.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 220)
                    }

                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            Label("Pick from Library", systemImage: "photo")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!isCameraAvailable)
                        .help(isCameraAvailable ? "" : "Camera not available in Simulator")
                    }

                    if vm.isFound(item) {
                        Button(role: .destructive) {
                            vm.clearFound(item)
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }
                .padding()
            }
            .padding()
            .contentShape(Rectangle()) // make the whole card tappable
            .onTapGesture {
                withAnimation(.easeInOut) { flipped.toggle() }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(flipped ? "Back of card. Double-tap to flip to front." : "Front of card. Double-tap to flip to back.")
        }
        .navigationTitle(item.name)
        // removed toolbar flip button
        .onChange(of: selectedItem) { _, newValue in
            Task {
                guard let newValue else { return }
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    vm.markFound(item, image: ui)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image in
                if let image { vm.markFound(item, image: image) }
            }
            .ignoresSafeArea()
        }
    }
}
