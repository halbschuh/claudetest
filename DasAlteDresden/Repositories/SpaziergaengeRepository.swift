import Foundation

protocol SpaziergaengeRepositoryProtocol {
    func fetchList() async throws -> [SpaziergangListItem]
    func fetchDetail(id: Int) async throws -> Spaziergang
}

final class SpaziergaengeRepository: SpaziergaengeRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchList() async throws -> [SpaziergangListItem] {
        try await apiClient.fetch(.spaziergaenge)
    }

    func fetchDetail(id: Int) async throws -> Spaziergang {
        try await apiClient.fetch(.spaziergangDetail(id: id))
    }
}
