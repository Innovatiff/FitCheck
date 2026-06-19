import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            switch session.state {
            case .loading:
                ProgressView()
                    .scaleEffect(1.4)

            case .signedOut:
                OnboardingView()

            case .needsUsername(let firebaseUser):
                UsernameSelectionView(firebaseUser: firebaseUser)

            case .signedIn(let user):
                MainTabView(user: user)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.state.stateKey)
    }
}
