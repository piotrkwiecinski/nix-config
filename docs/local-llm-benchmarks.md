# Local LLM Tool-Calling Benchmarks

**Date:** 2026-04-03
**Hardware:** ThinkPad X1 Extreme Gen3 (i9-10885H, 30GB RAM, NVIDIA 4GB VRAM)
**Ollama:** 0.20.0 (CUDA)
**Test:** Tool calling via Ollama Chat API with 4 pantry MCP tools (query_stock, query_expiring, list_catalog, record_event)
**Context:** 4096 tokens, `think: false`, sequential runs, model warm in VRAM

## Results: Models That Fit in VRAM (under 3GB)

| Model | Size | VRAM | Test | Time | Correct? | Tokens |
|-------|------|------|------|------|----------|--------|
| **qwen2.5:3b** | 2.3GB | 100% | query_stock | **2.4s** | Yes - perfect args | 16 |
| **qwen2.5:3b** | 2.3GB | 100% | query_expiring(7) | **1.2s** | Yes - perfect args | 22 |
| **qwen2.5:3b** | 2.3GB | 100% | add butter (mutation) | **2.7s** | Partial - wrong event_type, guessed IDs | 72 |
| **llama3.2:3b** | 2.6GB | 100% | query_stock | **2.5s** | Yes - messy arg format | 16 |
| **llama3.2:3b** | 2.6GB | 100% | query_expiring(7) | **1.8s** | Yes - messy arg format | 38 |
| **llama3.2:3b** | 2.6GB | 100% | add butter (mutation) | **2.3s** | Partial - string IDs instead of ints | 60 |
| **granite3.1-dense:2b** | 2.0GB | 100% | query_stock | **3.0s** | No - talked about tools, didn't call them | 110 |
| **granite3.1-dense:2b** | 2.0GB | 100% | query_expiring(7) | **4.5s** | No - talked about tools, didn't call them | 243 |
| **granite3.1-dense:2b** | 2.0GB | 100% | add butter (mutation) | **2.7s** | No - output raw JSON text, no tool call | 142 |

## Results: Models That Don't Fit in VRAM (over 4GB)

| Model | Size | VRAM | Test | Time | Correct? | Tokens |
|-------|------|------|------|------|----------|--------|
| **gemma4:e2b** (Q4_K_M) | 7.6GB | 27% | query_stock | **35s** (warm) | Yes | 158 |
| **gemma4:e2b** (Q4_K_M) | 7.6GB | 27% | query_expiring(7) | **35s** (warm) | Yes | - |
| **gemma4:e2b** (Q4_K_M) | 7.6GB | 27% | add butter (mutation) | **42min** | No - asked for IDs instead of calling tool | - |
| **gemma4:e2b** (no think) | 7.6GB | 27% | query_stock | **3m 17s** | Yes | 9 |
| **gemma4:e2b** (no think) | 7.6GB | 27% | query_expiring(7) | **2m 49s** | Yes | 16 |
| **gemma4:e4b** (Q4_K_M) | 12GB | 26% | query_stock | **3m 19s** | Yes | - |
| **gemma4:e4b** (Q4_K_M) | 12GB | 26% | query_expiring(7) | **3m 22s** | Yes | - |
| **qwen3:4b-32k** (Q4_K_M) | 8.0GB | 41% | query_stock | **9m 15s** | Yes | 359 |

## Conclusions

1. **qwen2.5:3b is the clear winner** for tool calling on 4GB VRAM hardware. 1-3 second responses, correct tool selection, clean argument formatting.
2. **Model must fit 100% in VRAM** to be usable. Any CPU/RAM spillover results in minutes-long responses regardless of token count.
3. **Thinking/reasoning mode is a trap** for small models doing tool calls. It generates hundreds of tokens before the actual tool call, wasting time (qwen3:4b generated 359 tokens for a simple query_stock).
4. **Gemma 4 E2B/E4B are too large** (7.6GB/12GB) for 4GB VRAM despite having "effective" parameter counts of 2.3B/4.5B - the full model still needs to be loaded.
5. **Granite 3.1 2B** understands tools conceptually but fails to make actual tool calls via the Ollama API.
6. **None approach cloud API speed** (Claude Code: 2-5s with full multi-step tool chains). Local models match on simple single-tool queries but struggle with mutations requiring catalog lookups.

## Pi Coding Agent Benchmarks

**Date:** 2026-04-10
**Pi version:** 0.66.1 (`@mariozechner/pi-coding-agent`)
**Test:** Tool calling via pi print mode (`pi --provider ollama --model <model> --no-session -p "Run ls..."`)
**Context:** 32768 tokens (pi default), model warm in VRAM, sequential runs (no parallel — VRAM contention invalidates results)
**Note:** Pi injects a system prompt with tool definitions (read, bash, edit, write), adding overhead vs raw Ollama API calls

### Results: Models That Fit in VRAM (under 3GB)

| Model | Size | Time | Tool call | Notes |
|-------|------|------|-----------|-------|
| **qwen2.5:3b** | 1.9GB | **20.3s** | Yes | Fastest, correct output |
| granite3.1-dense:2b | 1.6GB | 23.4s | **No** | Described tool instead of calling it — same failure as MCP benchmarks |
| llama3.2:3b | 2.0GB | 24.6s | Yes | Correct but ~4s slower than qwen2.5 |

### Results: Models That Don't Fit in VRAM

| Model | Size | Thinking | Time | Tool call | Notes |
|-------|------|----------|------|-----------|-------|
| qwen3:4b-32k | 2.5GB | on | 1m50s | Yes | ~41% VRAM, rest spills to CPU |
| qwen3:4b-32k | 2.5GB | off | 2m35s | Yes | Thinking OFF slower — more output tokens before tool call |

### Pi-Specific Conclusions

1. **qwen2.5:3b is the best model for pi on 4GB VRAM** — 20s for a tool call, fits entirely in GPU, reliable tool selection.
2. **Pi's system prompt adds significant overhead** vs raw Ollama API (20s vs 1-3s for qwen2.5:3b). The tool definitions and instructions consume context and generation time.
3. **VRAM contention is catastrophic** — running two pi instances simultaneously caused 3-8x slowdowns. Always benchmark sequentially.
4. **qwen3:4b-32k is unusable for interactive pi work** — 2-3 minutes per tool call due to CPU spill, regardless of thinking mode.
5. **granite3.1-dense:2b fails identically** in pi and raw Ollama — it understands tools conceptually but never makes actual tool calls.

## Opencode Integration Notes

- opencode injects ~11K tokens of system prompt + built-in tools, which can overwhelm small models at 4096 context
- Pantry MCP tools may not surface properly alongside opencode's built-in tools for 3B models
- Consider increasing context to 8192 or reducing opencode's built-in tool set when using small models
