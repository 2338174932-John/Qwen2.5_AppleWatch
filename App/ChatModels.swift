import Foundation

struct LocalMessage: Codable, Identifiable {
    var id = UUID()
    let role: String
    let content: String
}
struct LocalConversation: Codable, Identifiable {
    var id = UUID()
    var messages: [LocalMessage] = []
    var updated = Date()
    var title: String { String(messages.first?.content.prefix(20) ?? "新对话") }
}
