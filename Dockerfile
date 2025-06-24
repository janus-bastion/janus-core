FROM debian:12

LABEL maintainer="Janus Team <imtjanus@gmail.com>"
LABEL project="janus-core"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash curl dialog iputils-ping netcat-openbsd \
    openssh-client openssh-server \
    mariadb-client php-cli uuid-runtime \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd \
 && echo 'PermitRootLogin no'                              >> /etc/ssh/sshd_config \
 && echo 'AllowUsers janusadmin'                          >> /etc/ssh/sshd_config \
 && echo 'ForceCommand /opt/janus/scripts/janus.sh'       >> /etc/ssh/sshd_config

RUN adduser --disabled-password --gecos '' janusadmin \
 && mkdir -p /home/janusadmin/.ssh \
 && chown -R janusadmin:janusadmin /home/janusadmin/.ssh

COPY authorized_keys /home/janusadmin/.ssh/authorized_keys
RUN chmod 600 /home/janusadmin/.ssh/authorized_keys \
 && chown -R janusadmin:janusadmin /home/janusadmin/.ssh

CMD ["bash","-c","/usr/sbin/sshd -D & exec /opt/janus/scripts/janus.sh"]
