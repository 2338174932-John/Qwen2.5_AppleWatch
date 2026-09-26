import Foundation

struct LocalResult: Sendable {
    let status: Int32
    let text: String
    let tokens: Int32
    let seconds: Double
}
final class LocalEngine: @unchecked Sendable {
    private let queue = DispatchQueue(label: "watch.offline.inference", qos: .userInitiated)
    func generate(path: String, prompt: String) async -> LocalResult {
        await withCheckedContinuation { continuation in
            queue.async {
                var output: UnsafeMutablePointer<CChar>?
                var count: Int32 = 0
                var seconds = 0.0
                let status = wa_generate(path, prompt, 64, &output, &count, &seconds)
                let text = output.map { String(cString: $0) } ?? ""
                if let output { wa_free_string(output) }
                continuation.resume(
                    returning: LocalResult(status: status, text: text, tokens: count, seconds: seconds))
            }
        }
    }
}
