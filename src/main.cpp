/*
    SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "writingtoolscontroller.h"

#include <KGlobalAccel>
#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include <QAction>
#include <QApplication>
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QIcon>
#include <QKeySequence>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("kwritingtools");
    app.setApplicationName(QStringLiteral("kwritingtools"));
    app.setApplicationDisplayName(QStringLiteral("Herramientas de Escritura"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));
    app.setQuitOnLastWindowClosed(false);
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("document-edit-symbolic"), QIcon::fromTheme(QStringLiteral("accessories-text-editor"))));

    // Golden Gate parity: the application inherits the Plasma desktop style so
    // menus, tooltips and scroll bars match the rest of the CachyOS.UI
    // ecosystem instead of the raw Basic style.
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Herramientas de escritura con IA local para KDE Plasma 6 Wayland"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption daemonOpt(QStringList{QStringLiteral("d"), QStringLiteral("daemon")},
                                 QStringLiteral("Iniciar en segundo plano como servicio/demonio"));
    parser.addOption(daemonOpt);

    QCommandLineOption toggleOpt(QStringList{QStringLiteral("t"), QStringLiteral("toggle")},
                                 QStringLiteral("Alternar visualización de la ventana de herramientas"));
    parser.addOption(toggleOpt);

    QCommandLineOption proofreadOpt(QStringList{QStringLiteral("p"), QStringLiteral("proofread")},
                                   QStringLiteral("Capturar selección y corregir ortografía y gramática inmediatamente"));
    parser.addOption(proofreadOpt);

    QCommandLineOption rewriteOpt(QStringList{QStringLiteral("r"), QStringLiteral("rewrite")},
                                  QStringLiteral("Capturar selección y reescribir con el tono opcional"),
                                  QStringLiteral("tono"));
    parser.addOption(rewriteOpt);

    QCommandLineOption screenshotOpt(QStringLiteral("screenshot"),
                                     QStringLiteral("Capture window screenshot and exit"),
                                     QStringLiteral("path"));
    parser.addOption(screenshotOpt);

    parser.process(app);

    const QString serviceName = QStringLiteral("org.cesar.kwritingtools");
    const QString objectPath = QStringLiteral("/WritingTools");
    // The object is exported with ExportAllSlots, so the D-Bus interface is
    // derived from the class name of the controller.
    const QString interfaceName = QStringLiteral("org.cesar.kwritingtools.WritingToolsController");

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.isConnected() && !bus.registerService(serviceName)) {
        // Otra instancia ya se está ejecutando; reenviar petición por D-Bus y salir
        QDBusInterface iface(serviceName, objectPath, interfaceName, bus);
        if (iface.isValid()) {
            if (parser.isSet(proofreadOpt)) {
                iface.call(QStringLiteral("ProcessSelection"), QStringLiteral("proofread"), QString());
            } else if (parser.isSet(rewriteOpt)) {
                iface.call(QStringLiteral("ProcessSelection"), QStringLiteral("rewrite"), parser.value(rewriteOpt));
            } else {
                iface.call(QStringLiteral("Toggle"));
            }
            return 0;
        }
    }

    WritingToolsController controller;

    if (bus.isConnected()) {
        bus.registerObject(objectPath, &controller, QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllProperties);
    }

    // Atajo de teclado global Meta+Shift+W vía KF6 GlobalAccel
    auto *shortcutAction = new QAction(&app);
    shortcutAction->setObjectName(QStringLiteral("toggle_writing_tools"));
    shortcutAction->setText(QStringLiteral("Herramientas de Escritura (IA local)"));
    KGlobalAccel::setGlobalShortcut(shortcutAction, QKeySequence(Qt::META | Qt::SHIFT | Qt::Key_W));
    QObject::connect(shortcutAction, &QAction::triggered, &controller, [&controller]() {
        if (controller.hudVisible()) {
            controller.Hide();
        } else {
            controller.captureSelection();
            controller.Show();
        }
    });

    QQmlApplicationEngine engine;
    KLocalization::setupLocalizedContext(&engine);
    // The CachyOS.UI design system (Liquid Glass) is installed system wide or
    // in the user prefix.
    engine.addImportPath(QStringLiteral("/home/cesar/.local/lib/qt6/qml"));
    engine.rootContext()->setContextProperty(QStringLiteral("Controller"), &controller);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
        QObject::connect(&controller, &WritingToolsController::hudVisibleChanged, win, [win, &controller]() {
            if (controller.hudVisible()) {
                win->show();
                win->raise();
                win->requestActivate();
            } else {
                win->hide();
            }
        });

        if (parser.isSet(screenshotOpt)) {
            const QString outPath = parser.value(screenshotOpt);
            // The window visibility is bound to the controller state, so it is
            // shown through it instead of directly.
            controller.setHudVisible(true);
            win->show();
            QTimer::singleShot(900, win, [win, outPath, &app]() {
                const QImage img = win->grabWindow();
                img.save(outPath);
                app.quit();
            });
        }
    }

    // Procesar opciones iniciales de CLI
    if (parser.isSet(proofreadOpt)) {
        controller.ProcessSelection(QStringLiteral("proofread"), QString());
    } else if (parser.isSet(rewriteOpt)) {
        controller.ProcessSelection(QStringLiteral("rewrite"), parser.value(rewriteOpt));
    } else if (parser.isSet(toggleOpt)) {
        controller.captureSelection();
        controller.Show();
    } else if (!parser.isSet(daemonOpt)) {
        // Modo interactivo directo: abrir HUD capturando selección existente
        controller.captureSelection();
        controller.Show();
    }

    return app.exec();
}
