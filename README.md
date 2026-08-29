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
**給消費端服務跑**（`tpass-form`、`tpass-portal` 這類靠 `tpass-auth-js` 驗票的服務）；在
`tpass-auth`（發證端）跑會誤報「手刻 jwtVerify/algorithms」——那份是 auth 本來就該有的簽章邏輯，
不是抄漏的驗章。在服務 repo 根目錄執行：

```bash
bash ~/.claude/plugins/cache/tpass-skills/tpass/*/scripts/check.sh
```

路徑格式固定為 `~/.claude/plugins/cache/<marketplace 名>/<plugin 名>/<version>/scripts/check.sh`
（`claude plugin install` 會把 marketplace 版本複製進 cache，不是原地跑；2026-08-29 用
`claude plugin marketplace add` + `claude plugin install tpass@tpass-skills` 實測過，安裝後
`find ~/.claude/plugins -name check.sh` 命中的是這個 cache 路徑，不是舊文件猜的
`~/.claude/plugins/*/tpass/scripts/check.sh`——那個猜測少了中間的 `cache/<marketplace>/` 兩層）。

或安裝後在對話中請 Claude 跑 `${CLAUDE_PLUGIN_ROOT}/scripts/check.sh`——這個變數**會在 SKILL.md
內文裡被代換**（官方文件 `skills.md` §Available string substitutions 明載：plugin skill 的
`${CLAUDE_PLUGIN_ROOT}` 會在 skill 內文與 `allowed-tools` 的 Bash 規則裡代換，代換值就是上面那個
cache 路徑），不需要人工拼路徑，這是首選寫法。有命中會印出「檔案:行」並 exit 1；全乾淨 exit 0。
已知例外（`global-error.tsx` 的 inline hex、`HeroSection.tsx` 的 Google logo 品牌色）已經寫進腳本，
不會誤報。

## 開發

`docs/format-notes.md` 記錄了寫這個 plugin 時核對官方文件（`plugins.md` / `plugin-marketplaces.md` /
`skills.md`）確認的確切欄位格式，改 `plugin.json` / `marketplace.json` / SKILL.md frontmatter 前先看。

驗證：

```bash
claude plugin validate .
bash scripts/check.sh   # 在某個服務 repo 根目錄跑，不是在這個 repo 跑
```
