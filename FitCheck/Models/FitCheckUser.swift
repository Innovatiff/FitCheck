import Foundation
import FirebaseFirestore

struct FitCheckUser: Codable, Equatable {
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
