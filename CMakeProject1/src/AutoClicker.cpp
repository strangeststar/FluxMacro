#include "AutoClicker.h"
#include "InputSimulator.h"
#include "SafeZoneChecker.h"
#include <algorithm>

AutoClicker::AutoClicker(QObject* parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
    , m_safeZone(new SafeZoneChecker(this))
{
    connect(m_timer, &QTimer::timeout, this, &AutoClicker::onTick);
}

AutoClicker::~AutoClicker() {}

void AutoClicker::setClickType(int t)     { m_clickType    = t; }
void AutoClicker::setCPS(double cps)      { m_cps = std::max(0.1, cps); if (m_running.load()) { setRunning(false); setRunning(true); } }
void AutoClicker::setSafeTaskbar(bool v)  { m_safeTaskbar  = v; }
void AutoClicker::setSafeTitlebar(bool v) { m_safeTitlebar = v; }

bool AutoClicker::running()       const { return m_running.load(); }
bool AutoClicker::masterEnabled() const { return m_masterEnabled; }

void AutoClicker::setMasterEnabled(bool v) {
    if (m_masterEnabled == v) return;
    m_masterEnabled = v;
    if (!v && m_running.load()) setRunning(false);
    emit masterEnabledChanged(v);
}

void AutoClicker::setRunning(bool v) {
    if (v && !m_masterEnabled) return;
    if (m_running.load() == v) return;
    m_running.store(v);
    if (v) {
        int ms = static_cast<int>(1000.0 / m_cps);
        m_timer->start(std::max(1, ms));
    } else {
        m_timer->stop();
    }
    emit runningChanged(v);
}

void AutoClicker::onTick() {
    if (m_safeZone->isInSafeZone(m_safeTaskbar, m_safeTitlebar)) return;
    InputSim::mouseClick(m_clickType);
}
