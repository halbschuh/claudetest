import Foundation

@Observable
final class DannUndJetztViewModel {
    enum State {
        case idle, loading, loaded([DannUndJetzt]), error(String)
    }

    private(set) var state: State = .idle
    private let repository: DannUndJetztRepositoryProtocol

    init(repository: DannUndJetztRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            let items = try await repository.fetchAll()
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
