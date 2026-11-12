/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-2.0-or-later

    KWritingTools — Herramientas de escritura con IA local.

    Diseño Golden Gate / Liquid Glass (CachyOS.UI):
      * ventana `CachyWindow` con marco translúcido, cabecera de 44 px con el
        divisor duro de 1 px y radio de 20 px;
      * la identidad de la aplicación y la insignia del modelo viven en la
        cabecera, las acciones primarias en el pie;
      * el texto original, la rejilla de acciones y el resultado se presentan
        sobre `CachyCard`;
      * toda la paleta, los radios y los espaciados salen de `CachyTheme`.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import CachyOS.UI

CachyWindow {
    id: root

    title: CachyI18n.i18n("Herramientas de Escritura")

    // Canonical proportion of the ecosystem (1.33): the panel keeps a stable
    // shape and the result area takes the freed space.
    width: 720
    height: 540
    minimumWidth: 560
    minimumHeight: 460

    showTrafficLights: true
    showTitleBarDivider: true          // divisor duro de 1 px
    showWindowFrame: true              // Liquid Glass: blur KWin + rim especular
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    contentPadded: true                // margen perimetral de 18 px

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

    // =========================================================================
    // CABECERA — IZQUIERDA: marca de la aplicación
    // =========================================================================
    headerLeading: [
        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            source: "document-edit-symbolic"
            width: 18
            height: 18
            color: Controller.isGenerating ? CachyTheme.accentColor : CachyTheme.textMuted
        }
    ]

    // =========================================================================
    // CABECERA — DERECHA: insignia del modelo y cerrar
    // =========================================================================
    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Insignia del modelo local
            Rectangle {
                height: 24
                implicitWidth: badgeRow.implicitWidth + 16
                radius: 12
                color: CachyTheme.withAlpha(CachyTheme.accentColor, 0.14)
                border.width: 1
                border.color: CachyTheme.withAlpha(CachyTheme.accentColor, 0.32)

                RowLayout {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Controller.isGenerating ? "#30D158" : CachyTheme.accentColor

                        Behavior on color {
                            ColorAnimation { duration: CachyTheme.animFast }
                        }
                    }

                    Text {
                        text: CachyI18n.i18n("IA local (Qwen 2.5)")
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: CachyTheme.accentColor
                    }
                }
            }

            CachyToolbarButton {
                iconName: "window-close-symbolic"
                tooltipText: CachyI18n.i18n("Cerrar (Esc)")
                onClicked: {
                    if (Controller) {
                        Controller.hudVisible = false;
                    } else {
                        root.close();
                    }
                }
            }
        }
    ]

    // =========================================================================
    // CONTENIDO
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            spacing: CachyTheme.spacingMedium

            // -----------------------------------------------------------------
            // Texto original (plegable y desplazable)
            // -----------------------------------------------------------------
            CachyCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: {
                    if (!root.sourceExpanded) {
                        return 52;
                    }
                    if (root.hasResult) {
                        return Math.min(140, Math.max(86, sourceEditor.contentHeight + 46));
                    }
                    return Math.min(230, Math.max(96, sourceEditor.contentHeight + 46));
                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                contentItem: ColumnLayout {
                    spacing: 4

                    // --- Barra de la tarjeta ---
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        Kirigami.Icon {
                            source: "edit-find-replace"
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            color: CachyTheme.textMuted
                        }

                        Text {
                            text: CachyI18n.i18n("Texto original")
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: CachyTheme.textMuted
                            elide: Text.ElideRight
                        }

                        // Vista previa de una línea cuando está plegado
                        Text {
                            visible: !root.sourceExpanded
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "— " + Controller.selectedText.replace(/[\r\n]+/g, " ")
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: CachyTheme.textMuted
                        }

                        Item {
                            visible: root.sourceExpanded
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: root.sourceExpanded
                            text: Controller.selectedText.length > 0
                                ? (Controller.selectedText.length + " " + CachyI18n.i18n("caracteres"))
                                : ""
                            font.pixelSize: 10
                            color: CachyTheme.textMuted
                            elide: Text.ElideRight
                        }

                        CachyToolbarButton {
                            iconName: root.sourceExpanded ? "arrow-up-symbolic" : "arrow-down-symbolic"
                            tooltipText: root.sourceExpanded
                                ? CachyI18n.i18n("Plegar el texto original")
                                : CachyI18n.i18n("Desplegar el texto original")
                            onClicked: root.sourceExpanded = !root.sourceExpanded
                        }

                        CachyToolbarButton {
                            iconName: "edit-paste"
                            tooltipText: CachyI18n.i18n("Pegar la selección activa del sistema")
                            onClicked: {
                                Controller.captureSelection();
                                root.sourceExpanded = true;
                            }
                        }

                        CachyToolbarButton {
                            iconName: "edit-clear"
                            tooltipText: CachyI18n.i18n("Limpiar el texto")
                            visible: Controller.selectedText.length > 0
                            onClicked: Controller.clearAll()
                        }
                    }

                    // --- Editor ---
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
                            placeholderText: CachyI18n.i18n("Selecciona texto en cualquier aplicación o pégalo aquí…")
                            wrapMode: TextEdit.Wrap
                            font.pixelSize: 12
                            color: CachyTheme.textPrimary
                            selectionColor: CachyTheme.accentColor
                            selectedTextColor: "#FFFFFF"
                            placeholderTextColor: CachyTheme.textMuted
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

            // -----------------------------------------------------------------
            // Rejilla de acciones
            // -----------------------------------------------------------------
            CachyCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 0

                contentItem: ColumnLayout {
                    spacing: 6

                    // --- Fila A: correcciones directas ---
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "tools-check-spelling"
                            text: CachyI18n.i18n("Corregir")
                            checked: Controller.currentAction === "proofread"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("proofread");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "view-list-tree"
                            text: CachyI18n.i18n("Resumir")
                            checked: Controller.currentAction === "summary"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("summary");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "format-list-unordered"
                            text: CachyI18n.i18n("Puntos clave")
                            checked: Controller.currentAction === "keypoints"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("keypoints");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "view-form-table"
                            text: CachyI18n.i18n("Tabla")
                            checked: Controller.currentAction === "table"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("table");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }
                    }

                    // --- Fila B: reescritura por tonos ---
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        Text {
                            text: CachyI18n.i18n("Reescribir:")
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: CachyTheme.textMuted
                            elide: Text.ElideRight
                        }

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "document-edit-symbolic"
                            text: CachyI18n.i18n("Estándar")
                            checked: Controller.currentAction === "rewrite" && Controller.currentTone === ""
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("rewrite", "");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "user-symbolic"
                            text: CachyI18n.i18n("Amigable")
                            checked: Controller.currentAction === "rewrite" && Controller.currentTone === "friendly"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("rewrite", "friendly");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "mail-signed-symbolic"
                            text: CachyI18n.i18n("Profesional")
                            checked: Controller.currentAction === "rewrite" && Controller.currentTone === "professional"
                            enabled: !Controller.isGenerating && Controller.selectedText.length > 0
                            onClicked: {
                                Controller.applyAction("rewrite", "professional");
                                if (root.hasResult) {
                                    root.sourceExpanded = false;
                                }
                            }
                        }

                        CachyToolbarButton {
                            Layout.fillWidth: true
                            iconName: "speedometer-symbolic"
                            text: CachyI18n.i18n("Conciso")
                            checked: Controller.currentAction === "rewrite" && Controller.currentTone === "concise"
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

            // -----------------------------------------------------------------
            // Resultado sugerido
            // -----------------------------------------------------------------
            CachyCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0

                contentItem: ColumnLayout {
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        Text {
                            text: CachyI18n.i18n("Resultado sugerido")
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: CachyTheme.textMuted
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.BusyIndicator {
                            running: Controller.isGenerating
                            visible: Controller.isGenerating
                            implicitWidth: 16
                            implicitHeight: 16
                        }

                        Text {
                            visible: Controller.resultText.length > 0
                            text: Controller.resultText.length + " " + CachyI18n.i18n("caracteres")
                            font.pixelSize: 10
                            color: CachyTheme.textMuted
                            elide: Text.ElideRight
                        }

                        CachyToolbarButton {
                            iconName: "view-refresh-symbolic"
                            tooltipText: CachyI18n.i18n("Generar otra versión alternativa")
                            visible: Controller.resultText.length > 0 && !Controller.isGenerating
                            onClicked: Controller.regenerate()
                        }

                        CachyToolbarButton {
                            iconName: "edit-undo"
                            tooltipText: CachyI18n.i18n("Descartar la sugerencia y volver al original")
                            visible: Controller.resultText.length > 0 && !Controller.isGenerating
                            onClicked: {
                                Controller.clearResult();
                                root.sourceExpanded = true;
                            }
                        }
                    }

                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

                        QQC2.TextArea {
                            id: resultLabel
                            width: parent.width
                            text: Controller.resultText
                            placeholderText: Controller.isGenerating
                                ? CachyI18n.i18n("La IA local está procesando tu texto…")
                                : CachyI18n.i18n("Elige una de las acciones de arriba para mejorar el texto seleccionado.")
                            readOnly: Controller.isGenerating
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            color: CachyTheme.textPrimary
                            selectionColor: CachyTheme.accentColor
                            selectedTextColor: "#FFFFFF"
                            placeholderTextColor: CachyTheme.textMuted
                            font.pixelSize: 13
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

            // -----------------------------------------------------------------
            // Pie: estado y acciones primarias
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: Controller.statusMessage
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    color: CachyTheme.textMuted
                }

                CachyToolbarButton {
                    text: CachyI18n.i18n("Cancelar")
                    iconName: "process-stop-symbolic"
                    visible: Controller.isGenerating
                    onClicked: Controller.cancelGeneration()
                }

                CachyToolbarButton {
                    text: CachyI18n.i18n("Descartar")
                    iconName: "edit-undo"
                    visible: Controller.resultText.length > 0 && !Controller.isGenerating
                    onClicked: {
                        Controller.clearResult();
                        root.sourceExpanded = true;
                    }
                }

                CachyToolbarButton {
                    text: CachyI18n.i18n("Copiar")
                    iconName: "edit-copy"
                    enabled: Controller.resultText.length > 0
                    onClicked: Controller.copyResult()
                }

                CachyToolbarButton {
                    text: CachyI18n.i18n("Reemplazar la selección")
                    iconName: "document-edit-symbolic"
                    primary: true
                    enabled: Controller.resultText.length > 0
                    onClicked: Controller.replaceInApp()
                }
            }
        }
    ]

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
