#!/bin/bash

# ================================================
# Log Error Analyzer + Intrusion Detector
# Author: Vigneshwari K
# GitHub: github.com/vigneshwari08/server-log-analyzer
# ================================================

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

HOURS=${1:-24}  # Default last 24 hours, pass argument to change
THRESHOLD=5     # Alert if attacks exceed this

if ! [[ "$HOURS" =~ ^[0-9]+$ ]] || [ "$HOURS" -eq 0 ]; then
  echo "Usage: bash log-analyzer.sh [hours]  (hours must be a positive integer)" >&2
  exit 1
fi
SINCE="${HOURS} hours ago"

# journald and most of /var/log are root-only: elevate once instead of per command
if [ "$EUID" -ne 0 ]; then
  exec sudo bash "$0" "$@"
fi

echo -e "${CYAN}"
echo "================================================="
echo "   🔍 Server Security & Log Analyzer"
echo "   Scanning last ${HOURS} hours"
echo "=================================================${NC}"
echo ""

# ── SECTION 1: SYSTEM ERRORS ──────────────────────
echo -e "${YELLOW}📋 SYSTEM ERRORS${NC}"
echo "-------------------------------------------------"
journalctl -p err --since "$SINCE" \
  | grep -v '^-- ' \
  | awk '{$1=$2=$3=$4=""; sub(/^ +/, ""); print}' \
  | sed -E 's/\[[0-9]+\]:/:/' \
  | sort | uniq -c \
  | sort -rn \
  | head -5 \
  | while read -r count msg; do
      echo -e "  ${RED}[$count hits]${NC} $msg"
    done
echo ""

# ── SECTION 2: INTRUSION ATTEMPTS ─────────────────
echo -e "${YELLOW}🚨 SSH INTRUSION ATTEMPTS${NC}"
echo "-------------------------------------------------"

# One journal read for the whole section. "Failed password for invalid user"
# repeats an attempt already logged as "Invalid user", so it is dropped.
SSH_LOG=$(journalctl --since "$SINCE" 2>/dev/null \
  | grep -E "Invalid user|Failed password" \
  | grep -v "Failed password for invalid user")

if [ -n "$SSH_LOG" ]; then
  TOTAL=$(printf '%s\n' "$SSH_LOG" | wc -l)
else
  TOTAL=0
fi

echo -e "  Total attempts: ${RED}$TOTAL${NC}"
echo ""

echo -e "  ${CYAN}Top attacking IPs:${NC}"
printf '%s\n' "$SSH_LOG" \
  | awk '{ ip = ""; for (i = 1; i < NF; i++) if ($i == "from") ip = $(i+1);
           if (ip ~ /^[0-9]+\.[0-9.]+$/ || ip ~ /:/) print ip }' \
  | sort | uniq -c \
  | sort -rn \
  | head -5 \
  | while read -r count ip; do
      if [ "$count" -gt "$THRESHOLD" ]; then
        echo -e "  ${RED}[$count attempts]${NC} $ip ⚠️"
      else
        echo -e "  ${YELLOW}[$count attempts]${NC} $ip"
      fi
    done
echo ""

echo -e "  ${CYAN}Usernames they tried:${NC}"
printf '%s\n' "$SSH_LOG" \
  | awk '{ for (i = 1; i < NF - 1; i++)
             if ($i == "Invalid" && $(i+1) == "user") {
               u = $(i+2); print (u == "from" ? "(empty)" : u); break } }' \
  | sort | uniq -c \
  | sort -rn \
  | head -10 \
  | while read -r count user; do
      echo -e "  ${RED}✗${NC} $user ($count attempts)"
    done
echo ""

# ── SECTION 3: LOG FILE ERRORS ────────────────────
echo -e "${YELLOW}📁 LOG FILE ERRORS (Last ${HOURS}h)${NC}"
echo "-------------------------------------------------"
find /var/log -type f -name "*.log" -mmin -$((HOURS * 60)) -print0 \
  2>/dev/null | while IFS= read -r -d '' logfile; do
    COUNT=$(grep -ciE "error|fatal|failed" \
      "$logfile" 2>/dev/null)
    if [ "${COUNT:-0}" -gt 0 ]; then
      echo -e "  ${RED}[$COUNT errors]${NC} $(basename "$logfile")"
      grep -iE "error|fatal|failed" "$logfile" \
        | awk '{$1=$2=""; print}' \
        | sort | uniq -c \
        | sort -rn \
        | head -3 \
        | while read -r count msg; do
            echo -e "    ${YELLOW}↳ [$count hits]${NC} $msg"
          done
    fi
  done
echo ""

# ── SECTION 4: QUICK SUMMARY ──────────────────────
echo -e "${CYAN}================================================="
echo -e "✅ Scan Complete"
echo -e "   Run with: bash log-analyzer.sh <hours>"
echo -e "   Example:  bash log-analyzer.sh 1"
echo -e "=================================================${NC}"
