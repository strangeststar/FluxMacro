#include "AppSettings.h"
#include <QJsonDocument>
#include <QFile>
#include <QSaveFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

AppSettings* AppSettings::s_inst = nullptr;

AppSettings::AppSettings(QObject* parent)
    : QObject(parent), m_s("FluxMacro", "FluxMacro") { s_inst = this; }

AppSettings* AppSettings::instance() { return s_inst; }

static QString macrosFilePath() {
    QString appData = qEnvironmentVariable("APPDATA");
    if (appData.isEmpty()) appData = QDir::homePath();
    return appData + "/FluxMacro/macros.json";
}

void AppSettings::saveMacrosStr(const QString& json) {
    QString path = macrosFilePath();
    QDir().mkpath(QFileInfo(path).absolutePath());

    // Atomic write via QSaveFile: writes to a temp file, then renames on commit.
    // Prevents a corrupt macros.json if the app crashes mid-write.
    QSaveFile f(path);
    if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        f.write(json.toUtf8());
        if (f.commit()) {
            // Write a backup copy so we have a fallback if the primary gets corrupted
            QSaveFile bak(path + ".bak");
            if (bak.open(QIODevice::WriteOnly | QIODevice::Text)) {
                bak.write(json.toUtf8());
                bak.commit();
            }
            qDebug() << "Macros saved to" << path;
        } else {
            qDebug() << "ERROR: could not commit macros:" << f.errorString();
        }
    } else {
        qDebug() << "ERROR: could not open macros save file" << path << f.errorString();
    }
}

void AppSettings::saveMacros(const QJsonArray& a) {
    saveMacrosStr(QString::fromUtf8(QJsonDocument(a).toJson(QJsonDocument::Compact)));
}

static QString tryReadJson(const QString& path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return {};
    QString data = QString::fromUtf8(f.readAll()).trimmed();
    if (data.isEmpty()) return {};
    // Quick sanity check: must start with '[' (JSON array)
    if (!data.startsWith('[')) return {};
    return data;
}

QString AppSettings::loadMacrosStr() const {
    QString path = macrosFilePath();
    QString data = tryReadJson(path);
    if (!data.isEmpty()) {
        qDebug() << "Macros loaded from" << path;
        return data;
    }
    // Primary file missing / corrupt — try backup
    QString bak = path + ".bak";
    data = tryReadJson(bak);
    if (!data.isEmpty()) {
        qDebug() << "Macros loaded from backup" << bak;
        return data;
    }
    qDebug() << "No macros file found — starting fresh";
    return QStringLiteral("[]");
}

QJsonArray AppSettings::loadMacros() const {
    QString s = loadMacrosStr();
    if (s == QLatin1String("[]") || s.isEmpty()) return {};
    return QJsonDocument::fromJson(s.toUtf8()).array();
}

void AppSettings::resetToDefaults() {
    m_s.clear();
    emit animationsEnabledChanged(); emit accentColorChanged();
    emit acClickTypeChanged();       emit acCPSChanged();
    emit acHotkeyChanged();          emit acHotkeyModeChanged();
    emit acSafeTaskbarChanged();     emit acSafeTitlebarChanged();
    emit macroHotkeyChanged();       emit macroHotkeyModeChanged();
    emit macroMasterEnabledChanged(); emit acMasterEnabledChanged();
}

bool    AppSettings::animationsEnabled() const { return m_s.value("animEn",     true).toBool(); }
QString AppSettings::accentColor()       const { return m_s.value("accent",     "#B00020").toString(); }
int     AppSettings::acClickType()       const { return m_s.value("acType",     0).toInt(); }
double  AppSettings::acCPS()             const { return m_s.value("acCPS",      10.0).toDouble(); }
int     AppSettings::acHotkey()          const { return m_s.value("acHotkey",   0x46).toInt(); }
int     AppSettings::acHotkeyMode()      const { return m_s.value("acMode",     0).toInt(); }
bool    AppSettings::acSafeTaskbar()     const { return m_s.value("acSafeTB",   true).toBool(); }
bool    AppSettings::acSafeTitlebar()    const { return m_s.value("acSafeTTL",  true).toBool(); }
int     AppSettings::macroHotkey()          const { return m_s.value("macHotkey",    0x5A).toInt(); }
int     AppSettings::macroHotkeyMode()      const { return m_s.value("macMode",      1).toInt(); }
bool    AppSettings::macroMasterEnabled()   const { return m_s.value("macMaster",    false).toBool(); }
bool    AppSettings::acMasterEnabled()      const { return m_s.value("acMaster",     false).toBool(); }

void AppSettings::setAnimationsEnabled(bool v)    { if (animationsEnabled()==v) return; m_s.setValue("animEn",    v); emit animationsEnabledChanged(); }
void AppSettings::setAcClickType(int v)           { if (acClickType()==v)       return; m_s.setValue("acType",    v); emit acClickTypeChanged(); }
void AppSettings::setAcCPS(double v)              { if (acCPS()==v)             return; m_s.setValue("acCPS",     v); emit acCPSChanged(); }
void AppSettings::setAcHotkey(int v)              { if (acHotkey()==v)          return; m_s.setValue("acHotkey",  v); emit acHotkeyChanged(); }
void AppSettings::setAcHotkeyMode(int v)          { if (acHotkeyMode()==v)      return; m_s.setValue("acMode",    v); emit acHotkeyModeChanged(); }
void AppSettings::setAcSafeTaskbar(bool v)        { if (acSafeTaskbar()==v)     return; m_s.setValue("acSafeTB",  v); emit acSafeTaskbarChanged(); }
void AppSettings::setAcSafeTitlebar(bool v)       { if (acSafeTitlebar()==v)    return; m_s.setValue("acSafeTTL", v); emit acSafeTitlebarChanged(); }
void AppSettings::setMacroHotkey(int v)           { if (macroHotkey()==v)          return; m_s.setValue("macHotkey",  v); emit macroHotkeyChanged(); }
void AppSettings::setMacroHotkeyMode(int v)       { if (macroHotkeyMode()==v)      return; m_s.setValue("macMode",    v); emit macroHotkeyModeChanged(); }
void AppSettings::setMacroMasterEnabled(bool v)   { if (macroMasterEnabled()==v)   return; m_s.setValue("macMaster",  v); emit macroMasterEnabledChanged(); }
void AppSettings::setAcMasterEnabled(bool v)      { if (acMasterEnabled()==v)      return; m_s.setValue("acMaster",   v); emit acMasterEnabledChanged(); }
void AppSettings::setAccentColor(const QString& v){ if (accentColor()==v)          return; m_s.setValue("accent",     v); emit accentColorChanged(); }
