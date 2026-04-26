import SwiftUI
import CoreLocation

// MARK: - Leaderboard Entry (unified model for users + famous pirates)
enum LeaderboardEntry: Identifiable {
    case user(VivreUser, isCurrentUser: Bool)
    case pirate(FamousPirate)

    var id: String {
        switch self {
        case .user(let u, _): return u.id ?? u.displayName
        case .pirate(let p): return "pirate-\(p.id)"
        }
    }

    var bountyValue: Int {
        switch self {
        case .user(let u, _): return u.pirateBounty
        case .pirate(let p): return Int(p.bounty.replacingOccurrences(of: ",", with: "")) ?? 0
        }
    }

    var displayName: String {
        switch self {
        case .user(let u, _): return u.displayName
        case .pirate(let p): return p.name
        }
    }

    var formattedBounty: String {
        switch self {
        case .user(let u, _):
            let b = u.pirateBounty
            if b >= 1_000_000_000 { return String(format: "%.2fB", Double(b) / 1_000_000_000) }
            if b >= 1_000_000     { return String(format: "%.1fM", Double(b) / 1_000_000) }
            if b >= 1_000         { return String(format: "%.0fK", Double(b) / 1_000) }
            return "\(b)"
        case .pirate(let p): return p.bounty
        }
    }
}

// MARK: - Famous Pirates View
struct FamousPiratesView: View {
    @StateObject private var jikan = JikanService()
    @ObservedObject private var firebase = FirebaseService.shared

    // added: search text to filter the leaderboard by name
    @State private var searchText = ""

    // Merge users + famous pirates into one sorted list
    // added: filters results by searchText if user is typing
    private var leaderboard: [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = jikan.famousPirates.map { .pirate($0) }

        // Add current user
        if let me = firebase.currentUser {
            entries.append(.user(me, isCurrentUser: true))
        }

        // Add friends
        for friend in firebase.liveFriends {
            let user = VivreUser(
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
            )
            entries.append(.user(user, isCurrentUser: false))
        }

        // sort by bounty high to low
        let sorted = entries.sorted { $0.bountyValue > $1.bountyValue }

        // if search bar is empty return the full list
        if searchText.isEmpty { return sorted }

        // otherwise filter — case insensitive so "luffy" matches "Monkey D. Luffy"
        return sorted.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Page header — always visible
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

                // added: search bar to filter pirates and friends by name
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    TextField("Search pirates...", text: $searchText)
                        .font(VivreFont.body(14))
                        .foregroundColor(.textPrimary)
                    // show X button to clear search when typing
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(10)
                .background(Color.surfaceTertiary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

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
                        Button("Try Again") { jikan.fetchFamousPirates() }
                            .buttonStyle(PirateButtonStyle(color: .goldRoger, isWide: false))
                    }
                    Spacer()

                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // API source label
                            HStack {
                                Image(systemName: "network")
                                    .font(.system(size: 11))
                                Text("api.jikan.moe/v4/anime/21/characters")
                                    .font(VivreFont.caption(11))
                            }
                            .foregroundColor(.textSecondary.opacity(0.5))
                            .padding(.vertical, 8)

                            // added: empty state when search has no results
                            if leaderboard.isEmpty {
                                VStack(spacing: 12) {
                                    Text("🏴‍☠️")
                                        .font(.system(size: 40))
                                    Text("No pirates found for \"\(searchText)\"")
                                        .font(VivreFont.body(14))
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 40)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                                        LeaderboardCard(entry: entry, rank: index + 1)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 100)
                            }
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

// MARK: - Unified Leaderboard Card
struct LeaderboardCard: View {
    let entry: LeaderboardEntry
    let rank: Int

    var body: some View {
        HStack(spacing: 14) {

            // Rank
            Text("#\(rank)")
                .font(VivreFont.heading(16))
                .foregroundColor(rank <= 3 ? .goldRoger : .textSecondary.opacity(0.4))
                .frame(width: 32)

            // Portrait
            portrait

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(VivreFont.heading(15))
                        .foregroundColor(.textPrimary)

                    if case .user(_, let isMe) = entry, isMe {
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
                    Text("฿\(entry.formattedBounty)")
                        .font(VivreFont.caption(12))
                        .foregroundColor(.goldRoger)
                }
            }

            Spacer()

            // Right badge
            badge
        }
        .padding(14)
        .vivreCard()
        .overlay(
            // Highlight current user's card
            Group {
                if case .user(_, let isMe) = entry, isMe {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.oceanTurquoise.opacity(0.5), lineWidth: 1.5)
                }
            }
        )
    }

    @ViewBuilder
    private var portrait: some View {
        switch entry {
        case .pirate(let p):
            AsyncImage(url: URL(string: p.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.surfaceTertiary
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.goldRoger.opacity(0.3), lineWidth: 1))

        case .user(let u, _):
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.oceanTurquoise.opacity(0.2))
                    .frame(width: 52, height: 52)
                Text(String(u.displayName.prefix(1)).uppercased())
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
        case .user(let u, _):
            if let crew = u.crewName {
                Text(crew)
                    .font(VivreFont.label(9))
                    .foregroundColor(.sunsetOrange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.sunsetOrange, lineWidth: 1))
                    .lineLimit(1)
            }
        }
    }
}
