import SwiftUI
import CoreLocation

struct FriendListView: View {
    @ObservedObject var locationService: LocationService
    @ObservedObject private var firebase = FirebaseService.shared
    
    var onNavigateToCompass: (LiveFriend) -> Void
    
    @State private var searchEmail = ""
    @State private var isSearching = false
    @State private var searchResult: VivreUser?
    @State private var searchError: String?
    @State private var showAddFriend = false
    @State private var showRequests = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Page header
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Crew")
                                .font(VivreFont.title(26))
                                .foregroundColor(.textPrimary)
                            Text("\(firebase.liveFriends.count) nakama")
                                .font(VivreFont.caption())
                                .foregroundColor(.goldRoger)
                        }
                        Spacer()
                        Button {
                            showAddFriend = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.goldRoger)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Incoming requests banner
                    if !firebase.incomingRequests.isEmpty {
                        RequestsBanner(count: firebase.incomingRequests.count) {
                            showRequests = true
                        }
                        .padding(.horizontal, 16)
                    }

                    // Friends list
                    if firebase.liveFriends.isEmpty {
                        EmptyCrewView()
                            .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedFriends) { friend in
                                FriendCard(friend: friend, userLocation: locationService.currentLocation)
                                    .onTapGesture {
                                        onNavigateToCompass(friend)
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .background(BeachBackground(style: .soft).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddFriend) {
                AddFriendSheet()
            }
            .sheet(isPresented: $showRequests) {
                FriendRequestsSheet()
            }
        }
    }
    
    // Sort: online first, then alphabetically
    private var sortedFriends: [LiveFriend] {
        firebase.liveFriends.sorted { a, b in
            if a.isOnline != b.isOnline { return a.isOnline }
            return a.displayName < b.displayName
        }
    }
}

// MARK: - Friend Card
struct FriendCard: View {
    let friend: LiveFriend
    let userLocation: CLLocation?
    
    private var distance: String {
        guard let loc = userLocation else { return "---" }
        let meters = NavigationMath.distance(from: loc.coordinate, to: friend.coordinate)
        return NavigationMath.formattedDistance(meters: meters)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(friend.isOnline ? Color.oceanTurquoise.opacity(0.2) : Color.surfaceTertiary)
                    .frame(width: 50, height: 50)
                
                Text(String(friend.displayName.prefix(1)).uppercased())
                    .font(VivreFont.heading(20))
                    .foregroundColor(friend.isOnline ? .oceanTurquoise : .offlineGray)
                
                // Online indicator
                Circle()
                    .fill(friend.isOnline ? Color.onlineGreen : Color.offlineGray)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(Color.surfaceSecondary, lineWidth: 2)
                    )
                    .offset(x: 18, y: 18)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(VivreFont.heading(16))
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 6) {
                    if let crew = friend.crewName {
                        Text(crew)
                            .font(VivreFont.caption(11))
                            .foregroundColor(.sunsetOrange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.sunsetOrange.opacity(0.15))
                            )
                    }
                    
                    Text(friend.isOnline ? "Online" : timeAgo(friend.lastSeen))
                        .font(VivreFont.caption(12))
                        .foregroundColor(friend.isOnline ? .onlineGreen : .offlineGray)
                }
            }
            
            Spacer()
            
            // Distance + Arrow
            VStack(alignment: .trailing, spacing: 4) {
                Text(distance)
                    .font(VivreFont.heading(14))
                    .foregroundColor(.goldRoger)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.logPoseBlue)
            }
        }
        .padding(14)
        .vivreCard()
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}

// MARK: - Incoming Requests Banner
struct RequestsBanner: View {
    let count: Int
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.sunsetOrange)
                
                Text("\(count) friend request\(count > 1 ? "s" : "") waiting!")
                    .font(VivreFont.body(14))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.sunsetOrange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.sunsetOrange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Empty State
struct EmptyCrewView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.textSecondary.opacity(0.3))
            
            Text("No Nakama Yet")
                .font(VivreFont.heading(20))
                .foregroundColor(.textPrimary)
            
            Text("Every pirate king needs a crew.\nTap + to add your first friend!")
                .font(VivreFont.body(14))
                .foregroundColor(.textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
}
