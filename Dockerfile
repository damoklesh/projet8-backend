# syntax=docker/dockerfile:1.7

# Build stage: Gradle compiles and packages the Spring Boot application.
FROM gradle:8.7-jdk21 AS build

WORKDIR /workspace

# Copy the wrapper and build descriptors first to improve layer caching.
COPY --chown=gradle:gradle gradlew gradlew.bat settings.gradle build.gradle ./
COPY --chown=gradle:gradle gradle ./gradle
RUN sed -i 's/\r$//' ./gradlew && chmod +x ./gradlew

RUN ./gradlew dependencies --no-daemon

COPY --chown=gradle:gradle src ./src
RUN ./gradlew clean test bootJar --no-daemon

# Runtime stage: no build tools and no root process in the final image.
FROM eclipse-temurin:21-jre-jammy AS runtime

RUN groupadd --system appgroup \
    && useradd --system --gid appgroup --home-dir /app --shell /usr/sbin/nologin appuser

WORKDIR /app

COPY --from=build --chown=appuser:appgroup /workspace/build/libs/*.jar /app/app.jar

USER appuser:appgroup

EXPOSE 8080

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
