import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @Binding var userImages: [String]
    
    var body: some View {
        if isLoggedIn {
            HomeView(userImages: $userImages)
        } else {
            LoginView(userImages: $userImages)
        }
    }
}
