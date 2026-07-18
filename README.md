# cdp-ops-action

GitHub Actions workflows to manage CDP cluster operations — Oozie job control and shell script execution. Replaces direct edge node access with a controlled, auditable, and approval-gated interface.

## Why this exists

Previously, admins and data scientists SSHed into the CDP edge node to run Oozie commands and shell scripts manually — no audit trail, no approval, no visibility. These workflows provide a controlled alternative entirely within GitHub.

---

## Workflows

### 1. Oozie Operations — Environment-aware (`oozie-ops.yml`)

Manual trigger via GitHub Actions UI. Includes an **environment selector** (Prod / Test-deploy).

- Operation and environment selected from dropdowns
- Validates Oozie job ownership before executing — Prod jobs must be owned by `oozie`, Test-deploy jobs by `cicd_service_user1`
- Kill and Restart require approval via `cdp-production` environment
- Stale approvals older than 5 minutes are automatically rejected
- Runs inside the CDP runner image with Kerberos authentication (`kinit`)

**How to trigger:**
1. Go to **Actions** → **Oozie Operations** → **Run workflow**
2. Select environment, operation, and enter Job ID
3. Optionally enter a CR number for traceability
4. For Kill/Restart — approver must approve before execution

---

### 2. Oozie Operations — PR-based (`oozie-ops-pr.yml`)

GitOps approach. Edit `requests/request.yaml`, raise a PR — **merging the PR is the approval and triggers execution**.

- Best for planned operations where a review trail before execution is needed
- PR review replaces the approval gate
- Reason and CR number are documented in the request file

**How to trigger:**
1. Create a branch: `git checkout -b ops/<operation>-<job-id>`
2. Edit `requests/request.yaml` with the operation details, reason, and CR number
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

**How to add and run a script:**
1. Add your script to `scripts/` — create a branch, push, raise PR, merge (no execution yet)
2. Go to **Actions** → **Script Runner** → **Run workflow**
3. Enter the script filename (e.g. `example.sh`) and the OS user to run as
4. Approver approves → script runs on the edge node

---

## Oozie Job ID format

```
0000001-240101000000000-oozie-oozi-W
│       │               │          └─ W=Workflow, C=Coordinator, B=Bundle
│       │               └─ oozie server identifier
│       └─ timestamp
└─ sequence number
```

## Supported Oozie operations

| Operation | Description | Approval required |
|---|---|---|
| `Kill` | Kill a running Oozie job | Yes |
| `Suspend` | Pause a running Oozie job | No |
| `Resume` | Resume a suspended Oozie job | No |
| `Restart` | Kill and rerun a job from the beginning | Yes |
| `Restart_failed_node` | Rerun only the failed nodes in a workflow | No |

---

## Demo — Sample job IDs for testing

The runner image includes a sample jobs list at `/etc/oozie/oozie-jobs.json`. Use these job IDs when triggering workflows in demo mode (no real Oozie server needed). Using a job ID not in this list will fail with "Job ID not found on this cluster".

| Job ID | Name | Owner | Current Status | Environment to use |
|---|---|---|---|---|
| `0000001-240101120000000-oozie-oozi-W` | daily_etl_pipeline | `oozie` | RUNNING | **Prod** |
| `0000002-240101120000000-oozie-oozi-W` | data_ingestion_workflow | `cicd_service_user1` | RUNNING | **Test-deploy** |
| `0000003-240101120000000-oozie-oozi-C` | weekly_report_coordinator | `oozie` | SUSPENDED | **Prod** |
| `0000004-240101120000000-oozie-oozi-C` | spark_ingestion_coordinator | `cicd_service_user1` | RUNNING | **Test-deploy** |
| `0000005-240101120000000-oozie-oozi-B` | monthly_reconciliation_bundle | `oozie` | RUNNING | **Prod** |

> Job ownership is validated before execution. Use a Prod job ID with **Prod** environment and a Test-deploy job ID with **Test-deploy** environment, otherwise the ownership check will fail.

**Example — Suspend (no approval needed):**
- Environment: `Test-deploy`
- Operation: `Suspend`
- Job ID: `0000002-240101120000000-oozie-oozi-W`
- CR Number: `CHG0012345` (optional)

**Example — Kill (approval required):**
- Environment: `Prod`
- Operation: `Kill`
- Job ID: `0000001-240101120000000-oozie-oozi-W`
- CR Number: `CHG0012345` (optional)

**Example — Resume a suspended job:**
- Environment: `Prod`
- Operation: `Resume`
- Job ID: `0000003-240101120000000-oozie-oozi-C`

---

## Variables and secrets required

Set these in: **Settings → Secrets and variables → Actions**

| Type | Name | Description |
|---|---|---|
| Variable | `RUNNER_IMAGE` | CDP runner image e.g. `ghcr.io/pranambi/devops-cdp-image:latest` |
| Variable | `OOZIE_URL` | Oozie server URL e.g. `http://cdp-edge-node:11000/oozie` |
| Variable | `KRB5_PRINCIPAL` | Kerberos principal e.g. `cicd_service@REALM.COM` |
| Secret | `KRB5_KEYTAB_B64` | Base64-encoded Kerberos keytab for the service account |

> In demo mode, `OOZIE_URL` can be any placeholder (e.g. `http://demo-oozie:11000/oozie`) — the runner image's oozie wrapper falls back to demo mode automatically when the server is unreachable. `KRB5_KEYTAB_B64` can be any base64 string — the kinit wrapper skips authentication gracefully when the KDC is unreachable.

---

## Audit logging

Audit logs are written to a shared volume mounted on the runner at `/shared/cdp-ops-audit/` as monthly rotating log files.

| File | Workflow |
|---|---|
| `/shared/cdp-ops-audit/oozie-ops-YYYY-MM.log` | Oozie Operations |
| `/shared/cdp-ops-audit/oozie-ops-pr-YYYY-MM.log` | Oozie Operations (PR-based) |
| `/shared/cdp-ops-audit/script-runner-YYYY-MM.log` | Script Runner |

> In demo mode (no shared volume mounted), audit logging is skipped with a warning. Configure the volume on the self-hosted runner to enable it.
