## 目的與範圍

- 變更目的：
- 不在本 PR 範圍：

## 公開資料治理

- [ ] 不含秘密、憑證、個資、內網資訊或本機絕對路徑
- [ ] 不含 `PrivateResources/`、原始題庫／教材或未授權內容
- [ ] 新增素材或內容已有公開權利與來源紀錄
- [ ] `bash Scripts/ci/check_public_repo.sh` 通過

## 題庫與學習紀錄

- [ ] 題庫 ID 穩定且 schema 驗證通過，或本 PR 不改題庫
- [ ] 不覆蓋／重建學習紀錄，或本 PR 不改 persistence
- [ ] 升級／migration 測試通過，或不適用

## QA

- [ ] Unit tests
- [ ] iPhone build／核心流程
- [ ] iPad build／核心流程
- [ ] Accessibility／Dynamic Type
- [ ] `git diff --check`

## 回復方式

請說明失敗時如何回到上一個可用版本，並確認回復不刪除學習紀錄。
