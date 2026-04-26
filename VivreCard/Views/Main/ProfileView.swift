import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var firebase = FirebaseService.shared
    @State private var showSignOutConfirmation = false
    @State private var showEditName = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("Profile")
                            .font(VivreFont.title(26))
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    profileHeader

                    statsSection

                    settingsSection

                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Abandon Ship")
                        }
                    }
                    .buttonStyle(GhostButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .background(BeachBackground(style: .soft).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .alert("Leave the Crew?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("You'll stop sharing your location until you sign in again.")
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.skyBlue, Color.oceanTurquoise],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Text(String(firebase.currentUser?.displayName.prefix(1) ?? "?").uppercased())
                    .font(VivreFont.title(36))
                    .foregroundColor(.textPrimary)
                
                Circle()
                    .stroke(Color.goldRoger.opacity(0.4), lineWidth: 2)
                    .frame(width: 94, height: 94)
            }
            
            VStack(spacing: 4) {
                Text(firebase.currentUser?.displayName ?? "Pirate")
                    .font(VivreFont.heading(22))
                    .foregroundColor(.textPrimary)
                
                Text(firebase.currentUser?.email ?? "")
                    .font(VivreFont.caption(13))
                    .foregroundColor(.textSecondary.opacity(0.5))
                
                if let crew = firebase.currentUser?.crewName {
                    Text(crew)
                        .font(VivreFont.label(12))
                        .foregroundColor(.sunsetOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.sunsetOrange.opacity(0.15)))
                        .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 24)
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "BOUNTY",
                value: BountyFormatter.compact(firebase.currentUser?.pirateBounty ?? 0),
                icon: "star.fill",
                color: .goldRoger
            )
            
            StatCard(
                title: "NAKAMA",
                value: "\(firebase.currentUser?.friendIDs.count ?? 0)",
                icon: "person.2.fill",
                color: .oceanTurquoise
            )
            
            StatCard(
                title: "JOINED",
                value: memberSince,
                icon: "calendar",
                color: .logPoseBlue
            )
        }
        .padding(.horizontal, 16)
    }
    
    private var settingsSection: some View {
        VStack(spacing: 2) {
            SettingsRow(icon: "person.fill", title: "Edit Pirate Name", color: .textPrimary) {
                showEditName = true
            }
            SettingsRow(icon: "flag.fill", title: "Crew Settings", color: .sunsetOrange)
            SettingsRow(icon: "bell.fill", title: "Notifications", color: .logPoseBlue)
            SettingsRow(icon: "location.fill", title: "Location Permissions", color: .oceanTurquoise) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            SettingsRow(icon: "shield.fill", title: "Privacy", color: .strawHatRed)
        }
        .padding(.horizontal, 16)
        .vivreCard()
        .padding(.horizontal, 16)
        .sheet(isPresented: $showEditName) {
            EditNameSheet(currentName: firebase.currentUser?.displayName ?? "")
        }
    }
    
    private var memberSince: String {
        guard let date = firebase.currentUser?.createdAt else { return "---" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
}

struct EditNameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var firebase = FirebaseService.shared
    let currentName: String

    @State private var newName: String = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your pirate name is how nakama find you.")
                        .font(VivreFont.body(14))
                        .foregroundColor(.textSecondary.opacity(0.6))

                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.goldRoger.opacity(0.6))
                            .frame(width: 20)
                        TextField("Pirate Name", text: $newName)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .font(VivreFont.body())
                    .foregroundColor(.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.92))
                            .shadow(color: .deepSea.opacity(0.15), radius: 8, y: 2)
                    )
                }
                .padding(.horizontal, 16)

                if let error {
                    Text(error)
                        .font(VivreFont.caption())
                        .foregroundColor(.dangerRed)
                        .padding(.horizontal, 16)
                }

                Button {
                    save()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save Name")
                        }
                    }
                }
                .buttonStyle(PirateButtonStyle(color: .goldRoger))
                .disabled(newName.trimmingCharacters(in: .whitespaces).count < 2 || isSaving)
                .opacity(newName.trimmingCharacters(in: .whitespaces).count >= 2 ? 1.0 : 0.5)
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 20)
            .frame(maxWidth: .infinity)
            .background(BeachBackground(style: .soft).ignoresSafeArea())
            .navigationTitle("Edit Pirate Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.goldRoger)
                }
            }
            .onAppear { newName = currentName }
        }
    }

    private func save() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return }
        isSaving = true
        Task {
            do {
                try await firebase.updateDisplayName(trimmed)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(VivreFont.heading(18))
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(VivreFont.label(9))
                .foregroundColor(.textSecondary.opacity(0.5))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .vivreCard()
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(VivreFont.body(15))
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary.opacity(0.3))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .disabled(action == nil)
    }
}
