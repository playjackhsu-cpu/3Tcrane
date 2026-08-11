# Governed releases

目前正式候選為 `question-bank.release.json`：

- 內容版本：`1.0.0`
- 一般抽題池：983 題
- 例外審查：17 題（8 題官方刪題、5 題明顯答案／題意衝突、4 題法規過渡）
- 題圖資產：15 個檔案，對應 9 題含圖題
- SHA-256：`7399af027135ea462811d55bdc3f91dccefaf967dca7b92065aea7cfbcaaed15`
- 權利：`official-open-data`；顯名與使用條件見 [[Docs/04_題庫與內容/官方題庫授權評估]]
- 正確性狀態：`official-reference-reviewed`，不得描述為正式測試答案或逐題獨立技術驗證

每個 release 必須：

1. 符合 `Content/Schema/question-bank.schema.json`。
2. 只含已核准可公開內容，不含匯入檔路徑、頁碼截圖、審查者個資或內部備註。
3. 有內容版本、題數、SHA-256、來源／權利摘要與人工核准紀錄。
4. 通過 `Scripts/ci/validate_question_bank.py` 與 App 升級保留測試。
