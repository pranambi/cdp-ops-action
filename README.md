# oozie-ops-action

GitHub Actions workflows to manage Oozie jobs on a CDP cluster. Replaces direct edge node access with a controlled, auditable interface.

## Why this exists

Previously, admins SSHed into the CDP edge node to run Oozie commands manually — no audit trail, no approval, no visibility. These workflows provide a controlled alternative.

---

## Approaches

Two workflow approaches are available, both supporting the same operations:

### Approach 1 — Environment-aware (`Oozie Operations`)

Workflow: `.github/workflows/oozie-ops.yml`

Includes an **environment selector** (Prod / Test-deploy) as part of the trigger. Useful when you want to track which environment each operation targeted and maintain separate audit logs per environment.

- Environment shown in run title, approval summary, and audit log
- Separate audit files: `audit/audit_log_Prod.csv` and `audit/audit_log_Test-deploy.csv`
- Kill and Restart require approval via `cdp-production` environment

### Approach 2 — Basic (`Oozie Operations (Basic)`)

Workflow: `.github/workflows/oozie-ops-basic.yml`

No environment selector. The workflow executes the operation against Oozie regardless of which environment the job belongs to — since both Prod and Test-deploy share the same Oozie server and there is no naming convention to distinguish job IDs by environment.

- Simpler trigger — just operation and job ID
- Single audit file: `audit/audit_log_basic.csv`
- Kill and Restart still require approval via `cdp-production` environment

### Approach 3 — PR-based (`Oozie Operations (PR-based)`)

Workflow: `.github/workflows/oozie-ops-pr.yml`

Operations are requested by creating a YAML file in the `requests/` folder and raising a PR. Merging the PR triggers the workflow — **the PR review itself is the approval gate**. No manual approval step needed.

- Admin creates a request file from `requests/TEMPLATE.yaml`
- Raises a PR — reviewer reviews the file and approves the PR
- Merge triggers the workflow automatically
- Git history + merged PR = permanent audit trail (no separate CSV needed for traceability)
- Also writes to `audit/audit_log_pr.csv` for quick reference
- Best for **planned operations** where review before execution is preferred

**How to raise a PR-based request:**
1. Create a branch: `git checkout -b ops/kill-<job-id>`
2. Copy `requests/TEMPLATE.yaml` to a new file e.g. `requests/kill-<job-id>.yaml`
3. Fill in the operation, job ID, and reason
4. Push and raise a PR
5. Reviewer approves and merges — operation executes automatically

---

## Supported operations

| Operation | Description |
|---|---|
| `Kill` | Kill a running Oozie job |
| `Suspend` | Pause a running Oozie job |
| `Resume` | Resume a suspended Oozie job |
| `Restart` | Kill and rerun a job from the beginning |
| `Restart_failed_node` | Rerun only the failed node in a job |

## Job ID format

```
0000001-240101000000000-oozie-oozi-W
│       │               │          └─ W=Workflow, C=Coordinator, B=Bundle
│       │               └─ oozie server identifier
│       └─ timestamp
└─ sequence number
```

## How to trigger

1. Go to **Actions** tab
2. Select the workflow — **Oozie Operations** or **Oozie Operations (Basic)**
3. Click **Run workflow**
4. Fill in the inputs and click **Run workflow**
5. For `Kill` or `Restart` — an approver must approve before the operation executes
6. Stale requests older than 5 minutes are automatically rejected even if approved

## Audit logs

| File | Workflow |
|---|---|
| `audit/audit_log_Prod.csv` | Oozie Operations — Prod runs |
| `audit/audit_log_Test-deploy.csv` | Oozie Operations — Test-deploy runs |
| `audit/audit_log_basic.csv` | Oozie Operations (Basic) |
| `audit/audit_log_pr.csv` | Oozie Operations (PR-based) |

Each log captures: timestamp, operation, job ID, node name, triggered by, and status.

## Secrets required (when connecting to real CDP)

| Secret | Description |
|---|---|
| `OOZIE_URL` | Oozie server URL e.g. `http://cdp-edge-node:11000/oozie` |
| `CDP_USERNAME` | CDP cluster username |
| `CDP_PASSWORD` | CDP cluster password |

Set these in: **Settings → Secrets and variables → Actions**
