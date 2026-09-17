# Results: Muse Spark thinking levels on SWE-bench Verified (10-task smoke)

Model: `muse-spark-1.3-contributor-free` via opencode Zen (Responses API), all
runs at $0 on the free tier. Agent: mini-swe-agent 2.4.6, identical config for
every level (step_limit 50, cost_limit 1.0, fresh Docker container per task).
Only `reasoning.effort` varies. Scored with the official SWE-bench harness.

| Level | Resolved | Submitted | API calls | Wall time | Run dir |
|---|---|---|---|---|---|
| default (no effort param) | 7/10 | 8 (2 hit 50-step limit, 1 wrong) | 370 | ~54 min* | [runs/spark-default-1](/Users/amin/benchmark-llms/runs/spark-default-1) |
| low | 10/10 | 10 | 209 | ~16 min | [runs/spark-low-1](/Users/amin/benchmark-llms/runs/spark-low-1) |
| high | 7/9 scored | 7 (2 step-limit, 1 free-quota 429, unscored) | 310 | ~51 min | [runs/spark-high-1](/Users/amin/benchmark-llms/runs/spark-high-1) |

\* includes first-time Docker image pulls.

Task set: [configs/smoke_10.txt](/Users/amin/benchmark-llms/configs/smoke_10.txt).
Each run dir holds `preds.json`, per-instance trajectories, logs, and the
harness `report.json`.

## Caveats

- n=10 with a nondeterministic free endpoint: low beating default/high may be
  noise. Needs the 50-task set plus repeats for error bars.
- Free-tier gateway is flaky (transient 500s/503s, one 10-minute hang, TLS
  hiccups). The harness retries; persistent failures are reported as infra,
  not model misses.
- High reasoning burns free quota faster and hit `FreeUsageLimitError` (429)
  on the last instance; it also trips the 50-step cap more often, which may
  reflect cost-per-step rather than capability.
- As of 2026-09-16 the Zen free tier started returning 403
  ("free tier can only be used from within OpenCode") for direct API calls
  that previously worked. The opencode CLI path still works. Re-running these
  levels may require the CLI or waiting for gateway policy to settle.
