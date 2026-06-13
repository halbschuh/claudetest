import SwiftUI

struct RegisterView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var viewModel: AuthViewModel?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("E-Mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Passwort (mind. 8 Zeichen)", text: $password)
                        .textContentType(.newPassword)
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
                        Task {
                            await viewModel?.register(name: name, email: email, password: password)
                            if case .idle = viewModel?.state { dismiss() }
                        }
                    } label: {
                        if case .loading = viewModel?.state {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Registrieren").frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty || password.count < 8 || viewModel?.state == .loading)
                }
            }
            .navigationTitle("Konto erstellen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .onAppear {
                viewModel = AuthViewModel(apiClient: env.apiClient, authStore: env.authStore)
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
