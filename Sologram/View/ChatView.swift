import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    let chatId: String
    let recipientUsername: String
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""

    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            HStack {
                                if message.senderId == Auth.auth().currentUser?.uid {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        scrollView.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Сообщение...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Отправить") {
                    sendMessage()
                }
            }
            .padding()
        }
        .navigationTitle(recipientUsername)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listenForMessages()
        }
    }

    func sendMessage() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let messageData: [String: Any] = [
            "text": newMessage,
            "timestamp": Timestamp(date: Date()),
            "senderId": currentUserId
        ]
        db.collection("chats").document(chatId).collection("messages")
            .addDocument(data: messageData)
        newMessage = ""
    }

    func listenForMessages() {
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    guard
                        let text = data["text"] as? String,
                        let senderId = data["senderId"] as? String,
                        let timestamp = data["timestamp"] as? Timestamp
                    else {
                        return nil
                    }
                    return Message(id: doc.documentID, text: text, senderId: senderId, timestamp: timestamp.dateValue())
                }
            }
    }
}
