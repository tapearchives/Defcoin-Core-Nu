#include <QtCore/QDateTime>
#include <QtCore/QDir>
#include <QtCore/QElapsedTimer>
#include <QtCore/QFile>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QProcess>
#include <QtCore/QRegularExpression>
#include <QtCore/QStandardPaths>
#include <QtCore/QTemporaryDir>
#include <QtCore/QTextStream>
#include <QtCore/QSysInfo>
#include <QtGui/QDesktopServices>
#include <QtGui/QFont>
#include <QtGui/QIcon>
#include <QtGui/QPainter>
#include <QtGui/QPen>
#include <QtGui/QPixmap>
#include <QtCore/QTimer>
#include <QtCore/QUrl>
#include <QtCore/QUuid>
#include <QtNetwork/QAbstractSocket>
#include <QtNetwork/QHostAddress>
#include <QtNetwork/QHostInfo>
#include <QtNetwork/QUdpSocket>
#include <QtWidgets/QAbstractItemView>
#include <QtWidgets/QApplication>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDialog>
#include <QtWidgets/QDoubleSpinBox>
#include <QtWidgets/QFileDialog>
#include <QtWidgets/QFormLayout>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QListWidget>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMessageBox>
#include <QtWidgets/QPlainTextEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QSplitter>
#include <QtWidgets/QTableWidget>
#include <QtWidgets/QVBoxLayout>

#include <algorithm>

namespace {

constexpr quint16 BEACON_PORT = 10344;
constexpr quint16 CONTROL_PORT = 10347;
constexpr int DEFAULT_TCP_PORT = 10345;
constexpr int DEFAULT_UDP_PORT = 10346;
constexpr const char* BEACON_MAGIC = "DFCNU_FIREHOSE_BEACON_V1";
constexpr const char* CONTROL_MAGIC = "DFCNU_FIREHOSE_CONTROL_V1";

struct ResultRow {
    int phase = 0;
    QString role;
    QString protocol;
    int payload_size = 0;
    double duration_s = 0.0;
    qint64 sent_bytes = 0;
    qint64 recv_bytes = 0;
    qint64 sent_packets = 0;
    qint64 recv_packets = 0;
    qint64 lost_packets = 0;
    qint64 checksum_errors = 0;
    double mbps = 0.0;
    QString note;
};

struct PeerInfo {
    QString nodeId;
    QString host;
    QString hostname;
    QString mode;
    QString osName;
    int tcpPort = DEFAULT_TCP_PORT;
    int udpPort = DEFAULT_UDP_PORT;
};

QString formatRate(double mbps)
{
    if (mbps <= 0.0) return QStringLiteral("-");
    return QStringLiteral("%1 Mb/s").arg(QString::number(mbps, 'f', mbps >= 100.0 ? 1 : 2));
}

QString formatBytes(qint64 bytes)
{
    double value = static_cast<double>(bytes);
    const QStringList units = {QStringLiteral("B"), QStringLiteral("KB"), QStringLiteral("MB"), QStringLiteral("GB")};
    for (int i = 0; i < units.size(); ++i) {
        if (value < 1024.0 || i == units.size() - 1) {
            return i == 0
                ? QStringLiteral("%1 B").arg(bytes)
                : QStringLiteral("%1 %2").arg(QString::number(value, 'f', 1), units[i]);
        }
        value /= 1024.0;
    }
    return QStringLiteral("%1 B").arg(bytes);
}

QString csvField(const QString& line, int index)
{
    QStringList fields;
    QString current;
    bool quoted = false;
    for (int i = 0; i < line.size(); ++i) {
        const QChar ch = line.at(i);
        if (ch == QLatin1Char('"')) {
            if (quoted && i + 1 < line.size() && line.at(i + 1) == QLatin1Char('"')) {
                current.append(ch);
                ++i;
            } else {
                quoted = !quoted;
            }
        } else if (ch == QLatin1Char(',') && !quoted) {
            fields.push_back(current);
            current.clear();
        } else {
            current.append(ch);
        }
    }
    fields.push_back(current);
    return index >= 0 && index < fields.size() ? fields.at(index) : QString();
}

qint64 toInt64(const QString& value)
{
    bool ok = false;
    const qint64 parsed = value.trimmed().toLongLong(&ok);
    return ok ? parsed : 0;
}

double toDouble(const QString& value)
{
    bool ok = false;
    const double parsed = value.trimmed().toDouble(&ok);
    return ok ? parsed : 0.0;
}

class ThroughputChart final : public QWidget {
public:
    explicit ThroughputChart(QWidget* parent = nullptr) : QWidget(parent)
    {
        setMinimumHeight(180);
        setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    }

