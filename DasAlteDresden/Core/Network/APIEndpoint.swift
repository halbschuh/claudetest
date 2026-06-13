import Foundation

enum APIEndpoint {
    // Lexikon
    case lexikonList
    case lexikonDetail(slug: String)

    // Kalender
    case kalender(year: Int, month: Int)
    case kalenderEvent(id: Int)

    // Orte
    case orte
    case ortDetail(id: Int)

    // Dann & Jetzt
    case dannUndJetzt

    // Zeitzeugen
    case zeitzeugen
    case zeitzeugenDetail(id: Int)

    // Straßenbuch
    case strassenbuch
    case strassenbuchIdentify(id: Int, guess: String)

    // Spaziergänge
    case spaziergaenge
    case spaziergangDetail(id: Int)

    // Foto-Upload
    case uploadFoto(data: Data, metadata: FotoUploadMetadata)

    // Auth
    case login(email: String, password: String)
    case register(email: String, password: String, name: String)
    case refreshToken(token: String)
}

struct FotoUploadMetadata: Encodable {
    let locationDescription: String
    let uploaderName: String?
    let latitude: Double?
    let longitude: Double?
    let ortID: Int?
}

extension APIEndpoint {
    static let baseURL = URL(string: "https://das-alte-dresden.de/api/v1")!

    var url: URL {
        switch self {
        case .lexikonList:
            return Self.baseURL.appendingPathComponent("lexikon")
        case .lexikonDetail(let slug):
            return Self.baseURL.appendingPathComponent("lexikon/\(slug)")
        case .kalender(let year, let month):
            return Self.baseURL.appendingPathComponent("kalender")
                .appending(queryItems: [
                    URLQueryItem(name: "year", value: "\(year)"),
                    URLQueryItem(name: "month", value: "\(month)")
                ])
        case .kalenderEvent(let id):
            return Self.baseURL.appendingPathComponent("kalender/\(id)")
        case .orte:
            return Self.baseURL.appendingPathComponent("orte")
        case .ortDetail(let id):
            return Self.baseURL.appendingPathComponent("orte/\(id)")
        case .dannUndJetzt:
            return Self.baseURL.appendingPathComponent("dann-und-jetzt")
        case .zeitzeugen:
            return Self.baseURL.appendingPathComponent("zeitzeugen")
        case .zeitzeugenDetail(let id):
            return Self.baseURL.appendingPathComponent("zeitzeugen/\(id)")
        case .strassenbuch:
            return Self.baseURL.appendingPathComponent("strassenbuch")
        case .strassenbuchIdentify(let id, _):
            return Self.baseURL.appendingPathComponent("strassenbuch/\(id)/identify")
        case .spaziergaenge:
            return Self.baseURL.appendingPathComponent("spaziergaenge")
        case .spaziergangDetail(let id):
            return Self.baseURL.appendingPathComponent("spaziergaenge/\(id)")
        case .uploadFoto:
            return Self.baseURL.appendingPathComponent("fotos")
        case .login:
            return Self.baseURL.appendingPathComponent("auth/login")
        case .register:
            return Self.baseURL.appendingPathComponent("auth/register")
        case .refreshToken:
            return Self.baseURL.appendingPathComponent("auth/refresh")
        }
    }

    var method: String {
        switch self {
        case .strassenbuchIdentify, .uploadFoto, .login, .register, .refreshToken:
            return "POST"
        default:
            return "GET"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .strassenbuchIdentify, .uploadFoto:
            return true
        default:
            return false
        }
    }
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        return components.url!
    }
}
