#!/bin/sh
# ─────────────────────────────────────────────────────────────
#  Keycloak PostgreSQL 自動備份腳本
# ─────────────────────────────────────────────────────────────
set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/backup"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"
FILENAME="${BACKUP_DIR}/keycloak_${TIMESTAMP}.sql.gz"

echo "${LOG_PREFIX} ⏳ 開始備份資料庫: ${POSTGRES_DB}"

# 執行備份
pg_dump \
  -h "${POSTGRES_HOST}" \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  --no-owner \
  --no-acl \
  --clean \
  --if-exists \
  | gzip > "${FILENAME}"

SIZE=$(du -sh "${FILENAME}" | cut -f1)
echo "${LOG_PREFIX} ✅ 備份完成: $(basename ${FILENAME}) (${SIZE})"

# ─── 清除過期備份 ─────────────────────────────────────────────
RETENTION=${BACKUP_RETENTION_DAYS:-7}
echo "${LOG_PREFIX} 🧹 清除 ${RETENTION} 天前的備份..."

find "${BACKUP_DIR}" -name "keycloak_*.sql.gz" -mtime +${RETENTION} | while read old_file; do
  echo "${LOG_PREFIX}    刪除: $(basename ${old_file})"
  rm -f "${old_file}"
done

# ─── 列出現有備份 ─────────────────────────────────────────────
COUNT=$(find "${BACKUP_DIR}" -name "keycloak_*.sql.gz" | wc -l)
echo "${LOG_PREFIX} 📦 目前共 ${COUNT} 個備份檔案:"
find "${BACKUP_DIR}" -name "keycloak_*.sql.gz" -printf "  %f (%s bytes)\n" 2>/dev/null || \
  ls -lh "${BACKUP_DIR}"/keycloak_*.sql.gz 2>/dev/null | awk '{print "  "$NF" ("$5")"}'

echo "${LOG_PREFIX} ✔  備份流程結束"