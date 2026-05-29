FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    python3 \
    bc \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# ─── 💡 ここを追記（Rangerのチェックを騙すためのシンボリックリンク配置） ───
RUN mkdir -p /usr/share/java
COPY postgresql-42.7.2.jar /usr/share/java/mysql-connector-java.jar

ENV RANGER_HOME=/opt/ranger-admin

COPY ranger-2.4.0-admin.tar.gz /tmp/
COPY postgresql-42.7.2.jar /tmp/

RUN tar -xvf /tmp/ranger-2.4.0-admin.tar.gz -C /opt/ && \
    mv /opt/ranger-2.4.0-admin $RANGER_HOME

COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080
ENTRYPOINT ["/entrypoint.sh"]