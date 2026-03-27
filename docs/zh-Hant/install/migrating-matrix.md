---
summary: "OpenClaw 如何就地升級之前的 Matrix 外掛，包括加密狀態恢復限制和手動恢復步驟"
read_when:
  - 升級現有 Matrix 安裝
  - 遷移加密 Matrix 歷史記錄和裝置狀態
title: "Matrix migration（Matrix 遷移）"
---

# Matrix migration

本頁涵蓋了從之前的公開 `matrix` 外掛升級到目前實現的部分。

對大多數使用者來說，升級是就地進行的：

- 外掛保持 `@openclaw/matrix`
- 頻道保持 `matrix`
- 你的配置保持在 `channels.matrix`
- 快取的認證保持在 `~/.openclaw/credentials/matrix/`
- 執行時期狀態保持在 `~/.openclaw/matrix/`

你不需要重新命名配置金鑰或以新名稱重新安裝外掛。

## 遷移自動完成的內容

當 gateway 啟動時，以及當你執行 [`openclaw doctor --fix`](/zh-Hant/gateway/doctor) 時，OpenClaw 會嘗試自動修復舊的 Matrix 狀態。在任何可行的 Matrix 遷移步驟在磁碟上改變狀態之前，OpenClaw 會建立或重新使用聚焦恢復快照。

當你使用 `openclaw update` 時，確切的觸發器取決於 OpenClaw 的安裝方式：

- 源代碼安裝在更新流程中執行 `openclaw doctor --fix`，然後預設重新啟動 gateway
- 套件管理器安裝更新套件、執行非互動式醫生通過，然後依賴預設的 gateway 重新啟動，使啟動可以完成 Matrix 遷移
- 如果你使用 `openclaw update --no-restart`，啟動背景的 Matrix 遷移會延遲，直到你稍後執行 `openclaw doctor --fix` 並重新啟動 gateway

自動遷移涵蓋：

- 在 `~/Backups/openclaw-migrations/` 下建立或重新使用前遷移快照
- 重新使用你的快取 Matrix 認證
- 保持相同的帳戶選擇和 `channels.matrix` 配置
- 將最舊的平面 Matrix 同步存儲區移到目前帳戶範圍的位置
- 當目標帳戶可以安全解決時，將最舊的平面 Matrix 密碼存儲區移到目前帳戶範圍的位置
- 從舊的 rust 密碼存儲區中提取之前保存的 Matrix 房間金鑰備份解密金鑰（當該金鑰在本機存在時）
- 當存取令牌稍後變更時，重新使用同一 Matrix 帳戶、主伺服器和使用者的最完整的現有令牌雜湊存儲根
- 當 Matrix 存取令牌變更但帳戶/裝置身分保持不變時，掃描同級令牌雜湊存儲根以尋找待復原加密狀態的中繼資料
- 在下一次 Matrix 啟動時，將備份的房間金鑰恢復到新密碼存儲區中

快照詳情：

- OpenClaw 在成功快照後在 `~/.openclaw/matrix/migration-snapshot.json` 處寫入標記檔案，以便稍後的啟動和修復通過可以重新使用同一存檔。
- 這些自動 Matrix 遷移快照僅備份配置 + 狀態（`includeWorkspace: false`）。
- 如果 Matrix 只有警告限制的遷移狀態，例如因為 `userId` 或 `accessToken` 仍然遺失，OpenClaw 還沒有建立快照，因為沒有 Matrix 變動是可行的。
- 如果快照步驟失敗，OpenClaw 會跳過該執行的 Matrix 遷移，而不是在沒有恢復點的情況下改變狀態。

關於多帳戶升級：

- 最舊的平面 Matrix 存儲區（`~/.openclaw/matrix/bot-storage.json` 和 `~/.openclaw/matrix/crypto/`）來自單一存儲區配置，因此 OpenClaw 只能將其遷移到一個已解決的 Matrix 帳戶目標中
- 已帳戶範圍的舊版 Matrix 存儲區會被偵測並按已配置的 Matrix 帳戶準備

