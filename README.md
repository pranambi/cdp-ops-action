# oozie-ops-action

GitHub Actions workflow to manage Oozie jobs on a CDP cluster. Replaces direct edge node access with a controlled, auditable interface.

## Why this exists

Previously, admins SSHed into the CDP edge node to run Oozie commands manually — no audit trail, no approval, no visibility. This workflow provides a controlled alternative.

## Supported operations

| Operation | Description |
|---|---|
| `kill` | Kill a running Oozie job |
| `suspend` | Pause a running Oozie job |
| `resume` | Resume a suspended Oozie job |
| `restart` | Kill and rerun a job from the beginning |
| `restart_failed_node` | Rerun only the failed node in a job |

## How to trigger

1. Go to **Actions** tab → **Oozie Operations**
2. Click **Run workflow**
3. Select the operation
4. Enter the Oozie Job ID (format: `0000001-240101000000000-oozie-oozi-W`)
5. Enter node name if operation is `restart_failed_node`
6. Click **Run workflow**

## Job ID format

```
0000001-240101000000000-oozie-oozi-W
│       │               │          └─ W=Workflow, C=Coordinator, B=Bundle
│       │               └─ oozie server identifier
│       └─ timestamp
└─ sequence number
```

## Audit log

Every operation is recorded in [audit/audit_log.csv](audit/audit_log.csv) with:
- Timestamp
- Operation performed
- Job ID
- Node name (if applicable)
- Who triggered it
- Result (success/failure)

## Secrets required (when connecting to real CDP)

| Secret | Description |
|---|---|
| `OOZIE_URL` | Oozie server URL e.g. `http://cdp-edge-node:11000/oozie` |
| `CDP_USERNAME` | CDP cluster username |
| `CDP_PASSWORD` | CDP cluster password |

Set these in: **Settings → Secrets and variables → Actions**
