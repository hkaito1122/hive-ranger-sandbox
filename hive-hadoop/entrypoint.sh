#!/bin/bash
set -e

# ==========================================================
# 📦 Injecting missing Jackson JARs for Ranger
# ==========================================================
# ※コンテナが起動した瞬間に、内部のHadoopフォルダからHiveフォルダへJARを避難させます
mkdir -p /opt/hive/lib
cp /opt/hadoop/share/hadoop/yarn/lib/jackson-jaxrs-*.jar /opt/hive/lib/ 2>/dev/null || true

# 1. Javaのパスを自動検出（ここから下はいつも通り）
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# 2. SSHサーバー起動（Hadoopの内部通信用）
service ssh start

# 3. SSHの初回接続確認（yes/no）を自動スキップする設定
mkdir -p ~/.ssh
echo "StrictHostKeyChecking no" >> ~/.ssh/config

# 4. Hadoop環境変数へJavaパスを注入
echo "export JAVA_HOME=$JAVA_HOME" >> /opt/hadoop/etc/hadoop/hadoop-env.sh
echo "export HADOOP_HOME=/opt/hadoop" >> /opt/hadoop/etc/hadoop/hadoop-env.sh

# 5. rootユーザーでのHadoopコンポーネント起動を明示的に許可
export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export HDFS_RESOURCEMANAGER_USER=root

# 6. NameNodeの初期化（未初期化の場合のみ実行）
if [ ! -d "/tmp/hadoop-root/dfs/name" ]; then
    /opt/hadoop/bin/hdfs namenode -format
fi
/opt/hadoop/sbin/start-dfs.sh

# 7. HDFS上のHive用各種ディレクトリ作成と権限付与
/opt/hadoop/bin/hdfs dfs -mkdir -p /tmp
/opt/hadoop/bin/hdfs dfs -mkdir -p /user/hive/warehouse
/opt/hadoop/bin/hdfs dfs -chmod g+w /tmp
/opt/hadoop/bin/hdfs dfs -chmod g+w /user/hive/warehouse

# 8. パーミッション警告抑制のため、コンテナ内に hive ユーザーをダミー作成
id -u hive &>/dev/null || useradd -m -U hive || true

# 9. Ranger Hive Plugin の展開と有効化
cd /tmp
tar -xzf ranger-2.4.0-hive-plugin.tar.gz
cd ranger-2.4.0-hive-plugin
sed -i 's|POLICY_MGR_URL=.*|POLICY_MGR_URL=http://sandbox-ranger:6080|' install.properties
sed -i 's|REPOSITORY_NAME=.*|REPOSITORY_NAME=my_hive_repo|' install.properties
sed -i "s|COMPONENT_INSTALL_DIR_NAME=.*|COMPONENT_INSTALL_DIR_NAME=/opt/hive|" install.properties
./enable-hive-plugin.sh

# ─── 💡 ここを新規追記：Rangerプラグインが要求するクラス(Jackson)をHadoopからHiveへ横流しする ───
echo "Copying missing jackson-jaxrs jars for Ranger Plugin..."
cp /opt/hadoop/share/hadoop/yarn/lib/jackson-jaxrs-json-provider-*.jar /opt/hive/lib/ 2>/dev/null || true
cp /opt/hadoop/share/hadoop/yarn/lib/jackson-jaxrs-base-*.jar /opt/hive/lib/ 2>/dev/null || true

# 10. メタストアDB（PostgreSQL）の検証と初期スキーマ作成
/opt/hive/bin/schematool -validate -dbType postgres || /opt/hive/bin/schematool -dbType postgres -initSchema

# 11. 🚀 HiveServer2 をフォアグラウンドモードで起動
echo "=========================================================="
echo "🚀 Starting HiveServer2 in Foreground mode..."
echo "=========================================================="

if [ -f "/opt/hive/conf/hive-site.xml" ]; then
    sed -i 's/<value>tez<\/value>/<value>mr<\/value>/g' /opt/hive/conf/hive-site.xml
fi

export HIVE_ROOT_LOGGER=INFO,CONSOLE
/opt/hive/bin/hiveserver2