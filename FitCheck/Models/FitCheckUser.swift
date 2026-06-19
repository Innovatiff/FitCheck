import Foundation
import FirebaseFirestore

/// Mirror of the `users/{uid}` Firestore document.
///
/// Firestore field names match Swift property names exactly:
///   uid, username, styleTag, currentStreak, longestStreak, squadIds, createdAt
///
/// `createdAt` is stored as a Firestore Timestamp; the SDK's Codable bridge handles conversion.
/// `id` is decorated with `@DocumentID` so it is populated from the document path key and
/// is never written as a body field — no custom CodingKeys required.
struct FitCheckUser: Codable, Equatable, Identifiable {

    // Populated from the document path on decode; omitted from encoding automatically.
    @DocumentID var id: String?

    let uid: String
    var username: String
    var styleTag: String?
    var currentStreak: Int
    var longestStreak: Int
    var squadIds: [String]
    let createdAt: Date

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
