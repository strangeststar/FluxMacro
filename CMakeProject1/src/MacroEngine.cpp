#include "MacroEngine.h"
#include "AppSettings.h"
#include "InputSimulator.h"
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <thread>
#include <chrono>
#include <algorithm>

MacroEngine::MacroEngine(QObject* parent) : QObject(parent) {
    m_run.store(true);
    m_thread = QThread::create([this]{ workerLoop(); });
    m_thread->start();
}

MacroEngine::~MacroEngine() {
    m_run.store(false);
    if (m_thread) { m_thread->wait(1000); delete m_thread; }
}

bool MacroEngine::running()       const { return m_globalActive.load(); }
bool MacroEngine::masterEnabled() const { return m_masterEnabled.load(); }
bool MacroEngine::anyActive()     const { return m_anyActive.load(); }

void MacroEngine::setMasterEnabled(bool v) {
    if (m_masterEnabled.load() == v) return;
    m_masterEnabled.store(v);
    emit masterEnabledChanged(v);
}

void MacroEngine::setGlobalActive(bool v) {
    if (m_globalActive.load() == v) return;
    m_globalActive.store(v);
    emit runningChanged(v);
}

void MacroEngine::setMacros(const std::vector<MacroData>& macros) {
    std::lock_guard<std::mutex> lk(m_mutex);
    m_macros = macros;
}

void MacroEngine::workerLoop() {
    std::map<int, bool>         keyPrev;
    std::map<std::string, bool> localActive;

    while (m_run.load()) {
        if (!m_masterEnabled.load()) {
            keyPrev.clear();
            localActive.clear();
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
            continue;
        }

        std::vector<MacroData> snap;
        { std::lock_guard<std::mutex> lk(m_mutex); snap = m_macros; }

        // Update active states for individually-keyed macros
        for (auto& macro : snap) {
            if (!macro.useGlobalHotkey && macro.triggerKey > 0) {
                bool down = InputSim::isKeyDown(macro.triggerKey);
                if (macro.triggerMode == 1) {
                    // Toggle: flip on leading edge
                    if (down && !keyPrev[macro.triggerKey])
                        localActive[macro.name] = !localActive[macro.name];
                } else {
                    // Hold: directly follow key state
                    localActive[macro.name] = down;
                }
                keyPrev[macro.triggerKey] = down;
            }
        }

        bool globalOn = m_globalActive.load();
        bool didAny   = false;

        for (auto& macro : snap) {
            if (!macro.enabled || macro.actions.empty()) continue;

            bool active = macro.useGlobalHotkey ? globalOn : localActive[macro.name];
            if (!active) continue;

            didAny = true;
            bool aborted = false;
            for (auto& a : macro.actions) {
                if (!m_run.load()) { aborted = true; break; }
                if (macro.useGlobalHotkey && !m_globalActive.load()) { aborted = true; break; }
                if (!macro.useGlobalHotkey && macro.triggerMode == 0 && macro.triggerKey > 0
                    && !InputSim::isKeyDown(macro.triggerKey)) { aborted = true; break; }

                int delay = std::max(1, (int)((float)a.delayMs / macro.speed));
                switch (a.type) {
                case 0: InputSim::scroll(+a.amount); break;
                case 1: InputSim::scroll(-a.amount); break;
                case 2: InputSim::mouseClick(0);     break;
                case 3: InputSim::mouseClick(1);     break;
                case 4: InputSim::mouseClick(2);     break;
                case 5: if (a.keyCode > 0) InputSim::keyTap(a.keyCode); break;
                case 6: delay = a.delayMs; break;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(delay));
            }
            if (aborted) break;
            if (macro.loopDelayMs > 0)
                std::this_thread::sleep_for(std::chrono::milliseconds(macro.loopDelayMs));
        }
        if (m_anyActive.load() != didAny) {
            m_anyActive.store(didAny);
            emit anyActiveChanged(didAny);
        }
        if (!didAny)
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
}

QJsonArray MacroEngine::toJson() const {
    std::lock_guard<std::mutex> lk(m_mutex);
    QJsonArray arr;
    for (auto& m : m_macros) {
        QJsonObject mo;
        mo["name"]            = QString::fromStdString(m.name);
        mo["enabled"]         = m.enabled;
        mo["speed"]           = m.speed;
        mo["loopDelayMs"]     = m.loopDelayMs;
        mo["useGlobalHotkey"] = m.useGlobalHotkey;
        mo["triggerKey"]      = m.triggerKey;
        mo["triggerMode"]     = m.triggerMode;
        mo["isDefault"]       = m.isDefault;
        QJsonArray acts;
        for (auto& a : m.actions) {
            QJsonObject ao;
            ao["type"]    = a.type;
            ao["keyCode"] = a.keyCode;
            ao["amount"]  = a.amount;
            ao["delayMs"] = a.delayMs;
            ao["keyName"] = QString::fromStdString(a.keyName);
            acts.append(ao);
        }
        mo["actions"] = acts;
        arr.append(mo);
    }
    return arr;
}

void MacroEngine::fromJsonStr(const QString& json) {
    fromJson(QJsonDocument::fromJson(json.toUtf8()).array());
}

void MacroEngine::save() {
    if (AppSettings* s = AppSettings::instance())
        s->saveMacros(toJson());
}

void MacroEngine::fromJson(const QJsonArray& arr) {
    std::vector<MacroData> macros;
    for (auto val : arr) {
        QJsonObject mo = val.toObject();
        MacroData m;
        m.name            = mo["name"].toString().toStdString();
        m.enabled         = mo["enabled"].toBool(true);
        m.speed           = (float)mo["speed"].toDouble(1.0);
        m.loopDelayMs     = mo["loopDelayMs"].toInt(1);
        m.useGlobalHotkey = mo["useGlobalHotkey"].toBool(true);
        m.triggerKey      = mo["triggerKey"].toInt(0);
        m.triggerMode     = mo["triggerMode"].toInt(0);
        m.isDefault       = mo["isDefault"].toBool(false);
        for (auto av : mo["actions"].toArray()) {
            QJsonObject ao = av.toObject();
            MacroAction a;
            a.type    = ao["type"].toInt();
            a.keyCode = ao["keyCode"].toInt();
            a.amount  = ao["amount"].toInt(120);
            a.delayMs = ao["delayMs"].toInt(5);
            a.keyName = ao["keyName"].toString().toStdString();
            m.actions.push_back(a);
        }
        macros.push_back(std::move(m));
    }
    { std::lock_guard<std::mutex> lk(m_mutex); m_macros = macros; }
}
