---
title: App Store 上架文案
tags: [apple, app-store, metadata, listing]
status: release-candidate
updated: 2026-09-14
---

# App Store 上架文案

本文件是繁體中文（台灣）首發版的可貼用文案。它只描述實際已實作的離線功能；「自動更新」指使用者啟用 iOS App 自動更新後，透過新版 App 取得重新整理的內建題庫，不代表 App 會連線即時同步題庫。

## 商品資訊

| 欄位 | 正式候選值 | Apple 限制／檢核 |
| --- | --- | --- |
| App 名稱 | 起重機考照通－三噸以上固定式起重機 | 已建立 App record |
| 副標題 | 固定式起重機單一級技能檢定 | 13 字；上限 30 字元 |
| 主要類別 | 教育 | 與學習用途一致 |
| 次要類別 | 參考 | 題庫與法規參考 |
| 首發地區 | 台灣 | 只提供繁體中文 |
| 價格 | 免費 | App Store Connect 175 個國家／地區價格均為 0.00；首發供應地仍為台灣 |
| Copyright | © 2026 TaurusWinner. All rights reserved. | 草案；送審前由 Owner 確認權利主體 |
| 發布方式 | 手動發布 | App Review 通過後仍需 Owner 核准 |

## 宣傳文字

> 固定式起重機操作單一級技能檢定複習工具：課程閱讀、逐題解析、錯題複習與模擬測驗。啟用 iOS 自動更新後，可隨新版 App 取得依官方最新公布題庫整理的內建內容，並保留裝置內的學習紀錄。

共 93 字元，低於 170 字元上限。

## 關鍵字

```text
固定式起重機,技能檢定,單一級,三噸,考照,題庫,模擬測驗,錯題,職安,吊掛
```

UTF-8 共 96 bytes，低於 Apple 的 100 bytes 上限；包含「固定式起重機」、「技能檢定」與「單一級」。App 名稱已有「三噸以上」及「起重機」，因此關鍵字欄位以不重複搜尋意圖為主。

## App 說明

```text
準備三噸以上固定式起重機操作單一級技能檢定，用「起重機考照通」依固定進度閱讀課程、練習題目並檢視學習成果。

主要功能
• 課程學習：依科目與章節固定順序閱讀題目、答案、解析、另解與公開來源，不必先作答，也不會污染作答統計。
• 題庫練習：選答後立即判定，建立個人練習紀錄。
• 全題庫依序練習：不限時間，完全依題庫原始題序與選項順序作答；離開後會保存目前位置，選答後立即顯示正確答案與解析。
• 錯題複習：集中重做答錯的題目；每題須連續答對 3 次才會移出，中途答錯即歸零重新計算。
• 模擬測驗：提供 80 題／100 分鐘正式模式，以及 10 題／10 分鐘快速測驗。
• 收藏與筆記：標記重點，在裝置內建立自己的複習資料。
• iPhone 與 iPad：同一套學習內容支援手機和平板，並提供明亮與暗色模式。
• 離線使用：題庫內建於 App，無需帳號或網路即可學習。
• 題庫更新保留紀錄：啟用 iOS App 自動更新後，可隨新版 App 自動取得依官方最新公布題庫重新整理的內建內容；題庫與學習紀錄分開保存，安裝新版不會以題庫覆蓋進度、錯題、收藏、筆記與測驗紀錄。
• 內容治理：官方最新版已刪除、答案／題意衝突及法規生效過渡題目會另外標示，不納入一般抽題。

隱私設計
App 不要求登入，不含廣告、追蹤或分析 SDK；學習紀錄只保存在裝置內。

重要聲明
本 App 為獨立學習工具，並非勞動部、技能檢定中心或其他政府機關之官方 App，也不保證通過檢定。題庫、法規與測試規定如有異動，以主管機關最新公告為準。本 App 不取代依法應完成的訓練、現場指導、實機操作或安全程序。
```

## App Review 備註

```text
This app does not require an account, sign-in, subscription, in-app purchase, or backend service. All study content is bundled with the app and works offline. User progress, wrong-answer records, favorites, notes, and exam history are stored only in the app's local Application Support data store and are separate from the bundled question bank so that app updates preserve learning records.

Suggested review path:
1. Open 課程 and select a chapter to read questions, answers, explanations, alternate explanations, and public sources without changing answer statistics.
2. Open 測驗 > 全題庫依序練習. This untimed mode preserves the bundled question and option order, shows the correct answer and explanation immediately, and saves the next position locally.
3. Answer a question incorrectly, then open 測驗 > 錯題複習. A wrong item is removed only after three consecutive correct answers in wrong-answer review; any incorrect answer resets the streak to zero.
4. Open 測驗 > 模擬測驗 to try the 10-question quick mode. The 80-question mode follows the fixed-crane skill-test composition and has a 100-minute timer.
5. Open 首頁 > 官方題庫例外審查 to expand the separately governed deleted, disputed, and legal-transition items. These items are excluded from normal random selection.

The app is an independent study tool and is not affiliated with or endorsed by Taiwan's Ministry of Labor or Skills Evaluation Center. It does not replace legally required training or practical operation.
```

Review 聯絡人姓名、電話與 Email 屬 App Store Connect 私密欄位；不得從 TestFlight 測試名單推定或將測試者資料改作聯絡資料，須由 Owner 在正式送審前提供。

## What's New（1.0）

```text
首個正式版本：提供固定式起重機操作單一級技能檢定的課程閱讀、題庫練習、錯題複習、收藏筆記、學習紀錄與正式／快速模擬測驗。題庫內建、可離線使用，學習紀錄與 App 內容分開保存。
```

## What's New（1.0.1）

```text
新增全題庫依序練習：不限時間，題目與選項完全依內建題庫原始順序呈現，並保存下次續作位置；作答後立即顯示正確答案與解析。錯題複習改為每題連續答對 3 次才移出，中途答錯會歸零重新計算。既有進度、錯題、收藏、筆記與測驗紀錄均保留。
```

## URL

- 隱私權政策：`https://playjackhsu-cpu.github.io/3Tcrane/privacy/`
- 使用者支援：`https://playjackhsu-cpu.github.io/3Tcrane/support/`
- 行銷 URL：首版留空；不為了填欄位建立多餘追蹤頁。

URL 只能在 GitHub Pages workflow 合併、部署且以未登入瀏覽器驗證成功後填入 App Store Connect。

## 不得使用的宣稱

- 不寫「官方 App」、「官方授權」或「保證通過」。
- 不寫「即時同步官方題庫」或「App 內自動下載題庫」。
- 不把 `official-reference-reviewed` 描述為官方認證、正式測試答案或逐題獨立技術驗證。
- 不宣稱 App 能取代訓練、證照、實機操作、安全程序或主管機關公告。

## 送審前 Owner gate

1. 依 [[Docs/04_題庫與內容/官方題庫授權評估]] 回讀顯名、非背書與特別權利排除條件，再由 Owner 完成 App Store Content Rights 最終確認。
2. 以正式 release candidate binary 重做內容、隱私、年齡分級、升級保留、iPhone／iPad 與無障礙 QA。
3. 提供 App Review 私密聯絡人姓名、電話與 Email。
4. 明確核准「加入以供審查」及 App Review 通過後的手動發布。
