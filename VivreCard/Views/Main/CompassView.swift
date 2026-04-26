import SwiftUI
import CoreLocation

struct VivreCardPiece: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)

        path.move(to: CGPoint(x: center.x, y: rect.minY + height * 0.1))
        path.addLine(to: CGPoint(x: center.x + width * 0.35, y: rect.minY + height * 0.15))
        path.addLine(to: CGPoint(x: center.x + width * 0.4, y: rect.minY + height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX - width * 0.1, y: center.y - height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX - width * 0.08, y: center.y + height * 0.05))
        path.addLine(to: CGPoint(x: center.x + width * 0.38, y: rect.maxY - height * 0.12))
        path.addLine(to: CGPoint(x: center.x + width * 0.3, y: rect.maxY - height * 0.08))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY - height * 0.1))
        path.addLine(to: CGPoint(x: center.x - width * 0.3, y: rect.maxY - height * 0.08))
        path.addLine(to: CGPoint(x: center.x - width * 0.38, y: rect.maxY - height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.08, y: center.y + height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.1, y: center.y - height * 0.1))
        path.addLine(to: CGPoint(x: center.x - width * 0.4, y: rect.minY + height * 0.25))
        path.addLine(to: CGPoint(x: center.x - width * 0.35, y: rect.minY + height * 0.15))
        path.closeSubpath()

        return path
    }
}

struct CompassView: View {
    @ObservedObject var locationService: LocationService
    let selectedFriend: LiveFriend?
    @ObservedObject private var firebase = FirebaseService.shared
    @StateObject private var viewModel: CompassViewModel

    @State private var showFriendPicker = false
    @State private var paperFlicker = false

    init(locationService: LocationService, selectedFriend: LiveFriend? = nil) {
        self.locationService = locationService
        self.selectedFriend = selectedFriend
        _viewModel = StateObject(wrappedValue: CompassViewModel(locationService: locationService))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.top, 16)

            Spacer()

            vivreCardCompass

            Spacer()

