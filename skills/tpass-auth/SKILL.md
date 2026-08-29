---
name: tpass-auth
description: T-Pass SSO 契約 v2 規則：登入/驗章/cookie/session/權限/permissions claim/entryYear/年級。新服務串接登入、除錯認證問題、code review 檢查 SSO 實作時使用。
---

# T-Pass SSO v2

## 驗章一律用 tpass-auth-js，禁止新寫 jwtVerify

```bash
pnpm add github:tschoolsu/tpass-auth-js#v1.1.1 jose   # 釘 tag，不要用 #main
```

`src/config/auth.ts` 一行綁 env，兩條 route（`api/auth/{callback,logout}/route.ts`）各一行呼叫
`tpass.callbackHandler` / `tpass.logoutHandler`。完整三檔範例見 `references/example.md`。

錯了會怎樣：手刻一份 `verifyToken`/`jwtVerify` 會重演 2026-08-27 前六服務各自手抄一份
`src/lib/tpass-auth.ts` 又互相漂移的狀況；漏掉任一項檢查時**登入照樣成功、CI 照樣綠**，只有拿
別服務的票來打才會暴露。不要復活 `src/lib/tpass-auth.ts` 這個檔名。

## 非 Next.js 才需要手刻：四鐵則

只有沒有現成 Next.js 集成、必須自己呼叫 `jose.jwtVerify` 時才用（正常情況一律走上面的套件）：
`algorithms: ["EdDSA"]` 鎖死（不鎖有 alg confusion 偽造風險）、檢查 `issuer`、
`audience === "tpass:<本服務id>"`（不是共用值，每服務專屬，漏檢查＝服務隔離全毀）、`exp`。
非 Next.js 完整範例見 `references/example.md`。

## Cookie：host-only，不設 Domain

不要寫 `Domain=.<根網域>`（已退場的 v1）。套件預設就是 host-only；手刻時確認 cookie 屬性沒有
`domain:` 欄位。

## 每個 route handler / server action 都要自己重驗權限

`layout` 擋了不代表 API 層也擋了——**server action 可以被直接 POST，繞過表單/UI**。授權判斷必須
寫在 action/handler 函式內部：

```ts
if (!perm.read) redirect(tpass.deniedUrl());
```

## 權限讀 permissions claim，groups 不存在

`groups` 已於 2026-07-27 全面移除（token 裡完全沒有這個欄位，不是 deprecated）。權限一律用
`tpass.permOf(session)`；`read` 是唯一必看欄位（`restriction !== "ban"` 已算好）。`permissions`
缺鍵時預設 `{ read: true, role: "default" }`，不要因缺資料誤鎖使用者。各服務不自維護 admin
allowlist——名單在 auth 的 `/admin` panel。

## entryYear 與年級：8 月分界 + 必須 fallback

年級不能直接從信箱前三碼算——休學復學的人信箱沿用、前綴不變，直接推算會多算一級。規則：
`entryYear` claim 缺失時 fallback 回信箱前三碼解析、學年度以 8 月為分界（`month >= 8 ?
rocYear : rocYear - 1`）、年級 = 學年度 − `entryYear` + 1。fallback 是必要的：token TTL 只有
45 分鐘，轉場期舊 token 還沒有這個 claim，少了 fallback 那段時間全部人的年級會變空白。程式碼見
`references/example.md`。只在有顯示年級的服務才需要這段。

## NODE_TLS_REJECT_UNAUTHORIZED=0 只能放消費端 package.json 的 dev script

```json
"dev": "NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --experimental-https ... -H <svc>.lvh.me -p <port>"
```

不可進 `.env`/build/start script/`ecosystem.config.js`。auth 服務本身與主機**永遠不加**（會關掉
全部 TLS 驗證，資安事故）。漏放在消費端 dev：本機登入完靜默被踢回登入頁、無錯誤訊息。

## 上線前隔離測試（最關鍵，容易漏）

拿別服務（例如 `service=portal`）的票打自己的 `/api/auth/callback`，應該回 401。這一步最容易被
漏掉，因為登入流程本身「看起來」正常——只有隔離測試能揪出 audience 檢查漏掉的錯誤。
