# CLIProxyAPI

[![Release](https://img.shields.io/github/v/release/tsaQB/cliproxyapi-module?style=flat-square&color=38bdf8)](https://github.com/tsaQB/cliproxyapi-module/releases/latest)
[![License](https://img.shields.io/github/license/tsaQB/cliproxyapi-module?style=flat-square&color=f59e0b)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%207.0%2B%20(ARM64)-emerald?style=flat-square)](#requirements)

High-Performance ARM64 Android service & native proxy for [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI), supporting both **Root (Magisk/KernelSU/APatch)** and **Non-Root (Termux Native)**.

**Author:** tsaQB

---

![CLIProxyAPI Banner](banner.png)

## ✨ Features

- **Native Android NDK Build:** Compiled for Android 7.0+ (API 24+) ARM64 with Bionic libc (fixes DNS resolution issues in Go on Android without requiring `proot`).
- **Dual Mode Support:**
  - **Root Mode:** Automatic boot service with crash watchdog via Magisk / KernelSU / APatch.
  - **Non-Root Mode:** Runs natively in Termux with background daemon control (`setsid`).
- **WebUI Management:** Bundled Management Dashboard (`management.html`).
- **Termux CLI Wrapper:** Easy management with `cliproxyapi` command (`start`, `stop`, `status`, `logs`).
- **Automated Upstream Sync:** GitHub Actions automatically checks and builds official releases every 12 hours.

---

## ⚡ Quick Start

### 📱 Option 1: Termux (Non-Root Native)
Install directly in Termux with one command:
```sh
curl -sL https://raw.githubusercontent.com/tsaQB/cliproxyapi-module/main/install-termux.sh | bash
```

Quick commands:
```sh
cliproxyapi start    # Start service in background
cliproxyapi status   # Check status and PID
cliproxyapi logs     # Follow live logs
cliproxyapi stop     # Stop service
```
Open Dashboard at `http://127.0.0.1:8317/management.html` (Password: `admin123`).

### ⚡ Option 2: Magisk / KernelSU / APatch (Root Boot Service)
1. Download **`cliproxyapi-magisk.zip`** from the [Latest Release](https://github.com/tsaQB/cliproxyapi-module/releases/latest).
2. Install the ZIP inside **KernelSU Next**, **APatch**, or **Magisk Manager**.
3. Reboot device.
4. Open WebUI at `http://127.0.0.1:8317/management.html` (Initial password: `admin123`).

---

## 🔑 Security & Password Rotation

To change the default dashboard password (`admin123`) from Termux:

```sh
cliproxyapi dashboard-password
```

---

## 💻 Termux CLI Commands

```sh
# View help & available flags
cliproxyapi -h

# Authenticate providers
cliproxyapi -antigravity-login -no-browser
cliproxyapi -claude-login -no-browser
cliproxyapi -codex-device-login
```

---

## 📁 System Paths & Control

| Component | Path / Command |
| :--- | :--- |
| **Config File** | `/data/adb/cliproxyapi/config.yaml` |
| **Provider Auths** | `/data/adb/cliproxyapi/auths/` |
| **App Logs** | `/data/adb/cliproxyapi/cliproxyapi.log` |
| **Disable Service** | `touch /data/adb/cliproxyapi/disable` |
| **Restart Service** | `sh /data/adb/modules/cliproxyapi/service.sh` |

---

## 📄 License

Distributed under the [MIT License](LICENSE). Third-party software notices are available in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
