#!/usr/bin/env bash
# Read-only: report each cloned MCP repo's install state + type. No installs.
cd "$(dirname "$0")" || exit 1
repos=$(find external internal-host internal-ad cloud container code _build -maxdepth 3 -name .git -type d 2>/dev/null | sed 's#/.git##' | sort)
printf "%-40s %-8s %-8s %s\n" "REPO" "TYPE" "STATE" "NOTE"
printf "%-40s %-8s %-8s %s\n" "----" "----" "-----" "----"
for d in $repos; do
  type="?"; state="pending"; note=""
  if   [ -f "$d/package.json" ]; then type="npm"
  elif [ -f "$d/pyproject.toml" ]; then type="py"
  elif [ -f "$d/requirements.txt" ]; then type="py-req"
  elif [ -f "$d/go.mod" ]; then type="go"
  elif ls "$d"/*.gemspec "$d"/Gemfile >/dev/null 2>&1; then type="ruby"
  elif ls "$d"/build.gradle* >/dev/null 2>&1; then type="gradle"
  fi
  case "$type" in
    npm)    [ -d "$d/node_modules" ] && state="DONE" || note="no node_modules" ;;
    py|py-req)
       if [ -d "$d/.venv" ]; then
         n=$("$d/.venv/bin/pip" list 2>/dev/null | wc -l)
         if [ "$n" -gt 3 ]; then state="DONE"; note="$n pkgs"; else state="FAILED"; note="venv but empty ($n pkgs)"; fi
       else note="no .venv"; fi ;;
    go)     ls "$d"/*mcp* "$d"/main 2>/dev/null | grep -q . && state="DONE?" || note="not built" ;;
    ruby)   note="manual (bundler/omnibus)" ;;
    gradle) note="needs Burp+gradle" ;;
    *)      note="no known manifest at top" ;;
  esac
  printf "%-40s %-8s %-8s %s\n" "$d" "$type" "$state" "$note"
done
