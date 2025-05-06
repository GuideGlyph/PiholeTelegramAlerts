#!/bin/bash

# Configuration
TELEGRAM_TOKEN=${TELEGRAM_TOKEN}
CHAT_ID=${CHAT_ID}
TOPIC_ID=${TOPIC_ID:-}  # Optional topic ID
FILTER_FILE=${FILTER_FILE:-"/config/filter_domains.txt"}
LOG_FILE=${LOG_FILE:-"/logs/pihole.log"}

# Spam prevention cache
declare -A sent_cache

# Telegram alert function
send_alert() {
    local domain="$1"
    local user="$2"
    
    local message="🚨 Blocked domain accessed: $domain by user $user"
    local post_data="chat_id=$CHAT_ID&text=$message"
    
    # Add message_thread_id if topic ID is set
    if [ -n "$TOPIC_ID" ]; then
        post_data+="&message_thread_id=$TOPIC_ID"
    fi

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d "$post_data" >/dev/null

    # Log to file
    echo "$(date -u) $message" | tee -a /app/alerts.log
}

# Main loop
tail -Fn0 "$LOG_FILE" | while read -r line; do
    if echo "$line" | grep -q "from"; then
        domain=$(echo "$line" | awk -F ' ' '{print $6}' | sed 's/\/$//')

        if grep -qFx "$domain" "$FILTER_FILE"; then
            if [[ -z "${sent_cache[$domain]}" ]]; then
                user=$(echo "$line" | awk -F ' ' '{print $8}')
                send_alert "$domain" "$user"
                sent_cache["$domain"]=1
                (sleep 3600 && unset sent_cache["$domain"]) &
            fi
        fi
    fi
done