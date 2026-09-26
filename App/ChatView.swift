import SwiftUI

struct OfflineChatView: View {
    @EnvironmentObject private var store: OfflineStore
    @State private var more = false
    @State private var draft = ""
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                GeometryReader { viewport in
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                if store.messages.isEmpty {
                                    Text("离线小模型实验版").foregroundStyle(.secondary)
                                    Text("想聊点什么？").font(.caption)
                                }
                                ForEach(store.messages) { message in
                                    HStack {
                                        if message.role == "user" { Spacer(minLength: 12) }
                                        Text(message.content)
                                            .padding(10)
                                            .foregroundStyle(
                                                message.role == "user" ? Color.black : Color.white
                                            )
                                            .background(
                                                message.role == "user" ? Color.white : Color(white: 0.14),
                                                in: RoundedRectangle(cornerRadius: 14))
                                        if message.role != "user" { Spacer(minLength: 8) }
                                    }.id(message.id)
                                }
                                if store.busy {
                                    HStack {
                                        ProgressView()
                                        Text(store.status).font(.caption2)
                                    }
                                    Button("停止") { store.cancel() }
                                }
                                if let error = store.error { Text(error).font(.footnote) }
                                if let error = store.storageError { Text(error).font(.footnote) }
                                if store.messages.last?.role == "user" && !store.busy {
                                    Button("重试") { store.send("", retry: true) }
                                }
                                if !store.metrics.isEmpty {
                                    Text(store.metrics).font(.caption2).foregroundStyle(.secondary)
                                }
                            }.padding(.horizontal, 6)
                            Spacer(minLength: 8)
                            TextField("输入消息…", text: $draft)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.85))
                                .accessibilityLabel("输入消息")
                                .onSubmit {
                                    guard !store.busy,
                                        store.messages.last?.role != "user",
                                        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    else { return }
                                    store.send(draft)
                                    if store.busy { draft = "" }
                                }
                                .disabled(store.busy || store.messages.last?.role == "user")
                                .frame(minHeight: 38)
                                .padding(.horizontal, 14)
                                .padding(.top, 5)
                                .padding(.bottom, 12)
                                .background(.black)
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .frame(minHeight: viewport.size.height, alignment: .top)
                    }
                    .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
                    .onChange(of: store.messages.count) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                    .onChange(of: store.activeID) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                    .navigationTitle("Qwen")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                more = true
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 38, height: 38)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .tint(.clear)
                            .accessibilityLabel("更多")
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .navigationDestination(isPresented: $more) {
                List {
                    Button("新对话") {
                        store.newChat()
                        more = false
                    }.disabled(store.busy)
                    NavigationLink("历史") {
                        List {
                            ForEach(store.conversations.filter { !$0.messages.isEmpty }) { chat in
                                Button(chat.title) {
                                    store.select(chat.id)
                                    more = false
                                }.disabled(store.busy)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            store.delete(chat.id)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                                .labelStyle(.iconOnly)
                                                .foregroundStyle(.white)
                                        }
                                        .tint(.red)
                                        .accessibilityLabel("删除对话")
                                        .disabled(store.busy)
                                    }
                            }
                        }.navigationTitle("历史")
                    }
                    Button(role: .destructive) {
                        if store.clearHistory() {
                            draft = ""
                            more = false
                        }
                    } label: {
                        Label("清空全部历史", systemImage: "trash")
                    }
                    .disabled(store.busy)
                    if let error = store.storageError { Text(error).font(.footnote) }
                    NavigationLink("关于 Qwen") {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("关于 Qwen")
                                    .font(.headline)
                                    .accessibilityAddTraits(.isHeader)
                                Text("Qwen 是运行在 Apple Watch 上的离线 AI 助手，无需联网即可用中文聊天。对话仅保存在手表上，可随时清空。")
                                Text("采用 Qwen2.5-0.5B 开源模型，适合简短问答。回答可能有误，请核实重要信息。此应用为独立开发，非 Qwen 官方产品。")
                                Text("由鲸鱼🐳开发。")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.body)
                            .lineSpacing(3)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        }
                        .background(.black)
                        .navigationTitle("")
                    }
                }.navigationTitle("更多")
            }
        }
    }
}
