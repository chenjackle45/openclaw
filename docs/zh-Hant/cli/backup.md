---
summary: "`openclaw backup` CLI 參考（建立本地備份封存檔）"
read_when:
  - 想要為本地 OpenClaw 狀態建立完整的備份封存檔時
  - 想要在重設或解除安裝前預覽哪些路徑會被包含時
title: "backup（本地備份）"
---

# `openclaw backup`

為 OpenClaw 的狀態、設定、憑證、會話及工作區（可選）建立本地備份封存檔。

```bash
openclaw backup create
openclaw backup create --output ~/Backups
openclaw backup create --dry-run --json
openclaw backup create --verify
openclaw backup create --no-include-workspace
openclaw backup create --only-config
openclaw backup verify ./2026-03-09T00-00-00.000Z-openclaw-backup.tar.gz
```

## 注意事項

- 封存檔包含一個 `manifest.json` 檔案，記錄了解析後的來源路徑與封存佈局。
- 預設輸出為當前工作目錄下一個含有時間戳的 `.tar.gz` 封存檔。
- 若當前工作目錄位於已備份的來源樹狀目錄內，OpenClaw 會改以您的家目錄作為預設封存位置。
- 現有封存檔不會被覆寫。
- 位於來源 state/workspace 樹狀目錄內的輸出路徑會被拒絕，以避免自我包含。
- `openclaw backup verify <archive>` 會驗證封存檔只包含一個根 manifest，拒絕路徑遍歷式的封存路徑，並檢查每個 manifest 宣告的 payload 都存在於 tarball 中。
- `openclaw backup create --verify` 會在寫入封存檔後立即執行該驗證。
- `openclaw backup create --only-config` 僅備份目前使用中的 JSON 設定檔。

## 備份內容

`openclaw backup create` 會從您的本地 OpenClaw 安裝規劃備份來源：

- OpenClaw 本地狀態解析器所返回的狀態目錄，通常為 `~/.openclaw`
- 目前使用中的設定檔路徑
- OAuth / 憑證目錄
- 從當前設定中探索到的工作區目錄，除非您傳入 `--no-include-workspace`

若您使用 `--only-config`，OpenClaw 會跳過狀態、憑證和工作區探索，僅封存目前使用中的設定檔路徑。

OpenClaw 在建立封存前會將路徑正規化。若設定、憑證或工作區已位於狀態目錄內，它們不會被重複加入為獨立的頂層備份來源。缺失的路徑會被略過。

封存的 payload 儲存了這些來源樹狀目錄的檔案內容，而內嵌的 `manifest.json` 記錄了解析後的絕對來源路徑以及每個資產所使用的封存佈局。

## 設定檔無效時的行為

`openclaw backup` 有意繞過正常的設定檔預檢，使其在復原過程中仍能提供協助。由於工作區探索依賴有效的設定檔，當設定檔存在但無效，且工作區備份仍啟用時，`openclaw backup create` 會快速失敗。

若您在此情況下仍需要部分備份，請重新執行：

```bash
openclaw backup create --no-include-workspace
```

這樣可保留狀態、設定和憑證在備份範圍內，同時完全跳過工作區探索。

若您只需要設定檔本身的副本，`--only-config` 在設定檔損壞時同樣有效，因為它不依賴解析設定檔來進行工作區探索。

## 大小與效能

OpenClaw 不強制執行內建的最大備份大小或單檔大小限制。

實際限制來自本地機器和目標檔案系統：

- 臨時封存寫入加上最終封存所需的可用空間
- 遍歷大型工作區樹狀目錄並將其壓縮為 `.tar.gz` 的時間
- 若您使用 `openclaw backup create --verify` 或執行 `openclaw backup verify` 時重新掃描封存的時間
- 目標路徑的檔案系統行為。OpenClaw 優先使用無覆寫的硬連結發佈步驟，在硬連結不支援時回退至獨占複製

大型工作區通常是封存大小的主要驅動因素。若您需要更小或更快的備份，請使用 `--no-include-workspace`。

若要獲得最小的封存，請使用 `--only-config`。
