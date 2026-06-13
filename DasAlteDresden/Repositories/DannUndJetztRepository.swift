import Foundation

protocol DannUndJetztRepositoryProtocol {
    func fetchAll() async throws -> [DannUndJetzt]
}

final class DannUndJetztRepository: DannUndJetztRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchAll() async throws -> [DannUndJetzt] {
        try await apiClient.fetch(.dannUndJetzt)
    }
}
