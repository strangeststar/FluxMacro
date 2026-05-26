
# FluxMacro

A lightweight macro and autoclicker utility for Windows, built with Qt 6 and C++.  
Created by **strangeststar**.

---

## Features

### Macro Engine
- Create unlimited macros, each with a custom sequence of actions
- Action types: Scroll Up/Down, Left/Right/Middle Click, Key Press, Delay
- Per-macro speed multiplier and loop delay
- **Global hotkey** — one key triggers all global-mode macros (default: Z)
- **Individual hotkeys** — assign a unique key per macro with Hold or Toggle mode
- Master enable switch — pause all macros at once without losing individual settings
- Macros that are individually disabled stay disabled regardless of the master switch
- Protected default macro (Scroll Spam) cannot be deleted

### AutoClicker
- Adjustable CPS (clicks per second) from 1 to 100
- Click types: Left, Right, Middle mouse button
- Hold or Toggle trigger mode via configurable hotkey
- Master enable switch — disable the autoclicker entirely when not needed
- Safe Zones: automatically pause over the taskbar or window title bars

### Hotkey System
- Global hotkeys work even when the app is not in focus
- Debounced keybind picker — never accidentally captures the click used to open it
- All hotkeys and modes persist across restarts

### Appearance
- Dark UI with customisable accent colour (9 presets including baby pink)
- Animations toggle for lower-end systems
- Frameless window with drag-to-move, snap-to-edge, and resize handles

### System Tray
- Send to tray button keeps all macros and the autoclicker running in the background
- Double-click or use the tray context menu to restore the window
- Quit from the tray without reopening the window

---

## Persistence

All settings are saved automatically and restored on next launch:

| What | Where saved |
|------|-------------|
| Macros (actions, speed, hotkeys, mode) | Windows Registry via QSettings |
| Accent colour, animations toggle | Registry |
| Hotkey assignments and modes | Registry |
| Master switches (macro / autoclicker) | Registry |
| AutoClicker CPS, click type, safe zones | Registry |

Settings are written immediately on change and also flushed when the app closes.

---

## Building from Source

### Requirements
- Windows 10/11 (64-bit)
- Visual Studio 2022 with C++ workload
- Qt 6.4 or later (msvc2022_64) — tested on Qt 6.8.3
- CMake 3.21 or later

### Build steps

```bat
:: Open a VS 2022 x64 Developer Command Prompt, then:
cd path\to\CMakeProject1
cmake -B out\build\x64-release -DCMAKE_BUILD_TYPE=Release
cmake --build out\build\x64-release --config Release
```

Visual Studio users can open the folder directly — it auto-detects CMakeLists.txt.

---

## Standalone Deployment

Run the included script after a Release build:

```bat
deploy.bat
```

This calls `windeployqt` and copies everything needed into a `dist\` folder.  
Zip and distribute that folder — recipients need no Qt installation.

> **Note:** Adjust the `WINDEPLOYQT` path in `deploy.bat` if your Qt is installed  
> somewhere other than `C:\Qt\6.8.3\msvc2022_64`.

---

## Credits

**Created by strangeststar**

Built with:
- [Qt 6](https://www.qt.io/) — UI framework (LGPL v3)
- [CMake](https://cmake.org/) — Build system
- Windows API (`GetAsyncKeyState`, `SendInput`, DWM) for global input handling

---

## License

This project and its source code are the property of **strangeststar**.  
All rights reserved.

NOTE- this README might be outdated. Run build_installer.bat to build a new installer if you update the code, then you release and share that installer to distribute.