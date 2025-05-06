FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    grep \
    coreutils \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY alert.sh ./
RUN chmod +x alert.sh

# Create log file with write permissions
RUN mkdir -p /var/log/alerts
RUN touch /var/log/alerts/alerts.log && chmod 666 /var/log/alerts/alerts.log

CMD ["bash", "/app/alert.sh"]
