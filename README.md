# vless-all-in-one

面向 Linux 服务器的多协议代理部署与管理脚本，提供协议安装、用户管理、流量统计、路由分流、订阅生成、证书和服务管理。

## 支持能力

- Xray：VLESS、VMess、Trojan、SOCKS5、Shadowsocks 2022
- Sing-box：Hysteria2、TUIC、AnyTLS
- 独立组件：Snell v4/v5、ShadowTLS、NaiveProxy
- 多协议共存、IPv4/IPv6、端口跳跃、WARP/Realm、Cloudflare Tunnel
- systemd 与 OpenRC 服务管理

## 系统要求

- Debian、Ubuntu、AlmaLinux/Rocky Linux/CentOS 兼容系统或 Alpine Linux
- `amd64` 或 `arm64`；部分第三方组件同时支持 `armv7`
- root 权限
- 可访问 GitHub Releases、系统软件源和所选证书服务

建议先在全新的测试服务器验证，再用于已有生产服务器。脚本会安装软件包、修改防火墙规则、创建系统服务并写入定时任务。

## 快速安装

```bash
curl -fsSL https://raw.githubusercontent.com/charmtv/vless-all-in/main/install.sh | bash
```

安装器会下载 `vless-server.sh` 和仓库中的 `SHA256SUMS`，校验通过并完成 Bash 语法检查后才执行。

也可以手动运行：

```bash
wget -O vless-server.sh https://raw.githubusercontent.com/charmtv/vless-all-in/main/vless-server.sh
wget -O SHA256SUMS https://raw.githubusercontent.com/charmtv/vless-all-in/main/SHA256SUMS
sha256sum -c SHA256SUMS
chmod +x vless-server.sh
sudo ./vless-server.sh
```

安装成功后使用快捷命令：

```bash
sudo ml
```

申请真实证书时脚本会询问 ACME 通知邮箱，也可以预先设置 `ACME_EMAIL=你的邮箱`。

## 升级与回滚

菜单中的“检查脚本更新”会校验 SHA256 和脚本语法，然后备份当前脚本为 `vless-server.sh.bak` 并原子替换。

也可以执行：

```bash
curl -fsSL https://raw.githubusercontent.com/charmtv/vless-all-in/main/tools/upgrade-from-github.sh | sudo bash
```

如需手动回滚：

```bash
sudo cp /usr/local/bin/vless-server.sh.bak /usr/local/bin/vless-server.sh
sudo chmod 755 /usr/local/bin/vless-server.sh
```

重要配置位于 `/etc/vless-reality/`。升级或批量调整前建议备份该目录，其中 `db.json` 和 `telegram.json` 包含用户凭据，应保持 `600` 权限。

## 订阅兼容性

- `/sub/<uuid>/mihomo`：Mihomo、Clash Meta、Clash Verge 等，保留 VLESS、Reality、Hysteria2、TUIC、AnyTLS 等能力。
- `/sub/<uuid>/clash`：经典 Clash 兼容格式，只输出通用协议，避免不支持新字段时整份导入失败。
- `/sub/<uuid>/v2ray`：通用 Base64 分享链接订阅，适合 v2rayN、v2rayNG、Loon 等客户端。

未填写域名时，订阅服务默认使用 HTTP，避免自签名 HTTPS 证书导致客户端无法拉取。纯 IP 场景强制使用 HTTPS 时，客户端需要显式信任证书或允许跳过验证。

## 常用排查

```bash
sudo ml --help
sudo ml --show-traffic
sudo systemctl status vless-reality vless-singbox
sudo journalctl -u vless-reality -u vless-singbox -n 100 --no-pager
sudo xray run -test -config /etc/vless-reality/config.json
sudo sing-box check -c /etc/vless-reality/singbox.json
```

Alpine Linux 请将 `systemctl`/`journalctl` 命令替换为对应的 `rc-service` 和系统日志命令。

## 开发检查

```bash
bash tests/static.sh
```

每次修改 `vless-server.sh` 后需要同步更新 `SHA256SUMS`：

```bash
sha256sum vless-server.sh > SHA256SUMS
```

安全问题请参阅 [SECURITY.md](SECURITY.md)，版本变化参阅 [CHANGELOG.md](CHANGELOG.md)。
