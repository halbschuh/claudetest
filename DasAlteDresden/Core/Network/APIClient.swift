import Foundation

protocol APIClientProtocol {
    func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func post(_ endpoint: APIEndpoint) async throws
}

final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let authStore: AuthStore

    init(authStore: AuthStore) {
        self.authStore = authStore
        self.session = URLSession.shared
        self.decoder = {
            let d = JSONDecoder()
            d.keyDecodingStrategy = .convertFromSnakeCase
            d.dateDecodingStrategy = .iso8601
            return d
        }()
    }

    func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        do {
            return try decoder.decode(APIEnvelope<T>.self, from: data).data
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func post(_ endpoint: APIEndpoint) async throws {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
    }

    // MARK: - Private

    private func buildRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        var req = URLRequest(url: endpoint.url)
        req.httpMethod = endpoint.method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth {
            guard let token = authStore.accessToken else { throw APIError.unauthorized }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        switch endpoint {
        case .login(let email, let password):
            req.httpBody = try JSONEncoder().encode(["email": email, "password": password])
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case .register(let email, let password, let name):
            req.httpBody = try JSONEncoder().encode(["email": email, "password": password, "name": name])
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case .refreshToken(let token):
            req.httpBody = try JSONEncoder().encode(["refresh_token": token])
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case .strassenbuchIdentify(_, let guess):
            req.httpBody = try JSONEncoder().encode(["guess": guess])
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        case .uploadFoto(let data, let metadata):
            let boundary = UUID().uuidString
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            req.httpBody = multipartBody(imageData: data, metadata: metadata, boundary: boundary)

        default:
            break
        }

        return req
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        switch http.statusCode {
        case 200...299: return
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        default:
            let message = (try? decoder.decode(APIErrorResponse.self, from: data))?.message
            throw message.map { APIError.serverError(message: $0) } ?? APIError.httpError(statusCode: http.statusCode)
        }
    }

    private func multipartBody(imageData: Data, metadata: FotoUploadMetadata, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        func str(_ s: String) { body.append(Data(s.utf8)) }

        str("--\(boundary)\(crlf)")
        str("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\(crlf)")
        str("Content-Type: image/jpeg\(crlf)\(crlf)")
        body.append(imageData)
        str(crlf)

        if let encoded = try? JSONEncoder().encode(metadata) {
            str("--\(boundary)\(crlf)")
            str("Content-Disposition: form-data; name=\"metadata\"\(crlf)")
            str("Content-Type: application/json\(crlf)\(crlf)")
            body.append(encoded)
            str(crlf)
        }

        str("--\(boundary)--\(crlf)")
        return body
    }
}

private struct APIEnvelope<T: Decodable>: Decodable {
    let data: T
}

private struct APIErrorResponse: Decodable {
    let message: String
}
