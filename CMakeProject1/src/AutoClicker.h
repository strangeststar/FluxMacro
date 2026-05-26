#pragma once
#include <QObject>
#include <QTimer>
#include <atomic>

class SafeZoneChecker;

class AutoClicker : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running       READ running       NOTIFY runningChanged)
    Q_PROPERTY(bool masterEnabled READ masterEnabled NOTIFY masterEnabledChanged)

public:
    explicit AutoClicker(QObject* parent = nullptr);
    ~AutoClicker();

    void setClickType(int t);
    void setCPS(double cps);
    void setSafeTaskbar(bool v);
    void setSafeTitlebar(bool v);

    bool running()       const;
    bool masterEnabled() const;

public slots:
    void setRunning(bool v);
    void setMasterEnabled(bool v);

signals:
    void runningChanged(bool running);
    void masterEnabledChanged(bool v);

private slots:
    void onTick();

private:
    QTimer*           m_timer;
    SafeZoneChecker*  m_safeZone;
    std::atomic<bool> m_running {false};

    int    m_clickType     = 0;
    double m_cps           = 10.0;
    bool   m_safeTaskbar   = true;
    bool   m_safeTitlebar  = true;
    bool   m_masterEnabled = false;
};
