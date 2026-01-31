---
title: "Formal verification(形式化驗證)"
summary: OpenClaw 最高風險路徑的機器檢查安全模型。
permalink: /security/formal-verification/
---

# 形式化驗證 (Security Models)

此頁面追蹤 OpenClaw 的 **形式化安全模型** (目前使用 TLA+/TLC；未來可能增加更多)。

> 注意：部分舊連結可能指向先前的專案名稱。

**目標 (北極星):** 提供機器檢查的論證，證明 OpenClaw 強制執行其預期的安全政策（授權、Session 隔離、Tool Gating 與 Sandbox 完整性），即使面對複雜的並行狀態變更。

## 為什麼需要形式化驗證？

OpenClaw Gateway 是一個並行系統，管理：
- 多個不可信的 Clients (Sessions)
- 共用資源 (The Host, Docker Daemon, GPU Models)
- 複雜的狀態轉換 (Session Lifecycle, Sandbox Lifecycle)
- 授權層 (Allowlists, Admin Tokens)

單元測試無法輕易捕捉並行錯誤（Race Conditions, Deadlocks）或邏輯缺陷（例如："如果我在 Session 銷毀的同時請求 Admin Token 會發生什麼？"）。形式化方法幫助我們探索所有可能的狀態。

## 目前模型 (Current Models)

我們在 `model/` 目錄（源碼庫中）維護 TLA+ 規格。

### 1. Session Lifecycle & Isolation (`SessionLifecycle.tla`)

*狀態：探索性*

模擬 Session 的建立、使用、閒置逾時與垃圾回收 (GC)。
**關鍵屬性 (Invariants) 檢查：**
- **Isolation**: 資料絕不從一個 Session 洩漏到另一個 Session (除非明確共用)。
- **Liveness**: 閒置的 Sessions 最終會被回收。
- **Safety**: 銷毀中的 Session 無法被存取。

### 2. Sandbox State Machine (`Sandbox.tla`)

*狀態：規劃中*

模擬 Docker Container 的生命週期（Created, Running, Paused, Dead, Removed）與 Host 的同步。
**目標：** 確保 Agent 絕不會在 Sandbox **之外** 執行指令（當政策要求 Sandbox 時）。

### 3. Tool Authorization (`Authz.tla`)

*狀態：探索性*

模擬 Tool Request 的決策邏輯：
`Request -> (Global Policy) -> (Agent Policy) -> (Session Policy) -> (Extension Hooks) -> Decision`

**目標：** 證明沒有組合的 Config/Hooks 允許被拒絕的工具執行（預設拒絕原則）。

## 如何執行模型

您需要 [TLA+ Tools](https://lamport.azurewebsites.net/tla/tools.html) (TLC Model Checker)。
VS Code 的 TLA+ 擴充功能是推薦的開發環境。

```bash
# 範例 (假設您已安裝 tla2tools.jar)
java -jar tla2tools.jar model/SessionLifecycle.tla -config model/SessionLifecycle.cfg
```

## 下一步

我們目前的重點是主要的 Gateway 實作。這些模型作為設計文件與複雜邏輯的驗證。隨著專案成熟，我們計畫將模型檢查整合到 CI 中，並將規格連結到實際程式碼（透過註解或 Assertions）。
