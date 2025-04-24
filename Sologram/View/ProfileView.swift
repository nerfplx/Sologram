import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @State private var user: UserProfile? = nil
    @State private var errorMessage: String?
    @ObservedObject var postService = PostService()
    @State private var userImages: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                if let user = user {
                    headerView(for: user)
                    ScrollView {
                        VStack {
                            ProfileHeader(user: user, imageCount: postService.posts.count)
                            imagesGrid
                        }
                        .padding()
                    }
                      NavigationBarView(userImages: $userImages)
                } else {
                    ProgressView()
                }
            }
            .background(Color("grayCustom"))
            .navigationBarBackButtonHidden(true)
            .onAppear {
                loadUserProfile()
                if let userId = Auth.auth().currentUser?.uid {
                    postService.fetchUserPosts(userId: userId)
                }
            }
        }
    }
}

extension ProfileView {
    private func headerView(for user: UserProfile) -> some View {
        HStack {
            Text(user.email.split(separator: "@")[0])
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .foregroundColor(.white)
                .font(.title)
                .bold()
            
            Menu {
                NavigationLink(destination: EditProfileView(user: user, onSave: { username, bio in
                    updateProfile(username: username, bio: bio)
                })) {
                    Text("Edit Profile")
                }
                Button(role: .destructive) {
                        do {
                            try Auth.auth().signOut()
                            isLoggedIn = false
                        } catch {
                            errorMessage = "Ошибка при выходе: \(error.localizedDescription)"
                        }
                    } label: {
                        Label("Выйти", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
            } label: {
                Image(systemName: "line.horizontal.3")
            }
            .foregroundStyle(.white)
            .bold()
            .font(.title2)
            .padding()
        }
        .background(.gray.opacity(0.1))
    }
    
    private var imagesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
            ForEach(postService.posts, id: \.id) { post in
                let imageURL = URL(string: post.imageUrl)
                NavigationLink(destination: ProfileFeedView(userId: user?.uid ?? "")) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                }
            }
        }
    }
    
    private func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
            } else if let data = snapshot?.data() {
                user = UserProfile(
                    uid: data["uid"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    profileImageURL: data["profileImageURL"] as? String ?? ""
                )
            }
        }
    }
    
    private func updateProfile(username: String, bio: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "username": username,
            "bio": bio
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
            } else {
                loadUserProfile()
            }
        }
    }
}

