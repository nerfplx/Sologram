import SwiftUI

struct CommentsModalView: View {
    @Binding var post: Post?
    @Binding var commentText: String
    @Binding var comments: [Comment]
    var postService: PostService
    
    var body: some View {
            VStack {
                HStack {
                    Text("Комментарии")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding()
                
                ScrollView {
                    ForEach(comments) { comment in
                        HStack {
                            AsyncImage(url: URL(string: comment.userProfile.profileImageURL ?? "")) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(comment.userProfile.username)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(comment.timestampFormatted)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Text(comment.text)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                HStack {
                    TextField("Написать комментарий...", text: $commentText)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        if let post = post, !commentText.isEmpty {
                            postService.addComment(postId: post.id, commentText: commentText) { success in
                                if success {
                                    postService.fetchComments(postId: post.id) { comments in
                                        self.comments = comments
                                    }
                                    commentText = ""
                                }
                            }
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 5)
                }
                .padding()
            }
            .background(.black)
            .onAppear {
                if let postId = post?.id {
                    postService.fetchComments(postId: postId) { comments in
                        self.comments = comments
                    }
                }
            }
        }
}
