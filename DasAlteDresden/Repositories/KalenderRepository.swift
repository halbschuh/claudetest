import Foundation
import SwiftData

protocol KalenderRepositoryProtocol {
    func fetchEvents(year: Int, month: Int) async throws -> [KalenderEvent]
    func fetchEvent(id: Int) async throws -> KalenderEvent
}

final class KalenderRepository: KalenderRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let modelContext: ModelContext

    init(apiClient: APIClientProtocol, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    func fetchEvents(year: Int, month: Int) async throws -> [KalenderEvent] {
        let events: [KalenderEvent] = try await apiClient.fetch(.kalender(year: year, month: month))
        persistEvents(events)
        return events
    }

    func fetchEvent(id: Int) async throws -> KalenderEvent {
        return try await apiClient.fetch(.kalenderEvent(id: id))
    }

    private func persistEvents(_ events: [KalenderEvent]) {
        for event in events {
            let cached = CachedKalenderEvent(
                id: event.id,
                title: event.title,
                historicalDate: event.historicalDate,
                description: event.description,
                tags: event.tags
            )
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }
}
