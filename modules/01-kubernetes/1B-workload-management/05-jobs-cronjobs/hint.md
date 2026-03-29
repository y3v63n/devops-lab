# Hints — Exercise 1B-05: Jobs and CronJobs

## Hint 1 (Try this first)
For Task 1, Jobs require `restartPolicy: Never` or `OnFailure` on the pod template — you cannot use the default `Always` that Deployments use. If you get a validation error, check `restartPolicy`.

## Hint 2
For Task 1, to wait for the Job to complete before viewing logs:
```bash
kubectl wait --for=condition=complete job/hello-job --timeout=60s
kubectl logs -l job-name=hello-job
```
The pod stays in `Completed` state so you can always retrieve logs later.

## Hint 3
For Task 2, parallelism works like a pool: Kubernetes maintains `parallelism` concurrent pods until `completions` total succeed. With `completions=3, parallelism=2`:
- Run 2 pods simultaneously
- When one finishes, start the 3rd
- Done when 3 total succeed

Watch this happen:
```bash
kubectl get pods -l job-name=parallel-demo -w
```

## Hint 4
For Task 3, the CronJob won't create its first Job until the next minute boundary. If you apply the CronJob at 14:32:45, the first run happens at 14:33:00. Wait at least 70 seconds after creation.

Check if it has run:
```bash
kubectl get cronjob minutely-job
# Look at LAST SCHEDULE column — it will show the last run time
```

## Hint 5
CronJob schedule debugging:
```bash
kubectl describe cronjob minutely-job
# Look at Events section for "SuccessfulCreate" messages
```

To manually trigger a CronJob immediately:
```bash
kubectl create job --from=cronjob/minutely-job manual-run-1
```

## Common Mistakes
- Jobs need `restartPolicy: Never` or `OnFailure` (not `Always`)
- `completions` and `parallelism` are at the Job spec level, not the pod spec level
- CronJob schedule uses UTC timezone by default
- Completed job pods are NOT automatically deleted — use `ttlSecondsAfterFinished` to auto-clean
- `kubectl delete job` also deletes the pods it created
