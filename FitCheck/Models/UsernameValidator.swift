import Foundation

/// Pure, stateless username format validator.
/// No Firebase dependency — safe to unit-test directly.
enum UsernameValidator {

    static let minLength = 3
    static let maxLength = 20

    enum Failure: LocalizedError, Equatable {
        case empty
        case tooShort
        case tooLong
        case invalidCharacters

        var errorDescription: String? {
            switch self {
            case .empty:              return "Username cannot be empty."
            case .tooShort:           return "At least \(UsernameValidator.minLength) characters required."
            case .tooLong:            return "Maximum \(UsernameValidator.maxLength) characters."
            case .invalidCharacters:  return "Only letters, numbers, and underscores allowed."
            }
        }
    }

    /// Returns `.success` with the trimmed, lowercased candidate, or `.failure` with the first rule violation.
    @discardableResult
    static func validate(_ raw: String) -> Result<String, Failure> {
        let candidate = raw.trimmingCharacters(in: .whitespaces)

        if candidate.isEmpty              { return .failure(.empty) }
        if candidate.count < minLength    { return .failure(.tooShort) }
        if candidate.count > maxLength    { return .failure(.tooLong) }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard candidate.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return .failure(.invalidCharacters)
        }

        return .success(candidate.lowercased())
    }

    /// Convenience: `nil` means valid.
    static func errorMessage(for raw: String) -> String? {
        guard case .failure(let f) = validate(raw) else { return nil }
        return f.errorDescription
    }
}
