#pragma once
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
// 推理调用必须串行执行；取消标志可跨线程设置。
void wa_prepare(void);
void wa_cancel(void);
// 返回码：0 成功、1 已取消、2 模型加载失败、3 上下文失败、4 解码失败。
int wa_generate(const char *model_path, const char *prompt, int max_tokens,
                char **output, int *generated_tokens, double *elapsed_seconds);
void wa_free_string(char *value);
#ifdef __cplusplus
}
#endif
