---
summary: "在無根 Podman 容器中執行 OpenClaw"
read_when:
  - 你想使用 Podman 而非 Docker 的容器化 gateway
title: "Podman（Podman）"
---

# Podman

在**無根** Podman 容器中執行 OpenClaw gateway。使用與 Docker 相同的鏡像（從倉庫 [Dockerfile](https://github.com/openclaw/openclaw/blob/main/Dockerfile) 建置）。

## 需求

- Podman（無根）
- Sudo 用於一次性設定（建立使用者、建置鏡像）

## 快速開始

**1. 一次性設定**（從倉庫根目錄執行；建立使用者、建置鏡像、安裝啟動指令碼）：

```bash
./setup-podman.sh
```

這也會建立一個最小化的 `~openclaw/.openclaw/openclaw.json`（設定 `gateway.mode="local"`），使 gateway 能在不執行精靈的情況下啟動。

預設情況下容器**不會**安裝為 systemd 服務，你手動啟動它（見下文）。如果要進行生產式設定以支援自動啟動和重新啟動，改將其安裝為 systemd Quadlet 使用者服務：

```bash
./setup-podman.sh --quadlet
```

（或設定 `OPENCLAW_PODMAN_QUADLET=1`；使用 `--container` 僅安裝容器和啟動指令碼。）

**2. 啟動 gateway**（手動，用於快速煙霧測試）：

```bash
./scripts/run-openclaw-podman.sh launch
```

**3. 上線精靈**（例如新增頻道或提供者）：

```bash
./scripts/run-openclaw-podman.sh launch setup
```

然後開啟 `http://127.0.0.1:18789/` 並使用來自 `~openclaw/.openclaw/.env` 的令牌（或由 setup 列印的值）。

## Systemd（Quadlet，選用）

如果你執行了 `./setup-podman.sh --quadlet`（或 `OPENCLAW_PODMAN_QUADLET=1`），一個 [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) 單位會被安裝，使 gateway 以 systemd 使用者服務的形式為 openclaw 使用者執行。該服務在設定結束時被啟用並啟動。

- **啟動：** `sudo systemctl --machine openclaw@ --user start openclaw.service`
- **停止：** `sudo systemctl --machine openclaw@ --user stop openclaw.service`
- **狀態：** `sudo systemctl --machine openclaw@ --user status openclaw.service`
- **日誌：** `sudo journalctl --machine openclaw@ --user -u openclaw.service -f`

Quadlet 檔案位於 `~openclaw/.config/containers/systemd/openclaw.container`。要更改埠或環境變數，編輯該檔案（或它源自的 `.env`），然後執行 `sudo systemctl --machine openclaw@ --user daemon-reload` 並重新啟動服務。開機時，如果為 openclaw 啟用了 lingering，該服務會自動啟動（當 loginctl 可用時設定會執行此操作）。

若要在初始設定後新增 Quadlet（該設定未使用它），重新執行：`./setup-podman.sh --quadlet`。

## openclaw 使用者（非登入）

`setup-podman.sh` 建立一個專用的系統使用者 `openclaw`：

- **Shell：** `nologin` — 沒有互動式登入；減少攻擊面。
- **主目錄：** 例如 `/home/openclaw` — 存放 `~/.openclaw`（配置、工作區）和啟動指令碼 `run-openclaw-podman.sh`。
- **無根 Podman：** 使用者必須有一個 **subuid** 和 **subgid** 範圍。許多發行版在建立使用者時會自動分配這些。如果設定列印了警告，將行新增到 `/etc/subuid` 和 `/etc/subgid`：

  ```text
  openclaw:100000:65536
  ```

  然後以該使用者身份啟動 gateway（例如來自 cron 或 systemd）：

  ```bash
  sudo -u openclaw /home/openclaw/run-openclaw-podman.sh
  sudo -u openclaw /home/openclaw/run-openclaw-podman.sh setup
  ```

- **配置：** 只有 `openclaw` 和 root 可以訪問 `/home/openclaw/.openclaw`。要編輯配置：在 gateway 執行後使用控制 UI，或 `sudo -u openclaw $EDITOR /home/openclaw/.openclaw/openclaw.json`。

## 環境和配置

- **令牌：** 儲存在 `~openclaw/.openclaw/.env` 中，作為 `OPENCLAW_GATEWAY_TOKEN`。`setup-podman.sh` 和 `run-openclaw-podman.sh` 如果缺失會生成它（使用 `openssl`、`python3` 或 `od`）。
- **選用：** 在該 `.env` 中你可以設定提供者金鑰（例如 `GROQ_API_KEY`、`OLLAMA_API_KEY`）和其他 OpenClaw 環境變數。
- **主機埠：** 預設情況下指令碼映射 `18789`（gateway）和 `18790`（bridge）。使用 `OPENCLAW_PODMAN_GATEWAY_HOST_PORT` 和 `OPENCLAW_PODMAN_BRIDGE_HOST_PORT` 覆寫**主機**埠映射。
- **Gateway 繫結：** 預設情況下，`run-openclaw-podman.sh` 使用 `--bind loopback` 啟動 gateway 以實現安全的本機訪問。要在 LAN 上公開，設定 `OPENCLAW_GATEWAY_BIND=lan` 並配置 `gateway.controlUi.allowedOrigins`（或明確啟用主機標頭回退）在 `openclaw.json`。
- **路徑：** 主機配置和工作區預設為 `~openclaw/.openclaw` 和 `~openclaw/.openclaw/workspace`。使用 `OPENCLAW_CONFIG_DIR` 和 `OPENCLAW_WORKSPACE_DIR` 覆寫啟動指令碼使用的主機路徑。

## 有用的命令

- **日誌：** 使用 Quadlet：`sudo journalctl --machine openclaw@ --user -u openclaw.service -f`。使用指令碼：`sudo -u openclaw podman logs -f openclaw`
- **停止：** 使用 Quadlet：`sudo systemctl --machine openclaw@ --user stop openclaw.service`。使用指令碼：`sudo -u openclaw podman stop openclaw`
- **再次啟動：** 使用 Quadlet：`sudo systemctl --machine openclaw@ --user start openclaw.service`。使用指令碼：重新執行啟動指令碼或 `podman start openclaw`
- **移除容器：** `sudo -u openclaw podman rm -f openclaw` — 主機上的配置和工作區會被保留

## 故障排除

- **權限被拒絕 (EACCES) 配置或身分驗證設定檔：** 容器預設為 `--userns=keep-id` 並以執行指令碼的主機使用者的相同 uid/gid 執行。確保你的主機 `OPENCLAW_CONFIG_DIR` 和 `OPENCLAW_WORKSPACE_DIR` 由該使用者擁有。
- **Gateway 啟動被阻止（缺少 `gateway.mode=local`）：** 確保 `~openclaw/.openclaw/openclaw.json` 存在並設定 `gateway.mode="local"`。`setup-podman.sh` 如果缺失會建立此檔案。
- **無根 Podman 對使用者 openclaw 失敗：** 檢查 `/etc/subuid` 和 `/etc/subgid` 是否包含 `openclaw` 的一行（例如 `openclaw:100000:65536`）。如果缺失請新增並重新啟動。
- **容器名稱已在使用中：** 啟動指令碼使用 `podman run --replace`，所以當你再次啟動時現有容器會被替換。要手動清理：`podman rm -f openclaw`。
- **以 openclaw 身份執行時找不到指令碼：** 確保 `setup-podman.sh` 已執行，使 `run-openclaw-podman.sh` 被複製到 openclaw 的主目錄（例如 `/home/openclaw/run-openclaw-podman.sh`）。
- **Quadlet 服務找不到或啟動失敗：** 在編輯 `.container` 檔案後執行 `sudo systemctl --machine openclaw@ --user daemon-reload`。Quadlet 需要 cgroups v2：`podman info --format '{{.Host.CgroupsVersion}}'` 應顯示 `2`。

## 選用：以你自己的使用者身份執行

要以你的普通使用者身份執行 gateway（無專用的 openclaw 使用者）：建置鏡像，建立 `~/.openclaw/.env` 並含有 `OPENCLAW_GATEWAY_TOKEN`，以及使用 `--userns=keep-id` 和掛載到你的 `~/.openclaw` 執行容器。啟動指令碼是為 openclaw 使用者工作流程設計的；對於單使用者設定，你可改為手動執行指令碼中的 `podman run` 命令，指向配置和工作區到你的主目錄。推薦給大多數使用者：使用 `setup-podman.sh` 並以 openclaw 使用者身份執行，使配置和程序被隔離。
