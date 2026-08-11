---
title: 3Tcrane 專案首頁
aliases: [三噸起重機學習系統, 起重機考照通]
tags: [3tcrane, ios, ipad, iphone, project-home]
updated: 2026-08-11
---

# 3Tcrane 專案首頁

本資料夾是 Obsidian vault。產品目標是以最小原生 SwiftUI 開發量，建立支援 iPhone／iPad 的「三噸以上固定式起重機考照學習系統」，題庫隨 App 發行，學習紀錄離線保存。

## 專案導覽

- 治理：[[Docs/00_專案治理/專案章程]]、[[Docs/00_專案治理/GitHub公開倉庫治理]]、[[Docs/00_專案治理/內容與資料治理]]
- 產品：[[Docs/01_產品規格/產品需求書]]
- 架構：[[Docs/02_系統架構/系統架構與沿用策略]]、[[Docs/02_系統架構/資料保存與App更新策略]]
- 設計：[[Docs/03_UI_UX/設計系統]]
- 題庫：[[Docs/04_題庫與內容/題庫資料規格]]、[[Docs/04_題庫與內容/OCR與逐題審查流程]]
- 開發：[[Docs/05_iOS開發/開發環境盤點]]、[[Docs/05_iOS開發/開發流程與CI_PR]]、[[Docs/05_iOS開發/開發計劃書]]
- 測試：[[Docs/06_QA與測試/QA測試計劃]]
- 發布：[[Docs/07_發布與維運/Apple發布規劃]]、[[Docs/07_發布與維運/TestFlight測試版交付清單]]
- 決策：[[Docs/08_風險與決策/風險登錄表]]、[[Docs/08_風險與決策/ADR-001-離線題庫與獨立學習紀錄]]
- 現況：[[Docs/09_工作紀錄/CURRENT_STATE]]、[[Docs/09_工作紀錄/CHANGELOG]]
- 參考：[[Docs/10_參考/Taiwan_Wtsbot盤點與借鏡]]

## 現行產品基線

| 項目 | 決策 |
| --- | --- |
| 正式名稱 | 三噸以上固定式起重機考照學習系統 |
| App 顯示名稱 | 起重機考照通 |
| 平台 | iOS／iPadOS Universal App |
| 最低系統 | iOS／iPadOS 17.0 |
| 技術 | SwiftUI + SwiftData，無第三方 runtime dependency |
| 題庫 | 隨 App bundle 發行，不提供線上更新 |
| 學習紀錄 | App container 的 Application Support／SwiftData，與題庫分離 |
| 帳號／伺服器 | MVP 不提供 |
| GitHub | 公開倉庫；所有 push 預設按永久公開處理 |
| 遠端 | `git@github.com:playjackhsu-cpu/3Tcrane.git`（2026-08-11 已建立空白 `main` PR 基準；專案內容一律由功能分支經 CI／PR 進入） |

## 開放事項

- 私有 1,000 題已完成官方來源第一輪資料審查；983 題為正式內容候選、17 題列入例外清單，但內容權利、獨立來源與解析編審尚未全數通過，因此目前仍無正式題目可發行。
- 高解析 UI 素材包已分層；可用 Asset Catalog 與色票已進 `Assets/UIUX/Production/`，Dark／High Contrast 與 App 內視覺驗證待完成。
- 正式題庫科目、題數、考試抽題規格與內容權利，需在內容審查完成後確認。
- 公開倉庫 LICENSE 尚未由 Owner 選定，不阻塞本機開發但阻塞「開源」宣告。
