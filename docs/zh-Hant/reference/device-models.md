---
title: "Device models(裝置型號)"
summary: "OpenClaw 如何為 macOS App 中的友善名稱 Vendor Apple 裝置型號識別碼。"
read_when:
  - 更新裝置型號識別碼 Mappings 或 NOTICE/License 檔案
  - 變更 Instances UI 如何顯示裝置名稱
---

# 裝置型號資料庫（友善名稱）

macOS Companion App 透過將 Apple Model 識別碼（例如 `iPad16,6`、`Mac16,6`）對應至人類可讀名稱，在 **Instances** UI 中顯示友善的 Apple 裝置型號名稱。

Mapping 以 JSON Vendor 在：

- `apps/macos/Sources/OpenClaw/Resources/DeviceModels/`

## 資料來源

我們目前 Vendor MIT 授權 Repository 中的 Mapping：

- `kyle-seongwoo-jun/apple-device-identifiers`

為了保持 Builds 可確定性，JSON 檔案釘選到特定的 Upstream Commits（記錄在 `apps/macos/Sources/OpenClaw/Resources/DeviceModels/NOTICE.md`）。

## 更新資料庫

1. 選擇您想要釘選的 Upstream Commits（一個用於 iOS，一個用於 macOS）。
2. 更新 `apps/macos/Sources/OpenClaw/Resources/DeviceModels/NOTICE.md` 中的 Commit Hashes。
3. 重新下載 JSON 檔案，釘選到那些 Commits：

```bash
IOS_COMMIT="<commit sha for ios-device-identifiers.json>"
MAC_COMMIT="<commit sha for mac-device-identifiers.json>"

curl -fsSL "https://raw.githubusercontent.com/kyle-seongwoo-jun/apple-device-identifiers/${IOS_COMMIT}/ios-device-identifiers.json" \
  -o apps/macos/Sources/OpenClaw/Resources/DeviceModels/ios-device-identifiers.json

curl -fsSL "https://raw.githubusercontent.com/kyle-seongwoo-jun/apple-device-identifiers/${MAC_COMMIT}/mac-device-identifiers.json" \
  -o apps/macos/Sources/OpenClaw/Resources/DeviceModels/mac-device-identifiers.json
```

4. 確保 `apps/macos/Sources/OpenClaw/Resources/DeviceModels/LICENSE.apple-device-identifiers.txt` 仍與 Upstream 相符（如果 Upstream License 變更則取代它）。
5. 驗證 macOS App Build 正常（無警告）：

```bash
swift build --package-path apps/macos
```
