import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: Double = 0    // Magnetic heading in degrees
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var headingSmoothing: [Double] = []
    private let smoothingWindow = 5
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5              // Update every 5 meters
        locationManager.headingFilter = 2               // Update every 2 degrees
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Public Methods
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
    
    // MARK: - Heading Smoothing
    /// Smooths heading values to prevent jittery compass needle
    private func smoothedHeading(_ rawHeading: Double) -> Double {
        headingSmoothing.append(rawHeading)
        if headingSmoothing.count > smoothingWindow {
            headingSmoothing.removeFirst()
        }
        
        // Circular mean to handle 0/360 wraparound
        let sinSum = headingSmoothing.reduce(0.0) { $0 + sin($1.toRadians()) }
        let cosSum = headingSmoothing.reduce(0.0) { $0 + cos($1.toRadians()) }
        let avgRadians = atan2(sinSum, cosSum)
        let avgDegrees = avgRadians.toDegrees()
        
        return (avgDegrees + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - CLLocationManagerDelegate
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
        guard let location = locations.last else { return }
        
        // Filter out inaccurate readings
        guard location.horizontalAccuracy < 50 else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        
        let smoothed = smoothedHeading(newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading)
        
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
