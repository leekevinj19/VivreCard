import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct VivreCardApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(.light)
        }
    }
}
