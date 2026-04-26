import Foundation
import CoreLocation

struct NavigationMath {
    
    /// Calculate the bearing (in degrees) from one coordinate to another.
    /// 0° = North, 90° = East, 180° = South, 270° = West
    static func bearing(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = source.latitude.toRadians()
        let lon1 = source.longitude.toRadians()
        let lat2 = destination.latitude.toRadians()
        let lon2 = destination.longitude.toRadians()
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let radiansBearing = atan2(y, x)
        let degreesBearing = radiansBearing.toDegrees()
        
        return (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
    }
    
    /// Calculate the relative angle to rotate the compass arrow.
    /// Takes into account the device's current heading.
    /// Returns the angle (in degrees) that the arrow should be rotated.
    static func relativeAngle(
        userCoordinate: CLLocationCoordinate2D,
        friendCoordinate: CLLocationCoordinate2D,
        deviceHeading: Double
    ) -> Double {
        let absoluteBearing = bearing(from: userCoordinate, to: friendCoordinate)
        let relativeAngle = absoluteBearing - deviceHeading
        return (relativeAngle + 360).truncatingRemainder(dividingBy: 360)
    }
    
    /// Distance between two coordinates in meters
    static func distance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let location2 = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return location1.distance(from: location2)
    }
    
    /// Human-readable distance string
    static func formattedDistance(meters: Double) -> String {
        if meters < 100 {
            return "Nearby"
        } else if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else if meters < 10_000 {
            return String(format: "%.1f km", meters / 1000)
        } else if meters < 100_000 {
            return String(format: "%.0f km", meters / 1000)
        } else {
            let miles = meters / 1_609.344
            return String(format: "%.0f mi", miles)
        }
    }
    
    /// Compass direction label from degrees
    static func compassDirection(from degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return directions[index]
    }
}

// MARK: - Angle Conversion Extensions
extension Double {
    func toRadians() -> Double {
        self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        self * 180.0 / .pi
    }
}
