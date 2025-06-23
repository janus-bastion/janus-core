FROM debian:12

LABEL maintainer="xeylou.pro@gmail.com"
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
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd \
 && echo 'PermitRootLogin no'        >> /etc/ssh/sshd_config \
 && echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config \
 && echo 'ForceCommand /opt/janus/scripts/janus.sh' >> /etc/ssh/sshd_config \
 && adduser --disabled-password --gecos '' janus \
 && mkdir -p /home/janus/.ssh \
 && chown -R janus:janus /home/janus/.ssh

COPY authorized_keys /home/janus/.ssh/authorized_keys
RUN chmod 600 /home/janus/.ssh/authorized_keys \
 && chown -R janus:janus /home/janus/.ssh

EXPOSE 22

WORKDIR /opt/janus
COPY scripts/ ./scripts/
COPY config/ ./config/
RUN chmod +x scripts/*.sh

# CMD ["./scripts/janus.sh"]

CMD service ssh start && exec ./scripts/janus.sh
