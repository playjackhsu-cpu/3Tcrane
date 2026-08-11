---
title: Apple 發布規劃
tags: [apple, app-store, testflight, metadata]
status: draft
updated: 2026-08-10
---

# Apple 發布規劃

## 暫定識別資料

| 欄位 | 建議值 |
| --- | --- |
| App Store 名稱 | 起重機考照通－三噸以上固定式起重機 |
| 裝置顯示名稱 | 起重機考照通 |
| 英文工作名 | 3T Crane Study |
| Bundle ID | `tw.tauruswinner.crane.study` |
| SKU | `TW-3T-CRANE-IOS-001` |
| Marketing version | `1.0.0` |
| First build | `1`，後續單調遞增且不重用 |
| 類別 | Education；次類別 Reference |
| 價格 | 美國基準 US$0.99；台灣價格點 NT$30；無 IAP |
| 地區／語言 | 台灣、繁體中文首發 |
| 年齡分級 | 4+ 候選，依正式內容問卷回讀為準 |
| Copyright | `© 2026 TaurusWinner. All rights reserved.` 草案 |

Bundle ID 是否可用要在 Apple Developer portal 實際註冊確認；Team ID、憑證與 profile 不寫入公開倉庫。

## App Store 文案

- Subtitle：`固定式起重機單一級技能檢定`
- Promotional text：`固定式起重機操作單一級技能檢定複習工具：課程閱讀、逐題解析、錯題複習與模擬測驗。啟用 iOS 自動更新後，可隨新版 App 取得依官方最新公布題庫整理的內建內容，並保留裝置內的學習紀錄。`
- 關鍵字：`固定式起重機,技能檢定,單一級,三噸,考照,題庫,模擬測驗,錯題,職安,吊掛`
- 完整可貼用說明、Review notes 與字數檢核見 [[Docs/07_發布與維運/AppStore上架文案]]。
- 說明必須避免宣稱官方 App、保證通過或取代法規／實務訓練。

## 隱私與網路

MVP 不登入、不收集、不傳送學習紀錄，也不含追蹤、廣告或分析 SDK。App Privacy 候選回答為「不收集資料」，但送審前須以實際 binary／第三方清單重做問卷。iOS App 仍必須提供 Privacy Policy URL 且 App 內可容易開啟。

建議公開頁：

- Privacy：`https://playjackhsu-cpu.github.io/3Tcrane/privacy/`
- Support：`https://playjackhsu-cpu.github.io/3Tcrane/support/`

公開頁原始檔位於 `Site/`，由 GitHub Pages workflow 在 `main` 更新後部署。這些 URL 在 workflow 合併、Pages 啟用並以未登入瀏覽器驗證前都屬草案。Support 頁提供不需登入即可閱讀的 FAQ，公開 Issues 僅供不含個資的一般技術回報；私人支援聯絡方式須由 Owner 決定，不得挪用 TestFlight 測試者資料。

Apple 參考：[Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)、[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)。

## Privacy Manifest／加密

- 建立主 App `PrivacyInfo.xcprivacy`，按實際 Required Reason API 宣告；若使用 UserDefaults，只能選符合實際用途的 reason。
- 不使用自製加密或非豁免演算法時，`ITSAppUsesNonExemptEncryption=false` 候選；archive 前重新稽核 dependencies／network stack。
- 不請求通知、相機、照片、位置、藍牙等權限，除非功能已核准；本機提醒需由使用者明確開啟。

## 內容權利與安全聲明

- 保存題庫、圖示、圖片與文字使用權利；公開可瀏覽不等於可複製整包發行。
- App 與 metadata 明確說明非政府／非考試機關官方產品。
- 顯示內容版本、查核日期與「最新法規／考試規定以主管機關公告為準」。
- 不用模擬操作，不能宣稱取代合格訓練、實機操作或安全程序。

## 發布流程

1. 完成 governed content release、全 CI 與真機升級保留測試。
2. 建立 signed archive，驗證版本、bundle、entitlement、Privacy Manifest、codesign、敏感資料與題庫 SHA-256。
3. Owner 明確核准後上傳 TestFlight；先 internal，再 external beta（如需要）。
4. 回讀 crash、feedback、App Privacy、metadata、screenshots、Content Rights、export compliance。
5. App Review 採手動發布；Review notes 說明完全離線、無登入、題庫與學習紀錄位置。
6. 發布後保留 source commit、內容版、build、archive hash、提交紀錄與已知問題；binary／憑證不進 Git。

## 更新與回復

- 題庫更新＝新 App version/build；Release Notes 同時列 App／內容版本。
- App Store 不能上傳較低 build。若新版需回復，以更高 build 重新發行上一個已知良好程式碼，並確保可開啟現有 UserStore。
- 發布前先驗 A→B；緊急回復前驗 B→C（C 為舊程式邏輯的新 build）資料相容。

## Owner 才能完成但不阻塞開發的事項

Apple Paid Applications Agreement／稅務／銀行、正式 privacy/support 網站驗證、內容權利最終聲明、App Review 私密聯絡資料、正式送審操作與手動發布核准。App record、Bundle ID 與 TestFlight 已建立；憑證與簽章資料仍不得進公開倉庫。
