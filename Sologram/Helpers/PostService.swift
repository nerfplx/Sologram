import FirebaseFirestore
import FirebaseAuth

class PostService: ObservableObject {
    @Published var posts: [Post] = []
    
    private let db = Firestore.firestore()
    
    func fetchPosts() {
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    self.posts = documents.compactMap { doc -> Post? in
                        let data = doc.data()
                        
                        guard let imageUrl = data["imageUrl"] as? String,
                              let likes = data["likes"] as? Int,
                              let authorData = data["author"] as? [String: Any],
                              let uid = authorData["uid"] as? String,
                              let email = authorData["email"] as? String,
                              let username = authorData["username"] as? String else { return nil }
                        
                        let author = UserProfile(uid: uid, email: email, username: username, bio: "", profileImageURL: nil)
                        return Post(id: doc.documentID, imageUrl: imageUrl, author: author, likes: likes)
                    }
                }
            }
    }
}
