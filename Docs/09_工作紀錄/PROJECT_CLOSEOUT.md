---
title: 3Tcrane 專案結案總結報告
aliases: [起重機考照通結案報告, 3Tcrane Project Closeout]
tags: [closeout, handover, archive, app-store]
status: awaiting-app-review
updated: 2026-08-11
---

# 3Tcrane 專案結案總結報告

## 一、結案摘要

3Tcrane 已完成一套支援 iPhone 與 iPad 的原生離線考照學習 App，正式名稱為「起重機考照通－三噸以上固定式起重機」，技術基線為 SwiftUI、SwiftData 與 iOS／iPadOS 17 以上 Universal App。

首發版本為 `1.0.0`（build 6），售價為免費，供應地設定為台灣。正式發行包已完成簽章、內容、隱私、iPhone、iPad、升級保留及公開倉庫治理檢查，並已於 2026-08-11 送交 Apple；App Store Connect 現行狀態為「正在等待審查」。Apple 核准後採手動發佈，不會自動上架。

## 二、產品成果

### 2.1 核心功能

- 課程學習：依科目與章節固定順序閱讀題目、答案、解析、另解與公開來源，不要求先作答，也不影響作答統計。
- 題庫練習：選答後立即判定並保存學習進度。
- 錯題複習：集中重新作答錯題，保存熟練狀態。
- 模擬測驗：提供 80 題／100 分鐘正式模式及 10 題／10 分鐘快速模式。
- 收藏與筆記：以穩定題目 ID 保存個人複習內容。
- 學習記錄：保存題目進度、錯題、收藏、筆記、測驗與學習天數。
- 治理例外：首頁可展開檢視官方刪題、答案／題意衝突與法規生效過渡題目。
- 裝置支援：iPhone 使用五分頁導覽，iPad 使用側欄與內容區；支援 Light／Dark Mode。
- 離線使用：無帳號、無後端、無廣告、無追蹤或分析 SDK。

### 2.2 題庫內容

| 類別 | 數量 | 發行處理 |
| --- | ---: | --- |
| 完整歷史清冊 | 1,000 題 | 私有治理層完整保留 |
| 一般學習與抽題 | 983 題 | 納入正式 App |
| 官方最新版刪題 | 8 題 | App 內另列，不參與抽題 |
| 明顯答案／題意衝突 | 5 題 | App 內另列並顯示現行判定 |
| 法規生效過渡 | 4 題 | App 內另列並說明過渡原因 |
| 題目圖像 | 15 個 | 納入正式發行包 |

正式內容版為 `0.2.1`。題庫一般抽題池與 17 題治理例外互斥，App 載入時會驗證穩定 ID、題目欄位、例外分類與來源資料。正式題庫 JSON 的 SHA-256 為：

`7399af027135ea462811d55bdc3f91dccefaf967dca7b92065aea7cfbcaaed15`

## 三、架構與資料保存

### 3.1 最小原生架構

- UI：SwiftUI。
- 本機資料：SwiftData。
- 題庫：隨 App bundle 發行，不提供遠端下載。
- 學習資料：保存於 App Application Support，與 bundle 題庫分離。
- 第三方 runtime dependency：無。
- 網路服務：MVP 無會員後端、雲端同步、廣告或分析服務。

### 3.2 App 更新保留學習紀錄

題庫為唯讀 bundle 資源，學習紀錄為獨立永久 store。題目以穩定 ID 關聯；App 更新不覆蓋進度、錯題、收藏、筆記與測驗紀錄。A 版建立資料後以 B 版重新開啟的測試已確認五類資料皆保留；題目下架後，既有孤兒紀錄仍可讀取。

## 四、UI／UX 與裝置驗證

- 首頁、課程、測驗、紀錄、設定及例外審查均已完成。
- iPad sidebar 寬度採 240 至 280 pt、理想 260 pt 的 balanced split view。
- 17 題治理例外預設收合，避免首頁過長，使用者點擊後才展開完整理由與答案。
- 品牌語意色具 Light／Dark 動態值，主要文字、次要文字與互動色有 4.5:1 對比 gate。
- 已在連接的 iPhone 11 與 iPad 完成 Dark Mode 前景啟動 smoke；QA App 使用不同 Bundle ID，不覆蓋 TestFlight App 或既有學習紀錄。
- 尚未完整驗證的延伸項目為 High Contrast、最大 Dynamic Type、完整 VoiceOver、全橫向／多工與更多實機型號；不影響目前已通過的核心流程。

## 五、QA 與發行證據

### 5.1 正式 Release QA

- Unit／升級保留測試：14／14 通過。
- iPhone UI：5 項通過、2 項依裝置／內容條件跳過、0 失敗。
- iPad UI：6 項通過、1 項依裝置／內容條件跳過、0 失敗。
- iPhone／iPad Release build：通過。
- 正式 bundle：983 題、17 題例外、15 個題圖。
- 正式 bundle 只含 release JSON，不含合成 fixture、私有來源定位或原始 PDF。

### 5.2 簽章與安裝檔

- App 版本：`1.0.0`。
- Build：`6`。
- Bundle ID：`tw.tauruswinner.crane.study`。
- `get-task-allow=false`。
- `beta-reports-active=true`。
- `ITSAppUsesNonExemptEncryption=false`。
- IPA SHA-256：`387e4760befc9c2a5605a2aed94b8ce6b5bc570af5224c07fa2c6f7f95996921`。

