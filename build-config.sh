#!/usr/bin/env bash
set -euo pipefail

output_file="config.toml"

> "$output_file"

files_to_merge=(
    "base.toml"
    "vim.keymapping.toml"
)

for file in "${files_to_merge[@]}"; do
    if [ -f "$file" ]; then
        echo "# From file: $file" >> "$output_file"
        cat "$file" >> "$output_file"
        echo -e "\n" >> "$output_file"
    else
        echo "Warning: File $file not found, skipping..." >&2
    fi
done
