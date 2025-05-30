import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileFeedView: View {
    let userId: String
    @StateObject private var postService: PostService
    @State private var selectedPost: Post?
    @State private var commentText: String = ""
    @State private var comments: [Comment] = []
    @State private var showCommentsModal = false
    @State private var userProfile: UserProfile? = nil
    @Environment(\.dismiss) private var dismiss

    init(userId: String) {
        self.userId = userId
        _postService = StateObject(wrappedValue: PostService())
    }

    #if DEBUG
    init(userId: String, mockService: PostService, mockProfile: UserProfile?) {
        self.userId = userId
        _postService = StateObject(wrappedValue: mockService)
        _userProfile = State(initialValue: mockProfile)
    }
    #endif

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(10)
                }
                Spacer()
                Text("Публикации")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .bold()
                    .padding(.trailing)
                Spacer()
            }
            .padding(.horizontal)
            .background(Color("grayCustom"))

            ScrollView {
                ForEach(postService.posts, id: \..id) { (post: Post) in
                    VStack {
                        HStack {
                            if let user = userProfile {
                                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                                    image.resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                                .clipShape(Circle())
                                .frame(width: 20, height: 20)

                                Text(user.username)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Spacer()

                            Menu {
                                Button(action: {
                                    deletePost(post: post)
                                }) {
                                    Label("Удалить", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(.black.opacity(0.7), in: Circle())
                                    .padding(5)
                            }
                        }

                        AsyncImage(url: URL(string: post.imageUrl)) { image in
                            image.resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)

                        HStack {
                            Button(action: { postService.toggleLike(post: post) }) {
                                Image(systemName: post.likedBy.contains(Auth.auth().currentUser?.uid ?? "") ? "heart.fill" : "heart")
                                    .foregroundColor(.white)
                                Text("\(post.likes)")
                                    .foregroundStyle(.white)
                            }
                            Button(action: {
                                selectedPost = post
                                postService.fetchComments(postId: post.id) { comments in
                                    self.comments = comments
                                }
                                showCommentsModal.toggle()
                            }) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.white)
                                    .padding(.leading)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .background(Color("grayCustom"))
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                postService.fetchUserPosts(userId: userId)
                loadUserProfile()
            }
            #else
            postService.fetchUserPosts(userId: userId)
            loadUserProfile()
            #endif
        }
        .sheet(isPresented: $showCommentsModal) {
            if let selectedPost = selectedPost {
                CommentsModalView(post: $selectedPost, commentText: $commentText, comments: $comments, postService: postService)
            }
        }
    }

    private func loadUserProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
            } else if let data = snapshot?.data() {
                userProfile = UserProfile(
                    uid: data["uid"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    profileImageURL: data["profileImageURL"] as? String ?? ""
                )
            }
        }
    }

    private func deletePost(post: Post) {
        postService.deletePost(post: post) { success in
            if success {
                postService.fetchUserPosts(userId: userId)
            } else {
                print("Ошибка при удалении поста")
            }
        }
    }
}

#Preview {
    ProfileFeedView(
        userId: "demo_user_id",
        mockService: MockPostService(),
        mockProfile: mockUserProfile
    )
}
