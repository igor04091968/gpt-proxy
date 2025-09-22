#!/bin/sh
    2 
    3 # Устанавливаем права на файл cron
    4 chmod 0644 /etc/cron.d/my-cron
    5 
    6 # Применяем crontab
    7 crontab /etc/cron.d/my-cron
    8 
    9 # Создаем лог-файл и даем права
   10 touch /var/log/cron.log
   11 chmod 0666 /var/log/cron.log
   12 
   13 # Запускаем cron в фоновом режиме
   14 cron
   15 
   16 # Запускаем основное приложение в основном потоке.
   17 # 'exec' передает управление процессу npm, что является 
      лучшей практикой.
   18 echo "Starting Node.js application..."
   19 exec npm start
   
