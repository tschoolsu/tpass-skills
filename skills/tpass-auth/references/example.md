# SSO 串接最小範例

摘自 `tpass-portal`（消費端參考實作）。

`src/config/portal.ts`（env 綁定）：

```ts
import "server-only";
import { configFromEnv, createTpassNextAuth } from "tpass-auth-js/next";

// 缺必填 env 就直接 throw（fail closed）。REQUIRED 清單真相在套件裡：
// AUTH_JWKS_URL / AUTH_AUTHORIZE_URL / AUTH_LOGOUT_URL / TPASS_SERVICE_ID / JWT_ISSUER
// ＋這裡指定的「自己的網址」那一顆。
export const tpass = createTpassNextAuth(configFromEnv("PORTAL_SELF_URL"));

export function loginUrlFor(returnPath = "/"): string {
  return tpass.loginUrl(returnPath);
}

export function deniedUrlFor(serviceId: string): string {
  return tpass.deniedUrl(serviceId);
}
```

`src/app/api/auth/callback/route.ts`：

```ts
import { tpass } from "@/config/portal";

export const runtime = "nodejs";
export const POST = tpass.callbackHandler;
```

`src/app/api/auth/logout/route.ts`：

```ts
import { tpass } from "@/config/portal";

export const runtime = "nodejs";
export const POST = tpass.logoutHandler;
```

Server component 讀 session：

```ts
import { redirect } from "next/navigation";
import { tpass } from "@/config/auth";

export default async function Page() {
  const session = await tpass.getSession();
  if (!session) redirect(tpass.loginUrl("/"));

  const perm = tpass.permOf(session);
  if (!perm.read) redirect(tpass.deniedUrl());
  if (perm.role === "admin") { /* … */ }

  return <p>{session.name}</p>;
}
```

entryYear → 年級（8 月為學年度分界，`entryYear` 缺失時 fallback 回信箱解析）：

```ts
const entry = typeof payload.entryYear === "number"
  ? payload.entryYear
  : parseEntryYearFromEmail(email);         // fallback：舊 token 沒有這個 claim
const academicYear = month >= 8 ? rocYear : rocYear - 1;  // 學年度 8 月跳新
const grade = entry === null ? null : academicYear - entry + 1;
```

非 Next.js（純 `jose` 依賴，無框架相依）：

```ts
import { createTpassAuth } from "tpass-auth-js";

const tpass = createTpassAuth({ jwksUrl, issuer, serviceId, selfUrl, authorizeUrl, authLogoutUrl });
const session = await tpass.verifyToken(tokenFromYourOwnCookie);
```
