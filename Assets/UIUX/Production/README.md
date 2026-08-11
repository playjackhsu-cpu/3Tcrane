# Production assets

## 已匯入候選

- `CraneLearningAssets.xcassets/`：App Icon、8 組色票、12 組功能圖示。
- `ColorTokens.swift`、`colors.json`：與設計板一致的色彩 token。

這些檔案已通過基本格式、尺寸、Alpha、JSON 結構與 Xcode `actool` iPhone／iPad 編譯，可供 Xcode 骨架使用；編譯只有 iOS 10 前適用的 iPad 76×76@1x 舊尺寸提示。仍須在 iPhone／iPad、Dark Mode、Increase Contrast、Dynamic Type 與 VoiceOver 情境做 App 內驗證。

## Production asset gate

正式素材至少須通過：

- App Icon 1024×1024、RGB、無 Alpha、無預先裁圓角。
- 自訂圖示具 1x／2x／3x 或單一 PDF vector，命名穩定。
- Light／Dark、Increase Contrast 與大型字級下仍可辨識。
- 不含第三方商標、未授權字型或生成工具限制使用的素材。
- 與 `Docs/03_UI_UX/設計系統.md` 色票一致。

## 使用限制

- 不把 `PrivateResources/UIUX-Inbox/` 的完整素材包或 ZIP 加入 target。
- 畫面 mockup 只做內部參考，不能當作已核准題庫或產品功能規格。
- 一般功能優先 SF Symbols；只有辨識度或品牌需求明確時才採自訂 raster icon。
- 正式提交前補齊色票 Dark／High Contrast 變體並再次執行 Asset Catalog 編譯檢查。
