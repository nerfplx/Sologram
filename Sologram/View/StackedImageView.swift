import SwiftUI
import FirebaseAuth

struct StackedImage: Identifiable, Equatable {
    let id = UUID()
    var image: String
}

struct StackedImageView: View {
    @ObservedObject var postService = PostService()
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(postService.posts.indices, id: \.self) { index in
                    let post = postService.posts[index]
                    let isTopCard = index == postService.posts.count - 1
                    
                    AsyncImage(url: URL(string: post.imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                    .frame(width: geo.size.width * 0.75, height: geo.size.height * 0.6)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .scaleEffect(getScale(index: index))
                    .offset(
                        x: isTopCard ? dragOffset.width : CGFloat((postService.posts.count - 1 - index) * 20),
                        y: CGFloat((postService.posts.count - 1 - index) * 5)
                    )
                    .rotationEffect(.degrees(isTopCard ? Double(dragOffset.width / 20) : 0))
                    .zIndex(Double(index))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
                    .gesture(
                        isTopCard ?
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                if abs(value.translation.width) > 100 {
                                    swipeCard()
                                }
                            } : nil
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
        }
        .onAppear {
            if let userId = Auth.auth().currentUser?.uid {
                postService.fetchUserPosts(userId: userId)
            }
        }
    }
    
    private func getScale(index: Int) -> CGFloat {
        let topIndex = postService.posts.count - 1
        let delta = topIndex - index
        switch delta {
        case 0: return 1.0
        case 1: return 0.95
        case 2: return 0.9
        default: return 0.85
        }
    }

    private func swipeCard() {
        withAnimation {
            if let last = postService.posts.last {
                postService.posts.removeLast()
                postService.posts.insert(last, at: 0)
            }
        }
    }
}
