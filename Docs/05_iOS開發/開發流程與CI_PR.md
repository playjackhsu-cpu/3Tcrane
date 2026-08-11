---
title: 開發流程與 CI PR
tags: [workflow, ci, pull-request, release]
status: implemented-baseline
updated: 2026-08-11
---

# 開發流程與 CI／PR

## 日常流程

1. 讀 `AGENTS.md`、CURRENT_STATE 與相關規格。
2. 從最新 `main` 建立短分支。
3. 先以合成資料做測試驅動實作；不把私有題庫複製到可追蹤路徑。
4. 本機通過治理、內容與相關 Xcode 測試。
5. 建立小型 PR；一個 PR 不混合「架構、正式題庫、UI 大改、發版」。
6. CI、CODEOWNER、對話與 checklist 全部完成才合併。
7. 更新 CURRENT_STATE／CHANGELOG；release PR 再產生 signed archive。

## PR 類型與額外 gate

| 類型 | 額外證據 |
| --- | --- |
| `docs/*` | 連結、敏感資料、決策一致性 |
| `feat/*`／`fix/*` | unit、iPhone／iPad build／UI smoke |
| `content/*` | 題庫 schema、diff、題數、來源／權利、內容核准 |
| persistence | A→B upgrade、failure、orphan question、rollback model |
| `release/*` | 全 QA、真機、metadata、privacy、archive／codesign、Owner 核准 |

## CI 分層

### Stage 0 — 已建立

`Governance` 在 `ubuntu-latest`：公開檔案邊界、敏感 pattern、題庫 validator、commit whitespace。無 secrets、token 只讀。

### Stage 1 — 已建立

`ios-ci.yml` 使用 GitHub 官方 `macos-26` runner，並指定 runner image 目前提供的 Xcode 26.6：

- 顯示 `xcodebuild -version`，不偷偷下載 toolchain。
- unit tests 使用合成題庫與暫存／in-memory SwiftData，包含 A→B 更新保留。
- iPhone 17 Pro 與 iPad (A16) 的 latest simulator runtime 執行核心導覽／作答 UI smoke；兩種裝置皆是 GitHub `macos-26`／Xcode 26.6 runner 現行映像提供的 latest runtime 型號，避免裝置只存在舊 runtime 而造成假失敗。
- Release build `CODE_SIGNING_ALLOWED=NO`，檢查 warning、Privacy Manifest、bundle resource 與不含私有檔。

CI 不進行簽章、不上傳 TestFlight、不持有 Apple Distribution 憑證。正式簽章與上傳是受控 release workflow，需另行明確授權。

### Stage 2 — 發布成熟後

- CodeQL default setup、Dependabot、每週完整 UI／upgrade matrix。
- 若自動 TestFlight，使用 GitHub Environment `app-store-production`、required reviewer、短效 App Store Connect key；fork PR 永遠不能取得 secrets。
- 自動上傳與 App Review 提交分離，預設 manual release。

## 建議 required checks

固定 job 名稱：Governance workflow 的 `public-repository-gate`，以及 iOS workflow 的 `ios-unit`、`ios-iphone`、`ios-ipad`、`ios-release-build`。不要把 required job 完全 path-filter 掉；不適用時在 job 內回報 neutral／success。

## 首次 Git 發布順序

1. 本機初始化 `main` 與 `origin`，完成公開資料、題庫與文件連結 gate。（已完成）
2. 空倉庫以一次性空白 root commit 建立遠端 `main`，不攜帶專案內容，僅作為首個 PR 的 base。（已完成）
3. 從空白 `main` 建立 `agent/initial-public-baseline`；文件、合成 fixture、CI、可公開素材與 App skeleton 經同一個 Draft PR 接受完整 CI。（進行中）
4. 首個內容 PR 合併前設定 ruleset、安全功能與必要 status checks；後續不得直接推送 `main`。
5. GitHub Pages 只在 Privacy／Support 靜態頁內容另行核准後啟用。

一次性空白 root commit 是空倉庫建立 PR base 的行政例外，不得援引為日後直接推送 `main` 的先例。
