import SwiftUI
import Combine

// MARK: - One Piece Theme Colors (Tropical Ocean)
extension Color {
    // Primary palette — bright sky & ocean
    static let skyBlue = Color(hex: "4AC8F0")            // Vivid sky blue
    static let oceanTurquoise = Color(hex: "2BC4D8")     // Turquoise shallows
    static let deepSea = Color(hex: "1A7FA8")            // Deeper ocean blue
    static let sandGold = Color(hex: "F0D68A")           // Warm beach sand
    static let sandLight = Color(hex: "FFF4DC")          // Light sand / foam
    
    // Accent colors
    static let strawHatRed = Color(hex: "D42E38")        // Luffy's hat band
    static let sunsetOrange = Color(hex: "F0943A")       // Sunset glow
    static let sunsetPink = Color(hex: "E8889C")         // Cloud blush at sunset
    static let palmGreen = Color(hex: "3DA86B")          // Island vegetation
    static let goldRoger = Color(hex: "DAA844")          // Gold treasure accents
    static let logPoseBlue = Color(hex: "3D8FD4")        // Log Pose needle
    
    // Utility
    static let onlineGreen = Color(hex: "3DBB5E")
    static let offlineGray = Color(hex: "94A3B8")
    static let dangerRed = Color(hex: "E04050")
    
    // Surface colors (light tropical theme)
    static let surfacePrimary = Color(hex: "E8F6FC")     // Palest sky wash
    static let surfaceSecondary = Color(hex: "FFFFFF")   // Clean white cards
    static let surfaceTertiary = Color(hex: "D6EFFA")    // Light blue tint
    
    // Text colors (dark on light)
    static let textPrimary = Color(hex: "1A3A4A")        // Deep ocean ink
    static let textSecondary = Color(hex: "4A7A90")      // Muted sea blue
    static let textMuted = Color(hex: "8AACBC")          // Faded tide
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var accentColor: Color = .skyBlue
    
    // Semantic colors
    var background: Color { .surfacePrimary }
    var cardBackground: Color { .surfaceSecondary }
    var elevatedBackground: Color { .surfaceTertiary }
    var primaryText: Color { .textPrimary }
    var secondaryText: Color { .textSecondary }
    var accent: Color { accentColor }
    var gold: Color { .goldRoger }
}

// MARK: - Custom Button Styles
struct PirateButtonStyle: ButtonStyle {
    var color: Color = .skyBlue
    var isWide: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Avenir-Heavy", size: 16))
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, isWide ? 0 : 24)
            .frame(maxWidth: isWide ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.35), radius: 8, y: 4)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Avenir-Medium", size: 15))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Custom View Modifiers
struct VivreCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surfaceSecondary)
                    .shadow(color: Color.deepSea.opacity(0.08), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.skyBlue.opacity(0.15), lineWidth: 0.5)
            )
    }
}

struct ParchmentCardModifier: ViewModifier {
    var isHighlighted: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.sandLight.opacity(0.5))
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.goldRoger.opacity(0.5), lineWidth: 1.5)
                    }
                }
            )
    }
}

struct TextPrimaryCardModifier: ViewModifier {
    var isHighlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.surfaceSecondary)
                        .shadow(color: Color.deepSea.opacity(0.08), radius: 12, y: 4)
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.goldRoger.opacity(0.5), lineWidth: 1.5)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.skyBlue.opacity(0.15), lineWidth: 0.5)
                    }
                }
            )
    }
}

extension View {
    func vivreCard() -> some View {
        modifier(VivreCardModifier())
    }

    func parchmentCard(highlighted: Bool = false) -> some View {
        modifier(ParchmentCardModifier(isHighlighted: highlighted))
    }

    func textPrimaryCard(highlighted: Bool = false) -> some View {
        modifier(TextPrimaryCardModifier(isHighlighted: highlighted))
    }
}

// MARK: - Typography Helpers
struct VivreFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .custom("Avenir-Black", size: size)
    }
    
    static func heading(_ size: CGFloat = 20) -> Font {
        .custom("Avenir-Heavy", size: size)
    }
    
    static func body(_ size: CGFloat = 16) -> Font {
        .custom("Avenir-Medium", size: size)
    }
    
    static func caption(_ size: CGFloat = 13) -> Font {
        .custom("Avenir-Medium", size: size)
    }
    
    static func label(_ size: CGFloat = 12) -> Font {
        .custom("Avenir-Heavy", size: size)
    }
}

