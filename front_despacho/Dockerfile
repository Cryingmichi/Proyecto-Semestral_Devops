# Multistage
# Stage 1: Compilación de la aplicación
FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Servidor web de producción
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /build/dist /usr/share/nginx/html
EXPOSE 80