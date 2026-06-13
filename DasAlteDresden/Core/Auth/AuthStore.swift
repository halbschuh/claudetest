import Foundation

@Observable
final class AuthStore {
    private enum Keys {
        static let accessToken = "dad.accessToken"
        static let refreshToken = "dad.refreshToken"
    }

    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    var isAuthenticated: Bool { accessToken != nil }

    init() {
        accessToken = KeychainService.load(forKey: Keys.accessToken)
        refreshToken = KeychainService.load(forKey: Keys.refreshToken)
    }

    func store(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        KeychainService.save(accessToken, forKey: Keys.accessToken)
        KeychainService.save(refreshToken, forKey: Keys.refreshToken)
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        KeychainService.delete(forKey: Keys.accessToken)
        KeychainService.delete(forKey: Keys.refreshToken)
    }
}
