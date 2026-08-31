# Airflow API Reference Notes

## Sources

- Stable REST API reference: https://airflow.apache.org/docs/apache-airflow/stable/stable-rest-api-ref.html
- Public API authentication: https://airflow.apache.org/docs/apache-airflow/stable/security/api.html

## Credential File

Load credentials from `~/.airflow.env`. Support common variable names so the skill works with different local env-file styles:

- Base URL: `AIRFLOW_BASE_URL`, `AIRFLOW_API_URL`, `AIRFLOW_URL`, or `ENDPOINT_URL`
- Bearer token: `AIRFLOW_TOKEN`, `AIRFLOW_JWT_TOKEN`, `AIRFLOW_API_TOKEN`, or `TOKEN`
- Username: `AIRFLOW_USERNAME`, `AIRFLOW_USER`, `USERNAME`, or `USER`
- Password: `AIRFLOW_PASSWORD`, `PASSWORD`, or `AIRFLOW_PASS`

If a bearer token is present, send `Authorization: Bearer <token>`.

If username and password are present and no token is present, request a JWT from `/auth/token` with JSON body `{"username":"...","password":"..."}` and then send it as a bearer token. If that endpoint is not supported by the deployed auth manager, fall back to Basic auth only when the env file or server behavior indicates Basic auth is expected.

## Endpoint Pattern

Use current stable Airflow endpoints under `/api/v2/...` first:

```text
GET  /api/v2/dags
GET  /api/v2/dags/{dag_id}
GET  /api/v2/dags/{dag_id}/dagRuns
POST /api/v2/dags/{dag_id}/dagRuns
GET  /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}
GET  /api/v2/dags/{dag_id}/dagRuns/{dag_run_id}/taskInstances
```

Some Airflow 2 deployments expose the stable API under `/api/v1/...`. Use `/api/v1` only after confirming `/api/v2` is not available or the server version requires it.

## Request Hygiene

- URL-encode path components such as `dag_id`, `dag_run_id`, and `task_id` when they contain spaces, slashes, colons, plus signs, or other reserved characters.
- Add pagination parameters such as `limit` and `offset` for list endpoints.
- Add ordering where supported, commonly `order_by=-start_date` or a similar documented field.
- Keep mutation payloads minimal and explicit. For DAG triggers, include `conf` only when the user supplied configuration or an empty object is appropriate.
- Preserve raw JSON for debugging until the user-facing summary is complete.
