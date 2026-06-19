import AuthenticationServices
import CryptoKit
import FirebaseAuth

enum AuthError: LocalizedError {
    case invalidToken
    case missingNonce
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidToken:  return "Apple sign-in returned an invalid token."
        case .missingNonce:  return "Security nonce was missing. Please try again."
        case .cancelled:     return "Sign-in was cancelled."
        }
    }
}

/// Manages the Sign in with Apple + Firebase Auth handshake.
///
/// Usage with `SignInWithAppleButton`:
///   1. Call `prepareRequest(_:)` in the button's request handler.
///   2. Call `handleCompletion(_:)` in the button's completion handler.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    private(set) var currentNonce: String?

    private init() {}

    // MARK: - SwiftUI button integration

    /// Generates a fresh nonce and attaches it to the Apple ID request.
    func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Exchanges the Apple authorization result for a Firebase session.
    func handleCompletion(
        _ result: Result<ASAuthorization, Error>
    ) async throws -> (user: User, isNewUser: Bool) {
        switch result {
        case .failure(let error):
            let asError = error as? ASAuthorizationError
            throw asError?.code == .canceled ? AuthError.cancelled : error

        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else { throw AuthError.invalidToken }

            guard
                let tokenData = credential.identityToken,
                let tokenString = String(data: tokenData, encoding: .utf8)
            else { throw AuthError.invalidToken }

            guard let nonce = currentNonce else { throw AuthError.missingNonce }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nonce,
                fullName: credential.fullName
            )

            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            return (authResult.user, authResult.additionalUserInfo?.isNewUser ?? false)
        }
    }

    // MARK: - Sign out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Unable to generate nonce.")
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
