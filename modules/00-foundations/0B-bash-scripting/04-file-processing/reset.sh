#!/usr/bin/env bash
WORK_DIR="/tmp/devops-lab/0B-04"

echo "Resetting exercise 0B-04..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

cat > "$WORK_DIR/servers.csv" << 'EOF'
hostname,ip,role,status
web-01,10.0.1.10,frontend,active
web-02,10.0.1.11,frontend,active
db-01,10.0.2.10,database,active
db-02,10.0.2.11,database,maintenance
cache-01,10.0.3.10,cache,active
api-01,10.0.1.20,backend,active
api-02,10.0.1.21,backend,inactive
EOF

echo "Created: $WORK_DIR/servers.csv"
echo "Done. Work directory ready: $WORK_DIR"
