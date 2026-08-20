# Schedule_Daily

研三学习、科研与教师资格证《综合素质》备考的每日计划及微信提醒自动化。

- 全部日期与定时任务以 `Asia/Shanghai` 为准。
- 每日计划保存在 `MMDD/`，如 `0820/`。
- 06:05 生成完整日计划并推送微信；各重要时段发送简短提醒。
- 日计划经微信 API 成功发送后，自动提交当天目录并推送至 GitHub。

## 主要文件

- `AGENTS.md`：提醒 AI 的工作规则。
- `研三每日规划与教资备考方案.md`：总体学习与备考规划。
- `scripts/daily-reminder.sh`：cron 触发的计划生成、微信发送与归档任务。
- `scripts/commit-daily-folder.sh`：提交并推送当日计划目录。

## 查看任务

```bash
crontab -l
tmux attach -t pi-bot
```
