import SwiftUI

struct LexikonDetailView: View {
    let slug: String
    let title: String

    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LexikonDetailViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            guard viewModel == nil else { return }
            let repo = LexikonRepository(apiClient: env.apiClient, modelContext: modelContext)
            viewModel = LexikonDetailViewModel(slug: slug, repository: repo)
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(vm: LexikonDetailViewModel) -> some View {
        switch vm.state {
        case .loading:
            ProgressView("Lade Eintrag …")

        case .loaded(let entry):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !entry.imageURLs.isEmpty {
                        TabView {
                            ForEach(entry.imageURLs, id: \.self) { url in
                                AsyncImageView(url: url)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipped()
                            }
                        }
                        .tabViewStyle(.page)
                        .frame(height: 220)
                    }

                    RichTextView(html: entry.bodyHTML)
                        .padding(.horizontal)
                }
            }

        case .error(let message):
            ContentUnavailableView(
                "Fehler",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}
