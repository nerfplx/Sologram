import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseFirestore
import Cloudinary

struct EditProfileView: View {
    @State private var username: String
    @State private var bio: String
    var onSave: (String, String) -> Void
    @State private var navigateToProfile = false
    
    @State private var selectedImageItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploading = false

    init(user: UserProfile, onSave: @escaping (String, String) -> Void) {
        _username = State(initialValue: user.username)
        _bio = State(initialValue: user.bio)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ProfileImagePicker(profileImage: $profileImage, selectedImageItem: $selectedImageItem)

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Bio", text: $bio)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                Button(action: {
                    onSave(username, bio)
                    if let image = profileImage {
                        uploadImage(image)
                    }
                    navigateToProfile = true
                }) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView()
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    func uploadImage(_ image: UIImage) {
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

           let uploadPreset = "ml_default"

           cloudinary.createUploader().upload(data: imageData, uploadPreset: uploadPreset) { result, error in
               DispatchQueue.main.async {
                   isUploading = false
                   if let result = result, let url = result.secureUrl {
                       updateProfileImageURL(url)
                   }
               }
           }
       }
       
       func updateProfileImageURL(_ url: String) {
           guard let uid = Auth.auth().currentUser?.uid else { return }
           let db = Firestore.firestore()

           db.collection("users").document(uid).updateData([
               "profileImageURL": url
           ])
       }
}
