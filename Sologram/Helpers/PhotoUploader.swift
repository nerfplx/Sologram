import SwiftUI
import PhotosUI
import Cloudinary
import FirebaseAuth
import FirebaseFirestore

struct PhotoUploader: View {
    @Binding var userImages: [String]
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let cloudinary = CLDCloudinary(configuration: CLDConfiguration(
        cloudName: "dl1ajqx6c",
        apiKey: "362329481363912",
        apiSecret: "9SmqkB_CY_wOJxaKpcRtZs7EbGw"
    ))
    
    var body: some View {
        PhotosPicker(selection: $selectedImageItem, matching: .images) {
            Image(systemName: "plus.app")
                .font(.title)
                .foregroundStyle(.white)
        }
        .onChange(of: selectedImageItem) { newItem, _ in
            handleImageSelection(newItem: newItem)
        }
    }
    
    private func handleImageSelection(newItem: PhotosPickerItem?) {
        guard let newItem = newItem else { return }
        
        Task {
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    uploadImageToCloudinary(image: image)
                }
            } catch {
                errorMessage = "Ошибка загрузки изображения"
            }
        }
    }
    
    private func uploadImageToCloudinary(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        isUploading = true
        
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "ml_default", completionHandler:  { result, error in
            DispatchQueue.main.async {
                self.isUploading = false
                
                if let error = error {
                    self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                } else if let url = result?.secureUrl {
                    self.saveImageUrlToFirestore(url: url)
                }
            }
        })
    }
    
    private func saveImageUrlToFirestore(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).collection("images").addDocument(data: ["url": url]) { error in
            if let error = error {
                self.errorMessage = "Ошибка сохранения изображения: \(error.localizedDescription)"
            } else {
                self.addPost(imageUrl: url, userId: uid)
                self.userImages.append(url)
            }
        }
    }
    
    private func addPost(imageUrl: String, userId: String) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil,
                  let email = data["email"] as? String,
                  let username = data["username"] as? String else {
                self.errorMessage = "Ошибка получения данных пользователя"
                return
            }
            
            let postRef = self.db.collection("posts").document()
            let postData: [String: Any] = [
                "imageUrl": imageUrl,
                "likes": 0,
                "likedBy": [],
                "timestamp": Timestamp(date: Date()),
                "author": ["uid": userId, "email": email, "username": username]
            ]
            
            postRef.setData(postData) { error in
                if let error = error {
                    self.errorMessage = "Ошибка добавления поста: \(error.localizedDescription)"
                }
            }
        }
    }
}
