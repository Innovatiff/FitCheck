import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            switch authVM.state {
            case .loading:
                ProgressView()
                    .scaleEffect(1.4)

            case .welcome:
                OnboardingView()

            case .usernameSelection(let firebaseUser):
                UsernameSelectionView(firebaseUser: firebaseUser)

            case .authenticated(let user):
                MainTabView(user: user)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stateID)
    }

    // Equatable proxy so the animation triggers on state changes.
    private var stateID: String {
        switch authVM.state {
        case .loading:              return "loading"
        case .welcome:              return "welcome"
        case .usernameSelection:    return "username"
        case .authenticated:        return "home"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
