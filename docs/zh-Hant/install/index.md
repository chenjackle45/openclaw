---
summary: "安裝 OpenClaw — 安裝程式指令碼、npm/pnpm、從原始碼、Docker 等"
read_when:
  - 你需要除了「開始使用」快速開始以外的安裝方法
  - 你想要部署到雲平台
  - 你需要更新、遷移或卸載
title: "Install（安裝）"
---

# 安裝

已按照 [開始使用](/zh-Hant/start/getting-started)？那你已經全部設定好了。本頁面適用於替代安裝方法、特定平台指令和維護。

## 系統需求

- **[Node 22+](/zh-Hant/install/node)**（[安裝程式指令碼](#install-methods)如果缺失會自動安裝）
- macOS、Linux 或 Windows
- 如果從原始碼構建，需要 `pnpm`

<Note>
在 Windows，我們強烈推薦在 [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) 下執行 OpenClaw。
</Note>

## 安裝方法

<Tip>
**安裝程式指令碼**是推薦的 OpenClaw 安裝方法。它會處理 Node 偵測、安裝和上線精靈（一步完成）。
</Tip>

<AccordionGroup>
  <Accordion title="安裝程式指令碼" icon="rocket" defaultOpen>
    下載 CLI、透過 npm 全域安裝，並啟動上線精靈。

    <Tabs>
      <Tab title="macOS / Linux / WSL2">
        ```bash
        curl -fsSL https://openclaw.ai/install.sh | bash
        ```
      </Tab>
      <Tab title="Windows (PowerShell)">
        ```powershell
        iwr -useb https://openclaw.ai/install.ps1 | iex
        ```
      </Tab>
    </Tabs>

    就是這樣 — 指令碼會處理 Node 偵測、安裝和上線精靈。

    若要略過上線精靈，只安裝二進位檔：

    <Tabs>
      <Tab title="macOS / Linux / WSL2">
        ```bash
        curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
        ```
      </Tab>
      <Tab title="Windows (PowerShell)">
        ```powershell
        & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard
        ```
      </Tab>
    </Tabs>

    如需所有旗標、環境變數和 CI/自動化選項，詳見 [安裝程式內部機制](/zh-Hant/install/installer)。

  </Accordion>

  <Accordion title="npm / pnpm" icon="package">
    如果你已有 Node 22+ 且偏好自己管理安裝：

    <Tabs>
      <Tab title="npm">
        ```bash
        npm install -g openclaw@latest
        openclaw onboard --install-daemon
        ```

        <Accordion title="sharp 構建錯誤？">
          如果你已全域安裝 libvips（macOS Homebrew 常見），且 `sharp` 失敗，強制預建二進位檔：

          ```bash
          SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
          ```

          如果你看到 `sharp: Please add node-gyp to your dependencies`，要麼安裝構建工具（macOS：Xcode CLT + `npm install -g node-gyp`），要麼使用上面的環境變數。
        </Accordion>
      </Tab>
      <Tab title="pnpm">
        ```bash
        pnpm add -g openclaw@latest
        pnpm approve-builds -g        # approve openclaw, node-llama-cpp, sharp, etc.
        openclaw onboard --install-daemon
        ```

        <Note>
        pnpm 需要明確批准具有構建指令碼的套件。第一次安裝顯示「忽略的構建指令碼」警告後，執行 `pnpm approve-builds -g` 並選擇列出的套件。
        </Note>
      </Tab>
    </Tabs>

  </Accordion>

  <Accordion title="從原始碼" icon="github">
    適用於貢獻者或想從本地簽出執行的任何人。

    <Steps>
      <Step title="複製和構建">
        複製 [OpenClaw repo](https://github.com/openclaw/openclaw) 並構建：

        ```bash
        git clone https://github.com/openclaw/openclaw.git
        cd openclaw
        pnpm install
        pnpm ui:build
        pnpm build
        ```
      </Step>
      <Step title="連結 CLI">
        讓 `openclaw` 指令全域可用：

        ```bash
        pnpm link --global
        ```

        或者，略過連結，從 repo 內執行 `pnpm openclaw ...`。
      </Step>
      <Step title="執行上線">
        ```bash
        openclaw onboard --install-daemon
        ```
      </Step>
    </Steps>

    如需更深層次的開發工作流程，詳見 [設定](/zh-Hant/start/setup)。

  </Accordion>
</AccordionGroup>

## 其他安裝方法

<CardGroup cols={2}>
  <Card title="Docker" href="/zh-Hant/install/docker" icon="container">
    容器化或無頭部署。
  </Card>
  <Card title="Nix" href="/zh-Hant/install/nix" icon="snowflake">
    透過 Nix 進行聲明式安裝。
  </Card>
  <Card title="Ansible" href="/zh-Hant/install/ansible" icon="server">
    自動化機隊佈建。
  </Card>
  <Card title="Bun" href="/zh-Hant/install/bun" icon="zap">
    透過 Bun 執行時進行 CLI 專用使用。
  </Card>
</CardGroup>

## 安裝後

驗證一切正常：

```bash
openclaw doctor         # 檢查配置問題
openclaw status         # gateway 狀態
openclaw dashboard      # 開啟瀏覽器 UI
```

如果你需要自訂執行時路徑，使用：

- `OPENCLAW_HOME` 用於基於主目錄的內部路徑
- `OPENCLAW_STATE_DIR` 用於可變狀態位置
- `OPENCLAW_CONFIG_PATH` 用於配置檔案位置

詳見 [環境變數](/zh-Hant/help/environment) 以了解優先順序和完整細節。

## 故障排查：`openclaw` 找不到

<Accordion title="PATH 診斷和修復">
  快速診斷：

```bash
node -v
npm -v
npm prefix -g
echo "$PATH"
```

如果 `$(npm prefix -g)/bin`（macOS/Linux）或 `$(npm prefix -g)`（Windows）**不**在你的 `$PATH`，你的 shell 找不到全域 npm 二進位檔（包括 `openclaw`）。

修復 — 將其新增到 shell 啟動檔（`~/.zshrc` 或 `~/.bashrc`）：

```bash
export PATH="$(npm prefix -g)/bin:$PATH"
```

在 Windows，將 `npm prefix -g` 的輸出新增到你的 PATH。

然後開啟新終端（或在 zsh 中執行 `rehash` / 在 bash 中執行 `hash -r`）。
</Accordion>

## 更新 / 卸載

<CardGroup cols={3}>
  <Card title="更新" href="/zh-Hant/install/updating" icon="refresh-cw">
    保持 OpenClaw 最新版本。
  </Card>
  <Card title="遷移" href="/zh-Hant/install/migrating" icon="arrow-right">
    移到新機器。
  </Card>
  <Card title="卸載" href="/zh-Hant/install/uninstall" icon="trash-2">
    完全移除 OpenClaw。
  </Card>
</CardGroup>
