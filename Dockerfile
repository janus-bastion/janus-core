FROM debian:12

LABEL maintainer="contact@error.systems"
LABEL project="janus-core"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    dialog \
    netcat-openbsd \
    iputils-ping \
    openssh-client \
    uuid-runtime \
    mariadb-client \
    php-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/janus
COPY scripts/ ./scripts/
COPY config/ ./config/

RUN chmod +x scripts/*.sh

CMD ["./scripts/janus.sh"]
