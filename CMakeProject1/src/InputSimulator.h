#pragma once
#include <QString>

namespace InputSim {
    void mouseClick(int button);  // 0=left 1=right 2=middle
    void scroll(int delta);
    void keyTap(int vk);
    QString keyName(int vk);
    bool isKeyDown(int vk);
}
