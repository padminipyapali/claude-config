#!/usr/bin/env bash
# tier0-audit.sh — Automated Tier 0 adversarial review checks
#
# Runs ALL mechanical grep checks from adversarial-review.md against the current
# branch's diff vs base. Produces structured PASS/FAIL output with exact evidence.
# No judgment, no skimming — the grep either matches or it doesn't.
#
# Usage:
#   tier0-audit.sh [--base <branch>] [--repo <path>]
#
# Defaults: --base main, --repo . (current directory)
#
# Exit codes:
#   0 = all checks passed (or skipped)
#   1 = one or more findings
#   2 = usage error

set -euo pipefail

# --- Args ---
BASE="main"
REPO="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

cd "$REPO"

# Verify we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "ERROR: $REPO is not a git repository."
  exit 2
fi

# Verify base branch exists
if ! git rev-parse --verify "$BASE" &>/dev/null; then
  echo "ERROR: base branch '$BASE' does not exist."
  exit 2
fi

# --- Setup ---
TOTAL=0
PASS=0
FAIL=0
SKIP=0
FINDINGS=()

# Changed files (cached for reuse)
CHANGED_FILES=$(git diff "$BASE"...HEAD --name-only 2>/dev/null || git diff "$BASE"..HEAD --name-only)
CHANGED_TS=$(echo "$CHANGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' || true)
CHANGED_TSX=$(echo "$CHANGED_FILES" | grep -E '\.(tsx|jsx)$' || true)
CHANGED_CSS=$(echo "$CHANGED_FILES" | grep -E '\.css$' || true)
CHANGED_HTML=$(echo "$CHANGED_FILES" | grep -E '\.(html|htm)$' || true)

# Diff content (cached)
DIFF_TS=""
if [[ -n "$CHANGED_TS" ]]; then
  DIFF_TS=$(git diff "$BASE"...HEAD -- '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null || git diff "$BASE"..HEAD -- '*.ts' '*.tsx' '*.js' '*.jsx')
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Helpers ---
check_start() {
  TOTAL=$((TOTAL + 1))
  printf "\n${CYAN}[%s]${RESET} %s\n" "$1" "$2"
}

check_pass() {
  PASS=$((PASS + 1))
  printf "  ${GREEN}PASS${RESET}: %s\n" "${1:-no matches}"
}

check_fail() {
  FAIL=$((FAIL + 1))
  FINDINGS+=("$1")
  printf "  ${RED}FAIL${RESET}: %s\n" "$1"
}

check_skip() {
  SKIP=$((SKIP + 1))
  printf "  ${YELLOW}SKIP${RESET}: %s\n" "$1"
}

print_output() {
  # Print grep output indented, capped at 20 lines
  local output="$1"
  if [[ -z "$output" ]]; then return; fi
  local count
  count=$(echo "$output" | wc -l | tr -d ' ')
  echo "$output" | head -20 | sed 's/^/    /'
  if [[ "$count" -gt 20 ]]; then
    printf "    ${YELLOW}... and %d more lines${RESET}\n" $((count - 20))
  fi
}

# --- Header ---
printf "${BOLD}Tier 0 Automated Adversarial Review${RESET}\n"
printf "Repo: %s\n" "$(pwd)"
printf "Base: %s\n" "$BASE"
count_lines() { if [[ -z "$1" ]]; then echo 0; else echo "$1" | grep -c . || echo 0; fi; }
printf "Changed files: %d (%d TS/JS, %d TSX/JSX, %d CSS)\n\n" \
  "$(count_lines "$CHANGED_FILES")" \
  "$(count_lines "$CHANGED_TS")" \
  "$(count_lines "$CHANGED_TSX")" \
  "$(count_lines "$CHANGED_CSS")"

if [[ -z "$CHANGED_FILES" ]]; then
  echo "No changed files vs $BASE. Nothing to check."
  exit 0
fi

# ============================================================
# 0.1 — UTC suffix on Date strings
# ============================================================
check_start "0.1" "UTC suffix on Date strings"
if [[ -z "$CHANGED_TS" ]]; then
  check_skip "no TS/JS files changed"
else
  result=$(echo "$CHANGED_TS" | tr '\n' '\0' | xargs -0 grep -nE 'new Date\("[^"]*T[0-9]{2}:[0-9]{2}:[0-9]{2}"\)' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Date strings without Z suffix"
    print_output "$result"
  fi
fi

# ============================================================
# 0.2 — Fire-and-forget without .catch()
# ============================================================
check_start "0.2" "Fire-and-forget without .catch()"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  result=$(echo "$DIFF_TS" | grep -E '^\+.*\b(then|finally)\(' | grep -vE '\.catch\(' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "then()/finally() without .catch() (heuristic — .catch may be on another line)"
    print_output "$result"
  fi
fi

# ============================================================
# 0.3 — Generic error swallowing
# ============================================================
check_start "0.3" "Generic error swallowing (catch → return []|null)"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  result=$(echo "$DIFF_TS" | grep -B3 -A1 'catch' | grep -E 'return \[\]|return null|return undefined' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Catch blocks returning generic defaults (heuristic — some may be legitimate)"
    print_output "$result"
  fi
fi

# ============================================================
# 0.4 — Non-semantic interactive elements (a11y)
# ============================================================
check_start "0.4" "Non-semantic interactive elements (role=\"button\" on non-buttons)"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=$(echo "$CHANGED_TSX" | tr '\n' '\0' | xargs -0 grep -nE 'role=\{?.*"button"' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "role=\"button\" on non-button elements — use <button type=\"button\"> instead"
    print_output "$result"
  fi
fi

# ============================================================
# 0.4b — Form inputs without accessible labels
# ============================================================
check_start "0.4b" "Form inputs without accessible labels"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      file=$(echo "$line" | cut -d: -f1)
      lineno=$(echo "$line" | cut -d: -f2)
      context=$(sed -n "$((lineno > 2 ? lineno-2 : 1)),$((lineno+2))p" "$file" 2>/dev/null || true)
      if ! echo "$context" | grep -qE 'aria-label|htmlFor|aria-labelledby|aria-describedby'; then
        result="${result}MISSING LABEL: ${line}"$'\n'
      fi
    done < <(grep -nE 'placeholder=' "$f" 2>/dev/null || true)
  done <<< "$CHANGED_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Inputs with placeholder but no accessible label"
    print_output "$result"
  fi
fi

# ============================================================
# 0.5 — Escape handler only on textarea (not container)
# ============================================================
check_start "0.5" "Escape handler scope (textarea vs container)"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qE 'onKeyDown.*Escape|Escape.*handleEdit' "$f" 2>/dev/null; then
      if ! grep -q 'onKeyDownCapture' "$f" 2>/dev/null; then
        result="${result}MISSING onKeyDownCapture: ${f}"$'\n'
      fi
    fi
  done <<< "$CHANGED_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Escape handler without onKeyDownCapture (may not fire on sibling focus)"
    print_output "$result"
  fi
fi

# ============================================================
# 0.6 — Date comparison without validity check
# ============================================================
check_start "0.6" "Date comparison without validity check"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  result=$(echo "$DIFF_TS" | grep -B5 -E 'new Date\(' | grep -E '(>|<|>=|<=)\s*new Date' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Date comparisons near new Date() — verify isNaN/isFinite guard exists"
    print_output "$result"
  fi
fi

# ============================================================
# 0.7 — Infinite CSS animations without prefers-reduced-motion
# ============================================================
check_start "0.7" "Infinite animations without prefers-reduced-motion"
ALL_CSS_TSX=$(printf '%s\n%s\n' "$CHANGED_CSS" "$CHANGED_TSX" | sed '/^$/d')
if [[ -z "$ALL_CSS_TSX" ]]; then
  check_skip "no CSS/TSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if grep -q 'animation:.*infinite' "$f" 2>/dev/null; then
      if ! grep -A10 'animation:.*infinite' "$f" | grep -q 'prefers-reduced-motion' 2>/dev/null; then
        result="${result}MISSING REDUCE: ${f}"$'\n'
      fi
    fi
  done <<< "$ALL_CSS_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Infinite animation without prefers-reduced-motion override"
    print_output "$result"
  fi
fi

# ============================================================
# 0.8 — SVG <title> inside labeled buttons
# ============================================================
check_start "0.8" "SVG <title> inside aria-labeled buttons (duplicate a11y)"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    while IFS= read -r svgline; do
      [[ -z "$svgline" ]] && continue
      svglineno=$(echo "$svgline" | cut -d: -f1)
      if sed -n "${svglineno},$((svglineno+3))p" "$f" 2>/dev/null | grep -q '<title>'; then
        parentlines=$(sed -n "1,${svglineno}p" "$f" | tail -20)
        if echo "$parentlines" | grep -qE '<(button|a).*aria-label'; then
          result="${result}DUPLICATE A11Y: ${f}:${svglineno} (SVG <title> with labeled parent)"$'\n'
        fi
      fi
    done < <(grep -n '<svg' "$f" 2>/dev/null || true)
  done <<< "$CHANGED_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "SVG <title> inside labeled parent — remove <title>, add aria-hidden to SVG"
    print_output "$result"
  fi
fi

# ============================================================
# 0.9 — Truthiness guard without .trim()
# ============================================================
check_start "0.9" "Truthiness guard on strings without .trim()"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  result=$(echo "$DIFF_TS" | grep -E '^\+' | grep -E 'if\s*\(\s*!(\w+)\s*\)' | grep -vE '\.trim\(\)' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Truthiness guard without .trim() (heuristic — whitespace-only strings are truthy)"
    print_output "$result"
  fi
fi

# ============================================================
# 0.10 — Raw interpolation in XML/HTML template strings
# ============================================================
check_start "0.10" "Raw interpolation in XML/HTML template strings"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  # `<[^`]*${ — matches interpolation in BOTH attribute position (<doc src="${x}">)
  # AND element content (<entry>${x}</entry>). The old `<\w+[^>]*${ stopped at the
  # first '>', silently missing the element-content wrap that is the commonest shape
  # for embedding untrusted user/LLM text as data in an AI prompt (second-brain #720).
  result=$(echo "$DIFF_TS" | grep -E '^\+.*`<[^`]*\$\{' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Template literal building HTML/XML with \${} interpolation — verify escaping"
    print_output "$result"
  fi
fi

# ============================================================
# 0.11 — DELETE + INSERT without transaction
# ============================================================
check_start "0.11" "DELETE + INSERT without transaction"
if [[ -z "$CHANGED_TS" ]]; then
  check_skip "no TS/JS files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if grep -q 'DELETE FROM' "$f" 2>/dev/null && grep -q 'INSERT INTO' "$f" 2>/dev/null; then
      if ! grep -qE 'BEGIN|transaction|COMMIT' "$f" 2>/dev/null; then
        result="${result}NO TRANSACTION: ${f} (has DELETE + INSERT without BEGIN/COMMIT)"$'\n'
      fi
    fi
  done <<< "$CHANGED_TS"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "DELETE + INSERT in same file without transaction wrapper"
    print_output "$result"
  fi
fi

# ============================================================
# 0.12 — Brittle error type detection via string matching
# ============================================================
check_start "0.12" "Error detection via string matching (brittle)"
if [[ -z "$CHANGED_TS" ]]; then
  check_skip "no TS/JS files changed"
else
  result=$(echo "$CHANGED_TS" | tr '\n' '\0' | xargs -0 grep -nE '\.message\.(includes|startsWith|match)\(' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Error type detection via .message string matching — use instanceof instead"
    print_output "$result"
  fi
fi

# ============================================================
# 0.13 — Focus-visible parity for new interactive elements
# ============================================================
check_start "0.13" "Focus-visible parity for new interactive elements"
if [[ -z "$CHANGED_CSS" ]]; then
  check_skip "no CSS files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    new_selectors=$(git diff "$BASE"...HEAD -- "$f" 2>/dev/null | grep -E '^\+.*\{' | grep -vE '^\+\+\+' | sed 's/+//' | tr -d '{ ' || true)
    if [[ -n "$new_selectors" ]]; then
      existing_focus=$(grep -c ':focus-visible' "$f" 2>/dev/null || echo 0)
      if [[ "$existing_focus" -gt 0 ]]; then
        while IFS= read -r sel; do
          clean=$(echo "$sel" | sed 's/[.#]//g' | tr -d '[:space:]')
          if [[ -n "$clean" ]] && ! grep -q "${clean}.*:focus-visible" "$f" 2>/dev/null; then
            result="${result}MISSING FOCUS-VISIBLE: ${f} selector '${sel}' (file has ${existing_focus} existing :focus-visible rules)"$'\n'
          fi
        done <<< "$new_selectors"
      fi
    fi
  done <<< "$CHANGED_CSS"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "New CSS selectors in files with existing :focus-visible — add matching rules"
    print_output "$result"
  fi
fi

# ============================================================
# 0.14 — iOS auto-zoom on small font-size inputs
# ============================================================
check_start "0.14" "iOS auto-zoom on small font-size inputs"
if [[ -z "$CHANGED_CSS" ]]; then
  check_skip "no CSS files changed"
else
  result=$(echo "$CHANGED_CSS" | tr '\n' '\0' | xargs -0 grep -nE '(input|textarea|\.chat-input|\.text-input).*font-size:\s*(0\.\d+rem|1[0-5]px|0\.[0-8]\d*em)' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Input font-size < 16px triggers iOS auto-zoom — use font-size: 1rem"
    print_output "$result"
  fi
fi

# ============================================================
# 0.15 — Render-phase setState
# ============================================================
check_start "0.15" "Render-phase setState"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=$(echo "$CHANGED_TSX" | tr '\n' '\0' | xargs -0 grep -nE 'if\s*\(.*\)\s*\{?\s*set[A-Z]' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Conditional setState — verify it's inside useEffect/useCallback/event handler, not render body"
    print_output "$result"
  fi
fi

# ============================================================
# 0.16 — Stale async response guards
# ============================================================
check_start "0.16" "Stale async response guards (setState after await)"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! grep -qE 'useCallback' "$f" 2>/dev/null; then continue; fi
    while IFS= read -r awaitline; do
      [[ -z "$awaitline" ]] && continue
      lineno=$(echo "$awaitline" | cut -d: -f1)
      tail_lines=$(sed -n "${lineno},\$p" "$f" 2>/dev/null | head -10)
      if echo "$tail_lines" | grep -qE 'set[A-Z]'; then
        if ! grep -qE 'isMountedRef|currentKeyRef|abortController|signal|AbortController' "$f" 2>/dev/null; then
          result="${result}STALE ASYNC: ${f}:${lineno} (setState after await without mount/key guard)"$'\n'
        fi
      fi
    done < <(grep -n 'await' "$f" 2>/dev/null || true)
  done <<< "$CHANGED_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "setState after await without staleness guard"
    print_output "$result"
  fi
fi

# ============================================================
# 0.17 — Conditional UI branch completeness
# ============================================================
check_start "0.17" "Conditional UI branches (boolean-gated rendering)"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=$(echo "$CHANGED_TSX" | tr '\n' '\0' | xargs -0 grep -nE 'if\s*\(\s*(is|has|show|hide|can)[A-Z]' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Boolean-gated UI branches — verify tests cover BOTH true and false paths"
    print_output "$result"
  fi
fi

# ============================================================
# 0.18 — Undefined CSS custom properties
# ============================================================
check_start "0.18" "Undefined CSS custom properties"
if [[ -z "$CHANGED_CSS" ]]; then
  check_skip "no CSS files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    used=$(git diff "$BASE"...HEAD -- "$f" 2>/dev/null | grep '^+' | grep -v '^+++' | grep -oE 'var\(--[a-zA-Z0-9_-]+' | sed 's/var(//g' | sort -u || true)
    defined=$(grep -oE -- '--[a-zA-Z0-9_-]+:' "$f" 2>/dev/null | sed 's/:$//' | sort -u || true)
    for var in $used; do
      if ! echo "$defined" | grep -Fxq -- "$var"; then
        result="${result}UNDEFINED CSS VAR: ${f} uses ${var}"$'\n'
      fi
    done
  done <<< "$CHANGED_CSS"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "CSS var() references to undefined custom properties"
    print_output "$result"
  fi
fi

# ============================================================
# 0.19 — white-space pre-wrap + line-clamp co-occurrence
# ============================================================
check_start "0.19" "white-space pre-wrap + line-clamp conflict"
if [[ -z "$ALL_CSS_TSX" ]]; then
  check_skip "no CSS/TSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    has_prewrap=$(grep -lE 'white-space:\s*(pre-wrap|pre-line)' "$f" 2>/dev/null || true)
    has_clamp=$(grep -lE '(-webkit-)?line-clamp' "$f" 2>/dev/null || true)
    if [[ -n "$has_prewrap" ]] && [[ -n "$has_clamp" ]]; then
      result="${result}CONFLICT: ${f} has both white-space:pre-wrap/pre-line AND line-clamp"$'\n'
      grep -nE 'white-space:\s*(pre-wrap|pre-line)|(-webkit-)?line-clamp' "$f" 2>/dev/null | sed 's/^/  /' >> /dev/null
      context=$(grep -nE 'white-space:\s*(pre-wrap|pre-line)|(-webkit-)?line-clamp' "$f" 2>/dev/null || true)
      result="${result}${context}"$'\n'
    fi
  done <<< "$ALL_CSS_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "pre-wrap/pre-line defeats line-clamp truncation"
    print_output "$result"
  fi
fi

# ============================================================
# 0.20 — Animation without prefers-reduced-motion
# ============================================================
check_start "0.20" "Any animation without prefers-reduced-motion"
if [[ -z "$ALL_CSS_TSX" ]]; then
  check_skip "no CSS/TSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    has_animation=$(grep -lE '^\s*animation\s*:' "$f" 2>/dev/null || true)
    has_reduced_motion=$(grep -lE 'prefers-reduced-motion' "$f" 2>/dev/null || true)
    if [[ -n "$has_animation" ]] && [[ -z "$has_reduced_motion" ]]; then
      result="${result}MISSING reduced-motion: ${f} has animation: but no prefers-reduced-motion query"$'\n'
      context=$(grep -nE '^\s*animation\s*:' "$f" 2>/dev/null || true)
      result="${result}${context}"$'\n'
    fi
  done <<< "$ALL_CSS_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "Animation declarations without prefers-reduced-motion override"
    print_output "$result"
  fi
fi

# ============================================================
# 0.21 — hour12: false (midnight returns "24")
# ============================================================
check_start "0.21" "hour12: false (midnight returns '24' — use hourCycle: 'h23')"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  result=$(echo "$DIFF_TS" | grep -n 'hour12:\s*false' 2>/dev/null || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "hour12: false can return '24' at midnight — use hourCycle: 'h23' instead"
    print_output "$result"
  fi
fi

# ============================================================
# 0.22 — autoFocus attribute (a11y)
# ============================================================
check_start "0.22" "autoFocus attribute (a11y — disrupts screen reader flow)"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  result=$(echo "$DIFF_TS" | grep -n 'autoFocus\|autofocus' 2>/dev/null | grep -E '^\+' || true)
  # Also check HTML files
  if [[ -n "$CHANGED_HTML" ]]; then
    html_result=$(git diff "$BASE"...HEAD -- '*.html' '*.htm' 2>/dev/null | grep -n 'autoFocus\|autofocus' | grep -E '^\+' || true)
    result="${result}${html_result}"
  fi
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "autoFocus disrupts screen reader flow — manage focus programmatically instead"
    print_output "$result"
  fi
fi

# ============================================================
# 0.23 — Express JSON body parser without size limit
# ============================================================
check_start "0.23" "express.json() without size limit"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  result=$(echo "$DIFF_TS" | grep -n 'express\.json()' | grep -v 'limit' || true)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "express.json() without { limit: 'Nkb' } allows arbitrarily large payloads"
    print_output "$result"
  fi
fi

# ============================================================
# 0.24 — Nested interactive elements (a11y)
# ============================================================
check_start "0.24" "nested interactive elements"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    # Find files with role="button" that also contain <button — potential nesting
    if grep -qE 'role=.*"button"' "$f" 2>/dev/null && grep -q '<button' "$f" 2>/dev/null; then
      # Use awk to detect <button inside role="button" containers (within 30-line window)
      matches=$(awk '
        /role=.*"button"/ { container_start=NR; container_line=NR }
        /<button/ && container_start > 0 && NR > container_start && NR <= container_start+30 {
          print FILENAME ":" NR ": <button> nested inside role=\"button\" parent (line " container_line ")"
        }
        # Also detect <button inside <button
        /<button/ { if (btn_depth > 0) print FILENAME ":" NR ": <button> nested inside <button> (line " btn_start ")"; btn_depth++; btn_start=NR }
        /<\/button>/ { if (btn_depth > 0) btn_depth-- }
      ' "$f" 2>/dev/null || true)
      if [[ -n "$matches" ]]; then
        result="${result}${matches}"$'\n'
      fi
    fi
    # Also check for nested <button> elements (without role="button")
    btn_count=$(grep -c '<button' "$f" 2>/dev/null || true)
    if [[ "$btn_count" -gt 1 ]]; then
      nested=$(awk '
        /<button/ { if (depth > 0) print FILENAME ":" NR ": <button> nested inside <button> (line " start ")"; depth++; start=NR }
        /<\/button>/ { if (depth > 0) depth-- }
      ' "$f" 2>/dev/null || true)
      if [[ -n "$nested" ]]; then
        result="${result}${nested}"$'\n'
      fi
    fi
  done <<< "$CHANGED_TSX"
  result=$(echo "$result" | sed '/^$/d' | sort -u)
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "nested <button> or <button> inside role=\"button\" — browsers strip inner button silently"
    print_output "$result"
  fi
fi

# ============================================================
# BONUS: Button type audit (from Tier 3, but grepable)
# ============================================================
check_start "B.1" "Buttons without explicit type attribute"
if [[ -z "$CHANGED_TSX" ]]; then
  check_skip "no TSX/JSX files changed"
else
  result=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    # Find <button without type= on the same or next line
    matches=$(grep -nE '<button\b' "$f" 2>/dev/null | grep -v 'type=' || true)
    if [[ -n "$matches" ]]; then
      result="${result}${matches}"$'\n'
    fi
  done <<< "$CHANGED_TSX"
  result=$(echo "$result" | sed '/^$/d')
  if [[ -z "$result" ]]; then
    check_pass
  else
    check_fail "<button> without type= defaults to submit — add type=\"button\" or type=\"submit\""
    print_output "$result"
  fi
fi

# ============================================================
# BONUS: Semantic change signals (Step 2 from adversarial-review.md)
# ============================================================
check_start "S.1" "Semantic change signals detected (for Tier 1-4 targeting)"
if [[ -z "$DIFF_TS" ]]; then
  check_skip "no TS/JS diff"
else
  signals=""
  echo "$DIFF_TS" | grep -qE 'includes\(|has\(|new Set\(|VALID_|ALLOWED_' && signals="${signals}  restriction-introduced\n"
  echo "$DIFF_TS" | grep -qE 'return res\.status\(400\)|throw.*[Ii]nvalid|throw.*Error' && signals="${signals}  validation-added\n"
  echo "$DIFF_TS" | grep -qE "type.*=.*\||enum \{" && signals="${signals}  enum-changed\n"
  echo "$DIFF_TS" | grep -qE '^\-.*\|.*'"'"'|^\-.*enum ' && signals="${signals}  value-removed\n"
  echo "$DIFF_TS" | grep -qE '^\+.*throw' && signals="${signals}  error-behavior-changed\n"

  if [[ -z "$signals" ]]; then
    printf "  ${GREEN}No semantic signals detected${RESET} — Tier 1-4 judgment checks may be minimal.\n"
  else
    printf "  ${YELLOW}Signals detected — these trigger mandatory Tier 1-4 checklist items:${RESET}\n"
    printf "$signals" | sed 's/^/    /'
  fi
  # This is informational, not pass/fail
  TOTAL=$((TOTAL - 1))
fi

# ============================================================
# Summary
# ============================================================
printf "\n${BOLD}═══════════════════════════════════════════${RESET}\n"
printf "${BOLD}Tier 0 Summary${RESET}\n"
printf "${BOLD}═══════════════════════════════════════════${RESET}\n"
printf "Checks run:    %d\n" "$TOTAL"
printf "${GREEN}Passed:        %d${RESET}\n" "$PASS"
printf "${RED}Failed:        %d${RESET}\n" "$FAIL"
printf "${YELLOW}Skipped:       %d${RESET}\n" "$SKIP"

if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  printf "\n${RED}${BOLD}Findings to fix:${RESET}\n"
  for i in "${!FINDINGS[@]}"; do
    printf "  ${RED}%d.${RESET} %s\n" $((i + 1)) "${FINDINGS[$i]}"
  done
  printf "\n${RED}Fix all findings before proceeding to Tier 1+ review.${RESET}\n"
  exit 1
else
  printf "\n${GREEN}All Tier 0 checks passed.${RESET} Proceed to Tier 1+ judgment review.\n"
  exit 0
fi
