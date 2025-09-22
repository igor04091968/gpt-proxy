#!/bin/sh

# Устанавливаем права на файл cron
chmod 0644 /etc/cron.d/my-cron

# Применяем crontab
crontab /etc/cron.d/my-cron

# Запускаем cron в фоновом режиме
cron
# Start the DDNS update loop in the background
(
  while true; do
    echo "--- Running Cloudflare DDNS update ---"
    /app/cf-ddns.sh
    echo "--- DDNS update finished. Sleeping for 5 minutes. ---"
    sleep 300
  done
) &
# Запускаем основное приложение в основном потоке.
echo "Starting Node.js application..."
exec npm start
