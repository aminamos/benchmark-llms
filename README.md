# LLM coding benchmark (pilot)

Runs SWE-bench Verified issues through the same agent with each model. Pilot: 10-issue smoke test, then 50 for comparison.

## Fair setup

- Same agent: `mini-swe-agent` 2.4.6, bundled `swebench.yaml` + [configs/pilot.yaml](/Users/amin/benchmark-llms/configs/pilot.yaml) (step_limit 50, cost_limit 1.0, concurrency 1)
- Fresh isolated Docker container per task (`--environment-class docker`)
- Same instructions/tools/time/token budget per model; only the model config changes
- Scoring: % resolved + time, tokens, cost, API failures; repeat runs for variability
- Safety: disposable containers, secrets via env only, no production credentials

## Setup

```bash
cp .env.example .env   # fill in OPENROUTER_API_KEY
uv venv
uv pip install -r requirements.txt
chmod +x scripts/*.sh
```

Requires Docker running. Confirm the Union Alpha endpoint permits automated evaluation and check its rate limits before a full run.

## Smoke test (1 instance, then 10)

```bash
source .venv/bin/activate
scripts/run_single.sh pytest-dev__pytest-7236 configs/models/union-alpha.yaml
scripts/run_smoke.sh configs/models/union-alpha.yaml
```

## Providers (all free, $0)

| Config | Provider | Model | Run with |
|---|---|---|---|
| `union-alpha.yaml` | OpenRouter | `stealth/union-alpha` | `... union-alpha.yaml openrouter` |
| `zen-union-alpha.yaml` | opencode Zen | `union-alpha` | `... zen-union-alpha.yaml litellm OPENCODE_API_KEY` |
| `go-union-alpha.yaml` | opencode Go | `union-alpha` | `... go-union-alpha.yaml litellm OPENCODE_API_KEY` |
| `spark-default.yaml` | opencode Zen | `muse-spark-1.3-contributor-free`, default reasoning | `... spark-default.yaml litellm_response OPENCODE_API_KEY` |
| `spark-low.yaml` | opencode Zen | `muse-spark-1.3-contributor-free`, low effort | `... spark-low.yaml litellm_response OPENCODE_API_KEY` |
| `spark-high.yaml` | opencode Zen | `muse-spark-1.3-contributor-free`, high effort | `... spark-high.yaml litellm_response OPENCODE_API_KEY` |

OpenRouter note: free models require allowing non-ZDR endpoints at
openrouter.ai/settings/privacy, otherwise requests 404. opencode note: the
gateways need an `x-opencode-session` header, which the scripts inject
per run.

Trajectories + `preds.json` land in `runs/<run_id>/`.

## Score

```bash
scripts/score_local.sh runs/<run_id>/preds.json <run_id>
```

## Compare models

1. Copy `configs/models/model-b.yaml.example` to `configs/models/<model-b-version>.yaml`, pin the exact version. Same for model C.
2. Run `scripts/run_smoke.sh` once per model config with a distinct `RUN_ID`.
3. Score each `runs/<run_id>/preds.json` and compare resolved % + cost/time.

This measures coding performance in this agent, not universal intelligence. Close results need more tasks (50+).
