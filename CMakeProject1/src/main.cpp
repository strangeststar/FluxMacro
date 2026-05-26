#define WIN32_LEAN_AND_MEAN
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QUrl>
#include <QLocalServer>
#include <QLocalSocket>

#include "AppSettings.h"
#include "MacroEngine.h"
#include "AutoClicker.h"
#include "HotkeyManager.h"
#include "InputSimulator.h"
#include "WindowHelper.h"
#include "TrayHelper.h"
#include "SystemMonitor.h"

class KeyNameHelper : public QObject {
    Q_OBJECT
public:
    KeyNameHelper(QObject* p = nullptr) : QObject(p) {}
    Q_INVOKABLE QString nameOf(int vk) const { return InputSim::keyName(vk); }
};

static QFile* g_logFile = nullptr;
static void msgHandler(QtMsgType type, const QMessageLogContext&, const QString& msg) {
    if (g_logFile && g_logFile->isOpen()) {
        const char* pfx[] = {"DBG","WRN","CRT","FAT","INF"};
        QTextStream(g_logFile) << pfx[qMin((int)type,4)] << ": " << msg << "\n";
        g_logFile->flush();
    }
}

static void writeReadme() {
    QString appData = qEnvironmentVariable("APPDATA");
    if (appData.isEmpty()) return;
    QDir dir(appData + "/FluxMacro");
    if (!dir.exists()) dir.mkpath(".");
    QFile f(dir.filePath("README.txt"));
    if (f.exists()) return;   // only write once
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) return;
    QTextStream out(&f);
    out <<
R"(FluxMacro v2.0
==============
Created by: strangeststar
All rights reserved.

FEATURES
--------
* Macro sequencer  — scroll, click, keypress and delay actions that loop while active
* Per-macro hotkeys (Hold or Toggle) plus a shared global key (default Z)
* AutoClicker with adjustable CPS, LMB/RMB/MMB, safe-zone pause
* Master enable switches for Macros and AutoClicker (default OFF)
* System tray — minimize to tray while everything keeps running
* Accent colour themes, animation toggle
* All settings and macros persist across launches

HOTKEYS
-------
  Global macro key   Z  (configurable in Settings)
  AutoClicker key    F  (configurable in AutoClicker tab or Settings)
  Per-macro keys     set per-macro in the Macro tab (Hold or Toggle)
  Escape             cancels any active key-bind capture

SETTINGS LOCATION
-----------------
Registry: HKCU\Software\FluxMacro\FluxMacro

REQUIREMENTS
------------
No installation required. Run FluxMacro.exe directly.
Windows 10 / 11 (64-bit).
)";
}

static const QString kInstanceKey = "FluxMacro_SingleInstance_v2";

