import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserListView: View {
    @Binding var path: NavigationPath
    @State private var users: [UserProfile] = []
    @State private var searchText: String = ""
    
    private let db = Firestore.firestore()
    
    private var filteredUsers: [UserProfile] {
        searchText.isEmpty ? users : users.filter { $0.username.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Поиск", text: $searchText)
                .padding(10)
                .background(Color("grayCustom"))
                .foregroundStyle(.white)
                .cornerRadius(10)
                .padding(.horizontal, 22)
            
            Text("Сообщения")
                .foregroundStyle(.white)
                .bold()
                .padding(.horizontal, 32)
                .offset(y: 40)
            
            List(filteredUsers) { user in
                Button(action: { startChat(with: user) }) {
                    HStack {
                        profileImage(for: user)
                        Text(user.username)
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.horizontal)
                        Spacer()
                    }
                }
                .listRowBackground(Color("grayCustom"))
            }
            .onAppear(perform: fetchUsers)
            
            .navigationBarItems(leading: backButton)
        }
        .scrollContentBackground(.hidden)
        .navigationBarBackButtonHidden(true)
        .background(.black)
    }
    
    private func fetchUsers() {
        db.collection("users")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.users = documents.compactMap { doc in
                    let data = doc.data()
                    guard let uid = data["uid"] as? String, let username = data["username"] as? String else { return nil }
                    let profileImageURL = data["profileImageURL"] as? String
                    return UserProfile(uid: uid, email: "", username: username, bio: "", profileImageURL: profileImageURL)
                }
                if let currentUserId = Auth.auth().currentUser?.uid {
                    self.users.removeAll { $0.uid == currentUserId }
                }
            }
    }
    
    private func generateChatId(for user1: String, and user2: String) -> String {
        return [user1, user2].sorted().joined(separator: "_")
    }
    
    private func startChat(with user: UserProfile) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let chatId = generateChatId(for: currentUserId, and: user.uid)
        path.append(Route.chat(chatId: chatId, recipientUsername: user.username))
    }
    
    private func profileImage(for user: UserProfile) -> some View {
        Group {
            if let urlString = user.profileImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var backButton: some View {
        Button(action: {
            if !path.isEmpty {
                path.removeLast()
            }
        }) {
            HStack {
                Image(systemName: "chevron.left")
            }
            .foregroundColor(.white)
        }
    }
}
