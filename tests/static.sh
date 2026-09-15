#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

bash -n vless-server.sh
bash -n install.sh
bash -n tools/upgrade-from-github.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck --severity=error vless-server.sh
  shellcheck install.sh tools/upgrade-from-github.sh
fi

grep -Fq 'PROTO_SVC[anytls]="vless-singbox"' vless-server.sh
grep -Fq 'PROTO_KIND[anytls]="singbox"' vless-server.sh
if grep -Fq 'PROTO_SVC[anytls]="vless-anytls"' vless-server.sh; then
  echo "AnyTLS 不应再注册为独立服务" >&2
  exit 1
fi
if grep -Fq '/usr/local/bin/anytls-server -l' vless-server.sh; then
  echo "AnyTLS 不应再使用旧版独立进程" >&2
  exit 1
fi
if grep -Fq '${DB_FILE}.tmp' vless-server.sh; then
  echo "数据库临时文件必须使用唯一文件名" >&2
  exit 1
fi
if grep -Fq 'http://ip-api.com' vless-server.sh; then
  echo "公网地理位置查询必须使用 HTTPS" >&2
  exit 1
fi
grep -Fq 'SCRIPT_CHECKSUM_URL=' vless-server.sh

old_repo_name='mlnbvless''-all-in'
if grep -RFn --exclude-dir=.git "$old_repo_name" .; then
  echo "仓库中不应再保留旧项目名" >&2
  exit 1
fi

expected="$(awk '$2 == "vless-server.sh" || $2 == "*vless-server.sh" {print $1; exit}' SHA256SUMS)"
actual="$(sha256sum vless-server.sh | awk '{print $1}')"
[[ -n "$expected" && "$actual" == "$expected" ]] || {
  echo "SHA256SUMS 与 vless-server.sh 不一致" >&2
  exit 1
}

echo "静态检查通过"
