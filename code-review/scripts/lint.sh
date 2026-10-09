#!/usr/bin/env bash
# lint.sh - run whatever linters are installed for the files or folder given.
#
# Usage:  scripts/lint.sh <file-or-directory>
#
# Detects the language from file extensions and runs available tools:
#   JavaScript / TypeScript : eslint (npx, local project config only)
#   Python                  : ruff, else flake8
#   Shell                   : shellcheck
#   Java                    : checkstyle (if on PATH), else javac -Xlint syntax check
#   JSON                    : python3 -m json.tool
#   Any                     : generic checks (trailing whitespace, tabs, TODO/FIXME,
#                             debug output, likely hardcoded secrets)
#
# It never modifies files. Missing tools are reported as "skipped", not as failures.
# Exit code: 0 = no problems found, 1 = problems found, 2 = bad usage.

set -u

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <file-or-directory>" >&2
  exit 2
fi

if [[ ! -e "$TARGET" ]]; then
  echo "Error: '$TARGET' does not exist." >&2
  exit 2
fi

PROBLEMS=0

have() { command -v "$1" >/dev/null 2>&1; }

section() { printf '\n== %s ==\n' "$1"; }

note_problem() { PROBLEMS=1; }

# Collect files (skip common vendor/build folders)
mapfile -t FILES < <(
  if [[ -d "$TARGET" ]]; then
    find "$TARGET" -type f \
      -not -path '*/node_modules/*' \
      -not -path '*/.git/*' \
      -not -path '*/target/*' \
      -not -path '*/build/*' \
      -not -path '*/dist/*' \
      -not -path '*/.venv/*' \
      -not -path '*/__pycache__/*' 2>/dev/null
  else
    printf '%s\n' "$TARGET"
  fi
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No files found under '$TARGET'."
  exit 0
fi

filter_ext() {
  local pattern="$1"
  local f
  for f in "${FILES[@]}"; do
    [[ "$f" =~ $pattern ]] && printf '%s\n' "$f"
  done
}

mapfile -t JS_FILES < <(filter_ext '\.(js|jsx|ts|tsx|mjs|cjs)$')
mapfile -t PY_FILES < <(filter_ext '\.py$')
mapfile -t SH_FILES < <(filter_ext '\.(sh|bash)$')
mapfile -t JAVA_FILES < <(filter_ext '\.java$')
mapfile -t JSON_FILES < <(filter_ext '\.json$')

echo "Linting: $TARGET (${#FILES[@]} files)"

# ---------- JavaScript / TypeScript ----------
if [[ ${#JS_FILES[@]} -gt 0 ]]; then
  section "JavaScript / TypeScript (${#JS_FILES[@]} files)"
  if have npx && { ls .eslintrc* eslint.config.* >/dev/null 2>&1 || grep -q '"eslintConfig"' package.json 2>/dev/null; }; then
    npx --no-install eslint "${JS_FILES[@]}" || note_problem
  else
    echo "skipped: eslint or an ESLint config was not found in the current directory"
  fi
fi

# ---------- Python ----------
if [[ ${#PY_FILES[@]} -gt 0 ]]; then
  section "Python (${#PY_FILES[@]} files)"
  if have ruff; then
    ruff check "${PY_FILES[@]}" || note_problem
  elif have flake8; then
    flake8 "${PY_FILES[@]}" || note_problem
  else
    echo "skipped: neither ruff nor flake8 is installed"
  fi
fi

# ---------- Shell ----------
if [[ ${#SH_FILES[@]} -gt 0 ]]; then
  section "Shell (${#SH_FILES[@]} files)"
  if have shellcheck; then
    shellcheck "${SH_FILES[@]}" || note_problem
  else
    echo "skipped: shellcheck is not installed"
  fi
fi

# ---------- Java ----------
if [[ ${#JAVA_FILES[@]} -gt 0 ]]; then
  section "Java (${#JAVA_FILES[@]} files)"
  if have checkstyle; then
    checkstyle -c /sun_checks.xml "${JAVA_FILES[@]}" || note_problem
  elif have javac; then
    OUT_DIR="$(mktemp -d)"
    # Syntax-level check only; unresolved imports from project dependencies are expected.
    javac -Xlint:all -proc:none -d "$OUT_DIR" "${JAVA_FILES[@]}" 2>&1 \
      | grep -v 'package .* does not exist' \
      | grep -v 'cannot find symbol' || true
    rm -rf "$OUT_DIR"
    echo "note: javac check is syntax-level only; build with Maven/Gradle for full results"
  else
    echo "skipped: neither checkstyle nor javac is installed"
  fi
fi

# ---------- JSON ----------
if [[ ${#JSON_FILES[@]} -gt 0 ]]; then
  section "JSON (${#JSON_FILES[@]} files)"
  if have python3; then
    for f in "${JSON_FILES[@]}"; do
      if ! python3 -m json.tool "$f" >/dev/null 2>&1; then
        echo "invalid JSON: $f"
        note_problem
      fi
    done
    [[ $PROBLEMS -eq 0 ]] && echo "ok"
  else
    echo "skipped: python3 is not installed"
  fi
fi

# ---------- Generic checks (all text files) ----------
section "Generic checks"

TEXT_FILES=()
for f in "${FILES[@]}"; do
  # skip binary files
  if grep -Iq . "$f" 2>/dev/null; then
    TEXT_FILES+=("$f")
  fi
done

GENERIC_FOUND=0

report() {
  # $1 = label, remaining = grep output lines
  local label="$1"; shift
  if [[ -n "${1:-}" ]]; then
    printf '%s\n' "-- $label"
    printf '%s\n' "$@"
    GENERIC_FOUND=1
  fi
}

if [[ ${#TEXT_FILES[@]} -gt 0 ]]; then
  TRAILING="$(grep -nE '[[:space:]]+$' "${TEXT_FILES[@]}" 2>/dev/null | head -n 20)"
  report "trailing whitespace (first 20)" "$TRAILING"

  TODOS="$(grep -nE '\b(TODO|FIXME|HACK|XXX)\b' "${TEXT_FILES[@]}" 2>/dev/null | head -n 20)"
  report "TODO / FIXME markers (first 20)" "$TODOS"

  DEBUG="$(grep -nE 'console\.log\(|System\.out\.print|printStackTrace\(|\bdebugger\b|\bprint\(.*DEBUG' "${TEXT_FILES[@]}" 2>/dev/null | head -n 20)"
  report "debug output (first 20)" "$DEBUG"

  # Likely hardcoded secrets. Values are masked so the report never prints the secret itself.
  SECRETS="$(grep -nEi '(api[_-]?key|secret|passwd|password|token|private[_-]?key)[[:space:]]*[:=][[:space:]]*["'\''][^"'\'' ]{8,}["'\'']' "${TEXT_FILES[@]}" 2>/dev/null \
    | sed -E 's/([:=][[:space:]]*["'\''])[^"'\'']+(["'\''])/\1***\2/' | head -n 20)"
  if [[ -n "$SECRETS" ]]; then
    printf '%s\n' "-- possible hardcoded secrets (values masked)"
    printf '%s\n' "$SECRETS"
    GENERIC_FOUND=1
    note_problem
  fi
fi

[[ $GENERIC_FOUND -eq 0 ]] && echo "ok"

# ---------- Result ----------
section "Result"
if [[ $PROBLEMS -eq 0 ]]; then
  echo "No blocking problems found by the tools that ran."
  echo "Tools reported as skipped did not run; do not treat them as passed."
  exit 0
else
  echo "Problems found. See output above."
  exit 1
fi
