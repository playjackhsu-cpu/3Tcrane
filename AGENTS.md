# 3Tcrane Codex 工作規範

## 開始工作前

1. 完整閱讀：
   - `Docs/README.md`
   - `Docs/00_專案治理/專案章程.md`
   - `Docs/00_專案治理/GitHub公開倉庫治理.md`
   - `Docs/00_專案治理/內容與資料治理.md`
   - `Docs/09_工作紀錄/CURRENT_STATE.md`
2. 執行 `git status --short`、`git branch --show-current`、`git remote -v`。
3. 工作樹可能有使用者變更，不得 reset、checkout、clean 或覆蓋既有內容。

## 永久治理邊界

- 本專案是公開 GitHub 倉庫；所有將提交的內容都視為會被永久公開、複製與索引。
- 不得提交 `PrivateResources/` 內檔案、題庫原始 PDF／Office 文件、未授權教材、個資、內網位址、主機名稱、憑證、token、密碼、`.env`、簽章檔、正式資料庫、備份或 Xcode 使用者狀態。
- 題庫必須保留穩定 ID、答案、解析、另外解答、公開來源與內部匯入來源的分層；內部來源定位不得進入公開發行包。
- 法規、安全規範與考照答案若有衝突，保留證據並停止內容發布，不可用推測覆蓋原始資料。
- 題庫只隨 App 更新；不得自行加入遠端題庫下載、會員後端、追蹤 SDK、廣告、StoreKit 或雲端同步。
- 學習紀錄必須與 App bundle／題庫資料分離；任何 schema 或發版變更都要有升級保留測試。
- 未完成 QA 與明確授權前，不得推送、建立 PR、設定 GitHub 遠端規則、上傳 TestFlight 或送出 App Review。

## 提交前

1. 執行 `bash Scripts/ci/check_public_repo.sh`。
2. 題庫有變更時執行 `python3 Scripts/ci/validate_question_bank.py`。
3. 執行 `python3 Scripts/ci/check_markdown_links.py`。
4. App 已建立後執行 unit test、iPhone／iPad build 與 upgrade persistence test。
5. 更新 `Docs/09_工作紀錄/CURRENT_STATE.md` 與 `Docs/09_工作紀錄/CHANGELOG.md`。
