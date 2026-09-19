# Local LLM Tool-Calling Benchmarks

**Date:** 2026-04-03
**Hardware:** ThinkPad X1 Extreme Gen3 (i9-10885H, 30GB RAM, NVIDIA 4GB VRAM)
**Ollama:** 0.20.0 (CUDA)
**Test:** Tool calling via Ollama Chat API with 4 pantry MCP tools (query_stock, query_expiring, list_catalog, record_event)
**Context:** 4096 tokens, `think: false`, sequential runs, model warm in VRAM

## Results: Models That Fit in VRAM (under 3GB)

| Model                   | Size  | VRAM | Test                  | Time     | Correct?                                  | Tokens |
|-------------------------|-------|------|-----------------------|----------|-------------------------------------------|--------|
| **qwen2.5:3b**          | 2.3GB | 100% | query_stock           | **2.4s** | Yes - perfect args                        | 16     |
| **qwen2.5:3b**          | 2.3GB | 100% | query_expiring(7)     | **1.2s** | Yes - perfect args                        | 22     |
| **qwen2.5:3b**          | 2.3GB | 100% | add butter (mutation) | **2.7s** | Partial - wrong event_type, guessed IDs   | 72     |
| **llama3.2:3b**         | 2.6GB | 100% | query_stock           | **2.5s** | Yes - messy arg format                    | 16     |
| **llama3.2:3b**         | 2.6GB | 100% | query_expiring(7)     | **1.8s** | Yes - messy arg format                    | 38     |
| **llama3.2:3b**         | 2.6GB | 100% | add butter (mutation) | **2.3s** | Partial - string IDs instead of ints      | 60     |
| **granite3.1-dense:2b** | 2.0GB | 100% | query_stock           | **3.0s** | No - talked about tools, didn't call them | 110    |
| **granite3.1-dense:2b** | 2.0GB | 100% | query_expiring(7)     | **4.5s** | No - talked about tools, didn't call them | 243    |
| **granite3.1-dense:2b** | 2.0GB | 100% | add butter (mutation) | **2.7s** | No - output raw JSON text, no tool call   | 142    |

## Results: Models That Don't Fit in VRAM (over 4GB)

| Model                     | Size  | VRAM | Test                  | Time           | Correct?                                   | Tokens |
|---------------------------|-------|------|-----------------------|----------------|--------------------------------------------|--------|
| **gemma4:e2b** (Q4_K_M)   | 7.6GB | 27%  | query_stock           | **35s** (warm) | Yes                                        | 158    |
| **gemma4:e2b** (Q4_K_M)   | 7.6GB | 27%  | query_expiring(7)     | **35s** (warm) | Yes                                        | -      |
| **gemma4:e2b** (Q4_K_M)   | 7.6GB | 27%  | add butter (mutation) | **42min**      | No - asked for IDs instead of calling tool | -      |
| **gemma4:e2b** (no think) | 7.6GB | 27%  | query_stock           | **3m 17s**     | Yes                                        | 9      |
| **gemma4:e2b** (no think) | 7.6GB | 27%  | query_expiring(7)     | **2m 49s**     | Yes                                        | 16     |
| **gemma4:e4b** (Q4_K_M)   | 12GB  | 26%  | query_stock           | **3m 19s**     | Yes                                        | -      |
| **gemma4:e4b** (Q4_K_M)   | 12GB  | 26%  | query_expiring(7)     | **3m 22s**     | Yes                                        | -      |
| **qwen3:4b-32k** (Q4_K_M) | 8.0GB | 41%  | query_stock           | **9m 15s**     | Yes                                        | 359    |

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

| Model               | Size  | Time      | Tool call | Notes                                                                 |
|---------------------|-------|-----------|-----------|-----------------------------------------------------------------------|
| **qwen2.5:3b**      | 1.9GB | **20.3s** | Yes       | Fastest, correct output                                               |
| granite3.1-dense:2b | 1.6GB | 23.4s     | **No**    | Described tool instead of calling it — same failure as MCP benchmarks |
| llama3.2:3b         | 2.0GB | 24.6s     | Yes       | Correct but ~4s slower than qwen2.5                                   |

### Results: Models That Don't Fit in VRAM

