#include "WindowHelper.h"
#include <QQuickWindow>

WindowHelper::WindowHelper(QObject* parent) : QObject(parent) {}

#ifdef FLUX_WINDOWS
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <dwmapi.h>

// DWM_WINDOW_CORNER_PREFERENCE — Windows 11 only, safe to call on older OS
#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
#ifndef DWMWCP_ROUND
#define DWMWCP_ROUND 2
#endif

void WindowHelper::applyFrameless(QQuickWindow* win) {
    if (!win) return;
    HWND hwnd = reinterpret_cast<HWND>(win->winId());

    // Rounded corners (Windows 11+, silently ignored on Windows 10)
    DWORD corners = DWMWCP_ROUND;
    DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &corners, sizeof(corners));

    // Extend the DWM frame into the client area by 1px on each side.
    // This gives the window a drop-shadow even with FramelessWindowHint.
    MARGINS m = {1, 1, 1, 1};
    DwmExtendFrameIntoClientArea(hwnd, &m);
}

#else
void WindowHelper::applyFrameless(QQuickWindow*) {}
#endif
