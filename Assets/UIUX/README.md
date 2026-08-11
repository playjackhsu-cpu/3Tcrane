# UI/UX assets

- `Reference/`：可公開的概念設計板，只供對照，不直接切圖進 App。
- `Production/`：經驗證的 App Icon、品牌圖與必要自訂 vector／PNG；正式 UI 優先使用 SF Symbols 與 SwiftUI shape。

現有參考圖：`Reference/3t-crane-ios-uiux-board-2026-08-10.png`，1536×1024，SHA-256 `a5a8c0bbd62498aafb7d676b2fb185e40419c3b9103d03a2d7d6909c4de43f36`。

2026-08-10 已收到完整高解析獨立素材包。完整原包、畫面截圖與高解析設計板保留於 `PrivateResources/UIUX-Inbox/`；畫面內含尚未治理的示意題文及未列入 MVP 的帳戶／下載概念，因此未複製到公開區。

公開 `Production/` 已挑選：

- `CraneLearningAssets.xcassets/`：iPhone／iPad App Icon、8 組色票、12 組 1x／2x／3x 功能圖示。
- `ColorTokens.swift`：原始 SwiftUI／UIKit 色彩常數，導入 App 時再決定是否改用 Asset Catalog typed symbols。
- `colors.json`：色票與用途的機器可讀參考。

App Store 1024×1024 icon 已確認為 RGB、無 Alpha、未預先裁圓角。功能圖示尺寸為 64／128／192 px 並具透明背景。圖示線條在小尺寸略柔，首版可作品牌候選；一般導覽仍優先評估 SF Symbols。