    void setRows(const QList<ResultRow>& rows)
    {
        m_rows = rows;
        update();
    }

protected:
    void paintEvent(QPaintEvent*) override
    {
        QPainter painter(this);
        painter.setRenderHint(QPainter::Antialiasing, true);
        painter.fillRect(rect(), QColor(250, 251, 252));

        const QRectF plot = rect().adjusted(54, 18, -18, -38);
        painter.setPen(QPen(QColor(210, 214, 219), 1));
        painter.drawRect(plot);

        double max_rate = 1.0;
        for (const ResultRow& row : m_rows) {
            max_rate = std::max(max_rate, row.mbps);
        }
        const int max_phase = std::max(1, m_rows.isEmpty() ? 1 : m_rows.last().phase);

        painter.setPen(QColor(80, 88, 99));
        painter.drawText(QRectF(4, plot.top() - 2, 48, 18), Qt::AlignRight | Qt::AlignVCenter, formatRate(max_rate));
        painter.drawText(QRectF(4, plot.bottom() - 12, 48, 18), Qt::AlignRight | Qt::AlignVCenter, QStringLiteral("0"));
        painter.drawText(QRectF(plot.left(), plot.bottom() + 10, plot.width(), 22), Qt::AlignCenter, QStringLiteral("Phase order"));

        auto point_for = [&](const ResultRow& row) {
            const double x = plot.left() + (static_cast<double>(row.phase) / max_phase) * plot.width();
            const double y = plot.bottom() - (row.mbps / max_rate) * plot.height();
            return QPointF(x, y);
        };

        auto draw_series = [&](const QString& protocol, const QColor& color) {
            QVector<QPointF> points;
            for (const ResultRow& row : m_rows) {
                if (row.protocol.compare(protocol, Qt::CaseInsensitive) == 0) {
                    points.push_back(point_for(row));
                }
            }
            painter.setPen(QPen(color, 2.5));
            for (int i = 1; i < points.size(); ++i) {
                painter.drawLine(points.at(i - 1), points.at(i));
            }
            painter.setBrush(color);
            painter.setPen(Qt::NoPen);
            for (const QPointF& point : points) {
                painter.drawEllipse(point, 4, 4);
            }
        };

        draw_series(QStringLiteral("tcp"), QColor(43, 119, 228));
        draw_series(QStringLiteral("udp"), QColor(36, 168, 112));

        painter.setPen(QColor(43, 119, 228));
        painter.drawText(QRectF(plot.left(), 0, 90, 20), Qt::AlignLeft | Qt::AlignVCenter, QStringLiteral("TCP"));
        painter.setPen(QColor(36, 168, 112));
        painter.drawText(QRectF(plot.left() + 54, 0, 90, 20), Qt::AlignLeft | Qt::AlignVCenter, QStringLiteral("UDP"));

        if (m_rows.isEmpty()) {
            painter.setPen(QColor(110, 118, 129));
            painter.drawText(plot, Qt::AlignCenter, QStringLiteral("Start a firehose test to plot throughput"));
        }
    }

private:
    QList<ResultRow> m_rows;
};

class MainWindow final : public QMainWindow {
public:
    MainWindow()
    {
        setWindowTitle(QStringLiteral("LAN Firehose Throughput Test"));
        setWindowIcon(QIcon(iconPath()));
        resize(1120, 780);
        m_nodeId = QUuid::createUuid().toString(QUuid::WithoutBraces);

        m_process = new QProcess(this);
        m_process->setProcessChannelMode(QProcess::MergedChannels);
        connect(m_process, &QProcess::readyReadStandardOutput, this, &MainWindow::readProcessOutput);
        connect(m_process, &QProcess::finished, this, &MainWindow::processFinished);

        m_pollTimer = new QTimer(this);
        connect(m_pollTimer, &QTimer::timeout, this, &MainWindow::pollCsv);

        m_beaconSocket = new QUdpSocket(this);
        m_beaconSocket->setSocketOption(QAbstractSocket::MulticastTtlOption, 1);
        m_beaconTimer = new QTimer(this);
        connect(m_beaconTimer, &QTimer::timeout, this, &MainWindow::sendIdleBeacon);
        m_beaconTimer->start(1000);

        m_controlSocket = new QUdpSocket(this);
        if (m_controlSocket->bind(QHostAddress::AnyIPv4, CONTROL_PORT, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
            connect(m_controlSocket, &QUdpSocket::readyRead, this, &MainWindow::readControlPackets);
        }

        auto* root = new QWidget(this);
        auto* rootLayout = new QVBoxLayout(root);
        rootLayout->setContentsMargins(14, 12, 14, 12);
        rootLayout->setSpacing(10);

        auto* mast = new QWidget(root);
        auto* mastRow = new QHBoxLayout(mast);
        mastRow->setContentsMargins(0, 0, 0, 0);
        mastRow->setSpacing(12);
        auto* icon = new QLabel(mast);
        const QPixmap iconImage(iconPath());
        if (!iconImage.isNull()) {
            icon->setPixmap(iconImage.scaled(84, 84, Qt::KeepAspectRatio, Qt::SmoothTransformation));
        }
        icon->setFixedSize(90, 90);
        icon->setAlignment(Qt::AlignCenter);
        mastRow->addWidget(icon);
        auto* intro = new QLabel(QStringLiteral(
            "<b>LAN Firehose Throughput Test v%1</b><br>"
            "Compare TCP and UDP transfer behavior between two machines. "
            "Use Spray to send test traffic and Catch to receive it. "
            "This diagnostic tool does not read wallets, use RPC, or submit blocks.")
            .arg(releaseName()));
        intro->setWordWrap(true);
        intro->setTextFormat(Qt::RichText);
        mastRow->addWidget(intro, 1);
        auto* about = new QPushButton(QStringLiteral("About"), mast);
        connect(about, &QPushButton::clicked, this, &MainWindow::showAbout);
        mastRow->addWidget(about, 0, Qt::AlignTop);
        rootLayout->addWidget(mast);

        rootLayout->addWidget(buildControls());
        rootLayout->addWidget(buildStats());

        m_chart = new ThroughputChart(root);
        rootLayout->addWidget(m_chart);

        auto* splitter = new QSplitter(Qt::Vertical, root);
        m_table = new QTableWidget(splitter);
        m_table->setColumnCount(12);
        m_table->setHorizontalHeaderLabels({
            QStringLiteral("Phase"),
            QStringLiteral("Role"),
            QStringLiteral("Protocol"),
            QStringLiteral("Payload"),
            QStringLiteral("Duration"),
            QStringLiteral("Sent"),
            QStringLiteral("Received"),
            QStringLiteral("Sent pkts"),
            QStringLiteral("Recv pkts"),
            QStringLiteral("Lost"),
            QStringLiteral("Checksum"),
            QStringLiteral("Mb/s"),
        });
        m_table->setSelectionBehavior(QAbstractItemView::SelectRows);
        m_table->setEditTriggers(QAbstractItemView::NoEditTriggers);
        m_table->horizontalHeader()->setSectionResizeMode(QHeaderView::ResizeToContents);
        m_table->horizontalHeader()->setStretchLastSection(true);

        m_log = new QPlainTextEdit(splitter);
        m_log->setReadOnly(true);
        m_log->setMaximumBlockCount(2000);
        m_log->setPlaceholderText(QStringLiteral("Process output appears here."));
        splitter->addWidget(m_table);
        splitter->addWidget(m_log);
        splitter->setStretchFactor(0, 3);
        splitter->setStretchFactor(1, 2);
        rootLayout->addWidget(splitter, 1);

        setCentralWidget(root);
        refreshButtonState(false);
    }

private:
    QWidget* buildControls()
    {
        auto* box = new QGroupBox(QStringLiteral("Test setup"), this);
        auto* grid = new QGridLayout(box);
        grid->setColumnStretch(1, 1);
        grid->setColumnStretch(3, 1);

        m_mode = new QComboBox(box);
        m_mode->addItem(QStringLiteral("Auto pair"), QStringLiteral("auto"));
        m_mode->addItem(QStringLiteral("Spray"), QStringLiteral("hose"));
        m_mode->addItem(QStringLiteral("Catch"), QStringLiteral("sink"));
        m_mode->setToolTip(QStringLiteral("Auto pair discovers another tester and picks a role. Spray sends test traffic. Catch receives and measures incoming traffic."));

        m_peer = new QLineEdit(box);
        m_peer->setPlaceholderText(QStringLiteral("Target IP for Spray, e.g. 192.168.2.19"));
        m_peer->setToolTip(QStringLiteral("Only needed for manual Spray mode. Leave blank to discover visible testers."));

        m_duration = new QSpinBox(box);
        m_duration->setRange(4, 3600);
        m_duration->setValue(120);
        m_duration->setSuffix(QStringLiteral(" s"));

        m_switchSeconds = new QSpinBox(box);
        m_switchSeconds->setRange(2, 600);
        m_switchSeconds->setValue(60);
        m_switchSeconds->setSuffix(QStringLiteral(" s"));
        m_switchSeconds->setToolTip(QStringLiteral("Approximate time spent on each TCP or UDP window before switching protocol."));

        m_profile = new QComboBox(box);
        m_profile->addItems({QStringLiteral("practical"), QStringLiteral("conservative"), QStringLiteral("jumbo")});
        m_profile->setToolTip(QStringLiteral("Practical includes sub-MTU and larger LAN payloads. Conservative stays under common internet MTU limits. Jumbo intentionally tests large packets."));

        m_packetSizes = new QLineEdit(box);
        m_packetSizes->setPlaceholderText(QStringLiteral("Optional: 576,1280,1472,4096"));
        m_packetSizes->setToolTip(QStringLiteral("Comma-separated payload sizes. Leave blank to use the selected profile."));

        m_token = new QLineEdit(box);
        m_token->setPlaceholderText(QStringLiteral("Optional pairing token"));
        m_token->setToolTip(QStringLiteral("Use the same token on both machines to avoid pairing with the wrong tester."));

        m_udpChecksum = new QCheckBox(QStringLiteral("UDP checksum"), box);
        m_udpChecksum->setToolTip(QStringLiteral("Adds a CRC32 payload check in the test packet. Useful for measuring checksum overhead."));

        m_noBeacon = new QCheckBox(QStringLiteral("No beacon"), box);
        m_noBeacon->setToolTip(QStringLiteral("Disable LAN discovery beacon. Use this with manual Spray/Catch tests."));

        m_manualPick = new QCheckBox(QStringLiteral("Manual pick one tester"), box);
        m_manualPick->setToolTip(QStringLiteral("Leave off for automatic all-visible-tester mode. Turn on when you want a one-to-one test and a picker dialog."));

        m_start = new QPushButton(QStringLiteral("Start"), box);
        m_start->setDefault(true);
        connect(m_start, &QPushButton::clicked, this, &MainWindow::startTest);

        m_stop = new QPushButton(QStringLiteral("Stop"), box);
        connect(m_stop, &QPushButton::clicked, this, &MainWindow::stopTest);

        auto* openLog = new QPushButton(QStringLiteral("Open text log"), box);
        openLog->setToolTip(QStringLiteral("Open the readable .log file in the OS default text/log viewer. The JSONL sidecar remains available for machine parsing."));
        connect(openLog, &QPushButton::clicked, this, [this] { openPath(m_debugLogPath); });

        auto* openJson = new QPushButton(QStringLiteral("Open JSONL"), box);
        openJson->setToolTip(QStringLiteral("Open the structured machine-readable event log."));
        connect(openJson, &QPushButton::clicked, this, [this] { openPath(m_jsonlPath); });

        auto* openCsv = new QPushButton(QStringLiteral("Open CSV"), box);
        connect(openCsv, &QPushButton::clicked, this, [this] { openPath(m_csvPath); });

        auto* clear = new QPushButton(QStringLiteral("Clear"), box);
        connect(clear, &QPushButton::clicked, this, &MainWindow::clearResults);

        grid->addWidget(new QLabel(QStringLiteral("Role")), 0, 0);
        grid->addWidget(m_mode, 0, 1);
        grid->addWidget(new QLabel(QStringLiteral("Target")), 0, 2);
        grid->addWidget(m_peer, 0, 3);
        grid->addWidget(new QLabel(QStringLiteral("Duration")), 1, 0);
        grid->addWidget(m_duration, 1, 1);
        grid->addWidget(new QLabel(QStringLiteral("Switch every")), 1, 2);
        grid->addWidget(m_switchSeconds, 1, 3);
        grid->addWidget(new QLabel(QStringLiteral("Payload profile")), 2, 0);
        grid->addWidget(m_profile, 2, 1);
        grid->addWidget(new QLabel(QStringLiteral("Packet sizes")), 2, 2);
        grid->addWidget(m_packetSizes, 2, 3);
        grid->addWidget(new QLabel(QStringLiteral("Token")), 3, 0);
        grid->addWidget(m_token, 3, 1);
        grid->addWidget(m_udpChecksum, 3, 2);
        grid->addWidget(m_noBeacon, 3, 3);
        grid->addWidget(m_manualPick, 4, 0, 1, 2);

        auto* buttons = new QWidget(box);
        auto* buttonRow = new QHBoxLayout(buttons);
        buttonRow->setContentsMargins(0, 0, 0, 0);
        buttonRow->addWidget(m_start);
        buttonRow->addWidget(m_stop);
        buttonRow->addStretch(1);
        buttonRow->addWidget(openLog);
        buttonRow->addWidget(openJson);
        buttonRow->addWidget(openCsv);
        buttonRow->addWidget(clear);
        grid->addWidget(buttons, 5, 0, 1, 4);
        return box;
    }

    QWidget* buildStats()
    {
        auto* box = new QGroupBox(QStringLiteral("Live stats"), this);
        auto* grid = new QGridLayout(box);
        m_status = statLabel(QStringLiteral("Idle"));
        m_role = statLabel(QStringLiteral("-"));
        m_tcp = statLabel(QStringLiteral("-"));
        m_udp = statLabel(QStringLiteral("-"));
        m_best = statLabel(QStringLiteral("-"));
        m_errors = statLabel(QStringLiteral("-"));
        grid->addWidget(new QLabel(QStringLiteral("Status")), 0, 0);
        grid->addWidget(m_status, 0, 1);
        grid->addWidget(new QLabel(QStringLiteral("Role / peer")), 0, 2);
        grid->addWidget(m_role, 0, 3);
        grid->addWidget(new QLabel(QStringLiteral("TCP avg")), 1, 0);
        grid->addWidget(m_tcp, 1, 1);
        grid->addWidget(new QLabel(QStringLiteral("UDP avg")), 1, 2);
        grid->addWidget(m_udp, 1, 3);
        grid->addWidget(new QLabel(QStringLiteral("Best")), 2, 0);
        grid->addWidget(m_best, 2, 1);
        grid->addWidget(new QLabel(QStringLiteral("UDP loss/check")), 2, 2);
        grid->addWidget(m_errors, 2, 3);
        grid->setColumnStretch(1, 1);
        grid->setColumnStretch(3, 1);
        return box;
    }

    QLabel* statLabel(const QString& text)
    {
        auto* label = new QLabel(text, this);
        label->setTextInteractionFlags(Qt::TextSelectableByMouse | Qt::TextSelectableByKeyboard);
        label->setMinimumWidth(120);
        return label;
    }

    void startTest()
    {
        if (m_process->state() != QProcess::NotRunning) return;
        clearResults();

        QList<PeerInfo> discoveredPeers;
        PeerInfo selectedPeer;
        const QString modeValue = m_mode->currentData().toString();
        const bool manualTarget = !m_peer->text().trimmed().isEmpty();
        const bool manualPick = m_manualPick->isChecked();
        if (!manualTarget && !m_noBeacon->isChecked()) {
            discoveredPeers = discoverPeers(1800);
            if (manualPick && discoveredPeers.size() > 1) {
                if (!choosePeer(discoveredPeers, selectedPeer)) {
                    m_status->setText(QStringLiteral("Cancelled"));
                    return;
                }
            } else if (manualPick && discoveredPeers.size() == 1) {
                selectedPeer = discoveredPeers.first();
            }
        }

        allocateOutputPaths();

        QStringList args;
        args << scriptPath()
             << QStringLiteral("--mode") << modeValue
             << QStringLiteral("--duration") << QString::number(m_duration->value())
             << QStringLiteral("--switch-seconds") << QString::number(m_switchSeconds->value())
             << QStringLiteral("--size-profile") << m_profile->currentText()
             << QStringLiteral("--log-jsonl") << m_jsonlPath
             << QStringLiteral("--debug-log") << m_debugLogPath
             << QStringLiteral("--csv") << m_csvPath;
        if (manualTarget) {
            args << QStringLiteral("--peer") << m_peer->text().trimmed();
        } else if (!manualPick && (modeValue == QStringLiteral("hose") || modeValue == QStringLiteral("auto")) && !discoveredPeers.isEmpty()) {
            args << QStringLiteral("--peers-json") << peersJson(discoveredPeers);
        } else if (!selectedPeer.host.isEmpty()) {
            if (modeValue == QStringLiteral("sink")) {
                args << QStringLiteral("--accept-peer") << selectedPeer.host;
            } else {
                args << QStringLiteral("--peer") << selectedPeer.host
                     << QStringLiteral("--peer-node-id") << selectedPeer.nodeId
                     << QStringLiteral("--peer-hostname") << selectedPeer.hostname
                     << QStringLiteral("--peer-tcp-port") << QString::number(selectedPeer.tcpPort)
                     << QStringLiteral("--peer-udp-port") << QString::number(selectedPeer.udpPort);
            }
        }
        if (!m_packetSizes->text().trimmed().isEmpty()) args << QStringLiteral("--packet-sizes") << m_packetSizes->text().trimmed();
        if (!m_token->text().trimmed().isEmpty()) args << QStringLiteral("--token") << m_token->text().trimmed();
        if (m_noBeacon->isChecked()) args << QStringLiteral("--no-beacon");
        if (m_udpChecksum->isChecked()) args << QStringLiteral("--udp-checksum");

        if (!discoveredPeers.isEmpty()) {
            m_log->appendPlainText(QStringLiteral("Discovered %1 visible tester%2.")
                .arg(discoveredPeers.size())
                .arg(discoveredPeers.size() == 1 ? QString() : QStringLiteral("s")));
        }
        if (modeValue == QStringLiteral("sink") && !manualPick) {
            m_log->appendPlainText(QStringLiteral("Catch mode accepting all visible senders; UDP/TCP rows are separated by sender address and UDP port."));
        } else if ((modeValue == QStringLiteral("hose") || modeValue == QStringLiteral("auto")) && !manualPick && !discoveredPeers.isEmpty()) {
            m_log->appendPlainText(QStringLiteral("Spraying all visible testers at once."));
            sendStartCatchControls(discoveredPeers);
        }
        m_log->appendPlainText(QStringLiteral("$ python3 %1").arg(args.join(QLatin1Char(' '))));
        m_process->start(QStringLiteral("python3"), args);
        if (!m_process->waitForStarted(3000)) {
            QMessageBox::warning(this, QStringLiteral("Firehose did not start"), m_process->errorString());
            refreshButtonState(false);
            return;
        }
        m_status->setText(QStringLiteral("Running"));
        refreshButtonState(true);
        m_pollTimer->start(500);
    }

    void allocateOutputPaths()
    {
        const QDir outDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/firehose"));
        QDir().mkpath(outDir.path());
        const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-hhmmss"));
        m_jsonlPath = outDir.filePath(QStringLiteral("nu-firehose-%1.jsonl").arg(stamp));
        m_debugLogPath = outDir.filePath(QStringLiteral("nu-firehose-%1.log").arg(stamp));
        m_csvPath = outDir.filePath(QStringLiteral("nu-firehose-%1.csv").arg(stamp));
    }

    QString workstationName() const
    {
        const QString host = QHostInfo::localHostName().trimmed();
        return host.isEmpty() ? QStringLiteral("unknown-workstation") : host;
    }

    void sendIdleBeacon()
    {
        if (!m_beaconSocket || (m_noBeacon && m_noBeacon->isChecked())) return;
        QJsonObject obj;
        obj.insert(QStringLiteral("magic"), QString::fromLatin1(BEACON_MAGIC));
        obj.insert(QStringLiteral("node_id"), m_nodeId);
        obj.insert(QStringLiteral("hostname"), workstationName());
        obj.insert(QStringLiteral("mode"), m_mode ? m_mode->currentData().toString() : QStringLiteral("auto"));
        obj.insert(QStringLiteral("os"), QSysInfo::prettyProductName());
        obj.insert(QStringLiteral("tcp_port"), DEFAULT_TCP_PORT);
        obj.insert(QStringLiteral("udp_port"), DEFAULT_UDP_PORT);
        obj.insert(QStringLiteral("control_port"), CONTROL_PORT);
        obj.insert(QStringLiteral("state"), m_process && m_process->state() != QProcess::NotRunning ? QStringLiteral("running") : QStringLiteral("idle"));
        obj.insert(QStringLiteral("token"), m_token ? m_token->text().trimmed() : QString());
        obj.insert(QStringLiteral("version"), 2);
        const QByteArray payload = QJsonDocument(obj).toJson(QJsonDocument::Compact);
        m_beaconSocket->writeDatagram(payload, QHostAddress::Broadcast, BEACON_PORT);
    }

    void sendStartCatchControls(const QList<PeerInfo>& peers)
    {
        if (!m_beaconSocket) return;
        QJsonObject obj;
        obj.insert(QStringLiteral("magic"), QString::fromLatin1(CONTROL_MAGIC));
        obj.insert(QStringLiteral("command"), QStringLiteral("start-catch"));
        obj.insert(QStringLiteral("node_id"), m_nodeId);
        obj.insert(QStringLiteral("hostname"), workstationName());
        obj.insert(QStringLiteral("token"), m_token->text().trimmed());
        obj.insert(QStringLiteral("duration"), m_duration->value());
        obj.insert(QStringLiteral("switch_seconds"), m_switchSeconds->value());
        obj.insert(QStringLiteral("size_profile"), m_profile->currentText());
        obj.insert(QStringLiteral("packet_sizes"), m_packetSizes->text().trimmed());
        obj.insert(QStringLiteral("udp_checksum"), m_udpChecksum->isChecked());
        obj.insert(QStringLiteral("version"), 1);
        const QByteArray payload = QJsonDocument(obj).toJson(QJsonDocument::Compact);
        for (const PeerInfo& peer : peers) {
            m_beaconSocket->writeDatagram(payload, QHostAddress(peer.host), CONTROL_PORT);
        }
    }

    void readControlPackets()
    {
        while (m_controlSocket && m_controlSocket->hasPendingDatagrams()) {
            QByteArray datagram;
            datagram.resize(static_cast<int>(m_controlSocket->pendingDatagramSize()));
            QHostAddress sender;
            quint16 senderPort = 0;
            m_controlSocket->readDatagram(datagram.data(), datagram.size(), &sender, &senderPort);
            Q_UNUSED(senderPort);

            const QJsonDocument doc = QJsonDocument::fromJson(datagram);
            if (!doc.isObject()) continue;
            const QJsonObject obj = doc.object();
            if (obj.value(QStringLiteral("magic")).toString() != QString::fromLatin1(CONTROL_MAGIC)) continue;
            if (obj.value(QStringLiteral("node_id")).toString() == m_nodeId) continue;
            if (!m_token->text().trimmed().isEmpty() && obj.value(QStringLiteral("token")).toString() != m_token->text().trimmed()) continue;
            if (obj.value(QStringLiteral("command")).toString() == QStringLiteral("start-catch")) {
                startCatchFromControl(obj, sender.toString());
            }
        }
    }

    void startCatchFromControl(const QJsonObject& obj, const QString& senderHost)
    {
        if (m_process->state() != QProcess::NotRunning) {
            m_log->appendPlainText(QStringLiteral("Ignored remote start from %1 because a test is already running.").arg(senderHost));
            return;
        }
        clearResults();
        allocateOutputPaths();

        QStringList args;
        args << scriptPath()
             << QStringLiteral("--mode") << QStringLiteral("sink")
             << QStringLiteral("--duration") << QString::number(obj.value(QStringLiteral("duration")).toInt(m_duration->value()))
             << QStringLiteral("--switch-seconds") << QString::number(obj.value(QStringLiteral("switch_seconds")).toInt(m_switchSeconds->value()))
             << QStringLiteral("--size-profile") << obj.value(QStringLiteral("size_profile")).toString(m_profile->currentText())
             << QStringLiteral("--log-jsonl") << m_jsonlPath
             << QStringLiteral("--debug-log") << m_debugLogPath
             << QStringLiteral("--csv") << m_csvPath
             << QStringLiteral("--accept-peer") << senderHost;
        const QString packetSizes = obj.value(QStringLiteral("packet_sizes")).toString();
        if (!packetSizes.isEmpty()) args << QStringLiteral("--packet-sizes") << packetSizes;
        const QString token = obj.value(QStringLiteral("token")).toString();
        if (!token.isEmpty()) args << QStringLiteral("--token") << token;
        if (obj.value(QStringLiteral("udp_checksum")).toBool(false)) args << QStringLiteral("--udp-checksum");

        m_log->appendPlainText(QStringLiteral("Remote Auto Pair start from %1 (%2). Starting Catch mode.").arg(senderHost, obj.value(QStringLiteral("hostname")).toString()));
        m_log->appendPlainText(QStringLiteral("$ python3 %1").arg(args.join(QLatin1Char(' '))));
        m_process->start(QStringLiteral("python3"), args);
        if (!m_process->waitForStarted(3000)) {
            QMessageBox::warning(this, QStringLiteral("Firehose did not start"), m_process->errorString());
            refreshButtonState(false);
            return;
        }
        m_status->setText(QStringLiteral("Running remote Catch"));
        refreshButtonState(true);
        m_pollTimer->start(500);
    }

    void stopTest()
    {
        if (m_process->state() == QProcess::NotRunning) return;
        m_status->setText(QStringLiteral("Stopping"));
        m_process->terminate();
        if (!m_process->waitForFinished(1500)) {
            m_process->kill();
        }
    }

    void readProcessOutput()
    {
        const QString text = QString::fromLocal8Bit(m_process->readAllStandardOutput());
        const QStringList lines = text.split(QLatin1Char('\n'));
        for (const QString& line : lines) {
            const QString trimmed = line.trimmed();
            if (trimmed.isEmpty()) continue;
            m_log->appendPlainText(trimmed);
            if (trimmed.startsWith(QStringLiteral("Selected role:"))) {
                m_role->setText(trimmed.mid(QStringLiteral("Selected role:").size()).trimmed());
            } else if (trimmed.startsWith(QStringLiteral("Peer:"))) {
                m_role->setText(m_role->text() + QStringLiteral(" | ") + trimmed.mid(5).trimmed());
            }
        }
    }

    void processFinished(int exitCode, QProcess::ExitStatus status)
    {
        m_pollTimer->stop();
        pollCsv();
        m_status->setText(status == QProcess::NormalExit
            ? QStringLiteral("Finished (%1)").arg(exitCode)
            : QStringLiteral("Crashed/stopped"));
        refreshButtonState(false);
    }

    void pollCsv()
    {
        QFile file(m_csvPath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
        QTextStream in(&file);
        const QString header = in.readLine();
        Q_UNUSED(header);
        QList<ResultRow> rows;
        while (!in.atEnd()) {
            const QString line = in.readLine();
            if (line.trimmed().isEmpty()) continue;
            ResultRow row;
            row.phase = static_cast<int>(toInt64(csvField(line, 0)));
            row.role = csvField(line, 1);
            row.protocol = csvField(line, 2);
            row.payload_size = static_cast<int>(toInt64(csvField(line, 3)));
            row.duration_s = toDouble(csvField(line, 4));
            row.sent_bytes = toInt64(csvField(line, 5));
            row.recv_bytes = toInt64(csvField(line, 6));
            row.sent_packets = toInt64(csvField(line, 7));
            row.recv_packets = toInt64(csvField(line, 8));
            row.lost_packets = toInt64(csvField(line, 9));
            row.checksum_errors = toInt64(csvField(line, 11));
            row.mbps = toDouble(csvField(line, 12));
            row.note = csvField(line, 13);
            rows.push_back(row);
        }
        if (rows.size() == m_rows.size()) return;
        m_rows = rows;
        rebuildTable();
        updateStats();
        m_chart->setRows(m_rows);
    }

    void rebuildTable()
    {
        m_table->setRowCount(m_rows.size());
        for (int i = 0; i < m_rows.size(); ++i) {
            const ResultRow& row = m_rows.at(i);
            const QStringList values = {
                QString::number(row.phase),
                row.role,
                row.protocol.toUpper(),
                QStringLiteral("%1 B").arg(row.payload_size),
                QStringLiteral("%1 s").arg(QString::number(row.duration_s, 'f', 2)),
                formatBytes(row.sent_bytes),
                formatBytes(row.recv_bytes),
                QString::number(row.sent_packets),
                QString::number(row.recv_packets),
                QString::number(row.lost_packets),
                QString::number(row.checksum_errors),
                formatRate(row.mbps),
            };
            for (int col = 0; col < values.size(); ++col) {
                auto* item = new QTableWidgetItem(values.at(col));
                if (col == 2) {
                    item->setForeground(row.protocol.compare(QStringLiteral("udp"), Qt::CaseInsensitive) == 0 ? QColor(36, 168, 112) : QColor(43, 119, 228));
                }
                if (col >= 3) item->setTextAlignment(Qt::AlignRight | Qt::AlignVCenter);
                m_table->setItem(i, col, item);
            }
        }
        m_table->resizeColumnsToContents();
    }

    void updateStats()
    {
        double tcp_sum = 0.0, udp_sum = 0.0, best = 0.0;
        int tcp_count = 0, udp_count = 0;
        qint64 lost = 0, checks = 0;
        QString best_label;
        for (const ResultRow& row : m_rows) {
            if (row.protocol.compare(QStringLiteral("tcp"), Qt::CaseInsensitive) == 0) {
                tcp_sum += row.mbps;
                ++tcp_count;
            } else if (row.protocol.compare(QStringLiteral("udp"), Qt::CaseInsensitive) == 0) {
                udp_sum += row.mbps;
                ++udp_count;
                lost += row.lost_packets;
                checks += row.checksum_errors;
            }
            if (row.mbps > best) {
                best = row.mbps;
                best_label = QStringLiteral("%1 phase %2 @ %3 B").arg(row.protocol.toUpper()).arg(row.phase).arg(row.payload_size);
            }
        }
        m_tcp->setText(tcp_count ? formatRate(tcp_sum / tcp_count) : QStringLiteral("-"));
        m_udp->setText(udp_count ? formatRate(udp_sum / udp_count) : QStringLiteral("-"));
        m_best->setText(best > 0.0 ? QStringLiteral("%1 (%2)").arg(formatRate(best), best_label) : QStringLiteral("-"));
        m_errors->setText(udp_count ? QStringLiteral("lost %1 | checksum %2").arg(lost).arg(checks) : QStringLiteral("-"));
    }

    void clearResults()
    {
        m_rows.clear();
        m_table->setRowCount(0);
        if (m_chart) m_chart->setRows(m_rows);
        if (m_log) m_log->clear();
        m_tcp->setText(QStringLiteral("-"));
        m_udp->setText(QStringLiteral("-"));
        m_best->setText(QStringLiteral("-"));
        m_errors->setText(QStringLiteral("-"));
        m_role->setText(QStringLiteral("-"));
    }

    void refreshButtonState(bool running)
    {
        m_start->setEnabled(!running);
        m_stop->setEnabled(running);
    }

    QString scriptPath() const
    {
        const QString appDir = QCoreApplication::applicationDirPath();
#ifdef Q_OS_MACOS
        const QString bundled = QDir(appDir).filePath(QStringLiteral("../Resources/lan_firehose/LAN_Firehose_Throughput_Test.py"));
#else
        const QString bundled = QDir(appDir).filePath(QStringLiteral("lan_firehose/LAN_Firehose_Throughput_Test.py"));
#endif
        if (QFile::exists(bundled)) return QDir::cleanPath(bundled);
#ifdef DEFCOIN_FIREHOSE_SCRIPT_SRC
        return QStringLiteral(DEFCOIN_FIREHOSE_SCRIPT_SRC);
#else
        return QDir::cleanPath(QDir(appDir).filePath(QStringLiteral("../tools/lan_firehose/LAN_Firehose_Throughput_Test.py")));
#endif
    }

    QString iconPath() const
    {
        const QString appDir = QCoreApplication::applicationDirPath();
#ifdef Q_OS_MACOS
        const QString bundled = QDir(appDir).filePath(QStringLiteral("../Resources/lan_firehose/firehose_icon.png"));
#else
        const QString bundled = QDir(appDir).filePath(QStringLiteral("lan_firehose/firehose_icon.png"));
#endif
        if (QFile::exists(bundled)) return QDir::cleanPath(bundled);
        return QDir::cleanPath(QDir(appDir).filePath(QStringLiteral("../tools/lan_firehose/assets/firehose_icon.png")));
    }

    QString releaseName() const
    {
#ifdef DEFCOIN_FIREHOSE_RELEASE_NAME
        return QStringLiteral(DEFCOIN_FIREHOSE_RELEASE_NAME);
#else
        return QStringLiteral("1.0.1");
#endif
    }

    void showAbout()
    {
        QDialog dialog(this);
        dialog.setWindowTitle(QStringLiteral("About LAN Firehose Throughput Test"));
        auto* layout = new QVBoxLayout(&dialog);
        auto* icon = new QLabel(&dialog);
        const QPixmap iconImage(iconPath());
        if (!iconImage.isNull()) {
            icon->setPixmap(iconImage.scaled(220, 220, Qt::KeepAspectRatio, Qt::SmoothTransformation));
        }
        icon->setAlignment(Qt::AlignCenter);
        layout->addWidget(icon);
        auto* text = new QLabel(QStringLiteral(
            "<h2>LAN Firehose Throughput Test v%1</h2>"
            "<p>Open diagnostic utility for measuring TCP and UDP throughput behavior between two machines.</p>"
            "<p>The hydrant and binary-water icon is bundled as project artwork for this test app.</p>"
            "<p>No wallet, blockchain, or RPC data is read by this utility.</p>")
            .arg(releaseName()), &dialog);
        text->setWordWrap(true);
        text->setTextFormat(Qt::RichText);
        text->setTextInteractionFlags(Qt::TextSelectableByMouse | Qt::TextSelectableByKeyboard);
        layout->addWidget(text);
        auto* close = new QPushButton(QStringLiteral("Close"), &dialog);
        connect(close, &QPushButton::clicked, &dialog, &QDialog::accept);
        layout->addWidget(close, 0, Qt::AlignRight);
        dialog.resize(420, 460);
        dialog.exec();
    }

    QList<PeerInfo> discoverPeers(int timeoutMs)
    {
        QList<PeerInfo> peers;
        QUdpSocket socket;
        if (!socket.bind(QHostAddress::AnyIPv4, BEACON_PORT, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
            m_log->appendPlainText(QStringLiteral("Discovery listen failed: %1").arg(socket.errorString()));
            return peers;
        }

        QElapsedTimer timer;
        timer.start();
        while (timer.elapsed() < timeoutMs) {
            if (!socket.waitForReadyRead(100)) continue;
            while (socket.hasPendingDatagrams()) {
                QByteArray datagram;
                datagram.resize(static_cast<int>(socket.pendingDatagramSize()));
                QHostAddress sender;
                quint16 senderPort = 0;
                socket.readDatagram(datagram.data(), datagram.size(), &sender, &senderPort);
                Q_UNUSED(senderPort);

                const QJsonDocument doc = QJsonDocument::fromJson(datagram);
                if (!doc.isObject()) continue;
                const QJsonObject obj = doc.object();
                if (obj.value(QStringLiteral("magic")).toString() != QString::fromLatin1(BEACON_MAGIC)) continue;
                if (!m_token->text().trimmed().isEmpty() && obj.value(QStringLiteral("token")).toString() != m_token->text().trimmed()) continue;
                if (obj.value(QStringLiteral("node_id")).toString() == m_nodeId) continue;

                PeerInfo peer;
                peer.nodeId = obj.value(QStringLiteral("node_id")).toString();
                peer.host = sender.toString();
                peer.hostname = obj.value(QStringLiteral("hostname")).toString(peer.host);
                peer.mode = obj.value(QStringLiteral("mode")).toString(QStringLiteral("unknown"));
                peer.osName = obj.value(QStringLiteral("os")).toString();
                peer.tcpPort = obj.value(QStringLiteral("tcp_port")).toInt(DEFAULT_TCP_PORT);
                peer.udpPort = obj.value(QStringLiteral("udp_port")).toInt(DEFAULT_UDP_PORT);
                if (peer.nodeId.isEmpty()) continue;

                bool known = false;
                for (PeerInfo& existing : peers) {
                    if (existing.nodeId == peer.nodeId || (existing.host == peer.host && existing.tcpPort == peer.tcpPort && existing.udpPort == peer.udpPort)) {
                        existing = peer;
                        known = true;
                        break;
                    }
                }
                if (!known) peers.push_back(peer);
            }
        }
        return peers;
    }

    bool choosePeer(const QList<PeerInfo>& peers, PeerInfo& selected)
    {
        QDialog dialog(this);
        dialog.setWindowTitle(QStringLiteral("Choose Tester"));
        auto* layout = new QVBoxLayout(&dialog);
        auto* message = new QLabel(QStringLiteral("Multiple LAN Firehose testers are visible. Choose one tester for this one-to-one manual test. Leave Manual pick off for automatic all-visible-tester mode."), &dialog);
        message->setWordWrap(true);
        layout->addWidget(message);

        auto* combo = new QComboBox(&dialog);
        for (int row = 0; row < peers.size(); ++row) {
            const PeerInfo& peer = peers.at(row);
            const QString role = peer.mode == QStringLiteral("hose") ? QStringLiteral("Spray")
                : peer.mode == QStringLiteral("sink") ? QStringLiteral("Catch")
                : peer.mode == QStringLiteral("auto") ? QStringLiteral("Auto")
                : QStringLiteral("Unknown");
            combo->addItem(
                QStringLiteral("%1 - %2 - %3 (%4, TCP %5 / UDP %6)")
                    .arg(peer.host, peer.hostname, role, peer.osName)
                    .arg(peer.tcpPort)
                    .arg(peer.udpPort),
                row);
        }
        combo->setMinimumWidth(620);
        layout->addWidget(combo);

        auto* buttons = new QWidget(&dialog);
        auto* row = new QHBoxLayout(buttons);
        row->setContentsMargins(0, 0, 0, 0);
        row->addStretch(1);
        auto* cancel = new QPushButton(QStringLiteral("Cancel"), buttons);
        auto* use = new QPushButton(QStringLiteral("Use Selected"), buttons);
        use->setDefault(true);
        row->addWidget(cancel);
        row->addWidget(use);
        layout->addWidget(buttons);
        connect(cancel, &QPushButton::clicked, &dialog, &QDialog::reject);
        connect(use, &QPushButton::clicked, &dialog, &QDialog::accept);

        dialog.resize(720, 360);
        if (dialog.exec() != QDialog::Accepted) return false;
        const int selectedRow = combo->currentData().toInt();
        if (selectedRow < 0 || selectedRow >= peers.size()) return false;
        selected = peers.at(selectedRow);
        return true;
    }

    QString peersJson(const QList<PeerInfo>& peers) const
    {
        QJsonArray array;
        for (const PeerInfo& peer : peers) {
            QJsonObject obj;
            obj.insert(QStringLiteral("node_id"), peer.nodeId);
            obj.insert(QStringLiteral("host"), peer.host);
            obj.insert(QStringLiteral("hostname"), peer.hostname);
            obj.insert(QStringLiteral("os_name"), peer.osName);
            obj.insert(QStringLiteral("tcp_port"), peer.tcpPort);
            obj.insert(QStringLiteral("udp_port"), peer.udpPort);
            array.push_back(obj);
        }
        return QString::fromUtf8(QJsonDocument(array).toJson(QJsonDocument::Compact));
    }

    void openPath(const QString& path)
    {
        if (path.isEmpty() || !QFile::exists(path)) {
            QMessageBox::information(this, QStringLiteral("Nothing to open"), QStringLiteral("No output file has been written yet."));
            return;
        }
        QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    }

    QProcess* m_process = nullptr;
    QTimer* m_pollTimer = nullptr;
    QTimer* m_beaconTimer = nullptr;
    QUdpSocket* m_beaconSocket = nullptr;
    QUdpSocket* m_controlSocket = nullptr;
    QString m_nodeId;
    QComboBox* m_mode = nullptr;
    QLineEdit* m_peer = nullptr;
    QSpinBox* m_duration = nullptr;
    QSpinBox* m_switchSeconds = nullptr;
    QComboBox* m_profile = nullptr;
    QLineEdit* m_packetSizes = nullptr;
    QLineEdit* m_token = nullptr;
    QCheckBox* m_udpChecksum = nullptr;
    QCheckBox* m_noBeacon = nullptr;
    QCheckBox* m_manualPick = nullptr;
    QPushButton* m_start = nullptr;
    QPushButton* m_stop = nullptr;
    QLabel* m_status = nullptr;
    QLabel* m_role = nullptr;
    QLabel* m_tcp = nullptr;
    QLabel* m_udp = nullptr;
    QLabel* m_best = nullptr;
    QLabel* m_errors = nullptr;
    ThroughputChart* m_chart = nullptr;
    QTableWidget* m_table = nullptr;
    QPlainTextEdit* m_log = nullptr;
    QList<ResultRow> m_rows;
    QString m_jsonlPath;
    QString m_debugLogPath;
    QString m_csvPath;
};

} // namespace

int main(int argc, char* argv[])
{
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("LAN Firehose Throughput Test"));
    QApplication::setOrganizationName(QStringLiteral("Defcoin Core"));
    QApplication::setFont(QFont(QStringLiteral("Arial")));

    if (app.arguments().contains(QStringLiteral("--smoke-test"))) {
        return 0;
    }

    MainWindow window;
    window.show();
    return app.exec();
}
