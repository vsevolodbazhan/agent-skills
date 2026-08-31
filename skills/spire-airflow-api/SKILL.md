---
name: spire-airflow-api
description: Query and inspect the Apache Airflow stable REST API for the Spire Airflow instance at spire.ap.eu-north-1.k8s.int.avs.io. Use when Codex needs to list DAGs, inspect DAG runs, check task instances, read logs or health/version metadata, trigger DAG runs, pause or unpause DAGs, or perform other Airflow API operations against this Spire environment using credentials from ~/.airflow.env.
---

# Spire Airflow API

## Core Rules

- Use the Apache Airflow stable REST API reference: https://airflow.apache.org/docs/apache-airflow/stable/stable-rest-api-ref.html.
- Use the Spire Airflow base URL `https://spire.ap.eu-north-1.k8s.int.avs.io`.
- Load credentials from `~/.airflow.env`; do not ask the user to paste secrets into chat.
- Prefer read-only requests unless the user explicitly asks to mutate state, such as triggering a DAG run, clearing tasks, patching DAG pause state, or updating variables/connections.
- Treat returned data as potentially sensitive. Summarize only what is needed for the user's request.

## Quick Start

Use the bundled helper for most calls:

```bash
bash /path/to/spire-airflow-api/scripts/airflow_api.sh GET /api/v2/dags
bash /path/to/spire-airflow-api/scripts/airflow_api.sh GET '/api/v2/dags/example_dag/dagRuns?limit=10&order_by=-start_date'
```

For POST/PATCH/DELETE calls, pass the JSON request body as the third argument:

```bash
bash /path/to/spire-airflow-api/scripts/airflow_api.sh POST /api/v2/dags/example_dag/dagRuns '{"conf":{}}'
```

Read `references/airflow-api.md` when you need endpoint examples, authentication details, or credential variable conventions.

## Workflow

1. Source `~/.airflow.env` before making requests, or use `scripts/airflow_api.sh` which does this automatically.
2. Identify the stable REST endpoint in the Airflow docs. Use `/api/v2/...` for current stable Airflow; if the server is an Airflow 2 deployment returning 404 for `/api/v2`, verify its version and use `/api/v1/...` only when the server requires it.
3. Start with small, bounded queries. Add `limit`, `offset`, `dag_id_pattern`, `order_by`, and date filters when available.
4. For errors, capture the HTTP status and response body. A `401` or `403` usually means credentials or permissions; a `404` often means the wrong API version or an encoded DAG/task/run identifier issue.
5. Before state-changing requests, restate the exact target and payload unless the user's instruction is already explicit.

## Common Queries

- List DAGs: `GET /api/v2/dags?limit=100`
- Inspect one DAG: `GET /api/v2/dags/{dag_id}`
- List DAG runs: `GET /api/v2/dags/{dag_id}/dagRuns?limit=20&order_by=-start_date`
- Inspect a DAG run: `GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}`
- List task instances for a run: `GET /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances`
- Read task logs: use the documented task log endpoint for the server's Airflow version, encoding `dag_id`, `dag_run_id`, `task_id`, and `map_index` where required.
- Check API/server health: use the documented health or version endpoint for the deployed Airflow version.

## Output Handling

- Prefer `jq` for local filtering when available.
- If `jq` is unavailable, use Python's `json` module for pretty-printing or extracting fields.
- Include the endpoint path, important filters, and time window in the final answer so the user can reproduce the result.
