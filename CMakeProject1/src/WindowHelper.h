#pragma once
#include <QObject>

class QQuickWindow;

class WindowHelper : public QObject {
    Q_OBJECT
public:
    explicit WindowHelper(QObject* parent = nullptr);

    // Call after the window is shown to apply frameless DWM tweaks
    Q_INVOKABLE void applyFrameless(QQuickWindow* window);
};
