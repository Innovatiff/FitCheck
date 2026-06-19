import Foundation
import FirebaseFirestore

enum FirestoreError: LocalizedError {
    case usernameTaken
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .usernameTaken: return "That username is already taken."
        case .encodingFailed: return "Failed to encode user data."
        }
    }
}

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Username

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let doc = try await db.collection("usernames").document(username.lowercased()).getDocument()
        return !doc.exists
    }

    // MARK: - User creation

    /// Atomically reserves the username and writes the user document.
    func createUser(_ user: FitCheckUser) async throws {
        guard let encodedUser = try? Firestore.Encoder().encode(user) else {
            throw FirestoreError.encodingFailed
        }

        let usernameRef = db.collection("usernames").document(user.username.lowercased())
        let userRef = db.collection("users").document(user.uid)

        _ = try await db.runTransaction { transaction, errorPointer in
            let usernameDoc: DocumentSnapshot
            do {
                usernameDoc = try transaction.getDocument(usernameRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard !usernameDoc.exists else {
                errorPointer?.pointee = NSError(
                    domain: "FitCheck",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: FirestoreError.usernameTaken.localizedDescription]
                )
                return nil
            }

            transaction.setData(["uid": user.uid], forDocument: usernameRef)
            transaction.setData(encodedUser, forDocument: userRef)
            return nil
        }
    }

    // MARK: - Fetch user

    func fetchUser(uid: String) async throws -> FitCheckUser? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: FitCheckUser.self)
    }
}
