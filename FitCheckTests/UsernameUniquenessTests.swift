import XCTest
@testable import FitCheck

/// Tests the username-uniqueness check logic using `MockUserRepository`.
/// No network calls or Firebase SDK required.
final class UsernameUniquenessTests: XCTestCase {

    private var repo: MockUserRepository!

    override func setUp() {
        super.setUp()
        repo = MockUserRepository()
    }

    override func tearDown() {
        repo = nil
        super.tearDown()
    }

    // MARK: - isUsernameAvailable

    func testAvailableUsernameReturnsTrue() async throws {
        let available = try await repo.isUsernameAvailable("freshname")
        XCTAssertTrue(available)
    }

    func testTakenUsernameReturnsFalse() async throws {
        repo.takenUsernames = ["taken"]
        let available = try await repo.isUsernameAvailable("taken")
        XCTAssertFalse(available)
    }

    func testAvailabilityCheckIsCaseInsensitive() async throws {
        repo.takenUsernames = ["fitcheck"]
        let available = try await repo.isUsernameAvailable("FitCheck")
        XCTAssertFalse(available, "Check should be case-insensitive")
    }

    func testAvailabilityCheckRecordsQuery() async throws {
        _ = try await repo.isUsernameAvailable("myuser")
        XCTAssertEqual(repo.availabilityChecks, ["myuser"])
    }

    func testAvailabilityCheckPropagatesError() async {
        struct NetworkError: Error {}
        repo.shouldThrow = NetworkError()
        do {
            _ = try await repo.isUsernameAvailable("anything")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - createUser

    func testCreateUserWritesDocument() async throws {
        let user = FitCheckUser(uid: "uid-1", username: "alice")
        try await repo.createUser(user)
        let fetched = try await repo.fetchUser(uid: "uid-1")
        XCTAssertEqual(fetched?.username, "alice")
    }

    func testCreateUserReservesUsername() async throws {
        let user = FitCheckUser(uid: "uid-2", username: "bob")
        try await repo.createUser(user)
        let available = try await repo.isUsernameAvailable("bob")
        XCTAssertFalse(available, "Username should be reserved after createUser")
    }

    func testCreateUserWithAlreadyTakenUsernameThrows() async {
        repo.takenUsernames = ["charlie"]
        let user = FitCheckUser(uid: "uid-3", username: "charlie")
        do {
            try await repo.createUser(user)
            XCTFail("Expected FirestoreError.usernameTaken")
        } catch FirestoreError.usernameTaken {
            // Expected path.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateUserTracksCreatedUsers() async throws {
        let user = FitCheckUser(uid: "uid-4", username: "dana")
        try await repo.createUser(user)
        XCTAssertEqual(repo.createdUsers.count, 1)
        XCTAssertEqual(repo.createdUsers.first?.uid, "uid-4")
    }

    // MARK: - Full uniqueness-check flow

    /// Mirrors the logic in `AuthViewModel.submitUsername`: validate format → check availability → create.
    func testFullSubmitFlowSucceedsForAvailableUsername() async throws {
        let username = "validuser"

        // Step 1: format validation
        let formatResult = UsernameValidator.validate(username)
        guard case .success(let canonical) = formatResult else {
            return XCTFail("Format validation should succeed")
        }

        // Step 2: uniqueness check
        let available = try await repo.isUsernameAvailable(canonical)
        XCTAssertTrue(available)

        // Step 3: create
        let user = FitCheckUser(uid: "uid-5", username: canonical)
        try await repo.createUser(user)

        XCTAssertEqual(repo.createdUsers.first?.username, canonical)
    }

    func testFullSubmitFlowFailsForTakenUsername() async throws {
        repo.takenUsernames = ["taken"]

        let formatResult = UsernameValidator.validate("taken")
        guard case .success(let canonical) = formatResult else {
            return XCTFail("Format validation should succeed")
        }

        let available = try await repo.isUsernameAvailable(canonical)
        XCTAssertFalse(available, "Flow should stop here with 'username taken' error")
        XCTAssertTrue(repo.createdUsers.isEmpty, "createUser should not have been called")
    }

    func testFullSubmitFlowFailsForInvalidFormat() {
        // Invalid format short-circuits before any async call.
        let formatResult = UsernameValidator.validate("ab")
        guard case .failure(let failure) = formatResult else {
            return XCTFail("Validation should fail for 2-character username")
        }
        XCTAssertEqual(failure, .tooShort)
        XCTAssertTrue(repo.availabilityChecks.isEmpty, "No network call should be made for invalid format")
    }

    // MARK: - fetchUser

    func testFetchUserReturnsNilForUnknownUID() async throws {
        let user = try await repo.fetchUser(uid: "unknown")
        XCTAssertNil(user)
    }

    func testFetchUserReturnsCorrectUser() async throws {
        let user = FitCheckUser(uid: "uid-6", username: "eve")
        repo.existingUsers["uid-6"] = user
        let fetched = try await repo.fetchUser(uid: "uid-6")
        XCTAssertEqual(fetched?.username, "eve")
    }

    func testFetchUserPropagatesError() async {
        struct StorageError: Error {}
        repo.shouldThrow = StorageError()
        do {
            _ = try await repo.fetchUser(uid: "uid-7")
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is StorageError)
        }
    }

    // MARK: - FitCheckUser defaults

    func testNewUserHasCorrectDefaults() {
        let user = FitCheckUser(uid: "uid-8", username: "frank")
        XCTAssertNil(user.styleTag)
        XCTAssertEqual(user.currentStreak, 0)
        XCTAssertEqual(user.longestStreak, 0)
        XCTAssertTrue(user.squadIds.isEmpty)
    }

    func testNewUserCreatedAtIsRecent() {
        let before = Date()
        let user = FitCheckUser(uid: "uid-9", username: "grace")
        let after = Date()
        XCTAssertGreaterThanOrEqual(user.createdAt, before)
        XCTAssertLessThanOrEqual(user.createdAt, after)
    }
}
