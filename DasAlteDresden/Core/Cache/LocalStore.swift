import SwiftData
import Foundation

final class LocalStore {
    static let shared = LocalStore()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            CachedLexikonEntry.self,
            CachedKalenderEvent.self,
            CachedOrt.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: config)
    }
}

// MARK: - SwiftData cache models (separate from API response models)

@Model
final class CachedLexikonEntry {
    @Attribute(.unique) var slug: String
    var title: String
    var teaser: String
    var bodyHTML: String
    var updatedAt: Date
    var fetchedAt: Date

    init(slug: String, title: String, teaser: String, bodyHTML: String, updatedAt: Date) {
        self.slug = slug
        self.title = title
        self.teaser = teaser
        self.bodyHTML = bodyHTML
        self.updatedAt = updatedAt
        self.fetchedAt = Date()
    }
}

@Model
final class CachedKalenderEvent {
    @Attribute(.unique) var id: Int
    var title: String
    var historicalDate: Date
    var eventDescription: String
    var tags: [String]
    var fetchedAt: Date

    init(id: Int, title: String, historicalDate: Date, description: String, tags: [String]) {
        self.id = id
        self.title = title
        self.historicalDate = historicalDate
        self.eventDescription = description
        self.tags = tags
        self.fetchedAt = Date()
    }
}

@Model
final class CachedOrt {
    @Attribute(.unique) var id: Int
    var name: String
    var latitude: Double
    var longitude: Double
    var historicalPeriod: String?
    var thumbnailURLString: String?
    var fetchedAt: Date

    init(id: Int, name: String, latitude: Double, longitude: Double, historicalPeriod: String?, thumbnailURL: URL?) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.historicalPeriod = historicalPeriod
        self.thumbnailURLString = thumbnailURL?.absoluteString
        self.fetchedAt = Date()
    }
}
