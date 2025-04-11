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
        .onChange(of: selectedImageItem) { newItem in
            print("selectedImageItem изменился")
            handleImageSelection(newItem: newItem)
        }
    }

    private func handleImageSelection(newItem: PhotosPickerItem?) {
        print("handleImageSelection вызвана")
        guard let newItem = newItem else { return }
        print("Выбран элемент, загружаем данные...")
        Task {
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    print("Данные изображения успешно получены, начинаем загрузку...")
                    uploadImageToCloudinary(image: image)
                } else {
                    print("Не удалось получить данные или преобразовать в UIImage")
                }
            } catch {
                errorMessage = "Ошибка загрузки изображения"
                print("Ошибка загрузки изображения: \(error.localizedDescription)")
            }
        }
    }

    private func uploadImageToCloudinary(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        print("Начинается загрузка в Cloudinary...")
        isUploading = true

        cloudinary.createUploader().upload(data: imageData, uploadPreset: "ml_default", completionHandler: { result, error in
            DispatchQueue.main.async {
                self.isUploading = false
                
                if let error = error {
                    self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                    print("Ошибка Cloudinary: \(error.localizedDescription)")
                    return
                }
                
                guard let url = result?.secureUrl else {
                    self.errorMessage = "Не удалось получить URL изображения"
                    print("Не удалось получить URL изображения")
                    return
                }
                print("Изображение загружено, URL: \(url)")
                self.saveImageUrlToFirestore(url: url)
            }
        })
    }

    private func saveImageUrlToFirestore(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Пользователь не авторизован")
            return
        }

        db.collection("users").document(uid).collection("images").addDocument(data: ["url": url]) { error in
            if let error = error {
                self.errorMessage = "Ошибка сохранения изображения: \(error.localizedDescription)"
                print("Ошибка Firestore при сохранении изображения: \(error.localizedDescription)")
            } else {
                self.addPost(imageUrl: url, userId: uid)
                self.userImages.append(url)
                print("Изображение успешно сохранено в Firestore")
            }
        }
    }

    private func addPost(imageUrl: String, userId: String) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Ошибка получения данных пользователя: \(error?.localizedDescription ?? "неизвестная ошибка")")
                self.errorMessage = "Ошибка получения данных пользователя"
                return
            }

            let email = data["email"] as? String ?? ""
            let username = data["username"] as? String ?? ""

            let postData: [String: Any] = [
                "imageUrl": imageUrl,
                "likes": 0,
                "likedBy": [],
                "timestamp": Timestamp(date: Date()),
                "author": ["uid": userId, "email": email, "username": username]
            ]

            db.collection("posts").document().setData(postData) { error in
                if let error = error {
                    self.errorMessage = "Ошибка добавления поста: \(error.localizedDescription)"
                    print("Ошибка при добавлении поста в Firestore: \(error.localizedDescription)")
                } else {
                    print("Пост успешно добавлен в Firestore")
                }
            }
        }
    }
}
