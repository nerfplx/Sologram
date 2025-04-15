import SwiftUI
import FirebaseAuth

struct imageModel: Identifiable {
    var id: String = UUID().uuidString
    var image: String
}

let images: [imageModel] = [
    .init(image: "https://picsum.photos/300/400?1"),
    .init(image: "https://picsum.photos/300/400?2"),
    .init(image: "https://picsum.photos/300/400?3"),
]

struct ImageLoopView: View {
    var body: some View {
        NavigationStack {
            VStack {
                LoopingStack {
                    ForEach(images) {image in
                        AsyncImage(url: URL(string: image.image)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 250, height: 400)
                            case .success(let img):
                                img.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 300, height: 600)
                                    .clipShape(.rect(cornerRadius: 30))
                                    .padding(5)
                                    .background {
                                        RoundedRectangle(cornerRadius: 35)
                                            .fill(.background)
                                    }
                            case .failure:
                                Image(systemName: "xmark.octagon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Looping Stack")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray.opacity(0.2))
        }
    }
}

struct LoopingStack<ImageLoopView: View>: View {
    var visibleCardsCount: Int = 2
    @ViewBuilder var content: ImageLoopView
    @State private var rotation: Int = 0
    var body: some View {
        Group(subviews: content) { collection in
            let collection = collection.rotateFromLeft(by: rotation)
            let count = collection.count
            
            ZStack {
                ForEach(collection) { view in
                    let index = collection.index(view)
                    let zIndex = Double(count - index)

                    LoopingStackCardView(index: index, count: count, visibleCardsCount: visibleCardsCount, rotation: $rotation) {
                        view
                    }
                    .zIndex(zIndex)
                }
            }
        }
    }
}

fileprivate struct LoopingStackCardView<ImageLoopView: View>: View {
    var index: Int
    var count: Int
    var visibleCardsCount: Int
    @Binding var rotation: Int
    @ViewBuilder var content: ImageLoopView
    @State private var offset: CGFloat = .zero
    @State private var viewSize: CGSize = .zero
    var body: some View {
        let extraOffset = min(CGFloat(index) * 20, CGFloat(visibleCardsCount) * 20)
        let scale = 1 - min(CGFloat(index) * 0.07, CGFloat(visibleCardsCount) * 0.07)
        let rotationDegree: CGFloat = -30
        let rotation = max(min(-offset / viewSize.width, 1), 0) * -30
        
        content
            .onGeometryChange(for: CGSize.self, of: {
                $0.size
            }, action: {
                viewSize = $0
            })
            .offset(x: extraOffset)
            .scaleEffect(scale, anchor:.trailing)
            .animation(.smooth(duration: 0.25, extraBounce: 0), value: index)
            .offset(x: offset)
            .rotation3DEffect(.init(degrees: rotation), axis: (0, 1, 0), anchor: .center, perspective: 0.5)
            .gesture(
                DragGesture()
                    .onChanged{ value in
                        let xOffset = -max(-value.translation.width, 0)
                        offset = xOffset
                    }.onEnded { value in
                        let xVelocity = max(-value.velocity.width / 5, 0)
                        
                        if(-offset + xVelocity) > (viewSize.width * 0.65) {
                            pushToNextCard()
                        } else {
                            withAnimation(.smooth(duration: 0.3, extraBounce: 0 )) {
                                offset = .zero
                            }
                        }
                    },
                isEnabled: index == 0 && count > 1
            )
    }
    
    private func pushToNextCard() {
        withAnimation(.smooth(duration: 0.25, extraBounce: 0).logicallyComplete(after: 0.15), completionCriteria: .logicallyComplete) {
            offset = -viewSize.width
        } completion: {
            rotation += 1
            withAnimation(.smooth(duration: 0.25, extraBounce: 0)) {
                offset = .zero
            }
        }
    }
    
}

extension SubviewsCollection {
    func rotateFromLeft(by: Int) -> [SubviewsCollection.Element] {
        let moveIndex = by % count
        let rotatedElements = Array(self[moveIndex...]) + Array(self[0..<moveIndex])
        return rotatedElements
    }
}

extension [SubviewsCollection.Element] {
    func index(_ item: SubviewsCollection.Element) -> Int {
        firstIndex(where: { $0.id == item.id }) ?? 0
    }
}


