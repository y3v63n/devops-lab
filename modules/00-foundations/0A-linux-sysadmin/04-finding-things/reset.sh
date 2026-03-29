#!/usr/bin/env bash
rm -rf /tmp/devops-lab/0A-04
mkdir -p /tmp/devops-lab/0A-04/logs
mkdir -p /tmp/devops-lab/0A-04/data

# Create app.log with ~20 lines including ERROR and WARN entries
cat > /tmp/devops-lab/0A-04/logs/app.log << 'EOF'
2024-01-15 08:00:01 INFO  APP001 Server starting on port 8080
2024-01-15 08:00:02 INFO  APP002 Loading configuration from /etc/app/config.yml
2024-01-15 08:00:03 INFO  APP003 Database connection pool initialized (size=10)
2024-01-15 08:00:05 INFO  APP004 Cache warmed: 1523 entries loaded
2024-01-15 08:01:12 WARN  APP005 Memory usage above 70%: 2.8GB/4GB
2024-01-15 08:03:44 ERROR APP006 Failed to connect to replica DB: connection timeout
2024-01-15 08:03:45 INFO  APP007 Retrying DB connection (attempt 1/3)
2024-01-15 08:03:50 INFO  APP008 Retrying DB connection (attempt 2/3)
2024-01-15 08:03:55 ERROR APP009 DB connection retry failed: host unreachable
2024-01-15 08:03:56 WARN  APP010 Falling back to primary DB only
2024-01-15 08:15:22 INFO  APP011 Processed 4821 requests (avg 12ms)
2024-01-15 08:30:01 ERROR APP012 Disk write failed: /var/app/cache — no space left
2024-01-15 08:30:02 WARN  APP013 Cache disabled due to disk error
2024-01-15 09:00:00 INFO  APP014 Hourly health check: degraded
2024-01-15 09:15:33 ERROR APP015 HTTP 500 spike: 42 errors in 60 seconds
2024-01-15 09:15:34 WARN  APP016 Rate limiting activated for upstream calls
2024-01-15 09:45:11 INFO  APP017 Error rate returning to normal
2024-01-15 10:00:00 INFO  APP018 Hourly health check: healthy
2024-01-15 10:30:00 INFO  APP019 Scheduled backup completed: 1.2GB
2024-01-15 11:00:00 INFO  APP020 Processed 18204 total requests today
EOF

# Create data files of varying sizes
echo "tiny" > /tmp/devops-lab/0A-04/data/small.txt
echo "also small" > /tmp/devops-lab/0A-04/data/tiny.csv

# Create larger files (>100 bytes)
cat > /tmp/devops-lab/0A-04/data/users.csv << 'EOF'
id,username,email,role,last_login
1,alice,alice@example.com,admin,2024-01-15
2,bob,bob@example.com,developer,2024-01-14
3,charlie,charlie@example.com,developer,2024-01-13
4,diana,diana@example.com,operator,2024-01-15
5,eve,eve@example.com,viewer,2024-01-10
EOF

cat > /tmp/devops-lab/0A-04/data/notes.txt << 'EOF'
System maintenance notes
========================
- Jan 15: Replica DB went down at 08:03, recovered by 08:15
- Jan 15: Disk space alert on /var/app/cache, cleaned up 4GB of old logs
- Jan 14: Deployed v2.4.1 with connection pool fix
- Jan 13: Increased memory limit from 3GB to 4GB
- Action items: Set up disk space monitoring alerts, investigate replica instability
EOF

echo "Exercise reset. Work directory: /tmp/devops-lab/0A-04"
echo "Created:"
echo "  logs/app.log  — 20-line log with ERROR, WARN, INFO entries"
echo "  data/small.txt, data/tiny.csv  — small files (<100 bytes)"
echo "  data/users.csv, data/notes.txt — larger files (>100 bytes)"
