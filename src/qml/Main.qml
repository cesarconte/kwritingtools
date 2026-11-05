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
    width: 620
    height: 580
    minimumWidth: 500
    minimumHeight: 460

    flags: Qt.Dialog | Qt.FramelessWindowHint

    color: "transparent"
    visible: Controller ? Controller.hudVisible : false

    onClosing: (close) => {
        if (Controller) {
            Controller.hudVisible = false;
        }
        close.accepted = false;
    }

    // Background Container with Liquid Glass and Apple Intelligence Glow Border
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: 18
        color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.04)
        border.width: 2
        border.color: Controller.isGenerating ? "#D63384" : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.18)

        // Iridescent subtle glow border
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: 19
            z: -1
            opacity: Controller.isGenerating ? 0.85 : 0.45
            color: "transparent"
            border.width: 1.5
            border.color: "#6F42C1"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.mediumSpacing

            // 1. Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "document-edit-symbolic"
                    implicitWidth: 22
                    implicitHeight: 22
                    color: "#D63384"
                }

                QQC2.Label {
                    text: i18n("Herramientas de Escritura")
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize + 2
                    color: Kirigami.Theme.textColor
                }

                Item { Layout.fillWidth: true }

                // Model / Engine badge
                Rectangle {
                    radius: 10
                    height: 20
                    width: badgeText.implicitWidth + 14
                    color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.15)
                    border.width: 1
                    border.color: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.3)

                    QQC2.Label {
                        id: badgeText
                        anchors.centerIn: parent
                        text: "Apple Intelligence (Qwen 2.5)"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        color: Kirigami.Theme.highlightColor
                    }
                }

                QQC2.ToolButton {
                    icon.name: "window-close-symbolic"
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

            // 2. Source Text Input (Collapsible / Compact)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(100, Math.max(60, sourceEditor.contentHeight + 20))
                radius: 10
                color: Kirigami.Theme.alternateBackgroundColor
                border.width: 1
                border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    contentWidth: width
                    contentHeight: sourceEditor.contentHeight
                    clip: true

                    QQC2.TextArea {
                        id: sourceEditor
                        width: parent.width
                        text: Controller.selectedText
                        placeholderText: i18n("Selecciona o pega el texto que deseas mejorar...")
                        wrapMode: TextEdit.Wrap
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        color: Kirigami.Theme.textColor
                        background: null
                        onTextChanged: {
                            if (text !== Controller.selectedText) {
                                Controller.selectedText = text;
                            }
                        }
                    }
                }
            }

            // 3. Action Pills Toolbar
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    text: i18n("✓ Corregir")
                    highlighted: Controller.currentAction === "proofread"
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("proofread")
                }

                QQC2.Button {
                    text: i18n("↻ Reescribir")
                    highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === ""
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("rewrite", "")
                }

                QQC2.Button {
                    text: i18n("😊 Amigable")
                    highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "friendly"
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("rewrite", "friendly")
                }

                QQC2.Button {
                    text: i18n("💼 Profesional")
                    highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "professional"
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("rewrite", "professional")
                }

                QQC2.Button {
                    text: i18n("⚡ Conciso")
                    highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "concise"
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("rewrite", "concise")
                }

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    text: i18n("📝 Resumir")
                    highlighted: Controller.currentAction === "summary"
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("summary")
                }

                QQC2.Button {
                    text: i18n("• Puntos clave")
                    highlighted: Controller.currentAction === "keypoints"
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("keypoints")
                }

                QQC2.Button {
                    text: i18n("⊞ Tabla")
                    highlighted: Controller.currentAction === "table"
                    enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                    onClicked: Controller.applyAction("table")
                }
            }

            // 4. Result Area (Scrollable with Streaming AI Output)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: Controller.isGenerating ? "#0DCAF0" : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)

                Flickable {
                    id: resultFlickable
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.mediumSpacing
                    contentWidth: width
                    contentHeight: resultLabel.contentHeight
                    clip: true

                    QQC2.TextArea {
                        id: resultLabel
                        width: parent.width
                        text: Controller.resultText
                        placeholderText: Controller.isGenerating
                            ? i18n("Apple Intelligence está procesando tu texto...")
                            : i18n("El resultado generado aparecerá aquí listo para sustituir o copiar.")
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                        background: null
                    }
                }
            }

            // 5. Status & Footer Action Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    text: Controller.statusMessage
                    elide: Text.ElideRight
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.4)
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
