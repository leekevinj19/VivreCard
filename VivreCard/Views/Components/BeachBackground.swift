import SwiftUI

struct BeachBackground: View {
    enum Style {
        case full
        case soft
        case ghost
    }

    var style: Style = .soft

    var body: some View {
        ZStack {
            Image("BeachBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .opacity(imageOpacity)

            overlay
                .ignoresSafeArea()
        }
    }

    private var imageOpacity: Double {
        switch style {
        case .full:
            return 1
        case .soft:
            return 0.35
        case .ghost:
            return 0.15
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch style {
        case .full:
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0),
                    Color.deepSea.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .soft:
            LinearGradient(
                colors: [
                    Color.surfacePrimary.opacity(0.75),
                    Color.surfacePrimary.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .ghost:
            Color.surfacePrimary.opacity(0.92)
        }
    }
}

extension View {
    func beachBackground(_ style: BeachBackground.Style = .soft) -> some View {
        background(BeachBackground(style: style))
    }
}
