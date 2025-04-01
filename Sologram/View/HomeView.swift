import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var userImages: [String]
    @StateObject private var postService = PostService()
    
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
                        //                        ForEach(posts) { post in
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
                                Button(action: {}) {
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
        }
    }
}
#Preview {
    @Previewable @State var userImages: [String] = []
    return HomeView(userImages: $userImages)
}





//        @State private var posts: [Post] = [
//            Post(id: "", imageUrl: "https://images.prom.ua/2987667453_w600_h600_2987667453.jpg",
//                     author: UserProfile(uid: "1", email: "user1@example.com", username: "user1", bio: "", profileImageURL: nil),
//                     likes: 150),
//
//            Post(id: "", imageUrl: "https://avatarko.ru/img/kartinka/1/avatarko_anonim.jpg",
//                     author: UserProfile(uid: "2", email: "user2@example.com", username: "user2", bio: "", profileImageURL: nil),
//                     likes: 200),
//
//            Post(id: "", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ1zwhySGCEBxRRFYIcQgvOLOpRGqrT3d7Qng&s",
//                     author: UserProfile(uid: "3", email: "user3@example.com", username: "user3", bio: "", profileImageURL: nil),
//                     likes: 320)
//        ]