## 遷移無法自動完成的內容

之前的公開 Matrix 外掛 **不會** 自動建立 Matrix 房間金鑰備份。它持久化本機密碼狀態並請求裝置驗證，但它不保證你的房間金鑰被備份到主伺服器。

這意味著某些加密安裝只能部分遷移。

OpenClaw 無法自動復原：

- 從未備份的本機唯一房間金鑰
- 當目標 Matrix 帳戶無法解決，因為 `homeserver`、`userId` 或 `accessToken` 仍然無法使用時的加密狀態
- 當配置了多個 Matrix 帳戶但未設定 `channels.matrix.defaultAccount` 時，一個共享平面 Matrix 存儲區的自動遷移
- 釘選到倉庫路徑而不是標準 Matrix 套件的自訂外掛路徑安裝
- 舊存儲區具有備份金鑰但沒有在本機保留解密金鑰時遺失的恢復金鑰

目前的警告範圍：

- 自訂 Matrix 外掛路徑安裝由 gateway 啟動和 `openclaw doctor` 都浮現

如果你的舊安裝具有從未備份的本機唯一加密歷史記錄，升級後某些較舊的加密訊息可能會變成不可讀。

## 推薦的升級流程

1. 正常更新 OpenClaw 和 Matrix 外掛。
   偏好不帶 `--no-restart` 的普通 `openclaw update` 以便啟動可以立即完成 Matrix 遷移。
2. 執行：

   ```bash
   openclaw doctor --fix
   ```

   如果 Matrix 有可行的遷移工作，doctor 將首先建立或重新使用前遷移快照並列印存檔路徑。

3. 啟動或重新啟動 gateway。
4. 檢查目前驗證和備份狀態：

   ```bash
   openclaw matrix verify status
   openclaw matrix verify backup status
   ```

5. 如果 OpenClaw 告訴你需要恢復金鑰，執行：

   ```bash
   openclaw matrix verify backup restore --recovery-key "<your-recovery-key>"
   ```

6. 如果此裝置仍未驗證，執行：

   ```bash
   openclaw matrix verify device "<your-recovery-key>"
   ```

7. 如果你有意放棄無法復原的舊歷史記錄並想要未來訊息的新備份基線，執行：

   ```bash
   openclaw matrix verify backup reset --yes
   ```

8. 如果尚無伺服器端金鑰備份存在，為未來的恢復建立一個：

   ```bash
   openclaw matrix verify bootstrap
   ```

## 加密遷移如何運作

加密遷移是一個兩階段過程：

1. 啟動或 `openclaw doctor --fix` 在加密遷移可行時建立或重新使用前遷移快照。
2. 啟動或 `openclaw doctor --fix` 通過活躍的 Matrix 外掛安裝檢查舊的 Matrix 密碼存儲區。
3. 如果找到備份解密金鑰，OpenClaw 會將其寫入新的恢復金鑰流程並標記房間金鑰恢復為待復原。
4. 在下一次 Matrix 啟動時，OpenClaw 會自動將備份的房間金鑰恢復到新密碼存儲區。

如果舊存儲區報告從未備份的房間金鑰，OpenClaw 會發出警告，而不是假裝恢復成功。

## 常見訊息及其含義

### 升級和偵測訊息

`Matrix plugin upgraded in place.`

- 含義：舊的磁碟上 Matrix 狀態已被偵測並遷移到目前配置。
- 該怎麼做：除非相同輸出也包括警告，否則無需執行。

`Matrix migration snapshot created before applying Matrix upgrades.`

- 含義：OpenClaw 在改變 Matrix 狀態前建立了恢復存檔。
- 該怎麼做：保留列印的存檔路徑，直到你確認遷移成功。

`Matrix migration snapshot reused before applying Matrix upgrades.`

