import SwiftUI

@main struct OfflineWatchApp: App {
    @StateObject private var store = OfflineStore()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            OfflineChatView().environmentObject(store).tint(.white).preferredColorScheme(.dark)
                .onChange(of: phase) { _, value in
                    if value == .background && store.busy { store.cancel() }
                }
                .task {
                    #if DEBUG
                        if ProcessInfo.processInfo.environment["OFFLINE_SELF_TEST"] == "1" {
                            store.newChat()
                            print("OFFLINE_TEST bundled model, CPU only, no network transport")
                            store.send(
                                ProcessInfo.processInfo.environment["OFFLINE_TEST_PROMPT"]
                                    ?? "请用中文回答：法国的首都是哪里？")
                        }
                    #endif
                }
        }
    }
}
