#pragma once
#include <QObject>

class QSystemTrayIcon;

class TrayHelper : public QObject {
    Q_OBJECT
public:
    explicit TrayHelper(QObject* parent = nullptr);

    Q_INVOKABLE void sendToTray(QObject* window);
    void showMainWindow();   // called by single-instance guard to raise the window

signals:
    void restoreRequested();

private:
    QSystemTrayIcon* m_tray = nullptr;
};
