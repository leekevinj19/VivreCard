import Foundation
import CoreLocation

struct NavigationMath {
    static func bearing(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = source.latitude.toRadians()
        let lon1 = source.longitude.toRadians()
        let lat2 = destination.latitude.toRadians()
        let lon2 = destination.longitude.toRadians()

        let longitudeDelta = lon2 - lon1
        let y = sin(longitudeDelta) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longitudeDelta)
        let bearing = atan2(y, x).toDegrees()

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    static func relativeAngle(
        userCoordinate: CLLocationCoordinate2D,
        friendCoordinate: CLLocationCoordinate2D,
        deviceHeading: Double
    ) -> Double {
        let absoluteBearing = bearing(from: userCoordinate, to: friendCoordinate)
        return (absoluteBearing - deviceHeading + 360).truncatingRemainder(dividingBy: 360)
    }

    static func distance(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let location2 = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return location1.distance(from: location2)
    }

    static func formattedDistance(meters: Double) -> String {
        if meters < 100 {
            return "Nearby"
        }
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        }
        if meters < 10_000 {
            return String(format: "%.1f km", meters / 1000)
        }
        if meters < 100_000 {
            return String(format: "%.0f km", meters / 1000)
        }

        let miles = meters / 1_609.344
        return String(format: "%.0f mi", miles)
    }

    static func compassDirection(from degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return directions[index]
    }
}

extension Double {
    func toRadians() -> Double {
        self * .pi / 180
    }

    func toDegrees() -> Double {
        self * 180 / .pi
    }
}
