#!/usr/bin/env bash
# 一键下载并执行主脚本（与仓库 main 分支 vless-server.sh 一致）
# 用法: curl -fsSL https://raw.githubusercontent.com/charmtv/mlnbvless-all-in/main/install.sh | bash
set -euo pipefail
readonly RAW_BASE="https://raw.githubusercontent.com/charmtv/mlnbvless-all-in/main"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  fi
}

curl -fsSL -o "$TMP_DIR/vless-server.sh" "${RAW_BASE}/vless-server.sh"
curl -fsSL -o "$TMP_DIR/SHA256SUMS" "${RAW_BASE}/SHA256SUMS"
expected="$(awk '$2 == "vless-server.sh" || $2 == "*vless-server.sh" {print $1; exit}' "$TMP_DIR/SHA256SUMS")"
actual="$(sha256_file "$TMP_DIR/vless-server.sh")"
[[ -n "$expected" && "${actual,,}" == "${expected,,}" ]] || { echo "vless-server.sh SHA256 校验失败" >&2; exit 1; }
bash -n "$TMP_DIR/vless-server.sh"
install -m 755 "$TMP_DIR/vless-server.sh" ./vless-server.sh
# curl … | bash 时当前 shell 的 stdin 是管道，直接 exec 子脚本会继承管道，菜单 read 立刻 EOF。
# 显式把主脚本的 stdin 接到终端，子菜单/选项才能正常输入。
if [[ -r /dev/tty ]]; then
  exec ./vless-server.sh "$@" </dev/tty
else
  exec ./vless-server.sh "$@"
fi
