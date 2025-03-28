import SwiftUI

struct NavigationBarView: View {
    var body: some View {
        HStack {
            Image(systemName: "house")
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "plus.app")
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "play.square.stack")
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.black)
        .foregroundColor(.white)
        .font(.title)
        .ignoresSafeArea(edges: .bottom)
    }
}
