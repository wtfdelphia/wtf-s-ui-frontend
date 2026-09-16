#!/usr/bin/env bash
# Apply 03-up-on-cloud.patch on top of the targeted cloud/main commit and
# build the customized frontend.
#
# Usage: patch/apply.sh <target-dir>
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${1:?usage: apply.sh <target-dir>}"

REPO_URL="https://github.com/wtfdelphia/wtf-s-ui-frontend.git"
TARGET="$(python3 -c "import json; print(json.load(open('$HERE/METADATA.json'))['patch3_target'])")"

if [ ! -d "$WORK/.git" ]; then
  git clone "$REPO_URL" "$WORK"
fi
cd "$WORK"
git fetch origin
git checkout -f "$TARGET"

git apply --index "$HERE/03-up-on-cloud.patch"

npm ci
npm run build
test -s dist/index.html || { echo "FAIL: dist/index.html missing" >&2; exit 1; }

echo "OK: frontend built in $WORK/dist"