- 含義：OpenClaw 找到了現有的 Matrix 遷移快照標記並重新使用該存檔，而不是建立重複備份。
- 該怎麼做：保留列印的存檔路徑，直到你確認遷移成功。

`Legacy Matrix state detected at ... but channels.matrix is not configured yet.`

- 含義：舊的 Matrix 狀態存在，但 OpenClaw 無法將其對應到目前 Matrix 帳戶，因為 Matrix 未配置。
- 該怎麼做：配置 `channels.matrix`，然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`Legacy Matrix state detected at ... but the new account-scoped target could not be resolved yet (need homeserver, userId, and access token for channels.matrix...).`

- 含義：OpenClaw 找到了舊狀態，但它仍然無法確定確切的目前帳戶/裝置根。
- 該怎麼做：使用有效的 Matrix 登入啟動一次 gateway，或在快取認證存在後重新執行 `openclaw doctor --fix`。

`Legacy Matrix state detected at ... but multiple Matrix accounts are configured and channels.matrix.defaultAccount is not set.`

- 含義：OpenClaw 找到了一個共享平面 Matrix 存儲區，但它拒絕猜測應該接收它的命名 Matrix 帳戶。
- 該怎麼做：將 `channels.matrix.defaultAccount` 設定為預期帳戶，然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`Matrix legacy sync store not migrated because the target already exists (...)`

- 含義：新的帳戶範圍位置已經有同步或密碼存儲區，所以 OpenClaw 沒有自動覆寫它。
- 該怎麼做：在手動移除或移動衝突目標之前，驗證目前帳戶是否是正確帳戶。

`Failed migrating Matrix legacy sync store (...)` 或 `Failed migrating Matrix legacy crypto store (...)`

- 含義：OpenClaw 嘗試移動舊的 Matrix 狀態，但檔案系統操作失敗。
- 該怎麼做：檢查檔案系統權限和磁碟狀態，然後重新執行 `openclaw doctor --fix`。

`Legacy Matrix encrypted state detected at ... but channels.matrix is not configured yet.`

- 含義：OpenClaw 找到了舊的加密 Matrix 存儲區，但沒有目前的 Matrix 配置可以附加到其中。
- 該怎麼做：配置 `channels.matrix`，然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`Legacy Matrix encrypted state detected at ... but the account-scoped target could not be resolved yet (need homeserver, userId, and access token for channels.matrix...).`

- 含義：加密存儲區存在，但 OpenClaw 無法安全地決定它屬於哪個目前帳戶/裝置。
- 該怎麼做：使用有效的 Matrix 登入啟動一次 gateway，或在快取認證可用後重新執行 `openclaw doctor --fix`。

`Legacy Matrix encrypted state detected at ... but multiple Matrix accounts are configured and channels.matrix.defaultAccount is not set.`

- 含義：OpenClaw 找到了一個共享平面舊版密碼存儲區，但它拒絕猜測應該接收它的命名 Matrix 帳戶。
- 該怎麼做：將 `channels.matrix.defaultAccount` 設定為預期帳戶，然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`Matrix migration warnings are present, but no on-disk Matrix mutation is actionable yet. No pre-migration snapshot was needed.`

- 含義：OpenClaw 偵測到舊的 Matrix 狀態，但遷移仍然被缺少的身分或認證資料阻止。
- 該怎麼做：完成 Matrix 登入或配置設定，然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`Legacy Matrix encrypted state was detected, but the Matrix plugin helper is unavailable. Install or repair @openclaw/matrix so OpenClaw can inspect the old rust crypto store before upgrading.`

- 含義：OpenClaw 找到了舊的加密 Matrix 狀態，但它無法從通常檢查該存儲區的 Matrix 外掛載入幫助程式進入點。
- 該怎麼做：重新安裝或修復 Matrix 外掛（`openclaw plugins install @openclaw/matrix`，或用於倉庫簽出的 `openclaw plugins install ./extensions/matrix`），然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`Matrix plugin helper path is unsafe: ... Reinstall @openclaw/matrix and try again.`

