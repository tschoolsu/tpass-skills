# 格式核對筆記（官方文件原文引用）

寫這份 plugin 前，用 WebFetch 核對了三份官方文件的確切格式。以下是原文片段，供日後改動時對照。

## plugin.json（`.claude-plugin/plugin.json`）

只有 `name` 是必填。摘自 `plugins.md`：

> | Field | Purpose |
> | `name` | Unique identifier and skill namespace. Skills are prefixed with this (e.g., `/my-first-plugin:hello`). |
> | `description` | Shown in the plugin manager when browsing or installing plugins. |
> | `version` | Optional. If set, users only receive updates when you bump this field... |
> | `author` | Optional. Helpful for attribution. |

摘自 `plugins-reference.md`（完整欄位，本 repo 只用到其中幾個）：

> `displayName`, `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `metadata`, `defaultEnabled`

以及元件路徑欄位（本 repo 用預設 `skills/` 目錄，不需要覆寫）：

> `skills` (string|array) — 自訂技能目錄，**疊加**預設 `skills/`
> `commands` / `agents` / `hooks` / `mcpServers` / `lspServers` — **替換**對應預設目錄

**警告**（`plugins.md` 原文）：

> **Common mistake**: Don't put `commands/`, `agents/`, `skills/`, or `hooks/` inside the `.claude-plugin/` directory. Only `plugin.json` goes inside `.claude-plugin/`. All other directories must be at the plugin root level.

## marketplace.json（`.claude-plugin/marketplace.json`）

必填：`name`、`owner`（含 `name`）、`plugins`（陣列）。

## Plugin source 指向同一個 repo 自己（相對路徑）

摘自 `plugin-marketplaces.md`：

> Paths resolve relative to the **marketplace root**, which is the directory containing `.claude-plugin/`.

> `"source": "./"` — Marketplace Root 作為 Plugin Source

> Don't use `../` to reference paths outside the marketplace root.

本 repo 採用 `"source": "./"`（`.claude-plugin/marketplace.json` 裡的 plugin entry），因為
`skills/` 就放在 marketplace root，不需要子目錄轉一手。

## SKILL.md frontmatter（`skills.md` 官方 Frontmatter reference 表）

只有 `name`（No，非必填，預設用目錄名）、`description`（Recommended）是常用欄位；**沒有欄位是嚴格必填**。
本 repo 只用 `name` + `description`，符合 skill-creator 的「不要加其他欄位」建議。

摘自官方表格（節錄）：

> `name` | No | Display name shown in skill listings. Defaults to the directory name.
> `description` | Recommended | What the skill does and when to use it. Claude uses this to decide when to apply the skill... Put the key use case first: the combined `description` and `when_to_use` text is truncated at 1,536 characters.
> `disable-model-invocation` | No | Set to `true` to prevent Claude from automatically loading this skill. Use for workflows you want to trigger manually with `/name`.
> `allowed-tools` | No | Tools Claude can use without asking permission during the turn that invokes this skill.
> `metadata` | No | Free-form YAML map for your own key-value data... Claude Code doesn't act on its contents.

## `.claude/settings.json`：`extraKnownMarketplaces` / `enabledPlugins`

**重要更正**：WebFetch 第一次摘要 `plugins-reference.md` 時把 `extraKnownMarketplaces` 誤報成
「字串陣列」（`["my-marketplace", "https://..."]`）。這是摘要模型的錯誤，不是官方格式。
用 `discover-plugins.md`〈Configure team marketplaces〉章節重新核對，官方原文與範例如下：

> Add `extraKnownMarketplaces` to your project's `.claude/settings.json`:
>
> ```json
> {
>   "extraKnownMarketplaces": {
>     "my-team-tools": {
>       "source": {
>         "source": "github",
>         "repo": "your-org/claude-plugins"
>       }
>     }
>   }
> }
> ```

即：**物件**，鍵是 marketplace 名稱，值是 `{ "source": { "source": "github", "repo": "..." } }`。
`research-distribution.md` 的推測範例（`extraKnownMarketplaces` 物件+`source`巢狀）在這一點上是對的；
真正抓出錯誤的是 plugins-reference 摘要那次的陣列格式，寫 README 前務必以這份筆記為準，不要用摘要重跑。

`enabledPlugins` 格式兩次獨立 fetch 結果一致，可信：

> ```json
> {
>   "enabledPlugins": {
>     "formatter": true,
>     "debugger@my-marketplace": false
>   }
> }
> ```

鍵是 `plugin-name` 或 `plugin-name@marketplace-name`，值是 boolean。

## 與 research-distribution.md 的落差（不可照抄的部分，已避開）

- `hooks.json` 範例裡的 `if`、`exit_codes`、`condition` 欄位：官方 hooks.json schema **沒有**這些鍵
  （官方範例只有 `matcher` + `hooks: [{ type, command }]`）。本 plugin **沒有用 hooks**，所以沒有
  這個問題，但記錄下來避免以後加 hooks 時照抄。
- SKILL.md frontmatter 裡的 `@reference colors.md` 語法：官方文件用的是一般 Markdown 連結
  （`[FORMS.md](FORMS.md)` 或純檔名提及），不是 `@reference` 這種自訂標籤。本 plugin 的
  reference 檔案一律用「見 `references/xxx.md`」的純文字指向，不用 `@reference`。
