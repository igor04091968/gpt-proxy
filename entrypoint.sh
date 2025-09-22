#!/bin/sh

# Устанавливаем права на файл cron
chmod 0644 /etc/cron.d/my-cron

# Применяем crontab
crontab /etc/cron.d/my-cron

# Запускаем cron в фоновом режиме
cron

# Запускаем основное приложение в основном потоке.
echo "Starting Node.js application..."
exec npm start