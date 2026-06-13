import Foundation

struct DannUndJetzt: Codable, Identifiable, Hashable {
    let id: Int
    let ortID: Int
    let historicalImageURL: URL
    let modernImageURL: URL
    let caption: String
    let historicalYear: Int?
    let modernYear: Int?
}
