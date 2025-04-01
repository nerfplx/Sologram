import SwiftUI

struct Post: Identifiable {
    let id: String 
    let imageUrl: String
    let author: UserProfile
    let likes: Int
    var likedBy: [String]
}
