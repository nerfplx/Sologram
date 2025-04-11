import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserListView: View {
    @State private var users: [UserProfile] = []
    @State private var selectedUser: UserProfile? = nil
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack {
                List(users) { user in
                    Button(action: {
                        selectedUser = user
                        startChat(with: user)
                    }) {
                        HStack {
                            Text(user.username)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.black)
                }
                .navigationTitle("Выберите пользователя")
                .onAppear(perform: fetchUsers)
                .navigationDestination(isPresented: .constant(selectedUser != nil)) {
                    if let selectedUser = selectedUser, selectedUser.uid != Auth.auth().currentUser?.uid {
                        let chatId = generateChatId(for: Auth.auth().currentUser?.uid ?? "", and: selectedUser.uid)
                        ChatView(chatId: chatId, recipientUsername: selectedUser.username)
                    }
                }
            }
            .background(.black)
        }
    }
    
    func fetchUsers() {
        db.collection("users")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.users = documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let uid = data["uid"] as? String,
                        let username = data["username"] as? String
                    else {
                        return nil
                    }
                    return UserProfile(uid: uid, email: "", username: username, bio: "", profileImageURL: nil)
                }
                if let currentUserId = Auth.auth().currentUser?.uid {
                    self.users.removeAll { $0.uid == currentUserId }
                }
            }
    }

    func generateChatId(for user1: String, and user2: String) -> String {
        return [user1, user2].sorted().joined(separator: "_")
    }
    
    func startChat(with user: UserProfile) {
        selectedUser = user
    }
}
