---
title: GitHub 公開倉庫治理
tags: [github, security, ci, pr, public-repository]
status: required
updated: 2026-08-10
---

# GitHub 公開倉庫治理

## 核心原則

遠端為 `git@github.com:playjackhsu-cpu/3Tcrane.git`。2026-08-10 以唯讀方式確認遠端可存取且尚無 refs，可視為空倉庫。任何 commit／PR／Actions log 都按「可能永久公開」處理；刪除檔案不能撤回已被 clone 或索引的資料。

## 禁止進入 Git 的內容

| 類別 | 例子 | 正確位置 |
| --- | --- | --- |
| 秘密 | token、密碼、`.env`、API key | Keychain／GitHub Actions secrets；本專案 MVP 不需 runtime secrets |
| Apple 簽章 | `.p8`、`.p12`、profile、private export plist | Apple／本機 Keychain；不進 repo |
| 題庫原始資料 | PDF、Excel、Word、掃描圖、OCR 中間檔 | `PrivateResources/` 或 repo 外 |
| 授權／個資 | 合約、姓名、Email、審查者資料 | repo 外受控資料夾 |
| 正式資料 | SQLite、備份、真實學習紀錄 | App container／repo 外 |
| 內部環境 | 私網 IP、主機名、本機絕對路徑 | 不寫入公開文件／log |
| 建置產物 | archive、IPA、dSYM、xcresult | GitHub Release private evidence 或受控外部封存；不可直接提交 |

`Scripts/ci/check_public_repo.sh` 提供最低自動 gate；GitHub secret scanning／push protection 是第二道防線，不取代提交前人工檢查。

## 允許公開的內容

- Swift 原始碼、合成測試資料、JSON schema、CI 腳本與公開文件。
- 已確認有權公開的 UI 素材。
- 經內容、權利與去識別核准的 App 發行題庫 JSON。
- 官方公開來源 URL；不可把受限制的來源全文複製進 repo。

## 分支與 PR

- 預設分支 `main`，只接受 PR 合併。
- 分支：`feat/*`、`fix/*`、`docs/*`、`content/*`、`release/*`。
- 禁止 force push／delete `main`，要求 linear history、resolved conversations、CODEOWNER review。
- 單人維護初期若 GitHub 無法要求作者自我核准：仍禁止直接推送，改以「CI 全綠＋Owner 在 PR checklist 明示核准」作 gate；有第二位維護者後改為至少 1 個 approving review。
- 題庫、CI、治理、App privacy 或 persistence 變更必須由 CODEOWNER 審查。

## 必要 status checks

| Check | 現階段 | App 建立後 |
| --- | --- | --- |
| `Governance / public-repository-gate` | 必要 | 必要 |
| 題庫 schema／穩定 ID／來源 gate | 必要 | 必要 |
| Swift unit tests | 尚無 target | 必要 |
| iPhone simulator build/test | 尚無 project | 必要 |
| iPad simulator build/test | 尚無 project | 必要 |
| upgrade persistence test | 尚無 project | persistence 變更必跑 |
| CodeQL | 啟用 GitHub default setup | 必要安全告警不得新增 |

Required check 不可用會被 path filter 跳過的 workflow 名稱，避免 PR 永久 Pending。Actions 權限預設 `contents: read`；來自 fork 的 PR 不可取得 signing secrets。

## Push 前 gate

1. `git status --short` 精確檢查 scope。
2. `bash Scripts/ci/check_public_repo.sh`。
3. `python3 Scripts/ci/validate_question_bank.py`。
4. `git diff --check` 與相關測試。
5. 以 `git diff --cached --name-status` 再確認即將公開的檔名。
6. commit 後先開 PR；沒有明確發布授權不得 push tag、建立 Release 或上傳 binary。

## GitHub 設定清單

- 啟用 branch protection／ruleset：PR、required checks、conversation resolution、linear history、禁止 force push／delete、include administrators。
- 啟用 private vulnerability reporting、secret scanning、push protection、CodeQL default setup 與 Dependabot alerts。
- Actions 預設 read-only token；只允許官方或核准 action，重要 action 後續 pin 完整 commit SHA。
- GitHub Pages 僅發布已核准的 Privacy／Support 靜態頁，不曝光 vault 私有附件。

## 資料外洩處置

先撤銷秘密，再清理歷史；不能先把「刪檔」當作修復。暫停 PR／發版，建立 incident 紀錄、清點 clone／Actions artifact／Release，完成輪替與全庫掃描後才恢復。

## 官方依據

- [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub security features](https://docs.github.com/en/code-security/getting-started/github-security-features)
- [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