| Model        | Size  | Thinking | Time  | Tool call | Notes                                                     |
|--------------|-------|----------|-------|-----------|-----------------------------------------------------------|
| qwen3:4b-32k | 2.5GB | on       | 1m50s | Yes       | ~41% VRAM, rest spills to CPU                             |
| qwen3:4b-32k | 2.5GB | off      | 2m35s | Yes       | Thinking OFF slower — more output tokens before tool call |

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

---

# Model Landscape Research — September 2026

**Date:** 2026-09-11
**Method:** web research (Ollama registry API, Hugging Face model cards, IBM/Qwen primary sources)
**Not yet benchmarked** — this is a candidate shortlist, not measured results.

## Hardware re-check

|                    |                                                        |
|--------------------|--------------------------------------------------------|
| GPU                | GTX 1650 Ti Max-Q, **4096 MiB VRAM**, driver 595.71.05 |
| Free VRAM (idle)   | **3681 MiB** (display runs on iGPU, only 36 MiB used)  |
| Usable for weights | **~3.3 GB** after CUDA context (~300 MiB) + KV cache   |
| CPU                | i9-10885H, 8C/16T, **AVX2 only — no AVX-512, no AMX**  |
| RAM                | 30 GB DDR4 dual-channel (~30 GB/s real bandwidth)      |
| Ollama             | 0.32.13 (CUDA)                                         |

The AVX2-only CPU is the underrated constraint: it caps *prefill* throughput, which is what
agentic coding hammers (opencode injects ~11K tokens of system prompt per the notes above).

## Tier 1 — candidates for 4 GB VRAM

> **Superseded in part** — see MEASURED RESULTS below. Of these only `granite4.2:3b` actually
> held 100% GPU; both Qwen3.5 tags spilled. The Qwen3.5-4B recommendation did not hold up.

Sizes below are exact layer bytes from `registry.ollama.ai/v2/library/<m>/manifests/<tag>`.

| Model                               | Weights      | Released   | Arch                               | Context     | Notes                                                                                                      |
|-------------------------------------|--------------|------------|------------------------------------|-------------|------------------------------------------------------------------------------------------------------------|
| **granite4.2:3b**                   | **2140 MiB** | 2026-08-25 | dense, GQA 40h/8kv                 | 128K        | Newest small model. Apache 2.0. BFCL v4 **52.41**, LiveCodeBench v6 **69.71**, IFBench 74.33, AIME25 78.33 |
| **Qwen3.5-4B** (unsloth UD-Q4_K_XL) | **2.91 GB**  | 2026-03-02 | hybrid Gated DeltaNet + sparse MoE | 256K native | Tool calling + Qwen Code tuned. LiveCodeBench v6 55.8, IFEval 89.8, MMLU-Pro 79.1                          |
| **qwen3.5:2b**                      | **2614 MiB** | 2026-03-02 | same hybrid                        | 256K        | Safe fallback; direct successor to the qwen2.5:3b that won the April benchmarks                            |

### Key caveats

