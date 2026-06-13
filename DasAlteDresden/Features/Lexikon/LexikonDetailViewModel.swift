import Foundation

@Observable
final class LexikonDetailViewModel {
    enum State {
        case loading, loaded(LexikonEntry), error(String)
    }

    private(set) var state: State = .loading

    private let slug: String
    private let repository: LexikonRepositoryProtocol

    init(slug: String, repository: LexikonRepositoryProtocol) {
        self.slug = slug
        self.repository = repository
    }

    func load() async {
        do {
            let entry = try await repository.fetchDetail(slug: slug)
            state = .loaded(entry)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
