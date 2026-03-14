FROM eclipse-temurin:21-jre-jammy AS java

FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators

COPY --from=java /opt/java/openjdk /opt/java/openjdk

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
