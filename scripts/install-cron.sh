#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="/home/zxxxin/Schedule_Daily2026"
SCRIPT="$PROJECT_DIR/scripts/daily-reminder.sh"
LOG="$PROJECT_DIR/.automation-logs/cron.log"
mkdir -p "$PROJECT_DIR/.automation-logs"
chmod 750 "$SCRIPT"

# 本机 cron 按 UTC 运行；以下时间为北京时间（Asia/Shanghai）减 8 小时。
# 不依赖 CRON_TZ，以兼容未实现该扩展的 cron。
block=$(cat <<EOF
# BEGIN Schedule_Daily2026 reminders (UTC host; times converted from Asia/Shanghai)
# Beijing 06:05/06:15/06:35 = UTC previous day 22:05/22:15/22:35
5 22 * * * $SCRIPT plan >> $LOG 2>&1
15 22 * * * $SCRIPT reminder 0615 >> $LOG 2>&1
35 22 * * * $SCRIPT reminder 0635 >> $LOG 2>&1
# Beijing 08:30/09:00/11:30/13:30/17:30/19:00/21:00/22:15 = UTC below
30 0 * * * $SCRIPT reminder 0830 >> $LOG 2>&1
0 1 * * * $SCRIPT reminder 0900 >> $LOG 2>&1
30 3 * * * $SCRIPT reminder 1130 >> $LOG 2>&1
30 5 * * * $SCRIPT reminder 1330 >> $LOG 2>&1
30 9 * * * $SCRIPT reminder 1730 >> $LOG 2>&1
0 11 * * * $SCRIPT reminder 1900 >> $LOG 2>&1
0 13 * * * $SCRIPT reminder 2100 >> $LOG 2>&1
15 14 * * * $SCRIPT reminder 2215 >> $LOG 2>&1
# END Schedule_Daily2026 reminders
EOF
)

current="$(crontab -l 2>/dev/null || true)"
cleaned="$(printf '%s\n' "$current" | sed '/# BEGIN Schedule_Daily2026 reminders/,/# END Schedule_Daily2026 reminders/d')"
printf '%s\n%s\n' "$cleaned" "$block" | crontab -
echo 'Installed UTC cron entries (converted from Asia/Shanghai):'
crontab -l | sed -n '/# BEGIN Schedule_Daily2026 reminders/,/# END Schedule_Daily2026 reminders/p'
