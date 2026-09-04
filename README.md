<div align="center">

# ⚡ Ultimate Extreme Debloat & System Latency Optimizer

**Modular low-latency optimizer, telemetry stripper, and bloatware remover for Windows 10 and Windows 11.**

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Insider-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/blayk11)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://github.com/blayk11)
[![Author](https://img.shields.io/badge/Author-blayk11-black?style=for-the-badge&logo=github)](https://github.com/blayk11)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](https://github.com/blayk11)

</div>

---

## ⚡ Quick Start (Instant One-Liner)

Open **PowerShell** (as Administrator) and paste the following command:

```powershell
irm https://raw.githubusercontent.com/blayk11/ultimatedebloat/main/ExtremeDebloat.ps1 | iex
```

> **Note**: No manual repository cloning or file downloading required. The command fetches and executes the utility directly in memory with full interactive TUI support.

---

## 📌 Overview

**Ultimate Extreme Debloat & System Latency Optimizer** is an advanced PowerShell utility engineered to turn stock Windows installations into ultra-responsive, stripped-down, high-performance environments with minimal input lag, zero micro-stutters, and complete privacy.

Unlike traditional scripts that execute blind batch commands, this tool features a custom **Interactive Terminal User Interface (TUI)** built from the ground up, allowing you to preview, navigate, and selectively toggle exactly what you want to modify or remove.

---

## ✨ Highlights

* 🎮 **Flicker-Free Interactive TUI**: Built with dynamic pagination and in-memory cursor repositioning (`Zero-Flicker` engine), providing smooth keyboard-driven navigation across any console size.
* 🛡️ **Safety First**: Integrated automatic creation of **System Restore Points** before applying system-level registry or service changes.
* 🧩 **100% Modular**: Customize individual components via interactive menus with checkboxes `[X]` / `[ ]`, or run the automated **Full Turbo Mode**.
* ⚡ **Kernel & Hardware Scheduling**: Fine-tuned CPU quantum (`Win32PrioritySeparation`), GPU scheduling priorities, and multimedia system responsiveness for maximum gaming FPS and consistent frametimes.
* 🔇 **Deep Telemetry & Bloatware Stripping**: Complete eradication of background diagnostic tracking, File Explorer ads, Windows Copilot, Recall snapshots, and pre-installed provisioned UWP apps.

---

## 🖥️ Terminal UI Preview

```text
==========================================================================
         ULTIMATE EXTREME DEBLOAT & SYSTEM LATENCY OPTIMIZER              
             Created by: blayk11 | https://github.com/blayk11             
==========================================================================
 [CATEGORY]: REMOVE BLOATWARES & APPS (UWP)
 Select items with [SPACE] to permanently remove.
 ------------------------------------------------------------------------
 [Arrows / PgUp / PgDn]: Navigate  |  [Space]: Toggle [X]
 [A]: Select All   |   [N]: Deselect All   |   [I]: Invert
 [Enter]: Confirm & Execute  |  [ESC / Q]: Cancel / Back
 ========================================================================
   ^ (... more items above ...)
 > [X] Weather (Bing Weather)
   [X] News (Bing News)
   [X] Finance (Bing Finance)
   [X] Get Help
   [ ] Alarms & Clock
   [X] Clipchamp Video Editor
   [X] Microsoft Copilot App
   v (... more items below ...)
 [ Item 1 of 37 | Selected: 32/37 ] --------------------------------------
```

### 🎮 Navigation & Keyboard Controls

| Key / Shortcut | Action |
| :--- | :--- |
| `▲ / ▼` (Arrow Keys) | Navigate items one-by-one with real-time cursor highlight |
| `Page Up / Page Down` | Jump blocks of items for fast browsing |
| `Home / End` | Jump directly to the top or bottom of the list |
| `Spacebar` | Toggle checkbox on the active item (`[X]` / `[ ]`) |
| `A` | **Select All** items in the current category |
| `N` | **Deselect All** items |
| `I` | **Invert** the current selection |
| `Enter` | **Confirm and execute** modifications for selected items |
| `ESC` or `Q` | Cancel and return to the main menu without changes |

---

## 📦 System Modules

### 1. 🛡️ System Restore Point
Creates a safe system checkpoint (`Checkpoint-Computer`) to ensure rollback capability prior to modifying system registries or services.

### 2. 🗑️ UWP Bloatware & App Purge
Completely uninstalls for the current user and deprovisions from the OS image all promotional bloatware (Bing Suite, Clipchamp, Copilot, Feedback Hub, Solitaire, sponsored games, TikTok, Disney+, unused Xbox overlays, etc.).

### 3. 🔒 Telemetry, AI & Ad Stripping
* Disables Bing Search & Web Integration in the Start Menu.
* Disables Microsoft Copilot AI and Windows Recall snapshot analysis.
* Eliminates File Explorer promotional suggestions and Lock Screen ads.
* Disables diagnostic data collection, background telemetry, and user activity feeds.

### 4. ⚙️ Background Services Optimization
Safely stops and disables heavy background services causing unnecessary CPU cycles and SSD disk thrashing:
* `SysMain` (Superfetch - eliminates unnecessary I/O overhead on NVMe/SSD)
* `DiagTrack` & `dmwappushservice` (Connected User Experiences & Telemetry)
* `MapsBroker`, `Fax`, `RetailDemo`, `WpcMonSvc`, `WerSvc`, `PcaSvc`, etc.

### 5. 🚀 Universal Latency & Hardware Scheduling (CPU / RAM / GPU)
* **Win32PrioritySeparation = 38**: Short, variable quantum intervals giving maximum CPU thread priority to foreground apps and games.
* **GameDVR & Background Capture Disabled**: Eliminates hidden background recording overhead and removes micro-stutters.
* **SystemResponsiveness = 0 & NetworkThrottling Off**: Removes network throttle limits for low-latency network packet delivery.
* **GPU Priority = 8 & Scheduling Category High**: Sets high GPU priority in Windows Multimedia Class Scheduler.
* **MenuShowDelay = 0**: Instant UI/window response when navigating explorer folders and menus.
* **Ultimate Performance Power Plan**: Unlocks and activates the hidden Windows Ultimate Performance power scheme.

### 6. 🔓 VBS / Core Isolation Toggle
Disables Hypervisor-Enforced Code Integrity (HVCI) and Virtualization-Based Security (VBS) to eliminate CPU virtualization overhead and maximize raw clock speed access for competitive gaming and benchmarking.

### 7. 🧹 Deep Disk & Cache Cleaner
Deep cleanup of system temporary files (`C:\Windows\Temp`), user temp files (`%TEMP%`), Windows Update download cache, Prefetch cache, and Recycle Bin.

### 8. 🔄 Restore & Rollback Center (Undo Hub)
Full peace-of-mind rollback engine allowing selective, item-by-item or category-wide restoration:
* **Item-by-Item App Reinstallation**: Reinstall or repair specific UWP/Store apps individually (Weather, News, Calculator, Alarms, Phone Link, Media Player, Snipping Tool, Terminal, Store, etc.) via provisioned image manifest or Microsoft Store (`winget`).
* **Granular Background Services Restore**: Choose exactly which background services to re-enable and return to Windows defaults (`Automatic`/`Manual`).
* **Granular Privacy & Telemetry Restore**: Selectively re-enable Bing Search, Copilot AI, Start Menu widgets, or Diagnostic telemetry.
* **Granular Hardware & Latency Restore**: Revert specific kernel parameters (`Win32PrioritySeparation = 2`), GameDVR background capture, UI delays, or Balanced power plan.
* **VBS & Hypervisor Restore**: Re-enables Virtualization-Based Security (VBS) and sets Windows Hypervisor back to `auto`.
* **Full Store Package Re-registration**: One-click repair and re-registration of all factory Windows UWP apps.
* **System Restore Launcher**: Direct shortcut to launch the Windows System Restore Wizard (`rstrui.exe`).

---

## 🚀 Alternative Execution Methods

### Local Execution (Git Clone / Download)
1. Clone the repository:
   ```powershell
   git clone https://github.com/blayk11/ultimatedebloat.git
   ```
2. Navigate to the project directory:
   ```powershell
   cd ultimatedebloat
   ```
3. Run the script:
   ```powershell
   Set-ExecutionPolicy Unrestricted -Scope Process -Force; .\ExtremeDebloat.ps1
   ```

*(Or right-click **`ExtremeDebloat.ps1`** and choose **"Run with PowerShell"**).*

---

## 💻 Compatibility

* **Operating Systems**: Windows 10 & Windows 11 (Home, Pro, Enterprise, LTSC, and Insider Preview builds).
* **PowerShell**: Windows PowerShell 5.1 & PowerShell 7+ (Core).
* **Permissions**: Administrator privileges required (auto-elevation included).

---

## 👨‍💻 Author

Engineered and maintained by **[blayk11](https://github.com/blayk11)**.

Feel free to open an **Issue** or submit a **Pull Request** with suggestions and enhancements!

---

## 📄 License

This project is licensed under the [MIT](LICENSE) License. You are free to use, modify, and distribute it.
