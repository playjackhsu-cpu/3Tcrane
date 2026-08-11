# Private question-bank intake tools

此處工具只處理私有題庫證據，不會產生正式 App 題庫。

## OCR

需求：Python 3、Pillow、pypdf、Poppler `pdftoppm`、Tesseract 與 `chi_tra` 語言資料。Codex 桌面環境可使用已配置的文件處理 runtime。

若 `pdftoppm` 不在 `PATH`，以 `THREETCRANE_PDFTOPPM` 指定執行檔；不要把個人主目錄或機器專屬路徑寫入版本控制。

抽樣：

```bash
python3 Scripts/content/ocr_question_bank.py --pages 1-3,20
```

完整批次：

```bash
python3 Scripts/content/ocr_question_bank.py --pages all --dpi 300
```

輸出固定在 `PrivateResources/QuestionBank-Inbox/ocr/`，包含切頁影像、OCR 原文、TSV 與 manifest。原始 PDF 必須先放在 `PrivateResources/QuestionBank-Inbox/source/題庫.pdf`。

不要把 OCR 文字複製到 `Content/Releases/`。後續必須依 `Docs/04_題庫與內容/OCR與逐題審查流程.md` 完成逐題比對、答案／來源／解析與權利審查。

## macOS Vision OCR

`vision_ocr.swift` 使用 macOS Vision 的繁體中文文字辨識，輸出仍固定放在私有收件區。它適合和 Tesseract 結果交叉比對，不會取代逐題看圖。

```bash
swiftc Scripts/content/vision_ocr.swift -o /tmp/3tcrane-vision-ocr
/tmp/3tcrane-vision-ocr \
  --input-dir PrivateResources/QuestionBank-Inbox/ocr/processed-pages \
  --text-dir PrivateResources/QuestionBank-Inbox/ocr/raw-text-vision \
  --json-dir PrivateResources/QuestionBank-Inbox/ocr/vision-lines
```

## 官方題庫文字層清冊

把官方最新版 PDF 放在 `PrivateResources/QuestionBank-Inbox/source/official/` 後，可建立 1,000 題私有結構清冊：

```bash
python3 Scripts/content/build_question_inventory.py
```

工具會驗證 06100 四個工作項目共 600 題，加上 90006–90009 各 100 題，且輸出只能寫入 `PrivateResources/`。官方頁面已聲明學科資料僅供參考，因此清冊內答案一律先標記為 `printed-reference-only`；逐題來源、解析、現行答案及權利審查未通過前，不得轉入公開 release。

含圖題須再把官方 PDF 內明確對應的圖檔抽出，排除頁面浮水印：

```bash
python3 Scripts/content/extract_question_visuals.py
```

只有實際逐頁查看圖題與選項完整後，才可加上 `--mark-reviewed`。目前映射涵蓋 9 題、15 個圖檔；輸出與 manifest 同樣只能位於 `PrivateResources/`。

逐批完成來源與解析審查後，以私有 review batch 套回總清冊：

```bash
python3 Scripts/content/apply_review_batches.py
```

工具只合併答案驗證、來源、解析與審查狀態；官方轉錄的題幹與選項若不相容會立即失敗，避免審查批次悄悄改寫原題。

## 全庫官方來源第一輪審查

在人工優先審查批次已套用後，可為其餘題目建立每批最多 30 題的私有審查資料：

```bash
python3 Scripts/content/complete_official_review.py --dry-run
python3 Scripts/content/complete_official_review.py
python3 Scripts/content/apply_review_batches.py
```

此流程逐題保存官方來源 URL、印刷答案、解析草稿及四選項判讀，並把官方刪題保留為不可抽題的 tombstone。它完成的是「官方版本、題文、答案鍵與基本解析」第一輪審查，不代表獨立工程驗證、法規發行時效、內容權利或正式發行 QA 已通過。機械產生批次如需在模板修正後更新，只允許刷新帶有專用 `batchStatus` 的批次：

```bash
python3 Scripts/content/complete_official_review.py --refresh-generated --dry-run
python3 Scripts/content/complete_official_review.py --refresh-generated
```

## 未納入與衝突清單

完成套批後，從完整清冊重建候選抽題池的例外清單：

```bash
python3 Scripts/content/build_review_exception_reports.py
```

工具會在私有收件區產生機器可讀排除清單，以及「答案與法規衝突」和「未納入題目」兩份詳細報告。分類固定為官方刪題、明顯答案／題意衝突、法規生效過渡期，並檢查三類不可重疊。未納入候選池的題目仍保留在 1,000 題完整清冊，不能直接刪除；產出路徑受 Git 忽略規則保護。
