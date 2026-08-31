#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  airflow_api.sh METHOD PATH [JSON_BODY]

Examples:
  airflow_api.sh GET /api/v2/dags
  airflow_api.sh GET '/api/v2/dags/my_dag/dagRuns?limit=10&order_by=-start_date'
  airflow_api.sh POST /api/v2/dags/my_dag/dagRuns '{"conf":{}}'
EOF
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage
  exit 2
fi

method="$1"
path="$2"
body="${3:-}"

env_file="${AIRFLOW_ENV_FILE:-$HOME/.airflow.env}"
if [ ! -f "$env_file" ]; then
  echo "Missing credential file: $env_file" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$env_file"
set +a

base_url="${AIRFLOW_BASE_URL:-${AIRFLOW_API_URL:-${AIRFLOW_URL:-${ENDPOINT_URL:-https://spire.ap.eu-north-1.k8s.int.avs.io}}}}"
base_url="${base_url%/}"

token="${AIRFLOW_TOKEN:-${AIRFLOW_JWT_TOKEN:-${AIRFLOW_API_TOKEN:-${TOKEN:-}}}}"
username="${AIRFLOW_USERNAME:-${AIRFLOW_USER:-${USERNAME:-${USER:-}}}}"
password="${AIRFLOW_PASSWORD:-${PASSWORD:-${AIRFLOW_PASS:-}}}"

curl_args=(-fsS -X "$method" -H "Accept: application/json")

if [ -n "$body" ]; then
  curl_args+=(-H "Content-Type: application/json" -d "$body")
fi

if [ -n "$token" ]; then
  curl_args+=(-H "Authorization: Bearer $token")
elif [ -n "$username" ] && [ -n "$password" ]; then
  token_request="$(
    python3 - "$username" "$password" <<'PY' | curl -fsS -X POST "$base_url/auth/token" -H "Content-Type: application/json" -d @- 2>/dev/null || true
import json
import sys

print(json.dumps({"username": sys.argv[1], "password": sys.argv[2]}))
PY
  )"
  token="$(
    python3 -c 'import json,sys; text=sys.stdin.read().strip(); data=json.loads(text) if text else {}; print(data.get("access_token") or data.get("token") or data.get("jwt") or "")' <<PY || true
$token_request
PY
  )"
  if [ -n "$token" ]; then
    curl_args+=(-H "Authorization: Bearer $token")
  else
    curl_args+=(-u "$username:$password")
  fi
else
  echo "No token or username/password found in $env_file" >&2
  exit 1
fi

case "$path" in
  http://*|https://*) url="$path" ;;
  /*) url="$base_url$path" ;;
  *) url="$base_url/$path" ;;
esac

curl "${curl_args[@]}" "$url"
