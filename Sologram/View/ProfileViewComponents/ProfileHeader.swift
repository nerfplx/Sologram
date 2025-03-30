import SwiftUI

struct ProfileHeader: View {
    var user: UserProfile
    
    var body: some View {
        VStack(alignment: .leading) {
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
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .padding(.leading)
            Text(user.email)
                .foregroundColor(.gray)
                .padding(.leading)
            Text(user.bio)
                .foregroundStyle(.white)
                .padding(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ProfileView()
}
