#!/usr/bin/env bash
# Commit and push the current China-time daily folder after WeChat API delivery succeeds.
set -Eeuo pipefail

PROJECT_DIR="/home/zxxxin/Schedule_Daily2026"
export TZ="Asia/Shanghai"
cd "$PROJECT_DIR"

mmdd="$(date +%m%d)"
day_dir="$mmdd"
log_file="$day_dir/执行日志.log"
[[ -d "$day_dir" ]] || { echo "Daily folder does not exist: $day_dir" >&2; exit 1; }

# Commit only real daily records, never transient lock/marker files.
git add -- "$day_dir/每日安排.md" "$day_dir/微信简要安排.txt" "$day_dir/执行日志.log"
if git diff --cached --quiet; then
  printf '%s [git] no daily content changes to commit\n' "$(date '+%F %T %Z')" >> "$log_file"
  exit 0
fi

git commit -m "docs: add ${mmdd} daily schedule"
git push origin main
printf '%s [git] committed and pushed %s\n' "$(date '+%F %T %Z')" "$mmdd" >> "$log_file"
