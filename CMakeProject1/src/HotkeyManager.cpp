#include "HotkeyManager.h"
#include "InputSimulator.h"
#include <chrono>
#include <thread>

#ifdef FLUX_WINDOWS
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

static bool isVKDown(int vk) {
    if (vk <= 0) return false;
    return (GetAsyncKeyState(vk) & 0x8000) != 0;
}

static bool pollAnyKey(int& outVK) {
    int mouseVKs[] = { VK_LBUTTON, VK_RBUTTON, VK_MBUTTON, VK_XBUTTON1, VK_XBUTTON2 };
    for (int vk : mouseVKs) {
        if (GetAsyncKeyState(vk) & 0x8001) { outVK = vk; return true; }
    }
    for (int vk = 0x08; vk < 0xFE; ++vk) {
        if (vk == VK_ESCAPE) continue;
        if (GetAsyncKeyState(vk) & 0x8001) { outVK = vk; return true; }
    }
    return false;
}

#elif defined(FLUX_LINUX)
#include <X11/Xlib.h>

static Display* disp() {
    static Display* d = XOpenDisplay(nullptr);
    return d;
}

static bool isVKDown(int keycode) {
    Display* d = disp();
    if (!d || keycode <= 0) return false;
    char keys[32] = {};
    XQueryKeymap(d, keys);
    return (keys[keycode / 8] & (1 << (keycode % 8))) != 0;
}

static bool pollAnyKey(int& outVK) {
    Display* d = disp();
    if (!d) return false;
    char keys[32] = {};
    XQueryKeymap(d, keys);
    for (int i = 8; i < 256; ++i) {
        if (keys[i / 8] & (1 << (i % 8))) { outVK = i; return true; }
    }
    return false;
}

#else
static bool isVKDown(int) { return false; }
static bool pollAnyKey(int&) { return false; }
#endif

HotkeyManager::HotkeyManager(QObject* parent) : QObject(parent) {}
HotkeyManager::~HotkeyManager() { stop(); }

void HotkeyManager::start() {
    if (m_run.load()) return;
    m_run.store(true);
    m_thread = QThread::create([this]{ pollLoop(); });
    m_thread->start();
}

void HotkeyManager::stop() {
    m_run.store(false);
    if (m_thread) { m_thread->wait(500); delete m_thread; m_thread = nullptr; }
}

void HotkeyManager::setHotkey(int vk) { m_hotkey = vk; m_prevDown = false; }
int  HotkeyManager::hotkey()    const  { return m_hotkey; }
void HotkeyManager::setMode(int m)     { m_mode = m; }
int  HotkeyManager::mode()      const  { return m_mode; }

void HotkeyManager::beginCapture()  { m_captureWaitClear.store(true); m_capture.store(true); }
void HotkeyManager::cancelCapture() { m_capture.store(false); m_captureWaitClear.store(false); }
bool HotkeyManager::isCapturing()   const { return m_capture.load(); }
bool HotkeyManager::isActive()      const { return m_active.load(); }

void HotkeyManager::pollLoop() {
    std::this_thread::sleep_for(std::chrono::milliseconds(250));

    while (m_run.load()) {
        if (m_capture.load()) {
            if (m_captureWaitClear.load()) {
                // Phase 1: initial wait so the triggering click isn't still "down"
                std::this_thread::sleep_for(std::chrono::milliseconds(150));
                // Phase 2: wait until every key/button is physically released
                while (m_run.load() && m_capture.load()) {
                    bool anyDown = false;
#ifdef FLUX_WINDOWS
                    int mouseVKs[] = { VK_LBUTTON, VK_RBUTTON, VK_MBUTTON, VK_XBUTTON1, VK_XBUTTON2 };
                    for (int vk : mouseVKs)
                        if (GetAsyncKeyState(vk) & 0x8000) { anyDown = true; break; }
                    if (!anyDown) {
                        for (int vk = 0x08; vk < 0xFE; ++vk) {
                            if (vk == VK_ESCAPE) continue;
                            if (GetAsyncKeyState(vk) & 0x8000) { anyDown = true; break; }
                        }
                    }
#elif defined(FLUX_LINUX)
                    Display* d = disp();
                    if (d) {
                        char keys[32] = {};
                        XQueryKeymap(d, keys);
                        for (int i = 0; i < 256; ++i)
                            if (keys[i/8] & (1 << (i%8))) { anyDown = true; break; }
                    }
#endif
                    if (!anyDown) break;
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                }
                // Phase 3: drain accumulated "pressed-since-last-call" bits
#ifdef FLUX_WINDOWS
                for (int vk = 1; vk < 0x100; ++vk) GetAsyncKeyState(vk);
#endif
                // Phase 4: brief extra gap after release
                std::this_thread::sleep_for(std::chrono::milliseconds(60));
                m_captureWaitClear.store(false);
                continue;
            }
            int vk = 0;
            if (pollAnyKey(vk)) {
                m_capture.store(false);
                // Do NOT update m_hotkey here — let the QML/settings layer do it
                // so keyCapturer doesn't accidentally become an active hotkey
                QString name = InputSim::keyName(vk);
                emit keyCaptured(vk, name);
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            continue;
        }

        if (m_hotkey <= 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            continue;
        }

        bool down = isVKDown(m_hotkey);

        if (m_mode == 1) {
            if (down != m_active.load()) {
                m_active.store(down);
                emit activeChanged(down);
                if (down) emit activated();
                else      emit deactivated();
            }
        } else {
            if (down && !m_prevDown) {
                bool newState = !m_active.load();
                m_active.store(newState);
                emit activeChanged(newState);
                if (newState) emit activated();
                else          emit deactivated();
            }
        }

        m_prevDown = down;
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
}
