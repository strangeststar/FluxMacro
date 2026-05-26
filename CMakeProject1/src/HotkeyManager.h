#pragma once
#include <QObject>
#include <QThread>
#include <atomic>

class HotkeyManager : public QObject {
    Q_OBJECT
public:
    explicit HotkeyManager(QObject* parent = nullptr);
    ~HotkeyManager();

    void start();
    void stop();

    void setHotkey(int vk);
    int  hotkey() const;
    void setMode(int m);
    int  mode()   const;

    Q_INVOKABLE void beginCapture();
    Q_INVOKABLE void cancelCapture();
    Q_INVOKABLE bool isCapturing() const;

    bool isActive() const;

signals:
    void activated();
    void deactivated();
    void keyCaptured(int vk, const QString& name);
    void activeChanged(bool active);

private:
    void pollLoop();

    QThread*          m_thread          = nullptr;
    std::atomic<bool> m_run             {false};
    std::atomic<bool> m_capture         {false};
    std::atomic<bool> m_captureWaitClear{false};
    std::atomic<bool> m_active          {false};
    int               m_hotkey          = 0;
    int               m_mode            = 0;
    bool              m_prevDown        = false;
};
