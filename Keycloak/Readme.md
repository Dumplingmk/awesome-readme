# Keycloak Docker Compose + 自動備份

## 目錄結構

```
keycloak-docker/
├── docker-compose.yml      # 主設定檔
├── .env                    # 環境變數（請勿 commit）
├── restore.sh              # 手動還原腳本
└── backup/
    ├── scripts/
    │   └── backup.sh       # 備份腳本（由容器執行）
    ├── data/               # 備份檔案存放位置
    └── logs/               # 備份日誌
```

## 快速開始

### 1. 設定環境變數

編輯 `.env` 並修改所有密碼：

```bash
cp .env .env.local   # 可選：用 local 版本覆寫
nano .env
```

**必須修改的欄位：**
- `POSTGRES_PASSWORD` — 資料庫密碼
- `KEYCLOAK_ADMIN_PASSWORD` — Keycloak 管理員密碼
- `KC_HOSTNAME` — 你的 domain（正式環境）

### 2. 啟動服務

```bash
docker compose up -d
```

### 3. 查看狀態

```bash
docker compose ps
docker compose logs -f keycloak
```

Keycloak 管理介面：http://localhost:8080

---

## 備份說明

### 自動備份

備份服務會依照 `BACKUP_SCHEDULE` 設定自動執行。

預設：**每天凌晨 2 點**備份，保留最近 **7 天**。

```bash
# 查看備份日誌
docker compose logs backup
tail -f backup/logs/backup.log

# 列出備份檔案
ls -lh backup/data/
```

### 手動觸發備份

```bash
docker compose exec backup /scripts/backup.sh
```

### 還原備份

```bash
chmod +x restore.sh
./restore.sh keycloak_20240420_020000.sql.gz
```

---

## 常用指令

```bash
# 重啟 Keycloak
docker compose restart keycloak

# 查看所有 log
docker compose logs -f

# 停止所有服務
docker compose down

# 完整清除（含 volume）
docker compose down -v
```

## 正式環境建議

- 使用 Nginx / Traefik 作為 reverse proxy，並啟用 HTTPS
- 將 `backup/data/` 同步到 S3、GCS 或其他遠端儲存
- 設定 `KC_PROXY=edge`（已預設）並確保 hostname 正確

## 備份 Cron 格式參考

```
分 時 日 月 週
0 2 * * *    → 每天凌晨 2 點
0 */6 * * *  → 每 6 小時
0 1 * * 0    → 每週日凌晨 1 點
```