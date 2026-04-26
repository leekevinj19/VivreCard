import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var error: String?
    @Published var currentUID: String?
    
    private let firebase = FirebaseService.shared
    private var authListener: AuthStateDidChangeListenerHandle?
    
    init() {
        listenToAuthState()
    }
    
    private func listenToAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let user = user {
                    self.currentUID = user.uid
                    self.isAuthenticated = true
                    
                    // Fetch user profile from Firestore
                    Task {
                        do {
                            try await self.firebase.fetchCurrentUser(uid: user.uid)
                            self.firebase.listenToFriends()
                            self.firebase.listenToRequests()
                        } catch {
                            self.error = error.localizedDescription
                        }
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                } else {
                    self.currentUID = nil
                    self.isAuthenticated = false
                    self.isLoading = false
                }
            }
        }
    }
    
    // Sign Up
    func signUp(email: String, password: String, displayName: String) async {
        await MainActor.run { self.error = nil }
        
        do {
            let _ = try await firebase.signUp(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    // Sign In
    func signIn(email: String, password: String) async {
        await MainActor.run { self.error = nil }
        
        do {
            try await firebase.signIn(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    // Sign Out
    func signOut() {
        do {
            try firebase.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}
