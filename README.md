# Codex System Proxy Fix for Windows

这是一个可安装的 Codex Skill，用 Codex 原生的 Windows 系统代理支持解决启动后反复“正在重新连接 5/5”、请求超时或部分请求绕过代理的问题。

安装后继续使用原来的 Codex 桌面图标、开始菜单或任务栏入口即可。本项目不会创建、替换或劫持任何快捷方式。

## 工作原理

技能会检查当前 Codex 版本，然后在 `~/.codex/config.toml` 中启用：

```toml
[features]
respect_system_proxy = true
```

它只改变 Codex 读取 Windows 系统代理的行为，不修改系统代理、WinHTTP、Git 配置或环境变量，也不会改变其他应用的网络行为。

Clash、FlClash 等软件切换节点时，本地代理入口通常保持不变，因此 Codex 会自动使用新节点。如果更换代理软件或修改本地端口，请完全退出并重新打开 Codex。

## 作为 Skill 安装

在另一台电脑的 Codex 中说：

```text
请从 https://github.com/mantuoluozk/codex-proxy-launcher-windows 安装这个 Skill，然后用它修复 Windows Codex 的代理重连问题。不要修改任何快捷方式或全局网络设置。
```

也可以显式调用：

```text
使用 $codex-windows-system-proxy 修复 Codex 的“正在重新连接 5/5”。
```

## 直接安装

不使用 Skill 时，可以克隆仓库并运行：

```powershell
git clone https://github.com/mantuoluozk/codex-proxy-launcher-windows.git
cd codex-proxy-launcher-windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

安装后从系统托盘彻底退出 Codex 一次，再通过原来的入口重新打开。

## 验证

```powershell
codex features list | Select-String respect_system_proxy
```

末尾显示 `true` 即为启用成功。

## 卸载

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Uninstall.ps1
```

卸载只删除 `respect_system_proxy` 这一项，不覆盖之后产生的其他 Codex 配置。

## 安全边界

- 不创建或修改任何快捷方式。
- 不调用 `setx`，不写入系统或用户环境变量。
- 不修改 Windows 系统代理和 WinHTTP。
- 不接触 Codex 登录令牌或代理订阅。
- 首次安装前备份现有 `config.toml`。

## 官方参考

- [Codex configuration reference](https://developers.openai.com/codex/config-reference/)
- [Codex configuration schema](https://developers.openai.com/codex/config-schema.json)

## License

MIT
