import Foundation
import CoreLocation
import FirebaseFirestore

struct VivreUser: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var avatarURL: String?
    var crewName: String?
    var pirateBounty: Int
    var latitude: Double
    var longitude: Double
    var heading: Double
    var isOnline: Bool
    var lastSeen: Date
    var friendIDs: [String]
    var incomingRequestIDs: [String]
    var outgoingRequestIDs: [String]
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    static let collectionName = "users"

    static func newUser(id: String, displayName: String, email: String) -> VivreUser {
        VivreUser(
            id: id,
            displayName: displayName,
            email: email,
            avatarURL: nil,
            crewName: nil,
            pirateBounty: 0,
            latitude: 0,
            longitude: 0,
            heading: 0,
            isOnline: true,
            lastSeen: Date(),
            friendIDs: [],
            incomingRequestIDs: [],
            outgoingRequestIDs: [],
            createdAt: Date()
        )
    }
}

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var fromUserID: String
    var fromUserName: String
    var toUserID: String
    var toUserName: String
    var status: RequestStatus
    var sentAt: Date

    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case declined
    }

    static let collectionName = "friendRequests"
}

struct LiveFriend: Identifiable {
    let id: String
    var displayName: String
    var crewName: String?
    var pirateBounty: Int
    var coordinate: CLLocationCoordinate2D
    var isOnline: Bool
    var lastSeen: Date
    var avatarURL: String?
    var distanceFromUser: Double?
    var bearingFromUser: Double?

    var formattedDistance: String {
        guard let distanceFromUser else { return "Unknown" }
        return NavigationMath.formattedDistance(meters: distanceFromUser)
    }
}

struct Crew: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var captainID: String
    var memberIDs: [String]
    var createdAt: Date
    var crewJollyRoger: String?

    static let collectionName = "crews"
}

enum BountyFormatter {
    static func full(_ bounty: Int) -> String {
        bounty.formatted(.number)
    }

    static func compact(_ bounty: Int) -> String {
        if bounty >= 1_000_000_000 {
            return String(format: "%.2fB", Double(bounty) / 1_000_000_000)
        }
        if bounty >= 1_000_000 {
            return String(format: "%.1fM", Double(bounty) / 1_000_000)
        }
        if bounty >= 1_000 {
            return String(format: "%.0fK", Double(bounty) / 1_000)
        }
        return "\(bounty)"
    }
}
