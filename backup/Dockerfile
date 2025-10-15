# backup/Dockerfile
FROM alpine:latest

# install dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    unzip \
    tzdata \
    ca-certificates \
    busybox-suid \
    postgresql-client \
    && mkdir -p /opt/backup/scripts /backups

# install rclone
RUN curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip \
    && unzip /tmp/rclone.zip -d /tmp \
    && cp /tmp/rclone-*-linux-amd64/rclone /usr/bin/rclone \
    && chmod 755 /usr/bin/rclone \
    && rm -rf /tmp/rclone*

COPY scripts /opt/backup/scripts
RUN chmod +x /opt/backup/scripts/backup.sh

# Start cron in foreground
CMD ["sh", "-c", "/opt/backup/scripts/backup.sh && crond -f -L /dev/stdout"]

