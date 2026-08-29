---
name: tpass-service
description: T-Pass 服務慣例：新服務、註冊表 services.json、env 設定、port、pnpm、Next 16 / React 19 陷阱。開新服務、改 tpass-registry、寫 config/*.ts、遇到 Next.js API 跟預期不同時使用。
---

# T-Pass 服務慣例

## 註冊表是唯一真相，不硬編碼

服務 id / 目錄 / 子網域 / port / DB 策略 / 大廳卡片全在 `tpass-registry/services.json`，只透過對它開 PR 新增或修改，不在別的 repo（portal/auth）硬編碼服務清單或 URL。

`icon` 必須是 lucide-react 的 PascalCase 名，且必須已在 `tpass-portal/src/config/icons.ts` 白名單裡——registry 的 `validate.mjs` 只驗格式（PascalCase），**不驗是否在白名單**，白名單外的名字要等 portal 部署時才會炸（真實事故：2026-08-26 `CalendarDays` 不在白名單）。清單外的圖示要在 PR 說明裡提一句，讓維運同步加進 `icons.ts`。

## 網域 / issuer / URL 全 env 驅動

不寫死網域，包含「感覺不像 code」的地方（行銷文案、footer、meta 標籤）——`tpass-portal/HeroSection.tsx` 曾經寫死 `tschool.edu.tw` 就是真實漏網案例。服務自己的必填 env 用這個模式（SSO 那六顆 env 由 `tpass-auth-js` 自己檢查，不用重複寫）：

```ts
const REQUIRED = ["PORTAL_URL", "ANON_HASH_SECRET"] as const;
const missing = REQUIRED.filter((key) => !process.env[key]);
if (missing.length > 0) {
  throw new Error(`[config/xxx] 缺少必填環境變數：${missing.join(", ")}（請檢查 .env.local）`);
}
```

## pnpm-only

`pnpm add` / `pnpm install`，不要 npm/yarn，不要產生 `package-lock.json` 或 `yarn.lock`（混用會產生第二份鎖檔導致主機部署行為不一致）。

## 本機 dev 必須 HTTPS + lvh.me + 對的 port

```json
"dev": "NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --experimental-https --experimental-https-key $HOME/tpass-certs/key.pem --experimental-https-cert $HOME/tpass-certs/cert.pem -H <svc>.lvh.me -p <port>"
```

用 `localhost` 或漏掉 `-H`/`-p` 對應值：cookie 網域、`redirect_uri`、`aud` 全部對不上，登入必然失敗，且症狀跟少放 `NODE_TLS_REJECT_UNAUTHORIZED=0` 很像，容易混淆排查方向（SSO 的 TLS/cookie 細節見 `tpass-auth` skill）。

## Next 16 / React 19：不是你訓練資料裡的 Next.js

以下都是破壞性變更，模型會直覺當成同步 API 而寫錯：

- `cookies()` 是 **async**，必須 `await cookies()`。
- Route handler 的 `ctx.params` 是 **async**，需要 `await`。
- Page/Layout 的 `params`、`searchParams` 是 **async**（Promise）。
- Route 的型別（`RouteContext` 等）是 **產生物**，住在 `.next/types/`；全新 clone 沒跑過 `next typegen` 時 `tsc --noEmit` 會噴 `Cannot find name 'RouteContext'`（push 前的 `check` 流程已含這步，不用手動記，見下）。
- Server action **可被直接 POST**（繞過表單/UI），授權判斷必須寫在 action 函式內部——見 `tpass-auth` skill「每個 route handler / server action 都要自己重驗權限」。
- 若服務開了 React Compiler（`reactCompiler: true`）：render 期不可呼叫 `Date.now()`、不可讀 ref、effect 內不可同步 `setState`，這些寫法會被靜默錯誤 memoize。

寫 code 前先讀 `node_modules/next/dist/docs/` 確認 API 是否跟預期不同。

## webhook / callback 類設定欄位要 pin 官方網域

管理員可填的 webhook URL（例如 Discord）不能讓填任意網址，要 pin 官方網域（如僅允許 `discord.com`/`discordapp.com`），否則變成 SSRF / 任意外連跳板。

## push 前

跑 `pnpm lint && pnpm exec tsc --noEmit`（`scripts/tpass check` 做的就是這件事，含前置的 `next typegen`）。詳細上線步驟見 `docs/handbook/01-new-service.md`，不重抄。
