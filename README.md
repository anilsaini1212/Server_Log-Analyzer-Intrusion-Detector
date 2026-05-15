# 🔍 Server Log Analyzer & Intrusion Detector

A bash script that scans your server logs, ranks errors by frequency, and detects SSH intrusion attempts — all in seconds.

Built as part of my [DevOps learning series on LinkedIn](https://www.linkedin.com/in/vigneshwari-k/).

## What it does

- Scans all system errors from the last N hours
- Detects SSH brute force attempts and ranks attacking IPs
- Shows usernames attackers tried
- Scans all log files and ranks errors by frequency
- Color coded terminal output

## Prerequisites

- Linux server (tested on Amazon Linux 2023)
- bash
- journalctl (comes with systemd)
- curl (for Telegram alerts)
  
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
##  Commands Explained

### journalctl
```
sudo journalctl
```
journalctl is the log viewer for systems using systemd. Unlike traditional Linux systems that store logs in /var/log/syslog or /var/log/auth.log,
Amazon Linux and most modern distros use journald which stores logs in a binary format.

journalctl reads those binary logs and displays them in a human readable format. Think of it as your server's complete diary — every event, every error, every login attempt.

---

### Filter by Priority

```
sudo journalctl -p err --since "24 hours ago"
```
-p err → show only error level and above
  Levels: debug, info, notice, warning, 
          err, crit, alert, emerg

--since "24 hours ago" → only show recent logs
  You can also use:
  --since "2026-05-14 09:00"
  --since yesterday
  --since today

---

### Find Intrusion Attempts
```
sudo journalctl | grep "Invalid user"
```
grep "Invalid user" → filters only lines where someone tried to log in with a username that doesn't exist on your server.
Every "Invalid user" line means a bot or attackertried to SSH into your server with a made up username like admin, root, ubuntu, jenkins etc.

---

### Rank Attackers by Frequency
```
sudo journalctl | grep "Invalid user" | awk '{print $8}'| sort | uniq -c | sort -rn
```
Breaking this down pipe by pipe:

grep "Invalid user"
→ filters only intrusion attempt lines

awk '{print $8}'
→ awk splits each line by spaces and prints 
  the 8th word — which is the username they tried

sort
→ sorts all usernames alphabetically so 
  identical ones are grouped together

uniq -c
→ counts how many times each username appears
  -c adds the count at the start of each line

sort -rn
→ sorts numerically in reverse order so highest count appears first
  -r means reverse, -n means numeric sort

Result: a ranked list of most attempted usernames

---

### Find Attacking IPs
```
sudo journalctl \
  | grep -iE "invalid user|failed password" \
  | awk '{print $(NF-3)}' \
  | grep -E "^[0-9]+\." \
  | sort | uniq -c \
  | sort -rn | head -10
```
grep -iE "invalid user|failed password"
→ -i means case insensitive
→ -E means extended regex so you can use | for OR
→ catches both types of attack attempts

awk '{print $(NF-3)}'
→ NF means "number of fields" (total columns)
→ NF-3 means 3rd from the last column
→ that's where the IP address sits in the log line

grep -E "^[0-9]+\."
→ filters only lines that look like IP addresses
→ removes any non-IP output that slipped through

---

### Find Errors in Log Files
```
find /var/log -name "*.log" -mmin -1440
```
find → searches for files
/var/log → starting directory
-name "*.log" → only files ending in .log
-mmin -1440 → modified in last 1440 minutes (24h)

grep -iE "error|fatal|failed"
→ looks for any of these keywords
→ case insensitive so catches ERROR, Error, error

sort | uniq -c | sort -rn
→ same ranking trick as above
→ most frequent errors appear first

---

## ⏰ Automate with Cron

Run every morning at 8am:
crontab -e

Add this line:
0 8 * * * /path/to/log-analyzer.sh 24

---


## 🔒 Security Note

This script helped me discover my EC2 instance 
was being attacked within hours of launch.

86 attempts from a single IP.
Usernames tried: admin, devops, jenkins, 
                 ubuntu, mysql, minecraft 😭

Always monitor your logs. The bots never sleep.

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

I document everything I learn in DevOps - one concept a day.
Follow along on [LinkedIn](https://www.linkedin.com/in/vigneshwari-k/) for daily posts.