int main(int argc, char* argv[]) {
    QFile logFile("fluxmacro_debug.log");
    logFile.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);
    g_logFile = &logFile;
    qInstallMessageHandler(msgHandler);

    QApplication app(argc, argv);
    app.setOrganizationName("FluxMacro");
    app.setApplicationName("FluxMacro");
    app.setApplicationVersion("2.0");
    app.setWindowIcon(QIcon(":/icon.ico"));

    // ── Single-instance guard ─────────────────────────────────────────────────
    // If another instance is already running, tell it to show itself and exit.
    {
        QLocalSocket probe;
        probe.connectToServer(kInstanceKey, QIODevice::WriteOnly);
        if (probe.waitForConnected(300)) {
            probe.write("show");
            probe.waitForBytesWritten(500);
            probe.disconnectFromServer();
            return 0;
        }
    }
    // We are the first (and only) instance — start listening.
    QLocalServer instanceServer;
    QLocalServer::removeServer(kInstanceKey);   // clean up stale socket from a prior crash
    instanceServer.listen(kInstanceKey);

    writeReadme();

    QQuickStyle::setStyle("Basic");

    qmlRegisterType<AppSettings>  ("FluxMacro", 1, 0, "AppSettingsType");
    qmlRegisterType<MacroEngine>  ("FluxMacro", 1, 0, "MacroEngineType");
    qmlRegisterType<AutoClicker>  ("FluxMacro", 1, 0, "AutoClickerType");
    qmlRegisterType<HotkeyManager>("FluxMacro", 1, 0, "HotkeyManagerType");
    qmlRegisterType<KeyNameHelper>("FluxMacro", 1, 0, "KeyNameHelperType");

    AppSettings   settings;
    MacroEngine   macroEngine;
    AutoClicker   autoClicker;
    HotkeyManager macroHotkey;
    HotkeyManager acHotkey;
    HotkeyManager keyCapturer;
    KeyNameHelper keyNames;
    WindowHelper  windowHelper;
    TrayHelper    trayHelper;
    SystemMonitor sysMonitor;

    // When a second instance tries to launch, raise our window instead
    QObject::connect(&instanceServer, &QLocalServer::newConnection, [&]() {
        if (QLocalSocket* c = instanceServer.nextPendingConnection()) {
            c->waitForReadyRead(200);
            c->deleteLater();
        }
        trayHelper.showMainWindow();
    });

    macroHotkey.setHotkey(settings.macroHotkey());
    macroHotkey.setMode(settings.macroHotkeyMode());
    acHotkey.setHotkey(settings.acHotkey());
    acHotkey.setMode(settings.acHotkeyMode());

    QObject::connect(&settings, &AppSettings::macroHotkeyChanged,     [&]{ macroHotkey.setHotkey(settings.macroHotkey()); });
    QObject::connect(&settings, &AppSettings::macroHotkeyModeChanged, [&]{ macroHotkey.setMode(settings.macroHotkeyMode()); });
    QObject::connect(&settings, &AppSettings::acHotkeyChanged,        [&]{ acHotkey.setHotkey(settings.acHotkey()); });
    QObject::connect(&settings, &AppSettings::acHotkeyModeChanged,    [&]{ acHotkey.setMode(settings.acHotkeyMode()); });

    QObject::connect(&macroHotkey, &HotkeyManager::activeChanged, [&](bool v){ macroEngine.setGlobalActive(v); });
    QObject::connect(&acHotkey,    &HotkeyManager::activeChanged,
                     &autoClicker, &AutoClicker::setRunning, Qt::QueuedConnection);

    macroEngine.fromJson(settings.loadMacros());
    macroEngine.setMasterEnabled(settings.macroMasterEnabled());

    autoClicker.setClickType(settings.acClickType());
    autoClicker.setCPS(settings.acCPS());
    autoClicker.setSafeTaskbar(settings.acSafeTaskbar());
    autoClicker.setSafeTitlebar(settings.acSafeTitlebar());
    autoClicker.setMasterEnabled(settings.acMasterEnabled());

    QObject::connect(&settings, &AppSettings::macroMasterEnabledChanged,
                     [&]{ macroEngine.setMasterEnabled(settings.macroMasterEnabled()); });
    QObject::connect(&settings, &AppSettings::acMasterEnabledChanged,
                     &autoClicker, [&]{ autoClicker.setMasterEnabled(settings.acMasterEnabled()); },
                     Qt::QueuedConnection);

    // Belt-and-suspenders: save everything on clean exit
    QObject::connect(&app, &QApplication::aboutToQuit, [&]{
        macroEngine.save();
        settings.setMacroMasterEnabled(macroEngine.masterEnabled());
        settings.setAcMasterEnabled(autoClicker.masterEnabled());
    });

    macroHotkey.start();
    acHotkey.start();
    keyCapturer.start();

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("appSettings",  &settings);
    engine.rootContext()->setContextProperty("macroEngine",  &macroEngine);
    engine.rootContext()->setContextProperty("autoClicker",  &autoClicker);
    engine.rootContext()->setContextProperty("macroHotkey",  &macroHotkey);
    engine.rootContext()->setContextProperty("acHotkey",     &acHotkey);
    engine.rootContext()->setContextProperty("keyCapturer",  &keyCapturer);
    engine.rootContext()->setContextProperty("keyNames",     &keyNames);
    engine.rootContext()->setContextProperty("windowHelper", &windowHelper);
    engine.rootContext()->setContextProperty("trayHelper",   &trayHelper);
    engine.rootContext()->setContextProperty("sysMonitor",   &sysMonitor);

    engine.addImportPath(QStringLiteral("qrc:/"));
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));

    if (engine.rootObjects().isEmpty()) return -1;

    int ret = app.exec();

    macroHotkey.stop();
    acHotkey.stop();
    keyCapturer.stop();
    return ret;
}

#include "main.moc"
