import Foundation
import CoreLocation
import Combine
import SwiftUI

class CompassViewModel: ObservableObject {
    @Published var selectedFriend: LiveFriend?
    @Published var arrowRotation: Double = 0
    @Published var distanceText: String = "---"
    @Published var directionLabel: String = "--"
    @Published var isTracking = false
    @Published var cardBurnAmount: Double = 1.0

    private let locationService: LocationService
    private let firebase = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init(locationService: LocationService) {
        self.locationService = locationService
        setupBindings()
    }

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

    var arrowAngle: Angle {
        .degrees(arrowRotation)
    }

    private func setupBindings() {
        Publishers.CombineLatest(
            locationService.$currentLocation,
            locationService.$currentHeading
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] location, heading in
            self?.recalculate(userLocation: location, deviceHeading: heading)
        }
        .store(in: &cancellables)

        firebase.$liveFriends
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends in
                guard let self,
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

    private func recalculate(userLocation: CLLocation?, deviceHeading: Double) {
        guard let friend = selectedFriend,
              let userLocation else { return }

        let userCoordinate = userLocation.coordinate
        let friendCoordinate = friend.coordinate
        let angle = NavigationMath.relativeAngle(
            userCoordinate: userCoordinate,
            friendCoordinate: friendCoordinate,
            deviceHeading: deviceHeading
        )
        let distance = NavigationMath.distance(from: userCoordinate, to: friendCoordinate)
        let bearing = NavigationMath.bearing(from: userCoordinate, to: friendCoordinate)
        let normalizedDistance = min(distance / 50_000, 1.0)
        let burnAmount = 0.15 + (normalizedDistance * 0.85)

        withAnimation(.easeOut(duration: 0.3)) {
            arrowRotation = angle
            cardBurnAmount = burnAmount
        }

        distanceText = NavigationMath.formattedDistance(meters: distance)
        directionLabel = NavigationMath.compassDirection(from: bearing)
    }
}
