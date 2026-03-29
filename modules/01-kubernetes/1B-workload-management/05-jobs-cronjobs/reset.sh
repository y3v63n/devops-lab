#!/usr/bin/env bash
echo "Resetting Exercise 1B-05 — Jobs and CronJobs..."

# Delete CronJobs (must delete before associated jobs are cleaned up)
kubectl delete cronjob minutely-job --ignore-not-found=true
echo "  Deleted CronJob: minutely-job"

# Delete Jobs
kubectl delete job hello-job --ignore-not-found=true
kubectl delete job parallel-demo --ignore-not-found=true
kubectl delete job parallel-job --ignore-not-found=true
echo "  Deleted Jobs: hello-job, parallel-demo, parallel-job"

# Delete any leftover pods from completed jobs
kubectl delete pods -l job-name=hello-job --ignore-not-found=true
kubectl delete pods -l job-name=parallel-demo --ignore-not-found=true

# Also delete any jobs created by the CronJob
kubectl get jobs -o name 2>/dev/null | grep "minutely-job" | xargs kubectl delete --ignore-not-found=true 2>/dev/null || true
echo "  Cleaned up CronJob-spawned jobs"

# Clean up work directory
rm -rf /tmp/devops-lab/1B-05
echo "  Cleaned /tmp/devops-lab/1B-05"

echo "Reset complete."
