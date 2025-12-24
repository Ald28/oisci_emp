FROM node:18 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npx prisma generate

FROM node:18
WORKDIR /app
COPY --from=builder /app /app

EXPOSE 8000
CMD ["sh", "-c", "npx prisma migrate deploy && npx prisma db seed && node src/server.js"]