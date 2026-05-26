#pragma once
#include <QObject>

class SafeZoneChecker : public QObject {
    Q_OBJECT
public:
    explicit SafeZoneChecker(QObject* parent = nullptr);
    bool isInSafeZone(bool checkTaskbar, bool checkTitlebar) const;
};
