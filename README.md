# Codex Proxy Launcher for Windows

一个只对 Codex 生效的 Windows 代理启动器。它不会修改系统代理、WinHTTP、用户环境变量或其他应用的网络设置。

## 解决什么问题

Codex Desktop 在 Windows 上可能出现启动后反复“正在重新连接 5/5”、请求超时，或部分请求绕过代理的问题。这个启动器会在每次启动 Codex 时：

1. 优先读取你显式指定的代理；
2. 自动读取 Windows 当前代理；
3. 尝试常见本地代理端口（7890、7897、10809、10808）；
4. 等待代理就绪并验证可以访问 ChatGPT；
5. 仅向 Codex 进程注入 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY`，并为 Chromium 设置 `--proxy-server`。

Clash、FlClash 等代理软件切换节点时，本地监听地址通常不变，因此 Codex 会自动使用新节点，无需重新安装。若你更换了代理软件或本地端口，请完全退出 Codex 后重新从代理快捷方式启动。

## 安装

先安装 Windows 版 Codex，并确保代理软件能正常工作。然后下载或克隆本仓库，在 PowerShell 中运行：

```powershell
git clone https://github.com/mantuoluozk/codex-proxy-launcher-windows.git
cd codex-proxy-launcher-windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

如果电脑上没有 Git，也可以在 GitHub 页面选择 **Code → Download ZIP**，解压后在该目录打开 PowerShell，再运行安装命令。

安装完成后，从桌面或开始菜单打开 `Codex (Proxy)`。

如果希望把桌面的 `Codex.lnk` 也替换为代理启动器（原快捷方式会备份为 `Codex (Original).lnk`）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -ReplaceDesktopShortcut
```

如果代理不在系统设置中，也不使用常见端口，可显式指定：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -Proxy http://127.0.0.1:7890
```

## 卸载

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Uninstall.ps1
```

卸载会删除代理快捷方式、恢复备份的桌面快捷方式，并删除启动器文件。它不会修改或卸载 Codex、代理软件，也不会改动全局网络设置。

## 排查

启动日志位于：

```text
%LOCALAPPDATA%\CodexProxyLauncher\launcher.log
```

如果提示 Codex 已在运行，请从系统托盘彻底退出 Codex，再使用 `Codex (Proxy)` 启动。

可以用自检模式验证代理和 Codex 安装路径，而不启动 Codex：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\src\Start-CodexWithProxy.ps1 -ValidateOnly
```

## 安全边界

- 代理变量只存在于 Codex 进程树中。
- 不调用 `setx`，不写入系统或用户环境变量。
- 不修改 Windows 系统代理和 WinHTTP。
- 不接触 Codex 登录令牌或代理订阅。

## License

MIT
