import SwiftUI

struct UserProfile: Hashable, Identifiable {
    var id: String {uid}
    let uid: String
    let email: String
    let username: String
    let bio: String
    let profileImageURL: String?
}
