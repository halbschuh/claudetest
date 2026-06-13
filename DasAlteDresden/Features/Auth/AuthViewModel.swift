import Foundation

@Observable
final class AuthViewModel {
    enum State {
        case idle, loading, error(String)
    }

    private(set) var state: State = .idle

    private let apiClient: APIClientProtocol
    private let authStore: AuthStore

    init(apiClient: APIClientProtocol, authStore: AuthStore) {
        self.apiClient = apiClient
        self.authStore = authStore
    }

    func login(email: String, password: String) async {
        state = .loading
        do {
            let response: AuthResponse = try await apiClient.fetch(.login(email: email, password: password))
            authStore.store(accessToken: response.accessToken, refreshToken: response.refreshToken)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func register(name: String, email: String, password: String) async {
        state = .loading
        do {
            let response: AuthResponse = try await apiClient.fetch(.register(email: email, password: password, name: name))
            authStore.store(accessToken: response.accessToken, refreshToken: response.refreshToken)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func logout() {
        authStore.clear()
    }
}
