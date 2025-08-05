#!/bin/zsh
target=$1

if [[ -d "$target" ]]; then
  ls -G "$target"
elif [[ -f "$target" ]]; then
  case "${target:l}" in
    *taskfile.yml) task -t "$target" -l ;;
    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.tiff) viu -w 80 "$target" ;;
    *.md) COLUMNS=$FZF_PREVIEW_COLUMNS mdless -p "$target" ;;
    *.cow) cowsay -f "./$target" "What would you have me say?" ;;
    *) bat --style=plain --color=always --line-range :100 "$target" ;;
  esac
else
  if command -v man >/dev/null && man "$target" >/dev/null 2>&1; then
    man "$target" | col -bx | head -n 100
  else
    echo "No preview available for: $target"
  fi
fi
