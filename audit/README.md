# Audit Logs

Auto-updated by GitHub Actions after every operation. Each file corresponds to a workflow.

| File | Workflow | Updated by |
|---|---|---|
| `audit_log_Prod.csv` | Oozie Operations — Prod runs | `oozie-ops.yml` |
| `audit_log_Test-deploy.csv` | Oozie Operations — Test-deploy runs | `oozie-ops.yml` |
| `audit_log_basic.csv` | Oozie Operations (Basic) | `oozie-ops-basic.yml` |
| `audit_log_pr.csv` | Oozie Operations (PR-based) | `oozie-ops-pr.yml` |
| `audit_log_scripts.csv` | Script Runner | `script-runner.yml` |

## Columns

| Column | Description |
|---|---|
| `timestamp` | When the operation ran (UTC) |
| `environment` | Prod or Test-deploy (where applicable) |
| `operation` | Kill / Suspend / Resume / Restart / Restart_failed_node |
| `job_id` | Oozie Job ID |
| `node_name` | Node name (Restart_failed_node only, otherwise N/A) |
| `triggered_by` / `merged_by` | GitHub username who triggered or merged |
| `run_as` | OS user the script ran as (Script Runner only) |
| `reason` | Reason provided (PR-based only) |
| `status` | success or failure |

Each log keeps the latest **3 entries** (rotating — oldest dropped when limit is reached).
