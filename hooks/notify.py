#!/usr/bin/env python3
"""Desktop notification when Claude needs input.

Sends a desktop notification so you know when Claude has stopped and is
waiting for your response, useful when Claude is running long tasks in
the background and you've switched to another window.

PLATFORM SUPPORT:
  This script defaults to WSL (Windows Subsystem for Linux), using a
  PowerShell balloon tip. Commented-out alternatives for native Linux
  and macOS are provided below. Uncomment the one that matches your setup.

  A terminal bell (\\a) is always sent as an instant fallback regardless
  of platform.

SETUP (.claude/settings.json):
  {
    "hooks": {
      "Stop": [
        { "matcher": "", "hooks": [{ "type": "command", "command": "python3 /path/to/notify.py" }] }
      ]
    }
  }
"""
import subprocess
import sys

# Always send terminal bell as instant fallback
print("\a", end="", file=sys.stderr)

# ── CHOOSE YOUR PLATFORM ───────────────────────────────────────────────────────

# OPTION 1: WSL (Windows Subsystem for Linux): PowerShell balloon tip
# This is the default. Remove or comment out if you're on native Linux or macOS.
ps_script = r"""
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.ShowBalloonTip(5000, 'Claude Code', 'Claude Code needs your attention', 'Info')
Start-Sleep -Seconds 6
$notify.Dispose()
"""

try:
    subprocess.Popen(
        ["powershell.exe", "-NoProfile", "-Command", ps_script],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
except FileNotFoundError:
    pass
except Exception:
    pass

# ── ALTERNATIVE: Native Linux (uncomment to use instead of WSL option above) ──
# Requires: libnotify-bin (sudo apt install libnotify-bin)
#
# try:
#     subprocess.Popen(
#         ["notify-send", "Claude Code", "Claude Code needs your attention",
#          "--icon=dialog-information", "--expire-time=5000"],
#         stdout=subprocess.DEVNULL,
#         stderr=subprocess.DEVNULL,
#     )
# except FileNotFoundError:
#     pass
# except Exception:
#     pass

# ── ALTERNATIVE: macOS (uncomment to use instead of WSL option above) ─────────
#
# try:
#     subprocess.Popen(
#         ["osascript", "-e",
#          'display notification "Claude Code needs your attention" with title "Claude Code"'],
#         stdout=subprocess.DEVNULL,
#         stderr=subprocess.DEVNULL,
#     )
# except FileNotFoundError:
#     pass
# except Exception:
#     pass

sys.exit(0)