- 含義：OpenClaw 找到了逃離外掛根或失敗外掛邊界檢查的幫助程式檔案路徑，因此它拒絕了導入它。
- 該怎麼做：從受信任的路徑重新安裝 Matrix 外掛，然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`- Failed creating a Matrix migration snapshot before repair: ...`

`- Skipping Matrix migration changes for now. Resolve the snapshot failure, then rerun "openclaw doctor --fix".`

- 含義：OpenClaw 拒絕改變 Matrix 狀態，因為它無法首先建立恢復快照。
- 該怎麼做：解決備份錯誤，然後重新執行 `openclaw doctor --fix` 或重新啟動 gateway。

`Failed migrating legacy Matrix client storage: ...`

- 含義：Matrix 客戶端側備用發現舊平面存儲區，但移動失敗。OpenClaw 現在中止該備用，而不是以新存儲區無聲啟動。
- 該怎麼做：檢查檔案系統權限或衝突、保持舊狀態完整，然後在修復錯誤後重試。

`Matrix is installed from a custom path: ...`

- 含義：Matrix 釘選到路徑安裝，所以主線更新不會自動用倉庫的標準 Matrix 套件取代它。
- 該怎麼做：當你想回到預設 Matrix 外掛時，用 `openclaw plugins install @openclaw/matrix` 重新安裝。

### 加密狀態恢復訊息

`matrix: restored X/Y room key(s) from legacy encrypted-state backup`

- 含義：備份的房間金鑰已成功恢復到新密碼存儲區。
- 該怎麼做：通常無需執行。

`matrix: N legacy local-only room key(s) were never backed up and could not be restored automatically`

- 含義：某些舊房間金鑰只存在於舊本機存儲區中，從未上傳到 Matrix 備份。
- 該怎麼做：期望某些舊加密歷史記錄保持無法使用，除非你可以從另一個已驗證客戶端手動復原這些金鑰。

`Legacy Matrix encrypted state for account "..." has backed-up room keys, but no local backup decryption key was found. Ask the operator to run "openclaw matrix verify backup restore --recovery-key <key>" after upgrade if they have the recovery key.`

- 含義：備份存在，但 OpenClaw 無法自動復原恢復金鑰。
- 該怎麼做：執行 `openclaw matrix verify backup restore --recovery-key "<your-recovery-key>"`。

`Failed inspecting legacy Matrix encrypted state for account "..." (...): ...`

- 含義：OpenClaw 找到了舊的加密存儲區，但無法足夠安全地檢查它以準備恢復。
- 該怎麼做：重新執行 `openclaw doctor --fix`。如果重複，保持舊狀態目錄完整，並使用另一個已驗證的 Matrix 客戶端加上 `openclaw matrix verify backup restore --recovery-key "<your-recovery-key>"` 復原。

`Legacy Matrix backup key was found for account "...", but .../recovery-key.json already contains a different recovery key. Leaving the existing file unchanged.`

- 含義：OpenClaw 偵測到備份金鑰衝突並拒絕自動覆寫目前恢復金鑰檔案。
- 該怎麼做：在重試任何復原命令之前驗證哪個恢復金鑰是正確的。

`Legacy Matrix encrypted state for account "..." cannot be fully converted automatically because the old rust crypto store does not expose all local room keys for export.`

- 含義：這是舊存儲格式的硬限制。
- 該怎麼做：備份金鑰仍可復原，但本機唯一的加密歷史記錄可能會保持無法使用。

`matrix: failed restoring room keys from legacy encrypted-state backup: ...`

- 含義：新外掛嘗試復原，但 Matrix 回傳錯誤。
- 該怎麼做：執行 `openclaw matrix verify backup status`，然後視需要用 `openclaw matrix verify backup restore --recovery-key "<your-recovery-key>"` 重試。

### 手動恢復訊息

`Backup key is not loaded on this device. Run 'openclaw matrix verify backup restore' to load it and restore old room keys.`

