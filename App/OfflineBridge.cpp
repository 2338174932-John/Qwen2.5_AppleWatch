#include "OfflineBridge.h"
#include "llama.h"
#include <atomic>
#include <chrono>
#include <cstring>
#include <cstdlib>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

static std::atomic<bool> cancelled(false);
static std::once_flag initialized;
static bool should_abort(void *) { return cancelled.load(); }
static bool load_progress(float, void *) { return !cancelled.load(); }
extern "C" void wa_prepare(void) { cancelled.store(false); }
extern "C" void wa_cancel(void) { cancelled.store(true); }
extern "C" void wa_free_string(char *value) { free(value); }
extern "C" int wa_generate(const char *path, const char *prompt, int max_tokens,
                            char **output, int *generated, double *elapsed) {
    *output = nullptr; *generated = 0; *elapsed = 0;
    const auto started = std::chrono::steady_clock::now();
    std::call_once(initialized, [] { llama_backend_init(); });
    if (cancelled.load()) return 1;
    auto mp = llama_model_default_params();
    mp.n_gpu_layers = 0;
    mp.load_mode = LLAMA_LOAD_MODE_MMAP;
    mp.use_extra_bufts = false;
    mp.progress_callback = load_progress;
    std::unique_ptr<llama_model, decltype(&llama_model_free)> model(
        llama_model_load_from_file(path, mp), llama_model_free);
    if (!model) return cancelled.load() ? 1 : 2;
    auto cp = llama_context_default_params();
    cp.n_ctx = 512;
    cp.n_batch = 32;
    cp.n_ubatch = 32;
    cp.n_threads = 2;
    cp.n_threads_batch = 2;
    cp.offload_kqv = false;
    cp.op_offload = false;
    cp.abort_callback = should_abort;
    std::unique_ptr<llama_context, decltype(&llama_free)> ctx(
        llama_init_from_model(model.get(), cp), llama_free);
    if (!ctx) return cancelled.load() ? 1 : 3;
    const auto *vocab = llama_model_get_vocab(model.get());
    std::vector<llama_token> tokens(512);
    int n = llama_tokenize(vocab, prompt, (int)strlen(prompt), tokens.data(), (int)tokens.size(), true, true);
    if (n <= 0 || n > 384) return 3; // 保留当前问题，超限时返回错误，不悄悄截断。
    tokens.resize(n);
    for (int offset = 0; offset < n; offset += 32) {
        if (cancelled.load()) return 1;
        int count = std::min(32, n - offset);
        if (llama_decode(ctx.get(), llama_batch_get_one(tokens.data() + offset, count)) != 0)
            return cancelled.load() ? 1 : 4;
    }
    std::unique_ptr<llama_sampler, decltype(&llama_sampler_free)> sampler(
        llama_sampler_init_greedy(), llama_sampler_free);
    std::string answer;
    int status = 0;
    for (int i = 0; i < std::min(max_tokens, 96); ++i) {
        if (cancelled.load()) { status = 1; break; }
        auto token = llama_sampler_sample(sampler.get(), ctx.get(), -1);
        if (llama_vocab_is_eog(vocab, token)) break;
        std::vector<char> piece(256);
        int length = llama_token_to_piece(vocab, token, piece.data(), (int)piece.size(), 0, false);
        if (length < 0) {
            piece.resize(-length);
            length = llama_token_to_piece(vocab, token, piece.data(), (int)piece.size(), 0, false);
        }
        if (length > 0) answer.append(piece.data(), length);
        *generated += 1;
        if (llama_decode(ctx.get(), llama_batch_get_one(&token, 1)) != 0) {
            status = cancelled.load() ? 1 : 4; break;
        }
    }
    *output = strdup(answer.c_str());
    *elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - started).count();
    // 请求结束后释放上下文与模型，降低空闲时的内存占用。
    return status;
}
