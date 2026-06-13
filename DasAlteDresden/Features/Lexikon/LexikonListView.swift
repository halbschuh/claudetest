import SwiftUI

struct LexikonListView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LexikonListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Lexikon")
        }
        .task {
            guard viewModel == nil else { return }
            let repo = LexikonRepository(apiClient: env.apiClient, modelContext: modelContext)
            viewModel = LexikonListViewModel(repository: repo)
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(vm: LexikonListViewModel) -> some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView("Lade Lexikon …")

        case .loaded:
            List(vm.filteredItems) { item in
                NavigationLink(value: item) {
                    LexikonRowView(item: item)
                }
            }
            .listStyle(.plain)
            .searchable(text: Bindable(vm).searchText, prompt: "Einträge durchsuchen")
            .refreshable { await vm.reload() }
            .navigationDestination(for: LexikonListItem.self) { item in
                LexikonDetailView(slug: item.slug, title: item.title)
            }

        case .error(let message):
            ContentUnavailableView(
                "Fehler",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .onTapGesture { Task { await vm.reload() } }
        }
    }
}

private struct LexikonRowView: View {
    let item: LexikonListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.appHeadline)
                .foregroundStyle(Color.appSepia)
            Text(item.teaser)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
