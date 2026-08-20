#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="/home/zxxxin/Schedule_Daily2026"
SCRIPT="$PROJECT_DIR/scripts/daily-reminder.sh"
LOG="$PROJECT_DIR/.automation-logs/cron.log"
mkdir -p "$PROJECT_DIR/.automation-logs"
chmod 750 "$SCRIPT"

block=$(cat <<EOF
# BEGIN Schedule_Daily2026 reminders (Asia/Shanghai)
CRON_TZ=Asia/Shanghai
5 6 * * * $SCRIPT plan >> $LOG 2>&1
15 6 * * * $SCRIPT reminder 0615 >> $LOG 2>&1
35 6 * * * $SCRIPT reminder 0635 >> $LOG 2>&1
30 8 * * * $SCRIPT reminder 0830 >> $LOG 2>&1
0 9 * * * $SCRIPT reminder 0900 >> $LOG 2>&1
30 11 * * * $SCRIPT reminder 1130 >> $LOG 2>&1
30 13 * * * $SCRIPT reminder 1330 >> $LOG 2>&1
30 17 * * * $SCRIPT reminder 1730 >> $LOG 2>&1
0 19 * * * $SCRIPT reminder 1900 >> $LOG 2>&1
0 21 * * * $SCRIPT reminder 2100 >> $LOG 2>&1
15 22 * * * $SCRIPT reminder 2215 >> $LOG 2>&1
# END Schedule_Daily2026 reminders
EOF
)

current="$(crontab -l 2>/dev/null || true)"
cleaned="$(printf '%s\n' "$current" | sed '/# BEGIN Schedule_Daily2026 reminders (Asia\/Shanghai)/,/# END Schedule_Daily2026 reminders/d')"
printf '%s\n%s\n' "$cleaned" "$block" | crontab -
echo 'Installed reminder cron entries:'
crontab -l | sed -n '/# BEGIN Schedule_Daily2026 reminders (Asia\/Shanghai)/,/# END Schedule_Daily2026 reminders/p'
