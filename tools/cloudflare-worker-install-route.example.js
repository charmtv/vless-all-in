/**
 * Cloudflare Worker：自定义域名上的 /install.sh
 *
 * 重要：必须 302 到 GitHub 的 install.sh，而不是 vless-server.sh。
 * 原因：用户执行 curl https://你的域名/install.sh | bash 时，若跳到 vless-server.sh，
 * bash 会把整份主脚本从管道读入，install.sh 里的「exec … </dev/tty」不会执行，菜单会异常。
 *
 * 正确 raw：https://raw.githubusercontent.com/charmtv/vless-all-in/main/install.sh
 */
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    if (path === "" || path === "/") {
      return Response.redirect(
        "https://github.com/charmtv/vless-all-in",
        302
      );
    }

    if (path.toLowerCase() === "/install.sh") {
      return Response.redirect(
        "https://raw.githubusercontent.com/charmtv/vless-all-in/main/install.sh",
        302
      );
    }

    return new Response("Not Found", { status: 404 });
  },
};
