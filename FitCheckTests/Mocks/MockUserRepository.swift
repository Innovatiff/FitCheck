import Foundation
@testable import FitCheck

/// In-memory `UserRepositoryProtocol` for unit tests.
final class MockUserRepository: UserRepositoryProtocol {

    // Seed these before running tests.
    var takenUsernames: Set<String> = []
    var existingUsers:  [String: FitCheckUser] = [:]    // keyed by uid

    // Capture calls for assertion.
    private(set) var createdUsers: [FitCheckUser] = []
    private(set) var availabilityChecks: [String] = []

    // Inject to simulate network failures.
    var shouldThrow: Error?

    // MARK: - UserRepositoryProtocol

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        availabilityChecks.append(username)
        if let error = shouldThrow { throw error }
        return !takenUsernames.contains(username.lowercased())
    }

    func createUser(_ user: FitCheckUser) async throws {
        if let error = shouldThrow { throw error }
        guard !takenUsernames.contains(user.username.lowercased()) else {
            throw FirestoreError.usernameTaken
        }
        takenUsernames.insert(user.username.lowercased())
        existingUsers[user.uid] = user
        createdUsers.append(user)
    }

    func fetchUser(uid: String) async throws -> FitCheckUser? {
        if let error = shouldThrow { throw error }
        return existingUsers[uid]
    }
}
