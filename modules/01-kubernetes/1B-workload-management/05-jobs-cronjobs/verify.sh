#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1B-05"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1B-05 — Jobs and CronJobs"; echo ""

# Task 1: Simple job
echo "Task 1: Simple job"
[[ -f "$WORK_DIR/job.yaml" ]] \
  && check "job.yaml exists" "pass" \
  || check "job.yaml exists" "fail"

grep -q "Hello from K8s Job\|hello\|echo" "$WORK_DIR/job.yaml" 2>/dev/null \
  && check "job.yaml contains echo command" "pass" \
  || check "job.yaml contains echo command" "fail"

JOB_CONDITION=$(kubectl get job hello-job -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)
[[ "$JOB_CONDITION" == "True" ]] \
  && check "hello-job completed successfully" "pass" \
  || check "hello-job completed successfully (condition: $JOB_CONDITION)" "fail"

echo ""

# Task 2: Parallel job
echo "Task 2: Parallel job completions"
[[ -f "$WORK_DIR/parallel-jobs.txt" ]] \
  && check "parallel-jobs.txt exists" "pass" \
  || check "parallel-jobs.txt exists" "fail"

COMPLETIONS=$(kubectl get job parallel-demo -o jsonpath='{.status.succeeded}' 2>/dev/null)
[[ "$COMPLETIONS" -ge 3 ]] \
  && check "parallel-demo job has >= 3 completions (got $COMPLETIONS)" "pass" \
  || check "parallel-demo job has >= 3 completions (got $COMPLETIONS)" "fail"

echo ""

# Task 3: CronJob
echo "Task 3: CronJob exists and has run"
[[ -f "$WORK_DIR/cronjob.yaml" ]] \
  && check "cronjob.yaml exists" "pass" \
  || check "cronjob.yaml exists" "fail"

kubectl get cronjob minutely-job &>/dev/null \
  && check "minutely-job CronJob exists" "pass" \
  || check "minutely-job CronJob exists" "fail"

LAST_SCHEDULE=$(kubectl get cronjob minutely-job -o jsonpath='{.status.lastScheduleTime}' 2>/dev/null)
[[ -n "$LAST_SCHEDULE" ]] \
  && check "CronJob has run at least once (lastScheduleTime: $LAST_SCHEDULE)" "pass" \
  || check "CronJob has not run yet — wait a minute and retry" "fail"

echo ""

# Task 4: Use cases file
echo "Task 4: Job use cases documented"
[[ -f "$WORK_DIR/job-usecases.txt" ]] \
  && check "job-usecases.txt exists" "pass" \
  || check "job-usecases.txt exists" "fail"

WORD_COUNT=$(wc -w < "$WORK_DIR/job-usecases.txt" 2>/dev/null || echo 0)
[[ "$WORD_COUNT" -ge 30 ]] \
  && check "job-usecases.txt has sufficient content ($WORD_COUNT words)" "pass" \
  || check "job-usecases.txt needs more content ($WORD_COUNT words, need 30+)" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
