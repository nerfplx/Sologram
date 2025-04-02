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
    
    func fetchUserPosts(userId: String) {
        db.collection("posts")
            .whereField("author.uid", isEqualTo: userId)
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
            } else {
                self.fetchUserPosts(userId: post.author.uid)
            }
        }
    }
    
    func fetchComments(postId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("posts").document(postId).collection("comments")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    print("Ошибка получения комментариев: \(error?.localizedDescription ?? "неизвестная ошибка")")
                    return
                }
                
                let comments = documents.compactMap { doc in
                    self.parseComment(from: doc)
                }
                completion(comments)
            }
    }
    
    private func parseComment(from doc: QueryDocumentSnapshot) -> Comment? {
        let data = doc.data()
        
        guard let text = data["text"] as? String,
              let timestamp = data["timestamp"] as? Timestamp,
              let userProfileData = data["userProfile"] as? [String: Any],
              let uid = userProfileData["uid"] as? String,
              let username = userProfileData["username"] as? String,
              let profileImageURL = userProfileData["profileImageURL"] as? String else { return nil }
        
        let userProfile = UserProfile(uid: uid, email: "", username: username, bio: "", profileImageURL: profileImageURL)
        return Comment(id: doc.documentID, text: text, userProfile: userProfile, timestamp: timestamp.dateValue())
    }
    
    func addComment(postId: String, commentText: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Ошибка при получении данных пользователя: \(error?.localizedDescription ?? "")")
                completion(false)
                return
            }
            
            let username = data["username"] as? String ?? "Unknown"
            let profileImageURL = data["profileImageURL"] as? String ?? ""
            
            db.collection("posts").document(postId).collection("comments").addDocument(data: [
                "text": commentText,
                "timestamp": Timestamp(date: Date()),
                "userProfile": [
                    "uid": uid,
                    "username": username,
                    "profileImageURL": profileImageURL
                ]
            ]) { error in
                if let error = error {
                    print("Ошибка при добавлении комментария: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Комментарий успешно добавлен!")
                    completion(true)
                }
            }
        }
    }
    
    func deletePost(post: Post, completion: @escaping (Bool) -> Void) {
        let postId = post.id
        
        let db = Firestore.firestore()
        db.collection("posts").document(postId).delete() { error in
            if let error = error {
                print("Ошибка при удалении поста: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Пост удален успешно")
                completion(true)
            }
        }
    }
}
