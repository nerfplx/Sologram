import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import Cloudinary

struct ProfileView: View {
    //    @State private var user: UserProfile? = nil
    @State private var user: UserProfile? = UserProfile(
        uid: "123",
        email: "test@example.com",
        username: "Test User",
        bio: "This is a bio.",
        profileImageURL: ""
    )
    @State private var errorMessage: String?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var userImages: [String] = ["https://images.prom.ua/2987667453_w600_h600_2987667453.jpg", "https://avatarko.ru/img/kartinka/1/avatarko_anonim.jpg", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ1zwhySGCEBxRRFYIcQgvOLOpRGqrT3d7Qng&s", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSx6yT7oBWFeKJH-85mTe_LX8XL5RXw1mRFow&s", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR9SRRmhH4X5N2e4QalcoxVbzYsD44C-sQv-w&s", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTbCFD9hBq5ZBfdDqHa1IPFZORSL3EkPSxU2tomxsaeiOcuOyQMbUhNN-htl5xLTtZwvMU&usqp=CAU"]
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text(user?.email.split(separator: "@")[0] ?? "login")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.black)
                        .foregroundColor(.white)
                        .font(.title)
                        .bold()
                }
                ScrollView {
                    VStack {
                        if let user = user {
                            ProfileHeader(user: user)
                            PhotosPicker(selection: $selectedImageItem, matching: .images) {
                                Text("Upload Profile Picture")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .onChange(of: selectedImageItem) { newItem in
                                if let newItem = newItem {
                                    Task {
                                        if let data = try? await newItem.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            selectedImage = image
                                            uploadImageToCloudinary(image: image)
                                        }
                                    }
                                }
                            }
                            
                            NavigationLink(destination: EditProfileView(user: user, onSave: { username, bio in
                                updateProfile(username: username, bio: bio)
                            })) {
                                Text("Edit Profile")
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                                ForEach(userImages, id: \ .self) { imageUrl in
                                    AsyncImage(url: URL(string: imageUrl)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                        case .success(let image):
                                            image.resizable()
                                        case .failure:
                                            Image(systemName: "photo")
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 150, height: 150)
                                }
                            }
                            .padding()
                        } else {
                            ProgressView()
                        }
                    }
                }
                NavigationBarView()
            }
            .background(.gray).opacity(0.6)
            .onAppear {
                loadUserProfile()
                loadUserImages()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

extension ProfileView {
    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
            } else if let data = snapshot?.data() {
                user = UserProfile(
                    uid: data["uid"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    profileImageURL: data["profileImageURL"] as? String ?? ""
                )
            }
        }
    }

    func updateProfile(username: String, bio: String, profileImageURL: String? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        var data: [String: Any] = [
            "username": username,
            "bio": bio
        ]
        
        if let profileImageURL = profileImageURL {
            data["profileImageURL"] = profileImageURL
        }
        
        db.collection("users").document(uid).updateData(data) { error in
            if let error = error {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
            } else {
                loadUserProfile()
            }
        }
    }
    
    func loadUserImages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("images").getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Failed to load images: \(error.localizedDescription)"
            } else {
                userImages = snapshot?.documents.compactMap { $0["url"] as? String } ?? []
            }
        }
    }
    
    func saveImageUrlToFirestore(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("images").addDocument(data: ["url": url]) { error in
            if let error = error {
                errorMessage = "Failed to save image: \(error.localizedDescription)"
            } else {
                loadUserImages()
            }
        }
    }
    
    func uploadImageToCloudinary(image: UIImage) {
        isUploading = true
        let config = CLDConfiguration(cloudName: "dl1ajqx6c", apiKey: "362329481363912", apiSecret: "9SmqkB_CY_wOJxaKpcRtZs7EbGw")
        let cloudinary = CLDCloudinary(configuration: config)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "ml_default") { result, error in
            DispatchQueue.main.async {
                isUploading = false
                if let error = error {
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                } else if let url = result?.secureUrl {
                    saveImageUrlToFirestore(url: url)
                }
            }
        }
    }
}


#Preview {
    ProfileView()
}

