import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int)
    case decodingError(Error)
    case unauthorized
    case notFound
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "Ungültige URL"
        case .networkError(let e):      return "Netzwerkfehler: \(e.localizedDescription)"
        case .httpError(let code):      return "HTTP-Fehler \(code)"
        case .decodingError(let e):     return "Datenfehler: \(e.localizedDescription)"
        case .unauthorized:             return "Nicht angemeldet"
        case .notFound:                 return "Nicht gefunden"
        case .serverError(let msg):     return msg
        }
    }
}
