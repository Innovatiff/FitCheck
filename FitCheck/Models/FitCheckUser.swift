import Foundation
import FirebaseFirestore

/// Mirror of the `users/{uid}` Firestore document.
///
/// Field mapping (Firestore key → Swift property):
///   uid            → uid
///   username       → username
///   styleTag       → styleTag       (absent when nil)
///   currentStreak  → currentStreak
///   longestStreak  → longestStreak
///   squadIds       → squadIds
///   createdAt      → createdAt      (Firestore Timestamp)
///
/// `@DocumentID` captures the document path key but is never written as a field.
struct FitCheckUser: Codable, Equatable, Identifiable {

    // Document path key — populated automatically on decode, ignored on encode.
    @DocumentID var id: String?

    let uid: String
    var username: String
    var styleTag: String?
    var currentStreak: Int
    var longestStreak: Int
    var squadIds: [String]

    // Stored as a Firestore Timestamp; FirebaseFirestore's Codable bridge handles conversion.
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case uid
        case username
        case styleTag
        case currentStreak
        case longestStreak
        case squadIds
        case createdAt
    }

    init(uid: String, username: String) {
        self.uid = uid
        self.username = username
        self.styleTag = nil
        self.currentStreak = 0
        self.longestStreak = 0
        self.squadIds = []
        self.createdAt = Date()
    }
}
