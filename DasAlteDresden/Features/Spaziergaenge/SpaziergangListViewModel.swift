import Foundation

@Observable
final class SpaziergangListViewModel {
    enum State {
        case idle, loading, loaded([SpaziergangListItem]), error(String)
    }

    private(set) var state: State = .idle
    private let repository: SpaziergaengeRepositoryProtocol

    init(repository: SpaziergaengeRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            state = .loaded(try await repository.fetchList())
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func reload() async {
        state = .idle
        await load()
    }
}
