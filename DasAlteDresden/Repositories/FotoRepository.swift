import Foundation

protocol FotoRepositoryProtocol {
    func upload(imageData: Data, metadata: FotoUploadMetadata) async throws -> UserPhoto
}

final class FotoRepository: FotoRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func upload(imageData: Data, metadata: FotoUploadMetadata) async throws -> UserPhoto {
        try await apiClient.fetch(.uploadFoto(data: imageData, metadata: metadata))
    }
}
