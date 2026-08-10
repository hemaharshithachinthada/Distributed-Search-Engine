FROM eclipse-temurin:17-jdk-jammy AS build

WORKDIR /workspace

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw \
    && ./mvnw --batch-mode --no-transfer-progress -DskipTests dependency:go-offline

COPY src/ src/
RUN ./mvnw --batch-mode --no-transfer-progress -DskipTests package \
    && cp target/distributed-search-engine-*.jar /workspace/search-engine.jar

FROM eclipse-temurin:17-jre-jammy AS runtime

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 searchengine \
    && useradd --uid 10001 --gid searchengine --create-home --shell /usr/sbin/nologin searchengine \
    && mkdir --parents /var/lib/search-engine \
    && chown searchengine:searchengine /var/lib/search-engine

WORKDIR /app
COPY --from=build --chown=searchengine:searchengine /workspace/search-engine.jar ./search-engine.jar

USER searchengine
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/search-engine.jar"]
