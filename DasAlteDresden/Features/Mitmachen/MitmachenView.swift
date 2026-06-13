import SwiftUI

struct MitmachenView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        NavigationStack {
            List {
                Section("Beitragen") {
                    NavigationLink {
                        FotoUploadView()
                    } label: {
                        Label("Foto hochladen", systemImage: "camera.badge.plus")
                    }
                }

                Section("Entdecken") {
                    NavigationLink {
                        DannUndJetztView()
                    } label: {
                        Label("Dann & Jetzt", systemImage: "photo.on.rectangle.angled")
                    }
                }

                Section("Konto") {
                    if env.authStore.isAuthenticated {
                        Label("Angemeldet", systemImage: "person.crop.circle.fill")
                            .foregroundStyle(Color.appSepia)

                        Button(role: .destructive) {
                            env.authStore.clear()
                        } label: {
                            Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        NavigationLink {
                            LoginView()
                        } label: {
                            Label("Anmelden / Registrieren", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }
            }
            .navigationTitle("Mitmachen")
        }
    }
}