## 六、Apple 發佈狀態

| 項目 | 結案狀態 |
| --- | --- |
| App Store 版本 | 1.0.0（build 6） |
| 售價 | 免費 |
| 供應地 | 台灣 |
| App Privacy | 已發佈「不收集資料」 |
| 登入需求 | 不需要登入 |
| Content Rights | 已確認具有第三方內容必要權利 |
| 審查聯絡資料 | 已由 Owner 確認並填入 App Store Connect |
| 審查狀態 | 正在等待審查 |
| 核准後發佈 | 手動發佈 |

Apple 核准後必須由 Owner 在 App Store Connect 按下「發佈此版本」，App 才會正式出現在商店。若 Apple 提出問題，應保留原訊息與附件，先記錄於工作紀錄，再建立修正分支與新版 build；不得直接覆蓋既有學習資料模型或重用題目穩定 ID。

## 七、GitHub 與公開治理

- 遠端：`git@github.com:playjackhsu-cpu/3Tcrane.git`。
- `main` 已啟用 Ruleset：禁止刪除與 force push，要求 PR、最新分支、linear history、對話解決及五道必要檢查。
- PR #1 已合併至 `main`，建立公開治理基線。
- PR #6 為 App Store `1.0.0` release candidate，結案時維持 Draft／未合併，merge state 為 clean。
- PR #6 的 Governance、Unit tests、Release build、iPhone UI smoke 與 iPad UI smoke 均通過。
- 私有題庫、原始 PDF、Apple 簽章、審查聯絡資料、裝置識別資訊、正式 archive／IPA 與測試者資料未進入公開 Git。

## 八、文件與資源分層

### 8.1 公開可維護內容

- `Docs/`：Obsidian 專案、架構、題庫、QA、Apple、決策與工作紀錄。
- `ThreeTCraneStudy/`：App 原始碼與正式 bundle 資源。
- `ThreeTCraneStudyTests/`、`ThreeTCraneStudyUITests/`：unit、升級保留與 UI smoke。
- `Content/Releases/`：治理後正式題庫與題圖。
- `Assets/UIUX/Production/`：核准使用的 App 素材。
- `Scripts/ci/`：公開資料、題庫與文件 gate。

### 8.2 私有封存內容

- 題庫原始 PDF、掃描影像、OCR、逐題審查證據、衝突與未納入清單。
- UI／UX 原始素材包及未公開參考檔。
- TestFlight 私有題庫組合、Apple 簽章 archive／IPA、測試結果與上架截圖。
- 私有內容只能留在受控 NAS 或本機忽略區，不得加入公開 Git。

## 九、專案歷程摘要

### 2026-08-10

- 建立 Obsidian 文件框架、公開 Git 治理、SwiftUI／SwiftData 架構與題庫 schema。
- 收件掃描題庫與 UI 素材，建立私有 OCR、來源與逐題審查流程。
- 取得技能檢定中心官方 PDF，建立 1,000 題基準並開始官方資料優先審查。

### 2026-08-11

- 完成 1,000 題第一輪資料審查、983 題正式候選與 17 題例外治理。
- 完成 iPhone／iPad App、Taiwan_Wtsbot 式課程分流、模擬測驗、學習紀錄及更新保留。
- 完成 iPad 比例、暗色模式、例外卡收合與連接實機 smoke。
- 完成 GitHub Ruleset、PR／CI、Pages 隱私權與支援頁。
- 完成 Internal TestFlight 多版驗證，以及 App Store `1.0.0`（build 6）簽章、截圖、文案、免費價格與正式送審。

## 十、後續必要工作

1. 等待 Apple 審查結果。
2. Apple 核准後由 Owner 手動發佈版本 1.0.0。
3. 由 Owner 核准並合併 PR #6；不得繞過 `main` Ruleset。
4. 官方題庫或法規後續更新時，重新執行來源比對、17 題例外審查、題庫 validator、升級保留與雙平台 QA，再以新版 App 發行。
5. 若繼續開發，先從本報告、`CURRENT_STATE.md`、`CHANGELOG.md` 與 NAS 封存清冊恢復上下文。

## 十一、還原與接手順序

1. 從 NAS 讀取封存根目錄的 `README_封存說明.md` 與 `SHA256SUMS.txt`。
2. 使用 Git bundle 還原完整版本歷史，或從公開 GitHub clone 後切換 release branch。
3. 將私有資源還原至 `PrivateResources/`，不得加入 Git。
4. 將最終發行與 QA 產物還原至 `Artifacts/`，不得加入 Git。
5. 執行公開倉庫 gate、題庫 validator、文件連結檢查及 iPhone／iPad 測試。
6. 重新簽章時只使用本機 Keychain／Apple 帳號；NAS 封存不包含私鑰或密碼。

## 十二、結案判定

程式、內容、文件、測試、公開治理與 Apple 送審均已完成至「等待審查」階段，專案可進入封存與低維護狀態。尚未發生的外部事件只有 Apple 審查結果、核准後手動發佈及 PR #6 的 Owner 合併核准。

本專案最重要的永久邊界仍為：公開 Git 不得含私有題庫、原始教材、個資或 Apple 簽章；題庫只隨 App 更新；學習紀錄與 bundle 題庫保持分離；安全或法規答案衝突不得以推測覆蓋官方原始資料。
