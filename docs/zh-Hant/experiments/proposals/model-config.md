---
title: "Model config(模型設定探索)"
summary: "探索：模型設定、認證 profiles 和 fallback 行為"
read_when:
  - 探索未來模型選擇 + 認證 profile 想法
---
# Model Config (Exploration)(模型設定（探索）)

本文件捕獲未來模型設定的**想法**。這不是
發布規格。有關當前行為，請參閱：
- [Models](/concepts/models)
- [Model failover](/concepts/model-failover)
- [OAuth + profiles](/concepts/oauth)

## 動機

營運者想要：
- 每個供應商多個認證 profiles（個人 vs 工作）。
- 簡單的 `/model` 選擇與可預測的 fallbacks。
- 文字模型和圖片有能力模型之間的明確分離。

## 可能的方向（高層次）

- 保持模型選擇簡單：`provider/model` 加上選用別名。
- 讓供應商擁有多個認證 profiles，具有明確順序。
- 使用全域 fallback 清單，以便所有會話一致地 fail over。
- 僅在明確設定時覆蓋圖片路由。

## 開放問題

- Profile 輪換應該是每個供應商還是每個模型？
- UI 應該如何為會話顯示 profile 選擇？
- 從舊版設定鍵最安全的遷移路徑是什麼？
