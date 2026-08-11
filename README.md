# 3Tcrane

三噸以上固定式起重機考照學習系統的 iPhone／iPad 原生 App 專案。

目前已建立第一階段 SwiftUI Universal App 與自動測試骨架。專案採離線優先：題庫隨 App 發行，學習紀錄只存於 App 的獨立本機資料庫；未規劃線上題庫更新、會員後端或遠端同步。

## 文件入口

- [Obsidian 專案首頁](Docs/README.md)
- [開發計劃書](Docs/05_iOS開發/開發計劃書.md)
- [系統架構與沿用策略](Docs/02_系統架構/系統架構與沿用策略.md)
- [資料保存與 App 更新策略](Docs/02_系統架構/資料保存與App更新策略.md)
- [GitHub 公開倉庫治理](Docs/00_專案治理/GitHub公開倉庫治理.md)
- [Apple 發布規劃](Docs/07_發布與維運/Apple發布規劃.md)
- [App Store 上架文案](Docs/07_發布與維運/AppStore上架文案.md)

## 公開倉庫警示

本倉庫預定公開。不得提交題庫原始檔、未確認授權的教材、答案來源原稿、個資、內網資訊、Apple 憑證、簽章檔、token、`.env`、正式資料庫或建置產物。原始資源一律放入已忽略的 `PrivateResources/`，只有通過治理的發行 JSON 與可公開素材可以進入 Git。

## 專案狀態

目前 App 只使用公開合成題目，可在 iPhone 五分頁與 iPad 側欄完成最小作答流程。題庫 repository、SwiftData 學習紀錄、更新重開保留測試、iPhone／iPad UI smoke 與無簽章 Release build 已建立；正式題庫在內容、權利與 QA gate 通過前不會放入公開發行包。

下一個實作里程碑是完成收藏、錯題本、筆記、模擬考與完整統計，並補齊 Dark Mode、Dynamic Type、VoiceOver、iPad 多工及實機驗證。