- 含義：OpenClaw 知道你應該有備份金鑰，但它在此裝置上不活躍。
- 該怎麼做：執行 `openclaw matrix verify backup restore`，或在需要時傳遞 `--recovery-key`。

`Store a recovery key with 'openclaw matrix verify device <key>', then run 'openclaw matrix verify backup restore'.`

- 含義：此裝置目前沒有存儲恢復金鑰。
- 該怎麼做：先用恢復金鑰驗證裝置，然後恢復備份。

`Backup key mismatch on this device. Re-run 'openclaw matrix verify device <key>' with the matching recovery key.`

- 含義：儲存的金鑰與活躍的 Matrix 備份不相符。
- 該怎麼做：使用正確的金鑰重新執行 `openclaw matrix verify device "<your-recovery-key>"`。

如果你同意失去無法復原的舊加密歷史記錄，你可以改為用 `openclaw matrix verify backup reset --yes` 重設目前備份基線。

`Backup trust chain is not verified on this device. Re-run 'openclaw matrix verify device <key>'.`

- 含義：備份存在，但此裝置還沒有足夠強地信任交叉簽名鏈。
- 該怎麼做：重新執行 `openclaw matrix verify device "<your-recovery-key>"`。

`Matrix recovery key is required`

- 含義：你嘗試了需要提供恢復金鑰的恢復步驟，但沒有提供。
- 該怎麼做：用恢復金鑰重新執行該命令。

`Invalid Matrix recovery key: ...`

- 含義：提供的金鑰無法解析或不符合預期格式。
- 該怎麼做：用來自 Matrix 客戶端或恢復金鑰檔案的確切恢復金鑰重試。

`Matrix device is still unverified after applying recovery key. Verify your recovery key and ensure cross-signing is available.`

- 含義：金鑰已應用，但裝置仍無法完成驗證。
- 該怎麼做：確認使用了正確的金鑰，且帳戶上可用交叉簽名，然後重試。

`Matrix key backup is not active on this device after loading from secret storage.`

- 含義：機密存儲未在此裝置上產生活躍的備份工作階段。
- 該怎麼做：先驗證裝置，然後用 `openclaw matrix verify backup status` 重新檢查。

`Matrix crypto backend cannot load backup keys from secret storage. Verify this device with 'openclaw matrix verify device <key>' first.`

- 含義：在裝置驗證完成前，此裝置無法從機密存儲恢復。
- 該怎麼做：先執行 `openclaw matrix verify device "<your-recovery-key>"`。

### 自訂外掛安裝訊息

`Matrix is installed from a custom path that no longer exists: ...`

- 含義：你的外掛安裝記錄指向已刪除的本機路徑。
- 該怎麼做：用 `openclaw plugins install @openclaw/matrix` 重新安裝，或如果從倉庫簽出執行，用 `openclaw plugins install ./extensions/matrix`。

## 如果加密歷史記錄仍然沒有返回

按順序執行這些檢查：

```bash
openclaw matrix verify status --verbose
openclaw matrix verify backup status --verbose
openclaw matrix verify backup restore --recovery-key "<your-recovery-key>" --verbose
```

如果備份成功恢復但某些舊房間仍然沒有歷史記錄，那些遺失的金鑰可能從未被之前的外掛備份過。

## 如果你想為未來的訊息重新開始

如果你同意失去無法復原的舊加密歷史記錄，只想要未來的乾淨備份基線，請按順序執行這些命令：

```bash
openclaw matrix verify backup reset --yes
openclaw matrix verify backup status --verbose
openclaw matrix verify status
```

如果裝置在之後仍然未驗證，通過比較 SAS 表情符號或十進位程式碼並確認它們相符，從 Matrix 客戶端完成驗證。

## 相關頁面

- [Matrix](/zh-Hant/channels/matrix)
- [醫生](/zh-Hant/gateway/doctor)
- [遷移](/zh-Hant/install/migrating)
- [外掛](/zh-Hant/tools/plugin)