            if viewModel.isTracking {
                infoPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            selectFriendButton
                .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView.ignoresSafeArea())
        .onAppear {
            syncSelection()
        }
        .onChange(of: selectedFriend?.id) { _, _ in
            syncSelection()
        }
    }

    private var backgroundView: some View {
        ZStack {
            BeachBackground(style: .soft)
                .ignoresSafeArea()

            if viewModel.isTracking {
                RadialGradient(
                    colors: [Color.goldRoger.opacity(0.08), .clear],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("VIVRE CARD")
                .font(VivreFont.label(12))
                .foregroundColor(.goldRoger)
                .tracking(4)

            if let friend = viewModel.selectedFriend {
                Text(friend.displayName)
                    .font(VivreFont.title(24))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(friend.isOnline ? Color.onlineGreen : Color.offlineGray)
                        .frame(width: 8, height: 8)
                    Text(friend.isOnline ? "Active now" : "Offline")
                        .font(VivreFont.caption(12))
                        .foregroundColor(friend.isOnline ? .onlineGreen : .offlineGray)
                }
            } else {
                Text("Select a Nakama")
                    .font(VivreFont.heading(20))
                    .foregroundColor(.textPrimary.opacity(0.6))
            }
        }
    }

    private var vivreCardCompass: some View {
        ZStack {
            compassRing

            VivreCardPiece()
                .fill(
                    LinearGradient(
                        colors: [Color.sandGold, Color.sandLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: 80 * viewModel.cardBurnAmount,
                    height: 80 * viewModel.cardBurnAmount
                )
                .shadow(color: .goldRoger.opacity(0.3), radius: 12)
                .overlay(
                    VivreCardPiece()
                        .stroke(Color.sunsetOrange.opacity(paperFlicker ? 0.6 : 0.2), lineWidth: 2)
                        .frame(
                            width: 80 * viewModel.cardBurnAmount,
                            height: 80 * viewModel.cardBurnAmount
                        )
                )
                .rotationEffect(viewModel.arrowAngle)
                .animation(.easeInOut(duration: 0.4), value: viewModel.arrowRotation)
                .animation(.easeInOut(duration: 0.6), value: viewModel.cardBurnAmount)

            if viewModel.isTracking {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.strawHatRed)
                    .offset(y: -20 * viewModel.cardBurnAmount)
                    .rotationEffect(viewModel.arrowAngle)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.arrowRotation)
            }
        }
        .frame(width: 260, height: 260)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                paperFlicker = true
            }
        }
    }

    private var compassRing: some View {
        ZStack {
            Circle()
                .stroke(Color.goldRoger.opacity(0.2), lineWidth: 1)
                .frame(width: 240, height: 240)

            ForEach(0..<4) { i in
                let labels = ["N", "E", "S", "W"]
                let angle = Double(i) * 90

                Text(labels[i])
                    .font(VivreFont.label(11))
                    .foregroundColor(i == 0 ? .strawHatRed : .textSecondary.opacity(0.4))
                    .offset(y: -128)
                    .rotationEffect(.degrees(angle))
            }

            ForEach(0..<36) { i in
                Rectangle()
                    .fill(i % 9 == 0 ? Color.goldRoger.opacity(0.4) : Color.textSecondary.opacity(0.15))
                    .frame(width: i % 9 == 0 ? 1.5 : 0.5, height: i % 9 == 0 ? 12 : 6)
                    .offset(y: -113)
                    .rotationEffect(.degrees(Double(i) * 10))
            }

            Circle()
                .stroke(Color.textSecondary.opacity(0.1), lineWidth: 0.5)
                .frame(width: 180, height: 180)
        }
    }

    private var infoPanel: some View {
        HStack(spacing: 32) {
            metricView(title: "DISTANCE", value: viewModel.distanceText, color: .goldRoger)

            Rectangle()
                .fill(Color.textSecondary.opacity(0.2))
                .frame(width: 1, height: 40)

            metricView(title: "DIRECTION", value: viewModel.directionLabel, color: .logPoseBlue)

            Rectangle()
                .fill(Color.textSecondary.opacity(0.2))
                .frame(width: 1, height: 40)

            metricView(
                title: "CARD",
                value: "\(Int(viewModel.cardBurnAmount * 100))%",
                color: .sunsetOrange
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .textPrimaryCard()
    }

    private var selectFriendButton: some View {
        VStack(spacing: 10) {
            Button {
                showFriendPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isTracking ? "arrow.triangle.2.circlepath" : "person.2.fill")
                    Text(viewModel.isTracking ? "Switch Nakama" : "Choose a Nakama")
                }
            }
            .buttonStyle(PirateButtonStyle(
                color: viewModel.isTracking ? .surfaceTertiary : .strawHatRed,
                isWide: false
            ))

            Button {
                viewModel.selectFriend(
                    LiveFriend(
                        id: "test-luffy",
                        displayName: "Monkey D. Luffy",
                        crewName: "Straw Hat Pirates",
                        pirateBounty: 3_000_000_000,
                        coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                        isOnline: true,
                        lastSeen: Date()
                    )
                )
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flask.fill")
                    Text("Test: Point to Tokyo")
                }
            }
            .buttonStyle(PirateButtonStyle(color: .palmGreen, isWide: false))
            .font(VivreFont.caption(12))
        }
        .padding(.top, 16)
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(friends: firebase.liveFriends) { friend in
                viewModel.selectFriend(friend)
                showFriendPicker = false
            }
        }
    }

    private func syncSelection() {
        guard let selectedFriend else { return }

        if viewModel.selectedFriend?.id != selectedFriend.id {
            viewModel.selectFriend(selectedFriend)
        }
    }

    private func metricView(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(VivreFont.label(10))
                .foregroundColor(.textSecondary.opacity(0.5))
                .tracking(2)
            Text(value)
                .font(VivreFont.heading(22))
                .foregroundColor(color)
        }
    }
}

struct FriendPickerSheet: View {
    let friends: [LiveFriend]
    var onSelect: (LiveFriend) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BeachBackground(style: .soft)
                    .ignoresSafeArea()

                if friends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.textSecondary.opacity(0.3))
                        Text("No nakama to track yet")
                            .font(VivreFont.body())
                            .foregroundColor(.textSecondary.opacity(0.5))
                    }
                } else {
                    List(friends) { friend in
                        Button {
                            onSelect(friend)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(friend.isOnline ? Color.oceanTurquoise.opacity(0.2) : Color.surfaceTertiary)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(friend.displayName.prefix(1)).uppercased())
                                            .font(VivreFont.heading(16))
                                            .foregroundColor(friend.isOnline ? .oceanTurquoise : .offlineGray)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.displayName)
                                        .font(VivreFont.heading(15))
                                        .foregroundColor(.textPrimary)
                                    Text(friend.isOnline ? "Online" : "Offline")
                                        .font(VivreFont.caption(12))
                                        .foregroundColor(friend.isOnline ? .onlineGreen : .offlineGray)
                                }

                                Spacer()

                                Image(systemName: "location.fill")
                                    .foregroundColor(.goldRoger)
                            }
                        }
                        .listRowBackground(Color.surfaceSecondary)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Choose Nakama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.goldRoger)
                }
            }
        }
    }
}
