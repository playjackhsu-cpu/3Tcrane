---
title: QA 測試計劃
tags: [qa, testing, accessibility, persistence]
status: baseline
updated: 2026-09-14
---

# QA 測試計劃

## 測試層級

| 層級 | 覆蓋 |
| --- | --- |
| Content validation | schema、ID 唯一、foreign key、四選一、來源 URL、權利狀態、禁止私有欄位 |
| Unit | 計分、錯題、掌握狀態、抽題、版本比較、搜尋正規化 |
| Persistence | CRUD、migration、upgrade A→B、失敗保留、orphan question |
| View model | 題目流程、交卷、空資料、內容 decode 錯誤、深色模式 |
| UI smoke | iPhone 5 tabs、iPad sidebar、核心作答／複習／模考／紀錄 |
| Accessibility | VoiceOver、Dynamic Type、Contrast、Reduce Motion、44 pt target、非顏色單一傳意 |
| Release | unsigned Release build、bundle 資源、Privacy Manifest、無私有檔／Debug fixture |
| 真機 | iPhone／iPad、效能、旋轉／多工、App 更新安裝、離線 |

## 必過核心情境

1. 首次安裝離線開啟，所有主功能可用。
2. 課程／複習可不作答直接閱讀題目、答案、解析、另外解答與來源；前後題、跳題及繼續上次可用，且閱讀不增加作答次數或正確率。
3. 題庫練習選錯後同時顯示使用者選項、正解、解析與來源，並進錯題簿。
4. 全題庫依序練習不計時、不亂數抽題、不打亂選項，完全保留發行題庫陣列順序；離開 App 後可從獨立保存的位置繼續，且不覆蓋課程閱讀位置。
5. 錯題在錯題複習答對 1 次即移出；若在錯題複習中答錯，須重新連續答對 2 次，期間再答錯須歸零。舊版已答對 1／2 次的錯題升級後立即移出清單，但保存原作答紀錄。其他練習或模擬測驗答對不得意外清除錯題，歷史作答統計不得改寫。
6. 正式模擬固定抽 80 題（06100 取 64 題，90006～90009 各取 4 題）、限時 100 分鐘；未交卷可恢復，交卷前不揭露答案，允許空白題交卷，時間到自動交卷，交卷後分數與逐題結果固定。
7. iPhone 從「繼續學習」進題目後可直接切其他 tab。
8. iPad 從同一路徑可用 sidebar 切換，detail 不殘留題目 stack。
9. bundle B 新增／修訂／下架題目後，UserStore 紀錄完整。
10. content decode／migration／磁碟錯誤不建立空 store 覆蓋資料。
11. 飛航模式重啟，除使用者主動開啟來源網址外不需要網路。
12. 正式 bundle 不含 synthetic fixture、原始題庫、私有路徑或審查資料。

## 裝置矩陣

### 每個 PR

- iPhone 17 Pro simulator，latest CI runtime。
- iPad Air simulator，latest CI runtime。
- generic iOS Simulator Release build。

### 每週／Release Candidate

- iOS 26.1 與 26.5 本機 simulator。
- 小尺寸 iPhone／大型 iPhone、iPad 11／13 inch、iPad split view。
- 實體 iPhone 一台、實體 iPad 一台；至少一台由上一個 signed build 升級到 RC。

Deployment target 為 17.0，因此送審前仍須補 iOS 17 實體或可用 runtime 相容證據；現有機器盤點只有 iOS 26.1／26.5 simulator，不能把編譯通過誤當最低版本 UI 驗證。

## 升級資料保留證據

測試 A build 建立：每種作答、錯題、收藏、筆記、未完成模考、已完成模考與最後閱讀位置。用更高 build 的 B 安裝覆蓋，產生去識別 JSON 摘要，逐欄比對數量與 stable IDs；再完成一次 B 新題作答。不得先刪 App，也不得用合成 upgrade 模型取代唯一的 signed 真機 gate。

## 效能門檻（初版）

- 正式題庫冷載入目標 < 2 秒；超過時以 background decode／index 優化，不先引入後端。
- 題目切換與本機搜尋維持可感知即時，無長時間主執行緒阻塞。
- 連續 30 分鐘練習／模考無 crash、hang、記憶體持續成長或電量異常。
- 大圖需預縮放；不將 PDF／原始掃描整包放入 release。

## 發布停止條件

任何資料遺失、題庫答案衝突、未授權內容、敏感資料命中、真機 crash、計分錯誤或 accessibility 核心阻塞都停止發布；時程不能降級這些 gate。
