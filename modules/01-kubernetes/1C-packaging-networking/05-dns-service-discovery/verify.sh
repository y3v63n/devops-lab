#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/1C-05"
PASS=0; FAIL=0

check() {
  local desc="$1" result="$2"
  if [[ "$result" == "pass" ]]; then echo "  ✓ $desc"; PASS=$((PASS+1))
  else echo "  ✗ $desc"; FAIL=$((FAIL+1)); fi
}

echo "Verifying: Exercise 1C-05 — DNS and Service Discovery"; echo ""

# Task 1: dns-resolution.txt exists and has DNS output
[[ -f "$WORK_DIR/dns-resolution.txt" ]] && r="pass" || r="fail"
check "dns-resolution.txt exists" "$r"

[[ -s "$WORK_DIR/dns-resolution.txt" ]] && r="pass" || r="fail"
check "dns-resolution.txt has content" "$r"

grep -qi "my-svc\|nslookup\|address\|server" "$WORK_DIR/dns-resolution.txt" 2>/dev/null && r="pass" || r="fail"
check "dns-resolution.txt contains DNS lookup output" "$r"

# Task 1: Service exists in cluster
kubectl get service my-svc &>/dev/null && r="pass" || r="fail"
check "my-svc service exists" "$r"

# Task 2: headless-dns.txt exists with content
[[ -f "$WORK_DIR/headless-dns.txt" ]] && r="pass" || r="fail"
check "headless-dns.txt exists" "$r"

[[ -s "$WORK_DIR/headless-dns.txt" ]] && r="pass" || r="fail"
check "headless-dns.txt has content" "$r"

# Task 2: Headless service exists
kubectl get service headless-svc &>/dev/null && r="pass" || r="fail"
check "headless-svc service exists" "$r"

# Verify headless service has no ClusterIP
CLUSTER_IP=$(kubectl get service headless-svc -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
[[ "$CLUSTER_IP" == "None" ]] && r="pass" || r="fail"
check "headless-svc has clusterIP: None" "$r"

# Task 2: StatefulSet exists
kubectl get statefulset stateful-app &>/dev/null && r="pass" || r="fail"
check "stateful-app StatefulSet exists" "$r"

# Task 3: coredns-config.txt exists
[[ -f "$WORK_DIR/coredns-config.txt" ]] && r="pass" || r="fail"
check "coredns-config.txt exists" "$r"

grep -q "cluster.local" "$WORK_DIR/coredns-config.txt" 2>/dev/null && r="pass" || r="fail"
check "coredns-config.txt contains cluster.local config" "$r"

# Task 4: dns-notes.txt exists with content
[[ -f "$WORK_DIR/dns-notes.txt" ]] && r="pass" || r="fail"
check "dns-notes.txt exists" "$r"

[[ -s "$WORK_DIR/dns-notes.txt" ]] && r="pass" || r="fail"
check "dns-notes.txt has content" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
