import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var cardRotation: Double = 0

    var body: some View {
        ZStack {
            BeachBackground(style: .full)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.goldRoger.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)

                    VivreCardPiece()
                        .fill(Color.sandLight)
                        .frame(width: 80, height: 80)
                        .shadow(color: .goldRoger.opacity(0.7), radius: 12)
                        .rotationEffect(.degrees(cardRotation))
                }

                VStack(spacing: 8) {
                    Text("VIVRE CARD")
                        .font(VivreFont.title(36))
                        .foregroundColor(.white)
                        .tracking(6)
                        .shadow(color: .deepSea.opacity(0.5), radius: 8, y: 2)

                    Text("Find Your Nakama")
                        .font(VivreFont.body(14))
                        .foregroundColor(.sandLight)
                        .tracking(2)
                        .shadow(color: .deepSea.opacity(0.5), radius: 4, y: 1)
                }
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1
                scale = 1
            }

            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                cardRotation = 15
            }
        }
    }
}
