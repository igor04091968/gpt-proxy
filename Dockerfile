FROM node:20
COPY cf_ddns.sh /app/cf_ddns.sh
RUN chmod +x /app/cf_ddns.sh && apt-get update && apt-get install -y jq curl
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000

CMD [ "npm", "start" ]

