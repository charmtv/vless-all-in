#!/usr/bin/env bash
# 在已安装过脚本的 Linux 服务器上以 root 执行：从 GitHub main 拉取最新 vless-server.sh，
# 覆盖 /usr/local/bin/vless-server.sh，并重建 ml 快捷方式（修复菜单 stdin 等需依赖线上最新文件）。
# 用法: curl -fsSL https://raw.githubusercontent.com/charmtv/mlnbvless-all-in/main/tools/upgrade-from-github.sh | bash
#   或: bash upgrade-from-github.sh
set -euo pipefail

[[ "${EUID:-0}" -eq 0 ]] || { echo "请使用 root 执行: sudo bash $0"; exit 1; }

readonly RAW_BASE="https://raw.githubusercontent.com/charmtv/mlnbvless-all-in/main"
readonly TARGET="/usr/local/bin/vless-server.sh"
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

echo "[upgrade] 下载 ${RAW_BASE}/vless-server.sh ..."
curl -fsSL -o "$TMP_DIR/vless-server.sh" "${RAW_BASE}/vless-server.sh"
curl -fsSL -o "$TMP_DIR/SHA256SUMS" "${RAW_BASE}/SHA256SUMS"
expected="$(awk '$2 == "vless-server.sh" || $2 == "*vless-server.sh" {print $1; exit}' "$TMP_DIR/SHA256SUMS")"
actual="$(sha256_file "$TMP_DIR/vless-server.sh")"
[[ -n "$expected" && "${actual,,}" == "${expected,,}" ]] || { echo "[upgrade] SHA256 校验失败" >&2; exit 1; }
bash -n "$TMP_DIR/vless-server.sh"
install -m 755 "$TMP_DIR/vless-server.sh" "$TARGET"

echo "[upgrade] 更新快捷命令 ml ..."
rm -f /usr/local/bin/vless /usr/bin/vless 2>/dev/null || true
ln -sf "$TARGET" /usr/local/bin/ml
ln -sf "$TARGET" /usr/bin/ml
hash -r 2>/dev/null || true

echo "[upgrade] 完成。请执行: ml"
echo "[upgrade] 若使用「curl 域名/install.sh | bash」，请确保 GitHub 上 install.sh 已更新（含 </dev/tty>）。"
