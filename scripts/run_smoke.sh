#!/usr/bin/env bash
# Run the 10-issue smoke set with one model config.
# Usage: scripts/run_smoke.sh [MODEL_CONFIG] [RUN_ID] [MODEL_CLASS] [KEY_ENV]
# Examples:
#   scripts/run_smoke.sh configs/models/union-alpha.yaml
#   scripts/run_smoke.sh configs/models/zen-union-alpha.yaml smoke-zen-1 litellm OPENCODE_API_KEY
set -euo pipefail
cd "$(dirname "$0")/.."

MODEL_CONFIG="${1:-configs/models/union-alpha.yaml}"
RUN_ID="${2:-smoke-10-$(date +%Y%m%d-%H%M%S)}"
MODEL_CLASS="${3:-openrouter}"
KEY_ENV="${4:-}"

if [ -n "$KEY_ENV" ] && [ -z "${!KEY_ENV:-}" ]; then
  echo "$KEY_ENV is not set. Check .env." >&2
  exit 1
fi
if [ "$MODEL_CLASS" = "openrouter" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  echo "OPENROUTER_API_KEY is not set. Copy .env.example to .env and fill it in." >&2
  exit 1
fi

# --filter is a regex matched with re.match against instance_id
FILTER=$(paste -sd'|' configs/smoke_10.txt)
mkdir -p "runs/$RUN_ID"

CONFIG_ARGS=(-c swebench.yaml -c configs/pilot.yaml -c "$MODEL_CONFIG")
if [ -n "$KEY_ENV" ]; then
  # LiteLLM's openai/ provider reads OPENAI_API_KEY from env; mapping keeps the
  # secret out of logged -c specs and saved trajectory configs.
  export OPENAI_API_KEY="${!KEY_ENV}"
fi
if [ "$KEY_ENV" = "OPENCODE_API_KEY" ]; then
  # opencode gateways require a stable session id per conversation + browser UA (Cloudflare)
  SESSION_ID="bench-$RUN_ID"
  CONFIG_ARGS+=(-c "model.model_kwargs.extra_headers={\"x-opencode-session\": \"$SESSION_ID\", \"User-Agent\": \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36\"}")
fi

echo "run_id=$RUN_ID model_config=$MODEL_CONFIG model_class=$MODEL_CLASS"
echo "filter=$FILTER"
mini-extra swebench \
  --subset verified \
  --split test \
  --filter "$FILTER" \
  --model-class "$MODEL_CLASS" \
  --environment-class docker \
  "${CONFIG_ARGS[@]}" \
  -o "runs/$RUN_ID" \
  -w 1 \
  2>&1 | tee "runs/$RUN_ID/batch.log"

echo "predictions: runs/$RUN_ID/preds.json"
