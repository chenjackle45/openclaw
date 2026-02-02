#!/bin/bash
# 檢查 docs.json 中的所有路徑是否存在對應文件
# 用法: ./check-docs-json.sh

set -e

DOCS_JSON="docs/docs.json"

if [ ! -f "$DOCS_JSON" ]; then
  echo "錯誤: $DOCS_JSON 不存在"
  exit 1
fi

echo "=== 檢查 docs.json 路徑 ==="

missing=0
jq -r '.. | select(type == "string") | select(startswith("zh-Hant/"))' "$DOCS_JSON" 2>/dev/null | \
  sort -u | \
  while read page; do
    file="docs/${page}.md"
    if [ ! -f "$file" ]; then
      echo "缺少: $file"
      missing=$((missing + 1))
    fi
  done

if [ "$missing" -eq 0 ]; then
  echo "所有路徑都存在對應文件"
fi
