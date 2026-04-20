#!/bin/sh
# ─────────────────────────────────────────────────────────────
#  Keycloak PostgreSQL 還原腳本
#  用法: ./restore.sh [備份檔案名稱]
#  範例: ./restore.sh keycloak_20240420_020000.sql.gz
# ─────────────────────────────────────────────────────────────
set -e

BACKUP_DIR="./backup/data"

# ─── 選擇備份檔案 ─────────────────────────────────────────────
if [ -z "$1" ]; then
  echo "📦 可用備份檔案:"
  ls -lht "${BACKUP_DIR}"/keycloak_*.sql.gz 2>/dev/null | \
    awk '{print NR". "$NF" ("$5")"}' || echo "  （無備份檔案）"
  echo ""
  printf "請輸入要還原的檔案名稱: "
  read BACKUP_FILE
  BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
else
  BACKUP_PATH="${BACKUP_DIR}/$1"
fi

if [ ! -f "${BACKUP_PATH}" ]; then
  echo "❌ 找不到檔案: ${BACKUP_PATH}"
  exit 1
fi

# ─── 確認 ─────────────────────────────────────────────────────
echo ""
echo "⚠️  即將還原備份: $(basename ${BACKUP_PATH})"
echo "⚠️  這將覆蓋現有資料庫，操作無法復原！"
printf "確定要繼續嗎？ (yes/no): "
read CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
  echo "❌ 已取消還原"
  exit 0
fi

# ─── 載入環境變數 ─────────────────────────────────────────────
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo ""
echo "🔄 停止 Keycloak..."
docker compose stop keycloak

echo "📥 還原中..."
docker compose exec -T postgres sh -c \
  "PGPASSWORD=${POSTGRES_PASSWORD} gunzip -c | psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}" \
  < "${BACKUP_PATH}"

echo "🚀 重啟 Keycloak..."
docker compose start keycloak

echo ""
echo "✅ 還原完成！Keycloak 重啟中，請稍候約 60 秒..."