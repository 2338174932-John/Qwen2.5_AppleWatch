import Foundation

enum LocalPrompt {
    static func make(_ messages: [LocalMessage], includeHistory: Bool = true) -> String {
        func clean(_ value: String) -> String {
            value.replacingOccurrences(of: "<|", with: "< |")
        }
        var text = "<|im_start|>system\n你是通义千问，一个有帮助的助手。默认使用简体中文，简短、直接地回答。不确定时请明确说明。<|im_end|>\n"
        let selected = includeHistory ? Array(messages.suffix(3)) : Array(messages.suffix(1))
        for message in selected {
            let content =
                message.id == messages.last?.id ? message.content : String(message.content.prefix(100))
            text += "<|im_start|>\(message.role)\n\(clean(content))<|im_end|>\n"
        }
        return text + "<|im_start|>assistant\n"
    }
}
