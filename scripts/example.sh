#!/bin/bash
# Example script — replace with your actual Hadoop/Oozie commands
# This runs directly on the CDP edge node when merged to main

echo "Running on edge node: $(hostname)"
echo "Current user: $(whoami)"
echo "Timestamp: $(date -u)"

# Example: list Oozie jobs
# oozie jobs -jobtype wf -filter status=RUNNING

echo "Script completed successfully"
