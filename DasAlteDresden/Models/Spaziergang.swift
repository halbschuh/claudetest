import Foundation

struct Spaziergang: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let durationMinutes: Int
    let distanceMeters: Int
    let coverImageURL: URL?
    let waypoints: [Waypoint]
    let tags: [String]
}

struct Waypoint: Codable, Identifiable, Hashable {
    let id: Int
    let coordinate: Coordinate
    let title: String
    let bodyText: String
    let audioURL: URL?
    let imageURLs: [URL]
    let sortOrder: Int
}

struct SpaziergangListItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let durationMinutes: Int
    let distanceMeters: Int
    let coverImageURL: URL?
    let tags: [String]
}
