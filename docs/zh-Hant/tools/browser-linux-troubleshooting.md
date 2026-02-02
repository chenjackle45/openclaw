---
summary: "Fix Chrome/Brave/Edge/Chromium CDP startup issues for OpenClaw browser control on Linux"
read_when: "Browser control fails on Linux, especially with snap Chromium"
title: "Browser Troubleshooting"
---

# Browser Troubleshooting (Linux)

## Problem: "Failed to start Chrome CDP on port 18800"

OpenClaw's browser control server fails to launch Chrome/Brave/Edge/Chromium with the error:

```
{"error":"Error: Failed to start Chrome CDP on port 18800 for profile \"openclaw\"."}
```

### Root Cause

On Ubuntu (and many Linux distros), the default Chromium installation is a **snap package**. Snap's AppArmor confinement interferes with how OpenClaw spawns and monitors the browser process.

The `apt install chromium` command installs a stub package that redirects to snap:

```
Note, selecting 'chromium-browser' instead of 'chromium'
chromium-browser is already the newest version (2:1snap1-0ubuntu2).
```

This is NOT a real browser — it's just a wrapper.

### Solution 1: Install Google Chrome (Recommended)

Install the official Google Chrome `.deb` package, which is not sandboxed by snap:

```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y  # if there are dependency errors
```

Then update your OpenClaw config (`~/.openclaw/openclaw.json`):

```json
{
  "browser": {
    "enabled": true,
    "executablePath": "/usr/bin/google-chrome-stable",
    "headless": true,
    "noSandbox": true
  }
}
```

Then restart the gateway and try again:

```bash
pkill -f openclaw-gateway
openclaw gateway run
```

### Solution 2: Use snap Chromium with attach-only mode

If you must use snap Chromium, configure OpenClaw to only attach to a browser you launch manually:

1. Update config:

```json
{
  "browser": {
    "attachOnly": true
  }
}
```

2. Launch Chromium manually:

```bash
chromium-browser --headless --no-sandbox --disable-gpu \
  --remote-debugging-port=18800 \
  --user-data-dir=$HOME/.openclaw/browser/openclaw/user-data \
  about:blank &
```

3. (Advanced) Set up a systemd service or cron job to auto-start the above.

### Solution 3: Use WSL2 (if on Windows)

If you are on Windows, using WSL2 (Windows Subsystem for Linux) can simplify browser setup:

```bash
# Inside WSL2
sudo apt-get install -y google-chrome-stable
# Then set executablePath: "/usr/bin/google-chrome-stable"
```

## Verify the browser is working

Use `curl` to test the local API:

```bash
# Check status
curl -s http://127.0.0.1:18791/ | jq '{running, pid, chosenBrowser}'

# Start and list tabs
curl -s -X POST http://127.0.0.1:18791/start
curl -s http://127.0.0.1:18791/tabs
```

## Common issue: "Chrome extension relay is running, but no tab is connected"

This means you are using the `chrome` profile (extension relay mode) and the system is waiting for the extension to connect a tab.

- **Fix 1**: Use the managed browser instead: `openclaw browser start --browser-profile openclaw`
- **Fix 2**: Install the Chrome extension, open a tab, and click the extension icon to attach.
