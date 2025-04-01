import SwiftUI

struct Comment: Identifiable {
    let id: String
    let text: String
    let userProfile: UserProfile
    let timestamp: Date
    var timestampFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
