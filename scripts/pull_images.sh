#!/usr/bin/env bash
# Pre-pull SWE-bench eval images for the smoke list so runs never hit pull timeouts.
# Usage: scripts/pull_images.sh [INSTANCES_FILE]
set -euo pipefail
cd "$(dirname "$0")/.."

INSTANCES="${1:-configs/smoke_10.txt}"
uv run python - "$INSTANCES" <<'EOF'
import subprocess, sys
from datasets import load_dataset

want = [l.strip() for l in open(sys.argv[1]) if l.strip()]
ds = load_dataset("SWE-bench/SWE-bench_Verified", split="test")
images = {d["instance_id"]: d["image"] for d in ds if d["instance_id"] in set(want)}
missing = set(want) - set(images)
if missing:
    print(f"missing from dataset: {missing}", file=sys.stderr)
    sys.exit(1)
for iid in want:
    img = images[iid]
    print(f"=== {iid} -> {img}", flush=True)
    subprocess.run(["docker", "pull", "--platform", "linux/amd64", img], check=True)
print(f"pulled {len(images)} images")
EOF
