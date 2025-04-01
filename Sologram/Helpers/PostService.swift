import FirebaseFirestore
import FirebaseAuth

class PostService: ObservableObject {
    @Published var posts: [Post] = []
    private let db = Firestore.firestore()
    
    func fetchPosts() {
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                
                DispatchQueue.main.async {
                    self.posts = documents.compactMap { doc in
                        self.parsePost(from: doc)
                    }
                }
            }
    }
    
    private func parsePost(from doc: QueryDocumentSnapshot) -> Post? {
        let data = doc.data()
        
        guard let imageUrl = data["imageUrl"] as? String,
              let likes = data["likes"] as? Int,
              let likedBy = data["likedBy"] as? [String],
              
                let authorData = data["author"] as? [String: Any],
              let uid = authorData["uid"] as? String,
              let email = authorData["email"] as? String,
              let username = authorData["username"] as? String else { return nil }
        
        let author = UserProfile(uid: uid, email: email, username: username, bio: "", profileImageURL: nil)
        return Post(id: doc.documentID, imageUrl: imageUrl, author: author, likes: likes, likedBy: likedBy)
    }
    func toggleLike(post: Post) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let postRef = db.collection("posts").document(post.id)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let postSnapshot: DocumentSnapshot
            do {
                postSnapshot = try transaction.getDocument(postRef)
            } catch {
                errorPointer?.pointee = error as NSError
                print("Ошибка получения документа: \(error.localizedDescription)")
                return nil
            }
            var likedBy = postSnapshot.data()?["likedBy"] as? [String] ?? []
            var likes = postSnapshot.data()?["likes"] as? Int ?? 0
            
            if likedBy.contains(uid) {
                likes -= 1
                likedBy.removeAll { $0 == uid }
            } else {
                likes += 1
                likedBy.append(uid)
            }
            transaction.updateData([
                "likes": likes,
                "likedBy": likedBy
            ], forDocument: postRef)
            
            return nil
        }) { _, error in
            if let error = error {
                print("Ошибка при изменении лайка: \(error.localizedDescription)")
            }
        }
    }
}
