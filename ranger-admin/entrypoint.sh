#!/bin/bash
set -e

# ─── 💡 ここを追加（Javaの正しいパスを動的検出して上書き） ───
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

cd /opt/ranger-admin

# install.properties の接続先を PostgreSQL コンテナに向ける設定
sed -i 's/SQL_COMMAND_INVOKER=.*/SQL_COMMAND_INVOKER=postgres/' install.properties
sed -i 's/DB_FLAVOR=.*/DB_FLAVOR=POSTGRES/' install.properties
sed -i 's/db_host=.*/db_host=sandbox-db/' install.properties
sed -i 's/db_root_user=.*/db_root_user=postgres/' install.properties
sed -i 's/db_root_password=.*/db_root_password=rootpassword/' install.properties
sed -i 's/db_name=.*/db_name=ranger_db/' install.properties
sed -i 's/db_user=.*/db_user=rangeruser/' install.properties
sed -i 's/db_password=.*/db_password=rangerpassword/' install.properties

# ─── 💡 監査ログの設定をすべてOFFにする ───
sed -i 's/audit_store=.*/audit_store=none/' install.properties
sed -i 's/audit_solr_urls=.*/audit_solr_urls=/' install.properties
sed -i 's/is_audit_supported=.*/is_audit_supported=false/' install.properties
sed -i 's/XAAUDIT.SOLR.IS_ENABLED=.*/XAAUDIT.SOLR.IS_ENABLED=false/' install.properties

# JDBCドライバのセットアップ
mkdir -p lib/
cp /tmp/postgresql-*.jar lib/

# Rangerの初期化スクリプト実行
./setup.sh

# ─── 💡 ここを修正：生成された ews 配下の正規スクリプトを直接叩く ───
echo "[I] Starting Ranger Admin Web Service..."

START_SCRIPT="/opt/ranger-admin/ews/ranger-admin-services.sh"

if [ ! -f "$START_SCRIPT" ]; then
    echo "[E] Could not find $START_SCRIPT! Attempting alternative search..."
    START_SCRIPT=$(find /opt/ranger-admin -name "ranger-admin-services.sh" | head -n 1)
fi

echo "[I] Executing script: $START_SCRIPT"
chmod +x "$START_SCRIPT"
cd $(dirname "$START_SCRIPT")

# Webサービスをバックグラウンド起動
./$(basename "$START_SCRIPT") start

# コンテナ維持とログのリアルタイム出力
mkdir -p logs
touch logs/ranger-admin-admin-.log
tail -f logs/*.log /opt/ranger-admin/ews/logs/*.log 2>/dev/null || tail -f /dev/null