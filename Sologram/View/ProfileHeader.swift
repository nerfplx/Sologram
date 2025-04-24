import SwiftUI

struct ProfileHeader: View {
    var user: UserProfile
    var imageCount: Int
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                    }
                    .padding()
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                VStack {
                    Text("\(imageCount)")
                    Text("публикации")
                }
                VStack {
                    Text("5")
                    Text("подписчики")
                }
                VStack {
                    Text("2")
                    Text("подписки")
                }
            }
            .foregroundStyle(.white)
            .font(.footnote)
            .bold()
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


