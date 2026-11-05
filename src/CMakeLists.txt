add_library(kwritingtools_core STATIC
    writingtoolscontroller.cpp
    writingtoolscontroller.h
)

target_include_directories(kwritingtools_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(kwritingtools_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::DBus
    KF6::CoreAddons
    KF6::I18n
    KF6::GlobalAccel
)

qt_add_resources(KWRITINGTOOLS_QRC resources.qrc)

add_executable(kwritingtools
    main.cpp
    ${KWRITINGTOOLS_QRC}
)

target_link_libraries(kwritingtools PRIVATE
    kwritingtools_core
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    KF6::GlobalAccel
    KF6::I18n
    KF6::I18nQml
)

install(TARGETS kwritingtools ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
