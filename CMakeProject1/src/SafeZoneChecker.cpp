#include "SafeZoneChecker.h"

SafeZoneChecker::SafeZoneChecker(QObject* parent) : QObject(parent) {}

#ifdef FLUX_WINDOWS
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

bool SafeZoneChecker::isInSafeZone(bool checkTaskbar, bool checkTitlebar) const {
    POINT pt;
    if (!GetCursorPos(&pt)) return false;

    HWND hw = WindowFromPoint(pt);
    if (!hw) return false;

    if (checkTaskbar) {
        char cls[256] = {};
        GetClassNameA(hw, cls, sizeof(cls));
        if (strcmp(cls, "Shell_TrayWnd") == 0 ||
            strcmp(cls, "Shell_SecondaryTrayWnd") == 0 ||
            strcmp(cls, "NotifyIconOverflowWindow") == 0)
            return true;
    }

    if (checkTitlebar) {
        LONG style = GetWindowLongA(hw, GWL_STYLE);
        if (style & WS_CAPTION) {
            TITLEBARINFO tbi = { sizeof(tbi) };
            GetTitleBarInfo(hw, &tbi);
            RECT tbr = tbi.rcTitleBar;
            if (pt.x >= tbr.left && pt.x <= tbr.right &&
                pt.y >= tbr.top  && pt.y <= tbr.bottom)
                return true;
        }
    }

    return false;
}

#elif defined(FLUX_LINUX)
#include <X11/Xlib.h>
#include <X11/Xatom.h>

static Display* disp() {
    static Display* d = XOpenDisplay(nullptr);
    return d;
}

bool SafeZoneChecker::isInSafeZone(bool checkTaskbar, bool checkTitlebar) const {
    Display* d = disp();
    if (!d) return false;

    Window root, child;
    int rx, ry, wx, wy;
    unsigned int mask;
    XQueryPointer(d, DefaultRootWindow(d), &root, &child, &rx, &ry, &wx, &wy, &mask);
    if (child == None) return false;

    Atom wm_type   = XInternAtom(d, "_NET_WM_WINDOW_TYPE",      False);
    Atom dock_type = XInternAtom(d, "_NET_WM_WINDOW_TYPE_DOCK", False);

    if (checkTaskbar) {
        Atom actual; int fmt; unsigned long n, rem;
        unsigned char* data = nullptr;
        if (XGetWindowProperty(d, child, wm_type, 0, 1, False, XA_ATOM,
                               &actual, &fmt, &n, &rem, &data) == Success && data) {
            bool isDock = (*(Atom*)data == dock_type);
            XFree(data);
            if (isDock) return true;
        }
    }

    if (checkTitlebar) {
        XWindowAttributes wa;
        XGetWindowAttributes(d, child, &wa);
        if (wy < 0) return true;
    }

    return false;
}

#else
bool SafeZoneChecker::isInSafeZone(bool, bool) const { return false; }
#endif
