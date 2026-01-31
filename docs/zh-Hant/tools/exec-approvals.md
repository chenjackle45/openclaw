---
title: "Exec approvals(執行核准)"
summary: "執行核准、允許清單以及沙盒逃逸提示語說明"
read_when:
  - 配置執行核准或允許清單時
  - 在 macOS App 中實作過核准使用者介面時
  - 檢視沙盒提權提示與其影響時
---

# 執行核准 (Exec Approvals)

執行核准是 OpenClaw 的**安全防護欄**，用於控制受沙盒保護的 Agent 何時能在真實的宿主機（Gateway 或節點）執行指令。您可以將其視為安全聯鎖機制：只有當政策、允許清單以及使用者的即時核准同時達成一致時，才允許執行指令。

## 適用範圍
執行核准在執行端主機上進行在地化強制執行：
- **Gateway 主機**：位於 Gateway 機器上的 `openclaw` 背景進程。
- **節點主機 (Node Host)**：節點執行器（如 macOS 伴隨 App 或無頭節點主機）。

## 核心策略與設定
設定存放於本地的 `~/.openclaw/exec-approvals.json` 中。包含了：
- **安全性 (Security)**：
  - `deny`：阻斷所有宿主機執行請求。
  - `allowlist`：僅允許匹配允許清單的指令。
  - `full`：允許所有執行（等同於提權模式）。
- **核准請求 (Ask)**：
  - `off`：從不提示。
  - `on-miss`：僅當允許清單未匹配時才提示。
  - `always`：針對每一條指令皆要求核准。

## 允許清單 (Allowlist)
允許清單是**依 Agent 個別設定**的。在 macOS App 中您可以切換 Agent 來編輯不同的清單。模式匹配支援**不分大小寫的 Glob 匹配**，且必須指向**完整路徑**。

範例：
- `~/Projects/**/bin/bird`
- `/opt/homebrew/bin/rg`

## 安全指令 (Safe Bins)
系統定義了一系列「僅限標準輸入 (stdin-only)」的安全執行檔（例如 `jq`, `grep`, `sort`），它們可以在 `allowlist` 模式下**直接執行**，而無需顯式加入允許清單。這些指令會被限制只能處理輸入串流，而不允許直接存取本地檔案路徑。

## 核准流程
當 Agent 觸發需要核准的指令時：
1. Gateway 會向連接的 UI 客戶端廣播 `exec.approval.requested`。
2. 您可以在控制中心或 macOS App 看到確認對話框。
3. 您可以選擇：**允許一次 (Allow once)**、**始終允許 (Always allow - 加入清單)** 或 **拒絕 (Deny)**。

## 指令轉發至聊天頻道
您可以將執行核准請求轉發至任何聊天頻道（如 Discord 或 Slack），並透過以下指令進行遠端核准：
```
/approve <ID> allow-once
/approve <id> allow-always
/approve <id> deny
```

## 注意事項
- **優先順序**：最終執行的政策以 `tools.exec.*` 與核准設定中**較嚴格者**為準。
- **提權模式**：`/exec security=full` 是針對授權操作者的便利設定，設計上會跳過核准流程。
- **安全建議**：建議儘量使用 `allowlist` 與 `ask` 機制，以確保即使 Agent 受損也能保有最後防線。
