---
title: "Release Policy（發佈檢查清單）"
summary: "npm + macOS app 的逐步發行檢查清單"
read_when:
  - 剪下新的 npm 版本時
  - 剪下新的 macOS app 版本時
  - 發佈前驗證元資料時
---

# 發行檢查清單（npm + macOS）

從 repo 根目錄使用 `pnpm`，預設使用 Node 24。Node 22 LTS 目前為 `22.16+`，仍可支援相容性。標記／發佈前保持工作樹清潔。

## 操作員觸發

當操作員說「release」時，立即執行此預檢（除非被阻止，否則無額外問題）：

- 讀取本文件和 `docs/platforms/mac/release.md`。
- 從 `~/.profile` 載入環境並確認設定了 `SPARKLE_PRIVATE_KEY_FILE` + App Store Connect 變數（SPARKLE_PRIVATE_KEY_FILE 應位於 `~/.profile`）。
- 如果需要，使用 `~/Library/CloudStorage/Dropbox/Backup/Sparkle` 中的 Sparkle 金鑰。

## 版本控制

OpenClaw 目前發佈使用日期型版本控制。

- 穩定版本：`YYYY.M.D`
  - Git 標籤：`vYYYY.M.D`
  - Repo 歷史範例：`v2026.2.26`、`v2026.3.8`
- Beta 預發佈版本：`YYYY.M.D-beta.N`
  - Git 標籤：`vYYYY.M.D-beta.N`
  - Repo 歷史範例：`v2026.2.15-beta.1`、`v2026.3.8-beta.1`
- 到處使用相同的版本字串，減去不使用 Git 標籤的地方的開頭 `v`：
  - `package.json`：`2026.3.8`
  - Git 標籤：`v2026.3.8`
  - GitHub 發佈標題：`openclaw 2026.3.8`
- 不使用零填充月或日。使用 `2026.3.8`，而不是 `2026.03.08`。
- 穩定版和 beta 版是 npm dist-tags，而不是獨立的發佈線：
  - `latest` = 穩定版
  - `beta` = 預發佈／測試版
- Dev 是 `main` 的移動 head，而不是普通的 git 標籤發佈。
- 發佈工作流強制執行目前穩定／beta 標籤格式，並拒絕 CalVer 日期距發佈日期超過 2 個 UTC 日曆天的版本。

歷史記錄備註：

- 舊標籤如 `v2026.1.11-1`、`v2026.2.6-3` 和 `v2.0.0-beta2` 存在於 repo 歷史中。
- 將這些視為遺留標籤模式。新發佈應使用 `vYYYY.M.D` 進行穩定版本，使用 `vYYYY.M.D-beta.N` 進行 beta 版本。

1. **版本 & 元資料**

