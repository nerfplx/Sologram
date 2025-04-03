import SwiftUI

struct ContentView: View {
    @Binding var userImages: [String]
    
    var body: some View {
        LoginView(userImages: $userImages)
    }
}
