---
name: access-spark-history-server
description: Access logs of Spark jobs from Spark History Server.
---

## Spark Version

3.5.3

## Finished and Ongoing Jobs

- Logs of finished jobs can be retrieved from the host `spark-logs.ap.eu-north-1.k8s.int.avs.io`.
- For ongoing jobs, forward port 4040 to localhost.

## Port Forwarding

- Find the running driver in the `kyuubi` Kubernetes namespace: `kubectl get pods -n kyuubi | grep driver`
- Then forward the port with `kubectl port-forward <driver> 4040:4040` to localhost.

## Accessing Logs

There are multiple ways to access logs. Each is listed below in order of preference:

- CLI app. Use `spark-history-cli --help` to see available commands.
- REST API.
- Computer use.
