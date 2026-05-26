#pragma once
#include <QObject>
#include <QSettings>
#include <QJsonArray>
#include <QString>

class AppSettings : public QObject {
    Q_OBJECT

    // General
    Q_PROPERTY(bool   animationsEnabled  READ animationsEnabled  WRITE setAnimationsEnabled  NOTIFY animationsEnabledChanged)
    Q_PROPERTY(QString accentColor       READ accentColor        WRITE setAccentColor        NOTIFY accentColorChanged)

    // AutoClicker
    Q_PROPERTY(int    acClickType        READ acClickType        WRITE setAcClickType        NOTIFY acClickTypeChanged)
    Q_PROPERTY(double acCPS              READ acCPS              WRITE setAcCPS              NOTIFY acCPSChanged)
    Q_PROPERTY(int    acHotkey           READ acHotkey           WRITE setAcHotkey           NOTIFY acHotkeyChanged)
    Q_PROPERTY(int    acHotkeyMode       READ acHotkeyMode       WRITE setAcHotkeyMode       NOTIFY acHotkeyModeChanged)
    Q_PROPERTY(bool   acSafeTaskbar      READ acSafeTaskbar      WRITE setAcSafeTaskbar      NOTIFY acSafeTaskbarChanged)
    Q_PROPERTY(bool   acSafeTitlebar     READ acSafeTitlebar     WRITE setAcSafeTitlebar     NOTIFY acSafeTitlebarChanged)

    // Macro
    Q_PROPERTY(int    macroHotkey        READ macroHotkey        WRITE setMacroHotkey        NOTIFY macroHotkeyChanged)
    Q_PROPERTY(int    macroHotkeyMode    READ macroHotkeyMode    WRITE setMacroHotkeyMode    NOTIFY macroHotkeyModeChanged)
    Q_PROPERTY(bool   macroMasterEnabled READ macroMasterEnabled WRITE setMacroMasterEnabled NOTIFY macroMasterEnabledChanged)

    // Master switches
    Q_PROPERTY(bool   acMasterEnabled    READ acMasterEnabled    WRITE setAcMasterEnabled    NOTIFY acMasterEnabledChanged)

public:
    explicit AppSettings(QObject* parent = nullptr);
    static AppSettings* instance();

    Q_INVOKABLE void       saveMacros(const QJsonArray& macros);
    Q_INVOKABLE void       saveMacrosStr(const QString& json);  // direct save — bypasses QJsonArray, calls sync()
    Q_INVOKABLE QJsonArray loadMacros() const;
    Q_INVOKABLE QString    loadMacrosStr() const;   // returns raw JSON string — safe to use from QML
    Q_INVOKABLE void       resetToDefaults();

    bool    animationsEnabled() const;
    QString accentColor()       const;
    int     acClickType()       const;
    double  acCPS()             const;
    int     acHotkey()          const;
    int     acHotkeyMode()      const;
    bool    acSafeTaskbar()     const;
    bool    acSafeTitlebar()    const;
    int     macroHotkey()          const;
    int     macroHotkeyMode()      const;
    bool    macroMasterEnabled()   const;
    bool    acMasterEnabled()      const;

public slots:
    void setAnimationsEnabled(bool v);
    void setAccentColor(const QString& v);
    void setAcClickType(int v);
    void setAcCPS(double v);
    void setAcHotkey(int v);
    void setAcHotkeyMode(int v);
    void setAcSafeTaskbar(bool v);
    void setAcSafeTitlebar(bool v);
    void setMacroHotkey(int v);
    void setMacroHotkeyMode(int v);
    void setMacroMasterEnabled(bool v);
    void setAcMasterEnabled(bool v);

signals:
    void animationsEnabledChanged();
    void accentColorChanged();
    void acClickTypeChanged();
    void acCPSChanged();
    void acHotkeyChanged();
    void acHotkeyModeChanged();
    void acSafeTaskbarChanged();
    void acSafeTitlebarChanged();
    void macroHotkeyChanged();
    void macroHotkeyModeChanged();
    void macroMasterEnabledChanged();
    void acMasterEnabledChanged();

private:
    QSettings m_s;
    static AppSettings* s_inst;
};
