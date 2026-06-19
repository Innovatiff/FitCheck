import XCTest
@testable import FitCheck

final class UsernameValidatorTests: XCTestCase {

    // MARK: - Valid inputs

    func testMinimumLengthIsAccepted() {
        XCTAssertSuccess(UsernameValidator.validate("abc"))
    }

    func testMaximumLengthIsAccepted() {
        XCTAssertSuccess(UsernameValidator.validate(String(repeating: "a", count: 20)))
    }

    func testMixedAlphanumericIsAccepted() {
        XCTAssertSuccess(UsernameValidator.validate("FitCheck42"))
    }

    func testUnderscoresAreAccepted() {
        XCTAssertSuccess(UsernameValidator.validate("fit_check"))
    }

    func testLeadingAndTrailingWhitespaceIsStripped() {
        let result = UsernameValidator.validate("  hello  ")
        XCTAssertSuccess(result)
        if case .success(let clean) = result {
            XCTAssertEqual(clean, "hello")
        }
    }

    func testValidUsernameIsLowercased() {
        let result = UsernameValidator.validate("FitCheck")
        if case .success(let clean) = result {
            XCTAssertEqual(clean, "fitcheck")
        } else {
            XCTFail("Expected success for mixed-case username")
        }
    }

    // MARK: - Empty / whitespace

    func testEmptyStringFails() {
        XCTAssertFailure(UsernameValidator.validate(""), expected: .empty)
    }

    func testWhitespaceOnlyFails() {
        XCTAssertFailure(UsernameValidator.validate("   "), expected: .empty)
    }

    // MARK: - Length violations

    func testTwoCharactersFails() {
        XCTAssertFailure(UsernameValidator.validate("ab"), expected: .tooShort)
    }

    func testOneCharacterFails() {
        XCTAssertFailure(UsernameValidator.validate("x"), expected: .tooShort)
    }

    func testTwentyOneCharactersFails() {
        XCTAssertFailure(
            UsernameValidator.validate(String(repeating: "a", count: 21)),
            expected: .tooLong
        )
    }

    func testExactlyThreeCharactersAfterTrimSucceeds() {
        XCTAssertSuccess(UsernameValidator.validate("  fit  "))
    }

    // MARK: - Invalid characters

    func testSpaceInMiddleFails() {
        XCTAssertFailure(UsernameValidator.validate("fit check"), expected: .invalidCharacters)
    }

    func testHyphenFails() {
        XCTAssertFailure(UsernameValidator.validate("fit-check"), expected: .invalidCharacters)
    }

    func testAtSymbolFails() {
        XCTAssertFailure(UsernameValidator.validate("@fitcheck"), expected: .invalidCharacters)
    }

    func testEmojisFail() {
        XCTAssertFailure(UsernameValidator.validate("fit🔥"), expected: .invalidCharacters)
    }

    func testPeriodFails() {
        XCTAssertFailure(UsernameValidator.validate("fit.check"), expected: .invalidCharacters)
    }

    // MARK: - Error messages

    func testErrorMessageForEmptyUsername() {
        XCTAssertNotNil(UsernameValidator.errorMessage(for: ""))
    }

    func testNoErrorMessageForValidUsername() {
        XCTAssertNil(UsernameValidator.errorMessage(for: "fitcheck"))
    }

    // MARK: - Helpers

    private func XCTAssertSuccess(
        _ result: Result<String, UsernameValidator.Failure>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if case .failure(let f) = result {
            XCTFail("Expected success but got failure: \(f.localizedDescription ?? "")", file: file, line: line)
        }
    }

    private func XCTAssertFailure(
        _ result: Result<String, UsernameValidator.Failure>,
        expected: UsernameValidator.Failure,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        switch result {
        case .success(let v):
            XCTFail("Expected \(expected) but got success with value '\(v)'", file: file, line: line)
        case .failure(let actual):
            XCTAssertEqual(actual, expected, file: file, line: line)
        }
    }
}
