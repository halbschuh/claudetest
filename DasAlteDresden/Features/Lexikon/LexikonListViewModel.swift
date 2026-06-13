import Foundation

@Observable
final class LexikonListViewModel {
    enum State {
        case idle, loading, loaded([LexikonListItem]), error(String)
    }

    private(set) var state: State = .idle
    var searchText: String = ""

    private let repository: LexikonRepositoryProtocol

    init(repository: LexikonRepositoryProtocol) {
        self.repository = repository
    }

    var filteredItems: [LexikonListItem] {
        guard case .loaded(let items) = state else { return [] }
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.teaser.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            let items = try await repository.fetchList()
            state = .loaded(items)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func reload() async {
        state = .idle
        await load()
    }
}
