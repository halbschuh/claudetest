import Foundation

struct UserPhoto: Codable, Identifiable, Hashable {
    let id: Int
    let uploaderName: String?
    let locationDescription: String
    let coordinate: Coordinate?
    let ortID: Int?
    let imageURL: URL
    let status: SubmissionStatus
    let submittedAt: Date
}

struct StrassenbuchItem: Codable, Identifiable, Hashable {
    let id: Int
    let imageURL: URL
    let knownLocation: String?
    let approximateYear: Int?
    let identificationCount: Int
}

enum SubmissionStatus: String, Codable {
    case pending, approved, rejected
}
