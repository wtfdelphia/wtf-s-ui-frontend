#!/usr/bin/env bash
# Verify the three frontend patches against their target bases and check
# dev-patch branch semantics. Run from a clone that has up/cloud remotes.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
cd "$REPO"

BASE="a4b8816"
UP_SHA="$(python3 -c "import json; print(json.load(open('$HERE/METADATA.json'))['up_sha'])")"
CLOUD_SHA="$(python3 -c "import json; print(json.load(open('$HERE/METADATA.json'))['cloud_sha'])")"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== 1) apply --check on each target base =="
for t in "01-up-main:$BASE" "02-cloud-main:$BASE" "03-up-on-cloud:$CLOUD_SHA"; do
  name="${t%%:*}"; base="${t##*:}"
  git worktree add -f "/tmp/fe-verify-$name" "$base" >/dev/null
  (cd "/tmp/fe-verify-$name" && git apply --check "$HERE/$name.patch") \
    || fail "$name does not apply cleanly on $base"
  git worktree remove -f "/tmp/fe-verify-$name"
done

echo "== 2) 01 reproduces up/main tree =="
git worktree add -f /tmp/fe-verify-01 "$BASE" >/dev/null
(cd /tmp/fe-verify-01 && git apply --index "$HERE/01-up-main.patch" \
  && git diff "$UP_SHA" --exit-code) || fail "01 result differs from up/main"
git worktree remove -f /tmp/fe-verify-01

echo "== 3) 02 reproduces cloud/main tree =="
git worktree add -f /tmp/fe-verify-02 "$BASE" >/dev/null
(cd /tmp/fe-verify-02 && git apply --index "$HERE/02-cloud-main.patch" \
  && git diff "$CLOUD_SHA" --exit-code) || fail "02 result differs from cloud/main"
git worktree remove -f /tmp/fe-verify-02

echo "== 4) 03 reproduces dev-custom tree =="
git worktree add -f /tmp/fe-verify-03 "$CLOUD_SHA" >/dev/null
(cd /tmp/fe-verify-03 && git apply --index "$HERE/03-up-on-cloud.patch" \
  && git diff dev-custom --exit-code) || fail "03 result differs from dev-custom"
git worktree remove -f /tmp/fe-verify-03

echo "== 5) dev-patch semantics: only patch/ differs from $BASE =="
[ -z "$(git diff "$BASE" dev-patch -- . ':!patch')" ] \
  || fail "dev-patch carries changes outside patch/"

echo "== 6) frontend builds on dev-custom =="
git worktree add -f /tmp/fe-verify-build dev-custom >/dev/null
( cd /tmp/fe-verify-build && npm ci >/dev/null && npm run build >/dev/null \
  && test -s dist/index.html ) || fail "build failed on dev-custom"
git worktree remove -f /tmp/fe-verify-build

echo "ALL CHECKS PASSED"
