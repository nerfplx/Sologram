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
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Sologram")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                    Button(action: {}) {
                        Image(systemName: "paperplane")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(.black)
                
                ScrollView {
                    ForEach(postService.posts) { post in
                        VStack {
                            HStack {
                                Text(post.author.username)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding([.leading, .top])
                            
                            AsyncImage(url: URL(string: post.imageUrl)) { image in
                                image.resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                    .background(.gray)
                            } placeholder: {
                                ProgressView()
                            }
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
                        .background(.black)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding([.horizontal, .top])
                    }
                }
                .onAppear {
                    postService.fetchPosts()
                }
                NavigationBarView(userImages: $userImages)
            }
            .background(.black)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showCommentsModal) {
                if let post = selectedPost {
                    CommentsModalView(post: $selectedPost, commentText: $commentText, comments: $comments, postService: postService)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var userImages: [String] = []
    return HomeView(userImages: $userImages)
}
