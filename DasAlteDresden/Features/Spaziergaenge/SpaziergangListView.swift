import SwiftUI

struct SpaziergangListView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: SpaziergangListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel?.state {
                case .loading, .idle, .none:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)

                case .error(let msg):
                    ContentUnavailableView(msg, systemImage: "exclamationmark.triangle")

                case .loaded(let items) where items.isEmpty:
                    ContentUnavailableView("Keine Spaziergänge", systemImage: "figure.walk")

                case .loaded(let items):
                    List(items) { item in
                        NavigationLink(value: item.id) {
                            SpaziergangRow(item: item)
                        }
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel?.reload() }
                }
            }
            .navigationTitle("Spaziergänge")
            .navigationDestination(for: Int.self) { id in
                SpaziergangDetailView(spaziergangID: id, repository: SpaziergaengeRepository(apiClient: env.apiClient))
            }
        }
        .task {
            if viewModel == nil {
                viewModel = SpaziergangListViewModel(
                    repository: SpaziergaengeRepository(apiClient: env.apiClient)
                )
            }
            await viewModel?.load()
        }
    }
}

private struct SpaziergangRow: View {
    let item: SpaziergangListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: item.coverImageURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill().frame(height: 140).clipped()
                default:
                    Color.appParchment.frame(height: 140)
                        .overlay(Image(systemName: "figure.walk").font(.largeTitle).foregroundStyle(Color.appSepia))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12).corners(.top))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)

                HStack(spacing: 16) {
                    Label("\(item.durationMinutes) Min.", systemImage: "clock")
                    Label(String(format: "%.1f km", Double(item.distanceMeters) / 1000), systemImage: "arrow.triangle.swap")
                }
                .font(.caption)
                .foregroundStyle(Color.appSepia)

                if !item.tags.isEmpty {
                    Text(item.tags.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12).corners(.bottom))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.bottom, 4)
    }
}

private extension RoundedRectangle {
    func corners(_ corner: UIRectCorner) -> some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: corner.contains(.topLeft) ? cornerRadius : 0,
            bottomLeadingRadius: corner.contains(.bottomLeft) ? cornerRadius : 0,
            bottomTrailingRadius: corner.contains(.bottomRight) ? cornerRadius : 0,
            topTrailingRadius: corner.contains(.topRight) ? cornerRadius : 0
        )
    }
}
