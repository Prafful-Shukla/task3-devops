#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:?AWS_REGION must be set}"
: "${INSTANCE_ID:?INSTANCE_ID must be set}"
: "${SECRET_ID:?SECRET_ID must be set}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"
: "${GITHUB_REF_NAME:?GITHUB_REF_NAME must be set}"

repo_url="${APP_REPOSITORY_URL:-https://github.com/${GITHUB_REPOSITORY}.git}"
app_dir="${APP_DIR:-/opt/task3/app}"
payload_file="$(mktemp)"

cleanup() {
  rm -f "$payload_file"
}

trap cleanup EXIT

export APP_DIR="$app_dir"
export REPO_URL="$repo_url"

python3 <<'PY' >"$payload_file"
import json
import os
import shlex
import sys

app_dir = os.environ["APP_DIR"]
repo_url = os.environ["REPO_URL"]
branch = os.environ["GITHUB_REF_NAME"]
region = os.environ["AWS_REGION"]
secret_id = os.environ["SECRET_ID"]

commands = [
    "set -euo pipefail",
    f"APP_DIR={shlex.quote(app_dir)}",
    f"REPO_URL={shlex.quote(repo_url)}",
    f"BRANCH={shlex.quote(branch)}",
    f"AWS_REGION={shlex.quote(region)}",
    f"SECRET_ID={shlex.quote(secret_id)}",
    'mkdir -p "$(dirname "$APP_DIR")"',
    'if [ ! -d "$APP_DIR/.git" ]; then git clone "$REPO_URL" "$APP_DIR"; fi',
    'cd "$APP_DIR"',
    'git fetch origin "$BRANCH"',
    'if git show-ref --verify --quiet "refs/heads/$BRANCH"; then git checkout "$BRANCH"; else git checkout -b "$BRANCH" "origin/$BRANCH"; fi',
    'git pull --ff-only origin "$BRANCH"',
    'printf "AWS_REGION=%s\\nSECRET_ID=%s\\n" "$AWS_REGION" "$SECRET_ID" > .env',
    'docker-compose down --remove-orphans || true',
    'docker-compose up -d --build',
    'sleep 10',
    'curl -fsS http://localhost/',
    'curl -fsS http://localhost/api/test-db',
]

json.dump({"commands": commands}, sys.stdout)
PY

command_id="$(
  aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --comment "Deploy task3 from GitHub Actions" \
    --parameters "file://${payload_file}" \
    --query "Command.CommandId" \
    --output text
)"

echo "Started SSM deployment command: $command_id"

if ! aws ssm wait command-executed \
  --region "$AWS_REGION" \
  --command-id "$command_id" \
  --instance-id "$INSTANCE_ID"; then
  aws ssm get-command-invocation \
    --region "$AWS_REGION" \
    --command-id "$command_id" \
    --instance-id "$INSTANCE_ID" \
    --output json || true
  exit 1
fi

aws ssm get-command-invocation \
  --region "$AWS_REGION" \
  --command-id "$command_id" \
  --instance-id "$INSTANCE_ID" \
  --query "{Status:Status,StandardOutputContent:StandardOutputContent,StandardErrorContent:StandardErrorContent}" \
  --output json
