import FirebaseFirestore
import FirebaseAuth

class PostService: ObservableObject {
    @Published var posts: [Post] = []
    private let db = Firestore.firestore()
    
    func fetchPosts() {
        let query = db.collection("posts").order(by: "timestamp", descending: true)
        fetchPosts(query: query)
    }
    
    func fetchUserPosts(userId: String) {
        let query = db.collection("posts")
            .whereField("author.uid", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
        fetchPosts(query: query)
    }
    
    private func fetchPosts(query: Query) {
        query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Ошибка при получении постов: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            DispatchQueue.main.async {
                self.posts = documents.compactMap(self.parsePost)
            }
        }
    }
    
    private func parsePost(from doc: QueryDocumentSnapshot) -> Post? {
        let data = doc.data()
        guard
            let imageUrl = data["imageUrl"] as? String,
            let likes = data["likes"] as? Int,
            let likedBy = data["likedBy"] as? [String],
            let authorData = data["author"] as? [String: Any],
            let uid = authorData["uid"] as? String,
            let email = authorData["email"] as? String,
            let username = authorData["username"] as? String
        else {
            print("Ошибка парсинга поста: \(doc.documentID)")
            return nil
        }
        let author = UserProfile(uid: uid, email: email, username: username, bio: "", profileImageURL: nil)
        return Post(id: doc.documentID, imageUrl: imageUrl, author: author, likes: likes, likedBy: likedBy)
    }
    
    func toggleLike(post: Post) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let postRef = db.collection("posts").document(post.id)
        
        db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(postRef)
                var likedBy = snapshot.data()?["likedBy"] as? [String] ?? []
                var likes = snapshot.data()?["likes"] as? Int ?? 0
                
                if likedBy.contains(uid) {
                    likes -= 1
                    likedBy.removeAll { $0 == uid }
                } else {
                    likes += 1
                    likedBy.append(uid)
                }
                
                transaction.updateData(["likes": likes, "likedBy": likedBy], forDocument: postRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }) { _, error in
            if let error = error {
                print("Ошибка при лайке: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchComments(postId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("posts").document(postId).collection("comments")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Ошибка загрузки комментариев: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let comments = snapshot?.documents.compactMap(self.parseComment) ?? []
                completion(comments)
            }
    }
    
    private func parseComment(from doc: QueryDocumentSnapshot) -> Comment? {
        let data = doc.data()
        
        guard
            let text = data["text"] as? String,
            let timestamp = data["timestamp"] as? Timestamp,
            let userProfileData = data["userProfile"] as? [String: Any],
            let uid = userProfileData["uid"] as? String,
            let username = userProfileData["username"] as? String,
            let profileImageURL = userProfileData["profileImageURL"] as? String
        else {
            print("Ошибка парсинга комментария: \(doc.documentID)")
            return nil
        }
        
        let userProfile = UserProfile(uid: uid, email: "", username: username, bio: "", profileImageURL: profileImageURL)
        return Comment(id: doc.documentID, text: text, userProfile: userProfile, timestamp: timestamp.dateValue())
    }
    
    func addComment(postId: String, commentText: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Ошибка получения пользователя: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            let data = snapshot?.data() ?? [:]
            let username = data["username"] as? String ?? "Unknown"
            let profileImageURL = data["profileImageURL"] as? String ?? ""
            
            let commentData: [String: Any] = [
                "text": commentText,
                "timestamp": Timestamp(date: Date()),
                "userProfile": [
                    "uid": uid,
                    "username": username,
                    "profileImageURL": profileImageURL
                ]
            ]
            
            self.db.collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
                if let error = error {
                    print("Ошибка добавления комментария: \(error.localizedDescription)")
                }
                completion(error == nil)
            }
        }
    }
    
    func deletePost(post: Post, completion: @escaping (Bool) -> Void) {
        db.collection("posts").document(post.id).delete { error in
            if let error = error {
                print("Ошибка удаления поста: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
