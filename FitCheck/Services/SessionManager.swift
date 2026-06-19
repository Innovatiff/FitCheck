import Foundation
import FirebaseAuth
import Combine

// MARK: - Session state

enum SessionState {
    /// Firebase auth listener hasn't fired yet.
    case loading
    /// No Firebase session.
    case signedOut
    /// Firebase session exists but no Firestore document — user must choose a username.
    case needsUsername(firebaseUser: User)
    /// Fully onboarded.
    case signedIn(user: FitCheckUser)

    var stateKey: String {
        switch self {
        case .loading:       return "loading"
        case .signedOut:     return "signedOut"
        case .needsUsername: return "needsUsername"
        case .signedIn:      return "signedIn"
        }
    }
}

// MARK: - SessionManager

/// Single source of truth for authentication and profile state.
///
/// Inject at the app root and read via `@EnvironmentObject`.
/// `AuthViewModel` depends on this for state; it does NOT maintain its own auth listener.
@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var state: SessionState = .loading
    /// Non-nil only when `state == .signedIn`. Convenience accessor.
    @Published private(set) var currentUser: FitCheckUser?

    private let repository: UserRepositoryProtocol
    private var listener: AuthStateDidChangeListenerHandle?

    init(repository: UserRepositoryProtocol = FirestoreService.shared) {
        self.repository = repository
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            Task { await self.resolve(firebaseUser) }
        }
    }

    deinit {
        if let listener { Auth.auth().removeStateDidChangeListener(listener) }
    }

    // MARK: - Internal updates (called by AuthViewModel after actions)

    /// Call after successfully writing a new user document so the state updates without waiting
    /// for the next Firestore fetch triggered by the auth listener.
    func finishOnboarding(with user: FitCheckUser) {
        currentUser = user
        state = .signedIn(user: user)
    }

    func clearSession() {
        currentUser = nil
        state = .signedOut
    }

    // MARK: - Private

    private func resolve(_ firebaseUser: User?) async {
        guard let firebaseUser else {
            currentUser = nil
            state = .signedOut
            return
        }

        do {
            if let fitCheckUser = try await repository.fetchUser(uid: firebaseUser.uid) {
                currentUser = fitCheckUser
                state = .signedIn(user: fitCheckUser)
            } else {
                currentUser = nil
                state = .needsUsername(firebaseUser: firebaseUser)
            }
        } catch {
            currentUser = nil
            // Fall back to sign-out so the user can try again; the error surfaces via AuthViewModel.
            state = .signedOut
        }
    }
}
