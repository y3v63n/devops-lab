# Exercise 1B-05: Jobs and CronJobs

## Concept

While Deployments run continuously, **Jobs** run to completion and **CronJobs** schedule Jobs on a time basis.

### Jobs
```yaml
spec:
  completions: 3      # How many successful pods needed
  parallelism: 2      # How many pods can run at once
  backoffLimit: 4     # Retries before marking failed
```

| completions | parallelism | Behavior |
|-------------|-------------|---------|
| 1 | 1 | Single pod, run once |
| 3 | 1 | Run 3 pods sequentially |
| 3 | 2 | Run up to 2 pods at once until 3 complete |

### CronJobs
Use standard cron syntax:
```
┌──────── minute (0-59)
│ ┌────── hour (0-23)
│ │ ┌──── day of month (1-31)
│ │ │ ┌── month (1-12)
│ │ │ │ ┌ day of week (0-6, Sun=0)
* * * * *
```
- `* * * * *` — every minute
- `0 * * * *` — every hour
- `0 2 * * *` — 2am daily

### ConcurrencyPolicy
- `Allow` (default) — overlapping jobs are allowed
- `Forbid` — skip if previous still running
- `Replace` — cancel previous, start new

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1B-05
```

### Task 1 — Simple Job
Create a Job that echoes a message and exits:
```bash
cat > /tmp/devops-lab/1B-05/job.yaml << 'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: hello-job
spec:
  template:
    spec:
      containers:
      - name: hello
        image: busybox:1.35
        command: ["sh", "-c", "echo 'Hello from K8s Job' && date"]
      restartPolicy: Never
  backoffLimit: 2
EOF
kubectl apply -f /tmp/devops-lab/1B-05/job.yaml

# Wait for completion
kubectl wait --for=condition=complete job/hello-job --timeout=60s

# Get the logs
kubectl logs -l job-name=hello-job
```

### Task 2 — Parallel Job
Create a Job with multiple completions and parallelism:
```bash
kubectl create job parallel-job \
  --image=busybox:1.35 \
  -- sh -c "echo 'Pod $HOSTNAME completed'; sleep 5"

# Edit to add completions/parallelism
kubectl patch job parallel-job --type=merge -p '{"spec":{"completions":3,"parallelism":2}}'
```

Alternatively, apply a full YAML:
```bash
cat > /tmp/devops-lab/1B-05/parallel-job.yaml << 'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-demo
spec:
  completions: 3
  parallelism: 2
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.35
        command: ["sh", "-c", "echo Pod $HOSTNAME completed at $(date); sleep 3"]
      restartPolicy: Never
EOF
kubectl apply -f /tmp/devops-lab/1B-05/parallel-job.yaml

# Watch pods spin up
kubectl get pods -l job-name=parallel-demo -w &
sleep 20 && kill %1 2>/dev/null

kubectl get pods -l job-name=parallel-demo > /tmp/devops-lab/1B-05/parallel-jobs.txt
kubectl logs -l job-name=parallel-demo >> /tmp/devops-lab/1B-05/parallel-jobs.txt
```

### Task 3 — CronJob
Create a CronJob that runs every minute:
```bash
cat > /tmp/devops-lab/1B-05/cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: minutely-job
spec:
  schedule: "* * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: reporter
            image: busybox:1.35
            command: ["sh", "-c", "echo CronJob ran at $(date)"]
          restartPolicy: OnFailure
EOF
kubectl apply -f /tmp/devops-lab/1B-05/cronjob.yaml

echo "Waiting up to 90 seconds for CronJob to run..."
kubectl get cronjob minutely-job -w &
sleep 90 && kill %1 2>/dev/null

kubectl get jobs -l app.kubernetes.io/name=minutely-job 2>/dev/null || \
  kubectl get jobs | grep minutely
```

### Task 4 — Document Use Cases
```bash
cat > /tmp/devops-lab/1B-05/job-usecases.txt << 'EOF'
Kubernetes Jobs and CronJobs — Real-World Use Cases

Use Case 1: Database Migrations
  - Run as a Job before deploying a new app version
  - Ensures migration completes exactly once
  - Fails safely (backoffLimit) instead of crashing app servers

Use Case 2: Batch Data Processing
  - Process large datasets in parallel (completions=N, parallelism=M)
  - Each pod handles a shard of the data
  - Job controller handles retries on pod failures

Use Case 3: Scheduled Reports / Cleanup
  - CronJob runs nightly to generate reports or archive old data
  - ConcurrencyPolicy: Forbid prevents duplicate runs if processing is slow
  - successfulJobsHistoryLimit keeps logs accessible without accumulating forever
EOF
```

---

## What Just Happened

- The Job ran to completion and the pod remained in `Completed` state (not deleted)
- The parallel Job spawned 2 pods simultaneously until 3 completions were achieved
- The CronJob created a new Job object every minute — each Job creates a pod
- Old Job pods accumulate unless `ttlSecondsAfterFinished` or history limits are set

---

## Interview Question

**"What happens if a CronJob's previous run hasn't finished when the next one is scheduled?"**

Strong answer: It depends on `concurrencyPolicy`. With `Allow` (default), both runs execute simultaneously — risky if they compete for the same resources. With `Forbid`, the new run is skipped entirely — the system logs a warning but doesn't fail. With `Replace`, the running job is cancelled and a new one starts. For most real-world batch jobs, `Forbid` is safest to prevent duplicate processing, but you need monitoring to catch skipped runs.
