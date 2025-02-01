FROM alpine:latest

RUN apk add --no-cache openssl bash certbot python3 py3-pip

COPY scripts /scripts
COPY config /config

WORKDIR /workspace

# Make scripts executable
RUN chmod +x /scripts/*.sh

# keep the container running
CMD ["tail", "-f", "/dev/null"]
