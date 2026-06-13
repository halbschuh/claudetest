import Foundation
import SwiftData

protocol OrteRepositoryProtocol {
    func fetchAll() async throws -> [Ort]
    func fetchDetail(id: Int) async throws -> Ort
}

final class OrteRepository: OrteRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let modelContext: ModelContext

    init(apiClient: APIClientProtocol, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Ort] {
        let orte: [Ort] = try await apiClient.fetch(.orte)
        persistOrte(orte)
        return orte
    }

    func fetchDetail(id: Int) async throws -> Ort {
        return try await apiClient.fetch(.ortDetail(id: id))
    }

    private func persistOrte(_ orte: [Ort]) {
        for ort in orte {
            let cached = CachedOrt(
                id: ort.id,
                name: ort.name,
                latitude: ort.coordinate.lat,
                longitude: ort.coordinate.lng,
                historicalPeriod: ort.historicalPeriod,
                thumbnailURL: ort.thumbnailURL
            )
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }
}
