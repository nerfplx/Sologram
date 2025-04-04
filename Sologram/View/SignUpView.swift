import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var navigateToEditProfile = false
    @State private var userProfile: UserProfile?
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: signUpUser) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToEditProfile) {
                if let userProfile = userProfile {
                    EditProfileView(user: userProfile, onSave: saveProfileChanges)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    func signUpUser() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "username": "user_\(Int.random(in: 1000...9999))",
                    "bio": "",
                    "profileImageURL": ""
                ]
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        self.errorMessage = "Failed to save user: \(error.localizedDescription)"
                    } else {
                        print("User profile saved in Firestore")
                        userProfile = UserProfile(
                            uid: user.uid,
                            email: user.email ?? "",
                            username: "user_\(Int.random(in: 1000...9999))",
                            bio: "",
                            profileImageURL: ""
                        )
                        navigateToEditProfile = true
                    }
                }
            }
        }
    }
    func saveProfileChanges(username: String, bio: String) {
        print("Saving profile changes: \(username), \(bio)")
    }
}

#Preview {
    SignUpView()
}
