import Foundation

/// Abstracts Firestore operations so they can be replaced with a mock in unit tests.
protocol UserRepositoryProtocol: AnyObject {
    func isUsernameAvailable(_ username: String) async throws -> Bool
    func createUser(_ user: FitCheckUser) async throws
    func fetchUser(uid: String) async throws -> FitCheckUser?
}
