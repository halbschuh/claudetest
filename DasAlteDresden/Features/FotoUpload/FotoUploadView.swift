import SwiftUI
import PhotosUI

struct FotoUploadView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: FotoUploadViewModel?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: Image?

    var body: some View {
        NavigationStack {
            if env.authStore.isAuthenticated {
                uploadForm
            } else {
                loginGate
            }
        }
    }

    private var uploadForm: some View {
        Form {
            Section {
                photoPickerSection
            }

            Section("Beschreibung") {
                TextField("Wo wurde dieses Foto aufgenommen?", text: Binding(
                    get: { viewModel?.locationDescription ?? "" },
                    set: { viewModel?.locationDescription = $0 }
                ), axis: .vertical)
                .lineLimit(3...6)

                TextField("Dein Name (optional)", text: Binding(
                    get: { viewModel?.uploaderName ?? "" },
                    set: { viewModel?.uploaderName = $0 }
                ))
            }

            Section("Standort") {
                Toggle("GPS-Position hinzufügen", isOn: Binding(
                    get: { viewModel?.includeGPS ?? false },
                    set: { new in
                        viewModel?.includeGPS = new
                        viewModel?.requestLocationIfNeeded()
                    }
                ))

                if viewModel?.includeGPS == true {
                    if let loc = viewModel?.detectedLocation {
                        Label(
                            String(format: "%.5f, %.5f", loc.latitude, loc.longitude),
                            systemImage: "location.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(Color.appSepia)
                    } else {
                        Label("Standort wird ermittelt…", systemImage: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if case .error(let msg) = viewModel?.state {
                Section {
                    Text(msg).foregroundStyle(.red).font(.callout)
                }
            }

            Section {
                uploadButton
            }
        }
        .navigationTitle("Foto hochladen")
        .onChange(of: selectedItem) { _, new in
            Task { await loadPhoto(item: new) }
        }
        .alert("Vielen Dank!", isPresented: Binding(
            get: { viewModel?.state == .success },
            set: { _ in viewModel?.reset(); selectedItem = nil; selectedImage = nil; selectedImageData = nil }
        )) {
            Button("OK") {}
        } message: {
            Text("Dein Foto wird nach einer kurzen Prüfung veröffentlicht.")
        }
    }

    private var photoPickerSection: some View {
        VStack {
            if let image = selectedImage {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    selectedImage == nil ? "Foto auswählen" : "Foto wechseln",
                    systemImage: "photo.badge.plus"
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var uploadButton: some View {
        Button {
            Task {
                guard let data = selectedImageData else { return }
                await viewModel?.upload(imageData: data)
            }
        } label: {
            if case .uploading = viewModel?.state {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Text("Hochladen").frame(maxWidth: .infinity)
            }
        }
        .disabled(!canUpload)
    }

    private var canUpload: Bool {
        guard let vm = viewModel else { return false }
        guard selectedImageData != nil else { return false }
        guard !vm.locationDescription.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard case .uploading = vm.state else { return true }
        return false
    }

    private var loginGate: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(Color.appSepia)

            Text("Anmelden zum Mitmachen")
                .font(.title3.bold())

            Text("Erstelle ein kostenloses Konto, um historische Fotos aus Dresden beizutragen.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            NavigationLink("Anmelden / Registrieren") {
                LoginView()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appSepia)
        }
        .navigationTitle("Foto hochladen")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadPhoto(item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            selectedImageData = data
            if let uiImage = UIImage(data: data) {
                selectedImage = Image(uiImage: uiImage)
            }
        }
    }
}

extension Optional where Wrapped == FotoUploadViewModel.State {
    static func == (lhs: Self, rhs: Wrapped) -> Bool {
        switch (lhs, rhs) {
        case (.some(.uploading), .uploading): return true
        case (.some(.success), .success): return true
        default: return false
        }
    }
}
