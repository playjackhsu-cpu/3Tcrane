# Private resources — never commit files from this directory

此目錄供本機放置：題庫原始 PDF／Office 文件、OCR 中間檔、授權證明、內部來源定位、未公開設計素材與人工審查證據。

`.gitignore` 只允許本說明檔進入 Git。正式 App 所需內容必須經去識別、授權與內容治理後，輸出到 `Content/Releases/`；不得直接讓 Xcode 讀取本目錄。

- `QuestionBank-Inbox/`：原始題庫、OCR 證據與逐題審查台帳。
- `UIUX-Inbox/`：完整素材包、畫面 mockup 與尚未清權的設計來源。
