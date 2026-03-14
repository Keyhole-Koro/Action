FROM eclipse-temurin:21-jre-jammy AS java

FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:stable

COPY --from=java /opt/java/openjdk /opt/java/openjdk

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
    && mkdir -p /usr/share/keyrings \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /usr/share/keyrings/google-cloud-cli.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/google-cloud-cli.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli-pubsub-emulator \
    && rm -rf /var/lib/apt/lists/*
