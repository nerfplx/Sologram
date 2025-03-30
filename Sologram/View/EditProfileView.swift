import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseFirestore
import Cloudinary

struct EditProfileView: View {
    @State private var username: String
    @State private var bio: String
    var onSave: (String, String) -> Void
    
    @State private var selectedImageItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploading = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(user: UserProfile, onSave: @escaping (String, String) -> Void) {
        _username = State(initialValue: user.username)
        _bio = State(initialValue: user.bio)
        self.onSave = onSave
    }
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        saveChanges()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                .padding()
                
                VStack(spacing: 16) {
                    ProfileImagePicker(profileImage: $profileImage, selectedImageItem: $selectedImageItem)
                    
                    TextField("Username", text: $username)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundStyle(.white)
                        .background(.black)
                        .overlay(Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray),
                                 alignment: .bottom)
                    
                    TextField("Bio", text: $bio)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundStyle(.white)
                        .background(.black)
                        .overlay(Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray),
                                 alignment: .bottom)
                    
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(.black)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    private func saveChanges() {
        onSave(username, bio)
        if let image = profileImage {
            uploadImage(image)
        } else {
            dismiss()
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        isUploading = true
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isUploading = false
            return
        }
        
        let cloudinary = CLDCloudinary(configuration: CLDConfiguration(
            cloudName: "dl1ajqx6c",
            apiKey: "362329481363912",
            apiSecret: "9SmqkB_CY_wOJxaKpcRtZs7EbGw"
        ))
        
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "ml_default", completionHandler:  { result, _ in
            DispatchQueue.main.async {
                isUploading = false
                if let url = result?.secureUrl {
                    updateProfileImageURL(url)
                }
                dismiss()
            }
        })
    }
    
    private func updateProfileImageURL(_ url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["profileImageURL": url])
    }
}

#Preview {
    EditProfileView(user: UserProfile(uid: "123", email: "test@example.com", username: "TestUser", bio: "Bio", profileImageURL: "")) { _, _ in }
}
