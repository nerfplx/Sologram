import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var userImages: [String]
    @StateObject private var postService = PostService()
    @State private var showCommentsModal = false
    @State private var selectedPost: Post?
    @State private var commentText: String = ""
    @State private var comments: [Comment] = []
    @State private var showUserList = false
    @State private var selectedChat: (chatId: String, recipientUsername: String)? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                postFeed
                NavigationBarView(userImages: $userImages)
            }
            .background(Color("grayCustom"))
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showCommentsModal) {
                if let post = selectedPost {
                    CommentsModalView(
                        post: $selectedPost,
                        commentText: $commentText,
                        comments: $comments,
                        postService: postService
                    )
                }
            }
            .navigationDestination(isPresented: $showUserList) {
                UserListView()
            }
        }

        .onAppear {
            postService.fetchPosts()
        }
    }
    
    private var header: some View {
        HStack {
            Text("Sologram")
                .font(.largeTitle)
                .bold()
            Spacer()
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
            }
            Button {
                showUserList = true
            } label: {
                Image(systemName: "paperplane")
            }
        }
        .padding()
        .foregroundStyle(.white)
        .background(.gray.opacity(0.1))
    }
    
    private var postFeed: some View {
        ScrollView {
            LazyVStack {
                ForEach(postService.posts) { post in
                    postCard(post)
                }
            }
        }
    }
    
    private func postCard(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.author.username)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            AsyncImage(url: URL(string: post.imageUrl)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .background(.gray)
            } placeholder: {
                ProgressView()
            }
            
            HStack(spacing: 16) {
                Button {
                    postService.toggleLike(post: post)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: post.likedBy.contains(Auth.auth().currentUser?.uid ?? "")
                              ? "heart.fill"
                              : "heart")
                        Text("\(post.likes)")
                    }
                }
                
                Button {
                    selectedPost = post
                    postService.fetchComments(postId: post.id) { comments in
                        self.comments = comments
                    }
                    showCommentsModal = true
                } label: {
                    Image(systemName: "bubble.left")
                }
                
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.clear)
    }
}

#Preview {
    @Previewable @State var userImages: [String] = []
    return HomeView(userImages: $userImages)
}
