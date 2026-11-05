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

    property bool sourceExpanded: true
    readonly property bool hasResult: Controller && Controller.resultText.length > 0

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

            // 2. Source Text Card (Responsive, Scrollable & Collapsible)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: {
                    if (!root.sourceExpanded) {
                        return 38;
                    }
                    if (root.hasResult) {
                        return Math.min(130, Math.max(78, sourceEditor.contentHeight + 42));
                    }
                    return Math.min(220, Math.max(90, sourceEditor.contentHeight + 42));
                }
                radius: 10
                color: Kirigami.Theme.alternateBackgroundColor
                border.width: 1
                border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)
                clip: true

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Source Card Toolbar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Kirigami.Icon {
                            source: "edit-find-replace"
                            implicitWidth: 14
                            implicitHeight: 14
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.4)
                        }

                        QQC2.Label {
                            text: i18n("Texto original")
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            font.bold: true
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.4)
                        }

                        // Collapsed one-line preview
                        QQC2.Label {
                            visible: !root.sourceExpanded
                            Layout.fillWidth: true
                            text: "— " + Controller.selectedText.replace(/[\r\n]+/g, " ")
                            elide: Text.ElideRight
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.5)
                        }

                        Item {
                            visible: root.sourceExpanded
                            Layout.fillWidth: true
                        }

                        QQC2.Label {
                            text: Controller.selectedText.length > 0 ? (Controller.selectedText.length + " " + i18n("caracteres")) : ""
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 2
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.textColor, Kirigami.Theme.backgroundColor, 0.5)
                        }

                        QQC2.ToolButton {
                            icon.name: root.sourceExpanded ? "arrow-up" : "arrow-down"
                            implicitWidth: 22
                            implicitHeight: 22
                            QQC2.ToolTip.text: root.sourceExpanded ? i18n("Colapsar texto original") : i18n("Expandir texto original")
                            QQC2.ToolTip.visible: hovered
                            onClicked: root.sourceExpanded = !root.sourceExpanded
                        }

                        QQC2.ToolButton {
                            icon.name: "edit-paste"
                            implicitWidth: 22
                            implicitHeight: 22
                            QQC2.ToolTip.text: i18n("Pegar selección activa del sistema")
                            QQC2.ToolTip.visible: hovered
                            onClicked: {
                                Controller.captureSelection();
                                root.sourceExpanded = true;
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: "edit-clear"
                            implicitWidth: 22
                            implicitHeight: 22
                            visible: Controller.selectedText.length > 0
                            QQC2.ToolTip.text: i18n("Limpiar texto")
                            QQC2.ToolTip.visible: hovered
                            onClicked: Controller.clearAll()
                        }
                    }

                    // Native ScrollView for limitless smooth navigation & scrolling
                    QQC2.ScrollView {
                        visible: root.sourceExpanded
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

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
                            onClicked: {
                                Controller.applyAction("proofread");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "view-list-tree"
                            text: i18n("Resumir")
                            highlighted: Controller.currentAction === "summary"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("summary");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "format-list-unordered"
                            text: i18n("Puntos clave")
                            highlighted: Controller.currentAction === "keypoints"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("keypoints");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "view-form-table"
                            text: i18n("Tabla")
                            highlighted: Controller.currentAction === "table"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("table");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
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
                            onClicked: {
                                Controller.applyAction("rewrite", "");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "user"
                            text: i18n("Amigable")
                            highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "friendly"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("rewrite", "friendly");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "mail-signed"
                            text: i18n("Profesional")
                            highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "professional"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("rewrite", "professional");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        QQC2.Button {
                            Layout.fillWidth: true
                            icon.name: "speedometer"
                            text: i18n("Conciso")
                            highlighted: Controller.currentAction === "rewrite" && Controller.currentTone === "concise"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("rewrite", "concise");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }
                    }
                }
            }

            // 4. Result Area (Scrollable, Editable & with Regenerate / Revert Controls)
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

                        // Regenerate alternate variant button (Apple Intelligence)
                        QQC2.ToolButton {
                            icon.name: "view-refresh"
                            implicitWidth: 24
                            implicitHeight: 24
                            visible: Controller.resultText.length > 0 && !Controller.isGenerating
                            QQC2.ToolTip.text: i18n("Regenerar otra versión alternativa")
                            QQC2.ToolTip.visible: hovered
                            onClicked: Controller.regenerate()
                        }

                        // Revert / Discard suggestion button (Apple Intelligence)
                        QQC2.ToolButton {
                            icon.name: "edit-undo"
                            implicitWidth: 24
                            implicitHeight: 24
                            visible: Controller.resultText.length > 0 && !Controller.isGenerating
                            QQC2.ToolTip.text: i18n("Descartar sugerencia y volver al original")
                            QQC2.ToolTip.visible: hovered
                            onClicked: {
                                Controller.clearResult();
                                root.sourceExpanded = true;
                            }
                        }
                    }

                    QQC2.ScrollView {
                        id: resultScrollView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

                        QQC2.TextArea {
                            id: resultLabel
                            width: parent.width
                            text: Controller.resultText
                            placeholderText: Controller.isGenerating
                                ? i18n("Apple Intelligence está procesando tu texto...")
                                : i18n("Elige una de las acciones arriba para mejorar el texto seleccionado.")
                            readOnly: Controller.isGenerating
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            color: Kirigami.Theme.textColor
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                            background: null
                            onTextChanged: {
                                if (text !== Controller.resultText) {
                                    Controller.resultText = text;
                                }
                            }
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
                    Layout.maximumWidth: root.width - 340
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
                    text: i18n("Descartar")
                    icon.name: "edit-undo"
                    visible: Controller.resultText.length > 0 && !Controller.isGenerating
                    onClicked: {
                        Controller.clearResult();
                        root.sourceExpanded = true;
                    }
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