- [ ] 更新 `package.json` 版本（例如 `2026.1.29`）。
- [ ] 執行 `pnpm plugins:sync` 以對齊擴充套件包版本 + 變更日誌。
- [ ] 更新 CLI／版本字串在 [`src/version.ts`](https://github.com/openclaw/openclaw/blob/main/src/version.ts) 和 [`src/web/session.ts`](https://github.com/openclaw/openclaw/blob/main/src/web/session.ts) 中的 Baileys 使用者代理。
- [ ] 確認套件元資料（名稱、描述、儲存庫、關鍵字、授權）並且 `bin` 對應指向 [`openclaw.mjs`](https://github.com/openclaw/openclaw/blob/main/openclaw.mjs) 作為 `openclaw`。
- [ ] 如果依賴項已變更，執行 `pnpm install` 使 `pnpm-lock.yaml` 為最新。

2. **構建 & 成品**

- [ ] 如果 A2UI 輸入已變更，執行 `pnpm canvas:a2ui:bundle` 並提交任何已更新的 [`src/canvas-host/a2ui/a2ui.bundle.js`](https://github.com/openclaw/openclaw/blob/main/src/canvas-host/a2ui/a2ui.bundle.js)。
- [ ] `pnpm run build`（重新產生 `dist/`）。
- [ ] 驗證 npm 套件 `files` 包含所有必要的 `dist/*` 資料夾（特別是 `dist/node-host/**` 和 `dist/acp/**` 用於無頭 node + ACP CLI）。
- [ ] 確認 `dist/build-info.json` 存在並包含預期的 `commit` 雜湊（CLI 橫幅對 npm 安裝使用此項）。
- [ ] 選擇性：在構建後執行 `npm pack --pack-destination /tmp`；檢查 tarball 內容並將其保留在 GitHub 發佈的手邊（**不要**提交它）。

3. **變更日誌 & 文件**

- [ ] 使用使用者面向的亮點更新 `CHANGELOG.md`（如果遺留，請建立檔案）；保持條目嚴格按版本降序排列。
- [ ] 確保 README 範例／標誌與目前 CLI 行為相符（特別是新命令或選項）。

4. **驗證**

- [ ] `pnpm build`
- [ ] `pnpm check`
- [ ] `pnpm test`（或 `pnpm test:coverage` 如果需要覆蓋輸出）
- [ ] `pnpm release:check`（驗證 npm pack 內容）
- [ ] `OPENCLAW_INSTALL_SMOKE_SKIP_NONROOT=1 pnpm test:install:smoke`（Docker 安裝煙霧測試，快速路徑；發佈前必需）
  - 如果立即先前的 npm 發佈已知為損壞，設定 `OPENCLAW_INSTALL_SMOKE_PREVIOUS=<last-good-version>` 或 `OPENCLAW_INSTALL_SMOKE_SKIP_PREVIOUS=1` 進行安裝前步驟。
- [ ] （選擇性）完整安裝程式煙霧（新增非根 + CLI 覆蓋）：`pnpm test:install:smoke`
- [ ] （選擇性）安裝程式 E2E（Docker，執行 `curl -fsSL https://openclaw.ai/install.sh | bash`、登機，然後執行實際工具呼叫）：
  - `pnpm test:install:e2e:openai`（需要 `OPENAI_API_KEY`）
  - `pnpm test:install:e2e:anthropic`（需要 `ANTHROPIC_API_KEY`）
  - `pnpm test:install:e2e`（需要兩個金鑰；執行兩個提供者）
- [ ] （選擇性）如果您的變更影響傳送／接收路徑，點檢 web 閘道。

5. **macOS app（Sparkle）**

- [ ] 構建 + 簽署 macOS app，然後壓縮它以供發佈。
- [ ] 產生 Sparkle appcast（HTML 備註透過 [`scripts/make_appcast.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/make_appcast.sh)）並更新 `appcast.xml`。
- [ ] 保持 app zip（和選擇性的 dSYM zip）準備好附加到 GitHub 發佈。
- [ ] 遵循 [macOS 發佈](/zh-Hant/platforms/mac/release) 的確切命令和必要環境變數。
  - `APP_BUILD` 必須是數值 + 單調的（無 `-beta`），以便 Sparkle 正確比較版本。
  - 如果進行公証，使用從 App Store Connect API 環境變數建立的 `openclaw-notary` 鑰匙圈設定檔（參見 [macOS 發佈](/zh-Hant/platforms/mac/release)）。

6. **發佈（npm）**

- [ ] 確認 git 狀態乾淨；視需要提交並推送。
- [ ] 確認為 `openclaw` 套件配置了 npm 受信任發佈。
- [ ] 推送相符的 git 標籤以觸發 `.github/workflows/openclaw-npm-release.yml`。
  - 穩定標籤發佈到 npm `latest`。
  - Beta 標籤發佈到 npm `beta`。
  - 工作流拒絕與 `package.json` 不符、不在 `main` 上或 CalVer 日期距發佈日期超過 2 個 UTC 日曆天的標籤。
- [ ] 驗證登錄：`npm view openclaw version`、`npm view openclaw dist-tags` 和 `npx -y openclaw@X.Y.Z --version`（或 `--help`）。

### 故障排除（來自 2.0.0-beta2 發佈的備註）

- **npm pack／publish 掛起或產生巨大 tarball**：`dist/OpenClaw.app` 中的 macOS app bundle（和發佈 zip）被掃入套件中。透過 `package.json` `files` 白名單發佈內容以修復（包含 dist 子目錄、文件、技能；排除 app 束）。使用 `npm pack --dry-run` 確認 `dist/OpenClaw.app` 未列出。
- **npm 驗證 dist-tags 的 web 迴圈**：使用舊版驗證以取得 OTP 提示：
  - `NPM_CONFIG_AUTH_TYPE=legacy npm dist-tag add openclaw@X.Y.Z latest`
- **`npx` 驗證失敗，出現 `ECOMPROMISED: Lock compromised`**：使用全新快取重試：
  - `NPM_CONFIG_CACHE=/tmp/npm-cache-$(date +%s) npx -y openclaw@X.Y.Z --version`
- **標籤需要在晚期修復後重新指向**：強制更新並推送標籤，然後確保 GitHub 發佈資產仍然相符：
  - `git tag -f vX.Y.Z && git push -f origin vX.Y.Z`

7. **GitHub 發佈 + appcast**

- [ ] 標籤並推送：`git tag vX.Y.Z && git push origin vX.Y.Z`（或 `git push --tags`）。
  - 推送標籤也觸發 npm 發佈工作流。
- [ ] 為 `vX.Y.Z` 建立／刷新 GitHub 發佈，標題為 **`openclaw X.Y.Z`**（不只是標籤）；正文應包含該版本的 **完整**變更日誌區段（亮點 + 變更 + 修復），內聯（無裸連結），並且 **必須不重複正文內的標題**。
- [ ] 附加成品：`npm pack` tarball（選擇性）、`OpenClaw-X.Y.Z.zip` 和 `OpenClaw-X.Y.Z.dSYM.zip`（如果產生）。
- [ ] 提交已更新的 `appcast.xml` 並推送它（Sparkle 從 main 饋送）。
- [ ] 從乾淨的臨時目錄（無 `package.json`），執行 `npx -y openclaw@X.Y.Z send --help` 以確認安裝／CLI 進入點有效。
- [ ] 宣佈／分享發佈備註。

## 外掛發佈範圍（npm）

我們只發佈 `@openclaw/*` 範圍下的 **現有 npm 外掛**。未在 npm 上的束外掛保持 **磁碟樹僅有**（仍在 `extensions/**` 中發佈）。

導出清單的流程：

1. `npm search @openclaw --json` 並捕捉套件名稱。
2. 與 `extensions/*/package.json` 名稱進行比較。
3. 僅發佈 **交集**（已在 npm 上）。

目前 npm 外掛清單（視需要更新）：

- @openclaw/bluebubbles
- @openclaw/diagnostics-otel
- @openclaw/discord
- @openclaw/feishu
- @openclaw/lobster
- @openclaw/matrix
- @openclaw/msteams
- @openclaw/nextcloud-talk
- @openclaw/nostr
- @openclaw/voice-call
- @openclaw/zalo
- @openclaw/zalouser

發佈備註也必須指出 **預設未啟用的新選擇性束外掛**（範例：`tlon`）。
