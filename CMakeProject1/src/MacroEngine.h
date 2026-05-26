#pragma once
#include <QObject>
#include <QThread>
#include <QJsonArray>
#include <atomic>
#include <mutex>
#include <vector>
#include <string>
#include <map>

struct MacroAction {
    int  type    = 0; // 0=ScrollUp 1=ScrollDown 2=LClick 3=RClick 4=MClick 5=KeyPress 6=Delay
    int  keyCode = 0;
    int  amount  = 120;
    int  delayMs = 5;
    std::string keyName;
};

struct MacroData {
    std::string name;
    bool        enabled         = true;
    float       speed           = 1.0f;
    int         loopDelayMs     = 1;
    bool        useGlobalHotkey = true;
    int         triggerKey      = 0;
    int         triggerMode     = 0; // 0=Hold, 1=Toggle
    bool        isDefault       = false;
    std::vector<MacroAction> actions;
};

class MacroEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running       READ running       NOTIFY runningChanged)
    Q_PROPERTY(bool masterEnabled READ masterEnabled NOTIFY masterEnabledChanged)
    Q_PROPERTY(bool anyActive     READ anyActive     NOTIFY anyActiveChanged)

public:
    explicit MacroEngine(QObject* parent = nullptr);
    ~MacroEngine();

    bool running()       const;
    bool masterEnabled() const;
    bool anyActive()     const;
    void setMacros(const std::vector<MacroData>& macros);

    Q_INVOKABLE QJsonArray toJson()    const;
    Q_INVOKABLE void fromJson(const QJsonArray& arr);
    Q_INVOKABLE void fromJsonStr(const QString& json);
    Q_INVOKABLE void save();

public slots:
    void setRunning(bool v) { setGlobalActive(v); }
    void setGlobalActive(bool v);
    void setMasterEnabled(bool v);

signals:
    void runningChanged(bool running);
    void masterEnabledChanged(bool v);
    void anyActiveChanged(bool v);

private:
    void workerLoop();

    QThread*            m_thread       = nullptr;
    std::atomic<bool>   m_run          {false};
    std::atomic<bool>   m_globalActive {false};
    std::atomic<bool>   m_masterEnabled{false};
    std::atomic<bool>   m_anyActive    {false};
    mutable std::mutex  m_mutex;
    std::vector<MacroData> m_macros;
};
