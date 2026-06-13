import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        TabView {
            LexikonListView()
                .tabItem { Label("Lexikon", systemImage: "book.closed") }

            KalenderView()
                .tabItem { Label("Kalender", systemImage: "calendar") }

            KarteView()
                .tabItem { Label("Karte", systemImage: "map") }
        }
        .tint(Color.appSepia)
    }
}
