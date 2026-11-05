/*
    SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QClipboard>
#include <QGuiApplication>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QProcess>
#include <QString>

class WritingToolsController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString selectedText READ selectedText WRITE setSelectedText NOTIFY selectedTextChanged)
    Q_PROPERTY(QString resultText READ resultText WRITE setResultText NOTIFY resultTextChanged)
    Q_PROPERTY(bool isGenerating READ isGenerating NOTIFY isGeneratingChanged)
    Q_PROPERTY(QString currentAction READ currentAction NOTIFY currentActionChanged)
    Q_PROPERTY(QString currentTone READ currentTone NOTIFY currentToneChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool hudVisible READ hudVisible WRITE setHudVisible NOTIFY hudVisibleChanged)

public:
    explicit WritingToolsController(QObject *parent = nullptr);
    ~WritingToolsController() override;

    QString selectedText() const { return m_selectedText; }
    void setSelectedText(const QString &text);

    QString resultText() const { return m_resultText; }
    void setResultText(const QString &text);

    bool isGenerating() const { return m_isGenerating; }
    QString currentAction() const { return m_currentAction; }
    QString currentTone() const { return m_currentTone; }
    QString statusMessage() const { return m_statusMessage; }
    bool hudVisible() const { return m_hudVisible; }
    void setHudVisible(bool visible);

    // QML / User Invocations
    Q_INVOKABLE void captureSelection();
    Q_INVOKABLE void applyAction(const QString &action, const QString &tone = QString());
    Q_INVOKABLE void regenerate();
    Q_INVOKABLE void clearResult();
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void replaceInApp();
    Q_INVOKABLE void copyResult();
    Q_INVOKABLE void cancelGeneration();

    // Static Prompt Helpers (for business logic & unit tests)
    static QString buildPrompt(const QString &action, const QString &tone, const QString &sourceText);
    static QByteArray buildOllamaPayload(const QString &prompt, const QString &model = QStringLiteral("qwen2.5:7b"));

public Q_SLOTS:
    // D-Bus slots
    void Toggle();
    void Show();
    void Hide();
    void ProcessSelection(const QString &action, const QString &tone);

Q_SIGNALS:
    void selectedTextChanged();
    void resultTextChanged();
    void isGeneratingChanged();
    void currentActionChanged();
    void currentToneChanged();
    void statusMessageChanged();
    void hudVisibleChanged();
    void replaceRequested();

private Q_SLOTS:
    void onNetworkReadyRead();
    void onNetworkFinished();

private:
    void setStatus(const QString &msg);
    QString readWaylandSelection() const;

    QString m_selectedText;
    QString m_resultText;
    bool m_isGenerating = false;
    QString m_currentAction;
    QString m_currentTone;
    QString m_statusMessage;
    bool m_hudVisible = false;

    QNetworkAccessManager *m_nam = nullptr;
    QNetworkReply *m_currentReply = nullptr;
};
