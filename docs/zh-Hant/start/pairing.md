---
title: "Pairing(配對機制)"
summary: "配對功能總覽：核准誰可以向您發送私訊，以及哪些節點可以加入網路"
read_when:
  - 設定私訊存取控制時
  - 配對新的 iOS/Android 節點時
  - 檢視 OpenClaw 安全架構時
---

# 配對機制 (Pairing)

「配對」是 OpenClaw 的顯式**擁有者核准 (Owner approval)** 步驟。
它主要應用在兩個地方：

1) **私訊配對**（誰被允許與機器人對話）
2) **節點配對**（哪些裝置/節點被允許加入 Gateway 網路）

安全背景資訊請參閱：[安全性 (Security)](/gateway/security)

## 1) 私訊配對 (Inbound chat access)

當頻道配置為私訊政策 `pairing` 時，未知的發送者會收到一個短代碼，在您核准之前，他們的訊息**不會被處理**。

預設的私訊政策文件：[安全性 (Security)](/gateway/security)

配對碼規則：
- 8 個字元，全大寫，不包含易混淆字元（如 `0O1I`）。
- **效期為 1 小時**。機器人僅在建立新請求時發送配對碼（大約每小時每個發送者一次）。
- 每個頻道預設最多處理 **3 個待處理**的配對請求；其餘請求將被忽略，直到有人過期或被核准。

### 核准發送者

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <代碼>
```

支援頻道：`telegram`, `whatsapp`, `signal`, `imessage`, `discord`, `slack`。

### 狀態存儲路徑

存放在 `~/.openclaw/credentials/` 底下：
- 待處理請求：`<頻道>-pairing.json`
- 已核准名單：`<頻道>-allowFrom.json`

請將這些檔案視為機密資訊（它們守護著助理的存取權限）。

## 2) 節點裝置配對 (iOS/Android/macOS/無頭節點)

節點以 `role: node` 的**裝置**身份連接到 Gateway。Gateway 會建立一個必須經由核准的裝置配對請求。

### 核准節點裝置

```bash
openclaw devices list
openclaw devices approve <請求ID>
openclaw devices reject <請求ID>
```

### 狀態存儲路徑

存放在 `~/.openclaw/devices/` 底下：
- `pending.json`（短暫存儲；待處理請求會過期）
- `paired.json`（已配對裝置及其 Token）

### 備註

- 舊版的 `node.pair.*` API 已被裝置配對機制取代。WebSocket 節點均需要透過裝置配對流程進行。
