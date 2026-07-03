# Requests

Used by the **Oozie Operations (PR-based)** workflow (`oozie-ops-pr.yml`).

## How to raise a request

1. Create a branch: `git checkout -b ops/<operation>-<job-id>`
2. Edit `request.yaml` with the operation details
3. Push and raise a PR
4. Reviewer approves and merges — the operation executes automatically

## request.yaml fields

| Field | Required | Description |
|---|---|---|
| `operation` | Yes | Kill / Suspend / Resume / Restart / Restart_failed_node |
| `job_id` | Yes | Oozie Job ID e.g. `0000001-240101000000000-oozie-oozi-W` |
| `node_name` | Only for `Restart_failed_node` | Node name to rerun |
| `reason` | Yes | Why this operation is needed — visible to the reviewer |

## Notes

- The PR review is the approval gate — no separate approval step
- Merging the PR triggers execution immediately
- Git history of `request.yaml` serves as a permanent audit trail
- Detailed log also written to `audit/audit_log_pr.csv`
