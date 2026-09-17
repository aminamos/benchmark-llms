#!/usr/bin/env python3
"""Convert a mini-swe-agent single-run traj.json into a SWE-bench predictions file.

Usage: traj_to_preds.py <traj.json> <instance_id> <predictions.json>
"""
import json
import sys

traj_path, instance_id, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
traj = json.load(open(traj_path))
info = traj.get("info", {})
submission = info.get("submission", "")
model_name = info.get("config", {}).get("model", {}).get("model_name", "unknown")
if info.get("exit_status") != "Submitted" or not submission:
    print(f"warning: exit_status={info.get('exit_status')!r}, empty patch", file=sys.stderr)
preds = {instance_id: {"instance_id": instance_id, "model_patch": submission, "model_name_or_path": model_name}}
json.dump(preds, open(out_path, "w"), indent=2)
print(f"wrote {out_path}: {len(submission)} patch chars for {instance_id}")
