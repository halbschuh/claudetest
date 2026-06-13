import Foundation
import MapKit

// Ort is the hub model: referenced by LexikonEntry, KalenderEvent, DannUndJetzt, Spaziergang, UserPhoto
struct Ort: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let coordinate: Coordinate
    let historicalPeriod: String?
    let thumbnailURL: URL?
    let lexikonSlugs: [String]
    let description: String?
}

struct Coordinate: Codable, Hashable {
    let lat: Double
    let lng: Double

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
