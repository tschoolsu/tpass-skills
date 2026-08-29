# T-Pass Design Tokens（完整版）

摘自 `tpass-portal/docs/design.md`。改動請以該檔為準。

## Color Tokens（OKLCH）

```css
--background:  oklch(0.99 0.002 250)   /* 近白 */
--foreground:  oklch(0.21 0.01  264)   /* 近黑，同時是 border 色 */
--card:        oklch(1    0     0  )
--primary:     oklch(0.62 0.16  150)   /* 綠 */
--accent:      oklch(0.6  0.16  250)   /* 藍 */
--secondary:   oklch(0.96 0.005 250)
--muted:       oklch(0.96 0.004 250)
--muted-foreground: oklch(0.5 0.012 264)
--destructive: oklch(0.58 0.2   25 )   /* 紅橙 */
--border:      oklch(0.21 0.01  264)   /* = foreground */
--input:       oklch(0.85 0.008 264)
--ring:        oklch(0.62 0.16  150)   /* = primary */
```

`color-scheme: light`，`colorScheme: 'light'`。無 dark 對應值。

## Service Tone 色板

每個服務模組有專屬 tone，三層各一個色值：

| tone   | card bg（淡）           | badge bg（中）          | text（深）              |
|--------|--------------------------|---------------------------|----------------------------|
| green  | `oklch(0.96 0.05 150)`   | `oklch(0.88 0.11 150)`   | `oklch(0.45 0.13 150)`   |
| blue   | `oklch(0.96 0.04 250)`   | `oklch(0.88 0.09 250)`   | `oklch(0.46 0.15 250)`   |
| orange | `oklch(0.96 0.05  60)`   | `oklch(0.88 0.11  60)`   | `oklch(0.5  0.15  45)`   |
| violet | `oklch(0.96 0.04 300)`   | `oklch(0.88 0.09 300)`   | `oklch(0.48 0.16 300)`   |
| rose   | `oklch(0.96 0.04  15)`   | `oklch(0.89 0.09  15)`   | `oklch(0.5  0.17  18)`   |

## Border Radius

`--radius: 1rem`：

| token | 換算 | 用途 |
|-------|------|------|
| `rounded-md`   | ~0.6rem | 小 tag、badge 文字標籤 |
| `rounded-xl`   | ~1.4rem | icon 框、按鈕 |
| `rounded-2xl`  | ~1.8rem | 卡片 |
| `rounded-full` | 9999px  | 頭像圓形（唯一超過 2xl 的例外）|

## Layout

- 最大寬度：`max-w-6xl`（72rem）
- 水平 padding：`px-4 sm:px-6`
- Header：`h-16`、`sticky top-0 z-50`、`bg-background/90 backdrop-blur-md`

## 元件 className 模板

### Logo
```tsx
<span className="font-mono text-lg font-extrabold tracking-tight text-foreground">
  T<span className="text-primary">-</span>Pass
</span>
```

### Icon Badge
```tsx
<span className="flex h-10 w-10 items-center justify-center rounded-xl border-2 border-foreground bg-primary text-primary-foreground shadow-[2px_2px_0_0_var(--color-foreground)]">
  <Icon className="h-5 w-5" />
</span>
```

### Tag / Label
```tsx
<span className="rounded-md border-2 border-foreground bg-card px-2 py-0.5 font-mono text-[11px] font-bold text-foreground">
  LABEL
</span>
```

### Button（Google Sign-in 為基準）
```tsx
className="inline-flex items-center gap-2.5 rounded-xl border-2 border-foreground bg-card font-bold text-foreground shadow-[3px_3px_0_0_var(--color-foreground)] transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[5px_5px_0_0_var(--color-foreground)] active:translate-y-0 active:shadow-[2px_2px_0_0_var(--color-foreground)]"
```

### Service Card
```tsx
className="group flex flex-col items-start gap-4 rounded-2xl border-2 border-foreground p-5 text-left shadow-[4px_4px_0_0_var(--color-foreground)] transition-all duration-200 hover:-translate-y-1 hover:shadow-[7px_7px_0_0_var(--color-foreground)] active:translate-y-0 active:shadow-[3px_3px_0_0_var(--color-foreground)]"
```
Icon 在 hover 時加 `-rotate-6`；`ArrowUpRight` 加 `-translate-y-0.5 translate-x-0.5`。

### Inverted Card（深色背景）
```tsx
className="rounded-2xl border-2 border-foreground bg-foreground p-5 text-[oklch(0.99_0_0)] shadow-[4px_4px_0_0_var(--color-primary)]"
```
Shadow 色改用 `--color-primary`（綠）而非 foreground。

### Section Divider
```
border-b-2 border-dashed border-foreground/30
```

### 背景圖案（Hero dotted grid）
```tsx
<div
  aria-hidden
  className="pointer-events-none absolute inset-0 -z-10 opacity-[0.5]"
  style={{
    backgroundImage:
      "radial-gradient(color-mix(in oklch, var(--color-foreground) 16%, transparent) 1.4px, transparent 1.4px)",
    backgroundSize: "22px 22px",
    maskImage: "radial-gradient(75% 65% at 50% 0%, black, transparent)",
  }}
/>
```
點陣格 22×22px，點徑 1.4px，mask 從頂部向下淡出。
