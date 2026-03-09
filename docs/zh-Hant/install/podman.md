---
summary: "在無根 Podman 容器中執行 OpenClaw"
read_when:
  - 您想使用 Podman 而非 Docker 的容器化 gateway 時
title: "Podman（無根容器部署）"
---

# Podman

在**無根** Podman 容器中執行 OpenClaw gateway。使用與 Docker 相同的映像（從倉庫 [Dockerfile](https://github.com/openclaw/openclaw/blob/main/Dockerfile) 建置）。

## 需求

- Podman（rootless）
- 一次性設定需要 Sudo（建立使用者、建置映像）

## 快速開始

**1. 一次性設定**（從倉庫根目錄執行；建立使用者、建置映像、安裝啟動腳本）：

```bash
./setup-podman.sh
```

這也會建立一個最小的 `~openclaw/.openclaw/openclaw.json`（設定 `gateway.mode="local"`），讓 gateway 無需執行精靈即可啟動。

預設情況下容器**未**安裝為 systemd 服務，您需要手動啟動它（見下文）。若要進行生產環境設定並支援自動啟動和重啟，改為將其安裝為 systemd Quadlet 使用者服務：

```bash
./setup-podman.sh --quadlet
```

（或設定 `OPENCLAW_PODMAN_QUADLET=1`；使用 `--container` 只安裝容器和啟動腳本。）

選填的建置時環境變數（在執行 `setup-podman.sh` 前設定）：

- `OPENCLAW_DOCKER_APT_PACKAGES` — 映像建置期間安裝額外的 apt 套件
- `OPENCLAW_EXTENSIONS` — 預先安裝擴充套件依賴項（以空格分隔的擴充套件名稱，例如 `diagnostics-otel matrix`）

**2. 啟動 gateway**（手動，用於快速煙霧測試）：

```bash
./scripts/run-openclaw-podman.sh launch
```

**3. 引導精靈**（例如新增頻道或提供者）：

```bash
./scripts/run-openclaw-podman.sh launch setup
```

然後開啟 `http://127.0.0.1:18789/` 並使用 `~openclaw/.openclaw/.env` 中的 token（或設定列印的值）。

## Systemd（Quadlet，選用）

若您執行了 `./setup-podman.sh --quadlet`（或 `OPENCLAW_PODMAN_QUADLET=1`），會安裝一個 [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) 單元，讓 gateway 作為 openclaw 使用者的 systemd 使用者服務執行。服務在設定結束時啟用並啟動。

- **啟動：** `sudo systemctl --machine openclaw@ --user start openclaw.service`
- **停止：** `sudo systemctl --machine openclaw@ --user stop openclaw.service`
- **狀態：** `sudo systemctl --machine openclaw@ --user status openclaw.service`
- **日誌：** `sudo journalctl --machine openclaw@ --user -u openclaw.service -f`

quadlet 檔案位於 `~openclaw/.config/containers/systemd/openclaw.container`。若要變更連接埠或環境變數，編輯該檔案（或它引用的 `.env`），然後執行 `sudo systemctl --machine openclaw@ --user daemon-reload` 並重啟服務。開機時，若 openclaw 的 lingering 已啟用，服務會自動啟動（設定在 loginctl 可用時執行此操作）。

若要在**未使用** quadlet 的初始設定後新增它，重新執行：`./setup-podman.sh --quadlet`。

## openclaw 使用者（非登入）

`setup-podman.sh` 建立一個專用系統使用者 `openclaw`：

- **Shell：** `nologin` — 無互動式登入；減少攻擊面。
- **主目錄：** 例如 `/home/openclaw` — 持有 `~/.openclaw`（設定、工作區）和啟動腳本 `run-openclaw-podman.sh`。
- **Rootless Podman：** 使用者必須有 **subuid** 和 **subgid** 範圍。許多發行版在建立使用者時自動分配這些。若設定列印警告，新增行到 `/etc/subuid` 和 `/etc/subgid`：

  ```text
  openclaw:100000:65536
  ```

  然後以該使用者啟動 gateway（例如從 cron 或 systemd）：

  ```bash
  sudo -u openclaw /home/openclaw/run-openclaw-podman.sh
  sudo -u openclaw /home/openclaw/run-openclaw-podman.sh setup
  ```

- **設定：** 只有 `openclaw` 和 root 可以存取 `/home/openclaw/.openclaw`。若要編輯設定：在 gateway 執行後使用 Control UI，或 `sudo -u openclaw $EDITOR /home/openclaw/.openclaw/openclaw.json`。

## 環境與設定

- **Token：** 儲存在 `~openclaw/.openclaw/.env` 中為 `OPENCLAW_GATEWAY_TOKEN`。若缺少，`setup-podman.sh` 和 `run-openclaw-podman.sh` 會生成它（使用 `openssl`、`python3` 或 `od`）。
- **選填：** 在 `.env` 中您可以設定提供者金鑰（例如 `GROQ_API_KEY`、`OLLAMA_API_KEY`）和其他 OpenClaw 環境變數。
- **主機連接埠：** 預設腳本映射 `18789`（gateway）和 `18790`（bridge）。啟動時使用 `OPENCLAW_PODMAN_GATEWAY_HOST_PORT` 和 `OPENCLAW_PODMAN_BRIDGE_HOST_PORT` 覆寫**主機**連接埠映射。
- **Gateway 綁定：** 預設情況下，`run-openclaw-podman.sh` 以 `--bind loopback` 啟動 gateway 以確保安全的本機存取。若要在 LAN 上公開，設定 `OPENCLAW_GATEWAY_BIND=lan` 並在 `openclaw.json` 中設定 `gateway.controlUi.allowedOrigins`（或明確啟用 host-header 回退）。
- **路徑：** 主機設定和工作區預設為 `~openclaw/.openclaw` 和 `~openclaw/.openclaw/workspace`。使用 `OPENCLAW_CONFIG_DIR` 和 `OPENCLAW_WORKSPACE_DIR` 覆寫啟動腳本使用的主機路徑。

## 儲存模型

- **持久化主機資料：** `OPENCLAW_CONFIG_DIR` 和 `OPENCLAW_WORKSPACE_DIR` 綁定掛載到容器中，並在主機上保留狀態。
- **臨時沙箱 tmpfs：** 若您啟用 `agents.defaults.sandbox`，工具沙箱容器在 `/tmp`、`/var/tmp` 和 `/run` 掛載 `tmpfs`。這些路徑是記憶體支援的，沙箱容器消失時也會消失；頂層 Podman 容器設定不會新增自己的 tmpfs 掛載。
- **磁碟增長熱點：** 需要監控的主要路徑是 `media/`、`agents/<agentId>/sessions/sessions.json`、逐字稿 JSONL 檔案、`cron/runs/*.jsonl`，以及 `/tmp/openclaw/`（或您設定的 `logging.file`）下的滾動檔案日誌。

`setup-podman.sh` 現在將映像 tar 暫存在私有臨時目錄中，並在設定期間列印選定的基礎目錄。對於非 root 執行，只有當基礎是安全的才接受 `TMPDIR`；否則回退到 `/var/tmp`，然後 `/tmp`。儲存的 tar 保持擁有者專用，並串流到目標使用者的 `podman load`，因此私有呼叫者臨時目錄不會阻擋設定。

## 實用指令

- **日誌：** 使用 quadlet：`sudo journalctl --machine openclaw@ --user -u openclaw.service -f`。使用腳本：`sudo -u openclaw podman logs -f openclaw`
- **停止：** 使用 quadlet：`sudo systemctl --machine openclaw@ --user stop openclaw.service`。使用腳本：`sudo -u openclaw podman stop openclaw`
- **再次啟動：** 使用 quadlet：`sudo systemctl --machine openclaw@ --user start openclaw.service`。使用腳本：重新執行啟動腳本或 `podman start openclaw`
- **移除容器：** `sudo -u openclaw podman rm -f openclaw` — 主機上的設定和工作區會被保留

## 疑難排解

- **設定或 auth-profiles 的權限被拒絕（EACCES）：** 容器預設為 `--userns=keep-id`，以與執行腳本的主機使用者相同的 uid/gid 執行。確認您的主機 `OPENCLAW_CONFIG_DIR` 和 `OPENCLAW_WORKSPACE_DIR` 由該使用者擁有。
- **Gateway 啟動被阻擋（缺少 `gateway.mode=local`）：** 確認 `~openclaw/.openclaw/openclaw.json` 存在且設定了 `gateway.mode="local"`。若缺少，`setup-podman.sh` 會建立此檔案。
- **Rootless Podman 對 openclaw 使用者失敗：** 確認 `/etc/subuid` 和 `/etc/subgid` 包含 `openclaw` 的行（例如 `openclaw:100000:65536`）。若缺少，新增它並重啟。
- **容器名稱已在使用中：** 啟動腳本使用 `podman run --replace`，因此再次啟動時現有容器會被替換。若要手動清理：`podman rm -f openclaw`。
- **以 openclaw 執行時找不到腳本：** 確認 `setup-podman.sh` 已執行，以便 `run-openclaw-podman.sh` 複製到 openclaw 的主目錄（例如 `/home/openclaw/run-openclaw-podman.sh`）。
- **找不到 Quadlet 服務或啟動失敗：** 編輯 `.container` 檔案後執行 `sudo systemctl --machine openclaw@ --user daemon-reload`。Quadlet 需要 cgroups v2：`podman info --format '{{.Host.CgroupsVersion}}'` 應顯示 `2`。

## 選用：以您自己的使用者執行

若要以您的一般使用者執行 gateway（無需專用的 openclaw 使用者）：建置映像、使用 `OPENCLAW_GATEWAY_TOKEN` 建立 `~/.openclaw/.env`，並使用 `--userns=keep-id` 和掛載到您的 `~/.openclaw` 執行容器。啟動腳本為 openclaw 使用者流程設計；對於單一使用者設定，您可以手動執行腳本中的 `podman run` 指令，將設定和工作區指向您的主目錄。大多數使用者的建議做法：使用 `setup-podman.sh` 並以 openclaw 使用者執行，以便設定和程序隔離。
