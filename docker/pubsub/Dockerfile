FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:stable

RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*
