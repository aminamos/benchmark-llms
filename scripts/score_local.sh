#!/usr/bin/env bash
# Score a predictions file locally with the official SWE-bench harness.
# Usage: scripts/score_local.sh runs/<run_id>/preds.json <run_id>
set -euo pipefail
cd "$(dirname "$0")/.."

PREDICTIONS="${1:?usage: score_local.sh runs/<run_id>/preds.json <run_id>}"
RUN_ID="${2:?usage: score_local.sh runs/<run_id>/preds.json <run_id>}"

uv run python -m swebench.harness.run_evaluation \
  --dataset_name SWE-bench/SWE-bench_Verified \
  --predictions_path "$PREDICTIONS" \
  --run_id "$RUN_ID" \
  --report_dir "runs/$RUN_ID" \
  --max_workers 1
