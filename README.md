# 🔍 Server Log Analyzer & Intrusion Detector

A bash script that scans your server logs, ranks errors by frequency, and detects SSH intrusion attempts — all in seconds.

Built as part of my [DevOps learning series on LinkedIn](https://www.linkedin.com/in/vigneshwari-k/).

## What it does

- Scans all system errors from the last N hours
- Detects SSH brute force attempts and ranks attacking IPs
- Shows usernames attackers tried
- Scans all log files and ranks errors by frequency
- Color coded terminal output

## Quick Start

```bash
git clone https://github.com/yourhandle/log-analyzer
cd log-analyzer
chmod +x log-analyzer.sh

# Scan last 24 hours (default)
bash log-analyzer.sh

# Scan last 1 hour
bash log-analyzer.sh 1
```

## Sample Output

```
=================================================
   🔍 Server Security & Log Analyzer
   Scanning last 24 hours
=================================================

📋 SYSTEM ERRORS
-------------------------------------------------
  [2 hits] sshd: error: kex_exchange_identification
  [1 hit]  kernel: RETBleed: WARNING: Spectre v2

🚨 SSH INTRUSION ATTEMPTS
-------------------------------------------------
  Total attempts: 100

  Top attacking IPs:
  [86 attempts] 47.253.49.176 ⚠️
  [12 attempts] 106.53.61.219 ⚠️

  Usernames they tried:
  ✗ admin    (6 attempts)
  ✗ devops   (4 attempts)
  ✗ jenkins  (3 attempts)
  ✗ ubuntu   (5 attempts)
  ✗ mysql    (4 attempts)

📁 LOG FILE ERRORS (Last 24h)
-------------------------------------------------
  [1 error] dnf.log
    ↳ [1 hit] ERROR Operation aborted.
=================================================
✅ Scan Complete
```

## Tested On

- Amazon Linux 2023
- Ubuntu 22.04
- CentOS 8

## Part of my DevOps series

I document everything I learn in DevOps — one concept a day.
Follow along on [LinkedIn](https://www.linkedin.com/in/vigneshwari-k/) for daily posts.


