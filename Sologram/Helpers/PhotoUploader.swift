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
    
    var body: some View {
        PhotosPicker(selection: $selectedImageItem, matching: .images) {
            Image(systemName: "plus.app")
                .font(.title)
                .foregroundStyle(.white)
        }
        .onChange(of: selectedImageItem) {
            handleImageSelection()
        }
    }
    
    private func handleImageSelection() {
        guard let newItem = selectedImageItem else { return }
        
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                uploadImageToCloudinary(image: image)
            }
        }
    }
    
    private func uploadImageToCloudinary(image: UIImage) {
        isUploading = true
        let config = CLDConfiguration(cloudName: "dl1ajqx6c", apiKey: "362329481363912", apiSecret: "9SmqkB_CY_wOJxaKpcRtZs7EbGw")
        let cloudinary = CLDCloudinary(configuration: config)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "ml_default", completionHandler:  { result, error in
            DispatchQueue.main.async {
                self.isUploading = false
                
                if let error = error {
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                } else if let url = result?.secureUrl {
                    self.saveImageUrlToFirestore(url: url)
                }
            }
        })
    }
    
    private func saveImageUrlToFirestore(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).collection("images").addDocument(data: ["url": url]) { error in
            if let error = error {
                self.errorMessage = "Failed to save image: \(error.localizedDescription)"
            } else {
                self.addPost(imageUrl: url)
            }
        }
    }
    private func addPost(imageUrl: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil,
                  let email = data["email"] as? String,
                  let username = data["username"] as? String else {
                print("Ошибка получения данных пользователя")
                return
            }
            
            let postRef = db.collection("posts").document()
            let postData: [String: Any] = [
                "imageUrl": imageUrl,
                "likes": 0,
                "likedBy": [],
                "timestamp": Timestamp(date: Date()),
                "author": ["uid": uid, "email": email, "username": username]
            ]
            
            postRef.setData(postData) { error in
                if let error = error {
                    print("Ошибка при добавлении поста: \(error.localizedDescription)")
                } else {
                    print("Пост успешно добавлен!")
                }
            }
        }
    }
}
