import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: Double = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?

    private let locationManager = CLLocationManager()
    private var headingSamples: [Double] = []
    private let smoothingWindow = 5

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.headingFilter = 2
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    private func smoothedHeading(_ rawHeading: Double) -> Double {
        headingSamples.append(rawHeading)
        if headingSamples.count > smoothingWindow {
            headingSamples.removeFirst()
        }

        let sinSum = headingSamples.reduce(0.0) { $0 + sin($1.toRadians()) }
        let cosSum = headingSamples.reduce(0.0) { $0 + cos($1.toRadians()) }
        let averageRadians = atan2(sinSum, cosSum)
        let averageDegrees = averageRadians.toDegrees()

        return (averageDegrees + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startTracking()
                self.locationError = nil
            case .denied, .restricted:
                self.locationError = "Location access denied. Enable it in Settings to use Vivre Card."
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy < 50 else { return }

        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }

        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        let smoothed = smoothedHeading(heading)

        DispatchQueue.main.async {
            self.currentHeading = smoothed
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = "Location error: \(error.localizedDescription)"
        }
    }
}
