import SwiftUI

/// Reusable tropical beach background with configurable opacity & overlay
struct BeachBackground: View {
    enum Style {
        case full           // Full vivid image (login/splash)
        case soft           // Subtle faded version (main screens)
        case ghost          // Very subtle (dense content screens)
    }
    
    var style: Style = .soft
    
    var body: some View {
        ZStack {
            // Base beach image
            Image("BeachBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .opacity(imageOpacity)
            
            // Overlay for readability
            overlay
                .ignoresSafeArea()
        }
    }
    
    private var imageOpacity: Double {
        switch style {
        case .full:  return 1.0
        case .soft:  return 0.35
        case .ghost: return 0.15
        }
    }
    
    @ViewBuilder
    private var overlay: some View {
        switch style {
        case .full:
            // Light vignette to help text pop
            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.0),
                    Color.deepSea.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        case .soft:
            // Wash to background color so content is readable
            LinearGradient(
                colors: [
                    Color.surfacePrimary.opacity(0.75),
                    Color.surfacePrimary.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        case .ghost:
            // Nearly opaque — image barely peeks through
            Color.surfacePrimary.opacity(0.92)
        }
    }
}

// MARK: - Convenience modifier
extension View {
    func beachBackground(_ style: BeachBackground.Style = .soft) -> some View {
        self.background(BeachBackground(style: style))
    }
}
