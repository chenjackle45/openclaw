#!/bin/bash
# 找出需要翻譯的文件
# 用法: ./find-changed-docs.sh <base-commit> <latest-tag>

set -e

BASE_COMMIT="$1"
LATEST_TAG="$2"

if [ -z "$BASE_COMMIT" ] || [ -z "$LATEST_TAG" ]; then
  echo "用法: $0 <base-commit> <latest-tag>"
  exit 1
fi

echo "=== 需要更新的文件（英文版有變動，繁中版存在）==="
git diff --name-only "$BASE_COMMIT".."$LATEST_TAG" -- docs/ | \
  grep -v "zh-Hant" | grep -v "zh-CN" | grep "\.md$" | \
  while read f; do
    rel="${f#docs/}"
    zh_file="docs/zh-Hant/$rel"
    if [ -f "$zh_file" ]; then
      echo "$rel"
    fi
  done

echo ""
echo "=== 需要新增的文件（英文版有變動，繁中版不存在）==="
git diff --name-only "$BASE_COMMIT".."$LATEST_TAG" -- docs/ | \
  grep -v "zh-Hant" | grep -v "zh-CN" | grep "\.md$" | \
  while read f; do
    rel="${f#docs/}"
    zh_file="docs/zh-Hant/$rel"
    if [ ! -f "$zh_file" ]; then
      echo "$rel"
    fi
  done
