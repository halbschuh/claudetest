import Foundation

struct KalenderEvent: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let historicalDate: Date
    let description: String
    let ortID: Int?
    let tags: [String]
    let imageURL: URL?
}
