import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isRegistering = false
    @State private var isSubmitting = false
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.goldRoger.opacity(0.1))
                                .frame(width: 100, height: 100)

                            VivreCardPiece()
                                .fill(Color.sandLight)
                                .frame(width: 50, height: 50)
                                .shadow(color: .goldRoger.opacity(0.4), radius: 8)
                        }

                        Text("VIVRE CARD")
                            .font(VivreFont.title(32))
                            .foregroundColor(.white)
                            .tracking(4)
                            .shadow(color: .deepSea.opacity(0.5), radius: 8, y: 2)

                        Text(isRegistering ? "Join the Crew" : "Welcome Back, Pirate")
                            .font(VivreFont.body(15))
                            .foregroundColor(.sandLight)
                            .shadow(color: .deepSea.opacity(0.4), radius: 4, y: 1)
                    }

                    VStack(spacing: 16) {
                        if isRegistering {
                            VivreTextField(
                                placeholder: "Pirate Name",
                                text: $displayName,
                                icon: "person.fill"
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        VivreTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        VivreTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )
                    }
                    .padding(.horizontal, 24)

                    if let error = authViewModel.error {
                        Text(error)
                            .font(VivreFont.caption())
                            .foregroundColor(.dangerRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 12) {
                        Button {
                            submit()
                        } label: {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView().tint(.textPrimary)
                                } else {
                                    Text(isRegistering ? "Set Sail!" : "Board the Ship")
                                }
                            }
                        }
                        .buttonStyle(PirateButtonStyle())
                        .disabled(isSubmitting || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.5)

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isRegistering.toggle()
                                authViewModel.error = nil
                            }
                        } label: {
                            Text(isRegistering ? "Already a pirate? Sign In" : "New pirate? Join the Crew")
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .frame(width: geo.size.width)
            }
            .frame(width: geo.size.width)
            .background(BeachBackground(style: .full).ignoresSafeArea())
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        let nameValid = !isRegistering || displayName.count >= 2
        return emailValid && passwordValid && nameValid
    }
    
    private func submit() {
        isSubmitting = true
        Task {
            if isRegistering {
                await authViewModel.signUp(email: email, password: password, displayName: displayName)
            } else {
                await authViewModel.signIn(email: email, password: password)
            }
            await MainActor.run { isSubmitting = false }
        }
    }
}

struct VivreTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundColor(.goldRoger.opacity(0.6))
                    .frame(width: 20)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(autocapitalization)
                    .frame(maxWidth: .infinity)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .frame(maxWidth: .infinity)
            }
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}
