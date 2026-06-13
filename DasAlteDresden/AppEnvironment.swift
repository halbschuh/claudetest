import Foundation

@Observable
final class AppEnvironment {
    let apiClient: APIClient
    let authStore: AuthStore

    init() {
        let auth = AuthStore()
        self.authStore = auth
        self.apiClient = APIClient(authStore: auth)
    }
}
