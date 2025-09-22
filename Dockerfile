FROM node:20

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000

CMD [ "npm", "start" ]
COPY cf_ddns.sh /app/cf_ddns.sh
RUN chmod +x /app/cf_ddns.sh && apt-get update && apt-get install -y jq curl
