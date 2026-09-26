# Qwen2.5 Apple Watch

**在 Apple Watch 上独立运行的中文离线问答应用。由鲸鱼🐳开发。**

只使用 **Qwen2.5-0.5B-Instruct · Q4_K_M** 这一款模型，没有模型选择、API 密钥、账号登录或服务器。安装完成后，回答直接在手表上生成。

> 本项目为个人开源实验，非 Qwen／阿里巴巴官方应用。模型体积小、能力有限，可能答错、重复或截断回答，不应作为医疗等重要决策依据。

## 给朋友：下载完整包即可开始安装

到 [Releases 下载页面](https://github.com/2338174932-John/Qwen2.5_AppleWatch/releases/latest)，下载 **Qwen_AppleWatch_完整工程.zip**。

完整包已包含固定模型（约 491 MB）、手表推理静态库、源码和 Xcode 工程，**不需要另选模型，也不需要自己下载模型或编译推理引擎**。

**注意：这不是可直接在手表打开的安装包。** Apple Watch 不支持从 GitHub 下载 ZIP 后直接安装。你需要 Mac、Xcode、自己的 Apple 账号，以及配对并连接的手表。普通 Apple 账号的个人签名存在有效期及平台限制，到期可能需要重新安装；本项目未上架 App Store。

1. 解压完整包，打开 `QwenWatch.xcodeproj`。
2. 在 Xcode 的 **Settings → Accounts** 登录自己的 Apple 账号。
3. 在工程的 **Qwen → Signing & Capabilities** 选择自己的 Team，保持自动签名开启；将 Bundle Identifier 改为自己的唯一标识，例如 `com.yourname.qwenwatch`。也可编辑 `Config/Local.xcconfig` 中的两个配置。
4. 连接配对的 iPhone 和 Apple Watch，按 Xcode 提示完成信任、配对和开发者模式设置。
5. 选择 `Qwen` scheme 和真实 Apple Watch，点击运行。首次传输模型需要几分钟。
6. 安装后从手表应用列表打开 **Qwen**。

当前附带的推理库仅支持 **arm64 真机**，不支持模拟器及 arm64_32。已在 **Apple Watch Series 10** 测试，其他型号尚未验证；工程最低系统设置为 watchOS 10，不代表所有该版本设备都兼容。验证环境为 Xcode 27 / watchOS 27 SDK。

## 怎么用

- 点击底部“输入消息…”，在系统编辑页输入中文，点击“完成”提交。
- 等待“本地计算中...”；需要时点击“停止”。
- 向上查看聊天时输入栏随内容移出画面，回到底部可继续输入。
- 点击三个点，可新建对话、查看历史、清空全部历史或查看关于。
- 历史列表侧滑显示红色垃圾桶，可删除单个会话。**删除和清空不可撤销。**

键盘、手写、听写及 iPhone 辅助输入由 watchOS 提供。模型推理不需要网络，但系统听写不保证完全离线。

## 当前限制

- 每次问题最多 256 个 UTF-8 字节（中文通常每字占 3 字节）。
- 上下文最多 512 tokens，每次最多生成 64 tokens；输出可能在句中截断。
- 携带最近 3 条消息，较旧消息最多 100 字符；输入超出分词预算时仅保留当前问题重试一次。
- 不支持联网搜索、长期记忆、自动摘要或后台持续生成；进入后台会取消计算。
- 历史存储在本机，不含云同步；应用把记录文件标记为排除备份。卸载或抹掉设备可能丢失记录。
- 尚未完成全型号、长期稳定性、峰值内存、耗电和温升测试。

Series 10 开发版两次测试：中文“法国的首都”约 3.9 秒，中文“两条节水建议”约 5.3 秒，均包含模型加载。单题测试不代表所有问题的速度与质量。

## 给开发者：从源码构建

仓库本身不提交大型模型、静态库、个人签名及构建缓存。GitHub 的 **Code → Download ZIP** 只有源码；想省去依赖准备，请下载上面的完整 Release 包。

安装 Xcode 并完成首次启动，再安装 Python 3、CMake、XcodeGen、Git。如果使用 Homebrew：

```bash
brew install python cmake xcodegen
git clone https://github.com/2338174932-John/Qwen2.5_AppleWatch.git
cd Qwen2.5_AppleWatch
bash Scripts/setup.sh
open QwenWatch.xcodeproj
```

`setup.sh` 仅下载项目固定的 Qwen2.5-0.5B 权重，校验 SHA-256，获取固定提交的 llama.cpp，构建 CPU 静态库并生成 Xcode 工程。需要访问 GitHub 和 Hugging Face；下载失败不会用其他模型替代。

签名配置位于 `Config/Local.xcconfig`，由示例自动复制，已被 Git 忽略。请勿提交自己的 Team、证书、密钥或聊天文件。修改 `project.yml` 后运行 `xcodegen generate`。

```bash
# 格式、上下文行为和模型完整性检查（需先完成依赖准备）
bash Scripts/check.sh

# 不签名构建，检查 Swift / C++ 与 watchOS 的兼容性
xcodebuild -project QwenWatch.xcodeproj -scheme Qwen \
  -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

## 目录

| 路径 | 内容 |
| --- | --- |
| `App/ChatView.swift` | 聊天、历史、关于及输入界面 |
| `App/OfflineStore.swift` | 会话状态、持久化、取消和重试 |
| `App/ChatModels.swift` | 本地消息与会话结构 |
| `App/ChatPrompt.swift` | 中文提示词、上下文裁剪与分隔符转义 |
| `App/LocalEngine.swift` | 串行异步推理接口 |
| `App/OfflineBridge.cpp` | llama.cpp CPU 推理和资源释放 |
| `Models/model-manifest.json` | 固定权重版本、大小与哈希 |
| `Scripts/` | 下载、构建和检查脚本 |
| `Tests/` | 上下文行为与工程检查 |
| `Licenses/`、`THIRD_PARTY.md` | 第三方许可与来源 |

## 开源与贡献

本项目原创应用代码采用 [MIT 许可证](LICENSE)。模型、推理引擎及图标的权利范围见 [第三方说明](THIRD_PARTY.md)。MIT 许可不授予 Qwen 名称或图标的商标权，也不代表官方认可。

欢迎用中文提交 Issue / Pull Request。请附手表型号、系统版本和复现步骤；不要提交 API 密钥、完整个人聊天或开发者证书。贡献说明见 [CONTRIBUTING.md](CONTRIBUTING.md)。
