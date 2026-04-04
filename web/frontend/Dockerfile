# Etapa 1: Build da SPA Dinâmica
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Etapa 2: Servidor Estático NGINX Leve (Tamanho ~5MB CPU)
FROM nginx:alpine

# Remove padroes
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
