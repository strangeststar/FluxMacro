#include "InputSimulator.h"

#ifdef FLUX_WINDOWS
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

void InputSim::mouseClick(int button) {
    INPUT inp[2] = {};
    inp[0].type = inp[1].type = INPUT_MOUSE;
    switch (button) {
    case 0: inp[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;   inp[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;   break;
    case 1: inp[0].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;  inp[1].mi.dwFlags = MOUSEEVENTF_RIGHTUP;  break;
    case 2: inp[0].mi.dwFlags = MOUSEEVENTF_MIDDLEDOWN; inp[1].mi.dwFlags = MOUSEEVENTF_MIDDLEUP; break;
    default: return;
    }
    SendInput(2, inp, sizeof(INPUT));
}

void InputSim::scroll(int delta) {
    INPUT inp = {};
    inp.type = INPUT_MOUSE;
    inp.mi.dwFlags   = MOUSEEVENTF_WHEEL;
    inp.mi.mouseData = (DWORD)(LONG)delta;
    SendInput(1, &inp, sizeof(INPUT));
}

void InputSim::keyTap(int vk) {
    INPUT inp[2] = {};
    inp[0].type = inp[1].type = INPUT_KEYBOARD;
    inp[0].ki.wVk     = (WORD)vk;
    inp[1].ki.wVk     = (WORD)vk;
    inp[1].ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(2, inp, sizeof(INPUT));
}

QString InputSim::keyName(int vk) {
    if (vk <= 0)            return "None";
    if (vk == VK_LBUTTON)  return "LMB";
    if (vk == VK_RBUTTON)  return "RMB";
    if (vk == VK_MBUTTON)  return "MMB";
    if (vk == VK_XBUTTON1) return "Mouse Back";
    if (vk == VK_XBUTTON2) return "Mouse Fwd";
    UINT sc = MapVirtualKeyA(vk, MAPVK_VK_TO_VSC);
    char buf[128] = {};
    if (GetKeyNameTextA((LONG)(sc << 16), buf, sizeof(buf)) > 0)
        return QString::fromLocal8Bit(buf);
    return QString("VK 0x%1").arg(vk, 2, 16, QChar('0')).toUpper();
}

bool InputSim::isKeyDown(int vk) {
    if (vk <= 0) return false;
    return (GetAsyncKeyState(vk) & 0x8000) != 0;
}

#elif defined(FLUX_LINUX)
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <X11/keysym.h>

static Display* disp() {
    static Display* d = XOpenDisplay(nullptr);
    return d;
}

void InputSim::mouseClick(int button) {
    Display* d = disp(); if (!d) return;
    int b = (button == 0) ? 1 : (button == 1) ? 3 : 2;
    XTestFakeButtonEvent(d, b, True,  0);
    XTestFakeButtonEvent(d, b, False, 0);
    XFlush(d);
}

void InputSim::scroll(int delta) {
    Display* d = disp(); if (!d) return;
    int btn = (delta > 0) ? 4 : 5;
    XTestFakeButtonEvent(d, btn, True,  0);
    XTestFakeButtonEvent(d, btn, False, 0);
    XFlush(d);
}

void InputSim::keyTap(int keycode) {
    Display* d = disp(); if (!d) return;
    XTestFakeKeyEvent(d, keycode, True,  0);
    XTestFakeKeyEvent(d, keycode, False, 0);
    XFlush(d);
}

QString InputSim::keyName(int keycode) {
    Display* d = disp();
    if (!d || keycode <= 0) return "None";
    KeySym sym = XkbKeycodeToKeysym(d, keycode, 0, 0);
    const char* n = XKeysymToString(sym);
    return n ? QString(n) : QString("Key %1").arg(keycode);
}

bool InputSim::isKeyDown(int keycode) {
    Display* d = disp();
    if (!d || keycode <= 0) return false;
    char keys[32] = {};
    XQueryKeymap(d, keys);
    return (keys[keycode / 8] & (1 << (keycode % 8))) != 0;
}

#else
void InputSim::mouseClick(int) {}
void InputSim::scroll(int) {}
void InputSim::keyTap(int) {}
QString InputSim::keyName(int vk) { return vk > 0 ? QString("Key %1").arg(vk) : "None"; }
bool InputSim::isKeyDown(int) { return false; }
#endif
