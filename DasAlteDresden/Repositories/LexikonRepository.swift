import Foundation
import SwiftData

protocol LexikonRepositoryProtocol {
    func fetchList() async throws -> [LexikonListItem]
    func fetchDetail(slug: String) async throws -> LexikonEntry
}

final class LexikonRepository: LexikonRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let modelContext: ModelContext

    init(apiClient: APIClientProtocol, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    func fetchList() async throws -> [LexikonListItem] {
        let items: [LexikonListItem] = try await apiClient.fetch(.lexikonList)
        persistList(items)
        return items
    }

    func fetchDetail(slug: String) async throws -> LexikonEntry {
        let entry: LexikonEntry = try await apiClient.fetch(.lexikonDetail(slug: slug))
        persistDetail(entry)
        return entry
    }

    // MARK: - Cache persistence

    private func persistList(_ items: [LexikonListItem]) {
        for item in items {
            let cached = CachedLexikonEntry(
                slug: item.slug,
                title: item.title,
                teaser: item.teaser,
                bodyHTML: "",
                updatedAt: Date()
            )
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }

    private func persistDetail(_ entry: LexikonEntry) {
        let descriptor = FetchDescriptor<CachedLexikonEntry>(
            predicate: #Predicate { $0.slug == entry.slug }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.title = entry.title
            existing.teaser = entry.teaser
            existing.bodyHTML = entry.bodyHTML
            existing.updatedAt = entry.updatedAt
            existing.fetchedAt = Date()
        } else {
            modelContext.insert(CachedLexikonEntry(
                slug: entry.slug,
                title: entry.title,
                teaser: entry.teaser,
                bodyHTML: entry.bodyHTML,
                updatedAt: entry.updatedAt
            ))
        }
        try? modelContext.save()
    }
}
