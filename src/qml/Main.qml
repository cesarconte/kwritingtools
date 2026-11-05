/*
    SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    title: i18n("Herramientas de Escritura")
    width: 680
    height: 640
    minimumWidth: 580
    minimumHeight: 520

    flags: Qt.Dialog | Qt.FramelessWindowHint

    color: "transparent"
    visible: Controller ? Controller.hudVisible : false

    onClosing: (close) => {
        if (Controller) {
            Controller.hudVisible = false;
        }
        close.accepted = false;
    }

    DragHandler {
        target: null
        grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.ApprovesTakeOverByAnything
        onActiveChanged: {
            if (active) {
                root.startSystemMove();
            }
        }
    }

    // Outer Glow / Border and Glass Background Container
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: 16
        clip: true
        color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.03)
        border.width: 1.5
        border.color: Controller.isGenerating
            ? "#D63384"
            : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.20)

        // Iridescent subtle glow border on generation
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: 17
            z: -1
            opacity: Controller.isGenerating ? 0.9 : 0.35
            color: "transparent"
            border.width: 1.5
            border.color: Controller.isGenerating ? "#0DCAF0" : "#6F42C1"

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // 1. Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    source: "document-edit-symbolic"
                    implicitWidth: 20
                    implicitHeight: 20
                    color: Controller.isGenerating ? "#D63384" : Kirigami.Theme.highlightColor
                }

                QQC2.Label {
                    text: i18n("Herramientas de Escritura")
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 1
                    color: Kirigami.Theme.textColor
                }

                Item { Layout.fillWidth: true }

                // Model / Apple Intelligence Badge
                Rectangle {
                    radius: 10
                    height: 22
                    width: badgeRow.implicitWidth + 16
                    color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.12)
                    border.width: 1
                    border.color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.3)

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Controller.isGenerating ? "#20c997" : Kirigami.Theme.highlightColor
                        }

                        QQC2.Label {
                            text: "Apple Intelligence (Qwen 2.5)"
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }
                    }
                }

                QQC2.ToolButton {
                    icon.name: "window-close-symbolic"
                    implicitWidth: 28
                    implicitHeight: 28
                    onClicked: {
                        if (Controller) {
                            Controller.hudVisible = false;
                        } else {
                            root.close();
                        }
                    }
                    QQC2.ToolTip.text: i18n("Cerrar (Esc)")
                    QQC2.ToolTip.visible: hovered
                }
            }

            // 2. Source Text Card (Compact & Clean)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(100, Math.max(72, sourceEditor.contentHeight + 36))
                radius: 10
                color: Kirigami.Theme.alternateBackgroundColor
                border.width: 1
                border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        QQC2.Label {
                            text: i18n("Texto original")
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            font.bold: true
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.4)
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.Label {
                            text: Controller.selectedText.length > 0 ? (Controller.selectedText.length + " " + i18n("caracteres")) : ""
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 2
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.5)
                        }

                        QQC2.ToolButton {
                            icon.name: "edit-paste"
                            implicitWidth: 20
                            implicitHeight: 20
                            QQC2.ToolTip.text: i18n("Capturar selección activa de nuevo")
                            QQC2.ToolTip.visible: hovered
                            onClicked: Controller.captureSelection()
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: sourceEditor.contentHeight
                        clip: true

                        QQC2.TextArea {
                            id: sourceEditor
                            width: parent.width
                            text: Controller.selectedText
                            placeholderText: i18n("Selecciona texto en cualquier aplicación o pégalo aquí...")
                            wrapMode: TextEdit.Wrap
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.Theme.textColor
                            background: null
                            selectByMouse: true
                            onTextChanged: {
                                if (text !== Controller.selectedText) {
                                    Controller.selectedText = text;
                                }
                            }
                        }
                    }
                }
            }

            // 3. Action Toolbar (KDE HIG & Apple Intelligence Categorized Grid)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: actionsLayout.implicitHeight + 16
                radius: 10
                color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.02)
                border.width: 1
                border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)

                ColumnLayout {
                    id: actionsLayout
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Row A: Transformaciones y Corrección directa
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "tools-check-spelling"
                            text: i18n("Corregir")
                            highlighted: Controller.currentAction === "proofread"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("proofread")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "view-list-tree"
                            text: i18n("Resumir")
                            highlighted: Controller.currentAction === "summary"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("summary")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "format-list-unordered"
                            text: i18n("Puntos clave")
                            highlighted: Controller.currentAction === "keypoints"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("keypoints")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "view-form-table"
                            text: i18n("Tabla")
                            highlighted: Controller.currentAction === "table"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("table")
                        }
                    }

                    // Row B: Reescribir por Tonos (Apple Intelligence Tone Pills)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        QQC2.Label {
                            text: i18n("Reescribir:")
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.3)
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "document-edit-symbolic"
                            text: i18n("Estándar")
                            highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === ""
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("rewrite", "")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "user"
                            text: i18n("Amigable")
                            highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "friendly"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("rewrite", "friendly")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "mail-signed"
                            text: i18n("Profesional")
                            highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "professional"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("rewrite", "professional")
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "speedometer"
                            text: i18n("Conciso")
                            highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "concise"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: Controller.applyAction("rewrite", "concise")
                        }
                    }
                }
            }

            // 4. Result Area (Scrollable with Streaming AI Output)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Controller.isGenerating
                    ? "#0DCAF0"
                    : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        QQC2.Label {
                            text: i18n("Resultado sugerido")
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            font.bold: true
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.4)
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.BusyIndicator {
                            running: Controller.isGenerating
                            visible: Controller.isGenerating
                            implicitWidth: 16
                            implicitHeight: 16
                        }

                        QQC2.Label {
                            visible: Controller.resultText.length > 0
                            text: Controller.resultText.length + " " + i18n("caracteres")
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 2
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.5)
                        }
                    }

                    Flickable {
                        id: resultFlickable
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: resultLabel.contentHeight
                        clip: true

                        QQC2.TextArea {
                            id: resultLabel
                            width: parent.width
                            text: Controller.resultText
                            placeholderText: Controller.isGenerating
                                ? i18n("Apple Intelligence está procesando tu texto...")
                                : i18n("Elige una de las acciones arriba para mejorar el texto seleccionado.")
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            color: Kirigami.Theme.textColor
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                            background: null
                        }
                    }
                }
            }

            // 5. Footer Bar (Status & Primary Actions)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.maximumWidth: root.width - 320
                    text: Controller.statusMessage
                    elide: Text.ElideRight
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.35)
                }

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    text: i18n("Cancelar")
                    icon.name: "process-stop"
                    visible: Controller.isGenerating
                    onClicked: Controller.cancelGeneration()
                }

                QQC2.Button {
                    text: i18n("Copiar")
                    icon.name: "edit-copy"
                    enabled: Controller.resultText.length > 0
                    onClicked: Controller.copyResult()
                }

                QQC2.Button {
                    text: i18n("Reemplazar selección")
                    icon.name: "document-edit-symbolic"
                    highlighted: true
                    enabled: Controller.resultText.length > 0
                    onClicked: Controller.replaceInApp()
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (Controller) {
                Controller.hudVisible = false;
            } else {
                root.close();
            }
        }
    }
}
