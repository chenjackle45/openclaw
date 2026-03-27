---
summary: "為 OpenClaw 外掛系統新增共用功能的貢獻者指南"
read_when:
  - 新增核心功能和外掛註冊表面
  - 決定程式碼是否應屬於核心、供應商外掛或功能外掛
  - 為通道或工具連接新的執行階段幫助程式
title: "Adding Capabilities (Contributor Guide)（新增功能）"
sidebarTitle: "新增功能"
---

# 新增功能

<Info>
  這是 **OpenClaw 核心開發者的貢獻者指南**。如果你正在建立外部外掛，請改為參閱 [建立外掛](/zh-Hant/plugins/building-plugins)。
</Info>

當 OpenClaw 需要新的領域（如圖片生成、影片生成或某個未來由供應商支援的功能區域）時，請使用此指南。

規則是：

- 外掛 = 所有權邊界
- 功能 = 共用核心合約

這表示你不應以將供應商直接連接到通道或工具開始。應以定義功能開始。

## 何時建立功能

當以下所有情況都為真時，建立新功能：

1. 多個供應商可合理地實作它
2. 通道、工具或功能外掛應在不在意供應商的情況下使用它
3. 核心需要擁有備用、政策、設定或傳遞行為

如果工作僅為供應商專用且尚無共用合約存在，請先停下來定義合約。

## 標準序列

1. 定義具型別的核心合約。
2. 為該合約新增外掛註冊。
3. 新增共用執行階段幫助程式。
4. 連接一個真實供應商外掛作為驗證。
5. 將功能/通道消費者移至執行階段幫助程式。
6. 新增合約測試。
7. 記錄營運者面向的設定和所有權模型。

## 哪些內容放在何處

核心：

- 請求/回應類型
- 提供者登錄 + 解析
- 備用行為
- 設定綱要和標籤/幫助
- 執行階段幫助程式表面

供應商外掛：

- 供應商 API 呼叫
- 供應商驗證處理
- 供應商特定的請求正規化
- 功能實作的註冊

功能/通道外掛：

- 呼叫 `api.runtime.*` 或相符的 `plugin-sdk/*-runtime` 幫助程式
- 永遠不要直接呼叫供應商實作

## 檔案檢查清單

對於新功能，應預期接觸以下區域：

- `src/<capability>/types.ts`
- `src/<capability>/...registry/runtime.ts`
- `src/plugins/types.ts`
- `src/plugins/registry.ts`
- `src/plugins/captured-registration.ts`
- `src/plugins/contracts/registry.ts`
- `src/plugins/runtime/types-core.ts`
- `src/plugins/runtime/index.ts`
- `src/plugin-sdk/<capability>.ts`
- `src/plugin-sdk/<capability>-runtime.ts`
- 一個或多個 `extensions/<vendor>/...`
- 設定/文件/測試

## 範例：圖片生成

圖片生成遵循標準形狀：

1. 核心定義 `ImageGenerationProvider`
2. 核心公開 `registerImageGenerationProvider(...)`
3. 核心公開 `runtime.imageGeneration.generate(...)`
4. `openai` 和 `google` 外掛註冊供應商支援的實作
5. 未來供應商可註冊相同合約，而無需變更通道/工具

設定金鑰獨立於視覺分析路由：

- `agents.defaults.imageModel` = 分析影像
- `agents.defaults.imageGenerationModel` = 生成影像

保持分開，以確保備用和政策保持明確。

## 複查檢查清單

在傳遞新功能前，驗證：

- 無通道/工具直接匯入供應商程式碼
- 執行階段幫助程式是共用路徑
- 至少一個合約測試斷言捆綁所有權
- 設定文件命名新模型/設定金鑰
- 外掛文件說明所有權邊界

如果 PR 跳過功能層並將供應商行為硬編碼到通道/工具中，將其寄回並先定義合約。
