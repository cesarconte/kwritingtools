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
#include <QQuickWindow>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kwritingtools"));
    app.setApplicationDisplayName(QStringLiteral("Herramientas de Escritura"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));
    app.setQuitOnLastWindowClosed(false);
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("document-edit-symbolic"), QIcon::fromTheme(QStringLiteral("accessories-text-editor"))));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Herramientas de Escritura (Apple Intelligence) para KDE Plasma 6 Wayland"));
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

    parser.process(app);

    const QString serviceName = QStringLiteral("org.cesar.kwritingtools");
    const QString objectPath = QStringLiteral("/WritingTools");
    const QString interfaceName = QStringLiteral("org.cesar.kwritingtools");

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
        bus.registerObject(objectPath, &controller, QDBusConnection::ExportAllSlots);
    }

    // Atajo de teclado global Meta+Shift+W vía KF6 GlobalAccel
    auto *shortcutAction = new QAction(&app);
    shortcutAction->setObjectName(QStringLiteral("toggle_writing_tools"));
    shortcutAction->setText(QStringLiteral("Herramientas de Escritura (Apple Intelligence)"));
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
