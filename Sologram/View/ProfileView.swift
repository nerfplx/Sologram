import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    //    @State private var user: UserProfile? = nil
    @State private var user: UserProfile? = UserProfile(
        uid: "123",
        email: "test@example.com",
        username: "Test User",
        bio: "This is a bio",
        profileImageURL: ""
    )
    @State private var errorMessage: String?
    @State private var userImages: [String] = ["https://images.prom.ua/2987667453_w600_h600_2987667453.jpg", "https://avatarko.ru/img/kartinka/1/avatarko_anonim.jpg", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ1zwhySGCEBxRRFYIcQgvOLOpRGqrT3d7Qng&s", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSx6yT7oBWFeKJH-85mTe_LX8XL5RXw1mRFow&s", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR9SRRmhH4X5N2e4QalcoxVbzYsD44C-sQv-w&s", "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTbCFD9hBq5ZBfdDqHa1IPFZORSL3EkPSxU2tomxsaeiOcuOyQMbUhNN-htl5xLTtZwvMU&usqp=CAU"]
    
    var body: some View {
        NavigationStack {
            VStack {
                if let user = user {
                    HStack {
                        Text(user.email.split(separator: "@")[0])
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.black)
                            .foregroundColor(.white)
                            .font(.title)
                            .bold()
                        
                        Menu {
                            NavigationLink(destination: EditProfileView(user: user, onSave: { username, bio in
                                updateProfile(username: username, bio: bio)
                            })) {
                                Text("Edit Profile")
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3")
                        }
                        .foregroundStyle(.white)
                        .bold()
                        .font(.title2)
                        .padding()
                    }
                    ScrollView {
                        VStack {
                            ProfileHeader(user: user)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                                ForEach(userImages, id: \.self) { imageUrl in
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
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                }
                            }
                        }
                        .padding()
                    }
                    NavigationBarView(userImages: $userImages)
                } else {
                    ProgressView()
                }
            }
            .background(.black)
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
    
    func updateProfile(username: String, bio: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "username": username,
            "bio": bio
        ]) { error in
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
}

#Preview {
    ProfileView()
}
