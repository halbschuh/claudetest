import Foundation

struct LexikonEntry: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let title: String
    let teaser: String
    let bodyHTML: String
    let imageURLs: [URL]
    let linkedOrtIDs: [Int]
    let updatedAt: Date
}

struct LexikonListItem: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let title: String
    let teaser: String
    let thumbnailURL: URL?
}
