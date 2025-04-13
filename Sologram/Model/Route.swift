import Foundation

enum Route: Hashable {
    case userList
    case chat(chatId: String, recipientUsername: String)
}
