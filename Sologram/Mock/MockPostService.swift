import Foundation

class MockPostService: PostService {
    override init() {
        super.init()
        self.posts = [
            Post(
                id: "1",
                imageUrl: "https://res.cloudinary.com/dl1ajqx6c/image/upload/v1743627463/file_yxbw3f.jpg",
                author: mockUserProfile,
                likes: 10,
                likedBy: []
            ),
            Post(
                id: "2",
                imageUrl: "https://res.cloudinary.com/dl1ajqx6c/image/upload/v1743627463/file_yxbw3f.jpg",
                author: mockUserProfile,
                likes: 5,
                likedBy: ["demo_user_id"]
            )
        ]
    }
}

