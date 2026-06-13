import Foundation
import MapKit

@Observable
final class KarteViewModel {
    enum State {
        case idle, loading, loaded([Ort]), error(String)
    }

    private(set) var state: State = .idle
    var selectedOrt: Ort?
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.0504, longitude: 13.7373),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    private let repository: OrteRepositoryProtocol

    init(repository: OrteRepositoryProtocol) {
        self.repository = repository
    }

    var orte: [Ort] {
        guard case .loaded(let o) = state else { return [] }
        return o
    }

    func load() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            let orte = try await repository.fetchAll()
            state = .loaded(orte)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
