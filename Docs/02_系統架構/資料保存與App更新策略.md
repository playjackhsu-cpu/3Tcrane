---
title: 資料保存與 App 更新策略
tags: [persistence, migration, app-update, swiftdata]
status: accepted
updated: 2026-08-10
---

# 資料保存與 App 更新策略

## 能否在更新 App 時保留學習紀錄？

可以。正常 App Store／TestFlight 升級會替換 App bundle，App container 中的 Application Support 資料是另一個位置。本專案仍不只依賴平台行為，而以資料分離、schema migration、備份與升級測試形成可驗證保護。

> 限制：使用者刪除 App 通常會刪除其 container；「更新保留」不等於「解除安裝後可恢復」。跨裝置與刪除後復原不是 MVP 承諾。

## 儲存分區

| 資料 | 位置 | 更新行為 | 備份 |
| --- | --- | --- | --- |
| 題庫／解析／公開來源 | App bundle `QuestionBank.json` | 隨新 App 被替換 | 可由 App 重建，不需要備份 |
| 題庫圖片 | App bundle asset | 隨新 App 被替換 | 可由 App 重建 |
| 作答／錯題／收藏／筆記 | Application Support `LearningStore` | 保留並 migration | 由系統例行備份 |
| 暫存搜尋 index | Caches | 可被系統清除 | 不備份、可重建 |
| QA／診斷暫存 | tmp／Caches | 可清除 | 不備份 |

Apple 建議 App 運作所需但不應公開顯示的支援資料放 Application Support；該目錄位於 App sandbox，且一般會納入系統備份。參考：[Using the file system effectively](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively)、[`applicationSupportDirectory`](https://developer.apple.com/documentation/foundation/url/applicationsupportdirectory)。

## UserStore 最小模型

- `QuestionProgress`: questionID、attemptCount、correctCount、lastAnswer、lastAnsweredAt、masteryState。
- `Favorite`: questionID、createdAt。
- `QuestionNote`: questionID、text、updatedAt。
- `ExamAttempt`: stable UUID、contentVersion、startedAt、submittedAt、score、duration、question snapshots。
- `AppState`: current session／last question、streak、migration version。

ExamAttempt 保存必要題目快照，避免新版題庫修訂後舊成績失去當時上下文；快照不可包含私有來源欄位。

## 升級流程

1. 以 read-only 方式驗證新 bundle schema／content version。
2. 開啟現有 UserStore，執行明確 migration plan；禁止 delete-and-recreate。
3. 以穩定 question ID 對帳；不存在的題目標示 orphaned，不刪紀錄。
4. migration 完成後才更新 `lastOpenedAppBuild`／`lastSeenContentVersion`。
5. 失敗時保留原 store、記錄安全錯誤並停止寫入；不以空 store 繼續。

## 必要自動測試

- Fresh install：空 UserStore + bundle A。
- Upgrade A→B：建立所有類型紀錄，換 bundle／schema 後完整保留。
- Content removal：B 少一題，舊進度仍存在且 UI 可說明已下架。
- Content revision：同 ID 題幹小改，歷史成績不被重新計分。
- Migration interruption：在 migration 中斷，原 store 可重新開啟。
- Disk full／decode failure：不得建立空資料覆蓋原 store。
- App rollback model：舊程式遇到較新 schema 必須 fail safely；App Store 真正回復需以更高 build 重新發布已知良好程式。

## 可選的第二階段保護

加入使用者主動匯出／匯入加密備份，或採 CloudKit／iCloud。這會增加隱私、衝突處理與測試成本，需另立 ADR，不在 MVP 偷渡實作。
