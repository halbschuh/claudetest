import SwiftUI

struct LoginView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var viewModel: AuthViewModel?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("E-Mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Passwort", text: $password)
                        .textContentType(.password)
                }

                if case .error(let msg) = viewModel?.state {
                    Section {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                Section {
                    Button {
                        Task { await viewModel?.login(email: email, password: password) }
                    } label: {
                        if case .loading = viewModel?.state {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Anmelden")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || viewModel?.state == .loading)
                }

                Section {
                    Button("Noch kein Konto? Jetzt registrieren") {
                        showRegister = true
                    }
                    .foregroundStyle(Color.appSepia)
                }
            }
            .navigationTitle("Anmelden")
            .onAppear {
                viewModel = AuthViewModel(apiClient: env.apiClient, authStore: env.authStore)
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

private extension Optional where Wrapped == AuthViewModel.State {
    static func == (lhs: Self, rhs: AuthViewModel.State) -> Bool {
        guard case .loading = lhs else { return false }
        guard case .loading = rhs else { return false }
        return true
    }
}
