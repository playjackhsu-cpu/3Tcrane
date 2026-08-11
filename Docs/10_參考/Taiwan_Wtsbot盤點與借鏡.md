---
title: Taiwan_Wtsbot 盤點與借鏡
tags: [reference, reuse, taiwan-wtsbot]
status: reviewed
updated: 2026-08-10
---

# Taiwan_Wtsbot 盤點與借鏡

## 參考基線

「設計污水檢定複習系統06」交接摘要顯示：App/package 3.0.002、正式內容 3.0.021、複習 3,309、測驗 3,797，並已形成題庫、答案／解析／來源、iPhone／iPad、學習紀錄與發布治理。其完整系統同時含 Web／Bot／會員／付款／同步／遠端內容與多平台能力，遠大於本專案需求。

盤點 Taiwan_Wtsbot 目前工作樹時發現有既存未提交變更，因此全程只讀，未修改、未複製其工作樹內容，也不以當下 dirty file 當作新的 3Tcrane 權威來源。

## 主要參考位置（Taiwan_Wtsbot repo 內）

- `Docs/QUESTION_BANK_SCHEMA.md`：題目、答案、解析、來源與 OCR 治理。
- `Docs/mobile-app/MOBILE_DATA_PACKAGE_SCHEMA.md`：stable ID、package contract 與 failure-atomic 思路。
- `Docs/mobile-app/MOBILE_RELEASE_RUNBOOK.md`：iPhone／iPad、App／content version、QA／release gate。
- `mobile/ios/TaiwanWtsbotStudy/Models.swift`：題庫、作答、模考模型概念。
- `mobile/ios/TaiwanWtsbotStudy/ContentView.swift`：Universal App 導覽概念。
- `mobile/ios/TaiwanWtsbotStudy/ExamViews.swift`、`ReviewViews.swift`：作答與複習產品流程。
- `mobile/ios/TaiwanWtsbotStudy/OfflineStore.swift`：本機紀錄能力；檔案近 6,000 行，不能直接搬入最小 App。

## 沿用

- stable question ID／public code。
- 答案、解析、另外解答、公開來源獨立顯示。
- iPhone Tab 與 iPad persistent Sidebar 的共用功能 view。
- 錯題、掌握度、模考歷史、版本顯示與 upgrade QA。
- `ReviewView` 的閱讀式複習：選科目、依穩定題序閱讀、直接分段顯示答案／解析／另外解答／來源、前後題、跳題、繼續上次與記憶題。
- `SelfCheckView`／`ExamView` 與閱讀式複習分離；只有作答流程更新正確率與錯題，單純閱讀不計為答對。
- 正式內容不得因 UI／發版重建使用者資料。

## 明確不沿用

- Next.js、API、Telegram、會員、Apple／Email 登入、session、StoreKit、付款。
- 遠端 manifest、full／delta package、premium content delivery、同步 outbox／inbox。
- Widget、Android、admin、production DB、deployment／monitoring。
- 原專案題庫內容、品牌資產、憑證、環境設定與正式資料。

## 結論

3Tcrane 應借鏡「治理與使用者流程」，而不是 fork／rename Taiwan_Wtsbot。新 App 以約 7 個 feature、2 個 repository、1 個 SwiftData store 與 3 個 test target 起步，能保留最有價值的成熟邏輯而避免不需要的營運負擔。

3Tcrane 的「課程」在產品語意上等同 Taiwan_Wtsbot 的「複習」，不是四選一測驗的另一個入口。題目、答案、解析與來源可共用資料模型，但課程閱讀、題庫測驗與模擬測驗必須維持三套揭露規則。
