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

echo -e "${CYAN}"
echo "================================================="
echo "   🔍 Server Security & Log Analyzer"
echo "   Scanning last ${HOURS} hours"
echo "=================================================${NC}"
echo ""

# ── SECTION 1: SYSTEM ERRORS ──────────────────────
echo -e "${YELLOW}📋 SYSTEM ERRORS${NC}"
echo "-------------------------------------------------"
sudo journalctl -p err --since "${HOURS} hours ago" \
  | awk '{$1=$2=$3=$4=""; print}' \
  | sort | uniq -c \
  | sort -rn \
  | head -5 \
  | while read count msg; do
      echo -e "  ${RED}[$count hits]${NC} $msg"
    done
echo ""

# ── SECTION 2: INTRUSION ATTEMPTS ─────────────────
echo -e "${YELLOW}🚨 SSH INTRUSION ATTEMPTS${NC}"
echo "-------------------------------------------------"

TOTAL=$(sudo journalctl \
  | grep -cE "Invalid user|Failed password" 2>/dev/null)

echo -e "  Total attempts: ${RED}$TOTAL${NC}"
echo ""

echo -e "  ${CYAN}Top attacking IPs:${NC}"
sudo journalctl \
  | grep -iE "invalid user|failed password" \
  | awk '{print $(NF-3)}' \
  | grep -E "^[0-9]+\." \
  | sort | uniq -c \
  | sort -rn \
  | head -5 \
  | while read count ip; do
      if [ "$count" -gt "$THRESHOLD" ]; then
        echo -e "  ${RED}[$count attempts]${NC} $ip ⚠️"
      else
        echo -e "  ${YELLOW}[$count attempts]${NC} $ip"
      fi
    done
echo ""

echo -e "  ${CYAN}Usernames they tried:${NC}"
sudo journalctl \
  | grep "Invalid user" \
  | awk '{print $8}' \
  | sort | uniq -c \
  | sort -rn \
  | head -10 \
  | while read count user; do
      echo -e "  ${RED}✗${NC} $user ($count attempts)"
    done
echo ""

# ── SECTION 3: LOG FILE ERRORS ────────────────────
echo -e "${YELLOW}📁 LOG FILE ERRORS (Last ${HOURS}h)${NC}"
echo "-------------------------------------------------"
find /var/log -name "*.log" -mmin -$((HOURS * 60)) \
  2>/dev/null | while read logfile; do
    COUNT=$(grep -ciE "error|fatal|failed" \
      "$logfile" 2>/dev/null)
    if [ "$COUNT" -gt 0 ]; then
      echo -e "  ${RED}[$COUNT errors]${NC} $(basename $logfile)"
      grep -iE "error|fatal|failed" "$logfile" \
        | awk '{$1=$2=""; print}' \
        | sort | uniq -c \
        | sort -rn \
        | head -3 \
        | while read count msg; do
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
