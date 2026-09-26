import Foundation
import SwiftUI

@MainActor final class OfflineStore: ObservableObject {
    @Published var conversations: [LocalConversation] = []
    @Published var activeID: UUID?
    @Published var busy = false
    @Published var error: String?
    @Published var metrics = ""
    @Published var status = ""
    @Published var storageError: String?
    private var unreadable = false
    private let engine = LocalEngine()
    private var task: Task<Void, Never>?
    private let file = URL.documentsDirectory.appending(path: "offline-chats.json")
    var current: LocalConversation? { conversations.first { $0.id == activeID } }
    var messages: [LocalMessage] { current?.messages ?? [] }
    init() {
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                conversations = try JSONDecoder().decode(
                    [LocalConversation].self, from: Data(contentsOf: file))
            }
        } catch {
            unreadable = true
            storageError = "历史文件读取失败，已保留原文件。"
        }
        activeID = conversations.first?.id
        if activeID == nil { newChat() }
    }
    func newChat() {
        guard !busy else { return }
        let chat = LocalConversation()
        conversations.insert(chat, at: 0)
        activeID = chat.id
        error = nil
        metrics = ""
        save()
    }
    func select(_ id: UUID) {
        guard !busy else { return }
        activeID = id
        error = nil
        metrics = ""
    }
    func delete(_ id: UUID) {
        guard !busy else { return }
        conversations.removeAll { $0.id == id }
        if activeID == id {
            activeID = conversations.first?.id
            if activeID == nil { newChat() }
        }
        save()
    }
    @discardableResult
    func clearHistory() -> Bool {
        guard !busy else { return false }
        let fresh = LocalConversation()
        do {
            // 先写入磁盘，保存失败时不显示清空成功。
            try JSONEncoder().encode([fresh]).write(to: file, options: [.atomic, .completeFileProtection])
            var localFile = file
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try localFile.setResourceValues(values)
            conversations = [fresh]
            activeID = fresh.id
            unreadable = false
            error = nil
            storageError = nil
            metrics = ""
            status = ""
            return true
        } catch {
            storageError = "清空失败，请稍后重试。"
            return false
        }
    }
    private func save() {
        guard !unreadable else { return }
        do {
            try JSONEncoder().encode(conversations).write(
                to: file, options: [.atomic, .completeFileProtection])
            var localFile = file
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try localFile.setResourceValues(values)
            storageError = nil
        } catch { storageError = "无法保存聊天，请检查剩余空间。" }
    }
    func cancel() {
        wa_cancel()
        status = "正在停止…"
    }
    func send(_ raw: String, retry: Bool = false) {
        guard !busy, !unreadable, let id = activeID,
            let index = conversations.firstIndex(where: { $0.id == id })
        else { return }
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard retry ? messages.last?.role == "user" : (!input.isEmpty && messages.last?.role != "user") else {
            return
        }
        guard retry || input.utf8.count <= 256 else {
            error = "实验版请使用短问题（最多256字节）。"
            return
        }
        guard let path = Bundle.main.path(forResource: "qwen2.5-0.5b-instruct-q4_k_m", ofType: "gguf") else {
            error = "找不到随 App 安装的本地模型。"
            return
        }
        if !retry { conversations[index].messages.append(LocalMessage(role: "user", content: input)) }
        conversations[index].updated = Date()
        save()
        let snapshot = conversations[index].messages
        error = nil
        metrics = ""
        status = "本地计算中..."
        busy = true
        wa_prepare()
        task = Task {
            var result = await engine.generate(path: path, prompt: LocalPrompt.make(snapshot))
            if result.status == 3 && snapshot.count > 1 {
                // 超出上下文预算时，仅保留当前问题重试一次，不截断当前问题。
                result = await engine.generate(
                    path: path, prompt: LocalPrompt.make(snapshot, includeHistory: false))
            }
            if result.status == 0, !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                let i = conversations.firstIndex(where: { $0.id == id })
            {
                conversations[i].messages.append(LocalMessage(role: "assistant", content: result.text))
                conversations[i].updated = Date()
                save()
                metrics = String(format: "%d tokens · %.1f 秒", result.tokens, result.seconds)
            } else {
                switch result.status {
                case 1: error = "已停止，可以重试。"
                case 2: error = "模型加载失败，可能是可用内存不足。"
                case 3: error = "上下文或内存不足，请开新对话并缩短问题。"
                default: error = "本地推理未完成，请重试。"
                }
            }
            #if DEBUG
                if ProcessInfo.processInfo.environment["OFFLINE_SELF_TEST"] == "1" {
                    print(
                        "OFFLINE_RESULT status=\(result.status) tokens=\(result.tokens) seconds=\(result.seconds) text=\(result.text)"
                    )
                }
            #endif
            busy = false
            status = ""
            task = nil
        }
    }
}
