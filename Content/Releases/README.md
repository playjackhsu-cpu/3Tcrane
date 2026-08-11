# Governed releases

正式題庫版本檔未建立。每個 release 必須：

1. 符合 `Content/Schema/question-bank.schema.json`。
2. 只含已核准可公開內容，不含匯入檔路徑、頁碼截圖、審查者個資或內部備註。
3. 有內容版本、題數、SHA-256、來源／權利摘要與人工核准紀錄。
4. 通過 `Scripts/ci/validate_question_bank.py` 與 App 升級保留測試。
