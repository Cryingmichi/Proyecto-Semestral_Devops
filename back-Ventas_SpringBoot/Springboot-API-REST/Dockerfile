# Multistage
# Stage 1: se encargará de crear el .jar
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: ejecutar la api
FROM eclipse-temurin:21-jdk
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup appuser
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
RUN chown appuser:appgroup app.jar
USER appuser
EXPOSE 8081
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1
ENTRYPOINT ["java","-Dserver.port=8081","-jar","app.jar"]