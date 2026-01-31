---
title: "glm(GLM models)"
summary: "GLM 模型系列概覽 + 如何在 OpenClaw 中使用"
read_when:
  - 想要在 OpenClaw 中使用 GLM 模型時
  - 需要模型命名慣例與設定資訊時
---

# GLM models

GLM 是一個**模型系列**（並非公司），可透過 Z.AI 平台使用。在 OpenClaw 中，GLM 模型是透過 `zai` 供應商以及如 `zai/glm-4.7` 的模型 ID 進行存取。

## CLI 設定方式

```bash
openclaw onboard --auth-choice zai-api-key
```

## 配置範例

```json5
{
  env: { ZAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "zai/glm-4.7" } } }
}
```

## 注意事項

- GLM 版本與可用性可能會變更；請查看 Z.AI 文件以獲取最新資訊。
- 模型 ID 範例包括 `glm-4.7` 與 `glm-4.6`。
- 關於供應商詳情，請參閱 [/providers/zai](/providers/zai)。
