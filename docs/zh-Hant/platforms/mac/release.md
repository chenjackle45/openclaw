---
summary: "OpenClaw macOS 發行版本檢查清單（Sparkle feed、打包、簽名）"
read_when:
  - 發佈或驗證 OpenClaw macOS 版本
  - 更新 Sparkle appcast 或 feed 資產
title: "macOS Release（macOS 發行版本）"
---

# OpenClaw macOS 發行版本（Sparkle）

此應用程式現已配備 Sparkle 自動更新。發行版本建置必須使用 Developer ID 簽名、壓縮，並搭配已簽名的 appcast 項目一起發佈。

## 前置需求

- 已安裝 Developer ID Application 憑證（範例：`Developer ID Application: <Developer Name> (<TEAMID>)`）。
- 環境變數 `SPARKLE_PRIVATE_KEY_FILE` 設定為 Sparkle ed25519 私密金鑰的路徑（公開金鑰已預置於 Info.plist）。如果缺少，請檢查 `~/.profile`。
- `xcrun notarytool` 的公證憑證（Keychain profile 或 API 金鑰），用於 Gatekeeper 安全的 DMG/zip 發佈。
  - 我們使用名為 `openclaw-notary` 的 Keychain profile，從 shell profile 中的 App Store Connect API 金鑰環境變數建立：
    - `APP_STORE_CONNECT_API_KEY_P8`、`APP_STORE_CONNECT_KEY_ID`、`APP_STORE_CONNECT_ISSUER_ID`
    - `echo "$APP_STORE_CONNECT_API_KEY_P8" | sed 's/\\n/\n/g' > /tmp/openclaw-notary.p8`
    - `xcrun notarytool store-credentials "openclaw-notary" --key /tmp/openclaw-notary.p8 --key-id "$APP_STORE_CONNECT_KEY_ID" --issuer "$APP_STORE_CONNECT_ISSUER_ID"`
- 已安裝 `pnpm` 相依套件（`pnpm install --config.node-linker=hoisted`）。
- Sparkle 工具透過 SwiftPM 自動擷取至 `apps/macos/.build/artifacts/sparkle/Sparkle/bin/`（`sign_update`、`generate_appcast` 等）。

## 建置與打包

備註：

- `APP_BUILD` 對應至 `CFBundleVersion`/`sparkle:version`；必須為數字且單調遞增（不含 `-beta`），否則 Sparkle 會將其視為相等。
- 若省略 `APP_BUILD`，`scripts/package-mac-app.sh` 會從 `APP_VERSION` 推導 Sparkle 安全的預設值（`YYYYMMDDNN`：穩定版預設為 `90`，預發行版使用後綴推導的 lane），並取該值與 git commit 數量的較大值。
- 你仍可在發行工程需要特定單調值時明確覆蓋 `APP_BUILD`。
- `BUILD_CONFIG=release` 時，`scripts/package-mac-app.sh` 預設自動建置 universal（`arm64 x86_64`）。你仍可透過 `BUILD_ARCHS=arm64` 或 `BUILD_ARCHS=x86_64` 覆蓋。本地/開發建置（`BUILD_CONFIG=debug`）預設為目前架構（`$(uname -m)`）。
- 發行成品（zip + DMG + 公證）使用 `scripts/package-mac-dist.sh`。本地/開發打包使用 `scripts/package-mac-app.sh`。

```bash
# 從 repo 根目錄執行；設定發行 ID 以啟用 Sparkle feed。
# 此指令在不公證的情況下建置發行成品。
# APP_BUILD 必須為數字且單調遞增以供 Sparkle 比較。
# 省略時會從 APP_VERSION 自動推導。
SKIP_NOTARIZE=1 \
BUNDLE_ID=ai.openclaw.mac \
APP_VERSION=2026.3.12 \
BUILD_CONFIG=release \
SIGN_IDENTITY="Developer ID Application: <Developer Name> (<TEAMID>)" \
scripts/package-mac-dist.sh

# `package-mac-dist.sh` 已自動建立 zip + DMG。
# 若你改用 `package-mac-app.sh` 直接建置，請手動建立它們：
# 若想在此步驟公證/裝訂，請使用下方的 NOTARIZE 指令。
ditto -c -k --sequesterRsrc --keepParent dist/OpenClaw.app dist/OpenClaw-2026.3.12.zip

# 選用：為使用者建立一個樣式化的 DMG（拖放至 /Applications）
scripts/create-dmg.sh dist/OpenClaw.app dist/OpenClaw-2026.3.12.dmg

# 建議：建置 + 公證/裝訂 zip + DMG
# 首先，建立一次 Keychain profile：
#   xcrun notarytool store-credentials "openclaw-notary" \
#     --apple-id "<apple-id>" --team-id "<team-id>" --password "<app-specific-password>"
NOTARIZE=1 NOTARYTOOL_PROFILE=openclaw-notary \
BUNDLE_ID=ai.openclaw.mac \
APP_VERSION=2026.3.12 \
BUILD_CONFIG=release \
SIGN_IDENTITY="Developer ID Application: <Developer Name> (<TEAMID>)" \
scripts/package-mac-dist.sh

# 選用：隨發行版本一起提供 dSYM
ditto -c -k --keepParent apps/macos/.build/release/OpenClaw.app.dSYM dist/OpenClaw-2026.3.12.dSYM.zip
```

## Appcast 項目

使用版本說明產生器讓 Sparkle 渲染格式化的 HTML 說明：

```bash
SPARKLE_PRIVATE_KEY_FILE=/path/to/ed25519-private-key scripts/make_appcast.sh dist/OpenClaw-2026.3.12.zip https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml
```

從 `CHANGELOG.md` 產生 HTML 發行說明（透過 [`scripts/changelog-to-html.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/changelog-to-html.sh)）並嵌入 appcast 項目中。
發佈時，將更新後的 `appcast.xml` 與發行資產（zip + dSYM）一起 commit。

## 發佈與驗證

- 將 `OpenClaw-2026.3.12.zip`（和 `OpenClaw-2026.3.12.dSYM.zip`）上傳至標籤 `v2026.3.12` 的 GitHub release。
- 確認原始 appcast URL 與預置的 feed 一致：`https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml`。
- 健全性檢查：
  - `curl -I https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml` 回傳 200。
  - 資產上傳後，`curl -I <enclosure url>` 回傳 200。
  - 在先前的公開建置上，從 About 標籤執行「Check for Updates...」並確認 Sparkle 乾淨地安裝了新版本。

完成定義：已簽名的應用程式 + appcast 已發佈，更新流程可從較舊的已安裝版本正常運作，發行資產已附加至 GitHub release。
