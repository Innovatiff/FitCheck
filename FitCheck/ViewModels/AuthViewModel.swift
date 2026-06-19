import SwiftUI
import AuthenticationServices
import FirebaseAuth

/// Handles authentication *actions* only.
/// Session *state* lives in `SessionManager`.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var error: String?

    let authService: AuthService
    private let session: SessionManager
    private let repository: UserRepositoryProtocol

    init(
        session: SessionManager,
        authService: AuthService = .shared,
        repository: UserRepositoryProtocol = FirestoreService.shared
    ) {
        self.session = session
        self.authService = authService
        self.repository = repository
    }

    // MARK: - Sign in with Apple

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        error = nil
        do {
            _ = try await authService.handleCompletion(result)
            // SessionManager's auth listener fires automatically and updates state.
        } catch AuthError.cancelled {
            // User dismissed sheet — no error shown.
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Username submission

    func submitUsername(_ username: String, for firebaseUser: User) async {
        error = nil

        // Format check first (no network call needed).
        if case .failure(let f) = UsernameValidator.validate(username) {
            error = f.localizedDescription
            return
        }

        do {
            let available = try await repository.isUsernameAvailable(username)
            guard available else {
                error = "That username is already taken. Please choose another."
                return
            }
            let newUser = FitCheckUser(uid: firebaseUser.uid, username: username)
            try await repository.createUser(newUser)
            session.finishOnboarding(with: newUser)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sign out

    func signOut() {
        error = nil
        do {
            try authService.signOut()
            session.clearSession()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
