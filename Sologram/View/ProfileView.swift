import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
    
    var body: some View {
        NavigationStack {
            HStack {
                Text(user?.email.split(separator: "@")[0] ?? "login")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.black)
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
            }
            VStack {
                if let user = user {
                    if let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: profileImageURL)) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }
                        .padding()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .padding()
                    }
                    Text(user.username)
                        .fontWeight(.bold)
                    Text(user.email)
                        .foregroundColor(.gray)
                    Text(user.bio)
                        .padding(.leading)
                    NavigationLink(destination: EditProfileView(user: user, onSave: { username, bio in
                        updateProfile(username: username, bio: bio)
                    })) {
                        Text("Edit Profile")
                            .foregroundColor(.blue)
                            .padding()
                    }
                } else {
                    ProgressView()
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear(perform: loadUserProfile)
            .navigationBarBackButtonHidden(true)
            Spacer()
            NavigationBarView()
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
}

#Preview {
    ProfileView()
}

