/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-2.0-or-later

    KWritingTools — Herramientas de Escritura con IA local (Apple Intelligence).
    Diseño Golden Gate / Liquid Glass (CachyOS.UI).
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import CachyOS.UI

CachyWindow {
    id: root

    title: CachyI18n.i18n("Herramientas de Escritura")

    width: 720
    height: 560
    minimumWidth: 560
    minimumHeight: 460

    showTrafficLights: true
    showTitleBarDivider: false         // Golden Gate: cabecera translúcida sin divisor duro
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
    // CABECERA — IZQUIERDA: icono Apple Intelligence (el título va centrado)
    // =========================================================================
    headerLeading: [
        CachyIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "sparkles"
            size: 16
            color: Controller && Controller.isGenerating
                ? "#AF52DE"
                : (root.hasResult ? CachyTheme.accentColor : CachyPalette.textSecondary)

            Behavior on color {
                ColorAnimation { duration: CachyTheme.animFast }
            }
        }
    ]

    // =========================================================================
    // CABECERA — DERECHA: cápsula del modelo y cerrar
    // =========================================================================
    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Insignia interactiva del modelo local en cápsula Liquid Glass
            Rectangle {
                id: modelBadge
                implicitHeight: 26
                Layout.preferredHeight: 26
                implicitWidth: badgeRow.implicitWidth + 18
                radius: 13
                color: modelBadgeMouse.containsMouse
                    ? CachyPalette.cardBackgroundHover
                    : CachyPalette.surfacePill
                border.width: 1
                border.color: modelBadgeMouse.containsMouse
                    ? CachyTheme.accentColor
                    : CachyPalette.specularBorder

                Behavior on color {
                    ColorAnimation { duration: CachyTheme.animFast }
                }

                RowLayout {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Controller && Controller.isGenerating ? "#30D158" : CachyTheme.accentColor

                        Behavior on color {
                            ColorAnimation { duration: CachyTheme.animFast }
                        }
                    }

                    CachyLabel {
                        text: (Controller && Controller.currentModel.length > 0 ? Controller.currentModel : "qwen2.5:7b")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                    }

                    CachyIcon {
                        name: "chevron-down"
                        size: 10
                        color: CachyPalette.textMuted
                    }
                }

                MouseArea {
                    id: modelBadgeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelMenu.open()
                }

                CachyMenu {
                    id: modelMenu
                    y: modelBadge.height + 4

                    Instantiator {
                        model: Controller ? Controller.availableModels : []
                        delegate: CachyMenuItem {
                            id: modelItem
                            required property string modelData
                            text: modelItem.modelData
                            checkable: true
                            checked: Controller && Controller.currentModel === modelItem.modelData
                            onTriggered: {
                                if (Controller) {
                                    Controller.currentModel = modelItem.modelData;
                                }
                            }
                        }
                        onObjectAdded: (index, object) => modelMenu.insertItem(index, object)
                        onObjectRemoved: (index, object) => modelMenu.removeItem(object)
                    }

                    CachyMenuSeparator {
                        visible: Controller && Controller.availableModels.length > 0
                    }

                    CachyMenuItem {
                        text: CachyI18n.i18n("Actualizar modelos de Ollama")
                        iconName: "refresh"
                        onTriggered: {
                            if (Controller) {
                                Controller.refreshModels();
                            }
                        }
                    }
                }
            }

            CachyToolbarButton {
                iconName: "close"
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
    // CONTENIDO PRINCIPAL
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            spacing: 5

            // -----------------------------------------------------------------
            // 1. Campo Superior Cápsula: "Describe tu cambio…" (macOS Golden Gate)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 6

                CachyTextField {
                    id: customPromptInput
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    pillStyle: true
                    leadingIcon: "sparkles"
                    showClearButton: true
                    placeholderText: CachyI18n.i18n("Describe tu cambio… (ej. más persuasivo, traduce al inglés, poema)")
                    onAccepted: {
                        if (text.trim().length > 0 && Controller && Controller.selectedText.length > 0) {
                            Controller.applyAction("custom", text.trim());
                            if (root.hasResult) {
                                root.sourceExpanded = false;
                            }
                        }
                    }
                }

                CachyButton {
                    pillStyle: true
                    primary: true
                    iconName: "chevron-right"
                    enabled: customPromptInput.text.trim().length > 0 && Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                    QQC2.ToolTip.visible: customRunHover.hovered
                    QQC2.ToolTip.text: CachyI18n.i18n("Aplicar instrucción personalizada")
                    QQC2.ToolTip.delay: 450
                    onClicked: {
                        if (customPromptInput.text.trim().length > 0 && Controller) {
                            Controller.applyAction("custom", customPromptInput.text.trim());
                            if (root.hasResult) {
                                root.sourceExpanded = false;
                            }
                        }
                    }

                    HoverHandler {
                        id: customRunHover
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            // -----------------------------------------------------------------
            // 2. Acciones Rápidas: Revisar, Reescribir, Tonos y Transformaciones
            // -----------------------------------------------------------------
            CachyCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.minimumHeight: 66

                contentItem: ColumnLayout {
                    spacing: 4

                    // Fila A: Botones destacados (Revisar y Reescribir) + Selector de Tonos
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        CachyToolbarGroup {
                            CachyToolbarButton {
                                iconName: "check"
                                text: CachyI18n.i18n("Revisar")
                                checked: Controller && Controller.currentAction === "proofread"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("proofread");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }

                            CachyToolbarButton {
                                iconName: "sparkles"
                                text: CachyI18n.i18n("Reescribir")
                                checked: Controller && Controller.currentAction === "rewrite" && Controller.currentTone === ""
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("rewrite", "");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Selector rápido de tonos
                        CachyLabel {
                            text: CachyI18n.i18n("Tono:")
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: CachyPalette.textMuted
                        }

                        CachyToolbarGroup {
                            CachyToolbarButton {
                                text: CachyI18n.i18n("Amistoso")
                                checked: Controller && Controller.currentAction === "rewrite" && Controller.currentTone === "friendly"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("rewrite", "friendly");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }

                            CachyToolbarButton {
                                text: CachyI18n.i18n("Profesional")
                                checked: Controller && Controller.currentAction === "rewrite" && Controller.currentTone === "professional"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("rewrite", "professional");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }

                            CachyToolbarButton {
                                text: CachyI18n.i18n("Conciso")
                                checked: Controller && Controller.currentAction === "rewrite" && Controller.currentTone === "concise"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("rewrite", "concise");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }
                        }
                    }

                    // Fila B: Transformaciones estructuradas
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        CachyLabel {
                            text: CachyI18n.i18n("Transformar:")
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: CachyPalette.textMuted
                        }

                        CachyToolbarGroup {
                            Layout.fillWidth: true
                            spacing: 4

                            CachyToolbarButton {
                                iconName: "format-text"
                                text: CachyI18n.i18n("Resumen")
                                checked: Controller && Controller.currentAction === "summary"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("summary");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }

                            CachyToolbarButton {
                                iconName: "checklist"
                                text: CachyI18n.i18n("Puntos clave")
                                checked: Controller && Controller.currentAction === "keypoints"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("keypoints");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }

                            CachyToolbarButton {
                                iconName: "list"
                                text: CachyI18n.i18n("Lista")
                                checked: Controller && Controller.currentAction === "list"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("list");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }

                            CachyToolbarButton {
                                iconName: "table"
                                text: CachyI18n.i18n("Tabla")
                                checked: Controller && Controller.currentAction === "table"
                                enabled: Controller && !Controller.isGenerating && Controller.selectedText.length > 0
                                onClicked: {
                                    Controller.applyAction("table");
                                    if (root.hasResult) {
                                        root.sourceExpanded = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. Texto Original (Plegable)
            // -----------------------------------------------------------------
            CachyCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.minimumHeight: root.sourceExpanded ? 54 : 44
                Layout.preferredHeight: {
                    if (!root.sourceExpanded) {
                        return 44;
                    }
                    if (root.hasResult) {
                        return Math.min(84, Math.max(54, sourceEditor.contentHeight + 28));
                    }
                    return Math.min(110, Math.max(58, sourceEditor.contentHeight + 28));
                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                }

                contentItem: ColumnLayout {
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        CachyIcon {
                            name: "search"
                            size: 13
                            color: CachyPalette.textMuted
                        }

                        CachyLabel {
                            text: CachyI18n.i18n("Texto original")
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: CachyPalette.textMuted
                        }

                        CachyLabel {
                            visible: !root.sourceExpanded
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "— " + (Controller ? Controller.selectedText.replace(/[\r\n]+/g, " ") : "")
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: CachyPalette.textMuted
                        }

                        Item {
                            visible: root.sourceExpanded
                            Layout.fillWidth: true
                        }

                        CachyLabel {
                            visible: root.sourceExpanded
                            text: Controller && Controller.selectedText.length > 0
                                ? (Controller.selectedText.length + " " + CachyI18n.i18n("caracteres"))
                                : ""
                            font.pixelSize: 10
                            color: CachyPalette.textMuted
                            elide: Text.ElideRight
                        }

                        CachyToolbarButton {
                            iconName: root.sourceExpanded ? "chevron-up" : "chevron-down"
                            tooltipText: root.sourceExpanded
                                ? CachyI18n.i18n("Plegar el texto original")
                                : CachyI18n.i18n("Desplegar el texto original")
                            onClicked: root.sourceExpanded = !root.sourceExpanded
                        }

                        CachyToolbarButton {
                            iconName: "copy"
                            tooltipText: CachyI18n.i18n("Pegar la selección activa del sistema")
                            onClicked: {
                                if (Controller) {
                                    Controller.captureSelection();
                                    root.sourceExpanded = true;
                                }
                            }
                        }

                        CachyToolbarButton {
                            iconName: "close"
                            tooltipText: CachyI18n.i18n("Limpiar el texto")
                            visible: Controller && Controller.selectedText.length > 0
                            onClicked: Controller.clearAll()
                        }
                    }

                    CachyTextArea {
                        id: sourceEditor
                        visible: root.sourceExpanded
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        Layout.minimumHeight: 0
                        text: Controller ? Controller.selectedText : ""
                        placeholderText: CachyI18n.i18n("Selecciona texto en cualquier aplicación o pégalo aquí…")
                        wrapMode: TextEdit.Wrap
                        font.pixelSize: 12
                        background: null
                        selectByMouse: true

                        onTextChanged: {
                            if (Controller && text !== Controller.selectedText) {
                                Controller.selectedText = text;
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 4. Resultado Sugerido con Efecto Luminoso de Generación
            // -----------------------------------------------------------------
            CachyCard {
                id: resultCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.minimumHeight: 50

                // Efecto luminoso iridiscente de Apple Intelligence durante la generación
                Rectangle {
                    id: glowRect
                    anchors.fill: parent
                    radius: CachyTheme.radiusMedium
                    color: "transparent"
                    border.width: 2
                    border.color: "#AF52DE"
                    visible: Controller ? Controller.isGenerating : false
                    opacity: 0.75

                    SequentialAnimation {
                        running: glowRect.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: glowRect; property: "opacity"; from: 0.35; to: 0.85; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: glowRect; property: "opacity"; from: 0.85; to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
                    }
                }

                contentItem: ColumnLayout {
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 6

                        CachyIcon {
                            name: "sparkles"
                            size: 13
                            color: (Controller && Controller.isGenerating) ? "#AF52DE" : CachyTheme.accentColor
                        }

                        CachyLabel {
                            text: CachyI18n.i18n("Resultado sugerido")
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: CachyPalette.text
                        }

                        Item { Layout.fillWidth: true }

                        CachyBusyIndicator {
                            running: Controller ? Controller.isGenerating : false
                            visible: Controller ? Controller.isGenerating : false
                            size: 16
                        }

                        CachyLabel {
                            visible: Controller && Controller.resultText.length > 0
                            text: (Controller ? Controller.resultText.length : 0) + " " + CachyI18n.i18n("caracteres")
                            font.pixelSize: 10
                            color: CachyPalette.textMuted
                            elide: Text.ElideRight
                        }

                        CachyToolbarButton {
                            iconName: "refresh"
                            tooltipText: CachyI18n.i18n("Generar otra versión alternativa")
                            visible: Controller && Controller.resultText.length > 0 && !Controller.isGenerating
                            onClicked: Controller.regenerate()
                        }

                        CachyToolbarButton {
                            iconName: "close"
                            tooltipText: CachyI18n.i18n("Descartar la sugerencia y volver al original")
                            visible: Controller && Controller.resultText.length > 0 && !Controller.isGenerating
                            onClicked: {
                                Controller.clearResult();
                                root.sourceExpanded = true;
                            }
                        }
                    }

                    CachyTextArea {
                        id: resultLabel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        Layout.minimumHeight: 0
                        text: Controller ? Controller.resultText : ""
                        placeholderText: (Controller && Controller.isGenerating)
                            ? CachyI18n.i18n("La IA local está procesando tu texto…")
                            : CachyI18n.i18n("Elige una acción o escribe una instrucción para transformar el texto.")
                        readOnly: Controller ? Controller.isGenerating : false
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        font.pixelSize: 13
                        background: null

                        onTextChanged: {
                            if (Controller && text !== Controller.resultText) {
                                Controller.resultText = text;
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 5. Pie de Ventana: Estado y Botones Cápsula macOS Golden Gate
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 8

                CachyLabel {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: Controller ? Controller.statusMessage : ""
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    color: CachyPalette.textMuted
                }

                CachyButton {
                    pillStyle: true
                    text: CachyI18n.i18n("Cancelar")
                    iconName: "close"
                    visible: Controller ? Controller.isGenerating : false
                    onClicked: Controller.cancelGeneration()
                }

                CachyButton {
                    pillStyle: true
                    flat: true
                    text: CachyI18n.i18n("Descartar")
                    visible: Controller && Controller.resultText.length > 0 && !Controller.isGenerating
                    onClicked: {
                        Controller.clearResult();
                        root.sourceExpanded = true;
                    }
                }

                CachyButton {
                    pillStyle: true
                    iconName: "copy"
                    text: CachyI18n.i18n("Copiar")
                    enabled: Controller && Controller.resultText.length > 0
                    onClicked: Controller.copyResult()
                }

                CachyButton {
                    pillStyle: true
                    iconName: "refresh"
                    text: CachyI18n.i18n("Reintentar")
                    visible: Controller && Controller.resultText.length > 0 && !Controller.isGenerating
                    onClicked: Controller.regenerate()
                }

                CachyButton {
                    pillStyle: true
                    primary: true
                    iconName: "check"
                    text: CachyI18n.i18n("Reemplazar")
                    enabled: Controller && Controller.resultText.length > 0
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
