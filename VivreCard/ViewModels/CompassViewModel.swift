import Foundation
import CoreLocation
import Combine

class CompassViewModel: ObservableObject {
    
    // MARK: - Published
    @Published var selectedFriend: LiveFriend?
    @Published var arrowRotation: Double = 0       // Degrees to rotate the vivre card arrow
    @Published var distanceText: String = "---"
    @Published var directionLabel: String = "--"
    @Published var isTracking: Bool = false
    @Published var cardBurnAmount: Double = 1.0    // 1.0 = full card, 0.0 = tiny fragment (close = bigger)
    
    // MARK: - Dependencies
    private let locationService: LocationService
    private let firebase = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(locationService: LocationService) {
        self.locationService = locationService
        setupBindings()
    }
    
    private func setupBindings() {
        // Recalculate arrow angle whenever location or heading updates
        Publishers.CombineLatest(
            locationService.$currentLocation,
            locationService.$currentHeading
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] location, heading in
            self?.recalculate(userLocation: location, deviceHeading: heading)
        }
        .store(in: &cancellables)
        
        // Also recalculate when friend data updates
        firebase.$liveFriends
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends in
                guard let self = self,
                      let selectedID = self.selectedFriend?.id,
                      let updatedFriend = friends.first(where: { $0.id == selectedID }) else { return }
                self.selectedFriend = updatedFriend
                self.recalculate(
                    userLocation: self.locationService.currentLocation,
                    deviceHeading: self.locationService.currentHeading
                )
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Select a friend to track
    func selectFriend(_ friend: LiveFriend) {
        selectedFriend = friend
        isTracking = true
        recalculate(
            userLocation: locationService.currentLocation,
            deviceHeading: locationService.currentHeading
        )
    }
    
    func stopTracking() {
        selectedFriend = nil
        isTracking = false
        arrowRotation = 0
        distanceText = "---"
        directionLabel = "--"
        cardBurnAmount = 1.0
    }
    
    // MARK: - Core Calculation
    private func recalculate(userLocation: CLLocation?, deviceHeading: Double) {
        guard let friend = selectedFriend,
              let userLoc = userLocation else { return }
        
        let userCoord = userLoc.coordinate
        let friendCoord = friend.coordinate
        
        // Calculate relative angle (what the arrow should point to)
        let angle = NavigationMath.relativeAngle(
            userCoordinate: userCoord,
            friendCoordinate: friendCoord,
            deviceHeading: deviceHeading
        )
        
        // Distance
        let meters = NavigationMath.distance(from: userCoord, to: friendCoord)
        
        // Absolute bearing for compass label
        let absoluteBearing = NavigationMath.bearing(from: userCoord, to: friendCoord)
        
        // Vivre Card "burn" effect — closer friends = card burns down to a smaller fragment
        // At 0m = 0.15 (tiny piece), at 50km+ = 1.0 (full card)
        let normalized = min(meters / 50_000, 1.0)
        let burn = 0.15 + (normalized * 0.85)
        
        // Smooth the rotation to avoid jitter
        withAnimation(.easeOut(duration: 0.3)) {
            arrowRotation = angle
            cardBurnAmount = burn
        }
        
        distanceText = NavigationMath.formattedDistance(meters: meters)
        directionLabel = NavigationMath.compassDirection(from: absoluteBearing)
    }
}

// MARK: - Convenience for animation
import SwiftUI

extension CompassViewModel {
    /// Animated rotation as an Angle
    var arrowAngle: Angle {
        .degrees(arrowRotation)
    }
}
