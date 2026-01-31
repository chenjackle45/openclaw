---
title: "approvals(核准管理)"
summary: "`openclaw approvals` CLI 參考（Gateway 或節點主機的執行核准）"
read_when:
  - 想要透過 CLI 編輯執行核准項目時
  - 需要管理 Gateway 或節點主機上的允許清單 (Allowlists) 時
---

# `openclaw approvals`

管理**本地主機**、**Gateway 主機**或**節點主機**的執行核准 (Exec Approvals)。
預設情況下，指令會針對磁碟上的本地核准檔案進行操作。使用 `--gateway` 可針對 Gateway 主機，使用 `--node` 則可針對特定的節點。

相關資訊：
- 執行核准：[執行核准 (Exec approvals)](/tools/exec-approvals)
- 節點管理：[節點 (Nodes)](/nodes)

## 常見指令

```bash
# 獲取本地主機的核准項目
openclaw approvals get

# 獲取指定節點的核准項目
openclaw approvals get --node <ID|名稱|IP>

# 獲取 Gateway 主機的核准項目
openclaw approvals get --gateway
```

## 從檔案取代核准設定

```bash
# 取代本地核准設定
openclaw approvals set --file ./exec-approvals.json

# 取代指定節點的核准設定
openclaw approvals set --node <ID|名稱|IP> --file ./exec-approvals.json

# 取代 Gateway 的核准設定
openclaw approvals set --gateway --file ./exec-approvals.json
```

## 允許清單協助工具 (Allowlist helpers)

```bash
# 將特定的路徑加入允許清單
openclaw approvals allowlist add "~/Projects/**/bin/rg"

# 為指定節點與 Agent 加入允許清單
openclaw approvals allowlist add --agent main --node <ID|名稱|IP> "/usr/bin/uptime"

# 為所有 Agent 加入通用的允許指令
openclaw approvals allowlist add --agent "*" "/usr/bin/uname"

# 移除允許清單中的項目
openclaw approvals allowlist remove "~/Projects/**/bin/rg"
```

## 注意事項

- `--node` 使用與 `openclaw nodes` 相同的解析邏輯（支援 ID、名稱、IP 或 ID 前綴）。
- `--agent` 預設為 `"*"`，代表適用於所有 Agent。
- 節點主機必須宣稱支援 `system.execApprovals.get/set`（適用於 macOS App 或無頭節點主機）。
- 核准檔案會依主機儲存於 `~/.openclaw/exec-approvals.json`。
