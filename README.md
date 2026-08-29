# tpass-skills

TSchool 數位服務團隊（T-Pass）的 Claude Code plugin：把「模型推不出來、錯了很貴」的專案規則
（design system、SSO 契約、服務慣例）打包成 skill，讓部員的 AI agent 寫服務時自動遵守。
這個 repo 同時是 marketplace 也是 plugin 本體。

## 安裝

```
/plugin marketplace add tschoolsu/tpass-skills
/plugin install tpass@tpass-skills
```

或在各服務 repo 的 `.claude/settings.json` 加這段，team 成員信任資料夾後自動安裝：

```json
{
  "extraKnownMarketplaces": {
    "tpass-skills": {
      "source": {
        "source": "github",
        "repo": "tschoolsu/tpass-skills"
      }
    }
  },
  "enabledPlugins": {
    "tpass@tpass-skills": true
  }
}
```

## 內容

- `skills/tpass-design` — Neobrutalism 設計系統：light-only、OKLCH、border-2 + hard shadow、
  元件一律 import 自 `tpass-ui`。
- `skills/tpass-auth` — SSO 契約 v2：驗章一律用 `tpass-auth-js`、host-only cookie、
  permissions claim、entryYear 年級換算、每個 route/action 都要重驗權限。
- `skills/tpass-service` — 服務慣例：`tpass-registry` 是唯一真相、env 驅動、pnpm-only、
  Next 16 / React 19 的破壞性變更陷阱。

三個 skill 都是 model-invoked：Claude 依 `description` 判斷何時自動載入，不需要手動 `/tpass:xxx`。

## 手動跑檢查

`scripts/check.sh` 是可執行的 grep 集合，涵蓋設計系統違規、SSO 紅線、硬編碼網域、npm/yarn 鎖檔。
在服務 repo 根目錄執行：

```bash
bash ~/.claude/plugins/*/tpass/scripts/check.sh
```

或安裝後在對話中請 Claude 跑 `${CLAUDE_PLUGIN_ROOT}/scripts/check.sh`（plugin 啟用時這個變數會被
自動代換成安裝路徑）。有命中會印出「檔案:行」並 exit 1；全乾淨 exit 0。已知例外（`global-error.tsx`
的 inline hex、`HeroSection.tsx` 的 Google logo 品牌色）已經寫進腳本，不會誤報。

## 開發

`docs/format-notes.md` 記錄了寫這個 plugin 時核對官方文件（`plugins.md` / `plugin-marketplaces.md` /
`skills.md`）確認的確切欄位格式，改 `plugin.json` / `marketplace.json` / SKILL.md frontmatter 前先看。

驗證：

```bash
claude plugin validate .
bash scripts/check.sh   # 在某個服務 repo 根目錄跑，不是在這個 repo 跑
```
