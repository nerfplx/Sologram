import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserListView: View {
    @State private var users: [UserProfile] = []
    @State private var searchText: String = ""
    @State private var showChatModal = false
    @State private var selectedChat: (chatId: String, recipientUsername: String)? = nil
    @Environment(\.dismiss) var dismiss
    
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
                Button(action: {
                    startChat(with: user)
                }) {
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
        }
        .scrollContentBackground(.hidden)
        .navigationBarBackButtonHidden(true)
        .background(.black)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showChatModal) {
            if let chat = selectedChat {
                ChatModalWrapper(chatId: chat.chatId, recipientUsername: chat.recipientUsername)
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                    .background(.clear)
            }
        }
    }
    
    private func fetchUsers() {
        db.collection("users")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.users = documents.compactMap { doc in
                    let data = doc.data()
                    guard let uid = data["uid"] as? String,
                          let username = data["username"] as? String else { return nil }
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
        selectedChat = (chatId, user.username)
        showChatModal = true
    }
    
    private func profileImage(for user: UserProfile) -> some View {
        Group {
            if let urlString = user.profileImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(width: 40, height: 40)
                    case .success(let image):
                        image.resizable()
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
}

struct ChatModalWrapper: View {
    let chatId: String
    let recipientUsername: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            ChatView(chatId: chatId, recipientUsername: recipientUsername)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
