#!/usr/bin/env bash
set -euo pipefail

instance_id="${1:?usage: wait-for-ssm.sh <instance-id> [region] [max-attempts] [sleep-seconds]}"
region="${2:-us-east-1}"
max_attempts="${3:-30}"
sleep_seconds="${4:-10}"

for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  status="$(
    aws ssm describe-instance-information \
      --region "$region" \
      --query "InstanceInformationList[?InstanceId=='$instance_id'].PingStatus | [0]" \
      --output text 2>/dev/null || true
  )"

  if [[ "$status" == "Online" ]]; then
    echo "Instance $instance_id is online in AWS Systems Manager."
    exit 0
  fi

  echo "Waiting for instance $instance_id to register in Systems Manager ($attempt/$max_attempts)..."
  sleep "$sleep_seconds"
done

echo "Timed out waiting for instance $instance_id to become online in Systems Manager."
exit 1
