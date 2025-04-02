import SwiftUI
import FirebaseAuth

struct ProfileFeedView: View {
    let userId: String
    @StateObject private var postService = PostService()
    @State private var selectedPost: Post?
    @State private var commentText: String = ""
    @State private var comments: [Comment] = []
    @State private var showCommentsModal = false
    
    var body: some View {
        ScrollView {
            ForEach(postService.posts, id: \.id) { (post: Post) in
                VStack {
                    AsyncImage(url: URL(string: post.imageUrl)) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    
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
                    .padding(.top, -20)
                    
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
        .onAppear {
            postService.fetchUserPosts(userId: userId)
        }
        .sheet(isPresented: $showCommentsModal) {
            if let selectedPost = selectedPost {
                CommentsModalView(post: $selectedPost, commentText: $commentText, comments: $comments, postService: postService)
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
