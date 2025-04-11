import Foundation

struct Chat: Identifiable {
    let id: String
    let userIds: [String]
    let otherUser: UserProfile
}
