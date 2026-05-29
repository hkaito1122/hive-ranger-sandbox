FROM ubuntu:22.04

# 必要最低限のツールとJavaのインストール
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    ssh \
    pdsh \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin

# 1. 資材のコピーと展開（ホスト側の同フォルダに置いておく）
COPY hadoop-3.3.6.tar.gz /tmp/
COPY apache-hive-3.1.3-bin.tar.gz /tmp/
COPY postgresql-42.7.2.jar /tmp/
COPY ranger-2.4.0-hive-plugin.tar.gz /tmp/

RUN tar -xvf /tmp/hadoop-3.3.6.tar.gz -C /opt/ && mv /opt/hadoop-3.3.6 $HADOOP_HOME && \
    tar -xvf /tmp/apache-hive-3.1.3-bin.tar.gz -C /opt/ && mv /opt/apache-hive-3.1.3-bin $HIVE_HOME && \
    cp /tmp/postgresql-42.7.2.jar $HIVE_HOME/lib/

# SSHの設定（Hadoopの疑似分散モード起動に必要）
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# (他の記述の下に追記)
COPY hive-site.xml /opt/hive/conf/hive-site.xml

# 起動スクリプトの配置
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 10000 9870
ENTRYPOINT ["/entrypoint.sh"]