# cdp-ops-action

GitHub Actions workflows to manage CDP cluster operations — Oozie job control and shell script execution. Replaces direct edge node access with a controlled, auditable, and approval-gated interface.

## Why this exists

Previously, admins and data scientists SSHed into the CDP edge node to run Oozie commands and shell scripts manually — no audit trail, no approval, no visibility. These workflows provide a controlled alternative entirely within GitHub.

---

## Workflows

### 1. Oozie Operations — Environment-aware (`oozie-ops.yml`)

Manual trigger via GitHub Actions UI. Includes an **environment selector** (Prod / Test-deploy).

- Operation and environment selected from dropdowns
- Kill and Restart require approval via `cdp-production` environment
- Stale approvals older than 5 minutes are automatically rejected
- Separate audit files per environment: `audit/audit_log_Prod.csv` and `audit/audit_log_Test-deploy.csv`

**How to trigger:**
1. Go to **Actions** → **Oozie Operations** → **Run workflow**
2. Select environment, operation, and enter Job ID
3. For Kill/Restart — approver must approve before execution

---

### 2. Oozie Operations — PR-based (`oozie-ops-pr.yml`)

GitOps approach. Edit `requests/request.yaml`, raise a PR — **merging the PR is the approval and triggers execution**.

- Best for planned operations where a review trail before execution is needed
- PR review replaces the approval gate
- Reason for the operation is documented in the request file
- Audit: `audit/audit_log_pr.csv` + full git history as permanent trail

**How to trigger:**
1. Create a branch: `git checkout -b ops/<operation>-<job-id>`
2. Edit `requests/request.yaml` with the operation details and reason
3. Push and raise a PR
4. Reviewer approves and merges — operation executes automatically

---

### 3. Script Runner (`script-runner.yml`)

Runs shell scripts on the CDP edge node. Scripts are pushed to the repo for version control — execution is triggered separately and manually via the GitHub Actions UI.

- Push scripts to `scripts/` via PR (version control only — no auto-execution on merge)
- To execute: trigger manually from **Actions** → **Script Runner** → **Run workflow**
- Select the script filename and the OS user to run as
- Requires approval via `cdp-production` environment before execution
- Stale approvals older than 5 minutes are automatically rejected
- If the specified user doesn't exist on the runner, falls back to current user (demo mode)
- In production: set `runs-on: self-hosted` and configure `/etc/sudoers` for the runner service account
- Audit: `audit/audit_log_scripts.csv`

**How to add and run a script:**
1. Add your script to `scripts/` — create a branch, push, raise PR, merge (no execution yet)
2. Go to **Actions** → **Script Runner** → **Run workflow**
3. Enter the script filename (e.g. `example.sh`) and the OS user to run as
4. Approver approves → script runs on the edge node

> Note: `runs-on: ubuntu-latest` is set for demo. Change to `self-hosted` after installing the GitHub Actions runner on the CDP edge node.

---

## Oozie Job ID format

\`\`\`
0000001-240101000000000-oozie-oozi-W
│       │               │          └─ W=Workflow, C=Coordinator, B=Bundle
│       │               └─ oozie server identifier
│       └─ timestamp
└─ sequence number
\`\`\`

## Supported Oozie operations

| Operation | Description |
|---|---|
| \`Kill\` | Kill a running Oozie job |
| \`Suspend\` | Pause a running Oozie job |
| \`Resume\` | Resume a suspended Oozie job |
| \`Restart\` | Kill and rerun a job from the beginning |
| \`Restart_failed_node\` | Rerun only the failed node in a job |

## Audit logs

| File | Workflow |
|---|---|
| \`audit/audit_log_Prod.csv\` | Oozie Operations — Prod runs |
| \`audit/audit_log_Test-deploy.csv\` | Oozie Operations — Test-deploy runs |
| \`audit/audit_log_pr.csv\` | Oozie Operations (PR-based) |
| \`audit/audit_log_scripts.csv\` | Script Runner |

## Secrets required (when connecting to real CDP)

| Secret | Used by | Description |
|---|---|---|
| \`OOZIE_URL\` | all Oozie workflows | Oozie server URL e.g. \`http://cdp-edge-node:11000/oozie\` |
| \`CDP_USERNAME\` | all Oozie workflows | CDP cluster username |
| \`CDP_PASSWORD\` | all Oozie workflows | CDP cluster password |
| \`HIVESERVER2_URL\` | `oozie-ops.yml` | HiveServer2 JDBC URL e.g. \`jdbc:hive2://cdp-edge-node:10000/default\` |
| \`HIVE_USERNAME\` | `oozie-ops.yml` | Hive username |
| \`HIVE_PASSWORD\` | `oozie-ops.yml` | Hive password |

Set these in: **Settings → Secrets and variables → Actions**

## Hive audit table setup

Run this once on your cluster before enabling Hive audit logging:

\`\`\`sql
CREATE DATABASE IF NOT EXISTS ops_audit;

CREATE TABLE IF NOT EXISTS ops_audit.cdp_ops_log (
    timestamp     STRING,
    environment   STRING,
    operation     STRING,
    job_id        STRING,
    node_name     STRING,
    triggered_by  STRING,
    github_run_id STRING,
    status        STRING
) PARTITIONED BY (log_date STRING)
  STORED AS ORC
  TBLPROPERTIES ('transactional'='true');
\`\`\`

Each workflow run inserts one row. Partitioned by `log_date` (YYYY-MM-DD) for efficient querying.

To query recent operations:

\`\`\`sql
SELECT * FROM ops_audit.cdp_ops_log
WHERE log_date >= '2024-01-01'
ORDER BY timestamp DESC;
\`\`\`
