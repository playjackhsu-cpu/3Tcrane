# Content boundary

`Content/` 只放已核准公開、可隨 App 發行的資料：

- `Schema/`：公開資料契約。
- `Fixtures/`：完全合成的 CI／UI 測試資料。
- `Releases/`：通過內容、來源、授權與 QA gate 的 App 內建題庫。

原始 PDF、Office 文件、掃描圖、OCR 中間檔、授權證明與內部定位資料必須放在 `PrivateResources/` 或 repo 外，不得提交。
