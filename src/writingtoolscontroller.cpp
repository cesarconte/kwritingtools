/*
    SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "writingtoolscontroller.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QUrl>

WritingToolsController::WritingToolsController(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

WritingToolsController::~WritingToolsController()
{
    cancelGeneration();
}

void WritingToolsController::setSelectedText(const QString &text)
{
    if (m_selectedText != text) {
        m_selectedText = text;
        Q_EMIT selectedTextChanged();
    }
}

void WritingToolsController::setHudVisible(bool visible)
{
    if (m_hudVisible != visible) {
        m_hudVisible = visible;
        Q_EMIT hudVisibleChanged();

        if (visible && m_selectedText.trimmed().isEmpty()) {
            captureSelection();
        }
    }
}

void WritingToolsController::Toggle()
{
    setHudVisible(!m_hudVisible);
}

void WritingToolsController::Show()
{
    setHudVisible(true);
}

void WritingToolsController::Hide()
{
    setHudVisible(false);
}

void WritingToolsController::ProcessSelection(const QString &action, const QString &tone)
{
    captureSelection();
    setHudVisible(true);
    applyAction(action, tone);
}

void WritingToolsController::setStatus(const QString &msg)
{
    if (m_statusMessage != msg) {
        m_statusMessage = msg;
        Q_EMIT statusMessageChanged();
    }
}

QString WritingToolsController::readWaylandSelection() const
{
    // Try primary selection with wl-paste
    QProcess proc;
    proc.start(QStringLiteral("wl-paste"), {QStringLiteral("-p"), QStringLiteral("-n")});
    if (proc.waitForFinished(400)) {
        const QString text = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        if (!text.isEmpty()) {
            return text;
        }
    }

    // Try standard clipboard with wl-paste
    proc.start(QStringLiteral("wl-paste"), {QStringLiteral("-n")});
    if (proc.waitForFinished(400)) {
        const QString text = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        if (!text.isEmpty()) {
            return text;
        }
    }

    // Fallback to Qt clipboard
    if (auto *cb = QGuiApplication::clipboard()) {
        QString text = cb->text(QClipboard::Selection).trimmed();
        if (text.isEmpty()) {
            text = cb->text(QClipboard::Clipboard).trimmed();
        }
        return text;
    }

    return QString();
}

void WritingToolsController::captureSelection()
{
    const QString sel = readWaylandSelection();
    if (!sel.isEmpty()) {
        setSelectedText(sel);
        setStatus(QStringLiteral("Texto capturado (%1 caracteres)").arg(sel.length()));
    } else {
        setStatus(QStringLiteral("Selecciona un texto en cualquier app y vuelve a abrir"));
    }
}

QString WritingToolsController::buildPrompt(const QString &action, const QString &tone, const QString &sourceText)
{
    const QString clean = sourceText.trimmed();
    if (clean.isEmpty()) {
        return QString();
    }

    QString instruction;

    if (action == QStringLiteral("proofread")) {
        instruction = QStringLiteral(
            "Actúa como la herramienta 'Corregir' (Proofread) de Apple Intelligence. "
            "Corrige cualquier error ortográfico, gramatical y de puntuación del siguiente texto en español de España, "
            "manteniendo escrupulosamente su significado, estilo y formato original. "
            "Devuelve únicamente el texto corregido listo para sustitución directa, sin comentarios adicionales ni explicaciones.");
    } else if (action == QStringLiteral("rewrite")) {
        if (tone == QStringLiteral("friendly")) {
            instruction = QStringLiteral(
                "Actúa como Apple Intelligence en tono Amigable (Friendly). "
                "Reescribe el texto con un estilo cálido, cercano, empático y natural en español de España. "
                "Devuelve únicamente la versión reescrita, sin introducciones ni despedidas.");
        } else if (tone == QStringLiteral("professional")) {
            instruction = QStringLiteral(
                "Actúa como Apple Intelligence en tono Profesional (Professional). "
                "Reescribe el texto con un estilo ejecutivo, pulcro, formal y persuasivo en español de España. "
                "Devuelve únicamente la versión reescrita, sin introducciones ni despedidas.");
        } else if (tone == QStringLiteral("concise")) {
            instruction = QStringLiteral(
                "Actúa como Apple Intelligence en tono Conciso (Concise). "
                "Reescribe el texto de la manera más directa, clara y sintética posible en español de España, "
                "eliminando cualquier palabra redundante. Devuelve únicamente la versión concisa.");
        } else {
            instruction = QStringLiteral(
                "Actúa como Apple Intelligence (Herramienta Reescribir). "
                "Mejora la redacción, fluidez y claridad del texto en español de España, conservando su mensaje. "
                "Devuelve únicamente el texto mejorado.");
        }
    } else if (action == QStringLiteral("summary")) {
        instruction = QStringLiteral(
            "Actúa como Apple Intelligence (Herramienta Resumir). "
            "Genera un resumen ejecutivo de alta calidad, coherente y fluido en español de España. "
            "Devuelve únicamente el resumen.");
    } else if (action == QStringLiteral("keypoints")) {
        instruction = QStringLiteral(
            "Actúa como Apple Intelligence (Puntos Clave). "
            "Extrae las ideas principales y conclusiones clave en una lista de viñetas Markdown concisas en español de España. "
            "Devuelve únicamente la lista con viñetas.");
    } else if (action == QStringLiteral("table")) {
        instruction = QStringLiteral(
            "Actúa como Apple Intelligence (Crear Tabla). "
            "Estructura la información relevante del texto en una tabla Markdown con encabezados descriptivos y alineación limpia. "
            "Devuelve únicamente la tabla Markdown.");
    } else if (action.startsWith(QStringLiteral("translate:"))) {
        const QString targetLang = action.mid(10) == QStringLiteral("en") ? QStringLiteral("inglés") : QStringLiteral("español");
        instruction = QStringLiteral(
            "Traduce el siguiente texto al %1 de forma totalmente natural, detectando automáticamente el idioma original. "
            "Devuelve únicamente la traducción limpia.").arg(targetLang);
    } else {
        instruction = QStringLiteral("Mejora el siguiente texto en español de España:");
    }

    return QStringLiteral("%1\n\nTexto:\n\"\"\"\n%2\n\"\"\"").arg(instruction, clean);
}

QByteArray WritingToolsController::buildOllamaPayload(const QString &prompt, const QString &model)
{
    QJsonObject root;
    root[QStringLiteral("model")] = model;
    root[QStringLiteral("prompt")] = prompt;
    root[QStringLiteral("stream")] = true;

    QJsonObject options;
    options[QStringLiteral("temperature")] = 0.3;
    options[QStringLiteral("top_p")] = 0.9;
    root[QStringLiteral("options")] = options;

    return QJsonDocument(root).toJson(QJsonDocument::Compact);
}

void WritingToolsController::applyAction(const QString &action, const QString &tone)
{
    if (m_selectedText.trimmed().isEmpty()) {
        captureSelection();
        if (m_selectedText.trimmed().isEmpty()) {
            setStatus(QStringLiteral("Selecciona un texto primero para procesarlo"));
            return;
        }
    }

    cancelGeneration();

    m_currentAction = action;
    m_currentTone = tone;
    Q_EMIT currentActionChanged();
    Q_EMIT currentToneChanged();

    m_resultText.clear();
    Q_EMIT resultTextChanged();

    m_isGenerating = true;
    Q_EMIT isGeneratingChanged();

    setStatus(QStringLiteral("Generando con Apple Intelligence (Ollama)..."));

    const QString fullPrompt = buildPrompt(action, tone, m_selectedText);
    const QByteArray payload = buildOllamaPayload(fullPrompt);

    QNetworkRequest req(QUrl(QStringLiteral("http://127.0.0.1:11434/api/generate")));
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));

    m_currentReply = m_nam->post(req, payload);
    connect(m_currentReply, &QNetworkReply::readyRead, this, &WritingToolsController::onNetworkReadyRead);
    connect(m_currentReply, &QNetworkReply::finished, this, &WritingToolsController::onNetworkFinished);
}

void WritingToolsController::onNetworkReadyRead()
{
    if (!m_currentReply) {
        return;
    }

    while (m_currentReply->canReadLine()) {
        const QByteArray line = m_currentReply->readLine().trimmed();
        if (line.isEmpty()) {
            continue;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(line);
        if (!doc.isObject()) {
            continue;
        }

        const QJsonObject obj = doc.object();
        const QString chunk = obj.value(QStringLiteral("response")).toString();
        if (!chunk.isEmpty()) {
            m_resultText.append(chunk);
            Q_EMIT resultTextChanged();
        }

        if (obj.value(QStringLiteral("done")).toBool(false)) {
            setStatus(QStringLiteral("Completado"));
        }
    }
}

void WritingToolsController::onNetworkFinished()
{
    if (m_currentReply) {
        if (m_currentReply->error() != QNetworkReply::NoError) {
            setStatus(QStringLiteral("Error: %1").arg(m_currentReply->errorString()));
            if (m_resultText.isEmpty()) {
                m_resultText = QStringLiteral("No se pudo conectar con Ollama en http://127.0.0.1:11434. Asegúrate de que el servicio está activo.");
                Q_EMIT resultTextChanged();
            }
        }
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }

    m_isGenerating = false;
    Q_EMIT isGeneratingChanged();
}

void WritingToolsController::cancelGeneration()
{
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }

    if (m_isGenerating) {
        m_isGenerating = false;
        Q_EMIT isGeneratingChanged();
        setStatus(QStringLiteral("Generación cancelada"));
    }
}

void WritingToolsController::replaceInApp()
{
    if (m_resultText.trimmed().isEmpty()) {
        return;
    }

    const QString textToInsert = m_resultText.trimmed();

    // 1. Write to Qt clipboards (Clipboard & Selection)
    if (auto *cb = QGuiApplication::clipboard()) {
        cb->setText(textToInsert, QClipboard::Clipboard);
        cb->setText(textToInsert, QClipboard::Selection);
    }

    // 2. Write to Wayland primary selection and regular clipboard via wl-copy
    QProcess::execute(QStringLiteral("wl-copy"), {QStringLiteral("-p"), textToInsert});
    QProcess::execute(QStringLiteral("wl-copy"), {textToInsert});

    // 3. Hide HUD and signal replacement
    setHudVisible(false);
    Q_EMIT replaceRequested();
}

void WritingToolsController::copyResult()
{
    if (m_resultText.trimmed().isEmpty()) {
        return;
    }

    const QString textToCopy = m_resultText.trimmed();
    if (auto *cb = QGuiApplication::clipboard()) {
        cb->setText(textToCopy, QClipboard::Clipboard);
        cb->setText(textToCopy, QClipboard::Selection);
    }

    QProcess::execute(QStringLiteral("wl-copy"), {textToCopy});
    setStatus(QStringLiteral("¡Copiado al portapapeles!"));
}
