# Multistage
# Stage 1: se encargará de crear el .jar
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: ejecutar la api
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
EXPOSE 8081
# Forzamos a Spring Boot a escuchar en el puerto 8081 para evitar colisiones
ENTRYPOINT ["java","-Dserver.port=8081","-jar","app.jar"]