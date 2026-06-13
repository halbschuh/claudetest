import Foundation
import CoreLocation

@Observable
final class FotoUploadViewModel: NSObject {
    enum State {
        case idle, uploading, success, error(String)
    }

    private(set) var state: State = .idle
    var locationDescription = ""
    var uploaderName = ""
    var includeGPS = false

    private(set) var detectedLocation: CLLocationCoordinate2D?
    private let repository: FotoRepositoryProtocol
    private let locationManager = CLLocationManager()

    init(repository: FotoRepositoryProtocol) {
        self.repository = repository
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func upload(imageData: Data) async {
        guard !locationDescription.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        state = .uploading

        let metadata = FotoUploadMetadata(
            locationDescription: locationDescription,
            uploaderName: uploaderName.isEmpty ? nil : uploaderName,
            latitude: includeGPS ? detectedLocation?.latitude : nil,
            longitude: includeGPS ? detectedLocation?.longitude : nil,
            ortID: nil
        )

        do {
            _ = try await repository.upload(imageData: imageData, metadata: metadata)
            state = .success
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func requestLocationIfNeeded() {
        guard includeGPS else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: locationManager.requestLocation()
        default: break
        }
    }

    func reset() {
        state = .idle
        locationDescription = ""
        uploaderName = ""
        includeGPS = false
        detectedLocation = nil
    }
}

extension FotoUploadViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        detectedLocation = locations.last?.coordinate
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
