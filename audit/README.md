# Audit Logs

Auto-updated by GitHub Actions after every operation. Each subfolder corresponds to one workflow.

| Folder | File | Workflow |
|---|---|---|
| `oozie-ops/` | `audit_log_Prod.csv` | Oozie Operations — Prod runs |
| `oozie-ops/` | `audit_log_Test-deploy.csv` | Oozie Operations — Test-deploy runs |
| `oozie-ops-pr/` | `audit_log_pr.csv` | Oozie Operations (PR-based) |
| `script-runner/` | `audit_log_scripts.csv` | Script Runner |

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
