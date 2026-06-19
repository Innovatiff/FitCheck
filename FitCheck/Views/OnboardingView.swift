import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showSignIn = false

    var body: some View {
        ZStack {
            if showSignIn {
                signInScreen
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                welcomeScreen
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSignIn)
        .alert("Something went wrong", isPresented: .init(
            get: { authVM.error != nil },
            set: { if !$0 { authVM.error = nil } }
        )) {
            Button("OK") { authVM.error = nil }
        } message: {
            Text(authVM.error ?? "")
        }
    }

    // MARK: - Welcome screen

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)

                Text("FitCheck")
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text("Your daily style, rated.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation { showSignIn = true }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Sign-in screen

    private var signInScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation { showSignIn = false }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 12) {
                Text("Sign in to FitCheck")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("One tap to get started.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                authVM.authService.prepareRequest(request)
            } onCompletion: { result in
                Task { await authVM.handleAppleCompletion(result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}

#Preview {
    let session = SessionManager()
    let authVM  = AuthViewModel(session: session)
    return OnboardingView()
        .environmentObject(session)
        .environmentObject(authVM)
}
