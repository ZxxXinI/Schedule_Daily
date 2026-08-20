#!/usr/bin/env bash
# 由 cron 触发：向唯一已连接微信的 pi-bot tmux 会话注入提醒任务。
# pi-wechat-assistant 限制一个微信用户只能连接一个 pi TUI 会话，因此不能为每次提醒新建会话。
set -Eeuo pipefail

PROJECT_DIR="/home/zxxxin/Schedule_Daily2026"
BOT_TARGET="pi-bot:0.0"
TZ_NAME="Asia/Shanghai"
export TZ="$TZ_NAME"

usage() { echo "Usage: $0 plan|reminder <label>" >&2; exit 64; }
kind="${1:-}"
label="${2:-}"
case "$kind" in
  plan) label="0605" ;;
  reminder) [[ -n "$label" ]] || usage ;;
  *) usage ;;
esac
case "$label" in
  0605|0615|0635|0830|0900|1130|1330|1730|1900|2100|2215) ;;
  *) echo "Unsupported reminder label: $label" >&2; exit 64 ;;
esac

mmdd="$(date +%m%d)"
ymd="$(date +%F)"
day_dir="$PROJECT_DIR/$mmdd"
marker="$day_dir/.sent-$label"
mkdir -p "$day_dir"

exec 9>"$day_dir/.reminder-$label.lock"
if ! flock -n 9; then
  printf '%s [%s] skipped: another run holds lock\n' "$(date '+%F %T %Z')" "$label" >> "$day_dir/执行日志.log"
  exit 0
fi
if [[ -e "$marker" ]]; then
  printf '%s [%s] skipped: already sent\n' "$(date '+%F %T %Z')" "$label" >> "$day_dir/执行日志.log"
  exit 0
fi
if ! tmux has-session -t pi-bot 2>/dev/null; then
  printf '%s [%s] failed: pi-bot tmux session is not running\n' "$(date '+%F %T %Z')" "$label" >> "$day_dir/执行日志.log"
  exit 1
fi

if [[ "$kind" == "plan" ]]; then
  prompt="【自动提醒：06:05 日计划】现在是中国时间 $ymd $(date '+%A %H:%M')。先完整读取 /home/zxxxin/Schedule_Daily2026/AGENTS.md、/home/zxxxin/Schedule_Daily2026/研三每日规划与教资备考方案.md；严格遵守其中规则。所有路径均使用 /home/zxxxin/Schedule_Daily2026/$mmdd/：创建或更新 每日安排.md、微信简要安排.txt、执行日志.log。计划文件写入成功后，在日志记录“已生成，等待脚本发送”。不要创建 .sent-0605；随后最终回复仅输出要发送给微信的简要日计划。"
else
  prompt="【自动提醒：$label】现在是中国时间 $ymd $(date '+%A %H:%M')。先完整读取 /home/zxxxin/Schedule_Daily2026/AGENTS.md，再读取 /home/zxxxin/Schedule_Daily2026/$mmdd/每日安排.md，严格遵守其中规则。按今天已更新的计划生成本时段的一条微信提醒，并将提醒原文写入 /home/zxxxin/Schedule_Daily2026/$mmdd/.wechat-$label.txt；在 /home/zxxxin/Schedule_Daily2026/$mmdd/执行日志.log 记录“已生成，等待脚本发送”。不要创建 .sent-$label。最终回复只能包含该条中文提醒。"
fi

# 注入 Pi 完成文件生成；微信扩展只会转发微信输入触发的回复，故发送由下方 API 脚本负责。
tmux send-keys -t "$BOT_TARGET" -l -- "$prompt"
tmux send-keys -t "$BOT_TARGET" Enter
printf '%s [%s] injected into %s\n' "$(date '+%F %T %Z')" "$label" "$BOT_TARGET" >> "$day_dir/执行日志.log"

if [[ "$kind" == "plan" ]]; then
  message_file="$day_dir/微信简要安排.txt"
else
  message_file="$day_dir/.wechat-$label.txt"
fi

# 等待 Pi 生成当天文件/提醒文案；最长 3 分钟，避免脚本无限阻塞。
for _ in $(seq 1 36); do
  [[ -s "$message_file" ]] && break
  sleep 5
done
if [[ ! -s "$message_file" ]]; then
  printf '%s [%s] failed: message file was not generated: %s\n' "$(date '+%F %T %Z')" "$label" "$message_file" >> "$day_dir/执行日志.log"
  exit 1
fi

if /home/zxxxin/.nvm/versions/node/v24.16.0/bin/node "$PROJECT_DIR/scripts/send-wechat-text.mjs" "$message_file"; then
  touch "$marker"
  printf '%s [%s] WeChat API delivery succeeded\n' "$(date '+%F %T %Z')" "$label" >> "$day_dir/执行日志.log"
  # 日计划发送成功后立即归档当天文件；后续提醒仍会继续更新工作区日志。
  if [[ "$label" == "0605" ]]; then
    "$PROJECT_DIR/scripts/commit-daily-folder.sh" >> "$PROJECT_DIR/.automation-logs/git-${ymd}.log" 2>&1 || \
      printf '%s [%s] git commit/push failed; see .automation-logs/git-%s.log\n' "$(date '+%F %T %Z')" "$label" "$ymd" >> "$day_dir/执行日志.log"
  fi
else
  printf '%s [%s] WeChat API delivery failed\n' "$(date '+%F %T %Z')" "$label" >> "$day_dir/执行日志.log"
  exit 1
fi
