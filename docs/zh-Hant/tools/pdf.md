---
title: "PDF Tool（PDF 工具）"
summary: "使用原生提供者支援和提取備選分析一個或多個 PDF 文件"
read_when:
  - You want to analyze PDFs from agents
  - You need exact pdf tool parameters and limits
  - You are debugging native PDF mode vs extraction fallback
---

# PDF 工具

`pdf` 分析一個或多個 PDF 文件並返回文字。

快速行為：

- Anthropic 和 Google 模型提供者的原生提供者模式。
- 其他提供者的提取備選模式（先提取文字，然後在需要時提取頁面影像）。
- 支援單一（`pdf`）或多重（`pdfs`）輸入，每次呼叫最多 10 個 PDF。

## 可用性

工具只在 OpenClaw 可以為代理解析 PDF 能力模型設定時才會登記：

1. `agents.defaults.pdfModel`
2. 備選 `agents.defaults.imageModel`
3. 備選基於可用認證的最佳努力提供者預設值

如果無法解析可用模型，`pdf` 工具不會公開。

## 輸入參考

- `pdf`（`string`）：一個 PDF 路徑或 URL
- `pdfs`（`string[]`）：多個 PDF 路徑或 URL，最多 10 個
- `prompt`（`string`）：分析提示，預設 `Analyze this PDF document.`
- `pages`（`string`）：頁面篩選，如 `1-5` 或 `1,3,7-9`
- `model`（`string`）：可選模型覆蓋（`provider/model`）
- `maxBytesMb`（`number`）：每個 PDF 大小限制（MB）

詳見英文文件以了解完整配置...（篇幅限制）
