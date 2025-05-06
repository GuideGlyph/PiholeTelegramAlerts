FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    grep \
    awk \
    coreutils \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY alert.sh ./
RUN chmod +x alert.sh

# Create log file with write permissions
RUN touch /app/alerts.log && chmod 666 /app/alerts.log

CMD ["bash", "/app/alert.sh"]