1. **`granite4.2:3b` is NOT agentic-RL trained.** IBM states the agentic-RL block is trained
   only for the 8B and 30B; the 3B has no SWE-Bench Pro / Terminal-Bench 2.1 numbers at all.
   Expect strong single-shot code generation and weak multi-turn tool loops.
   It is *not* the same architecture as the `granite3.1-dense:2b` that failed tool calling
   above (Granite 4.2 dropped 4.0's Mamba-2 MoE for dense GQA and has native tool calling),
   so the old failure does not carry over — but it needs re-testing.
2. **Skip Ollama's own `qwen3.5:4b`** — 3232 MiB leaves only ~150 MiB for KV cache and will
   spill. Ollama publishes no sub-Q4 quants for qwen3.5, so pull from Unsloth instead:
   `ollama pull hf.co/unsloth/Qwen3.5-4B-GGUF:UD-Q4_K_XL` (2.91 GB) or `:Q4_K_M` (2.74 GB).
3. **The Gated DeltaNet hybrid is the real win at 4 GB.** Most layers are linear-attention with
   constant-size state, so only a few full-attention layers carry a KV cache. 32K+ usable
   context in 4 GB becomes plausible, where a dense 4B never was.
4. **Thinking mode is on by default** for both Qwen3.5 and Granite 4.2. Conclusion #3 from the
   April benchmarks still applies — disable it (`enable_thinking: false` / `think: false`) for
   tool calling.

### Not viable at this tier

- `qwen3.8` / `qwen3.6` — 27B minimum (18 GB), no sub-5B general models shipped. Qwen's newest
  small general models are still the March 2026 Qwen3.5 2B/4B.
- `gemma4:e2b` / `e4b` — still 7.2/9.6 GB locally. Raschka scored E2B 0/5 on reasoning with
  unreliable tool use; "unsuitable for coding agents beyond very narrow tasks."
- `granite4.2:8b` (5100 MiB) — the agentic-RL-trained one, but 1.4 GB over budget.

## Tier 2 — 30B-A3B MoE with CPU expert offload

This is where the 30 GB of RAM matters more than the 4 GB of VRAM. `llama.cpp --n-cpu-moe N`
keeps attention, KV cache, router, shared experts and norms on the GPU and pushes routed expert
FFNs to system RAM. With only 3B active parameters per token, decode is RAM-bandwidth-bound
rather than VRAM-bound.

| Model                            | Total/active                     | Best-fit quant                                                       | Released   | Notes                                                                                                |
|----------------------------------|----------------------------------|----------------------------------------------------------------------|------------|------------------------------------------------------------------------------------------------------|
| **North Mini Code 1.0** (Cohere) | 30B / 3B (128 experts, 8 active) | UD-IQ3_XXS **11.7 GB**, UD-Q3_K_M **14.2 GB**, UD-IQ4_XS **15.2 GB** | 2026-06    | Apache 2.0, 256K ctx, **purpose-built for agentic coding + terminal tasks**. Best fit for this box.  |
| Qwen3.6 35B-A3B                  | 35B / 3B                         | Q4 = 23 GB                                                           | 2026-05    | Raschka: ~40 tok/s on M4 Mac Mini, "very capable" — but he cites 30-40 GB RAM. Only Q3 fits here.    |
| Nemotron 3 Nano                  | 31.6B / 3.2B                     | ~18 GB                                                               | 2026-04-28 | NVIDIA states 25 GB RAM; hybrid Mamba-Transformer MoE, omni-modal. Too tight with a desktop session. |

### Honest expectations

- **Decode:** ~1.7 GB of expert weights read per token at IQ4_XS → roughly **8-15 tok/s** at
  ~30 GB/s effective bandwidth. Below the 20-30 tok/s that Raschka calls the floor for
  comfortable agent work, but fine for batch/background tasks.
- **Prefill is the actual blocker.** Expert FFNs run on the CPU during prompt processing too,
  and this CPU has AVX2 only. An 11K-token agent system prompt could take minutes before the
  first token. `--n-cpu-moe` makes an already-overcommitted model usable; it does not make it fast.
- Current RAM headroom is thin: 15 GB used / 15 GB available with 7 GB of swap already in use.
  A 14-15 GB model needs a mostly-idle session or it will thrash.

## Verdict

1. **For skills** (commit messages, classification, single-tool MCP queries, summarisation,
   embeddings/search) — Tier 1 is genuinely good now. `granite4.2:3b` and Qwen3.5-4B at
   UD-Q4_K_XL are both large jumps over `qwen2.5:3b`, and both fit with KV headroom.
2. **For agentic coding** — nothing at 2-4B will reliably drive a Claude-Code-style loop; this
   matches both the April findings and the 2026 consensus that sub-7B models emit malformed
   tool calls under agentic load. North Mini Code 1.0 at IQ3/IQ4 is the only local option on
   this machine that is actually *trained* for agentic coding, and it will be slow.
3. **The split that works**: let a Tier 1 model find the anchor (locate the file, the symbol,
   the one authoritative location) and let a cloud model do the reasoning-heavy sweep.

## MEASURED RESULTS — 2026-09-11

Supersedes the "suggested next benchmark run" section below; these are actual runs.

**Setup:** Ollama 0.32.13 CUDA, raw `/api/chat`, the 4 real pantry MCP tool schemas extracted
from `pantry-app-v2/db/crates/pantry-mcp/src/{server,lib}.rs`, `think:false`, `temperature:0`,
`num_ctx:4096`. Models run strictly sequentially, each explicitly unloaded (`keep_alive:0`)
before the next loads, so only one is ever resident.

| Model             | Resident | GPU           | query_stock                      | query_expiring(7)                                    | mutation (add butter)                                                            |
|-------------------|----------|---------------|----------------------------------|------------------------------------------------------|----------------------------------------------------------------------------------|
| **granite4.2:3b** | 2.5 GB   | **100%**      | 7.38s / 18 tok — `query_stock{}` | **1.62s** / 33 tok — `query_expiring{within_days:7}` | 4.41s / 145 tok — `list_catalog{products}`                                       |
| **qwen3.5:2b**    | 3.0 GB   | 76% / 24% CPU | 5.21s / 14 tok — `query_stock{}` | 4.44s / 28 tok — `query_expiring{within_days:7}`     | 7.24s / 81 tok — **3 parallel** `list_catalog{products}`+`{units}`+`{locations}` |

All six calls selected the right tool with well-formed arguments. No malformed JSON, no
string-vs-int confusion, no "talked about the tool instead of calling it".

### What changed vs. April

1. **The mutation test is no longer a failure case.** In April every model guessed IDs
   (`qwen2.5:3b`), passed strings instead of ints (`llama3.2:3b`), or asked the user for IDs
   (`gemma4:e2b`, 42 min). Both new models instead recognise that IDs must be *resolved first*
   and call `list_catalog`. `qwen3.5:2b` fires all three lookups in parallel — precisely the
   product_id, unit_id and location_id that `record_event(add)` requires. That is correct
   agentic sequencing, and it is new.
2. **Granite 3.1's tool-calling failure does not carry over to Granite 4.2.** The old
   `granite3.1-dense:2b` never emitted a tool call; `granite4.2:3b` emits clean native ones.
   The "not agentic-RL trained" caveat is still visible though — it resolved only *one* of the
   three needed IDs where Qwen resolved all three.
3. **Conclusion #2 above needs qualifying.** "Any CPU spill = minutes-long responses" held for
   dense models with thinking enabled. `qwen3.5:2b` spilled 24% to CPU and still answered in
   4-7s. Sparse-MoE + Gated DeltaNet degrades far more gracefully under partial spill than the
   dense models tested in April.

### Correction to the Tier 1 research above

`qwen3.5:2b` did **not** fit fully in VRAM as predicted. Ollama pulls a separate **675 MB
vision projector** (`mmproj-F16.gguf`) alongside every Qwen3.5 tag, pushing residency from
2.6 GB of weights to 3.0 GB and forcing a 24% CPU spill in 3.68 GB of free VRAM.

For coding and skills the vision tower is dead weight. Two consequences:

- `ollama pull hf.co/unsloth/Qwen3.5-4B-GGUF:...` is unreliable — the mmproj layer times out
  (`context deadline exceeded`; 5/5 attempts failed here). Download the `.gguf` directly with
  `curl -C -` and import via Modelfile to get a **text-only** model.
- Budget for Qwen3.5 under Ollama is therefore *weights + 0.675 GB*, not weights alone.

### Tool calling — all three models (4K ctx)

Re-stated with the text-only 4B added:

| Model                   | Resident | GPU      | query_stock        | query_expiring(7)  | mutation                        |
|-------------------------|----------|----------|--------------------|--------------------|---------------------------------|
| **granite4.2:3b**       | 2.5 GB   | **100%** | 7.38s / 18 tok     | **1.62s** / 33 tok | 4.41s / 145 tok — 1 of 3 IDs    |
| **qwen3.5:2b**          | 3.0 GB   | 76%      | **5.21s** / 14 tok | 4.44s / 28 tok     | **7.24s** / 81 tok — 3 parallel |
| **qwen3.5-4b-textonly** | 3.2 GB   | 80%      | 12.17s / 14 tok    | 6.40s / 28 tok     | 13.33s / 81 tok — 3 parallel    |

**The 4B is not worth it on this hardware.** It produces *byte-identical* tool calls to the 2B
(same 14/28/81 token counts, same three parallel `list_catalog` lookups) for roughly 2x the
latency, and it still spills 20% even with the vision tower stripped out. `qwen3.5:2b`
strictly dominates it here.

Ollama also refuses to use the last ~1.1 GB of the card: at 3.2 GB resident `nvidia-smi`
reported only 2600 MiB in use with 1116 MiB free. The practical ceiling for **100% GPU**
residency on this GPU is therefore ~2.5 GB resident / ~2.2 GB of weights — which among the
tested models only `granite4.2:3b` clears.

### pi agent (pi 0.84.4, `--thinking off`, pi's default 32K context)

Sandbox of 3 files. task1 = "run ls, how many files"; task2 = "read alpha.rs, what string does it print".

| Model                   | Resident @32K             | task1      | task2     | Correct  |
|-------------------------|---------------------------|------------|-----------|----------|
| **qwen3.5-2b-textonly** | **1.8 GB, 100% GPU**      | **25.03s** | **8.92s** | **both** |
| **qwen3.5-4b-textonly** | 4.3 GB, 58% GPU / 42% CPU | 69.32s     | 35.26s    | **both** |
| **qwen3.5:2b**          | 3.4 GB, 63% GPU / 37% CPU | 71.51s     | 28.05s    | **both** |
| **granite4.2:3b**       | 2.5 GB, 100% GPU          | 169.65s    | 97.48s    | **both** |

All four models answered both tasks correctly — a real change from April, where only simple
single-tool queries worked.

**Residency does not predict speed.** granite sits 100% on the GPU and is the slowest by a wide
margin; the 4B spills 42% to CPU and is still 2.4x faster than granite. This is the clearest
refutation of April's conclusion #2: VRAM residency is no longer the dominant term. What matters
is per-token compute cost — a sparse-MoE + Gated DeltaNet model beats a dense one even when
nearly half its layers are on the CPU.

Residency still matters *within* one model, though — compare the two builds of the same 2B:
1.8 GB at 100% GPU is **2.9x faster** than 3.4 GB at 63%.

**The 4B is not worth its extra 2B of parameters here.** It needs 4.3 GB at 32K — more than the
whole card — and lands between granite and the bundled 2B on speed while producing tool calls
identical to the 2B's.

Not directly comparable to the April pi numbers: pi went 0.66.1 -> 0.84.4 and its system prompt
grew, so `qwen2.5:3b`'s 20.3s from then is not a like-for-like baseline.

### VRAM vs context length

`ollama ps` reported size at each `num_ctx`, model unloaded between every measurement:

| Model                   | 4K                    | 16K             | 32K                  |
|-------------------------|-----------------------|-----------------|----------------------|
| **granite4.2:3b**       | **2.5 GB (100% GPU)** | 3.7 GB (spills) | 5.1 GB (spills hard) |
| **qwen3.5:2b**          | 3.0 GB (76% GPU)      | 3.1 GB          | 3.4 GB (63% GPU)     |
| **qwen3.5-4b-textonly** | 3.2 GB (80% GPU)      | 3.7 GB          | 4.3 GB               |

Granite's dense GQA KV cache costs roughly **90 MB per 1K tokens** — it blows past the whole
4 GB card by 32K, so granite is only viable at **<= 8K context** here. Qwen3.5's hybrid Gated
DeltaNet KV grows far more slowly (3.0 -> 3.4 GB going 4K -> 32K, ~13 MB per 1K tokens), which
confirms the architectural prediction and is why it wins every long-prompt test despite
starting from a worse residency position.

### THE WINNER: `qwen3.5-2b-textonly`

Built by stripping the vision projector — `curl` the Unsloth GGUF, one-line Modelfile,
`ollama create`. Weights 1.25 GB (vs 2.6 GB for Ollama's `qwen3.5:2b` tag with its bundled
675 MB mmproj).

|                          | resident   | GPU      | query_stock | query_expiring(7) | mutation               |
|--------------------------|------------|----------|-------------|-------------------|------------------------|
| **qwen3.5-2b-textonly**  | **1.4 GB** | **100%** | **4.57s**   | 2.11s             | **3.09s** — 3 parallel |
| qwen3.5:2b (with mmproj) | 3.0 GB     | 76%      | 5.21s       | 4.44s             | 7.24s — 3 parallel     |
| granite4.2:3b            | 2.5 GB     | 100%     | 7.38s       | **1.62s**         | 4.41s — 1 of 3 IDs     |
| qwen3.5-4b-textonly      | 3.2 GB     | 80%      | 12.17s      | 6.40s             | 13.33s — 3 parallel    |

It is **2.3x faster on the mutation** than the same model with the vision tower attached, and
**1.4x faster than granite** while resolving all three IDs instead of one. Only granite's
single-tool `query_expiring` (1.62s vs 2.11s) still edges it.

And it never spills, at any context length:

| Model                   | 4K                    | 16K                   | 32K                   |
|-------------------------|-----------------------|-----------------------|-----------------------|
| **qwen3.5-2b-textonly** | **1.4 GB (100% GPU)** | **1.7 GB (100% GPU)** | **1.8 GB (100% GPU)** |
| qwen3.5:2b              | 3.0 GB (76%)          | 3.1 GB                | 3.4 GB (63%)          |
| qwen3.5-4b-textonly     | 3.2 GB (80%)          | 3.7 GB                | 4.3 GB                |
| granite4.2:3b           | 2.5 GB (100%)         | 3.7 GB (spills)       | 5.1 GB (spills hard)  |

Under pi (32K context, `--thinking off`) the winner holds **1.8 GB / 100% GPU** and both tasks
were correct:

| Model                   | Resident @32K        | task1      | task2     |
|-------------------------|----------------------|------------|-----------|
| **qwen3.5-2b-textonly** | **1.8 GB, 100% GPU** | **25.03s** | **8.92s** |
| qwen3.5:2b (mmproj)     | 3.4 GB, 63% GPU      | 71.51s     | 28.05s    |
| granite4.2:3b           | 2.5 GB, 100% GPU     | 169.65s    | 97.48s    |

**2.9x faster than the same model with the vision tower, 6.8x faster than granite.** 25.03s is
also close to the 20.3s `qwen2.5:3b` scored in April despite pi's system prompt having grown
substantially between 0.66.1 and 0.84.4 — so in like-for-like terms this is roughly a wash on
speed while being far better at multi-tool reasoning.

1.8 GB at 32K context leaves **half the card free**. This is the configuration to use.

**Setup:**

```bash
curl -L -C - --retry 10 --retry-all-errors \
  -o Qwen3.5-2B-UD-Q4_K_XL.gguf \
  https://huggingface.co/unsloth/Qwen3.5-2B-GGUF/resolve/main/Qwen3.5-2B-UD-Q4_K_XL.gguf
printf 'FROM ./Qwen3.5-2B-UD-Q4_K_XL.gguf\n' > Modelfile
ollama create qwen3.5-2b-textonly -f Modelfile
```

Verified after import: arch `qwen35`, 1.9B params, 262144 context, capabilities
`tools`/`thinking`/`completion`, no vision. Chat template and tool-call grammar are inferred
correctly from GGUF metadata — nothing else to configure.

### Practical conclusions

1. **Use `qwen3.5-2b-textonly` for everything** — agent loops, skills, tool calling. 100% GPU
   at every context length up to 32K, fastest mutation handling, best mutation quality
   (all 3 IDs resolved in parallel), 1.8 GB at 32K leaves half the card free.
2. **Always strip the vision projector.** This single change — `curl` the GGUF + a one-line
   Modelfile instead of `ollama pull` — took the same model from 3.0 GB / 76% GPU to 1.4 GB /
   100% GPU and made it **2.3x faster on the mutation test**. It is the highest-leverage finding
   of this whole exercise, and it applies to every multimodal model used for text work.
   It also sidesteps the `ollama pull hf.co/...` timeouts on the mmproj layer.
3. **`granite4.2:3b` is the runner-up, for short prompts only** — still the fastest single-tool
   call measured (1.62s), but its dense GQA KV cache needs 5.1 GB at 32K, exceeding the whole
   card. Cap at <= 8K and do not use it for agent loops. It resolved only 1 of 3 IDs on the
   mutation, consistent with IBM training the agentic-RL block only for 8B/30B.
4. **Skip Qwen3.5-4B on 4 GB.** No measurable quality gain over the 2B — byte-identical tool
   calls — at 2-4x the latency on tool calls and 2.8-4x under pi, and it spills 20% at 4K,
   rising to 42% at pi's 32K default where it needs 4.3 GB — more than the whole card.
5. **Set `num_ctx` explicitly.** pi's 32K default drove the worst spills; it costs the
   text-only 2B only 0.4 GB, but it pushed granite and the 4B over the edge.
6. **Ollama reserves ~1.1 GB it will not use.** At 3.2 GB resident only 2600 of 3681 MiB were in
   use. Budget for a real ceiling of ~2.2 GB of weights if you need guaranteed full residency.

## Reproducing / next steps

The shortlist above was run on 2026-09-11; see MEASURED RESULTS. To set up the winners:

```bash
# granite4.2:3b — short-prompt work, only model holding 100% GPU. Cap at 8K ctx.
ollama pull granite4.2:3b

# qwen3.5:2b — agent/skill work. Ollama adds a 675 MB vision projector.
ollama pull qwen3.5:2b

# text-only Qwen3.5 (avoids the mmproj; `ollama pull hf.co/...` times out on that layer)
curl -L -C - --retry 10 --retry-all-errors \
  -o Qwen3.5-4B-UD-Q4_K_XL.gguf \
  https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-UD-Q4_K_XL.gguf
printf 'FROM ./Qwen3.5-4B-UD-Q4_K_XL.gguf\n' > Modelfile
ollama create qwen3.5-4b-textonly -f Modelfile
```

Still untested:

- ~~A text-only `qwen3.5:2b`~~ — **DONE, it won.** See THE WINNER section.
- **Multi-turn agent loop.** Every mutation result here is turn 1 only; feeding the
  `list_catalog` results back and checking whether `record_event(add)` gets correct int IDs is
  the test that actually decides agentic viability.
- **North Mini Code 1.0** at UD-IQ3_XXS (11.7 GB) / UD-IQ4_XS (15.2 GB) with
  `llama.cpp --n-cpu-moe`. Needs a quiet session — 15 GB RAM was in use during these runs.
  Expect prefill to dominate on this AVX2-only CPU.
- ~~pi on `qwen3.5-4b-textonly`~~ — **DONE.** 69.32s / 35.26s, both correct, 4.3 GB @ 58% GPU.
- **`granite4.2:8b`** (5100 MiB) — the agentic-RL-trained Granite. Will spill, but Qwen's results
  show partial spill is no longer disqualifying.
- **Tuning Ollama's VRAM reserve.** It left 1116 MiB of 3681 unused at 3.2 GB resident; recovering
  that headroom may be what gets a 2.9 GB model fully onto the GPU.

## Sources

- Ollama registry API (`registry.ollama.ai`) — exact layer sizes
- [Granite 4.2 LLMs: How They're Built](https://huggingface.co/blog/ibm-granite/granite-4-2) — arch, BFCL v4, LiveCodeBench, agentic-RL scope
- [Qwen/Qwen3.5-4B model card](https://huggingface.co/Qwen/Qwen3.5-4B) — hybrid GDN+MoE, 256K ctx, benchmarks
- [unsloth/Qwen3.5-4B-GGUF](https://huggingface.co/unsloth/Qwen3.5-4B-GGUF), [unsloth/North-Mini-Code-1.0-GGUF](https://huggingface.co/unsloth/North-Mini-Code-1.0-GGUF) — quant sizes
- [CohereLabs/North-Mini-Code-1.0](https://huggingface.co/CohereLabs/North-Mini-Code-1.0), [Artificial Analysis writeup](https://artificialanalysis.ai/articles/north-mini-code-cohere-s-small-coding-focused-moe-model)
- [Raschka, Using Local Coding Agents](https://magazine.sebastianraschka.com/p/using-local-coding-agents) — usability thresholds, Gemma 4 E2B failure
- [NVIDIA Nemotron 3 Nano technical report](https://research.nvidia.com/labs/nemotron/files/NVIDIA-Nemotron-3-Nano-Technical-Report.pdf)
- [llama.cpp MoE offload guide](https://huggingface.co/blog/Doctor-Shotgun/llamacpp-moe-offload-guide), [ollama#11772](https://github.com/ollama/ollama/issues/11772)
