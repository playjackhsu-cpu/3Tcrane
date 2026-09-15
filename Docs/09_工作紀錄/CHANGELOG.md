# Changelog

- 2026-09-15：`1.0.2` build 9 簽章發行包稽核通過，19:06 由 Apple Transporter 傳送，Apple 完成處理後綁定 App Store 正式版本；19:12 提交 App Review，回讀「等待審查」。免費、台灣 1 地供應、核准後手動發佈；尚未公開上架。送審回執與 IPA SHA-256 見 `CURRENT_STATE.md`。
- 2026-09-15：[PR #10](https://github.com/playjackhsu-cpu/3Tcrane/pull/10) 五道必要 CI 全數通過後於 19:24 squash merge 至 `main`（`1e5772b`），遠端 `main` 檔案內容與 Build 9 發行候選一致。依使用者指示採先 Apple 送審、後補 PR／CI 次序，並保留公開資料稽核與本地裝置尺寸回歸證據。
- 2026-09-15：`1.0.2` build 8 已傳送 Apple 並完成處理，[PR #9](https://github.com/playjackhsu-cpu/3Tcrane/pull/9) 五項 CI 通過後合併（`14823e6`）；尚未送審／公開。因使用者隨後調整錯題規則，新規則另做 QA 與後續 build，不以 build 8 冒充最新版本。
- 2026-09-15：錯題複習改為首次答對 1 次移出；在錯題複習中答錯後須連續答對 2 次，再答錯歸零。舊版已答對 1／2 次的錯題升級後移出清單但保留完整作答紀錄；沿用既有 SwiftData schema，補永久 store 重開與回歸測試。
- 2026-09-15：錯題複習跳題修正經 [PR #8](https://github.com/playjackhsu-cpu/3Tcrane/pull/8) 五項必要 CI 通過並 squash merge（`330b8cc`）；Apple 已核准但未手動發佈的 `1.0.1` build 7 不含修正。建立 `1.0.2` App Store 準備提交紀錄，將修正版候選升為 build 8，待 signed archive、發行包稽核、上傳與 Apple 審查回讀。
## 2026-09-15

- 修正錯題複習作答後跳題：複習頁固定進入時的題目 ID 快照，不再讓 SwiftData 即時重排／移除的上層清單改變目前題幹、選項或解析；按下一題才依尚待複習的題目切換。
- 新增兩個 iPhone／iPad UI 回歸：較舊錯題選錯導致清單重排後仍顯示原題與原題解析；第三次答對導致題目移出清單後仍顯示原題回饋，直到按下一題才切換。
- 本機驗證：iPhone 與 iPad simulator 各 2／2 回歸通過，17／17 unit／升級保留測試通過。題庫與資料 schema 未變；已送審的 `1.0.1` build 7 不含此修正，需以後續修正版重新走 PR／CI 與 Apple 發行 gate。

## 2026-09-14

- 新增「全題庫依序練習」：不限時間、不亂數抽題、不打亂選項，完全依發行題庫陣列順序呈現；作答後立即顯示正確答案與解析，並以獨立 AppState 鍵保存下次續作位置，不覆蓋課程閱讀進度。
- 錯題複習改為每題連續答對 3 次才移出；任何一次答錯立即把連勝歸零。一般題庫練習、全題庫練習及模擬測驗的答對不會意外累計錯題連勝或清除既有錯題。
- 題庫內容與 983 題一般題池均未修改；學習紀錄仍保存在 App bundle 之外的 SwiftData store，新增狀態沿用既有欄位值，避免破壞既有資料 schema。
- App Store Connect 已回讀首版 `1.0.0`（build 6）為「已可發佈」；本次更新版本規劃為 `1.0.1`（build 7）。
- 本機最終驗證通過 17／17 unit／升級保留測試、iPhone UI 6 通過／2 項裝置條件跳過、iPad UI 7 通過／1 項裝置條件跳過，兩平台均 0 失敗；正式題庫 QA App 已在 iPhone 11 安裝並啟動。本輪 iPad 因 Xcode 回報裝置不可用，未把 USB 裝置紀錄視為實機通過。
- [PR #6](https://github.com/playjackhsu-cpu/3Tcrane/pull/6) 五道必要檢查全數通過後已 squash merge 至 `main`（merge commit `ace6f7f64476c36d30a6410aafd52249c50faff8`）。
- 建立並稽核 App Store `1.0.1`（build 7）發行包：983 題、17 題例外與 15 個題圖齊全，未夾帶私有題庫、掃描原稿或簽章資料；IPA SHA-256 為 `9d6a94f6819d141c3842aa4a3303885449bbcab9c1a356187e7a8bee9bf302c0`。
- `1.0.1`（build 7）已於 2026-09-14 07:42 透過 Transporter 送達並由 Apple 完成處理；已綁定商店版本、儲存新增功能與審查路徑，07:48 提交 App Review，App Store Connect 回讀為「正在等待審查」。
- App Store Connect 「定價與供應狀況」已確認 `1.0.0`（build 6）在台灣 1 個地區供應，並顯示可停售操作；因此本輪不再誤將「已可發佈」解讀為尚未公開。

## 2026-08-11

- 完成專案結案總結報告及 6 頁正式 PDF，涵蓋產品與內容成果、資料保留架構、iPhone／iPad QA、簽章與 Apple 送審、GitHub 治理、公開／私有資料分層、兩日開發歷程、剩餘工作與還原指引。
- 建立私有 NAS 日期化封存，保存可瀏覽工作區、Git bundle、原始題庫與 UI/UX 資源、全部 `Artifacts/`、Xcode DerivedData、最終 IPA／archive、App Store 截圖、檔案清冊、SHA-256 與清理紀錄；只在驗證成功後釋放本機專案專用快取與模擬器。
- `1.0.0`（build 6）已透過 Apple Transporter 上傳並完成處理，選入 App Store 版本；經 Owner 明確確認後，發佈 App Privacy「不收集資料」聲明、沿用既有正式審查聯絡資料並確認第三方內容必要權利。版本已提交 Apple，狀態為「正在等待審查」，核准後採手動發佈；公開文件不記錄審查聯絡人的電話或信箱。
- PR #6 的 Governance、unit／升級保留、Release build、iPhone UI smoke 與 iPad UI smoke 已全數通過；首次 unit runner 未載入任何 iOS simulator 的暫時性失敗經單項重跑後通過，未修改程式或降低測試 gate。
- 依 Owner 指示將 App Store 首發價格改為免費；App Store Connect 回讀 175 個國家／地區價格均為 0.00，供應地維持台灣。版本欄位同步為 `1.0.0`，發布方式維持手動；未選正式建置、未按新增以供審查，也未代填私密聯絡資料。
- 建立可重建的正式題庫 release candidate：983 題一般抽題、17 題治理例外與 15 個題圖，公開包移除私有來源定位並寫入技能檢定中心政府網站資料開放宣告的授權連結與顯名；release JSON SHA-256 為 `7399af027135ea462811d55bdc3f91dccefaf967dca7b92065aea7cfbcaaed15`。
- 將 App 版本升為 `1.0.0`（build 6），正式 bundle 只嵌入 release JSON 與 15 個題圖，不再攜帶合成 fixture 或私有題庫。14／14 unit／升級保留、iPhone UI 5 通過／2 跳過、iPad UI 6 通過／1 跳過、iPhone／iPad Release build 均為 0 失敗。
- 建立 `1.0.0`（build 6）signed archive 與 App Store Connect 匯出 IPA；確認發行 entitlement、非豁免加密宣告、983／17／15 內容數量與私有標記掃描均通過。IPA SHA-256 為 `387e4760befc9c2a5605a2aed94b8ce6b5bc570af5224c07fa2c6f7f95996921`，產物維持 Git 忽略且未上傳 Apple。
- PR #1 已於五道必要檢查全綠後合併至 `main`；GitHub Pages workflow 首次部署成功，公開 Privacy／Support URL 均回讀 HTTP 200。
- 完成 App Store 1.0 首發準備：建立繁體中文商店文案、96 bytes 關鍵字、宣傳文字、App Review 導覽、隱私／支援靜態頁與 GitHub Pages workflow；App Store Connect 已設定副標題、教育／參考分類、4+、不需登入、手動發布及不收集資料。未選正式建置、未按新增以供審查、未代填私密聯絡資料。
- 擷取並稽核 iPhone 6.5 吋 1284×2778 與 iPad 12.9 吋 2048×2732 商店截圖；排除顯示舊測試版號的設定頁，將課程學習、題庫測驗與學習記錄各 3 張上傳至 App Store Connect。兩種裝置均回讀為 3 張且由 Apple 自動保存；截圖原檔維持在 Git 忽略的 `Artifacts/`，未選建置版本或新增以供審查。
- GitHub Pages workflow 的 checkout、configure-pages、upload-pages-artifact 與 deploy-pages 均以官方現行主要版本 commit SHA 固定，並以 `main`／`Site/**` 為唯一自動部署來源。
- 本次提交前通過公開倉庫 gate、文件連結與 whitespace 檢查、14／14 unit／升級保留測試、無簽章 Universal Release build，以及 iPhone UI 5 通過／2 項裝置條件跳過、iPad UI 6 通過／1 項裝置條件跳過；兩平台均為 0 失敗。
- 修正暗色模式的全域語意色：頁面背景、卡片邊界、主要／次要文字及互動色均加入 Dark 變體，排除深色卡片搭配深色文字與淺色導覽列搭配白字的低對比問題；新增 Light／Dark 4.5:1 對比單元測試與 iPhone／iPad 暗色首頁 UI gate。14 項 unit tests、iPhone 7 項及 iPad 7 項完整 UI 回歸皆 0 失敗；另建立不同 Bundle ID 的 QA App，避免覆蓋既有 TestFlight App 與學習紀錄，並於連接的 iPhone 11 與 iPad 完成安裝及 Dark Mode 前景啟動 smoke。
- 建立並啟用 GitHub `Protect main` Ruleset：套用預設分支 `main`、無 bypass、禁止刪除與 force push、要求 linear history、PR、對話解決與最新分支，並要求 `public-repository-gate`、`Unit tests`、`Release build`、`iPhone UI smoke test`、`iPad UI smoke test` 五道檢查。Draft PR #1 最新 Governance 與 iOS CI workflow 均已完成且成功，PR 維持 Draft、未合併。
- 產生並稽核 0.1.0（build 5）App Store archive，確認 iPad 比例修正、內容版 `0.2.1`、983 題候選、15 個題圖與 17 題治理例外，且未含私有來源定位、原始 PDF、敏感路徑或憑證；Apple 上傳與處理完成後已加入既有內部群組，目前顯示「正在測試」。未建立外部測試，未送 Beta App Review 或 App Review。
- 將首個公開基線提交至 `agent/initial-public-baseline`（commit `eb0621d`）並建立 Draft PR #1；首輪 GitHub Actions 的 Governance、12 項 unit／升級保留、Release build、iPhone UI smoke 與 iPad UI smoke 全數通過。PR 維持 Draft，尚未合併至 `main`。
- 依 iPad 直向／橫向實機截圖調整分割導覽比例：sidebar 改為 240～280 pt、理想 260 pt，使用 balanced split view；側欄與首頁改為 inline title，hero 內文限制為 900 pt，避免大標題、過寬側欄與橫向內容拉伸。新增 iPad 側欄比例 UI gate，完整 iPad UI 回歸通過。
- 修正 CI 的 iPhone simulator 假失敗：`iPhone 16e + OS=latest` 在 Xcode 26.6 latest runtime 不存在，依 GitHub `macos-26` runner 現行映像改為 `iPhone 17 Pro + OS=latest`；同時將課程冷啟動等待改為穩定的 10 秒上限，單項 iPad 測試連續通過兩次。
- 重新稽核公開 Git 候選範圍與忽略規則：`PrivateResources/` 私有題庫、`Artifacts/`、Apple 簽章與建置產物均未進入候選；公開資料、題庫 schema 與文件連結 gate 通過。
- 確認指定 GitHub 遠端的 SSH 驗證可用；以不含專案內容的一次性空白 root commit 建立遠端 `main` PR base，並建立 `agent/initial-public-baseline` 承載首個公開內容 PR。後續 `main` 仍只接受通過 CI 與治理檢查的 PR。
- 將首頁 17 題例外審查卡改為預設收合的摘要卡，固定顯示總數與 8／5／4 分類；點擊才展開逐題原因、正確答案與官方來源，再次點擊可收合。新增收合／展開無障礙狀態與 UI 驗證；iPhone、iPad 各 5／5 UI tests 及 12／12 unit tests 通過。
- 產生並稽核 0.1.0（build 4）App Store archive，確認收合版 UI、內容版 `0.2.1`、983 題可抽題候選、17 題例外與 8／5／4 分類，且未含私有來源定位、原始 PDF、敏感路徑或憑證；上傳後已加入既有內部群組，Apple 顯示「正在測試」。
- 在首頁「目前內容」卡片下方新增 17 題官方題庫例外完整明細：官方最新版刪除 8 題、答案或題意衝突 5 題、法規生效過渡 4 題；每題顯示官方原答案、正確答案／現行判定、列管原因與官方來源。刪除題保留歷史答案但明確標示無現行採計答案。
- Internal TestFlight 題庫內容版更新為 `0.2.1`；產生器與 App repository 新增 17 題治理例外契約、ID／分類／必填欄位驗證，且例外不進入 983 題抽題池、不攜帶掃描頁碼或私有匯入定位。
- 測試擴充為 12 個 unit tests、iPhone 5 個 UI tests 與 iPad 5 個 UI tests並全數通過；另完成兩種裝置的例外卡長文換行、分類、來源連結與捲動視覺檢查。
- 產生並稽核 0.1.0（build 3）App Store archive，確認內容版 `0.2.1`、983 題可抽題候選、17 題例外與 8／5／4 分類，且未含私有來源定位、原始 PDF、敏感路徑或憑證。
- 上傳 0.1.0（build 3）至 App Store Connect 並加入既有內部群組；目前顯示「正在測試」。群組現有 2 位測試人員；未建立外部測試、未送 Beta App Review 或 App Review。
- 重新確認並落實 Taiwan_Wtsbot 式學習分流：課程學習改為固定順序逐題閱讀，立即顯示答案、解析、另解與來源且不計入作答統計；題庫練習、錯題複習與模擬測驗維持各自獨立的回饋時機與紀錄語意。
- 依 UI/UX 參考板重整 iPhone／iPad 首頁、功能入口、進度卡片、課程閱讀、練習、測驗與設定畫面；修正 iPad 直向首頁隱藏側欄切換入口的問題，改為常駐側欄。
- 新增 Internal TestFlight 專用題庫產生流程；以受控建置參數嵌入 983 題候選池與 15 個題圖，公開／一般開發版仍只含 12 題合成資料。私有來源、產生題庫與題圖均維持 Git 忽略。
- 正式模擬測驗依技能檢定中心規則改為 80 題／100 分／100 分鐘，包含 06100 專業題 64 題及 90006～90009 各 4 題；另保留 10 題／10 分鐘快速測驗，題庫不足時禁止開始正式模式。
- 擴充為 10 個 unit tests、iPhone 4 個 UI tests 與 iPad 4 個 UI tests 並全數通過；新增課程閱讀不要求作答、正式模擬測驗科目配比與題庫不足阻擋測試。
- 產生並稽核 0.1.0（build 2）App Store archive：確認 983 題、5 科、8 章、9 題含圖題及 15 個題圖，未含內部來源定位、原始 PDF、敏感路徑或憑證；iPhone／iPad build、更新保留測試與公開治理檢查均通過。
- 上傳 0.1.0（build 2）至 App Store Connect；Apple 處理完成後已人工加入 `3Tcrane 內部測試｜10 人名額` 群組，目前顯示「正在測試」。未建立外部測試，亦未送出 Beta App Review 或 App Review。

- 收件技能檢定中心官方 `061004A13.pdf` 與 90006～90009 四份共同科目 PDF，全部保存於 Git 忽略的私有來源區。
- 新增官方 PDF 題目解析器與完整性檢查，建立 1,000 題穩定 ID 私有清冊；保留 8 題官方刪題且禁止抽題／發行。
- 完成掃描本 1,000 個答案標記交叉核對：996 題自動一致、4 題人工查看掃描後一致。
- 完成 9 題圖片題來源頁檢查，私有擷取 15 個題目圖示資產並排除浮水印。
- 新增私有 review batch 套用流程；安全衛生法規 33 題完成第一輪逐題影像、答案、來源與解析審查。
- 標記 4 題未生效修法風險、2 題題意／制度名稱警示及 1 題官方刪題；未宣稱可發行，也未提交或推送任何私有題庫內容。
- 依 Owner 指示將後續內容流程改為官方文字 PDF 與主管機關線上資料優先；既有 OCR 僅作缺頁、不清或衝突時備援，不再重複處理清楚題文。
- 完成 06100 安全措施全 76 題第一輪來源與解析審查；36 題直接確認、22 題保留用語／適用範圍警示、15 題待補獨立技術來源，另發現桁架走道寬度、摩擦力與單條鋼索吊掛共 3 題答案衝突並停用。全題庫累計完成 109 題且全部維持禁止發行。
- 修正官方 PDF 文字解析器跨工作項目時夾入章節頁尾的問題；第 76 題第 4 選項已恢復為「連桿式」，完整重建與重套審查批次成功。
- 完成 06100「吊掛、操作與指揮」第 1～30 題官方來源與解析審查；16 題直接確認、11 題保留範圍／文字註記、1 題待補獨立技術來源，另將混淆運動與加速度方向的第 7 題及把四條吊索當通則的第 27 題封鎖發布。全題庫累計完成 139 題，餘 861 題。
- 新增全庫官方來源第一輪審查產生器，將其餘 861 題拆成 32 個、每批最多 30 題的私有批次；連同既有人工優先批次共 38 批、1,000／1,000 題完成第一輪資料審查，未分批題數為 0。
- 每題補齊官方來源、印刷答案、現行答案狀態、基本解析、四選項判讀與審查標記；產生內容明確維持為編審草稿，不冒充獨立技術驗證、法律意見或已清權發行內容。
- 新增例外清單重建工具；完整清冊保留 1,000 題，預備候選抽題池納入 983 題，另外逐題列管 17 題未納入項目：8 題官方刪題、5 題明顯答案／題意衝突、4 題法規修正生效過渡期。所有例外仍保留穩定 ID、來源與恢復條件。
- 產出 9 頁正式例外審查 PDF，逐題彙整掃描書本與官方下載雙重頁碼／題號、題目名稱、錯誤內容及處置；PDF 維持 Git 忽略，公開程式不含私有題文。
- 建立 SwiftUI Universal App、共享 Xcode scheme、unit test 與 UI test targets；iPhone 採 TabView，iPad 採 NavigationSplitView。
- 建立 bundle 題庫 repository 與 schema／答案契約驗證，App 只使用公開合成 fixture，不帶入尚未核准的正式題庫。
- 建立獨立 SwiftData 學習 store 與題目進度、收藏、筆記、模擬考、App 狀態模型；加入 A→B 重開保留及孤兒題目紀錄測試。
- 完成首頁、課程、測驗、紀錄、設定與最小選答／解析流程；本機 4 個 unit tests、iPhone UI smoke、iPad UI smoke 及 Debug／Release 無簽章建置通過。
- 新增 `iOS CI` workflow，以 `macos-26`／Xcode 26.6 執行 unit、iPhone、iPad 與 Release build 四道固定關卡；不加入簽章或 Apple secrets。
- 將公開合成 fixture 擴充為 2 科、4 章、12 題，並強化 App 端題庫驗證：重複穩定 ID、空題幹、重複選項及錯誤章節關聯一律拒絕載入。
- 完成全題／章節練習、繼續上次題目、錯題兩階段複習、收藏、筆記與複習資料夾；學習資料全數寫入獨立 SwiftData store。
- 完成本機隨機模擬測驗、逐題快照保存、未完成恢復、交卷計分、逐題結果與測驗歷史；作答期間不揭露答案。
- 擴充學習統計與首頁摘要，加入正確率、學習天數、錯題、收藏及模擬測驗紀錄。
- 增加 export compliance Info.plist 宣告；確認 App 無登入、遠端題庫、追蹤、廣告或雲端同步。
- 8 個 unit tests、iPhone 3 個 UI tests、iPad 3 個 UI tests 全數通過；涵蓋練習、筆記、離線測驗、更新保留與題目下架紀錄。
- 成功產生 0.1.0（build 1）無簽章 Release archive 並完成 bundle 敏感資料稽核；本機 signed archive 因 Bundle ID 尚無 provisioning profile 而停在 Apple 端前置門檻，未允許自動建立 profile、未上傳 TestFlight。
- 新增 TestFlight 測試版交付清單，明列合成內容限制、QA 證據、內部測試步驟及 Owner 才能執行的 Apple Portal／簽章作業。
- 依 Owner 明確授權註冊正式 Bundle ID 與 App Store Connect App record，使用 Xcode 自動管理發行簽章上傳 0.1.0（build 1）；Apple binary 驗證通過，發行 entitlement、TestFlight 回報及非豁免加密宣告均正確。
- 建立 `3Tcrane 內部測試｜10 人名額` 群組並指派 build，關閉不可逆的自動分發，保存測試內容與回饋信箱；一位既有 App Store Connect 使用者已獲邀，四位非既有使用者待補 Apple 強制要求的正確姓、名後以最低權限新增。
- Apple 測試者信箱、Team ID、憑證、provisioning profile、signed archive／IPA 與內部識別碼均未寫入公開文件或 Git；發行產物維持在 Git 忽略區。

## 2026-08-10

- 建立 3Tcrane Obsidian 文件框架與專案章程。
- 定義 SwiftUI／SwiftData 離線架構、App 更新保存學習紀錄策略與 ADR-001。
- 定義產品名稱、Bundle ID／SKU 候選、Apple metadata／privacy／release 流程。
- 建立公開 GitHub 安全治理、PR／CI 計畫與第一個 Governance workflow。
- 建立 question bank schema、synthetic fixture 與 validation scripts。
- 將 UI/UX 概念設計板歸檔至 `Assets/UIUX/Reference/`。
- 初始化本機 Git `main` 並設定指定 GitHub `origin`；未 commit、未 push。
- 收件 38 頁掃描題庫 PDF 至 Git 忽略的 `PrivateResources/QuestionBank-Inbox/`，建立 intake manifest、OCR 切頁工具、原始辨識證據與逐題審查治理流程。
- 完成全 38 頁、76 個左右書頁的私有 OCR；首批 9 題完成原稿與官方法規查核，8 題答案確認、1 題題幹待消歧，全部因權利待確認而禁止發行。
- 收件完整 UI 素材包至 `PrivateResources/UIUX-Inbox/`；公開區只挑選 Xcode Asset Catalog、App Icon、色票與功能圖示，不公開 ZIP、畫面 mockup 或未治理示意題文。
- 以 Xcode `actool` 成功編譯 iPhone／iPad Asset Catalog，無資產錯誤。
