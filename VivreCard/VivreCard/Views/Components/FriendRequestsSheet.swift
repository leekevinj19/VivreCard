import SwiftUI

struct FriendRequestsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var firebase = FirebaseService.shared
    @State private var processingIDs: Set<String> = []
    
    var body: some View {
        NavigationStack {
            Group {
                if firebase.incomingRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary.opacity(0.3))
                        Text("No pending requests")
                            .font(VivreFont.body())
                            .foregroundColor(.textSecondary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(firebase.incomingRequests) { request in
                                RequestCard(
                                    request: request,
                                    isProcessing: processingIDs.contains(request.id ?? ""),
                                    onAccept: { accept(request) },
                                    onDecline: { decline(request) }
                                )
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(BeachBackground(style: .soft).ignoresSafeArea())
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.goldRoger)
                }
            }
        }
    }
    
    private func accept(_ request: FriendRequest) {
        guard let id = request.id else { return }
        processingIDs.insert(id)
        Task {
            try? await firebase.acceptFriendRequest(request)
            await MainActor.run { _ = processingIDs.remove(id) }
        }
    }
    
    private func decline(_ request: FriendRequest) {
        guard let id = request.id else { return }
        processingIDs.insert(id)
        Task {
            try? await firebase.declineFriendRequest(request)
            await MainActor.run { _ = processingIDs.remove(id) }
        }
    }
}

// MARK: - Request Card
struct RequestCard: View {
    let request: FriendRequest
    let isProcessing: Bool
    var onAccept: () -> Void
    var onDecline: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.sunsetOrange.opacity(0.2))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(String(request.fromUserName.prefix(1)).uppercased())
                        .font(VivreFont.heading(18))
                        .foregroundColor(.sunsetOrange)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUserName)
                    .font(VivreFont.heading(15))
                    .foregroundColor(.textPrimary)
                
                Text("Wants to share Vivre Cards")
                    .font(VivreFont.caption(12))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .tint(.goldRoger)
            } else {
                HStack(spacing: 8) {
                    // Decline
                    Button {
                        onDecline()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.offlineGray)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.surfaceTertiary))
                    }
                    
                    // Accept
                    Button {
                        onAccept()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.oceanTurquoise))
                    }
                }
            }
        }
        .padding(14)
        .vivreCard()
    }
}
