import SwiftUI
import AuthenticationServices
import FirebaseAuth
import Combine

enum AppAuthState {
    case loading
    case welcome
    case usernameSelection(firebaseUser: User)
    case authenticated(user: FitCheckUser)
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AppAuthState = .loading
    @Published var error: String?

    let authService = AuthService.shared
    private let firestoreService = FirestoreService.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            Task { await self.resolveAuthState(firebaseUser) }
        }
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - State resolution

    private func resolveAuthState(_ firebaseUser: User?) async {
        guard let firebaseUser else {
            state = .welcome
            return
        }
        do {
            if let fitCheckUser = try await firestoreService.fetchUser(uid: firebaseUser.uid) {
                state = .authenticated(user: fitCheckUser)
            } else {
                state = .usernameSelection(firebaseUser: firebaseUser)
            }
        } catch {
            self.error = error.localizedDescription
            state = .welcome
        }
    }

    // MARK: - Sign in with Apple

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        error = nil
        do {
            let (firebaseUser, isNewUser) = try await authService.handleCompletion(result)
            if isNewUser {
                state = .usernameSelection(firebaseUser: firebaseUser)
            } else if let fitCheckUser = try await firestoreService.fetchUser(uid: firebaseUser.uid) {
                state = .authenticated(user: fitCheckUser)
            } else {
                // Firebase account exists but no Firestore doc — treat as incomplete sign-up.
                state = .usernameSelection(firebaseUser: firebaseUser)
            }
        } catch AuthError.cancelled {
            // User dismissed — no error shown.
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Username submission

    func submitUsername(_ username: String, for firebaseUser: User) async {
        error = nil
        do {
            let available = try await firestoreService.isUsernameAvailable(username)
            guard available else {
                error = "That username is already taken. Please choose another."
                return
            }
            let newUser = FitCheckUser(uid: firebaseUser.uid, username: username)
            try await firestoreService.createUser(newUser)
            state = .authenticated(user: newUser)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sign out

    func signOut() {
        error = nil
        do {
            try authService.signOut()
            state = .welcome
        } catch {
            self.error = error.localizedDescription
        }
    }
}
