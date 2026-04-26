import SwiftUI

struct AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var firebase = FirebaseService.shared
    
    @State private var searchEmail = ""
    @State private var isSearching = false
    @State private var searchResult: VivreUser?
    @State private var searchError: String?
    @State private var requestSent = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter their email to send a Vivre Card")
                        .font(VivreFont.body(14))
                        .foregroundColor(.textSecondary.opacity(0.6))

                    HStack(spacing: 12) {
                        VivreTextField(
                            placeholder: "pirate@grandline.com",
                            text: $searchEmail,
                            icon: "magnifyingglass",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        Button {
                            search()
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(searchEmail.contains("@") ? .goldRoger : .offlineGray)
                        }
                        .disabled(!searchEmail.contains("@") || isSearching)
                    }
                }
                .padding(.horizontal, 16)

                if isSearching {
                    ProgressView()
                        .tint(.goldRoger)
                        .padding(.top, 40)
                } else if let error = searchError {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 36))
                            .foregroundColor(.dangerRed.opacity(0.6))
                        Text(error)
                            .font(VivreFont.body(14))
                            .foregroundColor(.dangerRed)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                } else if let user = searchResult {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.oceanTurquoise.opacity(0.2))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(String(user.displayName.prefix(1)).uppercased())
                                    .font(VivreFont.heading(24))
                                    .foregroundColor(.oceanTurquoise)
                            )

                        VStack(spacing: 4) {
                            Text(user.displayName)
                                .font(VivreFont.heading(18))
                                .foregroundColor(.textPrimary)

                            if let crew = user.crewName {
                                Text(crew)
                                    .font(VivreFont.caption(12))
                                    .foregroundColor(.sunsetOrange)
                            }

                            Text("Bounty: \(user.pirateBounty)")
                                .font(VivreFont.caption(12))
                                .foregroundColor(.goldRoger)
                        }

                        if requestSent {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.onlineGreen)
                                Text("Vivre Card Sent!")
                                    .font(VivreFont.heading(15))
                                    .foregroundColor(.onlineGreen)
                            }
                            .padding(.top, 8)
                        } else {
                            Button {
                                sendRequest(to: user)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Vivre Card")
                                }
                            }
                            .buttonStyle(PirateButtonStyle(isWide: false))
                        }
                    }
                    .padding(24)
                    .textPrimaryCard(highlighted: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }

                Spacer()
            }
            .padding(.top, 20)
            .frame(maxWidth: .infinity)
            .background(BeachBackground(style: .soft).ignoresSafeArea())
            .navigationTitle("Add Nakama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.goldRoger)
                }
            }
        }
    }
    
    private func search() {
        guard !searchEmail.isEmpty else { return }
        isSearching = true
        searchError = nil
        searchResult = nil
        requestSent = false
        
        Task {
            do {
                if searchEmail.lowercased() == firebase.currentUser?.email.lowercased() {
                    throw VivreError.selfRequest
                }
                
                let user = try await firebase.searchUser(byEmail: searchEmail)
                await MainActor.run {
                    if let user = user {
                        searchResult = user
                    } else {
                        searchError = VivreError.userNotFound.localizedDescription
                    }
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchError = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }
    
    private func sendRequest(to user: VivreUser) {
        Task {
            do {
                try await firebase.sendFriendRequest(to: user)
                await MainActor.run {
                    requestSent = true
                }
            } catch {
                await MainActor.run {
                    searchError = error.localizedDescription
                }
            }
        }
    }
}
