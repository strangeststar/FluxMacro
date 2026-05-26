#include "SystemMonitor.h"
#include <QDebug>

#ifdef FLUX_WINDOWS
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>
#include <sysinfoapi.h>
#endif

SystemMonitor::SystemMonitor(QObject* parent) : QObject(parent) {
    m_cpuHist.fill(0.0, kHistLen);
    m_ramHist.fill(0.0, kHistLen);
    m_sysCpuHist.fill(0.0, kHistLen);

#ifdef FLUX_WINDOWS
    SYSTEM_INFO si;
    GetSystemInfo(&si);

    FILETIME idle, kern, user;
    GetSystemTimes(&idle, &kern, &user);
    m_prevSysIdle   = ftToU64(&idle);
    m_prevSysKernel = ftToU64(&kern);
    m_prevSysUser   = ftToU64(&user);

    FILETIME cr, ex, pk, pu;
    GetProcessTimes(GetCurrentProcess(), &cr, &ex, &pk, &pu);
    m_prevProcKernel = ftToU64(&pk);
    m_prevProcUser   = ftToU64(&pu);

    // Seed total RAM (doesn't change)
    MEMORYSTATUSEX ms; ms.dwLength = sizeof(ms);
    if (GlobalMemoryStatusEx(&ms))
        m_sysRamTotal = (double)ms.ullTotalPhys / (1024.0 * 1024.0);
#endif

    connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::poll);
    m_timer.start(500);
}

SystemMonitor::~SystemMonitor() { m_timer.stop(); }

double       SystemMonitor::procCpu()       const { return m_procCpu; }
double       SystemMonitor::procRamMB()     const { return m_procRamMB; }
double       SystemMonitor::sysCpu()        const { return m_sysCpu; }
double       SystemMonitor::sysRamUsedMB()  const { return m_sysRamUsed; }
double       SystemMonitor::sysRamTotalMB() const { return m_sysRamTotal; }

QVariantList SystemMonitor::cpuHistory() const {
    QVariantList out; for (double v : m_cpuHist) out.append(v); return out;
}
QVariantList SystemMonitor::ramHistory() const {
    QVariantList out; for (double v : m_ramHist) out.append(v); return out;
}
QVariantList SystemMonitor::sysCpuHistory() const {
    QVariantList out; for (double v : m_sysCpuHist) out.append(v); return out;
}

#ifdef FLUX_WINDOWS
quint64 SystemMonitor::ftToU64(const void* vft) {
    const FILETIME* ft = reinterpret_cast<const FILETIME*>(vft);
    return ((quint64)ft->dwHighDateTime << 32) | ft->dwLowDateTime;
}
#endif

void SystemMonitor::poll() {
#ifdef FLUX_WINDOWS
    // --- System CPU ---
    FILETIME idle, kern, user;
    GetSystemTimes(&idle, &kern, &user);
    quint64 curIdle = ftToU64(&idle);
    quint64 curKern = ftToU64(&kern);
    quint64 curUser = ftToU64(&user);
    quint64 dKern = curKern - m_prevSysKernel;
    quint64 dUser = curUser - m_prevSysUser;
    quint64 dIdle = curIdle - m_prevSysIdle;
    m_prevSysKernel = curKern; m_prevSysUser = curUser; m_prevSysIdle = curIdle;

    quint64 totalSys = dKern + dUser;
    double sysCpuPct = totalSys > 0 ? (double)(totalSys - dIdle) / totalSys * 100.0 : 0.0;
    sysCpuPct = qBound(0.0, sysCpuPct, 100.0);

    // --- Process CPU ---
    FILETIME cr, ex, pk, pu;
    GetProcessTimes(GetCurrentProcess(), &cr, &ex, &pk, &pu);
    quint64 curPK = ftToU64(&pk), curPU = ftToU64(&pu);
    quint64 dProcTotal = (curPK - m_prevProcKernel) + (curPU - m_prevProcUser);
    m_prevProcKernel = curPK; m_prevProcUser = curPU;
    double procCpuPct = totalSys > 0 ? (double)dProcTotal / totalSys * 100.0 : 0.0;
    procCpuPct = qBound(0.0, procCpuPct, 100.0);

    // --- Process RAM ---
    PROCESS_MEMORY_COUNTERS_EX pmc; pmc.cb = sizeof(pmc);
    double procRam = 0.0;
    if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc)))
        procRam = (double)pmc.WorkingSetSize / (1024.0 * 1024.0);

    // --- System RAM ---
    MEMORYSTATUSEX ms; ms.dwLength = sizeof(ms);
    double sysUsed = 0.0;
    if (GlobalMemoryStatusEx(&ms))
        sysUsed = (double)(ms.ullTotalPhys - ms.ullAvailPhys) / (1024.0 * 1024.0);

    // Emit only on change (avoids QML rebinds every 500ms for unchanged values)
    if (m_sysCpu != sysCpuPct)     { m_sysCpu    = sysCpuPct;  emit sysCpuChanged(m_sysCpu); }
    if (m_procCpu != procCpuPct)   { m_procCpu   = procCpuPct; emit procCpuChanged(m_procCpu); }
    if (m_procRamMB != procRam)    { m_procRamMB = procRam;     emit procRamMBChanged(m_procRamMB); }
    if (m_sysRamUsed != sysUsed)   { m_sysRamUsed = sysUsed;   emit sysRamUsedMBChanged(m_sysRamUsed); }

    // Histories always shift regardless (drives graph repaints at 2 Hz)
    m_cpuHist.removeFirst();    m_cpuHist.append(procCpuPct);
    m_ramHist.removeFirst();    m_ramHist.append(procRam);
    m_sysCpuHist.removeFirst(); m_sysCpuHist.append(sysCpuPct);
    emit cpuHistoryChanged();
    emit ramHistoryChanged();
    emit sysCpuHistoryChanged();
#endif
}
