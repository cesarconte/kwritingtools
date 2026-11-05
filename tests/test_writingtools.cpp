/*
    SPDX-FileCopyrightText: 2026 Cesar <yugurta@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "writingtoolscontroller.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QSignalSpy>
#include <QtTest>

class TestWritingTools : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testBuildPromptProofread()
    {
        const QString input = QStringLiteral("este texto tiene herrores ortograficos");
        const QString prompt = WritingToolsController::buildPrompt(QStringLiteral("proofread"), QString(), input);

        QVERIFY(!prompt.isEmpty());
        QVERIFY(prompt.contains(QStringLiteral("Corregir")));
        QVERIFY(prompt.contains(input));
    }

    void testBuildPromptRewriteTones()
    {
        const QString input = QStringLiteral("Necesito que me entregues el reporte mañana sin falta.");

        const QString pFriendly = WritingToolsController::buildPrompt(QStringLiteral("rewrite"), QStringLiteral("friendly"), input);
        QVERIFY(pFriendly.contains(QStringLiteral("Amigable")));
        QVERIFY(pFriendly.contains(input));

        const QString pProf = WritingToolsController::buildPrompt(QStringLiteral("rewrite"), QStringLiteral("professional"), input);
        QVERIFY(pProf.contains(QStringLiteral("Profesional")));

        const QString pConcise = WritingToolsController::buildPrompt(QStringLiteral("rewrite"), QStringLiteral("concise"), input);
        QVERIFY(pConcise.contains(QStringLiteral("Conciso")));

        const QString pSummary = WritingToolsController::buildPrompt(QStringLiteral("summary"), QString(), input);
        QVERIFY(pSummary.contains(QStringLiteral("Resumir")));

        const QString pKeypoints = WritingToolsController::buildPrompt(QStringLiteral("keypoints"), QString(), input);
        QVERIFY(pKeypoints.contains(QStringLiteral("Puntos Clave")));

        const QString pTable = WritingToolsController::buildPrompt(QStringLiteral("table"), QString(), input);
        QVERIFY(pTable.contains(QStringLiteral("Tabla")));

        const QString pTrans = WritingToolsController::buildPrompt(QStringLiteral("translate:en"), QString(), input);
        QVERIFY(pTrans.contains(QStringLiteral("Traduce")));
        QVERIFY(pTrans.contains(QStringLiteral("inglés")));
    }

    void testBuildOllamaPayload()
    {
        const QString testPrompt = QStringLiteral("Prompt de prueba");
        const QByteArray payload = WritingToolsController::buildOllamaPayload(testPrompt, QStringLiteral("qwen2.5:7b"));

        QVERIFY(!payload.isEmpty());
        const QJsonDocument doc = QJsonDocument::fromJson(payload);
        QVERIFY(doc.isObject());

        const QJsonObject obj = doc.object();
        QCOMPARE(obj.value(QStringLiteral("model")).toString(), QStringLiteral("qwen2.5:7b"));
        QCOMPARE(obj.value(QStringLiteral("prompt")).toString(), testPrompt);
        QCOMPARE(obj.value(QStringLiteral("stream")).toBool(), true);

        const QJsonObject opts = obj.value(QStringLiteral("options")).toObject();
        QCOMPARE(opts.value(QStringLiteral("temperature")).toDouble(), 0.3);
    }

    void testControllerState()
    {
        WritingToolsController ctrl;
        QCOMPARE(ctrl.isGenerating(), false);
        QCOMPARE(ctrl.hudVisible(), false);

        QSignalSpy textSpy(&ctrl, &WritingToolsController::selectedTextChanged);
        QSignalSpy hudSpy(&ctrl, &WritingToolsController::hudVisibleChanged);

        ctrl.setSelectedText(QStringLiteral("Nuevo texto de prueba"));
        QCOMPARE(textSpy.count(), 1);
        QCOMPARE(ctrl.selectedText(), QStringLiteral("Nuevo texto de prueba"));

        ctrl.setHudVisible(true);
        QCOMPARE(hudSpy.count(), 1);
        QCOMPARE(ctrl.hudVisible(), true);

        ctrl.setHudVisible(false);
        QCOMPARE(hudSpy.count(), 2);
        QCOMPARE(ctrl.hudVisible(), false);
    }
};

QTEST_MAIN(TestWritingTools)
#include "test_writingtools.moc"
