import SwiftUI
import CoreLocation

enum LeaderboardEntry: Identifiable {
    case user(VivreUser, isCurrentUser: Bool)
    case pirate(FamousPirate)

    var id: String {
        switch self {
        case .user(let user, _):
            return user.id ?? user.displayName
        case .pirate(let pirate):
            return "pirate-\(pirate.id)"
        }
    }

    var bountyValue: Int {
        switch self {
        case .user(let user, _):
            return user.pirateBounty
        case .pirate(let pirate):
            return pirate.bounty
        }
    }

    var displayName: String {
        switch self {
        case .user(let user, _):
            return user.displayName
        case .pirate(let pirate):
            return pirate.name
        }
    }

    var formattedBounty: String {
        switch self {
        case .user(let user, _):
            return BountyFormatter.compact(user.pirateBounty)
        case .pirate(let pirate):
            return BountyFormatter.full(pirate.bounty)
        }
    }
}

struct FamousPiratesView: View {
    @StateObject private var jikan = JikanService()
    @ObservedObject private var firebase = FirebaseService.shared

    private var leaderboard: [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = jikan.famousPirates.map { .pirate($0) }

        if let currentUser = firebase.currentUser {
            entries.append(.user(currentUser, isCurrentUser: true))
        }

        for friend in firebase.liveFriends {
            entries.append(
                .user(
                    VivreUser(
                        id: friend.id,
                        displayName: friend.displayName,
                        email: "",
                        avatarURL: friend.avatarURL,
                        crewName: friend.crewName,
                        pirateBounty: friend.pirateBounty,
                        latitude: friend.coordinate.latitude,
                        longitude: friend.coordinate.longitude,
                        heading: 0,
                        isOnline: friend.isOnline,
                        lastSeen: friend.lastSeen,
                        friendIDs: [],
                        incomingRequestIDs: [],
                        outgoingRequestIDs: [],
                        createdAt: Date()
                    ),
                    isCurrentUser: false
                )
            )
        }

        return entries.sorted { $0.bountyValue > $1.bountyValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wanted!")
                            .font(VivreFont.title(26))
                            .foregroundColor(.textPrimary)
                        Text("Most Wanted Pirates")
                            .font(VivreFont.caption())
                            .foregroundColor(.goldRoger)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if jikan.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.goldRoger)
                            .scaleEffect(1.5)
                        Text("Loading wanted posters...")
                            .font(VivreFont.body(14))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                } else if let error = jikan.error {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text(error)
                            .font(VivreFont.body(14))
                            .foregroundColor(.textSecondary)
                        Button("Try Again") { jikan.fetchFamousPirates(force: true) }
                            .buttonStyle(PirateButtonStyle(color: .goldRoger, isWide: false))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "newspaper")
                                    .font(.system(size: 11))
                                Text("Live wanted board")
                                    .font(VivreFont.caption(11))
                            }
                            .foregroundColor(.textSecondary.opacity(0.5))
                            .padding(.vertical, 8)

                            LazyVStack(spacing: 12) {
                                ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                                    LeaderboardCard(entry: entry, rank: index + 1)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BeachBackground(style: .soft).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { jikan.fetchFamousPirates() }
        }
    }
}

struct LeaderboardCard: View {
    let entry: LeaderboardEntry
    let rank: Int

    var body: some View {
        HStack(spacing: 14) {
            Text("#\(rank)")
                .font(VivreFont.heading(16))
                .foregroundColor(rank <= 3 ? .goldRoger : .textSecondary.opacity(0.4))
                .frame(width: 32)

            portrait

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(VivreFont.heading(15))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if case .user(_, let isCurrentUser) = entry, isCurrentUser {
                        Text("YOU")
                            .font(VivreFont.label(8))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.oceanTurquoise))
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.goldRoger)
                    Text("Bounty \(entry.formattedBounty)")
                        .font(VivreFont.caption(12))
                        .foregroundColor(.goldRoger)
                }
            }

            Spacer()

            badge
        }
        .padding(14)
        .vivreCard()
        .overlay(
            Group {
                if case .user(_, let isCurrentUser) = entry, isCurrentUser {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.oceanTurquoise.opacity(0.5), lineWidth: 1.5)
                }
            }
        )
    }

    @ViewBuilder
    private var portrait: some View {
        switch entry {
        case .pirate(let pirate):
            AsyncImage(url: URL(string: pirate.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.surfaceTertiary
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.goldRoger.opacity(0.3), lineWidth: 1))

        case .user(let user, _):
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.oceanTurquoise.opacity(0.2))
                    .frame(width: 52, height: 52)
                Text(String(user.displayName.prefix(1)).uppercased())
                    .font(VivreFont.heading(22))
                    .foregroundColor(.oceanTurquoise)
            }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.oceanTurquoise.opacity(0.3), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch entry {
        case .pirate:
            if rank <= 3 {
                Text("WANTED")
                    .font(VivreFont.label(9))
                    .foregroundColor(.strawHatRed)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.strawHatRed, lineWidth: 1))
            }
        case .user(let user, _):
            if let crew = user.crewName {
                Text(crew)
                    .font(VivreFont.label(9))
                    .foregroundColor(.sunsetOrange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.sunsetOrange, lineWidth: 1))
                    .lineLimit(1)
                    .frame(maxWidth: 86)
            }
        }
    }
}
