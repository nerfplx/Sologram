import SwiftUI
import PhotosUI

struct ProfileImagePicker: View {
    @Binding var profileImage: UIImage?
    @Binding var selectedImageItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            PhotosPicker(selection: $selectedImageItem, matching: .images) {
                Text("Select Profile Picture")
                    .foregroundColor(.blue)
            }
            .onChange(of: selectedImageItem) {
                loadImage(from: selectedImageItem)
            }
            .padding()
        }
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self.profileImage = image
                    }
                case .failure(let error):
                    print("Error loading image: \(error.localizedDescription)")
                }
            }
        }
    }
}
