# 贡献说明

请使用中文描述问题和改动。代码标识符保持 Swift / C++ 常见英文命名，注释优先中文。许可证原文保持完整，不随意翻译替换。

1. 先按 README 准备固定模型与引擎，不引入模型选择或远程 API。
2. Swift 使用仓库 `.swift-format` 配置：`xcrun swift-format format --in-place App/*.swift`。
3. 运行 `bash Scripts/check.sh`，再进行 watchOS 真机构建。
4. UI 改动说明实际验证的设备和步骤，未验证内容如实注明。
5. 请勿提交模型权重、静态库、缓存、个人签名、证书、令牌或真实聊天记录。

提交 PR 时说明改动目的、用户可见行为和验证结果。保持变更范围集中。
