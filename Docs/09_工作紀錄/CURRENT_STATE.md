---
title: Current State
tags: [checkpoint, current-state]
updated: 2026-08-11
---

# Current State — 2026-08-11

## 已完成

- 盤點空白 3Tcrane workspace、Taiwan_Wtsbot 架構與「設計污水檢定複習系統06」權威摘要。
- 盤點本機 Xcode／Swift／Git／simulator 與空 GitHub 遠端。
- 建立 Obsidian vault、產品／架構／題庫／QA／Apple／風險／開發計畫。
- 建立公開 Git 治理、PR template、CODEOWNERS、Dependabot 與 Governance workflow。
- 建立公開題庫 schema、合成 fixture、validator 與敏感資料 gate。
- 找到並歸檔 2026-08-10 三噸起重機 UI/UX 參考板。
- 已將 38 頁、無文字層的題庫掃描 PDF 收入 Git 忽略的私有收件區；76 個左右書頁候選已完成 300 DPI 切頁 OCR，保留影像、原文、座標／信心值與 manifest。
- 已完成首批 9 題逐字原稿比對與勞動部官方法規查核：8 題答案確認、1 題標記題幹歧義；權利未清，因此沒有題目進公開 release。
- 已取得技能檢定中心最新版 `061004A13.pdf` 與四份共同科目官方 PDF，建立私有 1,000 題完整基準（06100 共 600 題、90006～90009 共 400 題），通過缺號、重複 ID、四選項與答案索引檢查。
- 官方標示 8 題刪題；私有台帳完整保留，但排除抽題與發行，現行參考題為 992 題。
- 掃描本 1,000 個答案標記已全部與官方版交叉核對：996 題自動一致、4 題查看原始掃描後確認一致，目前沒有答案標記需補拍。
- 9 題圖片題已逐頁檢查，從官方 PDF 擷取 15 個私有題目證據資產，全部清楚且未混入浮水印。
- 06100 工作項目 04「安全衛生法規」33 題已完成第一輪逐題影像、答案、來源與解析審查；其中 4 題受未生效修法影響、2 題需改寫警示、1 題官方刪題，全部仍因內容權利與整體 QA 未完成而禁止發行。
- 06100 工作項目 03「安全措施」全 76 題已改採官方文字資料優先完成第一輪來源與解析審查：36 題直接確認、22 題保留用語／適用範圍警示、15 題待補獨立技術來源、3 題發現答案衝突並停用；全題庫累計已審 109 題，且不再對清楚的官方題文重跑 OCR。
- 06100 工作項目 02「吊掛、操作與指揮」第 1～30 題已完成首批審查：16 題直接確認、11 題保留範圍／文字註記、1 題待補獨立技術來源、2 題答案衝突並停用。衝突為第 7 題混淆運動與加速度方向，以及第 27 題把四條吊索當成通用規則；累計完成 139 題。
- 修正官方 PDF 文字解析器的章節頁尾清理規則；安全措施第 76 題第 4 選項已由受頁尾污染的文字恢復為「連桿式」，重建 1,000 題清冊、重做 9 題圖片標記並重套 5 個審查批次後仍通過完整性檢查。
- 已以 38 個審查批次完成全 1,000 題官方來源第一輪資料審查；每題都有穩定 ID、官方來源、印刷答案、現行答案狀態、基本解析、四選項判讀與審查狀態，未分批與遺漏題數均為 0。
- 完整歷史清冊保留 1,000 題，預備候選抽題池納入 983 題；暫不納入的 17 題另外完整列管：8 題官方刪題、5 題明顯答案／題意衝突、4 題法規修正生效過渡期。17 題均未刪除，並保留來源位置、排除原因與恢復條件。
- 已建立可重建的私有「答案與法規衝突清單」、「未納入題目清單」及機器可讀排除清單，並驗證三類例外不重疊。
- 已將 17 題例外彙整為 9 頁正式審查 PDF；每題列出掃描書本頁碼／題號、官方下載頁碼／題號、題目名稱、錯誤內容與處置狀態。PDF 與其內容維持 Git 忽略，公開區只保留不含題文的重建程式。
- 已將完整 UI 素材包保存於私有區，挑選 Xcode Asset Catalog、App Icon、8 組色票與 12 組功能圖示放入公開正式素材候選區。
- Xcode `actool` 已成功編譯 iPhone／iPad Asset Catalog；只有 iOS 10 前適用的 iPad 76×76@1x 舊尺寸提示，無資產錯誤。
- 已建立 `ThreeTCraneStudy.xcodeproj` 與共享 scheme，包含 Universal iPhone／iPad App、unit test 及 UI test 三個 target。
- 已建立 SwiftUI Universal App：iPhone 採五分頁、iPad 採常駐側欄／detail 導覽；首頁、課程、測驗、紀錄、設定皆可進入，視覺已依 2026-08-10 UI/UX 參考板重整首頁英雄區、功能入口、進度摘要與卡片層級。
- 已重新對齊 Taiwan_Wtsbot 的學習分流：課程學習採固定順序逐題閱讀，直接呈現題目、答案、解析、另解與來源，不要求先作答且不污染作答統計；題庫練習才是選答後立即判定；錯題複習要求重新作答；模擬測驗則直到交卷才揭露答案。
- 題庫建置已分為三層：12 題合成 fixture 只供測試與正式內容缺席時的安全退路；正式發行組態載入公開治理後的 983 題 release package、17 題例外與 15 個題圖；Internal TestFlight 仍可用受控參數載入私有候選包。正式 Release bundle 會移除合成 fixture，私有來源定位、原始 PDF 與內部產生物均不進公開倉庫或發行包。
- bundle 題庫與 SwiftData 學習紀錄實體分離，永久 store 位於 Application Support，題目進度、收藏、筆記、模擬考與 App 狀態皆以穩定 ID 保存。
- 已完成更新保留測試：同一永久 store 經 A→B 重新開啟後，五類學習紀錄全部保留；題目下架後孤兒進度仍可讀取。
- 本機 Debug／Release 無簽章建置可執行；4 個 unit tests、iPhone UI smoke 與 iPad UI smoke 已各自通過。
- 已建立 `iOS CI` workflow，固定提供 `ios-unit`、`ios-iphone`、`ios-ipad`、`ios-release-build` 四道 macOS／Xcode 關卡，不簽章、不持有 Apple secrets。
- 已將合成內容版擴充為 2 科、4 章、12 題，所有題目皆明確標示為合成測試資料；repository 另阻擋重複穩定 ID、空題幹、重複選項及錯誤科目／章節關聯。
- 已完成可操作的題庫／章節練習、繼續上次題目、錯題熟練轉換、收藏、筆記、複習資料夾、未完成模擬測驗恢復、交卷計分、逐題結果、學習天數與測驗紀錄。
- 測試已擴充並全數通過：12 個 unit tests；iPhone 課程閱讀／練習／筆記／模擬測驗／例外卡 5 個 UI tests；iPad 側邊欄／課程閱讀／練習／筆記／模擬測驗／例外卡 5 個 UI tests。
- 已成功產生 0.1.0（build 1）無簽章 Release archive；稽核版本、iPhone／iPad family、Privacy Manifest、加密宣告及 bundle 敏感資料均通過。封存只含合成題庫，不含私有題庫或原始 PDF。
- 已註冊 `tw.tauruswinner.crane.study` 明確 Bundle ID，建立 App Store Connect App record，並以 Xcode 自動管理 App Store 發行簽章完成 0.1.0（build 1）上傳；Apple binary 驗證通過，確認 `get-task-allow=false`、`beta-reports-active=true` 且非豁免加密為否。
- 已建立 `3Tcrane 內部測試｜10 人名額` 群組、保存測試內容與回饋信箱，並關閉不可逆的未來 build 自動分發；目前有 2 位內部測試人員，其餘 3 位指定聯絡人仍待合格帳號／姓名資料以建立最低權限且僅限本 App 的使用者。
- 已完成 0.1.0（build 2）Internal TestFlight：嵌入 983 題受控候選題庫、15 個題圖資產、Taiwan_Wtsbot 式課程閱讀流程與新版 UI；Apple 處理完成後已人工加入內部群組，目前狀態為「正在測試」。
- 已將 17 題例外以完整明細卡放在首頁「目前內容」下方：8 題官方最新版刪除、5 題答案或題意衝突、4 題法規生效過渡；每題顯示穩定代碼、題名、官方原答案、正確答案／現行判定、列管原因與官方來源。官方刪題明確標示「無現行採計答案」，但保留歷史答案供對照。
- Internal TestFlight 題庫內容版升為 `0.2.1`；內部 bundle 除 983 題可抽題候選與 15 個題圖外，另含 17 題不參與抽題的治理例外。App 端會驗證例外 ID 不得與可抽題池重疊、分類數必須為 8／5／4，且理由、判定與公開來源均不可為空。
- 正式模擬測驗已依技能檢定中心規則調整為 80 題／100 分／100 分鐘；抽題組成為 06100 專業題 64 題，加上 90006～90009 四項共同科目各 4 題。另保留 10 題／10 分鐘快速測驗，且題庫不足時禁止啟動正式模式。
- build 2 封存與發行包已確認包含 983 題、5 科、8 章、9 題含圖題與 15 個題圖；沒有私有來源定位、原始 PDF、憑證或敏感路徑，簽章與公開治理三道檢查均通過。
- 已完成 0.1.0（build 3）封裝、敏感資料稽核、Apple 上傳與內部群組指派；發行包為內容版 `0.2.1`，包含 983 題可抽題候選及 17 題治理例外，Apple 顯示「正在測試」。本次只更新 Internal TestFlight，未啟用外部測試、Beta App Review 或 App Review。
- Build 3 驗證全數通過：12／12 unit tests、iPhone 5／5 UI tests、iPad 5／5 UI tests，以及 iPhone／iPad 例外卡長文換行與捲動視覺檢查。封存再確認版本、簽章、題數、8／5／4 分類與私有欄位隔離。
- 已完成 0.1.0（build 4）封裝、敏感資料稽核、Apple 上傳與內部群組指派；首頁 17 題例外卡改為預設收合，摘要顯示 17 題與 8／5／4 分類，點擊才展開逐題原因、正確答案與來源，再點可收合。收合／展開狀態具有明確無障礙標示，iPhone／iPad 完整 5 項 UI 回歸與 12 項 unit tests 均通過，Apple 顯示「正在測試」。
- 已依 768×1024 直向與 1024×768 橫向實機截圖調整 iPad 比例：sidebar 使用 240～280 pt、理想 260 pt 的 balanced split view，側欄及首頁採 inline title，hero 內文限制為 900 pt；新增側欄比例 UI gate，避免後續回歸成過寬側欄或大標題版面。
- 已完成 0.1.0（build 5）封裝、敏感資料稽核、Apple 上傳、處理與內部群組指派；此版納入 iPad 比例修正，內容版維持 `0.2.1`、983 題候選、15 個題圖與 17 題治理例外。Apple 顯示「正在測試」，未啟用外部測試、Beta App Review 或 App Review。
- 已依 GitHub `macos-26` runner 現行映像將 CI latest iPhone 改為 iPhone 17 Pro；iPhone 16e 只存在較舊 runtime，不再與 `OS=latest` 組合造成找不到 simulator 的假失敗。課程閱讀 smoke 的冷啟動等待亦已加固。
- 已將公開基線提交至 `agent/initial-public-baseline`（commit `eb0621d`），[PR #1](https://github.com/playjackhsu-cpu/3Tcrane/pull/1) 的 Governance、unit／升級保留、Release build、iPhone UI smoke 與 iPad UI smoke 全數通過後，已由 Owner 核准合併至 `main`（merge commit `832e696`）。
- 已在 GitHub 啟用 Active `Protect main` Ruleset，目標為預設分支 `main`，無 bypass；禁止刪除與 force push、要求 linear history、PR、對話解決、分支保持最新，並將 `public-repository-gate`、`Unit tests`、`Release build`、`iPhone UI smoke test`、`iPad UI smoke test` 設為必要檢查。單人維護階段依既定治理維持 0 個必要核准，改以 CI 全綠與 Owner checklist 明示核准作 gate。
- 已更新 [[Docs/07_發布與維運/TestFlight測試版交付清單]]，完整記錄候選版功能、QA 證據、Apple 上傳結果、內部測試治理與未完成名單條件；公開文件不含測試者信箱、Team ID、憑證或 Apple 內部識別碼。
- 已完成暗色模式第一輪修正：8 組品牌語意色具備一致的 Light／Dark 動態值，頁面、側欄、導覽列、卡片、標題、次要文字與互動色會同步切換；主要文字、次要文字與互動藍色具有至少 4.5:1 自動對比 gate。14 項 unit tests、iPhone 7 項與 iPad 7 項完整 UI 回歸均 0 失敗，並保留暗色首頁截圖證據。
- 已為連接實機建立不同 Bundle ID 的合成題庫 QA App，避免覆蓋 Internal TestFlight App 或既有學習紀錄；iPhone 11 與 iPad 均已完成安裝及 Dark Mode 前景啟動 smoke。QA App、裝置識別資訊、簽章與測試產物均未進入公開 Git。
- 已完成 App Store 首發繁體中文文案：副標題「固定式起重機單一級技能檢定」、教育／參考分類、96 bytes 關鍵字、宣傳文字、完整說明、App Review 導覽與獨立工具聲明；「自動更新」明確限定為隨新版 App 取得重新整理的內建內容，不宣稱 App 內即時同步題庫。
- App Store Connect 首發價格已依 Owner 指示改為免費：175 個國家／地區價格均為 0.00，供應地仍維持台灣；並已設定 4+ 年齡分級、不需登入、手動發布及「不收集資料」問卷。版本欄位已同步為 `1.0.0`；未按下 App Review、未選正式建置版本，也未代填私密審查聯絡資料。
- 已擷取並逐張檢查 iPhone 6.5 吋 1284×2778 與 iPad 12.9 吋 2048×2732 上架候選截圖；前三張依「題庫測驗、課程學習、學習記錄」呈現，舊測試版號的設定頁不列入上傳候選。截圖保存在 Git 忽略的 `Artifacts/`，不進公開倉庫。
- 已將稽核後的 3 張 iPhone 6.5 吋與 3 張 iPad 12.9／13 吋截圖上傳至 App Store Connect 1.0；兩種裝置均回讀為 3 張且由 Apple 自動保存。未上傳含舊測試版號的設定頁，亦未選建置版本或新增以供審查。
- 已建立無追蹤的靜態隱私權政策與支援頁，以及只從 `main` 部署 `Site/` 的 GitHub Pages workflow；四個官方 Actions 均以其現行主要版本 commit SHA 固定，避免浮動 tag 供應鏈風險。
- GitHub Pages 已以 workflow 模式啟用並完成首次成功部署；公開隱私權政策與支援頁均以未登入 HTTP 請求回讀為 200。
- 已建立 App Store 正式題庫 release candidate：內容版 `0.2.1`，983 題一般抽題、17 題治理例外（8／5／4）與 15 個題圖；每題保留公開來源及官方參考答案審查狀態，公開包移除私有頁碼、掃描來源與內部路徑，並加入技能檢定中心政府網站資料開放宣告之顯名與授權連結。發行包 SHA-256 為 `7399af027135ea462811d55bdc3f91dccefaf967dca7b92065aea7cfbcaaed15`。
- App Store `1.0.0`（build 6）發行候選 QA 通過：14／14 unit／升級保留測試、iPhone UI 5 通過／2 項裝置條件跳過、iPad UI 6 通過／1 項裝置條件跳過、iPhone／iPad Release build 均成功，兩平台 0 失敗。正式 bundle 回讀為版本 `1.0.0`、build `6`、983 題、17 題例外、15 個題圖，且只含正式題庫 JSON、不含合成或私有題庫。
- 已建立 `1.0.0`（build 6）本機 signed archive 與 App Store Connect 匯出 IPA；重新簽章後回讀 `get-task-allow=false`、`beta-reports-active=true`、`ITSAppUsesNonExemptEncryption=false`，內容與私有標記掃描通過。IPA SHA-256 為 `387e4760befc9c2a5605a2aed94b8ce6b5bc570af5224c07fa2c6f7f95996921`；archive／IPA 只保存在 Git 忽略的 `Artifacts/`，尚未上傳 Apple。

## 尚未完成

- 983 題正式 release candidate 已完成公開包、資料授權評估與本機正式 App QA；正式送審前仍需 Owner 回讀非背書聲明、授權顯名及特別權利排除條件，並在 App Store Connect 完成 Content Rights 最終聲明。此 gate 是送審法律／權利確認，不再阻塞程式與 CI／PR。
- 17 題例外已完整納入 App 的可展開審查卡，但不參與一般抽題：8 題官方刪題只作歷史保留、5 題明顯答案／題意衝突顯示現行判定、4 題法規生效過渡題顯示過渡原因；官方或法規後續變更時再逐題重審。
- UI 已完成 iPhone／iPad 核心流程、iPad 比例與 Dark 模式的模擬器檢查；尚未完成 High Contrast、Dynamic Type、VoiceOver、橫向／多工與多款實機完整驗證。
- 已確認指定 `origin` 的 GitHub SSH 驗證可用；PR #1 已合併至 `main`，`Protect main` Ruleset 與五道必要檢查維持啟用，GitHub Pages 已完成部署。GitHub security 的額外選配項目仍可後續強化，但不影響目前 PR gate。
- Internal TestFlight build 5 已上線；群組目前有 2 位測試人員。其餘 3 位指定聯絡人仍須具備 App Store Connect 帳號、正確姓／名與合格角色後，才能以最低必要權限完成邀請；10 人規劃仍有 5 個未指定名額。
- 隱私權政策／支援 URL 已部署並可公開讀取，截圖與本機 signed archive／IPA 亦已完成；仍未完成的 Apple gate 為 build 6 上傳與選版、App Review 私密聯絡資料、App Privacy 最終發布、Content Rights 最終確認及「新增以供審查」。

## 下一個可執行工作

等待 `1.0.0`（build 6）草稿 PR 的五道必要檢查全綠及 Owner 合併核准。Owner 完成 Content Rights、App Privacy 與私密審查聯絡資料確認後，才上傳／選取既有 signed build 並按下「新增以供審查」。首版已免費，沒有 Paid Applications Agreement、銀行或稅務 gate。

## 不可遺忘

公開 Git 是永久邊界；正式題庫原稿與 Apple 簽章永遠不進 repo。學習紀錄與 bundle 題庫永遠分離，App 更新 gate 必須有 A→B 保留證據。
