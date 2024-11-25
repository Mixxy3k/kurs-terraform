FROM node:18

WORKDIR /app
#katalog roboczy
COPY package*.json ./
COPY server.js ./
#zależności
RUN npm install
#ekspozycja portu
EXPOSE 3000
#start aplikacji
CMD ["node", "server.js"]