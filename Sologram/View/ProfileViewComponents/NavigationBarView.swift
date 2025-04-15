import SwiftUI

struct NavigationBarView: View {
    @Binding var userImages: [String]

    var body: some View {
        HStack {
            NavigationLink(destination: HomeView(userImages: $userImages)) {
                Image(systemName: "house")
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white)
            Spacer()
            PhotoUploader(userImages: $userImages)
            Spacer()
            NavigationLink(destination: ImageLoopView()) {
                Image(systemName: "play.square.stack")
                    .foregroundStyle(.white)
            }
            Spacer()
            NavigationLink(destination: ProfileView()) {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.black)
        .foregroundColor(.white)
        .font(.title)
        .ignoresSafeArea(edges: .bottom)
    }
}
