# Pi-hole Alert Monitoring Bot for Telegram

This bot monitors blocked domain requests in Pi-hole logs and sends instant alerts 
to Telegram (with Topics support) when matched domains from your filter list are detected.

**Key features:**
- Tracks domains from `config/filter_domains.txt`
- Supports Telegram Topics (threaded conversations)
- Handles large blocklists effectively
- Built-in spam protection (1 alert/hour per domain)
- Docker-ready configuration

Created after discovering suspicious domains in my Pi-hole logs and needing instant 
alerts about their blocked access attempts. Now sharing with the community!

## Compatibility
✔️ Works perfectly with blocklists from [hagezi/dns-blocklists](https://github.com/hagezi/dns-blocklists)  
*(Use Wildcard/Regex domains format)*

## 🔧 Customizable Parameters

Configure the bot behavior using environment variables. Here's the complete list of available settings:

| Variable | Required | Description | Default Value | Example |
|----------|----------|-------------|---------------|---------|
| `TELEGRAM_TOKEN` | Yes | Your Telegram Bot API token | - | `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11` |
| `CHAT_ID` | Yes | Target Telegram chat/channel ID | - | `-1001234567890` |
| `TOPIC_ID` | No | Message thread ID for Telegram Topics | Empty | `123` |
| `FILTER_FILE` | No | Path to domain filter list | `/config/filter_domains.txt` | `/custom/filters.txt` |
| `LOG_FILE` | No | Pi-hole log file location | `/logs/pihole.log` | `/var/log/pihole/pihole.log` |
| `ALERT_COOLDOWN` | No | Anti-spam interval in seconds<br>`0` = disable protection | `3600` (1 hour) | `300` = 5 minutes |
