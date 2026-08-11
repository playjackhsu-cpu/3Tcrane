# Security Policy

## 回報安全問題

請不要用公開 Issue 張貼憑證、token、個資、題庫原始檔或可利用細節。請改用 GitHub Security Advisory 的 private vulnerability reporting；若該功能尚未啟用，請先只建立不含敏感資訊的聯絡請求，由維護者提供私下通道。

## 公開倉庫資料事件

若敏感資料曾進入 commit：

1. 立即撤銷／輪替相關憑證；刪除檔案不能讓已公開的秘密恢復安全。
2. 暫停合併與發布，記錄暴露範圍。
3. 清理 Git 歷史並通知所有已知 clone 使用者更新。
4. 重新執行秘密掃描、公開資料檢查與發布 gate。

完整規範見 [GitHub 公開倉庫治理](Docs/00_專案治理/GitHub公開倉庫治理.md)。
