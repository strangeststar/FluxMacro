#pragma once
#include <QObject>
#include <QTimer>
#include <QVector>
#include <QVariantList>

class SystemMonitor : public QObject {
    Q_OBJECT
    Q_PROPERTY(double       procCpu      READ procCpu      NOTIFY procCpuChanged)
    Q_PROPERTY(double       procRamMB    READ procRamMB    NOTIFY procRamMBChanged)
    Q_PROPERTY(double       sysCpu       READ sysCpu       NOTIFY sysCpuChanged)
    Q_PROPERTY(double       sysRamUsedMB READ sysRamUsedMB NOTIFY sysRamUsedMBChanged)
    Q_PROPERTY(double       sysRamTotalMB READ sysRamTotalMB NOTIFY sysRamTotalMBChanged)
    Q_PROPERTY(QVariantList cpuHistory   READ cpuHistory   NOTIFY cpuHistoryChanged)
    Q_PROPERTY(QVariantList ramHistory   READ ramHistory   NOTIFY ramHistoryChanged)
    Q_PROPERTY(QVariantList sysCpuHistory READ sysCpuHistory NOTIFY sysCpuHistoryChanged)

public:
    static constexpr int kHistLen = 60;

    explicit SystemMonitor(QObject* parent = nullptr);
    ~SystemMonitor() override;

    double       procCpu()       const;
    double       procRamMB()     const;
    double       sysCpu()        const;
    double       sysRamUsedMB()  const;
    double       sysRamTotalMB() const;
    QVariantList cpuHistory()    const;
    QVariantList ramHistory()    const;
    QVariantList sysCpuHistory() const;

signals:
    void procCpuChanged(double);
    void procRamMBChanged(double);
    void sysCpuChanged(double);
    void sysRamUsedMBChanged(double);
    void sysRamTotalMBChanged(double);
    void cpuHistoryChanged();
    void ramHistoryChanged();
    void sysCpuHistoryChanged();

private slots:
    void poll();

private:
    QTimer  m_timer;
    double  m_procCpu      = 0.0;
    double  m_procRamMB    = 0.0;
    double  m_sysCpu       = 0.0;
    double  m_sysRamUsed   = 0.0;
    double  m_sysRamTotal  = 0.0;

    QVector<double> m_cpuHist;
    QVector<double> m_ramHist;
    QVector<double> m_sysCpuHist;

#ifdef FLUX_WINDOWS
    quint64 m_prevProcKernel = 0;
    quint64 m_prevProcUser   = 0;
    quint64 m_prevSysKernel  = 0;
    quint64 m_prevSysUser    = 0;
    quint64 m_prevSysIdle    = 0;
    static quint64 ftToU64(const void* ft);
#endif
};
