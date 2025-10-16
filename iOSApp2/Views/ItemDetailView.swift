import SwiftUI
import PhotosUI
import UIKit

struct ItemDetailView: View {
    @EnvironmentObject var vm: HuntViewModel
    @StateObject private var locationManager = LocationManager()

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
                frontContent
            } back: {
                backContent
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.flip()
                withAnimation(.easeInOut) { flipped.toggle() }
            }
            .padding()
        }
        .navigationTitle(item.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if vm.isFound(item), let hp = vm.progress[item.id] {
                    Button("Save as PDF") {
                        Task {
                            if let url = try? await PDFExportService.createSingleItemReportWithMap(item: item, hp: hp) {
                                shareURL = url
                                showShare = true
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { image in
                guard let image else { return }
                Task {
                    let (addr, lat, lon) = await locationManager.getFreshAddress()
                    vm.markFound(item, image: image, address: addr, latitude: lat, longitude: lon)
                    Haptics.marked()
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL { ShareSheet(activityItems: [url]) }
        }
        .onChange(of: selectedItem) { newValue in
            Task {
                guard let newValue,
                      let data = try? await newValue.loadTransferable(type: Data.self),
                      let ui = UIImage(data: data) else { return }

                let (addr, lat, lon) = await locationManager.getFreshAddress()
                vm.markFound(item, image: ui, address: addr, latitude: lat, longitude: lon)
                Haptics.marked()
            }
        }
    }

    // MARK: - Subviews
    private var frontContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.name).font(.title2.bold())
            Text(item.address).font(.subheadline).foregroundStyle(.secondary)
            Divider()
            Text("About").font(.headline)
            Text(item.description)
            Divider()
            Text("Clue").font(.headline)
            Text(item.clue).italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var backContent: some View {
        VStack(spacing: 12) {
            photoPreview
            pickerButtons

            if vm.isFound(item) {
                Button(role: .destructive) {
                    vm.clearFound(item)        // <-- works because clearFound exists on HuntViewModel
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
    }

    private var photoPreview: some View {
        Group {
            if let img = vm.image(for: item) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.separator, lineWidth: 0.5))
                    .accessibilityLabel("Saved photo for \(item.name)")
            } else {
                ContentUnavailableView(
                    "No Photo Yet",
                    systemImage: "photo.on.rectangle",
                    description: Text("Pick from library or take a photo.")
                )
                .frame(height: 220)
            }
        }
    }

    private var pickerButtons: some View {
        HStack {
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                Label("Library", systemImage: "photo")
            }
            .buttonStyle(.borderedProminent)

            Button {
                showCamera = true
            } label: {
                Label("Camera", systemImage: "camera")
            }
            .buttonStyle(.bordered)
            .disabled(!isCameraAvailable)
            .help(isCameraAvailable ? "" : "Camera not available in Simulator")
        }
    }
}
