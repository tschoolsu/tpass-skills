---
name: tpass-design
description: T-Pass Neobrutalism 設計系統規則。寫元件/UI/樣式/顏色/字體/卡片/按鈕/badge 時使用；code review 檢查樣式時也用。
---

# T-Pass Design System

風格：**Playful Tech / Bright Pop Tech**，嚴格 light-only，白底 + 重邊框 + 糖果色 Neobrutalism。

## 元件一律 import 自 tpass-ui，不要手刻 primitives

```bash
pnpm add github:tschoolsu/tpass-ui#v1.0.0
```

```ts
import { cn, Button, Input, Textarea, Select, Card, Badge, Label, Switch, ConfirmDialog } from "tpass-ui";
```

`globals.css` 三行（不要自己重寫 border/shadow 的 CSS）：

```css
@import "tailwindcss";
@import "tpass-ui/theme.css";
@source "../../node_modules/tpass-ui/dist";
```

錯了會怎樣：自己刻一份 Button/Card，六個服務又漂移出六種邊框粗細與 shadow 尺寸，回到套件出現前的狀態。

## 硬規則

- **Light-only**：不寫 `dark:` 前綴，不做 dark mode。錯了會怎樣：整個生態系只有一套 light token，`dark:` 樣式永遠不會被使用者看見（純垃圾程式碼）還可能誤觸發第三方工具的 dark 偵測。
- **顏色一律 OKLCH**：禁止 hex（`#fff`）、禁止 `rgb()/rgba()`。錯了會怎樣：混進去的 hex 在色彩空間上跟其他 OKLCH token 不一致，肉眼看起來「怪怪的」但 CI 抓不到，是純粹的視覺 bug。
- **互動元素必須同時有 `border-2 border-foreground` + hard offset shadow**（`shadow-[Xpx_Xpx_0_0_var(--color-foreground)]`），禁止 Tailwind 內建 soft shadow（`shadow-sm`/`shadow-md`/`shadow-lg`/`shadow-xl`）。錯了會怎樣：卡片看起來像別的設計系統長出來的，做 code review 會被要求整份重做。
- **圓角不超過 `rounded-2xl`**，例外只有頭像 `rounded-full`。錯了會怎樣：`rounded-3xl` 以上在這套 Neobrutalism 視覺裡會削弱「重邊框」的手感，等同破壞品牌一致性。
- **字體**：Plus Jakarta Sans（sans/heading）、Geist Mono（badge / tag / status label / code-like 文字）。標題/Logo/重要數字用 `font-extrabold`；body 用 `font-medium`；badge/tag 用 `font-mono font-bold`。

## 三級 shadow 尺寸（依元件大小挑）

| 元件大小 | 靜止 | hover | active |
|---|---|---|---|
| 小（icon badge） | `2px 2px` | `3px 3px` | `1px 1px` |
| 中（button） | `3px 3px` | `5px 5px` | `2px 2px` |
| 大（card） | `4px 4px` | `7px 7px` | `3px 3px` |

Hover 一律 `transition-all duration-200` + `hover:-translate-y-0.5`（小元件）或 `hover:-translate-y-1`（卡片）+ shadow 放大；`active:translate-y-0` + shadow 縮小。

## 完整 token 表與元件樣式模板

詳細 OKLCH 色值、service tone 色板、Icon Badge / Tag / Button / Service Card / Inverted Card 的完整 className 模板，見 `references/tokens.md`（僅在要精確湊 className 或選色時才需要展開讀）。

## 檢查

執行 `scripts/check.sh`（同 plugin 根目錄，`${CLAUDE_PLUGIN_ROOT}/scripts/check.sh`）掃 hex / `dark:` / soft shadow / 超限圓角等違規。
