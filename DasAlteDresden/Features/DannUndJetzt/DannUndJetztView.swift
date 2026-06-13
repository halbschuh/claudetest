import SwiftUI

struct DannUndJetztView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var viewModel: DannUndJetztViewModel?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel?.state {
                case .loading, .idle, .none:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .error(let msg):
                    ContentUnavailableView(msg, systemImage: "exclamationmark.triangle")

                case .loaded(let items) where items.isEmpty:
                    ContentUnavailableView("Noch keine Vergleiche", systemImage: "photo.on.rectangle.angled")

                case .loaded(let items):
                    List(items) { item in
                        NavigationLink(value: item) {
                            DannUndJetztRow(item: item)
                        }
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel?.reload() }
                }
            }
            .navigationTitle("Dann & Jetzt")
            .navigationDestination(for: DannUndJetzt.self) { item in
                DannUndJetztDetailView(item: item)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = DannUndJetztViewModel(
                    repository: DannUndJetztRepository(apiClient: env.apiClient)
                )
            }
            await viewModel?.load()
        }
    }
}

private struct DannUndJetztRow: View {
    let item: DannUndJetzt

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: item.historicalImageURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appParchment)
                        .frame(height: 160)
                }
            }

            Text(item.caption)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let year = item.historicalYear {
                Text("Historisch: \(year)")
                    .font(.caption)
                    .foregroundStyle(Color.appSepia)
            }
        }
    }
}
