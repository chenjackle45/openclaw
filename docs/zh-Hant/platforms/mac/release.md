---
title: "release(Release Workflow)"
summary: "OpenClaw macOS 發佈檢查清單 (Sparkle feed, 打包, 簽署)"
read_when:
  - 建立或驗證 OpenClaw macOS 發佈版本時
  - 更新 Sparkle Appcast 或 Feed 資產時
---

# OpenClaw macOS 發佈 (Sparkle)

本應用程式現在隨附 Sparkle 自動更新功能。發佈版本必須經過 Developer ID 簽署、壓縮為 Zip，並發佈帶有已簽署 Appcast 項目的版本。

## 先決條件
- 已安裝 Developer ID Application 憑證 (範例: `Developer ID Application: <Developer Name> (<TEAMID>)`)。
- 環境變數 `SPARKLE_PRIVATE_KEY_FILE` 設定為 Sparkle 私鑰路徑 (您的 Sparkle ed25519 私鑰路徑；公鑰已嵌入 Info.plist)。若遺失，請檢查 `~/.profile`。
- 若要進行 Gatekeeper 安全的 DMG/zip 分發，需具備 `xcrun notarytool` 的 Notary 憑證 (Keychain 設定檔或 API 金鑰)。
  - 我們使用名為 `openclaw-notary` 的 Keychain 設定檔，這是從您 Shell 設定檔中的 App Store Connect API 金鑰環境變數建立的：
    - `APP_STORE_CONNECT_API_KEY_P8`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`
    - `echo "$APP_STORE_CONNECT_API_KEY_P8" | sed 's/\\n/\n/g' > /tmp/openclaw-notary.p8`
    - `xcrun notarytool store-credentials "openclaw-notary" --key /tmp/openclaw-notary.p8 --key-id "$APP_STORE_CONNECT_KEY_ID" --issuer "$APP_STORE_CONNECT_ISSUER_ID"`
- 已安裝 `pnpm` 相依套件 (`pnpm install --config.node-linker=hoisted`)。
- Sparkle 工具會透過 SwiftPM 自動擷取至 `apps/macos/.build/artifacts/sparkle/Sparkle/bin/` (`sign_update`, `generate_appcast` 等)。

## 建置與打包
注意：
- `APP_BUILD` 對應至 `CFBundleVersion`/`sparkle:version`；請保持數值且單調遞增 (無 `-beta`)，否則 Sparkle 會將其視為相等。
- 預設為當前架構 (`$(uname -m)`)。對於發佈/通用建置，請設定 `BUILD_ARCHS="arm64 x86_64"` (或 `BUILD_ARCHS=all`)。
- 使用 `scripts/package-mac-dist.sh` 產生發佈產物 (zip + DMG + notarization)。使用 `scripts/package-mac-app.sh` 進行本地/開發打包。

```bash
# 從 Repo 根目錄；設定 Release ID 以啟用 Sparkle Feed。
# APP_BUILD 必須為數值且單調遞增以供 Sparkle 比較。
BUNDLE_ID=bot.molt.mac \
APP_VERSION=2026.1.27-beta.1 \
APP_BUILD="$(git rev-list --count HEAD)" \
BUILD_CONFIG=release \
SIGN_IDENTITY="Developer ID Application: <Developer Name> (<TEAMID>)" \
scripts/package-mac-app.sh

# 壓縮以供分發 (包含 resource forks 以支援 Sparkle delta)
ditto -c -k --sequesterRsrc --keepParent dist/OpenClaw.app dist/OpenClaw-2026.1.27-beta.1.zip

# 選用：亦建立風格化的 DMG 供人類使用 (拖曳至 /Applications)
scripts/create-dmg.sh dist/OpenClaw.app dist/OpenClaw-2026.1.27-beta.1.dmg

# 推薦：建置 + Notarize/Staple zip + DMG
# 首先，建立一次 Keychain 設定檔：
#   xcrun notarytool store-credentials "openclaw-notary" \
#     --apple-id "<apple-id>" --team-id "<team-id>" --password "<app-specific-password>"
NOTARIZE=1 NOTARYTOOL_PROFILE=openclaw-notary \
BUNDLE_ID=bot.molt.mac \
APP_VERSION=2026.1.27-beta.1 \
APP_BUILD="$(git rev-list --count HEAD)" \
BUILD_CONFIG=release \
SIGN_IDENTITY="Developer ID Application: <Developer Name> (<TEAMID>)" \
scripts/package-mac-dist.sh

# 選用：隨發佈版本附上 dSYM
ditto -c -k --keepParent apps/macos/.build/release/OpenClaw.app.dSYM dist/OpenClaw-2026.1.27-beta.1.dSYM.zip
```

## Appcast 項目
使用發行說明產生器，以便 Sparkle 渲染格式化的 HTML 說明：

```bash
SPARKLE_PRIVATE_KEY_FILE=/path/to/ed25519-private-key scripts/make_appcast.sh dist/OpenClaw-2026.1.27-beta.1.zip https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml
```

這會從 `CHANGELOG.md` (透過 [`scripts/changelog-to-html.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/changelog-to-html.sh)) 產生 HTML 發行說明並嵌入 Appcast 項目中。
發佈時，將更新後的 `appcast.xml` 連同發佈資產 (zip + dSYM) 一併 Commit。

## 發佈與驗證
- 上傳 `OpenClaw-2026.1.27-beta.1.zip` (與 `OpenClaw-2026.1.27-beta.1.dSYM.zip`) 至標籤為 `v2026.1.27-beta.1` 的 GitHub Release。
- 確保原始 Appcast URL 與內建的 Feed 相符：`https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml`。
- 合理性檢查：
  - `curl -I https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml` 回傳 200。
  - 資產上傳後，`curl -I <enclosure url>` 回傳 200。
  - 在先前的公開建置上，從 About 頁籤執行「Check for Updates…」並驗證 Sparkle 能乾淨地安裝新建置。

完成定義 (Definition of done)：已簽署的 App + Appcast 已發佈，從舊版安裝更新流程運作正常，且發佈資產已附加至 GitHub Release。
