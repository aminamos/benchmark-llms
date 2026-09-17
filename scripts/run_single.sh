#!/usr/bin/env bash
# Probe a single SWE-bench Verified instance with the pinned agent config.
# Usage: scripts/run_single.sh [INSTANCE_ID] [MODEL_CONFIG] [MODEL_CLASS] [KEY_ENV]
#   KEY_ENV: env var holding the model API key, injected as model.model_kwargs.api_key.
#            Omit for model classes that read their own env (e.g. openrouter).
# Examples:
#   scripts/run_single.sh pytest-dev__pytest-7236 configs/models/union-alpha.yaml openrouter
#   scripts/run_single.sh pytest-dev__pytest-7236 configs/models/zen-union-alpha.yaml litellm OPENCODE_API_KEY
set -euo pipefail
cd "$(dirname "$0")/.."

INSTANCE="${1:-pytest-dev__pytest-7236}"
MODEL_CONFIG="${2:-configs/models/union-alpha.yaml}"
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

RUN_ID="smoke-single-$(date +%Y%m%d-%H%M%S)"
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

echo "run_id=$RUN_ID instance=$INSTANCE model_config=$MODEL_CONFIG model_class=$MODEL_CLASS"
mini-extra swebench-single \
  --subset verified \
  --split test \
  -i "$INSTANCE" \
  --model-class "$MODEL_CLASS" \
  --environment-class docker \
  "${CONFIG_ARGS[@]}" \
  -o "runs/$RUN_ID/traj.json" \
  -y -l 1.0 --exit-immediately \
  2>&1 | tee "runs/$RUN_ID/single.log"
