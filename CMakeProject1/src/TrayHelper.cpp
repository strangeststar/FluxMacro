#include "TrayHelper.h"
#include <QSystemTrayIcon>
#include <QIcon>
#include <QQuickWindow>

TrayHelper::TrayHelper(QObject* parent) : QObject(parent) {
    m_tray = new QSystemTrayIcon(QIcon(":/icon.ico"), this);
    m_tray->setToolTip("FluxMacro — click to restore");
    m_tray->show();

    connect(m_tray, &QSystemTrayIcon::activated, this,
            [this](QSystemTrayIcon::ActivationReason reason) {
                if (reason == QSystemTrayIcon::DoubleClick ||
                    reason == QSystemTrayIcon::Trigger)
                    emit restoreRequested();
            });
}

void TrayHelper::sendToTray(QObject* window) {
    if (auto* w = qobject_cast<QQuickWindow*>(window))
        w->hide();
}

void TrayHelper::showMainWindow() {
    emit restoreRequested();
}
