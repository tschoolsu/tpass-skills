#!/usr/bin/env bash
# T-Pass 規則檢查：純文字 grep，涵蓋 design system / SSO 紅線 / 硬編碼網域 / lockfile。
# 在服務 repo 根目錄執行。有命中就印出「檔案:行」並在結尾 exit 1；全乾淨 exit 0。
#
# 只收「模型推不出來、錯了很貴、且目前沒有其他機制擋住」的規則（見 tpass-skills 調研）。
# CI 已經擋的（lint/tsc/next typegen）不重複做。
set -euo pipefail

SCAN_DIR="${1:-src}"
FAILED=0

# 排除：build 產物、依賴、.claude/worktrees（agent 的舊分支 scratch，不是現行程式碼）。
EXCLUDES=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next --exclude-dir=dist --exclude-dir=.claude)

# grep 找不到東西時 exit 1，這裡用 if 包住，不讓 set -e 把腳本弄死。
report() {
  local title="$1"
  shift
  local hits
  if hits=$(grep -rn "${EXCLUDES[@]}" "$@" 2>/dev/null); then
    echo "== ${title} =="
    echo "$hits"
    echo
    FAILED=1
  fi
}

echo "T-Pass 規則檢查（掃描目錄：${SCAN_DIR}）"
echo

# ---------- B1 設計系統違規 ----------

# hex 顏色（禁止，僅允許 OKLCH）。
# 已知例外：global-error.tsx（root layout 都炸掉時拿不到 Tailwind/CSS 變數，只能 inline hex）、
# HeroSection.tsx（Google 官方登入按鈕 logo，品牌色本來就是 hex，不能改 OKLCH）。
if hits=$(grep -rnE "${EXCLUDES[@]}" '#[0-9a-fA-F]{3,8}\b' "$SCAN_DIR" \
    --include='*.tsx' --include='*.ts' --include='*.css' 2>/dev/null \
    | grep -v 'global-error\.tsx' | grep -v 'HeroSection\.tsx'); then
  echo "== hex 顏色（禁止，一律 OKLCH） =="
  echo "$hits"
  echo
  FAILED=1
fi

report "rgb()/rgba()（禁止，一律 OKLCH）" -E 'rgb\(|rgba\(' "$SCAN_DIR" \
  --include='*.tsx' --include='*.ts' --include='*.css'

report "dark mode 前綴（禁止，嚴格 light-only）" 'dark:' "$SCAN_DIR" --include='*.tsx'

report "soft shadow（禁止，一律 hard offset shadow）" -E 'shadow-(sm|md|lg|xl|2xl)\b' "$SCAN_DIR" --include='*.tsx'

# 只抓具名 Tailwind 尺度（rounded-3xl 以上）。任意值 rounded-[Npx] 大小不一
# （小圓角、頭像圓形都合法用這個語法），grep 判斷不了數值大小，留給人眼審查。
report "圓角超過 rounded-2xl（例外只有 rounded-full 頭像）" -E 'rounded-[3-9]xl\b' "$SCAN_DIR" --include='*.tsx'

# ---------- B2 SSO / 安全紅線 ----------

if hits=$(find "$SCAN_DIR" -path '*/lib/tpass-auth.ts' -not -path '*/node_modules/*' -not -path '*/.claude/*' 2>/dev/null); then
  if [ -n "$hits" ]; then
    echo "== 手抄驗章檔案復活（本身存在就是違規，改去 tpass-auth-js 改） =="
    echo "$hits"
    echo
    FAILED=1
  fi
fi

if hits=$(grep -rn "${EXCLUDES[@]}" 'localStorage' "$SCAN_DIR" --include='*.ts' --include='*.tsx' 2>/dev/null | grep -i token); then
  echo "== localStorage 疑似存 token（cookie 是 HttpOnly，本來就拿不到） =="
  echo "$hits"
  echo
  FAILED=1
fi

report "groups claim 復活（2026-07-27 起不存在，讀 permissions）" -E '\.groups\b|groups\.includes' "$SCAN_DIR" \
  --include='*.ts' --include='*.tsx'

if hits=$(grep -rniE "${EXCLUDES[@]}" "domain\\s*[:=]\\s*['\"]\\.?" "$SCAN_DIR" --include='*.ts' --include='*.tsx' 2>/dev/null | grep -i cookie); then
  echo "== cookie 設 Domain（host-only 才對，不該有 domain） =="
  echo "$hits"
  echo
  FAILED=1
fi

# v1 遺物：程式碼本身（src/）+ 會被複製散布的 .env.example 範本。
# 不查 .env / .env.local（個人本機檔案，未進 git，沒人會照抄）。
report "v1 遺物（程式碼，2026-07-13 已移除，不該再出現）" -E 'JWT_AUDIENCE|TPASS_COOKIE_NAME|tschool-sso|tpass_session' "$SCAN_DIR" \
  --include='*.ts' --include='*.tsx'

if hits=$(grep -rnE "${EXCLUDES[@]}" 'JWT_AUDIENCE|TPASS_COOKIE_NAME|tschool-sso|tpass_session' . --include='*.env.example' 2>/dev/null); then
  echo "== v1 遺物（.env.example 範本，2026-07-13 已移除，不該再出現） =="
  echo "$hits"
  echo
  FAILED=1
fi

report "手刻 jwtVerify/algorithms（正常情況一律用 tpass-auth-js）" -E 'jwtVerify|algorithms\s*:' "$SCAN_DIR" --include='*.ts'

# ---------- B3 硬編碼網域 / 服務清單 ----------

report "硬編碼正式或本機網域（應該全部來自 env）" -E '\btschoolsu\.org\b|\btschool\.tp\.edu\.tw\b|\btschool\.edu\.tw\b|\.lvh\.me\b' "$SCAN_DIR" \
  --include='*.tsx'

if hits=$(grep -rnE "${EXCLUDES[@]}" '\btschoolsu\.org\b|\btschool\.tp\.edu\.tw\b|\btschool\.edu\.tw\b|\.lvh\.me\b' "$SCAN_DIR" \
    --include='*.ts' 2>/dev/null | grep -v '\.test\.ts:'); then
  echo "== 硬編碼正式或本機網域（應該全部來自 env） =="
  echo "$hits"
  echo
  FAILED=1
fi

report "硬編碼別的服務 URL" -E 'https?://[a-z]+\.(lvh\.me|tschoolsu\.org)' "$SCAN_DIR" \
  --include='*.tsx'

if hits=$(grep -rnE "${EXCLUDES[@]}" 'https?://[a-z]+\.(lvh\.me|tschoolsu\.org)' "$SCAN_DIR" \
    --include='*.ts' 2>/dev/null | grep -v '\.test\.ts:'); then
  echo "== 硬編碼別的服務 URL =="
  echo "$hits"
  echo
  FAILED=1
fi

# ---------- B5 套件管理 ----------

if hits=$(find . -maxdepth 2 \( -name 'package-lock.json' -o -name 'yarn.lock' \) 2>/dev/null); then
  if [ -n "$hits" ]; then
    echo "== 不該有 npm/yarn 鎖檔（pnpm-only） =="
    echo "$hits"
    echo
    FAILED=1
  fi
fi

if [ "$FAILED" -eq 0 ]; then
  echo "全部乾淨。"
  exit 0
else
  echo "發現違規，見上方。"
  exit 1
fi
