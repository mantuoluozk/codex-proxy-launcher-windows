---
name: codex-windows-system-proxy
description: Diagnose and fix Windows Codex Desktop reconnect loops or direct-connection failures by enabling Codex's native system-proxy support. Use when Codex fails despite a working Clash, FlClash, or other Windows system proxy. Do not use for phone Remote or general Windows network changes.
---

# Codex Windows System Proxy

Fix Codex Desktop without replacing shortcuts or changing networking for other applications.

## Workflow

1. Confirm the host is Windows and Codex Desktop is installed.
2. Read the current Windows user proxy from `HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings`. Do not modify it.
3. Check `codex features list` for `respect_system_proxy`. If absent, ask the user to update Codex; do not write an unsupported key.
4. When the user has asked to implement the fix, run `scripts/enable-system-proxy.ps1`.
5. Run `scripts/check-readiness.ps1`. Verify the system proxy is enabled and Codex reports `respect_system_proxy ... true`.
6. If `RestartRequired` is true, tell the user to fully exit Codex from the system tray once and reopen it from their original desktop, Start menu, or taskbar entry.

The script may edit only `~/.codex/config.toml`. It must not create or replace shortcuts, set proxy environment variables, change WinHTTP, modify the Windows proxy, or alter another application's configuration.

Switching proxy nodes behind the same local listener requires no Codex change. If the proxy application or local port changes, Codex may need to be restarted so it can read the updated Windows setting.

For removal, run `scripts/disable-system-proxy.ps1`; it removes only the setting managed by this skill.

Official references:

- [Codex configuration reference](https://developers.openai.com/codex/config-reference/)
- [Codex configuration schema](https://developers.openai.com/codex/config-schema.json)
