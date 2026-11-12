#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd "${1:-.}" && pwd)
mkdir -p "${2:-.build}"
output_dir=$(cd "${2:-.build}" && pwd)
command -v latexmk >/dev/null || { echo 'Este necesar latexmk.' >&2; exit 1; }
cd "$source_dir"
if [[ -n "${3:-}" ]]; then
  source_files=("$3")
else
  mapfile -d '' source_files < <(find . -type f -name '*.tex' -not -path './.git/*' -print0)
fi
found=0
while IFS= read -r -d '' source_file; do
  if ! grep -q '\\documentclass' "$source_file"; then
    continue
  fi
  found=1
  relative_dir=$(dirname "$source_file")
  target_dir="$output_dir/$relative_dir"
  mkdir -p "$target_dir"
  (
    cd "$relative_dir"
    latexmk -pdf -g -interaction=nonstopmode -halt-on-error -file-line-error \
      -outdir="$target_dir" "$(basename "$source_file")"
  )
done < <(printf '%s\0' "${source_files[@]}")
if [[ "$found" == 0 ]]; then
  echo 'Nu s-au găsit documente LaTeX de compilat.' >&2
  exit 1
fi
