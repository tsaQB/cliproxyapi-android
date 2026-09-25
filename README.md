# CLIProxyAPI for Android

[![Release](https://img.shields.io/github/v/release/tsaQB/cliproxyapi-android?style=flat-square&color=38bdf8)](https://github.com/tsaQB/cliproxyapi-android/releases/latest)
[![License](https://img.shields.io/github/license/tsaQB/cliproxyapi-android?style=flat-square&color=f59e0b)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%207.0%2B%20(ARM64)-emerald?style=flat-square)](#requirements)

High-Performance ARM64 Android service & native proxy for [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI).  
Supports both **Non-Root (Termux Native)** and **Root (Magisk / KernelSU / APatch)**.

**Author:** tsaQB

---

![CLIProxyAPI Banner](banner.png)

## ✨ Why This Distribution?

Official upstream CLIProxyAPI builds for generic Linux (`GOOS=linux`) fail on Android because pure Go resolvers look for `/etc/resolv.conf`, which does not exist on Android. This causes network and OAuth calls to fail with:
```text
lookup oauth2.googleapis.com on [::1]:53: read: connection refused
```

**This distribution solves the issue natively:**
- **Compiled with Android NDK (r27c, API 24+) & Bionic libc:** Uses native Android system DNS (`getaddrinfo` via `netd`).
- **100% Native Android:** Runs directly on bare-metal Android kernel with minimal RAM and zero emulation overhead.
- **Dual Mode:** Choose between a lightweight standalone Termux setup or a fully automated Magisk boot daemon.
- **Embedded WebUI Dashboard:** Pre-packaged with the official Management Center WebUI (`management.html`).

---

## ⚡ Quick Start

### 📱 Option 1: Termux (Non-Root Native) — Recommended

Install in Termux with the **One-Line Installer**:

```sh
curl -sL https://raw.githubusercontent.com/tsaQB/cliproxyapi-android/main/install.sh | bash
```

*(Or via alternative link: `curl -sL https://raw.githubusercontent.com/tsaQB/cliproxyapi-android/main/install-termux.sh | bash`)*

#### Quick Management Commands:
```sh
cliproxyapi start      # Start service in background
cliproxyapi status     # Check process status and port
cliproxyapi logs       # View live service logs
cliproxyapi update     # Upgrade binary & WebUI to latest release
cliproxyapi restart    # Restart service
cliproxyapi stop       # Stop background service
cliproxyapi run        # Run foreground in terminal
```

#### Access WebUI Dashboard:
* **URL:** `http://127.0.0.1:8317/management.html`
* **Default Password:** `admin123`

---

### ⚡ Option 2: Magisk / KernelSU / APatch (Root Boot Service)

1. Download **`cliproxyapi-magisk.zip`** from [Latest Release](https://github.com/tsaQB/cliproxyapi-android/releases/latest).
2. Flash the ZIP in **Magisk**, **KernelSU Next**, or **APatch**.
3. Reboot device.
4. Access WebUI at `http://127.0.0.1:8317/management.html` (Default Password: `admin123`).

---

## 🔑 Authentication & OAuth Setup

Authenticate providers via WebUI or CLI directly from Termux:

```sh
# Antigravity (Google / Gemini)
cliproxyapi -antigravity-login -no-browser

# Claude
cliproxyapi -claude-login -no-browser

# OpenAI / Codex
cliproxyapi -codex-device-login

# Kimi
cliproxyapi -kimi-login -no-browser

# xAI (Grok)
cliproxyapi -xai-login -no-browser
```

---

## 📁 System Paths & Reference

### Termux (Non-Root) Mode
| Component | Path / Command |
| :--- | :--- |
| **Data Directory** | `~/.cliproxyapi/` |
| **Config File** | `~/.cliproxyapi/config.yaml` |
| **Binary Executable** | `~/.cliproxyapi/bin/cli-proxy-api` |
| **Dashboard File** | `~/.cliproxyapi/static/management.html` |
| **Provider Credentials** | `~/.cliproxyapi/auths/` |
| **Service Logs** | `~/.cliproxyapi/logs/service.log` |
| **CLI Command** | `$PREFIX/bin/cliproxyapi` |

### Magisk (Root) Mode
| Component | Path / Command |
| :--- | :--- |
| **Data Directory** | `/data/adb/cliproxyapi/` |
| **Config File** | `/data/adb/cliproxyapi/config.yaml` |
| **Provider Credentials** | `/data/adb/cliproxyapi/auths/` |
| **App Logs** | `/data/adb/cliproxyapi/cliproxyapi.log` |
| **Watchdog Logs** | `/data/adb/cliproxyapi/watchdog.log` |
| **Change Password** | `cliproxyapi dashboard-password` |
| **Disable Service** | `touch /data/adb/cliproxyapi/disable` |
| **Restart Service** | `sh /data/adb/modules/cliproxyapi/service.sh` |

---

## 📄 License

Distributed under the [MIT License](LICENSE). Third-party software notices are available in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
