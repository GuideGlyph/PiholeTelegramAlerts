#!/bin/bash

# Configuration
TELEGRAM_TOKEN=${TELEGRAM_TOKEN}
CHAT_ID=${CHAT_ID}
TOPIC_ID=${TOPIC_ID:-} # optional
FILTER_FILE=${FILTER_FILE:-"/config/filter_domains.txt"}
LOG_FILE=${LOG_FILE:-"/logs/pihole.log"}
ALERT_LOG="/var/log/alerts/alerts.log"

# Logging functions
log_info() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [INFO] $1" | tee -a "$ALERT_LOG"
}

log_error() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [ERROR] $1" >&2 | tee -a "$ALERT_LOG"
}

# Validate configuration
validate_cooldown() {
    if ! [[ "$ALERT_COOLDOWN" =~ ^[0-9]+$ ]]; then
        log_error "Invalid ALERT_COOLDOWN value: '$ALERT_COOLDOWN'. Must be integer >= 0"
        exit 1
    fi
    
    if [ "$ALERT_COOLDOWN" -lt 0 ]; then
        log_error "ALERT_COOLDOWN cannot be negative. Current value: $ALERT_COOLDOWN"
        exit 1
    fi
}

# Validate required parameters
check_env() {
    log_info "Starting Pi-hole Alert Monitor"
    log_info "Initializing environment checks..."
    log_info "Alert cooldown set to: $ALERT_COOLDOWN seconds"

    local missing=()
    [ -z "$TELEGRAM_TOKEN" ] && missing+=("TELEGRAM_TOKEN")
    [ -z "$CHAT_ID" ] && missing+=("CHAT_ID")
    [ -z "$FILTER_FILE" ] && missing+=("FILTER_FILE")
    [ -z "$LOG_FILE" ] && missing+=("LOG_FILE")

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required environment variables:"
        printf ' - %s\n' "${missing[@]}" >&2
        exit 1
    fi

    # Check files existence
    [ ! -f "$FILTER_FILE" ] && log_error "Filter file $FILTER_FILE not found!" && exit 1
    [ ! -f "$LOG_FILE" ] && log_error "Log file $LOG_FILE not found!" && exit 1

    # Check filter file content
    local filter_lines=$(wc -l < "$FILTER_FILE")
    if [ "$filter_lines" -eq 0 ]; then
        log_error "Filter file $FILTER_FILE is empty!"
        exit 1
    fi
    log_info "Loaded filter file with $filter_lines domains"

    # Check write permissions for alert log
    touch "$ALERT_LOG" || {
        log_error "Cannot write to alert log file: $ALERT_LOG"
        exit 1
    }
}

# Initial environment check
check_env
validate_cooldown

# Spam prevention cache
declare -A sent_cache
log_info "Spam protection cache initialized"

# Telegram alert function
send_alert() {
    local domain="$1"
    local user="$2"

    local message="🚨 Blocked domain accessed: $domain by user $user"
    local post_data="chat_id=$CHAT_ID&text=$message"

    if [ -n "$TOPIC_ID" ]; then
        post_data+="&message_thread_id=$TOPIC_ID"
    fi

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d "$post_data" >/dev/null

    echo "$(date -u) $message" | tee -a "$ALERT_LOG"
}

# Main loop
main() {
    log_info "Starting log monitoring from: $LOG_FILE"
    log_info "Using Telegram chat ID: $CHAT_ID$([ -n "$TOPIC_ID" ] && echo ", topic ID: $TOPIC_ID")"

    tail -Fn0 "$LOG_FILE" | while read -r line; do
        if echo "$line" | grep -q "from"; then
            domain=$(echo "$line" | awk -F ' ' '{print $6}' | sed 's/\/$//')

            if grep -qFx "$domain" "$FILTER_FILE"; then
                if [ "$ALERT_COOLDOWN" -eq 0 ] || [[ -z "${sent_cache[$domain]}" ]]; then
                    user=$(echo "$line" | awk -F ' ' '{print $8}')
                    log_info "Detected blocked domain: $domain (user: $user)"
                    send_alert "$domain" "$user"
                    
                    if [ "$ALERT_COOLDOWN" -gt 0 ]; then
                        sent_cache["$domain"]=1
                        (sleep "$ALERT_COOLDOWN" && unset sent_cache["$domain"]) &
                    fi
                fi
            fi
        fi
    done
}

# Start main process
main
