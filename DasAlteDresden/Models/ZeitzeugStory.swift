import Foundation

struct ZeitzeugStory: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let authorName: String?
    let ortID: Int?
    let teaser: String
    let bodyHTML: String
    let period: String?
    let imageURLs: [URL]
    let publishedAt: Date
}

struct ZeitzeugListItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let authorName: String?
    let teaser: String
    let period: String?
    let thumbnailURL: URL?
}
