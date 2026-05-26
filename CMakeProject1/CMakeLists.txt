cmake_minimum_required(VERSION 3.21)
project(FluxMacro VERSION 2.0.0 LANGUAGES CXX RC)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Widgets Network)

set(SOURCES
    src/main.cpp
    src/AppSettings.cpp
    src/MacroEngine.cpp
    src/AutoClicker.cpp
    src/HotkeyManager.cpp
    src/SafeZoneChecker.cpp
    src/InputSimulator.cpp
    src/WindowHelper.cpp
    src/TrayHelper.cpp
    src/SystemMonitor.cpp
)

if(WIN32)
    list(APPEND SOURCES app.rc)
endif()

qt_add_executable(FluxMacro ${SOURCES} resources.qrc)

qt_add_qml_module(FluxMacro
    URI FluxMacro
    VERSION 1.0
    NO_RESOURCE_TARGET_PATH
    QML_FILES
        qml/main.qml
        qml/MacroPage.qml
        qml/AutoClickerPage.qml
        qml/SettingsPage.qml
        qml/components/NavButton.qml
        qml/components/GlassCard.qml
        qml/components/AnimButton.qml
        qml/components/HotkeyPicker.qml
        qml/components/ToggleSwitch.qml
        qml/components/ModernSlider.qml
        qml/components/SectionLabel.qml
        qml/components/StatusPill.qml
        qml/components/TitleBar.qml
        qml/MonitorPage.qml
    RESOURCES
        qml/components/qmldir
)

target_include_directories(FluxMacro PRIVATE src)

target_link_libraries(FluxMacro PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::Network
)

if(WIN32)
    target_link_libraries(FluxMacro PRIVATE dwmapi user32 psapi)
    target_compile_definitions(FluxMacro PRIVATE FLUX_WINDOWS)
    set_target_properties(FluxMacro PROPERTIES WIN32_EXECUTABLE TRUE)
endif()

if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(XTST REQUIRED xtst)
    pkg_check_modules(X11  REQUIRED x11)
    target_link_libraries(FluxMacro PRIVATE ${XTST_LIBRARIES} ${X11_LIBRARIES})
    target_include_directories(FluxMacro PRIVATE ${XTST_INCLUDE_DIRS} ${X11_INCLUDE_DIRS})
    target_compile_definitions(FluxMacro PRIVATE FLUX_LINUX)
endif()
