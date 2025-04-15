import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    let chatId: String
    let recipientUsername: String
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @Environment(\.dismiss) var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            messageList
            messageInput
        }
        .background(.black)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 4) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    Text(recipientUsername)
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
        }
        .onAppear {
            listenForMessages()
        }
    }
    
    private var messageList: some View {
        List(messages) { message in
            MessageView(message: message)
        }
        .listStyle(PlainListStyle())
        .listRowBackground(Color.clear)
        .padding(.top)
    }
    
    private var messageInput: some View {
        HStack {
            TextField("Сообщение...", text: $newMessage)
                .padding(10)
                .foregroundStyle(.white)
                .background(.gray.opacity(0.2))
                .cornerRadius(20)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func sendMessage() {
        guard let currentUserId = Auth.auth().currentUser?.uid, !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let messageData: [String: Any] = [
            "text": newMessage,
            "senderId": currentUserId,
            "timestamp": Timestamp()
        ]
        
        db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData)
        newMessage = ""
    }
    
    private func listenForMessages() {
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap { doc in
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

struct MessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.senderId == Auth.auth().currentUser?.uid {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(message.text)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
        .id(message.id)
    }
}
