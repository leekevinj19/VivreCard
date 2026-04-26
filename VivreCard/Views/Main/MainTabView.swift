import SwiftUI

struct MainTabView: View {
    @StateObject private var locationService = LocationService()
    @State private var selectedTab: Tab = .friends
    @State private var selectedFriend: LiveFriend?
    
    enum Tab: String, CaseIterable {
        case friends = "Friends"
        case compass = "Vivre Card"
        case wanted = "Wanted"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .friends: return "person.2.fill"
            case .compass: return "location.north.line.fill"
            case .wanted: return "scroll.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .friends:
                    FriendListView(locationService: locationService, onNavigateToCompass: { friend in
                        selectedFriend = friend
                        selectedTab = .compass
                    })
                case .compass:
                    CompassView(locationService: locationService, selectedFriend: selectedFriend)
                case .wanted:
                    FamousPiratesView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            locationService.requestPermission()
            FirebaseService.shared.startLocationBroadcast(locationService: locationService)
        }
        .onDisappear {
            FirebaseService.shared.stopLocationBroadcast()
            locationService.stopTracking()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    
    var body: some View {
        HStack {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        if tab == .compass {
                            ZStack {
                                Circle()
                                    .fill(selectedTab == tab ? Color.strawHatRed : Color.surfaceTertiary)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: selectedTab == tab ? Color.strawHatRed.opacity(0.4) : .clear, radius: 8)
                                
                                Image(systemName: tab.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -12)
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? .goldRoger : .textSecondary.opacity(0.4))
                            
                            Text(tab.rawValue)
                                .font(VivreFont.label(10))
                                .foregroundColor(selectedTab == tab ? .goldRoger : .textSecondary.opacity(0.4))
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(Color.surfaceSecondary)
                .shadow(color: .black.opacity(0.3), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
