import SwiftUI

struct ProfileHeader: View {
    var user: UserProfile
    
    var body: some View {
        VStack {
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
                .padding(.leading)
            Text(user.email)
                .foregroundColor(.gray)
                .padding(.leading)
            Text(user.bio)
                .padding(.leading)
            
            NavigationLink(destination: EditProfileView(user: user, onSave: { username, bio in
                updateProfile(username: username, bio: bio)
            })) {
                Text("Edit Profile")
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ProfileView()
}
