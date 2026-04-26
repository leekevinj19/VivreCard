import Foundation
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private var locationListener: ListenerRegistration?
    private var friendsListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?
    private var locationUpdateTimer: Timer?

    @Published var currentUser: VivreUser?
    @Published var liveFriends: [LiveFriend] = []
    @Published var incomingRequests: [FriendRequest] = []
    @Published var error: String?

    private init() {}

    func signUp(email: String, password: String, displayName: String) async throws -> VivreUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        let user = VivreUser.newUser(id: result.user.uid, displayName: displayName, email: email)
        try db.collection(VivreUser.collectionName).document(result.user.uid).setData(from: user)

        DispatchQueue.main.async {
            self.currentUser = user
        }

        return user
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        try await fetchCurrentUser(uid: result.user.uid)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        stopAllListeners()

        DispatchQueue.main.async {
            self.currentUser = nil
            self.liveFriends = []
            self.incomingRequests = []
        }
    }

    func updateDisplayName(_ name: String) async throws {
        guard let uid = currentUser?.id else { return }

        try await db.collection(VivreUser.collectionName).document(uid).updateData([
            "displayName": name
        ])
        try await fetchCurrentUser(uid: uid)
    }

    func fetchCurrentUser(uid: String) async throws {
        let document = try await db.collection(VivreUser.collectionName).document(uid).getDocument()
        let user = try document.data(as: VivreUser.self)

        DispatchQueue.main.async {
            self.currentUser = user
        }
    }

    func updateLocation(latitude: Double, longitude: Double, heading: Double) {
        guard let uid = currentUser?.id else { return }

        db.collection(VivreUser.collectionName).document(uid).updateData([
            "latitude": latitude,
            "longitude": longitude,
            "heading": heading,
            "isOnline": true,
            "lastSeen": FieldValue.serverTimestamp()
        ])
    }

    func startLocationBroadcast(locationService: LocationService) {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let location = locationService.currentLocation else { return }

            self?.updateLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                heading: locationService.currentHeading
            )
        }
    }

    func stopLocationBroadcast() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil

        guard let uid = currentUser?.id else { return }
        db.collection(VivreUser.collectionName).document(uid).updateData([
            "isOnline": false,
            "lastSeen": FieldValue.serverTimestamp()
        ])
    }

    func listenToFriends() {
        guard let user = currentUser, !user.friendIDs.isEmpty else {
            DispatchQueue.main.async {
                self.liveFriends = []
            }
            return
        }

        let batches = user.friendIDs.chunked(into: 30)
        guard let firstBatch = batches.first else { return }

        friendsListener?.remove()
        friendsListener = db.collection(VivreUser.collectionName)
            .whereField(FieldPath.documentID(), in: firstBatch)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    self?.error = error?.localizedDescription
                    return
                }

                let friends = documents.compactMap { document -> LiveFriend? in
                    guard let friend = try? document.data(as: VivreUser.self) else { return nil }
                    return LiveFriend(
                        id: document.documentID,
                        displayName: friend.displayName,
                        crewName: friend.crewName,
                        pirateBounty: friend.pirateBounty,
                        coordinate: friend.coordinate,
                        isOnline: friend.isOnline,
                        lastSeen: friend.lastSeen,
                        avatarURL: friend.avatarURL
                    )
                }

                DispatchQueue.main.async {
                    self?.liveFriends = friends
                }
            }
    }

    func searchUser(byEmail email: String) async throws -> VivreUser? {
        let snapshot = try await db.collection(VivreUser.collectionName)
            .whereField("email", isEqualTo: email.lowercased())
            .limit(to: 1)
            .getDocuments()

        return try snapshot.documents.first?.data(as: VivreUser.self)
    }

    func sendFriendRequest(to targetUser: VivreUser) async throws {
        guard let currentUser,
              let currentUID = currentUser.id,
              let targetUID = targetUser.id else { return }

        let existing = try await db.collection(FriendRequest.collectionName)
            .whereField("fromUserID", isEqualTo: currentUID)
            .whereField("toUserID", isEqualTo: targetUID)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()

        guard existing.documents.isEmpty else {
            throw VivreError.duplicateRequest
        }

        let request = FriendRequest(
            fromUserID: currentUID,
            fromUserName: currentUser.displayName,
            toUserID: targetUID,
            toUserName: targetUser.displayName,
            status: .pending,
            sentAt: Date()
        )

        let documentReference = try db.collection(FriendRequest.collectionName).addDocument(from: request)

        let batch = db.batch()
        batch.updateData(
            ["outgoingRequestIDs": FieldValue.arrayUnion([documentReference.documentID])],
            forDocument: db.collection(VivreUser.collectionName).document(currentUID)
        )
        batch.updateData(
            ["incomingRequestIDs": FieldValue.arrayUnion([documentReference.documentID])],
            forDocument: db.collection(VivreUser.collectionName).document(targetUID)
        )
        try await batch.commit()
    }

    func acceptFriendRequest(_ request: FriendRequest) async throws {
        guard let requestID = request.id,
              let currentUID = currentUser?.id else { return }

        let batch = db.batch()
        batch.updateData(
            ["status": "accepted"],
            forDocument: db.collection(FriendRequest.collectionName).document(requestID)
        )

        let currentUserRef = db.collection(VivreUser.collectionName).document(currentUID)
        let fromUserRef = db.collection(VivreUser.collectionName).document(request.fromUserID)

        batch.updateData([
            "friendIDs": FieldValue.arrayUnion([request.fromUserID]),
            "incomingRequestIDs": FieldValue.arrayRemove([requestID])
        ], forDocument: currentUserRef)

        batch.updateData([
            "friendIDs": FieldValue.arrayUnion([currentUID]),
            "outgoingRequestIDs": FieldValue.arrayRemove([requestID])
        ], forDocument: fromUserRef)

        batch.updateData(["pirateBounty": FieldValue.increment(Int64(50))], forDocument: currentUserRef)
        batch.updateData(["pirateBounty": FieldValue.increment(Int64(50))], forDocument: fromUserRef)

        try await batch.commit()
        try await fetchCurrentUser(uid: currentUID)
        listenToFriends()
    }

    func declineFriendRequest(_ request: FriendRequest) async throws {
        guard let requestID = request.id,
              let currentUID = currentUser?.id else { return }

        let batch = db.batch()
        batch.updateData(
            ["status": "declined"],
            forDocument: db.collection(FriendRequest.collectionName).document(requestID)
        )
        batch.updateData(
            ["incomingRequestIDs": FieldValue.arrayRemove([requestID])],
            forDocument: db.collection(VivreUser.collectionName).document(currentUID)
        )
        batch.updateData(
            ["outgoingRequestIDs": FieldValue.arrayRemove([requestID])],
            forDocument: db.collection(VivreUser.collectionName).document(request.fromUserID)
        )
        try await batch.commit()
    }

    func listenToRequests() {
        guard let uid = currentUser?.id else { return }

        requestsListener?.remove()
        requestsListener = db.collection(FriendRequest.collectionName)
            .whereField("toUserID", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let requests = documents.compactMap { try? $0.data(as: FriendRequest.self) }

                DispatchQueue.main.async {
                    self?.incomingRequests = requests
                }
            }
    }

    func stopAllListeners() {
        locationListener?.remove()
        friendsListener?.remove()
        requestsListener?.remove()
        stopLocationBroadcast()
    }
}

enum VivreError: LocalizedError {
    case duplicateRequest
    case userNotFound
    case selfRequest

    var errorDescription: String? {
        switch self {
        case .duplicateRequest:
            return "You already sent a request to this nakama!"
        case .userNotFound:
            return "No pirate found with that email."
        case .selfRequest:
            return "You can't send a Vivre Card to yourself!"
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
