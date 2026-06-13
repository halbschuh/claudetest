import SwiftUI
import MapKit

struct SpaziergangDetailView: View {
    let spaziergangID: Int
    let repository: SpaziergaengeRepositoryProtocol

    @State private var spaziergang: Spaziergang?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedWaypoint: Waypoint?
    @State private var audioPlayer = AudioPlayerViewModel()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.0504, longitude: 13.7373),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let msg = errorMessage {
                ContentUnavailableView(msg, systemImage: "exclamationmark.triangle")
            } else if let walk = spaziergang {
                content(walk)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
        .onDisappear { audioPlayer.stop() }
    }

    private func content(_ walk: Spaziergang) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let url = walk.coverImageURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill().frame(height: 220).clipped()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(walk.title)
                        .font(.title2.bold())

                    HStack(spacing: 20) {
                        Label("\(walk.durationMinutes) Min.", systemImage: "clock")
                        Label(String(format: "%.1f km", Double(walk.distanceMeters) / 1000),
                              systemImage: "arrow.triangle.swap")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.appSepia)

                    Text(walk.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()

                routeMap(walk)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                Text("Wegpunkte")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 20)

                LazyVStack(spacing: 0) {
                    ForEach(walk.waypoints.sorted(by: { $0.sortOrder < $1.sortOrder })) { waypoint in
                        WaypointRow(
                            waypoint: waypoint,
                            isSelected: selectedWaypoint?.id == waypoint.id,
                            audioPlayer: audioPlayer
                        )
                        .onTapGesture {
                            withAnimation { selectedWaypoint = waypoint }
                        }
                        Divider().padding(.leading, 56)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(walk.title)
    }

    private func routeMap(_ walk: Spaziergang) -> some View {
        Map(coordinateRegion: $mapRegion, annotationItems: walk.waypoints) { waypoint in
            MapAnnotation(coordinate: waypoint.coordinate.clLocation) {
                ZStack {
                    Circle()
                        .fill(selectedWaypoint?.id == waypoint.id ? Color.appSepia : Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 3)
                    Text("\(waypoint.sortOrder + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(selectedWaypoint?.id == waypoint.id ? .white : Color.appSepia)
                }
                .onTapGesture { withAnimation { selectedWaypoint = waypoint } }
            }
        }
    }

    private func loadDetail() async {
        do {
            spaziergang = try await repository.fetchDetail(id: spaziergangID)
            if let first = spaziergang?.waypoints.first {
                mapRegion.center = first.coordinate.clLocation
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct WaypointRow: View {
    let waypoint: Waypoint
    let isSelected: Bool
    let audioPlayer: AudioPlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appSepia : Color.appSepia.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text("\(waypoint.sortOrder + 1)")
                        .font(.callout.bold())
                        .foregroundStyle(isSelected ? .white : Color.appSepia)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(waypoint.title)
                        .font(.headline)
                    if isSelected {
                        Text(waypoint.bodyText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isSelected, let audioURL = waypoint.audioURL {
                AudioPlayerBar(url: audioURL, player: audioPlayer)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .background(isSelected ? Color.appSepia.opacity(0.06) : Color.clear)
    }
}

private struct AudioPlayerBar: View {
    let url: URL
    let player: AudioPlayerViewModel

    var isCurrentlyPlaying: Bool {
        player.currentURL == url && player.isPlaying
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                player.toggle(url: url)
            } label: {
                Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.appSepia)
            }

            VStack(spacing: 4) {
                ProgressView(value: player.currentURL == url ? player.progress : 0)
                    .tint(Color.appSepia)

                HStack {
                    Text(player.currentURL == url ? player.currentTimeDisplay : "0:00")
                    Spacer()
                    Text(player.currentURL == url ? player.totalTimeDisplay : "--:--")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
