import SwiftUI
import MapKit

struct KarteView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: KarteViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    mapContent(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Historische Karte")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            guard viewModel == nil else { return }
            let repo = OrteRepository(apiClient: env.apiClient, modelContext: modelContext)
            viewModel = KarteViewModel(repository: repo)
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func mapContent(vm: KarteViewModel) -> some View {
        Map(position: Bindable(vm).cameraPosition, selection: Bindable(vm).selectedOrt) {
            ForEach(vm.orte) { ort in
                Annotation(ort.name, coordinate: ort.coordinate.clLocationCoordinate, anchor: .bottom) {
                    OrtAnnotationView(ort: ort, isSelected: vm.selectedOrt?.id == ort.id)
                        .onTapGesture { vm.selectedOrt = ort }
                }
                .tag(ort)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .overlay(alignment: .bottom) {
            if let selected = vm.selectedOrt {
                OrtPreviewCard(ort: selected)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: vm.selectedOrt?.id)
        .overlay(alignment: .center) {
            if case .loading = vm.state {
                ProgressView().padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

private struct OrtAnnotationView: View {
    let ort: Ort
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.appSepia : Color.appSepia.opacity(0.7))
                .frame(width: isSelected ? 18 : 12, height: isSelected ? 18 : 12)
                .shadow(radius: 2)
            Circle()
                .strokeBorder(.white, lineWidth: 2)
                .frame(width: isSelected ? 18 : 12, height: isSelected ? 18 : 12)
        }
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

private struct OrtPreviewCard: View {
    let ort: Ort

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ort.name)
                .font(.appHeadline)
                .foregroundStyle(Color.appSepia)
            if let period = ort.historicalPeriod {
                Text(period)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let desc = ort.description {
                Text(desc)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            NavigationLink("Mehr erfahren") {
                OrtDetailPlaceholderView(ort: ort)
            }
            .font(.caption)
            .foregroundStyle(Color.appSepia)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct OrtDetailPlaceholderView: View {
    let ort: Ort
    var body: some View {
        Text(ort.name)
            .navigationTitle(ort.name)
    }
}
