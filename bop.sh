#!/usr/bin/env bash

BOOKMARK_DIR="${1:-$HOME/Documents}"
BOOKMARK_FILE=$(ls -t "$BOOKMARK_DIR"/*bookmarks*.html 2>/dev/null | head -n 1)

BROWSER_CMD=""
# for linux
if command -v xdg-open >/dev/null 2>&1; then
  BROWSER_CMD="xdg-open"
# for macOS
elif command -v open >/dev/null 2>&1; then
  BROWSER_CMD="open"
# for windows
elif command -v start >/dev/null 2>&1; then
  BROWSER_CMD="start"
else
  echo "ERROR: xdg-open or open or start command was not found"
  exit 1
fi

extract_bookmarks() {
  gawk '
  BEGIN {
    path_depth = 0
  }
  /<H3/ {
    match($0, /<H3[^>]*>([^<]+)<\/H3>/, m)
    if (m[1]) {
      path[++path_depth] = m[1]
    }
  }
  /<\/DL>/ {
    if (path_depth > 0) {
      delete path[path_depth--]
    }
  }
  /<A HREF=/ {
    match($0, /<A HREF="([^"]+)".*>([^<]+)<\/A>/, n)
    if (n[1] && n[2]) {
      full_path = ""
      for (i = 1; i <= path_depth; i++) {
        full_path = full_path path[i] "/"
      }
      print full_path n[2] "\t" n[1]
    }
  }
  ' "$BOOKMARK_FILE"
}

main() {
  selection=$(extract_bookmarks | fzf --exact --prompt="Bookmark > " )

  if [[ -z "$selection" ]]; then
    exit 0
  fi

  url=$(echo "$selection" | awk -F'\t' '{print $2}')

  $BROWSER_CMD "$url" &>/dev/null &
}

main
