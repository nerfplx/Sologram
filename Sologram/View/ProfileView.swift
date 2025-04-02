import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var user: UserProfile? = nil
//    @State private var userImages: [String] = []
    @State private var errorMessage: String?
    @ObservedObject var postService = PostService()
    
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
                    
                    NavigationBarView(userImages: .constant(postService.posts.map { $0.imageUrl }))
                } else {
                    ProgressView()
                }
            }
            .background(.black)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                loadUserProfile()
                if let userId = user?.uid {
                    postService.fetchUserPosts(userId: userId)
                }
            }
            .onChange(of: user) { newUser, _ in
                if let uid = newUser?.uid {
                    postService.fetchUserPosts(userId: uid)
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
                .background(.black)
                .foregroundColor(.white)
                .font(.title)
                .bold()
            
            Menu {
                NavigationLink(destination: EditProfileView(user: user, onSave: { username, bio in
                    updateProfile(username: username, bio: bio)
                })) {
                    Text("Edit Profile")
                }
            } label: {
                Image(systemName: "line.horizontal.3")
            }
            .foregroundStyle(.white)
            .bold()
            .font(.title2)
            .padding()
        }
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
    
//    private func loadUserImages() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let db = Firestore.firestore()
//        db.collection("users").document(uid).collection("images").getDocuments { snapshot, error in
//            if let error = error {
//                errorMessage = "Failed to load images: \(error.localizedDescription)"
//            } else {
//                userImages = snapshot?.documents.compactMap { $0["url"] as? String } ?? []
//            }
//        }
//    }
    
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

#Preview {
    ProfileView()
}
