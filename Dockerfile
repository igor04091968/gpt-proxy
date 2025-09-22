FROM node:20 
# Устанавливаем рабочую директорию
WORKDIR /app
# Устанавливаем cron и делаем очистку
RUN apt-get update && apt-get install -y cron && apt-get
clean
# Копируем package.json и package-lock.json
COPY package*.json ./
# Устанавливаем зависимости Node.js
RUN npm install
# Копируем все остальные файлы проекта в /app
COPY . .
# --- Добавленные шаги для cron и ddns ---
# Копируем файл с расписанием cron
COPY my-cron /etc/cron.d/my-cron
# Копируем и делаем исполняемыми скрипты
COPY cf-ddns.sh /app/cf-ddns.sh
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/cf-ddns.sh
RUN chmod +x /app/entrypoint.sh
# --- Конец добавленных шагов ---
# Открываем порт
EXPOSE 3000
# Устанавливаем точку входа
ENTRYPOINT ["/app/entrypoint.sh"]
# CMD теперь не нужен, так как 'npm start' вызывается из entrypoint.sh
# CMD [ "npm", "start" ]
   
