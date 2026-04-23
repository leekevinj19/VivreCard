import Foundation
import CoreLocation
import FirebaseFirestore

// MARK: - User Model
struct VivreUser: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var avatarURL: String?
    var crewName: String?                  // One Piece themed "group" name
    var pirateBounty: Int                  // Fun gamification — increases with activity
    var latitude: Double
    var longitude: Double
    var heading: Double                    // Device compass heading in degrees
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
    
    // Default for new users
    static func newUser(id: String, displayName: String, email: String) -> VivreUser {
        VivreUser(
            id: id,
            displayName: displayName,
            email: email,
            avatarURL: nil,
            crewName: nil,
            pirateBounty: 0,
            latitude: 0.0,
            longitude: 0.0,
            heading: 0.0,
            isOnline: true,
            lastSeen: Date(),
            friendIDs: [],
            incomingRequestIDs: [],
            outgoingRequestIDs: [],
            createdAt: Date()
        )
    }
}

// MARK: - Friend Request
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

// MARK: - Friend With Live Data (used in UI)
struct LiveFriend: Identifiable {
    let id: String
    var displayName: String
    var crewName: String?
    var pirateBounty: Int
    var coordinate: CLLocationCoordinate2D
    var isOnline: Bool
    var lastSeen: Date
    var avatarURL: String?
    
    /// Distance from current user in meters
    var distanceFromUser: Double?
    
    /// Bearing from current user in degrees (0 = north, 90 = east)
    var bearingFromUser: Double?
    
    var formattedDistance: String {
        guard let distance = distanceFromUser else { return "Unknown" }
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else if distance < 100_000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            let miles = distance / 1_609.344
            return String(format: "%.0f mi", miles)
        }
    }
}

// MARK: - Crew (Group of friends)
struct Crew: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var captainID: String              // Creator of the crew
    var memberIDs: [String]
    var createdAt: Date
    var crewJollyRoger: String?        // Custom emoji or symbol
    
    static let collectionName = "crews"
}
