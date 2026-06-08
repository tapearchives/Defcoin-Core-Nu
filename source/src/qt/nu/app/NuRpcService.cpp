#include "NuRpcService.h"
#include "NuVelopackUpdater.h"

#include <QApplication>
#include <QAbstractSocket>
#include <QClipboard>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDate>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QDnsLookup>
#include <QEventLoop>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QFontMetrics>
#include <QHostInfo>
#include <QHostAddress>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QLockFile>
#include <QNetworkAccessManager>
#include <QNetworkDatagram>
#include <QNetworkInterface>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPainter>
#include <QPair>
#include <QPointer>
#include <QProcess>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSettings>
#include <QSet>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimeZone>
#include <QTimer>
#include <QThread>
#include <QUrlQuery>
#include <QUdpSocket>
#include <QVector>
#include <QSysInfo>
#include <QVersionNumber>
#include <QUuid>

#include <qrencode.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cctype>
#include <cstring>
#include <functional>
#include <limits>
#include <map>
#include <memory>
#include <set>
#include <utility>
#if defined(Q_OS_MACOS)
#include "MacHelp.h"
#include <mach/mach.h>
#include <sys/sysctl.h>
#elif defined(Q_OS_WIN)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

#ifndef DEFCOIN_NU_EXPLORE_APP
#define DEFCOIN_NU_EXPLORE_APP 0
#endif

#if !defined(Q_OS_WIN)
#include <pwd.h>
#include <sys/resource.h>
#include <unistd.h>
#endif

namespace {
constexpr int QR_IMAGE_SIZE = 512;
constexpr int TRAFFIC_CHART_BUCKET_SECONDS = 60;
constexpr int TRAFFIC_CHART_HISTORY_DAYS = 7;
constexpr int TRAFFIC_CHART_MAX_SECONDS = TRAFFIC_CHART_HISTORY_DAYS * 24 * 60 * 60;
constexpr int TRAFFIC_CHART_MAX_SAMPLES = TRAFFIC_CHART_MAX_SECONDS / TRAFFIC_CHART_BUCKET_SECONDS;
constexpr qint64 TRAFFIC_CHART_BUCKET_MS = TRAFFIC_CHART_BUCKET_SECONDS * 1000;
constexpr int RECOVERY_GAP_SCAN_BATCH_SIZE = 1024;
constexpr int RECOVERY_GAP_SCAN_HARD_MAX_ADDRESSES = 65536;
constexpr int EXPLORER_INDEX_BATCH_BLOCKS = 96;
constexpr int EXPLORER_INDEX_FOCUSED_BATCH_BLOCKS = 384;
constexpr int EXPLORER_INDEX_BUSY_COOPERATIVE_DELAY_MS = 150;
constexpr int EXPLORER_INDEX_FOCUSED_DELAY_MS = 0;
constexpr int EXPLORER_TOP100_CHUNK_BLOCKS = 2500;
constexpr int EXPLORER_TOP100_FOCUSED_CHUNK_BLOCKS = 25000;
constexpr int EXPLORER_TOP100_MAX_ANCHOR_BLOCKS = 10000;
constexpr int EXPLORER_TOP100_MIN_PLAYBACK_CHECKPOINTS = 250;
constexpr int EXPLORER_TOP100_LARGE_PLAYBACK_CHECKPOINTS = 500;
constexpr int EXPLORER_TOP100_EVENT_WRITE_BATCH_ROWS = 5000;
constexpr qint64 EXPLORER_TOP100_UI_REFRESH_MS = 5000;
constexpr int DROIDTRAILS_CACHE_SCHEMA_VERSION = 5;
constexpr int DEFCOIN_REDDIT_TIMELINE_SCHEMA_VERSION = 1;
constexpr quint16 LAN_FAST_SYNC_PORT = 10334;
constexpr int LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES = 1232;
constexpr int LAN_FAST_SYNC_INTERNET_PROBE_DATAGRAM_BYTES = 1472;
constexpr int LAN_FAST_SYNC_MAX_DATAGRAM_BYTES = 16640;
constexpr int LAN_FAST_SYNC_MAX_HEADER_BYTES = 768;
constexpr int LAN_FAST_SYNC_MAX_CHUNK_BYTES = LAN_FAST_SYNC_MAX_DATAGRAM_BYTES - 448;
constexpr int LAN_FAST_SYNC_MIN_CHUNK_BYTES = 128;
constexpr int LAN_FAST_SYNC_MAX_CHUNKS_PER_BLOCK = 65536;
constexpr int LAN_FAST_SYNC_MAX_DATAGRAMS_PER_READ = 96;
constexpr int LAN_FAST_SYNC_REQUEST_TIMEOUT_MS = 3000;
constexpr int LAN_FAST_SYNC_MAX_RETRIES_PER_BLOCK = 3;
constexpr int LAN_FAST_SYNC_MAX_BLOCK_BYTES = 8 * 1024 * 1024;
constexpr int LAN_FAST_SYNC_MAX_INFLIGHT_BLOCKS = 4;
constexpr int LAN_FAST_SYNC_MAX_READY_BLOCKS = 16;
constexpr qint64 LAN_FAST_SYNC_MAX_BUFFER_BYTES = 64LL * 1024LL * 1024LL;
constexpr int LAN_FAST_SYNC_PROBE_TIMEOUT_MS = 2500;
constexpr int LAN_FAST_SYNC_PUBLIC_PROBE_MIN_INTERVAL_MS = 30000;
constexpr int LAN_FAST_SYNC_PUBLIC_PROBE_COOLDOWN_MS = 180000;
constexpr int LAN_FAST_SYNC_PUBLIC_PROBE_FAILURES_BEFORE_COOLDOWN = 2;
constexpr int LAN_FAST_SYNC_DIAGNOSTIC_LOG_THROTTLE_MS = 30000;
constexpr int LAN_DISCOVERY_ANNOUNCE_INTERVAL_MS = 10000;
constexpr int LAN_DISCOVERY_ANNOUNCE_MAX_BYTES = 1536;
constexpr quint16 DEFCOIN_DEFAULT_P2P_PORT = 1337;
constexpr int SENSITIVE_CLIPBOARD_MAX_CHARS = 4096;
constexpr int LAN_FAST_SYNC_MIN_REQUEST_INTERVAL_MS = 50;
constexpr int LAN_FAST_SYNC_TIMER_INTERVAL_MS = 500;
constexpr int QUICK_CLONE_RESERVATION_BACKOFF_MS = 30000;
constexpr int BACKEND_GRACEFUL_SHUTDOWN_MS = 60000;
constexpr int FAST_SYNC_PROTOCOL_MAX_WINDOW = 32;
constexpr int FAST_SYNC_PROTOCOL_PROBE_INTERVAL_MS = 30000;
constexpr int FAST_SYNC_PROTOCOL_MIN_UDP_PROBES = 4;
constexpr int FAST_SYNC_PROTOCOL_TCP_SAMPLE_CAP_PER_UDP = 3;
constexpr int FAST_SYNC_PROTOCOL_UDP_KEEPALIVE_MS = 5000;
constexpr double FAST_SYNC_PROTOCOL_EWMA_ALPHA = 0.35;
constexpr double FAST_SYNC_PROTOCOL_EXPLORATION_C = 0.35;
constexpr int AUTO_DBCACHE_MIN_MIB = 450;
constexpr int AUTO_DBCACHE_64BIT_MAX_MIB = 32768;
constexpr int AUTO_DBCACHE_32BIT_MAX_MIB = 1024;
constexpr char UDP_FAST_SYNC_CAPABILITY[] = "defcoin-nu-udp-fast-sync-v1";
constexpr unsigned char DEFCOIN_CURRENT_WIF_PREFIX = 0xb0; // Defcoin v1.0.0+ private keys render as T...
constexpr unsigned char DEFCOIN_LEGACY_WIF_PREFIX = 0x9e;  // Defcoin v0.22/Ian Coleman legacy entry renders as Q...
constexpr char BASE58_ALPHABET[] = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const QStringList EXPLORER_TOP100_COLORS = {
    QStringLiteral("#48b7ff"), QStringLiteral("#f3d447"), QStringLiteral("#46d39a"),
    QStringLiteral("#f05d4f"), QStringLiteral("#b779ff"), QStringLiteral("#ff9f43"),
    QStringLiteral("#5fe1e8"), QStringLiteral("#f78fb3"), QStringLiteral("#9bc53d"),
    QStringLiteral("#c8d6e5"), QStringLiteral("#7f8fa6"), QStringLiteral("#00a8ff"),
    QStringLiteral("#e84118"), QStringLiteral("#4cd137"), QStringLiteral("#8c7ae6")
};

QByteArray doubleSha256(const QByteArray& bytes)
{
    return QCryptographicHash::hash(QCryptographicHash::hash(bytes, QCryptographicHash::Sha256), QCryptographicHash::Sha256);
}

QString lanFastSyncChecksum(const QByteArray& bytes)
{
    return QString::fromLatin1(QCryptographicHash::hash(bytes, QCryptographicHash::Sha256).toHex());
}

bool peerServicesAdvertiseFastSync(const QString& services_hex)
{
    bool ok = false;
    const qulonglong services = services_hex.trimmed().toULongLong(&ok, 16);
    return ok && (services & (1ULL << 29));
}

bool isLowerRiskHexText(const QString& value, int max_chars)
{
    if (value.isEmpty() || value.size() > max_chars || value.size() % 2 != 0) return false;
    static const QRegularExpression hex_re(QStringLiteral(R"(^[0-9A-Fa-f]+$)"));
    return hex_re.match(value).hasMatch();
}

QVector<int> lanFastSyncDatagramCandidates(bool lan_mode)
{
    return lan_mode
        ? QVector<int>{LAN_FAST_SYNC_INTERNET_PROBE_DATAGRAM_BYTES, 4096, 8192, 12000, 16000}
        : QVector<int>{LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES, LAN_FAST_SYNC_INTERNET_PROBE_DATAGRAM_BYTES};
}

int lanFastSyncChunkBytesForDatagram(int max_datagram)
{
    return qBound(LAN_FAST_SYNC_MIN_CHUNK_BYTES, max_datagram - 448, LAN_FAST_SYNC_MAX_CHUNK_BYTES);
}

QString explorerTop100Color(int rank)
{
    if (rank <= 0) return EXPLORER_TOP100_COLORS.last();
    return EXPLORER_TOP100_COLORS.at((rank - 1) % EXPLORER_TOP100_COLORS.size());
}

bool launchExploreLookup(const QString& option, const QString& value)
{
#if DEFCOIN_NU_EXPLORE_APP
    Q_UNUSED(option);
    Q_UNUSED(value);
    return false;
#else
    if (option.trimmed().isEmpty() || value.trimmed().isEmpty()) return false;
    const QStringList lookup_args{option, value.trimmed()};
#if defined(Q_OS_MACOS)
    QStringList open_args;
    open_args << QStringLiteral("-b")
              << QStringLiteral("org.defcoincore.DefcoinCoreNuExplore")
              << QStringLiteral("--args")
              << lookup_args;
    if (QProcess::startDetached(QStringLiteral("/usr/bin/open"), open_args)) return true;
    open_args.clear();
    open_args << QStringLiteral("-b")
              << QStringLiteral("org.defcoincore.DefcoinCoreExplore")
              << QStringLiteral("--args")
              << lookup_args;
    if (QProcess::startDetached(QStringLiteral("/usr/bin/open"), open_args)) return true;
#endif
    const QDir app_dir(QCoreApplication::applicationDirPath());
#if defined(Q_OS_WIN)
    const QString candidate = app_dir.filePath(QStringLiteral("DefcoinCoreExplore.exe"));
#else
    const QString candidate = app_dir.filePath(QStringLiteral("DefcoinCoreExplore"));
#endif
    const QFileInfo candidate_info(candidate);
    if (candidate_info.exists() && candidate_info.isExecutable())
        return QProcess::startDetached(candidate, lookup_args);
    return false;
#endif
}

QString normalizedFastSyncHost(const QHostAddress& address)
{
    bool ipv4_ok = false;
    const quint32 ipv4 = address.toIPv4Address(&ipv4_ok);
    if (ipv4_ok) return QHostAddress(ipv4).toString().toLower();
    QString host = address.toString().toLower();
    const int scope = host.indexOf(QLatin1Char('%'));
    if (scope >= 0) host.truncate(scope);
    return host;
}

bool isInvalidLanDiscoveryAddress(const QHostAddress& address)
{
    if (address.isNull() || address.isLoopback()) return true;
    bool ipv4_ok = false;
    const quint32 ipv4 = address.toIPv4Address(&ipv4_ok);
    if (ipv4_ok) {
        const quint32 ip = ipv4;
        const quint8 a = static_cast<quint8>((ip >> 24) & 0xff);
        const quint8 d = static_cast<quint8>(ip & 0xff);
        return ip == 0xffffffffu || a == 0 || a >= 224 || d == 0 || d == 255;
    }
    if (address.protocol() == QAbstractSocket::IPv6Protocol) {
        const Q_IPV6ADDR bytes = address.toIPv6Address();
        return bytes[0] == 0xff;
    }
    return true;
}

bool isPrivateOrLocalFastSyncAddress(const QHostAddress& address)
{
    if (address.isNull()) return false;
    if (address.isLoopback()) return false;
    if (isInvalidLanDiscoveryAddress(address)) return false;
    bool ipv4_ok = false;
    const quint32 ipv4 = address.toIPv4Address(&ipv4_ok);
    if (ipv4_ok) {
        const quint32 ip = ipv4;
        return ((ip & 0xff000000u) == 0x0a000000u)      // 10.0.0.0/8
            || ((ip & 0xfff00000u) == 0xac100000u)      // 172.16.0.0/12
            || ((ip & 0xffff0000u) == 0xc0a80000u)      // 192.168.0.0/16
            || ((ip & 0xffff0000u) == 0xa9fe0000u);     // 169.254.0.0/16
    }
    if (address.protocol() == QAbstractSocket::IPv6Protocol) {
        const Q_IPV6ADDR bytes = address.toIPv6Address();
        return bytes[0] == 0xfc || bytes[0] == 0xfd || (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80);
    }
    return false;
}

bool trySetProcessNiceForIndexing(bool focused)
{
#if defined(Q_OS_WIN)
    Q_UNUSED(focused);
    return false;
#else
    const int nice_value = focused ? -5 : 0;
    return setpriority(PRIO_PROCESS, 0, nice_value) == 0;
#endif
}

bool systemLooksBusyForCooperativeIndexing()
{
#if defined(Q_OS_WIN)
    return false;
#else
    double loadavg[1] = {0.0};
    if (getloadavg(loadavg, 1) != 1) return false;
    const int cores = std::max(1, QThread::idealThreadCount());
    return loadavg[0] >= std::max(1.0, static_cast<double>(cores) * 0.70);
#endif
}

int explorerIndexNextDelayMs(bool focused)
{
    if (focused) return EXPLORER_INDEX_FOCUSED_DELAY_MS;
    return systemLooksBusyForCooperativeIndexing() ? EXPLORER_INDEX_BUSY_COOPERATIVE_DELAY_MS : 0;
}

qint64 availableMemoryMiB()
{
#if defined(Q_OS_MACOS)
    vm_size_t page_size = 0;
    if (host_page_size(mach_host_self(), &page_size) != KERN_SUCCESS || page_size == 0) return 0;
    vm_statistics64_data_t stats{};
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, reinterpret_cast<host_info64_t>(&stats), &count) != KERN_SUCCESS) return 0;
    const quint64 pages = static_cast<quint64>(stats.free_count)
        + static_cast<quint64>(stats.inactive_count)
#if defined(VM_PAGE_SPECULATIVE_COUNT)
        + static_cast<quint64>(stats.speculative_count)
#endif
        ;
    return static_cast<qint64>((pages * static_cast<quint64>(page_size)) / (1024ULL * 1024ULL));
#elif defined(Q_OS_WIN)
    MEMORYSTATUSEX status{};
    status.dwLength = sizeof(status);
    if (!GlobalMemoryStatusEx(&status)) return 0;
    return static_cast<qint64>(status.ullAvailPhys / (1024ULL * 1024ULL));
#elif defined(Q_OS_LINUX)
    QFile meminfo(QStringLiteral("/proc/meminfo"));
    if (!meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) return 0;
    while (!meminfo.atEnd()) {
        const QString line = QString::fromLatin1(meminfo.readLine()).trimmed();
        if (!line.startsWith(QStringLiteral("MemAvailable:"))) continue;
        const QStringList parts = line.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
        if (parts.size() < 2) return 0;
        bool ok = false;
        const qint64 kib = parts.at(1).toLongLong(&ok);
        return ok ? kib / 1024 : 0;
    }
    return 0;
#else
    return 0;
#endif
}

bool defcoinConfHasDbCache(const QString& data_dir)
{
    QFile conf(QDir(data_dir).filePath(QStringLiteral("defcoin.conf")));
    if (!conf.open(QIODevice::ReadOnly | QIODevice::Text)) return false;
    const QRegularExpression dbcache_line(QStringLiteral("^\\s*(?:defcoin\\.)?dbcache\\s*="), QRegularExpression::CaseInsensitiveOption);
    while (!conf.atEnd()) {
        QString line = QString::fromUtf8(conf.readLine());
        const int hash_index = line.indexOf(QLatin1Char('#'));
        if (hash_index >= 0) line.truncate(hash_index);
        const int semicolon_index = line.indexOf(QLatin1Char(';'));
        if (semicolon_index >= 0) line.truncate(semicolon_index);
        if (dbcache_line.match(line).hasMatch()) return true;
    }
    return false;
}

int autoDbCacheMiB(qint64 available_mib)
{
    if (available_mib <= 0) return 0;
    const int max_cache = sizeof(void*) > 4 ? AUTO_DBCACHE_64BIT_MAX_MIB : AUTO_DBCACHE_32BIT_MAX_MIB;
    if (available_mib < 2048) return 0;

    // Keep enough RAM for the GUI, OS file cache, peers, wallet rescans, and other apps.
    const qint64 reserved_mib = std::max<qint64>(2048, available_mib / 4);
    const qint64 usable_mib = available_mib > reserved_mib ? available_mib - reserved_mib : 0;
    if (usable_mib < AUTO_DBCACHE_MIN_MIB) return 0;

    // A bigger dbcache helps most during IBD, but swapping is worse than disk reads.
    const qint64 target_mib = std::min<qint64>(usable_mib, available_mib * 3 / 5);
    return qBound(AUTO_DBCACHE_MIN_MIB, static_cast<int>(target_mib), max_cache);
}

QString autoDbCacheLaunchArg(const QString& data_dir, QString* note)
{
    if (note) note->clear();
    const QByteArray env = qgetenv("DEFCOIN_NU_DBCACHE_MB");
    if (!env.isEmpty()) {
        bool ok = false;
        const int requested = QString::fromLatin1(env).trimmed().toInt(&ok);
        const int max_cache = sizeof(void*) > 4 ? AUTO_DBCACHE_64BIT_MAX_MIB : AUTO_DBCACHE_32BIT_MAX_MIB;
        if (ok && requested >= AUTO_DBCACHE_MIN_MIB) {
            const int cache_mib = qBound(AUTO_DBCACHE_MIN_MIB, requested, max_cache);
            if (note) *note = QStringLiteral("Database cache selected from DEFCOIN_NU_DBCACHE_MB: %1 MiB.").arg(cache_mib);
            return QStringLiteral("-dbcache=%1").arg(cache_mib);
        }
        if (note) *note = QStringLiteral("Ignored invalid DEFCOIN_NU_DBCACHE_MB value '%1'.").arg(QString::fromLatin1(env).left(64));
    }

    if (defcoinConfHasDbCache(data_dir)) {
        if (note) *note = QStringLiteral("Database cache is set in defcoin.conf; Nu will not override it.");
        return QString();
    }

    const qint64 available_mib = availableMemoryMiB();
    const int cache_mib = autoDbCacheMiB(available_mib);
    if (cache_mib <= 0) {
        if (note) *note = available_mib > 0
            ? QStringLiteral("Available RAM is %1 MiB; using Core's default database cache.").arg(available_mib)
            : QStringLiteral("Available RAM could not be measured; using Core's default database cache.");
        return QString();
    }
    if (note) *note = QStringLiteral("Auto database cache: %1 MiB selected from %2 MiB available RAM.").arg(cache_mib).arg(available_mib);
    return QStringLiteral("-dbcache=%1").arg(cache_mib);
}

QByteArray lanFastSyncDatagram(const QJsonObject& header,
                               const QByteArray& payload = QByteArray(),
                               int max_datagram = LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES)
{
    max_datagram = qBound(576, max_datagram, LAN_FAST_SYNC_MAX_DATAGRAM_BYTES);
    if (payload.size() > LAN_FAST_SYNC_MAX_CHUNK_BYTES) return QByteArray();
    QJsonObject copy = header;
    copy.insert(QStringLiteral("payload_size"), payload.size());
    const QByteArray json = QJsonDocument(copy).toJson(QJsonDocument::Compact);
    if (json.isEmpty() || json.size() > LAN_FAST_SYNC_MAX_HEADER_BYTES) return QByteArray();
    QByteArray datagram;
    const int datagram_size = 10 + json.size() + payload.size();
    if (datagram_size > max_datagram) return QByteArray();
    datagram.reserve(datagram_size);
    datagram.append("DFCLAN1\n", 8);
    datagram.append(json);
    datagram.append("\n\n", 2);
    datagram.append(payload);
    return datagram;
}

bool parseLanFastSyncDatagram(const QByteArray& datagram, QJsonObject* header, QByteArray* payload)
{
    static const QByteArray prefix("DFCLAN1\n");
    if (!header || !payload || !datagram.startsWith(prefix)) return false;
    if (datagram.size() < prefix.size() + 2 || datagram.size() > LAN_FAST_SYNC_MAX_DATAGRAM_BYTES) return false;
    const int split = datagram.indexOf("\n\n", prefix.size());
    if (split < 0) return false;
    const int header_size = split - prefix.size();
    if (header_size <= 0 || header_size > LAN_FAST_SYNC_MAX_HEADER_BYTES) return false;
    QJsonParseError parse_error;
    const QJsonDocument doc = QJsonDocument::fromJson(datagram.mid(prefix.size(), header_size), &parse_error);
    if (parse_error.error != QJsonParseError::NoError) return false;
    if (!doc.isObject()) return false;
    *header = doc.object();
    const QJsonValue payload_size_value = header->value(QStringLiteral("payload_size"));
    if (!payload_size_value.isDouble()) return false;
    const int payload_size = payload_size_value.toInt(-1);
    if (payload_size < 0 || payload_size > LAN_FAST_SYNC_MAX_CHUNK_BYTES) return false;
    *payload = datagram.mid(split + 2);
    return payload_size == payload->size();
}

bool decodeBase58CheckPayload(const QString& text, QByteArray* payload)
{
    if (!payload) return false;
    const QByteArray input = text.trimmed().toLatin1();
    if (input.isEmpty()) return false;
    for (char c : input) {
        if (std::isspace(static_cast<unsigned char>(c))) return false;
        if (!std::strchr(BASE58_ALPHABET, c)) return false;
    }

    int zeroes = 0;
    while (zeroes < input.size() && input.at(zeroes) == '1') ++zeroes;
    QVector<unsigned char> base256((input.size() - zeroes) * 733 / 1000 + 1);
    int length = 0;
    for (int i = zeroes; i < input.size(); ++i) {
        const char* found = std::strchr(BASE58_ALPHABET, input.at(i));
        if (!found) return false;
        int carry = static_cast<int>(found - BASE58_ALPHABET);
        int j = 0;
        for (auto it = base256.rbegin(); (carry != 0 || j < length) && it != base256.rend(); ++it, ++j) {
            carry += 58 * (*it);
            *it = static_cast<unsigned char>(carry % 256);
            carry /= 256;
        }
        if (carry != 0) return false;
        length = j;
    }

    auto it = base256.begin() + (base256.size() - length);
    while (it != base256.end() && *it == 0) ++it;
    QByteArray decoded;
    decoded.append(zeroes, '\0');
    while (it != base256.end()) {
        decoded.append(static_cast<char>(*it));
        ++it;
    }
    if (decoded.size() < 4) return false;
    const QByteArray body = decoded.left(decoded.size() - 4);
    const QByteArray checksum = decoded.right(4);
    if (doubleSha256(body).left(4) != checksum) return false;
    *payload = body;
    return true;
}

QString encodeBase58CheckPayload(const QByteArray& payload)
{
    QByteArray input = payload;
    input.append(doubleSha256(payload).left(4));
    int zeroes = 0;
    while (zeroes < input.size() && input.at(zeroes) == '\0') ++zeroes;

    QVector<unsigned char> base58((input.size() - zeroes) * 138 / 100 + 1);
    int length = 0;
    for (int i = zeroes; i < input.size(); ++i) {
        int carry = static_cast<unsigned char>(input.at(i));
        int j = 0;
        for (auto it = base58.rbegin(); (carry != 0 || j < length) && it != base58.rend(); ++it, ++j) {
            carry += 256 * (*it);
            *it = static_cast<unsigned char>(carry % 58);
            carry /= 58;
        }
        length = j;
    }

    auto it = base58.begin() + (base58.size() - length);
    while (it != base58.end() && *it == 0) ++it;
    QString result;
    result.reserve(zeroes + static_cast<int>(std::distance(it, base58.end())));
    for (int i = 0; i < zeroes; ++i) result.append(QLatin1Char('1'));
    while (it != base58.end()) {
        result.append(QLatin1Char(BASE58_ALPHABET[*it]));
        ++it;
    }
    return result;
}

QByteArray bytes(std::initializer_list<unsigned char> values)
{
    QByteArray out;
    out.reserve(static_cast<int>(values.size()));
    for (unsigned char value : values) out.append(static_cast<char>(value));
    return out;
}

bool hasPrefix(const QByteArray& payload, const QByteArray& prefix)
{
    return payload.size() >= prefix.size() && payload.left(prefix.size()) == prefix;
}

bool isValidBip39WordCount(int word_count)
{
    return word_count == 12 || word_count == 15 || word_count == 18 || word_count == 21 || word_count == 24;
}

int bip39EntropyBitsForWordCount(int word_count)
{
    if (!isValidBip39WordCount(word_count)) return 0;
    return word_count * 11 * 32 / 33;
}

unsigned char recoveryWifPrefix(const QString& mode)
{
    return mode.compare(QStringLiteral("legacy"), Qt::CaseInsensitive) == 0 ? DEFCOIN_LEGACY_WIF_PREFIX : DEFCOIN_CURRENT_WIF_PREFIX;
}

QString recoveryWifLabel(const QString& mode)
{
    return mode.compare(QStringLiteral("legacy"), Qt::CaseInsensitive) == 0
        ? QStringLiteral("Legacy Defcoin v0.22 / Ian Coleman reference, Q... WIF prefix 0x9e")
        : QStringLiteral("Current Defcoin v1.0.0+ wallet-compatible, T... WIF prefix 0xb0");
}

QVariantList row(std::initializer_list<QVariant> values)
{
    QVariantList out;
    for (const QVariant& value : values) out.push_back(value);
    return out;
}

QVariantMap tableRow(std::initializer_list<QVariant> cells, const QVariantMap& meta)
{
    QVariantMap out;
    out.insert(QStringLiteral("cells"), row(cells));
    out.insert(QStringLiteral("meta"), meta);
    return out;
}

QVariantMap metricRow(const QString& metric, const QString& value, const QString& tooltip)
{
    QVariantList tips;
    tips << tooltip << tooltip;
    return tableRow({metric, value}, QVariantMap{{QStringLiteral("cellTooltips"), tips}});
}

QString formatDiagnosticBytes(qint64 bytes)
{
    static const char* units[] = {"B", "KB", "MB", "GB"};
    double value = static_cast<double>(bytes);
    int unit_index = 0;
    while (value >= 1024.0 && unit_index < 3) {
        value /= 1024.0;
        ++unit_index;
    }
    if (unit_index == 0) return QStringLiteral("%1 B").arg(bytes);
    return QStringLiteral("%1 %2").arg(value, 0, 'f', value >= 100.0 ? 0 : 1).arg(QLatin1String(units[unit_index]));
}

QString shallowDirectorySummary(const QString& path)
{
    const QFileInfo info(path);
    if (!info.exists()) return QFileInfo(path).fileName() + QStringLiteral(" missing");
    if (!info.isDir()) return QFileInfo(path).fileName() + QStringLiteral(" not a directory");

    const QFileInfoList entries = QDir(path).entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    qint64 immediate_bytes = 0;
    int file_count = 0;
    int dir_count = 0;
    for (const QFileInfo& entry : entries) {
        if (entry.isDir()) {
            ++dir_count;
        } else {
            ++file_count;
            immediate_bytes += entry.size();
        }
    }

    QStringList parts;
    parts << QFileInfo(path).fileName();
    parts << QStringLiteral("%1 files").arg(file_count);
    if (dir_count > 0) parts << QStringLiteral("%1 dirs").arg(dir_count);
    parts << formatDiagnosticBytes(immediate_bytes);
    return parts.join(QStringLiteral(" / "));
}

QString chainStorageDiagnosticLine(const QString& data_dir)
{
    const QDir dir(data_dir);
    return QStringLiteral("Public chain storage before backend launch: %1; %2; %3; %4.")
        .arg(shallowDirectorySummary(dir.filePath(QStringLiteral("blocks"))),
             shallowDirectorySummary(dir.filePath(QStringLiteral("blocks/index"))),
             shallowDirectorySummary(dir.filePath(QStringLiteral("chainstate"))),
             shallowDirectorySummary(dir.filePath(QStringLiteral("indexes"))));
}

QVariantList tableRowCells(const QVariant& value)
{
    const QVariantMap map = value.toMap();
    if (map.contains(QStringLiteral("cells"))) {
        return map.value(QStringLiteral("cells")).toList();
    }
    return value.toList();
}

bool isValidWalletMenuName(const QString& name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty() || trimmed.size() > 128) return false;
    if (trimmed == QLatin1String(".") || trimmed == QLatin1String("..")) return false;
    if (trimmed.contains(QLatin1Char('/')) || trimmed.contains(QLatin1Char('\\')) || trimmed.contains(QLatin1Char(':'))) return false;
    for (const QChar ch : trimmed) {
        if (ch.unicode() < 0x20 || ch.unicode() == 0x7f) return false;
    }
    return true;
}

bool isLikelyLoadableWalletMenuName(const QString& name)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) return true; // Core's legacy top-level wallet.dat is named "" over RPC.

    QString leaf = trimmed;
    const QString path = trimmed;
    const QString normalized_path = path;
    const QString slash_path = QString(normalized_path).replace(QLatin1Char('\\'), QLatin1Char('/'));
    if (slash_path.startsWith(QStringLiteral("wallets/"))) {
        leaf = slash_path.mid(QStringLiteral("wallets/").size());
        if (leaf.contains(QLatin1Char('/'))) return false;
    }

    if (!isValidWalletMenuName(leaf)) return false;

    const QString lower = trimmed.toLower();
    if (lower.endsWith(QStringLiteral(".bak")) || lower.endsWith(QStringLiteral(".bkp"))) return false;
    if (lower.endsWith(QStringLiteral(".dat")) && lower != QLatin1String("wallet.dat")) return false;
    if (lower.contains(QStringLiteral("backup")) || lower.contains(QStringLiteral(" bkp")) || lower.contains(QStringLiteral(" copy "))) return false;
    return true;
}

bool isLikelyCreatableWalletMenuName(const QString& name)
{
    return isValidWalletMenuName(name) && isLikelyLoadableWalletMenuName(name);
}

QString normalizedWalletListName(const QString& name)
{
    const QString trimmed = name.trimmed();
    return trimmed == QLatin1String("wallet.dat") ? QString() : trimmed;
}

QString walletAmountText(double amount, bool with_unit = false)
{
    QString text = QString::number(amount, 'f', 8);
    return with_unit ? text + QStringLiteral(" DFC") : text;
}

qint64 explorerAmountSats(const QJsonValue& value)
{
    return static_cast<qint64>(std::llround(value.toDouble() * 100000000.0));
}

QString explorerAmountText(qint64 sats, bool with_unit = true)
{
    const bool negative = sats < 0;
    quint64 absolute = static_cast<quint64>(negative ? -sats : sats);
    const QString whole = QString::number(absolute / 100000000);
    const QString fractional = QString::number(absolute % 100000000).rightJustified(8, QLatin1Char('0'));
    QString text = (negative ? QStringLiteral("-") : QString()) + whole + QLatin1Char('.') + fractional;
    return with_unit ? text + QStringLiteral(" DFC") : text;
}

QString roundedExplorerAmountText(qint64 sats, int decimals = 2)
{
    const double coins = static_cast<double>(sats) / 100000000.0;
    return QString::number(coins, 'f', std::max(0, decimals)) + QStringLiteral(" DFC");
}

QString explorerDateRangeText(qint64 start_time, qint64 end_time)
{
    if (start_time <= 0 || end_time <= 0) return QStringLiteral("date unavailable");
    const QTimeZone utc = QTimeZone::utc();
    const QDate start_date = QDateTime::fromSecsSinceEpoch(start_time, utc).date();
    const QDate end_date = QDateTime::fromSecsSinceEpoch(end_time, utc).date();
    if (start_date == end_date) return start_date.toString(QStringLiteral("yyyy-MM-dd"));
    return start_date.toString(QStringLiteral("yyyy-MM-dd")) + QStringLiteral(" - ") +
           end_date.toString(QStringLiteral("yyyy-MM-dd"));
}

QStringList explorerOutputAddresses(const QJsonObject& script)
{
    QStringList out;
    const QJsonArray addresses = script.value(QStringLiteral("addresses")).toArray();
    for (const QJsonValue& value : addresses) {
        const QString address = value.toString().trimmed();
        if (!address.isEmpty() && !out.contains(address)) out.push_back(address);
    }
    const QString address = script.value(QStringLiteral("address")).toString().trimmed();
    if (!address.isEmpty() && !out.contains(address)) out.push_back(address);
    return out;
}

QByteArray explorerOpReturnPayloadBytes(const QString& script_hex)
{
    const QByteArray script_bytes = QByteArray::fromHex(script_hex.trimmed().toLatin1());
    if (script_bytes.isEmpty() || static_cast<unsigned char>(script_bytes.at(0)) != 0x6a) return {};

    QByteArray payload;
    int pos = 1;
    while (pos < script_bytes.size()) {
        const unsigned char opcode = static_cast<unsigned char>(script_bytes.at(pos++));
        quint32 length = 0;
        if (opcode <= 75) {
            length = opcode;
        } else if (opcode == 0x4c && pos < script_bytes.size()) {
            length = static_cast<unsigned char>(script_bytes.at(pos++));
        } else if (opcode == 0x4d && pos + 1 < script_bytes.size()) {
            length = static_cast<unsigned char>(script_bytes.at(pos)) |
                     (static_cast<unsigned char>(script_bytes.at(pos + 1)) << 8);
            pos += 2;
        } else if (opcode == 0x4e && pos + 3 < script_bytes.size()) {
            length = static_cast<unsigned char>(script_bytes.at(pos)) |
                     (static_cast<unsigned char>(script_bytes.at(pos + 1)) << 8) |
                     (static_cast<unsigned char>(script_bytes.at(pos + 2)) << 16) |
                     (static_cast<unsigned char>(script_bytes.at(pos + 3)) << 24);
            pos += 4;
        } else {
            continue;
        }
        if (length == 0) continue;
        if (pos + static_cast<int>(length) > script_bytes.size()) break;
        payload.append(script_bytes.mid(pos, static_cast<int>(length)));
        pos += static_cast<int>(length);
    }
    return payload;
}

QString explorerPrintablePayloadText(const QByteArray& payload)
{
    if (payload.isEmpty()) return QStringLiteral("");
    int printable = 0;
    for (char byte : payload) {
        const unsigned char value = static_cast<unsigned char>(byte);
        if (value == 9 || value == 10 || value == 13 || (value >= 32 && value <= 126)) ++printable;
    }
    const int minimum_printable = std::max(1, static_cast<int>(payload.size()) * 3 / 4);
    if (printable < minimum_printable) return QStringLiteral("");
    QString text = QString::fromUtf8(payload).trimmed();
    text.replace(QRegularExpression(QStringLiteral("[\\x00-\\x08\\x0b\\x0c\\x0e-\\x1f]")), QStringLiteral(" "));
    text = text.simplified();
    return text.size() > 512 ? text.left(512) : text;
}

bool isLikelyBase58AddressText(const QString& value);

QStringList recognizedExplorerAddresses(const QStringList& candidates)
{
    QStringList out;
    for (const QString& candidate : candidates) {
        QString address = candidate.trimmed();
        if (address.startsWith(QStringLiteral("defcoin:"), Qt::CaseInsensitive)) {
            address = address.mid(QStringLiteral("defcoin:").size());
        }
        const int query_index = address.indexOf(QLatin1Char('?'));
        if (query_index >= 0) address = address.left(query_index);
        address.remove(QRegularExpression(QStringLiteral(R"(^[<\[\("']+|[>\]\),"';:.]+$)")));
        if (isLikelyBase58AddressText(address) && !out.contains(address)) out.push_back(address);
    }
    return out;
}

QString explorerAddressLinkHtml(const QString& address)
{
    const QString clean = address.trimmed();
    if (!isLikelyBase58AddressText(clean)) return clean.toHtmlEscaped();
    return QStringLiteral("<a href=\"nu://address/%1\">%2</a>")
        .arg(QString::fromLatin1(QUrl::toPercentEncoding(clean)).toHtmlEscaped(),
             clean.toHtmlEscaped());
}

QString explorerAddressLinksHtml(const QStringList& addresses)
{
    const QStringList clean_addresses = recognizedExplorerAddresses(addresses);
    QStringList links;
    links.reserve(clean_addresses.size());
    for (const QString& address : clean_addresses) links.push_back(explorerAddressLinkHtml(address));
    return links.join(QStringLiteral("<br>"));
}

bool walletDefaultDatExists(const QString& data_dir)
{
    const QDir dir(data_dir);
    return QFileInfo::exists(dir.filePath(QStringLiteral("wallet.dat"))) ||
           QFileInfo::exists(dir.filePath(QStringLiteral("wallets/wallet.dat")));
}

QString walletStorageTypeFromFormat(const QString& format)
{
    const QString lower = format.trimmed().toLower();
    if (lower == QLatin1String("sqlite")) return QStringLiteral("SQL");
    if (lower == QLatin1String("bdb")) return QStringLiteral("BDB");
    return QStringLiteral("Unknown");
}

QString walletStorageTypeFromFile(const QString& path)
{
    QFile file(path);
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) return QStringLiteral("Unknown");

    const QByteArray header = file.read(72);
    if (header.size() >= 16 && header.left(16) == QByteArray("SQLite format 3", 16)) {
        return QStringLiteral("SQL");
    }

    if (header.size() >= 16) {
        const auto b12 = static_cast<unsigned char>(header.at(12));
        const auto b13 = static_cast<unsigned char>(header.at(13));
        const auto b14 = static_cast<unsigned char>(header.at(14));
        const auto b15 = static_cast<unsigned char>(header.at(15));
        const bool bdb_big_endian = b12 == 0x00 && b13 == 0x05 && b14 == 0x31 && b15 == 0x62;
        const bool bdb_little_endian = b12 == 0x62 && b13 == 0x31 && b14 == 0x05 && b15 == 0x00;
        if (bdb_big_endian || bdb_little_endian) return QStringLiteral("BDB");
    }

    return QStringLiteral("Unknown");
}

QString walletStorageTypeForName(const QString& data_dir, const QString& wallet_name)
{
    const QDir data(data_dir);
    const QString normalized = normalizedWalletListName(wallet_name);
    if (normalized.isEmpty()) {
        const QString top_level = data.filePath(QStringLiteral("wallet.dat"));
        const QString top_level_type = walletStorageTypeFromFile(top_level);
        if (top_level_type != QLatin1String("Unknown")) return top_level_type;
        return walletStorageTypeFromFile(data.filePath(QStringLiteral("wallets/wallet.dat")));
    }

    const QDir wallets(data.filePath(QStringLiteral("wallets")));
    const QString direct = wallets.filePath(normalized);
    const QFileInfo direct_info(direct);
    if (direct_info.isFile()) {
        return walletStorageTypeFromFile(direct);
    }
    return walletStorageTypeFromFile(QDir(direct).filePath(QStringLiteral("wallet.dat")));
}

QByteArray sha256Bytes(const QByteArray& data)
{
    return QCryptographicHash::hash(data, QCryptographicHash::Sha256);
}

QByteArray hash256Bytes(const QByteArray& data)
{
    return sha256Bytes(sha256Bytes(data));
}

QByteArray hmacSha512(const QByteArray& key, const QByteArray& message)
{
    constexpr int block_size = 128;
    QByteArray normalized_key = key;
    if (normalized_key.size() > block_size) normalized_key = QCryptographicHash::hash(normalized_key, QCryptographicHash::Sha512);
    normalized_key.resize(block_size);

    QByteArray outer(block_size, char(0x5c));
    QByteArray inner(block_size, char(0x36));
    for (int i = 0; i < block_size; ++i) {
        outer[i] = char(outer.at(i) ^ normalized_key.at(i));
        inner[i] = char(inner.at(i) ^ normalized_key.at(i));
    }

    const QByteArray inner_hash = QCryptographicHash::hash(inner + message, QCryptographicHash::Sha512);
    return QCryptographicHash::hash(outer + inner_hash, QCryptographicHash::Sha512);
}

QByteArray pbkdf2HmacSha512(const QByteArray& password, const QByteArray& salt, int iterations, int output_size)
{
    QByteArray output;
    for (int block = 1; output.size() < output_size; ++block) {
        QByteArray block_salt = salt;
        block_salt.append(char((block >> 24) & 0xff));
        block_salt.append(char((block >> 16) & 0xff));
        block_salt.append(char((block >> 8) & 0xff));
        block_salt.append(char(block & 0xff));

        QByteArray u = hmacSha512(password, block_salt);
        QByteArray t = u;
        for (int i = 1; i < iterations; ++i) {
            u = hmacSha512(password, u);
            for (int j = 0; j < t.size(); ++j) t[j] = char(t.at(j) ^ u.at(j));
        }
        output.append(t);
    }
    output.truncate(output_size);
    return output;
}

int compareUnsignedBytes(const QByteArray& left, const QByteArray& right)
{
    const int size = std::min(left.size(), right.size());
    for (int i = 0; i < size; ++i) {
        const int a = static_cast<unsigned char>(left.at(i));
        const int b = static_cast<unsigned char>(right.at(i));
        if (a < b) return -1;
        if (a > b) return 1;
    }
    if (left.size() < right.size()) return -1;
    if (left.size() > right.size()) return 1;
    return 0;
}

bool isValidSecp256k1Secret(const QByteArray& secret)
{
    static const QByteArray order = QByteArray::fromHex("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");
    if (secret.size() != 32) return false;
    bool non_zero = false;
    for (const char byte : secret) {
        if (byte != 0) {
            non_zero = true;
            break;
        }
    }
    return non_zero && compareUnsignedBytes(secret, order) < 0;
}

QString encodeBase58Check(const QByteArray& payload)
{
    static constexpr char alphabet[] = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    const QByteArray data = payload + hash256Bytes(payload).left(4);

    int zeroes = 0;
    while (zeroes < data.size() && data.at(zeroes) == 0) ++zeroes;

    QVector<unsigned char> b58((data.size() - zeroes) * 138 / 100 + 1);
    int length = 0;
    for (int i = zeroes; i < data.size(); ++i) {
        int carry = static_cast<unsigned char>(data.at(i));
        int j = 0;
        for (auto it = b58.rbegin(); (carry != 0 || j < length) && it != b58.rend(); ++it, ++j) {
            carry += 256 * (*it);
            *it = carry % 58;
            carry /= 58;
        }
        length = j;
    }

    QString result;
    result.reserve(zeroes + length);
    for (int i = 0; i < zeroes; ++i) result.append(QLatin1Char('1'));
    auto it = b58.cbegin() + (b58.size() - length);
    while (it != b58.cend()) {
        result.append(QLatin1Char(alphabet[*it]));
        ++it;
    }
    return result;
}

bool bitAt(const QByteArray& bytes, int bit)
{
    return (static_cast<unsigned char>(bytes.at(bit / 8)) >> (7 - (bit % 8))) & 1;
}

QPair<QString, QString> splitPeerAddressAndPort(QString raw)
{
    raw = raw.trimmed();
    if (raw.startsWith(QLatin1Char('[')) && raw.contains(QStringLiteral("]:"))) {
        const int close = raw.lastIndexOf(QStringLiteral("]:"));
        return {raw.mid(1, close - 1), raw.mid(close + 2)};
    }

    if (raw.startsWith(QLatin1Char('[')) && raw.endsWith(QLatin1Char(']'))) {
        return {raw.mid(1, raw.size() - 2), QString()};
    }

    static const QRegularExpression ipv4_with_port(QStringLiteral(R"(^(\d{1,3}(?:\.\d{1,3}){3})(?::(\d+))?$)"));
    const QRegularExpressionMatch match = ipv4_with_port.match(raw);
    if (match.hasMatch()) {
        return {match.captured(1), match.captured(2)};
    }

    const int colon = raw.lastIndexOf(QLatin1Char(':'));
    if (colon > 0 && raw.indexOf(QLatin1Char(':')) == colon) {
        const QString maybe_port = raw.mid(colon + 1);
        bool port_ok = false;
        maybe_port.toUShort(&port_ok);
        if (port_ok) return {raw.left(colon), maybe_port};
    }

    return {raw, QString()};
}

QString peerAddressWithPort(const QString& raw, const QPair<QString, QString>& endpoint)
{
    if (!raw.trimmed().isEmpty()) return raw.trimmed();
    if (endpoint.first.isEmpty()) return QStringLiteral("-");
    if (endpoint.second.isEmpty()) return endpoint.first;
    if (endpoint.first.contains(QLatin1Char(':'))) {
        return QStringLiteral("[%1]:%2").arg(endpoint.first, endpoint.second);
    }
    return QStringLiteral("%1:%2").arg(endpoint.first, endpoint.second);
}

QString fallbackDash(QString value)
{
    value = value.trimmed();
    return value.isEmpty() ? QStringLiteral("-") : value;
}

bool isIpLiteral(QString host)
{
    host = host.trimmed();
    if (host.startsWith(QLatin1Char('[')) && host.endsWith(QLatin1Char(']'))) {
        host = host.mid(1, host.size() - 2);
    }
    QHostAddress address;
    return address.setAddress(host);
}

QString normalizedPeerHost(QString host)
{
    host = host.trimmed();
    if (host.startsWith(QLatin1Char('[')) && host.endsWith(QLatin1Char(']'))) {
        host = host.mid(1, host.size() - 2);
    }
    const int scope = host.indexOf(QLatin1Char('%'));
    if (scope >= 0) host.truncate(scope);
    QHostAddress address;
    if (address.setAddress(host)) return address.toString().toLower();
    return host.toLower();
}

QString normalizeDnsName(QString value)
{
    value = value.trimmed();
    while (value.endsWith(QLatin1Char('.'))) value.chop(1);
    return value;
}

bool isLikelySyntheticReverseDnsName(QString value)
{
    value = normalizeDnsName(value).toLower();
    if (value.isEmpty() || isIpLiteral(value)) return false;

    const QString dashed = value;
    QString dotted = value;
    dotted.replace(QLatin1Char('-'), QLatin1Char('.'));

    static const QVector<QRegularExpression> synthetic_patterns{
        QRegularExpression(QStringLiteral(R"(^syn-[a-z0-9-]+-res[0-9]+-spectrum-com$)")),
        QRegularExpression(QStringLiteral(R"((^|\.)res[0-9]+\.spectrum\.com$)")),
        QRegularExpression(QStringLiteral(R"((^|\.)members\.linode\.com$)")),
        QRegularExpression(QStringLiteral(R"((^|\.)vultrusercontent\.com$)")),
        QRegularExpression(QStringLiteral(R"((^|\.)hsd[0-9]*\.)")),
        QRegularExpression(QStringLiteral(R"((^|\.)(cpe|pool|dhcp|dyn|dynamic|static|host|ip)[-.])")),
        QRegularExpression(QStringLiteral(R"((^|\.)comcast\.net$)")),
        QRegularExpression(QStringLiteral(R"((^|\.)rr\.com$)"))
    };

    for (const QRegularExpression& pattern : synthetic_patterns) {
        if (pattern.match(value).hasMatch() ||
            pattern.match(dashed).hasMatch() ||
            pattern.match(dotted).hasMatch()) {
            return true;
        }
    }
    return false;
}

QString reverseDomainSortNotation(const QString& value)
{
    QString name = normalizeDnsName(value).toLower();
    if (name.isEmpty() || name == QLatin1String("-") || isIpLiteral(name)) return QString();
    const QStringList labels = name.split(QLatin1Char('.'), Qt::SkipEmptyParts);
    if (labels.isEmpty()) return QString();
    QStringList reversed;
    reversed.reserve(labels.size());
    for (auto it = labels.crbegin(); it != labels.crend(); ++it) reversed << *it;
    return reversed.join(QLatin1Char('.'));
}

QString reverseDnsNameForAddress(const QHostAddress& address)
{
    if (address.protocol() == QAbstractSocket::IPv4Protocol) {
        QStringList octets = address.toString().split(QLatin1Char('.'));
        if (octets.size() != 4) return QString();
        std::reverse(octets.begin(), octets.end());
        return octets.join(QLatin1Char('.')) + QStringLiteral(".in-addr.arpa");
    }

    if (address.protocol() == QAbstractSocket::IPv6Protocol) {
        const Q_IPV6ADDR bytes = address.toIPv6Address();
        QStringList nibbles;
        nibbles.reserve(32);
        for (int i = 15; i >= 0; --i) {
            nibbles << QString::number(bytes[i] & 0x0f, 16);
            nibbles << QString::number((bytes[i] >> 4) & 0x0f, 16);
        }
        return nibbles.join(QLatin1Char('.')) + QStringLiteral(".ip6.arpa");
    }

    return QString();
}

bool isLikelyLanAddress(const QString& host)
{
    QHostAddress address;
    if (!address.setAddress(host.trimmed()) || isInvalidLanDiscoveryAddress(address)) return false;

    if (address.protocol() == QAbstractSocket::IPv4Protocol) {
        const quint32 value = address.toIPv4Address();
        const quint8 a = static_cast<quint8>((value >> 24) & 0xff);
        const quint8 b = static_cast<quint8>((value >> 16) & 0xff);
        return a == 10
            || (a == 172 && b >= 16 && b <= 31)
            || (a == 192 && b == 168)
            || (a == 169 && b == 254);
    }

    if (address.protocol() == QAbstractSocket::IPv6Protocol) {
        const Q_IPV6ADDR bytes = address.toIPv6Address();
        return (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80)
            || (bytes[0] & 0xfe) == 0xfc;
    }

    return false;
}

bool isOnLocalInterfaceSubnet(const QString& host)
{
    QHostAddress peer;
    if (!peer.setAddress(host.trimmed()) || peer.isNull() || peer.isLoopback()) return false;

    for (const QNetworkInterface& iface : QNetworkInterface::allInterfaces()) {
        const QNetworkInterface::InterfaceFlags flags = iface.flags();
        if (!(flags & QNetworkInterface::IsUp) ||
            (flags & QNetworkInterface::IsLoopBack)) {
            continue;
        }
        for (const QNetworkAddressEntry& entry : iface.addressEntries()) {
            const QHostAddress local = entry.ip();
            const int prefix_length = entry.prefixLength();
            if (local.isNull() || local.isLoopback() || prefix_length <= 0) continue;
            if (local.protocol() != peer.protocol()) continue;
            if (peer.isInSubnet(local, prefix_length)) return true;
        }
    }
    return false;
}

QString sanitizedLanHostName(QString value)
{
    value = normalizeDnsName(value);
    if (isLikelySyntheticReverseDnsName(value)) return QString();
    const QStringList local_suffixes{
        QStringLiteral(".localdomain"),
        QStringLiteral(".local"),
        QStringLiteral(".lan"),
        QStringLiteral(".home")
    };
    for (const QString& suffix : local_suffixes) {
        if (value.endsWith(suffix, Qt::CaseInsensitive)) {
            value.chop(suffix.size());
            break;
        }
    }
    value = value.trimmed();
    value.replace(QLatin1Char('.'), QLatin1Char('-'));
    static const QRegularExpression valid(QStringLiteral(R"(^[A-Za-z0-9][A-Za-z0-9_.-]{0,62}$)"));
    if (!valid.match(value).hasMatch()) return QString();

    const QString upper = value.toUpper();
    if (upper == QLatin1String("WORKGROUP") ||
        upper == QLatin1String("LOCAL") ||
        upper == QLatin1String("LOCALHOST") ||
        upper == QLatin1String("BROADCAST") ||
        upper == QLatin1String("BROADCASTHOST") ||
        upper.startsWith(QLatin1Char('_'))) {
        return QString();
    }

    return value;
}

QString sanitizedLanDisplayName(QString value)
{
    value = value.trimmed();
    value.replace(QStringLiteral("\\032"), QStringLiteral(" "));
    value.replace(QRegularExpression(QStringLiteral(R"(\s+)")), QStringLiteral(" "));
    value.remove(QRegularExpression(QStringLiteral(R"([\x00-\x1f\x7f])")));
    if (value.isEmpty() || isIpLiteral(value) || isLikelySyntheticReverseDnsName(value)) return QString();
    if (!value.contains(QLatin1Char(' '))) return sanitizedLanHostName(value);

    static const QRegularExpression valid(QStringLiteral(R"(^[\p{L}\p{N}][\p{L}\p{N} _.'’()-]{0,80}$)"));
    if (!valid.match(value).hasMatch()) return QString();
    const QString upper = value.toUpper();
    if (upper == QLatin1String("WORKGROUP") ||
        upper == QLatin1String("LOCAL") ||
        upper == QLatin1String("LOCALHOST") ||
        upper == QLatin1String("BROADCAST") ||
        upper == QLatin1String("BROADCASTHOST") ||
        upper.startsWith(QLatin1Char('_'))) {
        return QString();
    }
    return value;
}

QString lanWorkstationNameFromCandidate(const QString& value)
{
    const QString name = sanitizedLanDisplayName(value);
    if (name.isEmpty() || isIpLiteral(name)) return QString();
    if (isLikelySyntheticReverseDnsName(name)) return QString();
    return name;
}

QString lanWorkstationIdentityKey(QString value)
{
    value = lanWorkstationNameFromCandidate(value);
    if (value.isEmpty()) return QString();
    value = normalizeDnsName(value).toLower();
    value.replace(QStringLiteral("\\032"), QStringLiteral(" "));
    value.remove(QRegularExpression(QStringLiteral(R"([ ._'’()-])")));
    return value;
}

bool lanWorkstationNameIsHumanPreferred(const QString& value)
{
    return value.contains(QLatin1Char(' '));
}

int lanWorkstationDisplayRank(const QString& value)
{
    if (value.contains(QLatin1Char(':'))) return 3;
    if (lanWorkstationNameIsHumanPreferred(value)) return 0;
    const QString key = lanWorkstationIdentityKey(value);
    if (!key.isEmpty()) return 1;
    return 2;
}

bool isLocalStyleDnsName(QString value)
{
    value = normalizeDnsName(value);
    if (value.isEmpty() || isIpLiteral(value)) return false;
    if (!value.contains(QLatin1Char('.'))) return true;
    const QString lower = value.toLower();
    return lower.endsWith(QStringLiteral(".localdomain")) ||
           lower.endsWith(QStringLiteral(".local")) ||
           lower.endsWith(QStringLiteral(".lan")) ||
           lower.endsWith(QStringLiteral(".home"));
}

QString lanAliasFromDnsName(const QString& value)
{
    if (!isLocalStyleDnsName(value)) return QString();
    const QString name = lanWorkstationNameFromCandidate(value);
    if (name.isEmpty()) return QString();
    return name;
}

QString parseLanPeerNameLookupOutput(const QString& output)
{
    static const QVector<QRegularExpression> patterns{
        QRegularExpression(QStringLiteral(R"(^\s*Bonjour\s+Name:\s*(.+?)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(NetBIOS\s+Name:\s*([A-Za-z0-9_.-]+))"), QRegularExpression::CaseInsensitiveOption),
        QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62})\s+0x00\s+UNIQUE\b.*\[Workstation Service\].*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62})\s+0x20\s+UNIQUE\b.*\[File/Print Server Service\].*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(^\s*Server\s*:\s*([A-Za-z0-9_.-]+)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(NameHost\s*:\s*([A-Za-z0-9_.-]+))"), QRegularExpression::CaseInsensitiveOption),
        QRegularExpression(QStringLiteral(R"(^\s*name:\s*([A-Za-z0-9_.-]+)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(\bPinging\s+([A-Za-z0-9_.-]+)\s+\[)"), QRegularExpression::CaseInsensitiveOption),
        QRegularExpression(QStringLiteral(R"(^\s*PING\s+([A-Za-z0-9_.-]+)\s+\()"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(\bPTR\s+([A-Za-z0-9_.-]+\.local)\.?)"), QRegularExpression::CaseInsensitiveOption),
        QRegularExpression(QStringLiteral(R"(^\s*(?:[0-9]{1,3}\.){3}[0-9]{1,3}\s+([A-Za-z0-9_.-]+)\s*$)"), QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62})\s+<00>\s+(?!(?:.*<GROUP>))(?:UNIQUE|-)\b.*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62})\s+<20>\s+(?!(?:.*<GROUP>))(?:UNIQUE|-)\b.*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption),
        QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62}\.(?:localdomain|local|lan|home))\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)
    };

    for (int i = 0; i < patterns.size(); ++i) {
        const QRegularExpression& pattern = patterns.at(i);
        const QRegularExpressionMatch match = pattern.match(output);
        if (!match.hasMatch()) continue;
        const QString captured = match.captured(1);
        const bool trusted_machine_name = i == 0 || i == 1 || i == 2 || i == 3 || i == 4 || i == 11 || i == 12;
        if (!trusted_machine_name && !isLocalStyleDnsName(captured)) continue;
        const QString name = lanWorkstationNameFromCandidate(captured);
        if (!name.isEmpty()) return name;
    }

    return QString();
}

QStringList parseLanPeerFingerprintDetails(const QString& output)
{
    QStringList details;
    auto addDetail = [&details](QString label, QString value) {
        value = value.trimmed();
        value.replace(QRegularExpression(QStringLiteral(R"(\s+)")), QStringLiteral(" "));
        if (value.isEmpty()) return;
        if ((label == QLatin1String("Name") ||
             label == QLatin1String("Server") ||
             label == QLatin1String("NetBIOS")) &&
            lanWorkstationNameFromCandidate(value).isEmpty()) {
            return;
        }
        if (label == QLatin1String("Name") ||
            label == QLatin1String("Server") ||
            label == QLatin1String("NetBIOS")) {
            value = lanWorkstationNameFromCandidate(value);
        }
        if (label == QLatin1String("Bonjour")) {
            value = lanWorkstationNameFromCandidate(value);
            if (value.isEmpty()) return;
            label = QStringLiteral("Name");
        }
        if (label == QLatin1String("MAC")) return;
        const bool identity_label = label == QLatin1String("Name") ||
                                    label == QLatin1String("Server") ||
                                    label == QLatin1String("NetBIOS");
        const QString item = identity_label
            ? value
            : QStringLiteral("%1: %2").arg(label, value);
        const QString item_key = identity_label ? lanWorkstationIdentityKey(value) : item.toLower();
        if (item_key.isEmpty()) return;

        for (int i = 0; i < details.size(); ++i) {
            const QString existing = details.at(i);
            const QString existing_key = identity_label ? lanWorkstationIdentityKey(existing) : existing.toLower();
            if (existing_key != item_key) continue;
            if (identity_label &&
                lanWorkstationNameIsHumanPreferred(value) &&
                !lanWorkstationNameIsHumanPreferred(existing)) {
                details[i] = item;
            }
            return;
        }
        details.push_back(item);
    };

    const QString name = parseLanPeerNameLookupOutput(output);
    if (!name.isEmpty()) addDetail(QStringLiteral("Name"), name);

    const QVector<QPair<QString, QRegularExpression>> patterns{
        {QStringLiteral("Name"), QRegularExpression(QStringLiteral(R"(^\s*Bonjour\s+Name:\s*(.+?)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("Bonjour"), QRegularExpression(QStringLiteral(R"(^\s*Bonjour\s+Host:\s*(.+?)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("macOS"), QRegularExpression(QStringLiteral(R"(\bOS=\[([^\]]*(?:Mac|Darwin|Apple)[^\]]*)\])"), QRegularExpression::CaseInsensitiveOption)},
        {QStringLiteral("Windows"), QRegularExpression(QStringLiteral(R"(\bOS=\[([^\]]*Windows[^\]]*)\])"), QRegularExpression::CaseInsensitiveOption)},
        {QStringLiteral("Linux"), QRegularExpression(QStringLiteral(R"(\bOS=\[([^\]]*Linux[^\]]*)\])"), QRegularExpression::CaseInsensitiveOption)},
        {QStringLiteral("OS"), QRegularExpression(QStringLiteral(R"(\bOS=\[([^\]]+)\])"), QRegularExpression::CaseInsensitiveOption)},
        {QStringLiteral("Server"), QRegularExpression(QStringLiteral(R"(\bServer=\[([^\]]+)\])"), QRegularExpression::CaseInsensitiveOption)},
        {QStringLiteral("Server"), QRegularExpression(QStringLiteral(R"(^\s*Server\s*:\s*([A-Za-z0-9_.-]+)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("Workgroup"), QRegularExpression(QStringLiteral(R"(\bWorkgroup=\[([^\]]+)\])"), QRegularExpression::CaseInsensitiveOption)},
        {QStringLiteral("Workgroup"), QRegularExpression(QStringLiteral(R"(^\s*Workgroup\s*:\s*([A-Za-z0-9_.-]+)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("NetBIOS"), QRegularExpression(QStringLiteral(R"(NetBIOS\s+Name:\s*([A-Za-z0-9_.-]+))"), QRegularExpression::CaseInsensitiveOption)},
        {QStringLiteral("NetBIOS"), QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62})\s+0x00\s+UNIQUE\b.*\[Workstation Service\].*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("NetBIOS"), QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62})\s+0x20\s+UNIQUE\b.*\[File/Print Server Service\].*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("NetBIOS"), QRegularExpression(QStringLiteral(R"(^\s*([A-Za-z0-9][A-Za-z0-9_.-]{0,62})\s+<20>\s+(?!(?:.*<GROUP>))(?:UNIQUE|-)\b.*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("OS"), QRegularExpression(QStringLiteral(R"(^\s*(?:Running|OS details):\s*(.+?)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)},
        {QStringLiteral("Device"), QRegularExpression(QStringLiteral(R"(^\s*Device type:\s*(.+?)\s*$)"), QRegularExpression::CaseInsensitiveOption | QRegularExpression::MultilineOption)}
    };

    for (const auto& item : patterns) {
        QRegularExpressionMatchIterator it = item.second.globalMatch(output);
        while (it.hasNext() && details.size() < 10) {
            const QRegularExpressionMatch match = it.next();
            addDetail(item.first, match.captured(1));
        }
    }

    if (output.contains(QStringLiteral("Windows"), Qt::CaseInsensitive) && !details.join(QString()).contains(QStringLiteral("Windows"), Qt::CaseInsensitive)) {
        addDetail(QStringLiteral("OS"), QStringLiteral("Windows"));
    }
    if ((output.contains(QStringLiteral("Darwin"), Qt::CaseInsensitive) || output.contains(QStringLiteral("Mac OS"), Qt::CaseInsensitive)) &&
        !details.join(QString()).contains(QStringLiteral("macOS"), Qt::CaseInsensitive)) {
        addDetail(QStringLiteral("OS"), QStringLiteral("macOS"));
    }
    if (output.contains(QStringLiteral("Linux"), Qt::CaseInsensitive) && !details.join(QString()).contains(QStringLiteral("Linux"), Qt::CaseInsensitive)) {
        addDetail(QStringLiteral("OS"), QStringLiteral("Linux"));
    }

    std::stable_sort(details.begin(), details.end(), [](const QString& a, const QString& b) {
        return lanWorkstationDisplayRank(a) < lanWorkstationDisplayRank(b);
    });

    return details;
}

QString cleanedLanWorkstationInfo(QString info)
{
    QStringList cleaned;
    auto addItem = [&cleaned](QString item) {
        item = item.trimmed();
        if (item.isEmpty()) return;

        const QString lower = item.toLower();
        if (lower.startsWith(QStringLiteral("mac:")) ||
            lower.contains(QRegularExpression(QStringLiteral(R"(\bmac:\s*[0-9a-f]{1,2}(?::[0-9a-f]{1,2}){5}\b)"), QRegularExpression::CaseInsensitiveOption))) {
            return;
        }

        static const QRegularExpression source_prefix(
            QStringLiteral(R"(^\s*(?:Name|Bonjour|NetBIOS|Server)\s*:\s*)"),
            QRegularExpression::CaseInsensitiveOption);
        item.remove(source_prefix);
        item = item.trimmed();

        const QString identity = lanWorkstationNameFromCandidate(item);
        const bool identity_item = !identity.isEmpty();
        if (identity_item) item = identity;

        const QString item_key = identity_item ? lanWorkstationIdentityKey(item) : item.toLower();
        if (item_key.isEmpty()) return;

        for (int i = 0; i < cleaned.size(); ++i) {
            const QString existing = cleaned.at(i);
            const QString existing_key = identity_item ? lanWorkstationIdentityKey(existing) : existing.toLower();
            if (existing_key != item_key) continue;
            if (identity_item &&
                lanWorkstationNameIsHumanPreferred(item) &&
                !lanWorkstationNameIsHumanPreferred(existing)) {
                cleaned[i] = item;
            }
            return;
        }

        cleaned.push_back(item);
    };

    const QStringList parts = info.split(QLatin1Char('|'), Qt::SkipEmptyParts);
    for (const QString& part : parts) addItem(part);
    std::stable_sort(cleaned.begin(), cleaned.end(), [](const QString& a, const QString& b) {
        return lanWorkstationDisplayRank(a) < lanWorkstationDisplayRank(b);
    });
    return cleaned.join(QStringLiteral(" | "));
}

QString nmapProgramPath()
{
    static const QStringList candidates{
#if defined(Q_OS_WIN)
        QStringLiteral("nmap.exe")
#elif defined(Q_OS_MACOS)
        QStringLiteral("/opt/homebrew/bin/nmap"),
        QStringLiteral("/usr/local/bin/nmap"),
        QStringLiteral("/usr/bin/nmap")
#else
        QStringLiteral("/usr/bin/nmap"),
        QStringLiteral("/usr/local/bin/nmap")
#endif
    };
    for (const QString& candidate : candidates) {
        if (candidate.contains(QLatin1Char('/'))) {
            if (QFileInfo::exists(candidate) && QFileInfo(candidate).isExecutable()) return candidate;
        } else {
            return candidate;
        }
    }
    return QString();
}

QString optionalProgramPath(const QStringList& candidates)
{
    for (const QString& candidate : candidates) {
        if (candidate.contains(QLatin1Char('/'))) {
            if (QFileInfo::exists(candidate) && QFileInfo(candidate).isExecutable()) return candidate;
        } else {
            return candidate;
        }
    }
    return QString();
}

bool isVisibleLanPeer(const QString& host,
                      const QString& reverse_dns,
                      const QString& known_dns,
                      const QHash<QString, QString>& lan_cache,
                      const QHash<QString, QString>& lan_info_cache)
{
    Q_UNUSED(reverse_dns);
    Q_UNUSED(known_dns);
    const QString key = normalizedPeerHost(host);
    return isLikelyLanAddress(host) ||
           isOnLocalInterfaceSubnet(host) ||
           lan_cache.contains(key) ||
           lan_info_cache.contains(key);
}

QString peerLanWorkstationInfo(const QString& host,
                               const QString& reverse_dns,
                               const QHash<QString, QString>& lan_info_cache,
                               const QHash<QString, QString>& lan_name_cache,
                               const QHash<QString, QString>& dns_cache,
                               const QSet<QString>& pending)
{
    const QString key = normalizedPeerHost(host);
    const QString name = lan_name_cache.value(key);
    if (!name.isEmpty()) return name;
    const QString info = cleanedLanWorkstationInfo(lan_info_cache.value(key));
    if (!info.isEmpty()) return info;
    Q_UNUSED(reverse_dns);
    const QString alias = lanAliasFromDnsName(dns_cache.value(key));
    if (!alias.isEmpty()) return alias;
    if (pending.contains(key)) return QStringLiteral("Scanning...");
    return QStringLiteral("-");
}

QString peerLanWorkstationSourceTooltip(const QString& host,
                                        const QString& display_name,
                                        const QString& reverse_dns,
                                        const QHash<QString, QString>& lan_info_cache,
                                        const QHash<QString, QString>& lan_name_cache,
                                        const QHash<QString, QString>& dns_cache,
                                        const QSet<QString>& pending)
{
    const QString key = normalizedPeerHost(host);
    QStringList sources;
    const QString raw_info = lan_info_cache.value(key);
    if (raw_info.contains(QStringLiteral("Nu LAN beacon"), Qt::CaseInsensitive)) sources.push_back(QStringLiteral("Nu LAN beacon"));
    if (raw_info.contains(QStringLiteral("Bonjour"), Qt::CaseInsensitive)) sources.push_back(QStringLiteral("Bonjour/mDNS"));
    if (raw_info.contains(QStringLiteral("NetBIOS"), Qt::CaseInsensitive) ||
        raw_info.contains(QStringLiteral("Workstation Service"), Qt::CaseInsensitive) ||
        raw_info.contains(QStringLiteral("File/Print Server Service"), Qt::CaseInsensitive)) {
        sources.push_back(QStringLiteral("SMB/NetBIOS"));
    }
    if (raw_info.contains(QStringLiteral("nmap"), Qt::CaseInsensitive) ||
        raw_info.contains(QStringLiteral("OS="), Qt::CaseInsensitive) ||
        raw_info.contains(QStringLiteral("Device type:"), Qt::CaseInsensitive)) {
        sources.push_back(QStringLiteral("nmap fingerprint"));
    }
    if (lan_name_cache.contains(key)) sources.push_back(QStringLiteral("host-name probe"));
    if (!lanAliasFromDnsName(dns_cache.value(key)).isEmpty() ||
        !lanAliasFromDnsName(reverse_dns).isEmpty()) {
        sources.push_back(QStringLiteral("local DNS/reverse DNS"));
    }
    if (isLikelyLanAddress(host) || isOnLocalInterfaceSubnet(host)) {
        sources.push_back(QStringLiteral("local/private address match"));
    }
    if (pending.contains(key)) sources.push_back(QStringLiteral("scan pending"));
    sources.removeDuplicates();

    const QString name = display_name.trimmed().isEmpty() || display_name == QLatin1String("-")
        ? QStringLiteral("detected LAN peer")
        : display_name.trimmed();
    return QStringLiteral("LAN: %1%2")
        .arg(name,
             sources.isEmpty()
                ? QString()
                : QStringLiteral("\nDiscovery source: %1").arg(sources.join(QStringLiteral(", "))));
}

QStringList configuredSeedDomains()
{
    return {
        QStringLiteral("seed.defcoin.io"),
        QStringLiteral("seed.defcoin.mikej.tech"),
        QStringLiteral("seed.defcoin.dc903.org"),
        QStringLiteral("seed.defcoincore.org"),
        QStringLiteral("seed.defcoin-ng.org")
    };
}

int seedDomainPriority(const QString& domain)
{
    const QStringList domains = configuredSeedDomains();
    const int index = domains.indexOf(domain.toLower());
    return index < 0 ? domains.size() : index;
}

QString alignIPv4ForDisplay(const QString& value)
{
    const QString trimmed = value.trimmed();
    static const QRegularExpression ipv4_with_optional_port(QStringLiteral(R"(^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(:\d+)?$)"));
    const QRegularExpressionMatch match = ipv4_with_optional_port.match(trimmed);
    if (!match.hasMatch()) return trimmed;
    return QStringLiteral("%1.%2.%3.%4%5")
        .arg(match.captured(1).toInt(), 3, 10, QLatin1Char(' '))
        .arg(match.captured(2).toInt(), 3, 10, QLatin1Char(' '))
        .arg(match.captured(3).toInt(), 3, 10, QLatin1Char(' '))
        .arg(match.captured(4).toInt(), 3, 10, QLatin1Char(' '))
        .arg(match.captured(5));
}

QString peerIpDisplay(const QPair<QString, QString>& endpoint)
{
    if (endpoint.first.trimmed().isEmpty()) return QStringLiteral("-");
    return isIpLiteral(endpoint.first) ? alignIPv4ForDisplay(endpoint.first) : QStringLiteral("-");
}

QString peerAddressPortDisplay(const QString& raw, const QPair<QString, QString>& endpoint)
{
    return alignIPv4ForDisplay(peerAddressWithPort(raw, endpoint));
}

QString peerDnsName(const QJsonObject& peer,
                    const QPair<QString, QString>& endpoint,
                    const QHash<QString, QString>& dns_cache)
{
    const QString explicit_dns = fallbackDash(peer.value(QStringLiteral("dns_name")).toString(
        peer.value(QStringLiteral("fqdn")).toString(peer.value(QStringLiteral("addr_name")).toString())));
    if (explicit_dns != QLatin1String("-") && !isIpLiteral(splitPeerAddressAndPort(explicit_dns).first)) return explicit_dns;
    if (!endpoint.first.isEmpty() && !isIpLiteral(endpoint.first)) return endpoint.first;
    const QString cached_dns = dns_cache.value(normalizedPeerHost(endpoint.first));
    if (!cached_dns.isEmpty()) return cached_dns;
    return QStringLiteral("-");
}

QString peerDomainAlias(const QJsonObject& peer,
                        const QPair<QString, QString>& endpoint,
                        const QString& reverse_dns,
                        const QHash<QString, QString>& dns_cache,
                        const QHash<QString, QString>& alias_cache,
                        const QHash<QString, QString>& lan_cache)
{
    const QString lan_name = lan_cache.value(normalizedPeerHost(endpoint.first));
    if (!lan_name.isEmpty()) return lan_name;

    const QString explicit_dns = peer.value(QStringLiteral("dns_name")).toString(
        peer.value(QStringLiteral("fqdn")).toString(peer.value(QStringLiteral("addr_name")).toString()));
    const QString explicit_lan_alias = lanAliasFromDnsName(explicit_dns);
    if (!explicit_lan_alias.isEmpty()) return explicit_lan_alias;

    const QString reverse_lan_alias = lanAliasFromDnsName(reverse_dns);
    if (!reverse_lan_alias.isEmpty()) return reverse_lan_alias;

    const QString cached_lan_alias = lanAliasFromDnsName(dns_cache.value(normalizedPeerHost(endpoint.first)));
    if (!cached_lan_alias.isEmpty()) return cached_lan_alias;

    if (isLikelyLanAddress(endpoint.first)) {
        const QString fallback_lan_name = sanitizedLanHostName(endpoint.first);
        if (!fallback_lan_name.isEmpty() && !isIpLiteral(fallback_lan_name)) {
            return fallback_lan_name;
        }
    }

    const QString explicit_alias = fallbackDash(peer.value(QStringLiteral("domain_alias")).toString(
        peer.value(QStringLiteral("seed_domain")).toString(peer.value(QStringLiteral("source_domain")).toString())));
    if (explicit_alias != QLatin1String("-")) return explicit_alias;

    const QString alias = alias_cache.value(normalizedPeerHost(endpoint.first));
    if (!alias.isEmpty()) return alias;

    const QString host = endpoint.first.trimmed().toLower();
    if (!host.isEmpty() && configuredSeedDomains().contains(host)) return host;

    return QStringLiteral("-");
}

QString peerNumberText(const QJsonObject& peer, const QString& key)
{
    const QJsonValue value = peer.value(key);
    if (value.isDouble()) return QString::number(value.toVariant().toLongLong());
    if (value.isString()) return fallbackDash(value.toString());
    return QStringLiteral("-");
}

QString formatHashrateMetric(double value)
{
    static const QStringList units{
        QStringLiteral("H/s"),
        QStringLiteral("KH/s"),
        QStringLiteral("MH/s"),
        QStringLiteral("GH/s"),
        QStringLiteral("TH/s"),
        QStringLiteral("PH/s")
    };
    if (!std::isfinite(value) || value <= 0.0) return QStringLiteral("-");
    int unit = 0;
    while (value >= 1000.0 && unit + 1 < units.size()) {
        value /= 1000.0;
        ++unit;
    }
    return QStringLiteral("%1 %2").arg(value, 0, 'f', value >= 100.0 ? 0 : 2).arg(units.at(unit));
}

QString formatBlockSpacingMetric(double seconds)
{
    if (!std::isfinite(seconds) || seconds <= 0.0) return QStringLiteral("-");
    if (seconds < 90.0) return QStringLiteral("%1s").arg(QString::number(seconds, 'f', seconds < 10.0 ? 1 : 0));
    const double minutes = seconds / 60.0;
    if (minutes < 120.0) return QStringLiteral("%1m").arg(QString::number(minutes, 'f', minutes < 10.0 ? 1 : 0));
    const double hours = minutes / 60.0;
    return QStringLiteral("%1h").arg(QString::number(hours, 'f', hours < 10.0 ? 1 : 0));
}

QString formatCompactDifficulty(double value)
{
    if (!std::isfinite(value) || value <= 0.0) return QStringLiteral("-");
    return QString::number(value, 'f', value >= 100.0 ? 2 : 8)
        .remove(QRegularExpression(QStringLiteral("0+$")))
        .remove(QRegularExpression(QStringLiteral("\\.$")));
}

QString formatMinerHashrateText(const QString& amount, const QString& unit)
{
    QString normalized_unit = unit.trimmed().toUpper();
    if (normalized_unit == QLatin1String("KH/S")) return QStringLiteral("%1 KH/s").arg(amount);
    if (normalized_unit == QLatin1String("MH/S")) return QStringLiteral("%1 MH/s").arg(amount);
    if (normalized_unit == QLatin1String("GH/S")) return QStringLiteral("%1 GH/s").arg(amount);
    if (normalized_unit == QLatin1String("TH/S")) return QStringLiteral("%1 TH/s").arg(amount);
    return QStringLiteral("%1 H/s").arg(amount);
}

QString formatSyncEtaSeconds(qint64 seconds)
{
    if (seconds <= 0) return QStringLiteral("<1 min");
    const qint64 minutes = std::max<qint64>(1, (seconds + 59) / 60);
    const qint64 days = minutes / (24 * 60);
    const qint64 hours = (minutes % (24 * 60)) / 60;
    const qint64 mins = minutes % 60;
    if (days > 0) return QStringLiteral("%1d %2h %3m").arg(days).arg(hours, 2, 10, QLatin1Char('0')).arg(mins, 2, 10, QLatin1Char('0'));
    if (hours > 0) return QStringLiteral("%1h %2m").arg(hours).arg(mins, 2, 10, QLatin1Char('0'));
    return QStringLiteral("%1m").arg(mins);
}

QString formatMessageByteCount(qint64 bytes)
{
    double value = bytes;
    QString unit = QStringLiteral("B");
    if (value >= 1024.0) { value /= 1024.0; unit = QStringLiteral("KB"); }
    if (value >= 1024.0) { value /= 1024.0; unit = QStringLiteral("MB"); }
    return QStringLiteral("%1 %2").arg(value, 0, unit == QLatin1String("B") ? 'f' : 'f', unit == QLatin1String("B") ? 0 : 1).arg(unit);
}

QString orderedMessageTypeStats(const QHash<QString, qint64>& counts)
{
    static const QVector<QPair<QString, QStringList>> ordered{
        {QStringLiteral("cmpctblock"), {QStringLiteral("cmpctblock")}},
        {QStringLiteral("headers"), {QStringLiteral("headers")}},
        {QStringLiteral("ping"), {QStringLiteral("ping")}},
        {QStringLiteral("pong"), {QStringLiteral("pong")}},
        {QStringLiteral("addr*"), {QStringLiteral("addr"), QStringLiteral("addrv2")}},
    };

    QStringList out;
    out.reserve(ordered.size());
    for (const auto& entry : ordered) {
        qint64 total = 0;
        for (const QString& key : entry.second) total += counts.value(key, 0);
        out.push_back(QStringLiteral("%1: %2").arg(entry.first, formatMessageByteCount(total)));
    }
    return out.join(QStringLiteral(" | "));
}

QString peerSyncHeightText(const QJsonObject& peer, const QString& key)
{
    const QJsonValue value = peer.value(key);
    if (value.isDouble()) {
        const qint64 height = value.toVariant().toLongLong();
        return height < 0 ? QStringLiteral("Unknown") : QString::number(height);
    }
    if (value.isString()) {
        const QString text = value.toString().trimmed();
        return text == QLatin1String("-1") ? QStringLiteral("Unknown") : fallbackDash(text);
    }
    return QStringLiteral("-");
}

QString peerBoolText(const QJsonObject& peer, const QString& key)
{
    const QJsonValue value = peer.value(key);
    return value.isBool() ? (value.toBool() ? QStringLiteral("Enabled") : QStringLiteral("Disabled")) : QStringLiteral("-");
}

QString peerUnixTimeText(const QJsonObject& peer, const QString& key)
{
    const QJsonValue value = peer.value(key);
    if (!value.isDouble()) return QStringLiteral("-");
    const qint64 seconds = value.toVariant().toLongLong();
    if (seconds <= 0) return QStringLiteral("-");
    return QDateTime::fromSecsSinceEpoch(seconds).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
}

QString boolText(bool value)
{
    return value ? QStringLiteral("Enabled") : QStringLiteral("Disabled");
}

QString normalPurpose(const QString& purpose)
{
    if (purpose == QLatin1String("send")) return QStringLiteral("Contact");
    if (purpose == QLatin1String("receive")) return QStringLiteral("Receive");
    return purpose.isEmpty() ? QStringLiteral("Address") : purpose.left(1).toUpper() + purpose.mid(1);
}

void upsertAddressRow(QVariantList& rows, const QVariantList& candidate)
{
    if (candidate.size() < 2) return;
    const QString address = candidate.at(1).toString();
    for (QVariant& value : rows) {
        QVariantList existing = value.toList();
        if (existing.size() >= 2 && existing.at(1).toString() == address) {
            value = candidate;
            return;
        }
    }
    rows.push_back(candidate);
}

QString realHomePath()
{
#if defined(Q_OS_WIN)
    return QDir::homePath();
#else
    if (const passwd* pw = getpwuid(getuid())) {
        if (pw->pw_dir && *pw->pw_dir) {
            return QString::fromLocal8Bit(pw->pw_dir);
        }
    }
    return QDir::homePath();
#endif
}

QString localLogTimestamp(const QDateTime& utc)
{
    return utc.toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"));
}

bool parseDebugLogTimestamp(const QString& line, QDateTime& utc, QString& message)
{
    static const QRegularExpression re(QStringLiteral(R"(^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})Z\s*(.*)$)"));
    const QRegularExpressionMatch match = re.match(line);
    if (!match.hasMatch()) return false;
    utc = QDateTime::fromString(match.captured(1), QStringLiteral("yyyy-MM-dd'T'HH:mm:ss"));
    utc.setTimeZone(QTimeZone(QByteArrayLiteral("UTC")));
    message = match.captured(2);
    return utc.isValid();
}

bool isBackendTransportError(QNetworkReply::NetworkError error)
{
    switch (error) {
    case QNetworkReply::ConnectionRefusedError:
    case QNetworkReply::RemoteHostClosedError:
    case QNetworkReply::HostNotFoundError:
    case QNetworkReply::TimeoutError:
    case QNetworkReply::NetworkSessionFailedError:
    case QNetworkReply::TemporaryNetworkFailureError:
        return true;
    default:
        return false;
    }
}

QString formatLocalDebugLogLine(const QString& line)
{
    QDateTime utc;
    QString message;
    if (!parseDebugLogTimestamp(line, utc, message)) return line;
    return localLogTimestamp(utc) + QStringLiteral(" ") + message;
}

QString formatDurationFromSeconds(qint64 seconds)
{
    if (seconds < 0) return QStringLiteral("Unknown");
    const qint64 hours = seconds / 3600;
    const qint64 minutes = (seconds % 3600) / 60;
    const qint64 secs = seconds % 60;
    if (hours > 0) return QStringLiteral("%1h %2m %3s").arg(hours).arg(minutes).arg(secs);
    if (minutes > 0) return QStringLiteral("%1m %2s").arg(minutes).arg(secs);
    return QStringLiteral("%1s").arg(secs);
}

QString variantColumnType(const QVariantList& column_types, const QVariantList& columns, int index)
{
    if (index >= 0 && index < column_types.size()) {
        const QString explicit_type = column_types.at(index).toString().trimmed().toLower();
        if (!explicit_type.isEmpty()) return explicit_type;
    }
    const QString name = index >= 0 && index < columns.size() ? columns.at(index).toString().toLower() : QString();
    if (name.contains(QStringLiteral("date")) || name.contains(QStringLiteral("time"))) return QStringLiteral("date");
    if (name.contains(QStringLiteral("amount")) || name.contains(QStringLiteral("balance"))) return QStringLiteral("amount");
    if (name.contains(QStringLiteral("sent")) || name.contains(QStringLiteral("rec"))) return QStringLiteral("bytes");
    if (name.contains(QStringLiteral("ping"))) return QStringLiteral("duration");
    if (name.contains(QStringLiteral("id")) || name.contains(QStringLiteral("peers")) || name.contains(QStringLiteral("block"))) return QStringLiteral("number");
    if (name.contains(QStringLiteral("address")) || name.contains(QStringLiteral("ip")) || name.contains(QStringLiteral("port"))) return QStringLiteral("ipport");
    return QStringLiteral("text");
}

double variantAt(const QVariantList& values, int index, double fallback)
{
    if (index < 0 || index >= values.size()) return fallback;
    bool ok = false;
    const double value = values.at(index).toDouble(&ok);
    return ok ? value : fallback;
}

double defaultColumnMinimum(const QString& type)
{
    if (type == QLatin1String("action") || type == QLatin1String("delete")) return 44.0;
    if (type == QLatin1String("ipport") || type == QLatin1String("address") || type == QLatin1String("hash")) return 210.0;
    if (type == QLatin1String("date")) return 132.0;
    if (type == QLatin1String("bytes") || type == QLatin1String("amount")) return 96.0;
    if (type == QLatin1String("duration")) return 78.0;
    if (type == QLatin1String("number")) return 64.0;
    return 90.0;
}

double defaultColumnMaximum(const QString& type)
{
    if (type == QLatin1String("action") || type == QLatin1String("delete")) return 44.0;
    if (type == QLatin1String("ipport")) return 840.0;
    if (type == QLatin1String("address") || type == QLatin1String("hash")) return 960.0;
    if (type == QLatin1String("text")) return 1200.0;
    return 720.0;
}

bool monoColumnType(const QString& type, const QString& name = QString())
{
    const QString lower = name.toLower();
    return type == QLatin1String("ipport") || type == QLatin1String("address") || type == QLatin1String("hash")
        || type == QLatin1String("number") || type == QLatin1String("bytes") || type == QLatin1String("duration")
        || type == QLatin1String("date") || lower == QLatin1String("port") || lower.contains(QStringLiteral("magic"))
        || lower.contains(QStringLiteral("version")) || lower == QLatin1String("svcs") || lower.contains(QStringLiteral("height"))
        || lower.contains(QStringLiteral("headers")) || lower.contains(QStringLiteral("blocks"));
}

QString shellQuoteForDisplay(const QString& value)
{
    if (value.isEmpty()) return QStringLiteral("''");
    QString out = value;
    out.replace(QLatin1Char('\''), QStringLiteral("'\\''"));
    return QStringLiteral("'%1'").arg(out);
}

QString processCommandForDisplay(const QString& program, const QStringList& args)
{
    QStringList parts;
    parts.push_back(shellQuoteForDisplay(program));
    for (const QString& arg : args) parts.push_back(shellQuoteForDisplay(arg));
    return parts.join(QLatin1Char(' '));
}

QString singleLineLimited(const QString& value, int max_chars)
{
    QString out;
    out.reserve(std::min(value.size(), static_cast<qsizetype>(max_chars)));
    for (const QChar ch : value.trimmed()) {
        const ushort code = ch.unicode();
        if (code < 0x20 || code == 0x7f) continue;
        out.append(ch);
        if (out.size() >= max_chars) break;
    }
    return out;
}

bool isSafeRpcMethodName(const QString& method)
{
    static const QRegularExpression method_re(QStringLiteral(R"(^[A-Za-z0-9_]{1,64}$)"));
    return method_re.match(method).hasMatch();
}

QStringList splitConsoleCommandLine(const QString& command, QString* error)
{
    QString text = command.trimmed();
    if ((text.startsWith(QLatin1Char('"')) && text.endsWith(QLatin1Char('"'))) ||
        (text.startsWith(QLatin1Char('\'')) && text.endsWith(QLatin1Char('\'')))) {
        text = text.mid(1, text.size() - 2).trimmed();
    }

    QStringList tokens;
    QString current;
    QChar quote;
    bool escape = false;
    for (const QChar ch : text) {
        if (escape) {
            current.append(ch);
            escape = false;
            continue;
        }
        if (ch == QLatin1Char('\\')) {
            escape = true;
            continue;
        }
        if (!quote.isNull()) {
            if (ch == quote) {
                quote = QChar();
            } else {
                current.append(ch);
            }
            continue;
        }
        if (ch == QLatin1Char('"') || ch == QLatin1Char('\'')) {
            quote = ch;
            continue;
        }
        if (ch.isSpace()) {
            if (!current.isEmpty()) {
                tokens.push_back(current);
                current.clear();
            }
            continue;
        }
        current.append(ch);
    }
    if (!quote.isNull()) {
        if (error) *error = QStringLiteral("Unclosed quote in RPC console command.");
        return {};
    }
    if (escape) current.append(QLatin1Char('\\'));
    if (!current.isEmpty()) tokens.push_back(current);
    return tokens;
}

QJsonValue consoleTokenToJsonValue(const QString& token)
{
    const QString trimmed = token.trimmed();
    if (trimmed.compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0) return true;
    if (trimmed.compare(QStringLiteral("false"), Qt::CaseInsensitive) == 0) return false;
    if (trimmed.compare(QStringLiteral("null"), Qt::CaseInsensitive) == 0) return QJsonValue();

    if ((trimmed.startsWith(QLatin1Char('{')) && trimmed.endsWith(QLatin1Char('}'))) ||
        (trimmed.startsWith(QLatin1Char('[')) && trimmed.endsWith(QLatin1Char(']')))) {
        QJsonParseError parse_error;
        const QJsonDocument doc = QJsonDocument::fromJson(trimmed.toUtf8(), &parse_error);
        if (parse_error.error == QJsonParseError::NoError) {
            if (doc.isObject()) return doc.object();
            if (doc.isArray()) return doc.array();
        }
    }

    static const QRegularExpression integer_re(QStringLiteral(R"(^-?(0|[1-9][0-9]*)$)"));
    static const QRegularExpression decimal_re(QStringLiteral(R"(^-?(0|[1-9][0-9]*)\.[0-9]+$)"));
    if (integer_re.match(trimmed).hasMatch()) {
        bool ok = false;
        const qint64 value = trimmed.toLongLong(&ok);
        if (ok) return static_cast<double>(value);
    }
    if (decimal_re.match(trimmed).hasMatch()) {
        bool ok = false;
        const double value = trimmed.toDouble(&ok);
        if (ok) return value;
    }
    return trimmed;
}

QString rpcPromptForDisplay(const QString& method, const QString& params_json);

struct ParsedConsoleCommand
{
    QString method;
    QJsonArray params;
    QString prompt;
};

QString paramsJsonForPrompt(const QJsonArray& params)
{
    if (params.isEmpty()) return QString();
    return QString::fromUtf8(QJsonDocument(params).toJson(QJsonDocument::Compact));
}

bool parseConsoleCommandForRpc(QString command, QString params_json, ParsedConsoleCommand* parsed, QString* error)
{
    command = command.trimmed();
    params_json = params_json.trimmed();
    if (params_json.isEmpty() && command.startsWith(QLatin1Char('>'))) {
        command = command.mid(1).trimmed();
    }
    if (params_json.isEmpty()
        && command.size() >= 2
        && ((command.startsWith(QLatin1Char('"')) && command.endsWith(QLatin1Char('"')))
            || (command.startsWith(QLatin1Char('\'')) && command.endsWith(QLatin1Char('\''))))) {
        command = command.mid(1, command.size() - 2).trimmed();
    }
    if (params_json.isEmpty() && command.contains(QRegularExpression(QStringLiteral("\\s")))) {
        QString split_error;
        const QStringList tokens = splitConsoleCommandLine(command, &split_error);
        if (!split_error.isEmpty()) {
            if (error) *error = split_error;
            return false;
        }
        if (!tokens.isEmpty()) {
            command = tokens.first();
            QJsonArray parsed_params;
            for (int i = 1; i < tokens.size(); ++i) {
                parsed_params.push_back(consoleTokenToJsonValue(tokens.at(i)));
            }
            params_json = paramsJsonForPrompt(parsed_params);
        }
    }
    if (command.isEmpty()) {
        if (error) *error = QStringLiteral("Enter an RPC method name.");
        return false;
    }
    if (!isSafeRpcMethodName(command)) {
        if (error) *error = QStringLiteral("RPC method names may contain only letters, numbers, and underscores, up to 64 characters.");
        return false;
    }

    constexpr int max_rpc_params_chars = 32768;
    if (params_json.size() > max_rpc_params_chars) {
        if (error) *error = QStringLiteral("RPC parameters are too large for the Nu console. Keep JSON parameter input under %1 characters.")
            .arg(max_rpc_params_chars);
        return false;
    }

    QJsonArray params;
    if (!params_json.isEmpty()) {
        QJsonParseError parse_error;
        const QJsonDocument doc = QJsonDocument::fromJson(params_json.toUtf8(), &parse_error);
        if (parse_error.error != QJsonParseError::NoError || !doc.isArray()) {
            if (error) *error = QStringLiteral("Parameters must be a JSON array, for example: [\"address\", \"message\"]");
            return false;
        }
        params = doc.array();
    }

    if (parsed) {
        parsed->method = command;
        parsed->params = params;
        parsed->prompt = rpcPromptForDisplay(command, paramsJsonForPrompt(params));
    }
    return true;
}

QStringList splitConsolePasteCommands(const QString& text, QString* error)
{
    QString normalized = text.trimmed();
    normalized.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
    normalized.replace(QLatin1Char('\r'), QLatin1Char('\n'));

    QStringList lines;
    for (const QString& line : normalized.split(QLatin1Char('\n'))) {
        const QString clean = line.trimmed();
        if (!clean.isEmpty()) lines.push_back(clean);
    }
    if (lines.size() > 1) return lines;

    // Accept compact paste batches such as:
    // addnode host1 add addnode host2 add
    QString split_error;
    const QStringList tokens = splitConsoleCommandLine(normalized, &split_error);
    if (!split_error.isEmpty()) {
        if (error) *error = split_error;
        return {};
    }
    if (tokens.isEmpty()) return {normalized};
    if (tokens.size() <= 3 || tokens.first().compare(QStringLiteral("addnode"), Qt::CaseInsensitive) != 0) {
        return {normalized};
    }

    QStringList commands;
    int i = 0;
    while (i < tokens.size()) {
        if (i + 2 >= tokens.size() || tokens.at(i).compare(QStringLiteral("addnode"), Qt::CaseInsensitive) != 0) {
            return {normalized};
        }
        const QString command = tokens.at(i + 2).toLower();
        if (command != QLatin1String("add") && command != QLatin1String("remove") && command != QLatin1String("onetry")) {
            return {normalized};
        }
        commands.push_back(QStringLiteral("addnode %1 %2").arg(tokens.at(i + 1), tokens.at(i + 2)));
        i += 3;
    }
    return commands.size() > 1 ? commands : QStringList{normalized};
}

bool rpcMethodTakesSensitiveInput(const QString& method)
{
    const QString lower = method.toLower();
    static const QSet<QString> sensitive_methods{
        QStringLiteral("encryptwallet"),
        QStringLiteral("importdescriptors"),
        QStringLiteral("importmulti"),
        QStringLiteral("importprivkey"),
        QStringLiteral("importwallet"),
        QStringLiteral("sethdseed"),
        QStringLiteral("signmessagewithprivkey"),
        QStringLiteral("walletpassphrase"),
        QStringLiteral("walletpassphrasechange")
    };
    return sensitive_methods.contains(lower)
        || lower.contains(QStringLiteral("passphrase"))
        || lower.contains(QStringLiteral("privkey"));
}

QString rpcPromptForDisplay(const QString& method, const QString& params_json)
{
    if (params_json.isEmpty()) return method;
    if (rpcMethodTakesSensitiveInput(method)) return method + QStringLiteral(" [params redacted]");
    return method + QStringLiteral(" ") + params_json;
}

QString processCommandForDisplayRedacted(const QString& program, const QStringList& args)
{
    QStringList redacted;
    redacted.reserve(args.size());
    bool redact_next = false;
    for (const QString& arg : args) {
        if (redact_next) {
            redacted.push_back(QStringLiteral("[redacted]"));
            redact_next = false;
            continue;
        }
        if (arg == QLatin1String("-p") || arg == QLatin1String("--pass") || arg == QLatin1String("--password")) {
            redacted.push_back(arg);
            redact_next = true;
            continue;
        }
        if (arg.startsWith(QStringLiteral("--pass=")) || arg.startsWith(QStringLiteral("--password="))) {
            redacted.push_back(arg.left(arg.indexOf(QLatin1Char('=')) + 1) + QStringLiteral("[redacted]"));
            continue;
        }
        redacted.push_back(arg);
    }
    return processCommandForDisplay(program, redacted);
}

bool isValidStratumUrl(const QString& pool_url)
{
    static const QRegularExpression stratum_re(QStringLiteral(
        R"(^stratum\+(tcp|ssl)://(\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9.-]+)(?::([0-9]{1,5}))?$)"));
    const QRegularExpressionMatch match = stratum_re.match(pool_url);
    if (!match.hasMatch()) return false;
    if (pool_url.contains(QStringLiteral(".."))) return false;
    const QString port_text = match.captured(3);
    if (port_text.isEmpty()) return true;
    bool ok = false;
    const int port = port_text.toInt(&ok);
    return ok && port > 0 && port <= 65535;
}

bool isHex256(const QString& value)
{
    static const QRegularExpression hash_re(QStringLiteral(R"(^[0-9A-Fa-f]{64}$)"));
    return hash_re.match(value).hasMatch();
}

bool isNonNegativeBlockHeight(const QString& value)
{
    static const QRegularExpression height_re(QStringLiteral(R"(^[0-9]{1,10}$)"));
    if (!height_re.match(value).hasMatch()) return false;
    bool ok = false;
    const qlonglong height = value.toLongLong(&ok);
    return ok && height >= 0 && height <= std::numeric_limits<int>::max();
}

bool isLikelyBase58AddressText(const QString& value)
{
    const QString clean = value.trimmed();
    if (clean.size() < 26 || clean.size() > 64) return false;
    QByteArray payload;
    if (!decodeBase58CheckPayload(clean, &payload) || payload.size() != 21) return false;
    const unsigned char version = static_cast<unsigned char>(payload.at(0));
    switch (version) {
    case 30:  // mainnet P2PKH, D...
    case 50:  // mainnet canonical P2SH, M...
    case 5:   // legacy P2SH, 3...
    case 22:  // tool/BeerWallet-era P2SH, 9.../A...
    case 111: // test/regtest P2PKH
    case 196: // test/regtest legacy P2SH
    case 58:  // test/regtest canonical P2SH
        return true;
    default:
        return false;
    }
}

bool isSafeHttpUrl(const QUrl& url)
{
    const QString scheme = url.scheme().toLower();
    return url.isValid()
        && (scheme == QLatin1String("http") || scheme == QLatin1String("https"))
        && !url.host().isEmpty()
        && url.userInfo().isEmpty();
}

QString stripAnsiControlSequences(QString text)
{
    static const QRegularExpression ansi_re(QStringLiteral(R"(\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~]))"));
    text.remove(ansi_re);
    return text;
}

QString resolvedCpuminerExecutable(const QString& selected_path, QString* note)
{
    const QFileInfo selected_info(selected_path);
    if (note) note->clear();
    if (selected_info.suffix().compare(QStringLiteral("sh"), Qt::CaseInsensitive) != 0) {
        return selected_path;
    }

    const QString candidate = selected_info.dir().filePath(QStringLiteral("cpuminer"));
    if (QFileInfo(candidate).isExecutable()) {
        if (note) {
            *note = QStringLiteral("Nu detected a shell wrapper script and will launch '%1' directly so the UI pool, payout, and thread settings apply.")
                .arg(QDir::toNativeSeparators(candidate));
        }
        return candidate;
    }

    if (note) {
        *note = QStringLiteral("The selected file is a shell wrapper script. Select the actual cpuminer executable instead, or place an executable named cpuminer beside the script.");
    }
    return selected_path;
}
} // namespace

NuRpcService::NuRpcService(QObject* parent)
    : QObject(parent),
      m_network(new QNetworkAccessManager(this)),
      m_update_network(new QNetworkAccessManager(this)),
      m_velopack_updater(new NuVelopackUpdater(this))
{
    m_app_launch_utc = QDateTime::currentDateTimeUtc();
    loadLocalSettings();
    m_debug_disable_core_tcp_sync = !qEnvironmentVariableIsEmpty("DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC");
    m_debug_disable_core_sync = !qEnvironmentVariableIsEmpty("DEFCOIN_NU_DEBUG_DISABLE_CORE_SYNC");
    m_debug_disable_fast_sync = !qEnvironmentVariableIsEmpty("DEFCOIN_NU_DEBUG_DISABLE_FAST_SYNC");
    m_debug_disable_quick_clone = !qEnvironmentVariableIsEmpty("DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE");
    if (m_debug_disable_fast_sync) {
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync disabled by debug launch switch.");
    }
    if (m_debug_disable_quick_clone) {
        m_lan_quick_clone_enabled = false;
        m_lan_quick_clone_status = QStringLiteral("Quick Clone disabled by debug launch switch.");
    }
    appendLaunchDiagnostic(QStringLiteral("Frontend application launched."));
    if (m_debug_disable_core_tcp_sync || m_debug_disable_core_sync || m_debug_disable_fast_sync || m_debug_disable_quick_clone) {
        appendLaunchDiagnostic(QStringLiteral("Debug launch switches: Core TCP block copy=%1, Core P2P sync=%2, UDP fast sync=%3, Quick Clone=%4.")
            .arg((m_debug_disable_core_tcp_sync || m_debug_disable_core_sync) ? QStringLiteral("disabled") : QStringLiteral("enabled"),
                 m_debug_disable_core_sync ? QStringLiteral("disabled for Quick Clone isolation") : QStringLiteral("enabled"),
                 m_debug_disable_fast_sync ? QStringLiteral("disabled") : QStringLiteral("enabled"),
                 m_debug_disable_quick_clone ? QStringLiteral("disabled") : QStringLiteral("enabled")));
    }
    appendLaunchDiagnostic(QStringLiteral("Network preferences: Defcoin-only magic=%1, /Defcoin user-agent filtering=%2, LAN discovery=%3, UPnP=%4.")
        .arg(boolText(m_only_defcoin_magic_bytes),
             boolText(m_only_defcoin_user_agents),
             boolText(m_lan_node_discovery_enabled),
             boolText(m_upnp_connections_enabled)));
    appendLaunchDiagnostic(QStringLiteral("UDP fast sync: %1. This optional peer transport submits received blocks through normal Core validation.")
        .arg(boolText(m_lan_fast_sync_enabled)));
    appendLaunchDiagnostic(QStringLiteral("Quick Clone: %1. When enabled, Nu uses trusted-LAN discovery and guarded public-chain copy scaffolding; wallet data is never copied.")
        .arg(boolText(m_lan_quick_clone_enabled)));
    rebuildNodeMetrics();
    connect(m_network, &QNetworkAccessManager::finished, this, &NuRpcService::handleReply);
    m_uptime.start();

    m_refresh_timer = new QTimer(this);
    m_refresh_timer->setInterval(5000);
    connect(m_refresh_timer, &QTimer::timeout, this, &NuRpcService::refresh);
    m_refresh_timer->start();

    m_traffic_timer = new QTimer(this);
    // Poll once per second for live rates, but keep the chart as one-minute buckets.
    m_traffic_timer->setInterval(1000);
    connect(m_traffic_timer, &QTimer::timeout, this, &NuRpcService::sampleTraffic);
    m_traffic_timer->start();

    m_lan_fast_sync_timer = new QTimer(this);
    m_lan_fast_sync_timer->setInterval(LAN_FAST_SYNC_TIMER_INTERVAL_MS);
    connect(m_lan_fast_sync_timer, &QTimer::timeout, this, &NuRpcService::lanFastSyncTick);
    m_lan_fast_sync_timer->start();

    QTimer::singleShot(0, this, &NuRpcService::refresh);
    QTimer::singleShot(250, this, &NuRpcService::sampleTraffic);
    QTimer::singleShot(500, this, &NuRpcService::lanFastSyncTick);
    QTimer::singleShot(6500, this, [this] {
        if (m_automatic_update_checks_enabled) checkForUpdates(false);
    });
}

NuRpcService::~NuRpcService()
{
    stopMiner();
    stopLanFastSyncSocket();
    stopExplorerTop100Timeline();
    stopHelperProcesses();
    releaseExplorerWriterLock();
    stopOwnedBackend();
}

void NuRpcService::loadLocalSettings()
{
    QSettings legacy_settings(QStringLiteral("Defcoin"), QStringLiteral("Defcoin-Qt"));
    m_only_defcoin_user_agents = legacy_settings.value(QStringLiteral("OnlyDefcoinUserAgents"), true).toBool();
    const QString legacy_explorer_url = legacy_settings.value(QStringLiteral("strThirdPartyTxUrls"), QString()).toString();

    QSettings nu_settings;
    m_mask_balances = nu_settings.value(QStringLiteral("MaskBalances"), false).toBool();
    m_only_defcoin_magic_bytes = nu_settings.value(
        QStringLiteral("OnlyDefcoinMagicBytes"),
        !nu_settings.value(QStringLiteral("LegacyMagicEnabled"), true).toBool()).toBool();
    m_switch_to_defcoin_only_magic_starting_july_2026 = nu_settings.value(QStringLiteral("SwitchToDefcoinOnlyMagicStarting20260701"), true).toBool();
    if (m_switch_to_defcoin_only_magic_starting_july_2026 && QDate::currentDate() >= QDate(2026, 7, 1)) {
        m_only_defcoin_magic_bytes = true;
        nu_settings.setValue(QStringLiteral("OnlyDefcoinMagicBytes"), true);
    }
    m_lan_node_discovery_enabled = nu_settings.value(QStringLiteral("LanNodeDiscoveryEnabled"), false).toBool();
    m_lan_fast_sync_enabled = nu_settings.value(QStringLiteral("LanFastSyncEnabled"), true).toBool();
    const bool quick_clone_was_persisted = nu_settings.value(QStringLiteral("LanQuickCloneEnabled"), false).toBool();
    m_lan_quick_clone_enabled = false;
    m_quick_clone_auto_validate_after = nu_settings.value(QStringLiteral("QuickCloneAutoValidateAfter"), false).toBool();
    if (quick_clone_was_persisted) {
        nu_settings.setValue(QStringLiteral("LanQuickCloneEnabled"), false);
        m_lan_quick_clone_status = QStringLiteral("Quick Clone not requested; trusted-LAN discovery continues in the background.");
    }
    m_advanced_tools_visible = nu_settings.value(QStringLiteral("AdvancedToolsVisible"), false).toBool();
    m_explorer_top100_focused_indexing = nu_settings.value(QStringLiteral("ExplorerTop100FocusedIndexing"), false).toBool();
    m_upnp_connections_enabled = nu_settings.value(QStringLiteral("UpnpConnectionsEnabled"), false).toBool();
    m_lan_node_discovery_notice_acknowledged = nu_settings.value(QStringLiteral("LanNodeDiscoveryNoticeAcknowledged"), false).toBool();
    m_automatic_update_checks_enabled = nu_settings.value(QStringLiteral("AutomaticUpdateChecksEnabled"), true).toBool();
    m_table_copy_delimiter_style = nu_settings.value(QStringLiteral("TableCopyDelimiterStyle"), QStringLiteral("tsv")).toString().toLower();
    if (!QStringList{QStringLiteral("csv"), QStringLiteral("tsv"), QStringLiteral("pipe"), QStringLiteral("semicolon"), QStringLiteral("custom")}.contains(m_table_copy_delimiter_style)) {
        m_table_copy_delimiter_style = QStringLiteral("tsv");
    }
    m_table_copy_custom_delimiter = nu_settings.value(QStringLiteral("TableCopyCustomDelimiter"), QStringLiteral("|")).toString();
    m_table_copy_custom_delimiter = m_table_copy_custom_delimiter.left(15);
    if (m_table_copy_custom_delimiter.isEmpty()) m_table_copy_custom_delimiter = QStringLiteral("|");
    m_log_verbosity = std::clamp(nu_settings.value(QStringLiteral("LogVerbosity"), 0).toInt(), 0, 3);
    m_log_last_search_pattern = nu_settings.value(QStringLiteral("LogLastSearchPattern"), QString()).toString().left(160);
    m_log_search_pattern.clear();
    m_log_remove_pattern.clear();
    nu_settings.remove(QStringLiteral("LogSearchPattern"));
    nu_settings.remove(QStringLiteral("LogRemovePattern"));
    m_forensics_accept_bip141_as_regular = nu_settings.value(QStringLiteral("ForensicsAcceptBip141AsRegular"), true).toBool();
    m_background_close_enabled = nu_settings.value(QStringLiteral("KeepRunningWhenClosedEnabled"), false).toBool();
    m_miner_executable = singleLineLimited(nu_settings.value(QStringLiteral("MinerExecutable"), QString()).toString(), 1024);
    m_miner_pool_url = singleLineLimited(nu_settings.value(QStringLiteral("MinerPoolUrl"), m_miner_pool_url).toString(), 512);
    m_miner_payout_address = singleLineLimited(nu_settings.value(QStringLiteral("MinerPayoutAddress"), QString()).toString(), 128);
    m_miner_password = singleLineLimited(nu_settings.value(QStringLiteral("MinerPassword"), QStringLiteral("x")).toString(), 128);
    if (m_miner_password.isEmpty()) m_miner_password = QStringLiteral("x");
    m_miner_threads = std::clamp(nu_settings.value(QStringLiteral("MinerThreads"), 4).toInt(), 1, 256);
    m_miner_nice_level = std::clamp(nu_settings.value(QStringLiteral("MinerNiceLevel"), 20).toInt(), 0, 20);
    m_miner_status = m_miner_executable.isEmpty() ? QStringLiteral("Select a miner executable before starting.") : QStringLiteral("Miner configured.");
    m_third_party_tx_urls_enabled = nu_settings.value(QStringLiteral("ThirdPartyTxUrlsEnabled"), false).toBool();
    m_third_party_tx_url = normalizedExplorerUrl(nu_settings.value(QStringLiteral("ThirdPartyTxUrl"), legacy_explorer_url).toString());
    m_explorer_mode = nu_settings.value(QStringLiteral("ExplorerMode"), QStringLiteral("internal")).toString().trimmed().toLower();
    if (!QStringList{QStringLiteral("internal"), QStringLiteral("dc903"), QStringLiteral("legacy"), QStringLiteral("custom")}.contains(m_explorer_mode)) {
        m_explorer_mode = QStringLiteral("internal");
    }
    if (m_explorer_mode == QLatin1String("internal")) {
        m_third_party_tx_urls_enabled = false;
    } else {
        m_third_party_tx_urls_enabled = true;
        if (m_explorer_mode == QLatin1String("dc903")) m_third_party_tx_url = explorerPresetUrl(1);
        if (m_explorer_mode == QLatin1String("legacy")) m_third_party_tx_url = explorerPresetUrl(2);
        if (m_explorer_mode == QLatin1String("custom") && m_third_party_tx_url.isEmpty()) {
            m_explorer_mode = QStringLiteral("internal");
            m_third_party_tx_urls_enabled = false;
        }
    }
    loadExplorerRecentLookups();
    loadExplorerContacts();
}

QString NuRpcService::defaultDataDir() const
{
    if (!qEnvironmentVariableIsEmpty("DEFCOIN_DATADIR")) {
        return QString::fromLocal8Bit(qgetenv("DEFCOIN_DATADIR"));
    }
#if defined(Q_OS_WIN)
    const QString appdata = QString::fromLocal8Bit(qgetenv("APPDATA"));
    return QDir(appdata).filePath(QStringLiteral("Defcoin"));
#elif defined(Q_OS_MACOS)
    return QDir(realHomePath()).filePath(QStringLiteral("Library/Application Support/Defcoin"));
#else
    return QDir(realHomePath()).filePath(QStringLiteral(".defcoin"));
#endif
}

void NuRpcService::readDefcoinConf(const QString& conf_path)
{
    QFile file(conf_path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) continue;
        const int eq = line.indexOf(QLatin1Char('='));
        if (eq < 0) continue;
        const QString key = line.left(eq).trimmed().toLower();
        const QString value = line.mid(eq + 1).trimmed();
        if (key == QLatin1String("rpcconnect")) m_rpc_host = value;
        if (key == QLatin1String("rpcport")) m_rpc_port = value.toInt();
        if (key == QLatin1String("rpcuser")) m_rpc_user = value;
        if (key == QLatin1String("rpcpassword")) m_rpc_password = value;
        if (key == QLatin1String("blockexplorer") && m_third_party_tx_url.trimmed().isEmpty()) {
            m_third_party_tx_url = normalizedExplorerUrl(value);
        }
    }
}

bool NuRpcService::readCookie()
{
    QFile file(QDir(m_data_dir).filePath(QStringLiteral(".cookie")));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return false;
    const QString cookie = QString::fromUtf8(file.readAll()).trimmed();
    const int colon = cookie.indexOf(QLatin1Char(':'));
    if (colon <= 0) return false;
    m_rpc_user = cookie.left(colon);
    m_rpc_password = cookie.mid(colon + 1);
    return true;
}

QString NuRpcService::backendBinaryPath() const
{
    if (!qEnvironmentVariableIsEmpty("DEFCOIN_BACKEND_PATH")) {
        const QString path = QString::fromLocal8Bit(qgetenv("DEFCOIN_BACKEND_PATH"));
        if (QFileInfo::exists(path) && QFileInfo(path).isExecutable()) return path;
    }

    const QString app_dir = QCoreApplication::applicationDirPath();
#if defined(Q_OS_MACOS)
    const QString bundled = QDir(app_dir).filePath(QStringLiteral("../Resources/nu/bin/defcoind"));
#elif defined(Q_OS_WIN)
    const QString bundled = QDir(app_dir).filePath(QStringLiteral("nu/bin/defcoind.exe"));
#else
    const QString bundled = QDir(app_dir).filePath(QStringLiteral("nu/bin/defcoind"));
#endif
    if (QFileInfo::exists(bundled) && QFileInfo(bundled).isExecutable()) return bundled;

    const QString sibling = QDir(app_dir).filePath(
#if defined(Q_OS_WIN)
        QStringLiteral("defcoind.exe")
#else
        QStringLiteral("defcoind")
#endif
    );
    if (QFileInfo::exists(sibling) && QFileInfo(sibling).isExecutable()) return sibling;

    return QString();
}

void NuRpcService::appendLaunchDiagnostic(const QString& message)
{
    QString clean_message = message.trimmed();
    if (clean_message.startsWith(QStringLiteral("Nu startup:"), Qt::CaseInsensitive)) {
        clean_message = clean_message.mid(QStringLiteral("Nu startup:").size()).trimmed();
    }
    if (clean_message.isEmpty()) return;
    if (!m_launch_diagnostics_section_started) {
        const QString marker = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
            + QStringLiteral(" ----- Nu startup diagnostics -----");
        const int marker_debug_line = appendDebugLogLineFromNu(QStringLiteral("----- Nu startup diagnostics -----"));
        appendLogLine(marker, marker_debug_line);
        m_launch_diagnostics_section_started = true;
    }
    const QString line = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
        + QStringLiteral(" Nu startup: ") + clean_message;
    const int debug_line = appendDebugLogLineFromNu(QStringLiteral("Nu startup: %1").arg(clean_message));
    if (m_log_lines.isEmpty() || m_log_lines.constLast() != line) {
        appendLogLine(line, debug_line);
    }
    trimLogLines();
    rebuildNodeMetrics();
    Q_EMIT logChanged();
    Q_EMIT stateChanged();
}

int NuRpcService::appendDebugLogLineFromNu(const QString& message)
{
    if (message.trimmed().isEmpty()) return 0;

    const QString path = debugLogPath();
    const QFileInfo info(path);
    QDir().mkpath(info.absolutePath());

    int next_line_number = 0;
    const qint64 size_before = QFileInfo(path).exists() ? QFileInfo(path).size() : 0;
    if (m_debug_log_append_path == path
        && m_debug_log_append_size_hint == size_before
        && m_debug_log_append_line_hint > 0) {
        next_line_number = m_debug_log_append_line_hint + 1;
    } else {
        QFile read_file(path);
        int existing_lines = 0;
        if (read_file.open(QIODevice::ReadOnly)) {
            while (!read_file.atEnd()) {
                existing_lines += read_file.read(64 * 1024).count('\n');
            }
        }
        next_line_number = existing_lines + 1;
    }

    QFile file(path);
    if (!file.open(QIODevice::Append | QIODevice::Text)) return 0;

    QTextStream out(&file);
    out << QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyy-MM-ddTHH:mm:ssZ"))
        << ' ' << message << '\n';
    out.flush();
    file.flush();

    m_debug_log_append_path = path;
    m_debug_log_append_size_hint = QFileInfo(path).size();
    m_debug_log_append_line_hint = next_line_number;
    return next_line_number;
}

void NuRpcService::appendLogLine(const QString& line, int debug_log_line_number)
{
    m_log_lines.push_back(line);
    m_log_line_numbers.push_back(debug_log_line_number > 0 ? QVariant(debug_log_line_number) : QVariant());
}

void NuRpcService::trimLogLines()
{
    while (m_log_lines.size() > 5000) {
        m_log_lines.removeFirst();
        if (!m_log_line_numbers.isEmpty()) m_log_line_numbers.removeFirst();
    }
    while (m_log_line_numbers.size() > m_log_lines.size()) m_log_line_numbers.removeLast();
    while (m_log_line_numbers.size() < m_log_lines.size()) m_log_line_numbers.push_front(QVariant());
}

void NuRpcService::beginBackendDebugLogSection(bool write_to_debug_log)
{
    if (m_backend_log_section_started) return;

    const QString marker = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
        + QStringLiteral(" ----- Backend debug.log -----");
    if (m_log_lines.isEmpty() || m_log_lines.constLast() != marker) {
        appendLogLine(marker);
    }
    if (write_to_debug_log) {
        const int debug_line = appendDebugLogLineFromNu(QStringLiteral("----- Backend debug.log follows -----"));
        if (!m_log_line_numbers.isEmpty() && !m_log_line_numbers.last().isValid()) {
            m_log_line_numbers.last() = debug_line > 0 ? QVariant(debug_line) : QVariant();
        }
    }
    m_backend_log_section_started = true;
}

QStringList NuRpcService::backendRuntimeDiagnostics(const QString& binary) const
{
    QStringList diagnostics;
    const QDir backend_dir(QFileInfo(binary).absolutePath());
    diagnostics << QStringLiteral("Backend path: %1").arg(QDir::toNativeSeparators(binary));
    const QString cli_name =
#if defined(Q_OS_WIN)
        QStringLiteral("defcoin-cli.exe");
#else
        QStringLiteral("defcoin-cli");
#endif
    const QString cli_path = backend_dir.filePath(cli_name);
    diagnostics << QStringLiteral("CLI path: %1")
        .arg(QFileInfo::exists(cli_path) ? QDir::toNativeSeparators(cli_path) : QStringLiteral("not bundled"));
    diagnostics << QStringLiteral("Backend working directory: %1").arg(QDir::toNativeSeparators(backend_dir.absolutePath()));
    diagnostics << QStringLiteral("Data directory: %1").arg(QDir::toNativeSeparators(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir));
    diagnostics << QStringLiteral("Debug log path: %1").arg(QDir::toNativeSeparators(QDir(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir).filePath(QStringLiteral("debug.log"))));
    diagnostics << chainStorageDiagnosticLine(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir);
#if defined(Q_OS_WIN)
    const QFileInfoList runtime_files = backend_dir.entryInfoList({QStringLiteral("*.dll")}, QDir::Files, QDir::Name);
    QStringList runtime_names;
    for (const QFileInfo& runtime_file : runtime_files) {
        runtime_names << runtime_file.fileName();
    }
    diagnostics << QStringLiteral("Backend runtime DLLs in nu/bin: %1")
        .arg(runtime_names.isEmpty() ? QStringLiteral("none bundled") : runtime_names.join(QStringLiteral(", ")));
    if (runtime_names.isEmpty()) {
        diagnostics << QStringLiteral("Backend runtime note: bundled defcoind may be static apart from Windows system and UCRT libraries.");
    }
#endif
    return diagnostics;
}

bool NuRpcService::ensureBackendStarted()
{
    if (m_backend_start_attempted || !qEnvironmentVariableIsEmpty("DEFCOIN_NU_NO_BACKEND_AUTOSTART")) {
        return false;
    }

    appendLaunchDiagnostic(QStringLiteral("Backend autostart requested."));
    const QString binary = backendBinaryPath();
    if (binary.isEmpty()) {
        const QString message = QStringLiteral("Bundled Defcoin backend was not found. Expected a defcoind executable inside this app.");
        appendLaunchDiagnostic(message);
        m_last_error = message;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return false;
    }

    QDir().mkpath(m_data_dir);
    pruneCoreWalletAutoloadSettings();
    for (const QString& diagnostic : backendRuntimeDiagnostics(binary)) {
        appendLaunchDiagnostic(diagnostic);
    }

    const QString working_dir = QFileInfo(binary).absolutePath();
    QProcess version_probe;
    version_probe.setWorkingDirectory(working_dir);
    version_probe.start(binary, {QStringLiteral("-version")});
    if (!version_probe.waitForStarted(3000)) {
        const QString message = QStringLiteral("Defcoin backend preflight failed to start: %1").arg(version_probe.errorString());
        m_backend_start_attempted = true;
        m_last_error = message;
        appendLaunchDiagnostic(message);
        return false;
    }
    if (!version_probe.waitForFinished(5000)) {
        version_probe.kill();
        version_probe.waitForFinished(1000);
        appendLaunchDiagnostic(QStringLiteral("Defcoin backend preflight timed out while running -version."));
    } else {
        const QString output = QString::fromUtf8(version_probe.readAllStandardOutput()).trimmed();
        const QString error_output = QString::fromUtf8(version_probe.readAllStandardError()).trimmed();
        if (version_probe.exitStatus() != QProcess::NormalExit || version_probe.exitCode() != 0) {
            const QString message = QStringLiteral("Defcoin backend preflight exited with code %1. %2%3")
                .arg(version_probe.exitCode())
                .arg(output.left(700))
                .arg(error_output.isEmpty() ? QString() : QStringLiteral(" ") + error_output.left(700));
            m_backend_start_attempted = true;
            m_last_error = message;
            appendLaunchDiagnostic(message);
            return false;
        }
        appendLaunchDiagnostic(output.isEmpty()
            ? QStringLiteral("Defcoin backend -version preflight succeeded.")
            : QStringLiteral("Defcoin backend -version preflight: %1").arg(output.section(QLatin1Char('\n'), 0, 0)));
    }

    const bool effective_lan_node_discovery_enabled = m_lan_node_discovery_enabled;
    const bool effective_network_active = !m_debug_disable_core_sync;
    const bool effective_lan_fast_sync_enabled = m_lan_fast_sync_enabled && !m_debug_disable_fast_sync;

    const bool listen_for_peers =
#if defined(Q_OS_MACOS)
        !m_debug_disable_core_sync && (effective_lan_node_discovery_enabled || m_upnp_connections_enabled);
#else
        true;
#endif

    QSettings nu_settings;
    if (nu_settings.contains(QStringLiteral("RepairWitnessFromHeight"))) {
        nu_settings.remove(QStringLiteral("RepairWitnessFromHeight"));
        nu_settings.sync();
        appendLaunchDiagnostic(QStringLiteral("Cleared legacy startup witness repair request. Witness storage inspection now runs from the Forensics scan only after user confirmation."));
    }

    QStringList args;
    args << QStringLiteral("-datadir=%1").arg(QDir::toNativeSeparators(m_data_dir))
         << QStringLiteral("-debuglogfile=%1").arg(QDir::toNativeSeparators(QDir(m_data_dir).filePath(QStringLiteral("debug.log"))))
         << QStringLiteral("-server=1")
         << QStringLiteral("-listen=%1").arg(listen_for_peers ? 1 : 0)
         << QStringLiteral("-networkactive=%1").arg(effective_network_active ? 1 : 0)
         << QStringLiteral("-defcoindisablecoretcpblocks=%1").arg((m_debug_disable_core_tcp_sync || m_debug_disable_core_sync) ? 1 : 0)
         << QStringLiteral("-acceptlegacymagic=%1").arg(m_only_defcoin_magic_bytes ? 0 : 1)
         << QStringLiteral("-allowlannodediscovery=%1").arg(effective_lan_node_discovery_enabled ? 1 : 0)
         << QStringLiteral("-defcoinfastsync=%1").arg(effective_lan_fast_sync_enabled ? 1 : 0)
         << QStringLiteral("-upnp=%1").arg(m_upnp_connections_enabled ? 1 : 0)
         << QStringLiteral("-rpcport=%1").arg(m_rpc_port)
         << QStringLiteral("-rpcbind=127.0.0.1")
         << QStringLiteral("-rpcallowip=127.0.0.1");
    QString dbcache_note;
    const QString dbcache_arg = autoDbCacheLaunchArg(m_data_dir, &dbcache_note);
    if (!dbcache_note.isEmpty()) appendLaunchDiagnostic(dbcache_note);
    if (!dbcache_arg.isEmpty()) args << dbcache_arg;
    appendLaunchDiagnostic(QStringLiteral("Historical Defcoin SegWit is active; post-activation blocks require witness-capable peers. Witness storage repair is never started automatically by Nu."));

    const QFileInfo legacy_default_wallet(QDir(m_data_dir).filePath(QStringLiteral("wallet.dat")));
    const QDir nested_wallets_dir(QDir(m_data_dir).filePath(QStringLiteral("wallets")));
    if (legacy_default_wallet.isFile()) {
        args << QStringLiteral("-walletdir=%1").arg(QDir::toNativeSeparators(m_data_dir))
             << QStringLiteral("-wallet=");
        appendLaunchDiagnostic(QStringLiteral("Legacy top-level wallet.dat detected; backend launch includes the old default wallet so balances remain visible after new wallets are created."));

        if (nested_wallets_dir.exists()) {
            const QFileInfoList wallet_entries = nested_wallets_dir.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot, QDir::Name);
            for (const QFileInfo& entry : wallet_entries) {
                const QString leaf = entry.fileName();
                if (!isValidWalletMenuName(leaf) || !isLikelyLoadableWalletMenuName(leaf)) continue;

                bool looks_like_wallet = false;
                if (entry.isDir()) {
                    looks_like_wallet = QFileInfo(QDir(entry.absoluteFilePath()).filePath(QStringLiteral("wallet.dat"))).isFile();
                } else if (entry.isFile()) {
                    looks_like_wallet = leaf.compare(QStringLiteral("wallet.dat"), Qt::CaseInsensitive) == 0 || leaf.endsWith(QStringLiteral(".dat"), Qt::CaseInsensitive);
                }
                if (looks_like_wallet) {
                    args << QStringLiteral("-wallet=wallets/%1").arg(leaf);
                }
            }
        }
    }

    if (!effective_lan_node_discovery_enabled) {
        args << QStringLiteral("-discover=0");
        appendLaunchDiagnostic(QStringLiteral("LAN node discovery is disabled; backend launch skips local interface peer discovery before networking starts."));
    } else {
        args << QStringLiteral("-discover=1");
    }
    if (!listen_for_peers) {
        appendLaunchDiagnostic(QStringLiteral("Inbound peer listening is disabled on macOS until LAN node discovery or UPnP is enabled, avoiding the Local Network permission prompt on first launch."));
    }

    args << QStringLiteral("-seednode=seed.defcoin.io")
         << QStringLiteral("-seednode=seed.defcoin.mikej.tech")
         << QStringLiteral("-seednode=seed.defcoin.dc903.org:10332")
         << QStringLiteral("-seednode=seed.defcoincore.org")
         << QStringLiteral("-seednode=seed.defcoin-ng.org");

    if (m_backend_process == nullptr) {
        m_backend_process = new QProcess(this);
        m_backend_process->setProcessChannelMode(QProcess::SeparateChannels);
        m_backend_process->setStandardOutputFile(QProcess::nullDevice());
        m_backend_process->setStandardErrorFile(QProcess::nullDevice());
        connect(m_backend_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
            Q_UNUSED(error);
            if (!m_backend_started_by_nu) return;
            appendLaunchDiagnostic(QStringLiteral("Defcoin backend process error: %1").arg(m_backend_process->errorString()));
        });
        connect(m_backend_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this, [this](int exit_code, QProcess::ExitStatus status) {
            if (!m_backend_started_by_nu) return;
            appendLaunchDiagnostic(QStringLiteral("Defcoin backend process exited with code %1%2.")
                .arg(exit_code)
                .arg(status == QProcess::CrashExit ? QStringLiteral(" after a crash") : QString()));
            m_backend_started_by_nu = false;
            m_backend_pid = 0;
            Q_EMIT stateChanged();
        });
    }
    m_backend_process->setWorkingDirectory(working_dir);
    m_backend_process->setProgram(binary);
    m_backend_process->setArguments(args);
    appendLaunchDiagnostic(QStringLiteral("Backend launch arguments: %1").arg(args.join(QLatin1Char(' '))));
    m_backend_process->start();
    const bool started = m_backend_process->waitForStarted(5000);
    const qint64 pid = started ? m_backend_process->processId() : 0;
    m_backend_start_attempted = true;

    if (started) {
        m_backend_started_by_nu = true;
        m_backend_pid = pid;
        m_connection_status = QStringLiteral("Starting backend");
        m_metric_network_active = QStringLiteral("Starting");
        m_last_error = QStringLiteral("Starting Defcoin backend from %1%2")
            .arg(QFileInfo(binary).fileName(),
                 pid > 0 ? QStringLiteral(" (pid %1)").arg(pid) : QString());
        appendLaunchDiagnostic(m_last_error);
        beginBackendDebugLogSection(true);
        Q_EMIT logChanged();
        rebuildNodeMetrics();
        QTimer::singleShot(1500, this, &NuRpcService::refresh);
        Q_EMIT stateChanged();
        return true;
    }

    const QString process_error = m_backend_process ? m_backend_process->errorString() : QString();
    const QString message = QStringLiteral("Defcoin backend launch failed from %1. %2Check executable permissions and bundled runtime libraries.")
                                .arg(QDir::toNativeSeparators(binary),
                                     process_error.isEmpty() ? QString() : process_error + QStringLiteral(" "));
    m_last_error = message;
    appendLaunchDiagnostic(message);
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
    return false;
}

bool NuRpcService::loadRpcSettings()
{
    m_data_dir = defaultDataDir();
    m_rpc_host = qEnvironmentVariableIsEmpty("DEFCOIN_RPC_HOST") ? QStringLiteral("127.0.0.1") : QString::fromLocal8Bit(qgetenv("DEFCOIN_RPC_HOST"));
    m_rpc_port = qEnvironmentVariableIsEmpty("DEFCOIN_RPC_PORT") ? 9332 : QString::fromLocal8Bit(qgetenv("DEFCOIN_RPC_PORT")).toInt();
    m_rpc_user = QString::fromLocal8Bit(qgetenv("DEFCOIN_RPC_USER"));
    m_rpc_password = QString::fromLocal8Bit(qgetenv("DEFCOIN_RPC_PASSWORD"));

    readDefcoinConf(QDir(m_data_dir).filePath(QStringLiteral("defcoin.conf")));
    loadReceiveRequests();
    if ((m_rpc_user.isEmpty() || m_rpc_password.isEmpty()) && !readCookie()) {
        if (ensureBackendStarted()) {
            setError(QStringLiteral("Starting Defcoin backend. The wallet will connect when RPC credentials are ready."));
            return false;
        }
        if (m_backend_started_by_nu && m_backend_process && m_backend_process->state() != QProcess::NotRunning) {
            setError(QStringLiteral("Starting Defcoin backend. The wallet will connect when RPC credentials are ready."));
            return false;
        }
        setError(QStringLiteral("RPC credentials not found. Start Defcoin Core with RPC enabled or set DEFCOIN_RPC_USER / DEFCOIN_RPC_PASSWORD."));
        return false;
    }
    return true;
}

bool NuRpcService::shouldAutostartAfterTransportError(QNetworkReply* reply) const
{
    return isBackendTransportError(reply->error()) &&
        !m_backend_start_attempted &&
        qEnvironmentVariableIsEmpty("DEFCOIN_NU_NO_BACKEND_AUTOSTART");
}

QUrl NuRpcService::rpcUrl(bool wallet_scoped) const
{
    QUrl url;
    url.setScheme(QStringLiteral("http"));
    url.setHost(m_rpc_host);
    url.setPort(m_rpc_port);
    if (wallet_scoped && m_wallet_selected) {
        url.setPath(QStringLiteral("/wallet/") + walletRpcNameFor(m_wallet_name), QUrl::DecodedMode);
    }
    return url;
}

QUrl NuRpcService::rpcUrlForWallet(const QString& wallet_name) const
{
    QUrl url;
    url.setScheme(QStringLiteral("http"));
    url.setHost(m_rpc_host);
    url.setPort(m_rpc_port);
    url.setPath(QStringLiteral("/wallet/") + walletRpcNameFor(wallet_name), QUrl::DecodedMode);
    return url;
}

QString NuRpcService::walletRpcNameFor(const QString& wallet_name) const
{
    const QString canonical = normalizedWalletListName(wallet_name);
    if (m_wallet_rpc_name_by_canonical.contains(canonical)) {
        return m_wallet_rpc_name_by_canonical.value(canonical);
    }
    if (canonical.isEmpty()) {
        const QString data_dir = m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir;
        const QDir dir(data_dir);
        if (!QFileInfo::exists(dir.filePath(QStringLiteral("wallet.dat"))) &&
            QFileInfo::exists(dir.filePath(QStringLiteral("wallets/wallet.dat")))) {
            return QStringLiteral("wallet.dat");
        }
        return QString();
    }
    return wallet_name.trimmed();
}

QString NuRpcService::walletLoadNameFor(const QString& wallet_name) const
{
    const QString canonical = normalizedWalletListName(wallet_name);
    if (canonical.isEmpty()) {
        const QString data_dir = m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir;
        const QDir dir(data_dir);
        if (!QFileInfo::exists(dir.filePath(QStringLiteral("wallet.dat"))) &&
            QFileInfo::exists(dir.filePath(QStringLiteral("wallets/wallet.dat")))) {
            return QStringLiteral("wallet.dat");
        }
        return QString();
    }
    return wallet_name.trimmed();
}

bool NuRpcService::walletAutoloadEntryExists(const QString& wallet_name) const
{
    QString normalized = normalizedWalletListName(wallet_name);
    normalized.replace(QLatin1Char('\\'), QLatin1Char('/'));
    const QString data_dir_path = m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir;
    const QDir data_dir(data_dir_path);

    if (normalized.isEmpty()) return walletDefaultDatExists(data_dir_path);
    if (!isLikelyLoadableWalletMenuName(normalized)) return false;

    QString leaf = normalized;
    if (leaf.startsWith(QStringLiteral("wallets/"))) {
        leaf = leaf.mid(QStringLiteral("wallets/").size());
    }
    if (!isLikelyLoadableWalletMenuName(leaf)) return false;

    QStringList candidates;
    if (normalized.startsWith(QStringLiteral("wallets/"))) {
        candidates << data_dir.filePath(normalized);
    } else {
        candidates << data_dir.filePath(QStringLiteral("wallets/") + leaf)
                   << data_dir.filePath(leaf);
    }

    for (const QString& candidate : candidates) {
        const QFileInfo info(candidate);
        if (info.isDir() && QFileInfo(QDir(candidate).filePath(QStringLiteral("wallet.dat"))).isFile()) {
            return true;
        }
        if (info.isFile() && (leaf.compare(QStringLiteral("wallet.dat"), Qt::CaseInsensitive) == 0 ||
                              leaf.endsWith(QStringLiteral(".dat"), Qt::CaseInsensitive))) {
            return true;
        }
    }
    return false;
}

void NuRpcService::pruneCoreWalletAutoloadSettings(const QStringList& force_remove)
{
    const QString data_dir_path = m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir;
    const QString settings_path = QDir(data_dir_path).filePath(QStringLiteral("settings.json"));
    QFile file(settings_path);
    if (!file.exists()) return;
    if (!file.open(QIODevice::ReadOnly)) {
        appendLaunchDiagnostic(QStringLiteral("Core wallet startup settings could not be read for cleanup."));
        return;
    }

    QJsonParseError parse_error;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parse_error);
    file.close();
    if (parse_error.error != QJsonParseError::NoError || !document.isObject()) {
        appendLaunchDiagnostic(QStringLiteral("Core wallet startup settings were not valid JSON; leaving them unchanged."));
        return;
    }

    QJsonObject object = document.object();
    const QJsonValue wallet_value = object.value(QStringLiteral("wallet"));
    if (!wallet_value.isArray()) return;

    QSet<QString> forced;
    for (const QString& value : force_remove) forced.insert(normalizedWalletListName(value));

    QJsonArray kept;
    QSet<QString> seen;
    int removed = 0;
    const QJsonArray wallets = wallet_value.toArray();
    for (const QJsonValue& value : wallets) {
        if (!value.isString()) {
            ++removed;
            continue;
        }
        QString wallet = normalizedWalletListName(value.toString());
        wallet.replace(QLatin1Char('\\'), QLatin1Char('/'));
        const QString leaf = wallet.startsWith(QStringLiteral("wallets/"))
            ? wallet.mid(QStringLiteral("wallets/").size())
            : wallet;
        const QString canonical = leaf == QLatin1String("wallet.dat") ? QString() : leaf;
        if (forced.contains(wallet) || forced.contains(leaf) || forced.contains(canonical)) {
            ++removed;
            continue;
        }
        if (!walletAutoloadEntryExists(wallet)) {
            ++removed;
            continue;
        }
        if (seen.contains(canonical)) {
            ++removed;
            continue;
        }
        seen.insert(canonical);
        kept.push_back(canonical);
    }

    if (removed == 0 && kept.size() == wallets.size()) return;
    if (kept.isEmpty()) {
        object.remove(QStringLiteral("wallet"));
    } else {
        object.insert(QStringLiteral("wallet"), kept);
    }

    QSaveFile save_file(settings_path);
    if (!save_file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        appendLaunchDiagnostic(QStringLiteral("Core wallet startup settings could not be opened for cleanup."));
        return;
    }
    save_file.write(QJsonDocument(object).toJson(QJsonDocument::Indented));
    if (!save_file.commit()) {
        appendLaunchDiagnostic(QStringLiteral("Core wallet startup settings cleanup could not be saved."));
        return;
    }

    appendLaunchDiagnostic(QStringLiteral("Pruned %1 stale wallet startup entr%2 from Core settings.")
        .arg(removed)
        .arg(removed == 1 ? QStringLiteral("y") : QStringLiteral("ies")));
}

void NuRpcService::rpcCall(const QString& method, const QJsonArray& params, bool wallet_scoped, RpcCallback callback)
{
    if (!loadRpcSettings()) {
        callback(QJsonValue(), m_last_error);
        return;
    }

    const int id = m_next_id++;
    QJsonObject request_obj;
    request_obj.insert(QStringLiteral("jsonrpc"), QStringLiteral("1.0"));
    request_obj.insert(QStringLiteral("id"), id);
    request_obj.insert(QStringLiteral("method"), method);
    request_obj.insert(QStringLiteral("params"), params);

    QNetworkRequest request(rpcUrl(wallet_scoped));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    const QByteArray auth = QStringLiteral("%1:%2").arg(m_rpc_user, m_rpc_password).toUtf8().toBase64();
    request.setRawHeader("Authorization", "Basic " + auth);

    m_pending.insert(id, PendingCall{method, std::move(callback)});
    QNetworkReply* reply = m_network->post(request, QJsonDocument(request_obj).toJson(QJsonDocument::Compact));
    reply->setProperty("nuRpcId", id);
}

void NuRpcService::rpcCallForWallet(const QString& method, const QJsonArray& params, const QString& wallet_name, RpcCallback callback)
{
    if (!loadRpcSettings()) {
        callback(QJsonValue(), m_last_error);
        return;
    }

    const int id = m_next_id++;
    QJsonObject request_obj;
    request_obj.insert(QStringLiteral("jsonrpc"), QStringLiteral("1.0"));
    request_obj.insert(QStringLiteral("id"), id);
    request_obj.insert(QStringLiteral("method"), method);
    request_obj.insert(QStringLiteral("params"), params);

    QNetworkRequest request(rpcUrlForWallet(wallet_name));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    const QByteArray auth = QStringLiteral("%1:%2").arg(m_rpc_user, m_rpc_password).toUtf8().toBase64();
    request.setRawHeader("Authorization", "Basic " + auth);

    m_pending.insert(id, PendingCall{method, std::move(callback)});
    QNetworkReply* reply = m_network->post(request, QJsonDocument(request_obj).toJson(QJsonDocument::Compact));
    reply->setProperty("nuRpcId", id);
}

void NuRpcService::rpcBatchCall(const QVector<QPair<QString, QJsonArray>>& calls,
                                bool wallet_scoped,
                                RpcBatchCallback callback)
{
    if (calls.isEmpty()) {
        callback({}, {}, QString());
        return;
    }
    if (!loadRpcSettings()) {
        callback({}, {}, m_last_error);
        return;
    }
    if (calls.size() == 1) {
        rpcBatchCallAsSingles(calls, wallet_scoped, std::move(callback));
        return;
    }

    QJsonArray batch;
    QHash<int, int> id_to_index;
    for (int i = 0; i < calls.size(); ++i) {
        const int id = m_next_id++;
        id_to_index.insert(id, i);
        QJsonObject request_obj;
        request_obj.insert(QStringLiteral("jsonrpc"), QStringLiteral("1.0"));
        request_obj.insert(QStringLiteral("id"), id);
        request_obj.insert(QStringLiteral("method"), calls.at(i).first);
        request_obj.insert(QStringLiteral("params"), calls.at(i).second);
        batch.append(request_obj);
    }

    QNetworkRequest request(rpcUrl(wallet_scoped));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    const QByteArray auth = QStringLiteral("%1:%2").arg(m_rpc_user, m_rpc_password).toUtf8().toBase64();
    request.setRawHeader("Authorization", "Basic " + auth);

    const QVector<QPair<QString, QJsonArray>> calls_copy = calls;
    QNetworkReply* reply = m_network->post(request, QJsonDocument(batch).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, id_to_index, count = calls.size(), calls_copy, wallet_scoped, callback = std::move(callback)]() mutable {
        QVector<QJsonValue> results(count);
        QStringList errors;
        errors.fill(QString(), count);

        if (reply->error() != QNetworkReply::NoError) {
            QString network_error = reply->errorString();
            if (m_backend_start_attempted && !m_rpc_connected && isBackendTransportError(reply->error())) {
                network_error = QStringLiteral("Starting Defcoin backend. The wallet will connect when RPC is ready.");
                QTimer::singleShot(2500, this, &NuRpcService::refresh);
            }
            reply->deleteLater();
            callback(results, errors, network_error);
            return;
        }

        QJsonParseError parse_error;
        const int http_status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QString content_type = reply->header(QNetworkRequest::ContentTypeHeader).toString();
        const QByteArray body = reply->readAll();
        const QJsonDocument doc = QJsonDocument::fromJson(body, &parse_error);
        reply->deleteLater();
        if (parse_error.error != QJsonParseError::NoError || !doc.isArray()) {
            QString preview = QString::fromUtf8(body.left(240)).simplified();
            if (preview.isEmpty()) preview = QStringLiteral("(empty body)");
            const QString malformed_message = QStringLiteral("RPC batch returned malformed JSON: %1. HTTP %2, content-type \"%3\", %4 bytes, preview: %5")
                .arg(parse_error.errorString())
                .arg(http_status > 0 ? QString::number(http_status) : QStringLiteral("unknown"))
                .arg(content_type.isEmpty() ? QStringLiteral("unknown") : content_type)
                .arg(body.size())
                .arg(preview);
            rpcBatchCallAsSingles(calls_copy, wallet_scoped, [callback = std::move(callback), malformed_message](const QVector<QJsonValue>& single_results,
                                                                                                                const QStringList& single_errors,
                                                                                                                const QString& single_error) mutable {
                if (!single_error.isEmpty()) {
                    callback(single_results, single_errors, malformed_message + QStringLiteral("; single-call fallback failed: ") + single_error);
                    return;
                }
                callback(single_results, single_errors, QString());
            });
            return;
        }

        for (const QJsonValue& value : doc.array()) {
            const QJsonObject object = value.toObject();
            const int id = object.value(QStringLiteral("id")).toInt(-1);
            if (!id_to_index.contains(id)) continue;
            const int index = id_to_index.value(id);
            const QJsonValue error_value = object.value(QStringLiteral("error"));
            if (!error_value.isNull() && !error_value.isUndefined()) {
                const QJsonObject error_obj = error_value.toObject();
                const QString message = error_obj.value(QStringLiteral("message")).toString();
                errors[index] = message.isEmpty()
                    ? QString::fromUtf8(QJsonDocument(error_obj).toJson(QJsonDocument::Compact))
                    : message;
            } else {
                results[index] = object.value(QStringLiteral("result"));
            }
        }

        callback(results, errors, QString());
    });
}

void NuRpcService::rpcBatchCallAsSingles(const QVector<QPair<QString, QJsonArray>>& calls,
                                         bool wallet_scoped,
                                         RpcBatchCallback callback)
{
    const int count = calls.size();
    QVector<QJsonValue> empty_results(count);
    QStringList empty_errors;
    empty_errors.fill(QString(), count);
    if (calls.isEmpty()) {
        callback(empty_results, empty_errors, QString());
        return;
    }

    auto results = std::make_shared<QVector<QJsonValue>>(count);
    auto errors = std::make_shared<QStringList>();
    errors->fill(QString(), count);
    auto index = std::make_shared<int>(0);
    auto callback_ptr = std::make_shared<RpcBatchCallback>(std::move(callback));
    auto run_next = std::make_shared<std::function<void()>>();
    *run_next = [this, calls, wallet_scoped, results, errors, index, callback_ptr, run_next]() mutable {
        if (*index >= calls.size()) {
            (*callback_ptr)(*results, *errors, QString());
            return;
        }
        const int current = *index;
        const QPair<QString, QJsonArray> call = calls.at(current);
        rpcCall(call.first, call.second, wallet_scoped, [results, errors, index, callback_ptr, run_next, current](const QJsonValue& result, const QString& error) mutable {
            if (!error.isEmpty()) {
                (*errors)[current] = error;
            } else {
                (*results)[current] = result;
            }
            ++(*index);
            (*run_next)();
        });
    };
    (*run_next)();
}

void NuRpcService::handleReply(QNetworkReply* reply)
{
    const QByteArray body = reply->readAll();
    const int http_status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QString content_type = reply->header(QNetworkRequest::ContentTypeHeader).toString();
    reply->deleteLater();

    bool property_id_ok = false;
    int id = reply->property("nuRpcId").toInt(&property_id_ok);
    QJsonParseError parse_error;
    const QJsonDocument doc = QJsonDocument::fromJson(body, &parse_error);
    const QJsonObject obj = doc.isObject() ? doc.object() : QJsonObject();
    if (!property_id_ok) {
        id = obj.value(QStringLiteral("id")).toInt();
    }
    PendingCall call = m_pending.take(id);
    if (!call.callback) return;

    QString error;
    if (reply->error() != QNetworkReply::NoError) {
        error = reply->errorString();
        if (!body.isEmpty() && doc.isObject()) {
            const QJsonValue rpc_error = obj.value(QStringLiteral("error"));
            if (rpc_error.isObject()) {
                error = rpc_error.toObject().value(QStringLiteral("message")).toString(error);
            }
        }
        if (shouldAutostartAfterTransportError(reply) && ensureBackendStarted()) {
            error = QStringLiteral("Starting Defcoin backend. The wallet will connect when RPC is ready.");
            QTimer::singleShot(2500, this, &NuRpcService::refresh);
        } else if (m_backend_start_attempted && !m_rpc_connected && isBackendTransportError(reply->error())) {
            error = QStringLiteral("Starting Defcoin backend. The wallet will connect when RPC is ready.");
            QTimer::singleShot(2500, this, &NuRpcService::refresh);
        }
    } else if (parse_error.error != QJsonParseError::NoError || !doc.isObject()) {
        QString preview = QString::fromUtf8(body.left(240)).simplified();
        if (preview.isEmpty()) preview = QStringLiteral("(empty body)");
        const QString parse_detail = parse_error.error == QJsonParseError::NoError
            ? QStringLiteral("RPC response was not a JSON object")
            : parse_error.errorString();
        error = QStringLiteral("RPC returned malformed JSON: %1. HTTP %2, content-type \"%3\", %4 bytes, preview: %5")
            .arg(parse_detail,
                 http_status > 0 ? QString::number(http_status) : QStringLiteral("unknown"),
                 content_type.isEmpty() ? QStringLiteral("unknown") : content_type,
                 QString::number(body.size()),
                 preview);
    } else if (!obj.value(QStringLiteral("error")).isNull()) {
        const QJsonValue rpc_error = obj.value(QStringLiteral("error"));
        error = rpc_error.isObject() ? rpc_error.toObject().value(QStringLiteral("message")).toString() : QString::fromUtf8(QJsonDocument(rpc_error.toObject()).toJson());
    }

    call.callback(obj.value(QStringLiteral("result")), error);
}

void NuRpcService::setError(const QString& message)
{
    m_rpc_connected = false;
    m_forensics_witness_capability_known = false;
    m_forensics_witness_inspection_available = false;
    m_forensics_witness_capability_probe_in_flight = false;
    m_connection_status = QStringLiteral("RPC not connected");
    m_last_error = message;
    m_syncing = false;
    m_sync_state = QStringLiteral("Unknown");
    m_sync_detail = QStringLiteral("Waiting for backend RPC.");
    m_sync_eta = QStringLiteral("Unknown");
    m_sync_progress_percent = 0;
    if (!message.isEmpty()) {
        rebuildNodeMetrics();
        m_node_metrics.push_front(row({"Detail", message}));
        m_node_metrics.push_front(row({"Backend", m_connection_status}));
        m_node_metrics.push_back(row({"Data directory", m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir}));
    }
    const bool log_message = !message.startsWith(QStringLiteral("Starting Defcoin backend"));
    if (log_message && !message.isEmpty() && m_last_logged_error_message != message) {
        appendLogLine(QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t")) + QStringLiteral(" ") + message);
        m_last_logged_error_message = message;
        trimLogLines();
        Q_EMIT logChanged();
    }
    Q_EMIT forensicsChanged();
    Q_EMIT stateChanged();
}

void NuRpcService::clearError()
{
    const bool was_connected = m_rpc_connected;
    m_rpc_connected = true;
    m_connection_status = QStringLiteral("RPC connected");
    m_last_error.clear();
    m_last_logged_error_message.clear();
    if (!was_connected && !m_rpc_ready_logged) {
        appendLaunchDiagnostic(QStringLiteral("RPC credentials are available; backend RPC is connected."));
        m_rpc_ready_logged = true;
    }
    Q_EMIT stateChanged();
    if (m_have_pending_network_active && !m_applying_pending_network_active) {
        m_applying_pending_network_active = true;
        const bool active = m_pending_network_active;
        QTimer::singleShot(0, this, [this, active] {
            setNetworkActive(active);
        });
    }
}

void NuRpcService::probeBackendCapabilities()
{
    if (!m_rpc_connected || m_forensics_witness_capability_known || m_forensics_witness_capability_probe_in_flight) return;
    m_forensics_witness_capability_probe_in_flight = true;
    m_forensics_witness_repair_status = QStringLiteral("Checking backend witness-inspection support.");
    Q_EMIT forensicsChanged();
    rpcCall(QStringLiteral("help"), {QStringLiteral("scanwitnessblockdata")}, false, [this](const QJsonValue& result, const QString& error) {
        m_forensics_witness_capability_probe_in_flight = false;
        m_forensics_witness_capability_known = true;
        m_forensics_witness_inspection_available = error.isEmpty() && result.isString()
            && result.toString().contains(QStringLiteral("scanwitnessblockdata"));
        if (m_forensics_witness_inspection_available) {
            if (m_forensics_witness_repair_status == QLatin1String("Checking backend witness-inspection support.")) {
                m_forensics_witness_repair_status = QStringLiteral("Witness data inspection is available.");
            }
            appendLaunchDiagnostic(QStringLiteral("Backend supports scanwitnessblockdata witness inspection RPC."));
        } else {
            m_forensics_witness_repair_status = QStringLiteral("This backend does not support witness inspection. Stop older defcoind instances and launch the bundled Nu backend.");
            appendLaunchDiagnostic(QStringLiteral("Backend does not support scanwitnessblockdata witness inspection RPC: %1")
                .arg(error.isEmpty() ? QStringLiteral("help text did not include method") : error));
        }
        Q_EMIT forensicsChanged();
    });
}

void NuRpcService::clearWalletScopedState()
{
    ++m_wallet_refresh_generation;
    m_wallet_locked = true;
    m_wallet_encrypted = false;
    m_total_balance = QStringLiteral("0.00000000 DFC");
    m_available_balance = QStringLiteral("0.00000000");
    m_pending_balance = QStringLiteral("0.00000000");
    m_immature_balance = QStringLiteral("0.00000000");
    m_wallet_transaction_count = 0;
    m_wallet_address_count = 0;
    m_wallet_nonzero_address_count = 0;
    m_receive_address.clear();
    m_receive_qr_source.clear();
    m_receive_label.clear();
    m_receive_amount.clear();
    m_receive_message.clear();
    m_loaded_receive_request_settings_key.clear();
    m_address_book_refresh_generation++;
    m_address_book.clear();
    m_recent_transactions.clear();
    m_receive_requests.clear();
    m_current_psbt.clear();
    m_current_psbt_final_hex.clear();
    m_current_psbt_summary = QStringLiteral("No PSBT loaded.");
}

bool NuRpcService::setCurrentWalletInternal(const QString& name, bool selected)
{
    const QString wallet_name = name.trimmed();
    if (m_wallet_selected == selected && m_wallet_name == wallet_name) return false;

    m_wallet_name = wallet_name;
    m_wallet_selected = selected;
    clearWalletScopedState();
    if (m_wallet_selected) {
        appendLaunchDiagnostic(QStringLiteral("Wallet selected: %1").arg(walletDisplayName(m_wallet_name)));
        loadReceiveRequests();
    } else {
        appendLaunchDiagnostic(QStringLiteral("No wallet is selected."));
    }
    Q_EMIT walletChanged();
    Q_EMIT psbtChanged();
    return true;
}

bool NuRpcService::ensureCurrentWalletSelected(const QString& title)
{
    if (m_wallet_selected) return true;
    Q_EMIT userMessage(title, QStringLiteral("Open or create a wallet before using this wallet action."));
    return false;
}

void NuRpcService::refresh()
{
    refreshNode();
    refreshWallet();
    refreshAddressBook();
    refreshFeeEstimate();
    refreshDebugLog();
}

void NuRpcService::refreshWalletList()
{
    rpcCall(QStringLiteral("listwallets"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty() || !result.isArray()) return;
        QStringList loaded;
        QHash<QString, QString> rpc_names;
        for (const QJsonValue& value : result.toArray()) {
            const QString raw_wallet = value.toString();
            const QString wallet = normalizedWalletListName(raw_wallet);
            if (isLikelyLoadableWalletMenuName(wallet)) loaded.push_back(wallet);
            if (isLikelyLoadableWalletMenuName(wallet) && !rpc_names.contains(wallet)) {
                rpc_names.insert(wallet, raw_wallet);
            }
        }
        loaded.removeDuplicates();
        bool changed = false;
        if (m_loaded_wallets != loaded) {
            m_loaded_wallets = loaded;
            changed = true;
        }
        if (m_wallet_rpc_name_by_canonical != rpc_names) {
            m_wallet_rpc_name_by_canonical = rpc_names;
            changed = true;
        }
        QStringList available = m_available_wallets;
        for (const QString& wallet : loaded) {
            if (!available.contains(wallet)) available.push_back(wallet);
        }
        if (walletDefaultDatExists(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir) && !available.contains(QString())) {
            available.push_back(QString());
        }
        available.removeDuplicates();
        available.sort(Qt::CaseInsensitive);
        if (m_available_wallets != available) {
            m_available_wallets = available;
            changed = true;
        }
        if (loaded.isEmpty()) {
            changed = setCurrentWalletInternal(QString(), false) || changed;
        } else if (!m_wallet_selected || !loaded.contains(m_wallet_name)) {
            changed = setCurrentWalletInternal(loaded.first()) || changed;
        }
        if (changed) {
            Q_EMIT walletChanged();
            refreshWalletStats();
        }
    });

    rpcCall(QStringLiteral("listwalletdir"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty() || !result.isObject()) return;
        QStringList available;
        const QJsonArray wallets = result.toObject().value(QStringLiteral("wallets")).toArray();
        for (const QJsonValue& wallet_value : wallets) {
            const QString wallet = normalizedWalletListName(wallet_value.toObject().value(QStringLiteral("name")).toString());
            if (isLikelyLoadableWalletMenuName(wallet)) available.push_back(wallet);
        }
        if (walletDefaultDatExists(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir) && !available.contains(QString())) {
            available.push_back(QString());
        }
        for (const QString& wallet : m_loaded_wallets) {
            available.push_back(wallet);
        }
        available.removeDuplicates();
        available.sort(Qt::CaseInsensitive);
        if (m_available_wallets == available) return;
        m_available_wallets = available;
        Q_EMIT walletChanged();
        refreshWalletStats();
    });
}

void NuRpcService::schedulePeerNameLookups(const QString& host)
{
    QHostAddress address;
    if (!address.setAddress(host.trimmed())) return;

    scheduleConfiguredSeedAliasLookups();

    const QString key = normalizedPeerHost(host);
    if (m_peer_dns_name_by_host.contains(key) ||
        m_peer_reverse_lookup_pending.contains(key) ||
        m_peer_reverse_lookup_attempted.contains(key)) {
        return;
    }

    const QString ptr_name = reverseDnsNameForAddress(address);
    if (ptr_name.isEmpty()) return;

    m_peer_reverse_lookup_pending.insert(key);
    m_peer_reverse_lookup_attempted.insert(key);
    QDnsLookup* dns = new QDnsLookup(QDnsLookup::PTR, ptr_name, this);
    connect(dns, &QDnsLookup::finished, this, [this, dns, key] {
        m_peer_reverse_lookup_pending.remove(key);

        if (dns->error() == QDnsLookup::NoError && !dns->pointerRecords().isEmpty()) {
            const QString name = normalizeDnsName(dns->pointerRecords().constFirst().value());
            if (!name.isEmpty() && !isIpLiteral(name) && m_peer_dns_name_by_host.value(key) != name) {
                m_peer_dns_name_by_host.insert(key, name);
                refreshNode();
            }
        }

        dns->deleteLater();
    });
    dns->lookup();
}

void NuRpcService::scheduleLanPeerNameLookups(const QString& host)
{
    if (m_stopping_helper_processes) return;
    if (!m_lan_node_discovery_enabled) return;
    const QString key = normalizedPeerHost(host);
    const bool has_local_dns_hint = !lanAliasFromDnsName(m_peer_dns_name_by_host.value(key)).isEmpty();
    const bool on_local_subnet = isOnLocalInterfaceSubnet(host);
    if (!isLikelyLanAddress(host) && !has_local_dns_hint && !on_local_subnet) return;

    if ((m_peer_lan_name_by_host.contains(key) && m_peer_lan_info_by_host.contains(key)) ||
        m_peer_lan_lookup_pending.contains(key)) {
        return;
    }

    const qint64 now_ms = QDateTime::currentMSecsSinceEpoch();
    const qint64 last_attempt_ms = m_peer_lan_lookup_last_attempt_ms.value(key, 0);
    if (last_attempt_ms > 0 && now_ms - last_attempt_ms < 60000) {
        return;
    }

    QHostAddress address;
    if (!address.setAddress(host.trimmed())) return;

    struct Command {
        QString program;
        QStringList arguments;
    };

    QVector<Command> commands;
#if defined(Q_OS_MACOS)
    const QString dns_sd = optionalProgramPath({QStringLiteral("/usr/bin/dns-sd")});
    const QString dscacheutil = optionalProgramPath({QStringLiteral("/usr/bin/dscacheutil")});
    if (!dns_sd.isEmpty() && !dscacheutil.isEmpty()) {
        const QString bonjour_script = QStringLiteral(R"SH(
target=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
    browse=$(mktemp -t nu-bonjour-browse.XXXXXX) || exit 0
    trap 'rm -f "$browse"' EXIT
    /usr/bin/dns-sd -B _smb._tcp local > "$browse" 2>/dev/null &
    browse_pid=$!
    sleep 1.2
    kill "$browse_pid" 2>/dev/null
    wait "$browse_pid" 2>/dev/null
    awk '/_smb\._tcp\./ {sub(/^.*_smb\._tcp\.[[:space:]]+/,""); print; fflush()}' "$browse" |
while IFS= read -r name; do
  [ -n "$name" ] || continue
  tmp=$(mktemp -t nu-bonjour.XXXXXX) || exit 0
  (/usr/bin/dns-sd -L "$name" _smb._tcp local > "$tmp" 2>/dev/null & pid=$!; sleep 0.8; kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null)
  host=$(awk '/ can be reached at / {sub(/^.* at /,""); sub(/:[0-9]+.*$/,""); print; exit}' "$tmp")
  rm -f "$tmp"
  [ -n "$host" ] || continue
  /usr/bin/dscacheutil -q host -a name "$host" 2>/dev/null |
  awk -v target="$target" -v name="$name" -v host="$host" '
    /^(ipv6_address|ip_address):/ {
      addr=tolower($2)
      sub(/%.*/, "", addr)
      if (addr == target) {
        print "Bonjour Name: " name
        print "Bonjour Host: " host
        exit
      }
    }'
done
)SH");
        commands.push_back({QStringLiteral("/bin/sh"), {QStringLiteral("-c"), bonjour_script, QStringLiteral("nu-lan-bonjour"), address.toString()}});
    }
    const QString smbutil = optionalProgramPath({QStringLiteral("/usr/bin/smbutil")});
    if (!smbutil.isEmpty()) {
        commands.push_back({smbutil, {QStringLiteral("status"), QStringLiteral("-ae"), address.toString()}});
    }
    if (address.protocol() == QAbstractSocket::IPv4Protocol) {
        const QString nmblookup = optionalProgramPath({
            QStringLiteral("/opt/homebrew/bin/nmblookup"),
            QStringLiteral("/usr/local/bin/nmblookup"),
            QStringLiteral("/usr/bin/nmblookup")
        });
        if (!nmblookup.isEmpty()) {
            commands.push_back({nmblookup, {QStringLiteral("-A"), address.toString()}});
        }
    }
    commands.push_back({QStringLiteral("/sbin/ping"), {QStringLiteral("-c"), QStringLiteral("1"), QStringLiteral("-W"), QStringLiteral("1000"), address.toString()}});
    if (address.protocol() == QAbstractSocket::IPv4Protocol) {
        commands.push_back({QStringLiteral("/usr/sbin/arp"), {QStringLiteral("-n"), address.toString()}});
    } else if (address.protocol() == QAbstractSocket::IPv6Protocol) {
        if (!smbutil.isEmpty()) {
            const QString ipv6_smb_bridge_script = QStringLiteral(R"SH(
target=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
mac=$(/usr/sbin/ndp -an 2>/dev/null |
  awk -v target="$target" 'tolower($1) == target {print tolower($2); exit}')
[ -n "$mac" ] || exit 0
ipv4=$(/usr/sbin/arp -an 2>/dev/null |
  awk -v mac="$mac" '
    {
      line=tolower($0)
      if (index(line, mac) > 0) {
        host=$0
        sub(/^.*\(/, "", host)
        sub(/\).*$/, "", host)
        print host
        exit
      }
    }')
[ -n "$ipv4" ] || exit 0
/usr/bin/smbutil status -ae "$ipv4" 2>/dev/null
)SH");
            commands.push_back({QStringLiteral("/bin/sh"), {QStringLiteral("-c"), ipv6_smb_bridge_script, QStringLiteral("nu-lan-ipv6-smb-bridge"), address.toString()}});
        }
        commands.push_back({QStringLiteral("/usr/sbin/ndp"), {QStringLiteral("-n"), address.toString()}});
    }
#elif defined(Q_OS_WIN)
    commands.push_back({QStringLiteral("powershell.exe"), {
        QStringLiteral("-NoProfile"),
        QStringLiteral("-Command"),
        QStringLiteral("Resolve-DnsName -Name '%1' -Type PTR -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty NameHost").arg(address.toString())
    }});
    if (address.protocol() == QAbstractSocket::IPv4Protocol) {
        commands.push_back({QStringLiteral("nbtstat"), {QStringLiteral("-A"), address.toString()}});
    }
    commands.push_back({QStringLiteral("ping"), {QStringLiteral("-a"), QStringLiteral("-n"), QStringLiteral("1"), address.toString()}});
#else
    commands.push_back({QStringLiteral("getent"), {QStringLiteral("hosts"), address.toString()}});
    commands.push_back({QStringLiteral("avahi-resolve-address"), {address.toString()}});
    commands.push_back({QStringLiteral("nmblookup"), {QStringLiteral("-A"), address.toString()}});
#endif
    const QString nmap = nmapProgramPath();
    if (!nmap.isEmpty()) {
        QStringList nmap_args;
        if (address.protocol() == QAbstractSocket::IPv6Protocol) nmap_args << QStringLiteral("-6");
        nmap_args << QStringLiteral("-O")
                  << QStringLiteral("--osscan-limit")
                  << QStringLiteral("--max-retries") << QStringLiteral("1")
                  << QStringLiteral("--host-timeout") << QStringLiteral("3s")
                  << QStringLiteral("-Pn")
                  << address.toString();
        commands.push_back({nmap, nmap_args});
    }
    if (commands.isEmpty()) return;

    m_peer_lan_lookup_pending.insert(key);
    m_peer_lan_lookup_attempted.insert(key);
    m_peer_lan_lookup_last_attempt_ms.insert(key, now_ms);

    auto lan_lookup_id = std::make_shared<int>(-1);
    *lan_lookup_id = QHostInfo::lookupHost(address.toString(), this, [this, key, lan_lookup_id](const QHostInfo& info) {
        if (*lan_lookup_id >= 0) m_host_lookup_ids.remove(*lan_lookup_id);
        if (m_stopping_helper_processes) return;
        if (info.error() != QHostInfo::NoError) return;
        const QString name = lanWorkstationNameFromCandidate(info.hostName());
        if (name.isEmpty()) return;
        bool changed = false;
        if (m_peer_lan_name_by_host.value(key) != name) {
            m_peer_lan_name_by_host.insert(key, name);
            changed = true;
        }
        const QString detail = name;
        if (m_peer_lan_info_by_host.value(key).isEmpty()) {
            m_peer_lan_info_by_host.insert(key, detail);
            changed = true;
        }
        if (changed) refreshNode();
    });
    if (*lan_lookup_id >= 0) m_host_lookup_ids.insert(*lan_lookup_id);

    auto command_list = std::make_shared<QVector<Command>>(commands);
    auto aggregate_name = std::make_shared<QString>();
    auto aggregate_details = std::make_shared<QStringList>();
    auto run_next = std::make_shared<std::function<void(int)>>();
    *run_next = [this, key, command_list, aggregate_name, aggregate_details, run_next](int index) {
        if (m_stopping_helper_processes) {
            m_peer_lan_lookup_pending.remove(key);
            return;
        }
        if (index >= command_list->size()) {
            m_peer_lan_lookup_pending.remove(key);
            bool changed = false;
            if (!aggregate_name->isEmpty() && m_peer_lan_name_by_host.value(key) != *aggregate_name) {
                m_peer_lan_name_by_host.insert(key, *aggregate_name);
                changed = true;
            }
            if (!aggregate_details->isEmpty()) {
                const QString info = aggregate_details->join(QStringLiteral(" | "));
                if (m_peer_lan_info_by_host.value(key) != info) {
                    m_peer_lan_info_by_host.insert(key, info);
                    changed = true;
                }
            }
            if (changed) refreshNode();
            return;
        }

        const Command command = command_list->at(index);
        if (command.program.startsWith(QLatin1Char('/')) && !QFileInfo::exists(command.program)) {
            (*run_next)(index + 1);
            return;
        }

        QProcess* process = new QProcess(this);
        m_helper_processes.insert(process);
        connect(process, &QObject::destroyed, this, [this, process] {
            m_helper_processes.remove(process);
        });
        QTimer* timeout = new QTimer(process);
        timeout->setSingleShot(true);
        auto completed = std::make_shared<bool>(false);

        connect(timeout, &QTimer::timeout, process, [process] {
            if (process->state() != QProcess::NotRunning) process->kill();
        });

        const auto finish = [this, process, timeout, run_next, index, completed, aggregate_name, aggregate_details] {
            if (*completed) return;
            *completed = true;
            timeout->stop();
            if (process->state() != QProcess::NotRunning) {
                process->kill();
                process->waitForFinished(500);
            }

            if (!m_stopping_helper_processes) {
                const QString output = QString::fromLocal8Bit(process->readAllStandardOutput())
                    + QLatin1Char('\n')
                    + QString::fromLocal8Bit(process->readAllStandardError());
                const QString name = parseLanPeerNameLookupOutput(output);
                const QStringList details = parseLanPeerFingerprintDetails(output);
                if (!name.isEmpty() && aggregate_name->isEmpty()) {
                    *aggregate_name = name;
                }
                for (const QString& detail : details) {
                    if (!aggregate_details->contains(detail, Qt::CaseInsensitive)) aggregate_details->push_back(detail);
                }
            }

            m_helper_processes.remove(process);
            process->deleteLater();
            if (!m_stopping_helper_processes) (*run_next)(index + 1);
        };

        connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
                [finish](int, QProcess::ExitStatus) { finish(); });
        connect(process, &QProcess::errorOccurred, this,
                [finish](QProcess::ProcessError) { finish(); });

        process->start(command.program, command.arguments);
        timeout->start(command.program == QLatin1String("/bin/sh") ? 4500 : 2500);
    };

    (*run_next)(0);
}

void NuRpcService::scheduleConfiguredSeedAliasLookups()
{
    if (m_seed_alias_lookups_started) return;
    m_seed_alias_lookups_started = true;

    for (const QString& domain : configuredSeedDomains()) {
        auto seed_lookup_id = std::make_shared<int>(-1);
        *seed_lookup_id = QHostInfo::lookupHost(domain, this, [this, domain, seed_lookup_id](const QHostInfo& info) {
            if (*seed_lookup_id >= 0) m_host_lookup_ids.remove(*seed_lookup_id);
            if (info.error() != QHostInfo::NoError) return;

            bool changed = false;
            const int priority = seedDomainPriority(domain);
            for (const QHostAddress& address : info.addresses()) {
                const QString key = normalizedPeerHost(address.toString());
                const int current_priority = m_peer_domain_alias_priority_by_host.value(key, std::numeric_limits<int>::max());
                if (priority < current_priority) {
                    m_peer_domain_alias_by_host.insert(key, domain);
                    m_peer_domain_alias_priority_by_host.insert(key, priority);
                    changed = true;
                }
            }

            if (changed) refreshNode();
        });
        if (*seed_lookup_id >= 0) m_host_lookup_ids.insert(*seed_lookup_id);
    }
}

void NuRpcService::refreshNode()
{
    rpcCall(QStringLiteral("getonlydefcoinuseragents"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (error.isEmpty() && result.isBool() && m_only_defcoin_user_agents != result.toBool()) {
            m_only_defcoin_user_agents = result.toBool();
            QSettings(QStringLiteral("Defcoin"), QStringLiteral("Defcoin-Qt")).setValue(QStringLiteral("OnlyDefcoinUserAgents"), m_only_defcoin_user_agents);
            Q_EMIT settingsChanged();
        }
    });

    rpcCall(QStringLiteral("getacceptlegacymagic"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (error.isEmpty() && result.isBool()) {
            const bool only_defcoin_magic = !result.toBool();
            if (m_only_defcoin_magic_bytes != only_defcoin_magic) {
                m_only_defcoin_magic_bytes = only_defcoin_magic;
                QSettings().setValue(QStringLiteral("OnlyDefcoinMagicBytes"), only_defcoin_magic);
                Q_EMIT settingsChanged();
            }
        }
    });

    rpcCall(QStringLiteral("getallowlannodediscovery"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (error.isEmpty() && result.isBool() && m_lan_node_discovery_enabled != result.toBool()) {
            m_lan_node_discovery_enabled = result.toBool();
            QSettings().setValue(QStringLiteral("LanNodeDiscoveryEnabled"), m_lan_node_discovery_enabled);
            Q_EMIT settingsChanged();
        }
    });

    refreshWalletList();

    rpcCall(QStringLiteral("getnetworkinfo"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) {
            setError(error);
            return;
        }
        clearError();
        probeBackendCapabilities();
        const QJsonObject info = result.toObject();
        const bool active = info.value(QStringLiteral("networkactive")).toBool();
        m_peer_count = info.value(QStringLiteral("connections")).toInt();
        m_network_state = active ? QStringLiteral("connected") : QStringLiteral("isolated");
        m_metric_network_active = boolText(active);
        m_metric_connections = QString::number(m_peer_count);
        m_metric_inbound = QString::number(info.value(QStringLiteral("connections_in")).toInt());
        m_metric_outbound = QString::number(info.value(QStringLiteral("connections_out")).toInt());
        m_metric_version = info.value(QStringLiteral("subversion")).toString();
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
    });

    rpcCall(QStringLiteral("getblockchaininfo"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) return;
        const QJsonObject chain = result.toObject();
        m_block_height = chain.value(QStringLiteral("blocks")).toInt();
        const int headers = chain.value(QStringLiteral("headers")).toInt();
        m_header_height = headers;
        const bool ibd = chain.value(QStringLiteral("initialblockdownload")).toBool();
        const double progress = std::clamp(chain.value(QStringLiteral("verificationprogress")).toDouble(), 0.0, 1.0);
        const bool headers_ahead = headers > m_block_height;
        const bool syncing = ibd || headers_ahead;
        const qint64 now_ms = QDateTime::currentMSecsSinceEpoch();
        const int blocks_behind = std::max(0, headers - m_block_height);
        if (m_chain_progress_last_diagnostic_ms <= 0 ||
            now_ms - m_chain_progress_last_diagnostic_ms >= 30000 ||
            headers < m_chain_progress_last_diagnostic_headers ||
            m_block_height < m_chain_progress_last_diagnostic_blocks) {
            appendDebugLogLineFromNu(QStringLiteral("Nu chain progress sample: blocks=%1 headers=%2 blocks_behind=%3 ibd=%4 verification=%5.")
                .arg(m_block_height)
                .arg(headers)
                .arg(blocks_behind)
                .arg(ibd ? QStringLiteral("true") : QStringLiteral("false"))
                .arg(QString::number(progress * 100.0, 'f', 4) + QStringLiteral("%")));
            m_chain_progress_last_diagnostic_ms = now_ms;
            m_chain_progress_last_diagnostic_headers = headers;
            m_chain_progress_last_diagnostic_blocks = m_block_height;
        }
        if (m_sync_last_sample_ms > 0 && now_ms > m_sync_last_sample_ms && m_sync_last_block_height >= 0 && m_block_height > m_sync_last_block_height) {
            const int block_delta = m_block_height - m_sync_last_block_height;
            const double seconds = double(now_ms - m_sync_last_sample_ms) / 1000.0;
            const bool recent_udp_accept = m_fast_sync_last_udp_accepted_height >= (m_block_height - block_delta + 1)
                && m_fast_sync_last_udp_accepted_height <= m_block_height
                && m_lan_fast_sync_last_progress_ms > 0
                && now_ms - m_lan_fast_sync_last_progress_ms < 10000;
            if (!recent_udp_accept) {
                recordCoreSyncPathProgress(block_delta, seconds);
            }
        }
        m_syncing = syncing;
        int progress_percent = qBound(0, int(std::round(progress * 100.0)), 100);
        if (syncing && blocks_behind > 0 && progress_percent >= 100) {
            progress_percent = 99;
        }
        m_sync_progress_percent = progress_percent;
        const QString progress_text = QString::number(progress * 100.0, 'f', progress >= 0.999 ? 3 : 2) + QStringLiteral("%");
        if (syncing) {
            QString eta = QStringLiteral("calculating");
            if (m_sync_last_sample_ms > 0 && now_ms > m_sync_last_sample_ms) {
                const double seconds = double(now_ms - m_sync_last_sample_ms) / 1000.0;
                const double progress_delta = progress - m_sync_last_progress;
                if (progress_delta > 0.0000001) {
                    eta = formatSyncEtaSeconds(qint64(std::ceil((1.0 - progress) / (progress_delta / seconds))));
                } else if (m_sync_last_block_height >= 0 && m_block_height > m_sync_last_block_height && blocks_behind > 0) {
                    const double blocks_per_second = double(m_block_height - m_sync_last_block_height) / seconds;
                    if (blocks_per_second > 0.0) eta = formatSyncEtaSeconds(qint64(std::ceil(blocks_behind / blocks_per_second)));
                }
            }
            m_sync_eta = eta;
            m_sync_state = QStringLiteral("Syncing | %1 done | Est. %2").arg(progress_text, eta);
            m_sync_detail = QStringLiteral("%1 done. Block %2 of %3 headers. %4 block%5 behind. Estimated time remaining: %6.")
                .arg(progress_text)
                .arg(m_block_height)
                .arg(headers)
                .arg(blocks_behind)
                .arg(blocks_behind == 1 ? QString() : QStringLiteral("s"))
                .arg(eta);
        } else {
            m_sync_eta = QStringLiteral("0m");
            m_sync_state = QStringLiteral("Up to Date");
            m_sync_detail = QStringLiteral("Up to Date. Block %1 of %2 headers.").arg(m_block_height).arg(headers);
        }
        m_sync_last_progress = progress;
        m_sync_last_block_height = m_block_height;
        m_sync_last_sample_ms = now_ms;
        m_metric_blocks = QString::number(m_block_height);
        m_metric_headers = QString::number(headers);
        m_metric_verification = progress_text;
        m_metric_difficulty = chain.value(QStringLiteral("difficulty")).isDouble()
            ? formatCompactDifficulty(chain.value(QStringLiteral("difficulty")).toDouble())
            : QStringLiteral("Unknown");
#if DEFCOIN_NU_EXPLORE_APP
        refreshRecentAverageBlockTimeFromIndex();
#endif
        refreshRecentAverageBlockTimeFromRpc(m_block_height);
        rebuildNodeMetrics();
        evaluateQuickClonePrompt();
        Q_EMIT stateChanged();

#if DEFCOIN_NU_EXPLORE_APP
        if (!m_explorer_indexing && !m_explorer_index_paused_by_user && !m_explorer_auto_index_requested && m_block_height > 0) {
            const int indexed_height = explorerHighestIndexedBlock();
            if (indexed_height < m_block_height) {
                m_explorer_auto_index_requested = true;
                QTimer::singleShot(750, this, [this] {
                    m_explorer_auto_index_requested = false;
                    if (!m_explorer_indexing && !m_explorer_index_paused_by_user && m_rpc_connected) {
                        startExplorerIndexing();
                    }
                });
            }
        }
#endif
    });

    rpcCall(QStringLiteral("getnetworkhashps"), {120, -1}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) return;
        m_metric_network_hashrate = formatHashrateMetric(result.toDouble());
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
    });

    rpcCall(QStringLiteral("getchaintips"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty() || !result.isArray()) return;
        int active = 0;
        int active_height = -1;
        int valid_forks = 0;
        int closest_valid_fork_height = -1;
        int closest_valid_fork_branch_len = 0;
        int headers_only = 0;
        for (const QJsonValue& value : result.toArray()) {
            const QJsonObject tip = value.toObject();
            const QString status = tip.value(QStringLiteral("status")).toString();
            const int height = tip.value(QStringLiteral("height")).toInt(-1);
            if (status == QLatin1String("active")) {
                ++active;
                active_height = std::max(active_height, height);
            } else if (status == QLatin1String("valid-fork")) {
                ++valid_forks;
                if (height > closest_valid_fork_height) {
                    closest_valid_fork_height = height;
                    closest_valid_fork_branch_len = tip.value(QStringLiteral("branchlen")).toInt();
                }
            }
            else if (status == QLatin1String("headers-only")) ++headers_only;
        }
        QString fork_summary;
        if (valid_forks > 0 && active_height >= 0 && closest_valid_fork_height >= 0) {
            const int blocks_behind = std::max(0, active_height - closest_valid_fork_height);
            fork_summary = QStringLiteral("%1 historical stale branch%2 (closest: %3-block branch, tip %4 blocks behind)")
                .arg(valid_forks)
                .arg(valid_forks == 1 ? QString() : QStringLiteral("s"))
                .arg(closest_valid_fork_branch_len)
                .arg(blocks_behind);
        } else {
            fork_summary = QStringLiteral("%1 historical stale branches").arg(valid_forks);
        }
        m_metric_chain_tips = QStringLiteral("%1 active, %2, %3 headers-only, %4 total")
            .arg(active)
            .arg(fork_summary)
            .arg(headers_only)
            .arg(result.toArray().size());
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
    });

    rpcCall(QStringLiteral("getnettotals"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) return;
        const QJsonObject totals = result.toObject();
        m_traffic_received_total = formatBytes(totals.value(QStringLiteral("totalbytesrecv")).toVariant().toLongLong());
        m_traffic_sent_total = formatBytes(totals.value(QStringLiteral("totalbytessent")).toVariant().toLongLong());
        m_metric_traffic = m_traffic_received_total + QStringLiteral(" received / ") + m_traffic_sent_total + QStringLiteral(" sent");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        Q_EMIT trafficChanged();
    });

    rpcCall(QStringLiteral("getpeerinfo"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) return;
        QVariantList simple_rows;
        QVariantList detailed_rows;
        QHash<QString, qint64> sent_message_bytes;
        QHash<QString, qint64> received_message_bytes;
        QSet<QString> udp_fast_sync_peer_hosts;
        QHash<QString, int> udp_fast_sync_peer_node_ids_by_host;
        QHash<QString, int> udp_fast_sync_peer_tips_by_host;
        QHash<QString, int> udp_fast_sync_peer_inflight_counts_by_host;
        QHash<int, QString> peer_host_by_node_id;
        QHash<int, QString> peer_addr_by_node_id;
        QHash<int, bool> peer_inbound_by_node_id;
        for (const QJsonValue& peer_value : result.toArray()) {
            const QJsonObject peer = peer_value.toObject();
            const QString subver = trimUserAgent(peer.value(QStringLiteral("subver")).toString());
            if (m_only_defcoin_user_agents && !isDefcoinUserAgent(subver)) continue;
            const QString raw_addr = peer.value(QStringLiteral("addr")).toString();
            const QPair<QString, QString> endpoint = splitPeerAddressAndPort(peer.value(QStringLiteral("addr")).toString());
            const int node_id_int = peer.value(QStringLiteral("id")).toInt(-1);
            const int inflight_count = peer.value(QStringLiteral("inflight")).toArray().size();
            if (node_id_int >= 0) {
                peer_host_by_node_id.insert(node_id_int, endpoint.first);
                peer_addr_by_node_id.insert(node_id_int, raw_addr);
                peer_inbound_by_node_id.insert(node_id_int, peer.value(QStringLiteral("inbound")).toBool());
            }
            QHostAddress udp_fast_sync_address;
            QString udp_fast_sync_host_key;
            const bool fast_sync_service_candidate = peerServicesAdvertiseFastSync(peer.value(QStringLiteral("services")).toString());
            const bool nu_fast_sync_candidate = fast_sync_service_candidate &&
                udp_fast_sync_address.setAddress(endpoint.first) &&
                !isLocalInterfaceAddress(udp_fast_sync_address);
            if (nu_fast_sync_candidate) {
                udp_fast_sync_host_key = normalizedFastSyncHost(udp_fast_sync_address);
                udp_fast_sync_peer_hosts.insert(udp_fast_sync_host_key);
                udp_fast_sync_peer_node_ids_by_host.insert(udp_fast_sync_host_key, node_id_int);
                udp_fast_sync_peer_inflight_counts_by_host.insert(udp_fast_sync_host_key, inflight_count);
                const int peer_tip = std::max(peer.value(QStringLiteral("synced_headers")).toInt(-1),
                                              peer.value(QStringLiteral("synced_blocks")).toInt(-1));
                if (peer_tip >= 0) udp_fast_sync_peer_tips_by_host.insert(udp_fast_sync_host_key, peer_tip);
            }
            QString fast_sync_available = QStringLiteral("No");
            if (!m_lan_fast_sync_enabled) {
                fast_sync_available = QStringLiteral("Off");
            } else if (nu_fast_sync_candidate) {
                if (!udp_fast_sync_host_key.isEmpty() &&
                    (m_udp_fast_sync_available_peer_hosts.contains(udp_fast_sync_host_key) ||
                     m_udp_fast_sync_used_peer_hosts.contains(udp_fast_sync_host_key))) {
                    fast_sync_available = QStringLiteral("Yes");
                } else if (!udp_fast_sync_host_key.isEmpty() &&
                           m_udp_fast_sync_failed_peer_hosts.contains(udp_fast_sync_host_key)) {
                    fast_sync_available = QStringLiteral("No reply");
                } else if (!udp_fast_sync_host_key.isEmpty() &&
                           m_udp_fast_sync_probe_ids_by_host.contains(udp_fast_sync_host_key)) {
                    fast_sync_available = QStringLiteral("Probe sent");
                } else {
                    fast_sync_available = QStringLiteral("Advertised");
                }
            }
            schedulePeerNameLookups(endpoint.first);
            scheduleLanPeerNameLookups(endpoint.first);
            const QString node_id = QString::number(node_id_int);
            const QString direction = peer.value(QStringLiteral("inbound")).toBool() ? QStringLiteral("In") : QStringLiteral("Out");
            const QString ping = formatPing(peer.value(QStringLiteral("pingtime")));
            const QString min_ping = formatPing(peer.value(QStringLiteral("minping")));
            const qint64 peer_bytes_sent = peer.value(QStringLiteral("bytessent")).toVariant().toLongLong();
            const qint64 peer_bytes_received = peer.value(QStringLiteral("bytesrecv")).toVariant().toLongLong();
            const QString sent = formatBytes(peer_bytes_sent);
            const QString received = formatBytes(peer_bytes_received);
            const bool tcp_used = peer_bytes_sent > 0 || peer_bytes_received > 0;
            const bool udp_used = !udp_fast_sync_host_key.isEmpty() && m_udp_fast_sync_used_peer_hosts.contains(udp_fast_sync_host_key);
            const QString transport_methods = tcp_used && udp_used
                ? QStringLiteral("TCP+UDP")
                : (tcp_used ? QStringLiteral("TCP") : (udp_used ? QStringLiteral("UDP") : QStringLiteral("-")));
            const QString magic = fallbackDash(peer.value(QStringLiteral("p2p_magic")).toString(
                peer.value(QStringLiteral("magic")).toString(QStringLiteral("pending"))));
            const QString protocol_version = peerNumberText(peer, QStringLiteral("version"));
            const QString services_hex = peer.value(QStringLiteral("services")).toString();
            const QString services = formatServices(services_hex);
            const QString service_details = formatServiceDetails(services_hex);
            const QString reverse_dns = peerDnsName(peer, endpoint, m_peer_dns_name_by_host);
            const QString known_dns = peerDomainAlias(peer, endpoint, reverse_dns, m_peer_dns_name_by_host, m_peer_domain_alias_by_host, m_peer_lan_name_by_host);
            const bool lan_peer = m_lan_node_discovery_enabled && isVisibleLanPeer(endpoint.first, reverse_dns, known_dns, m_peer_lan_name_by_host, m_peer_lan_info_by_host);
            const QString workstation_info = lan_peer
                ? peerLanWorkstationInfo(endpoint.first, reverse_dns, m_peer_lan_info_by_host, m_peer_lan_name_by_host, m_peer_dns_name_by_host, m_peer_lan_lookup_pending)
                : QString();
            const QString source_or_lan_name = lan_peer && workstation_info != QLatin1String("-")
                ? workstation_info
                : known_dns;
            const QString lan_tooltip = lan_peer
                ? peerLanWorkstationSourceTooltip(endpoint.first, source_or_lan_name, reverse_dns, m_peer_lan_info_by_host, m_peer_lan_name_by_host, m_peer_dns_name_by_host, m_peer_lan_lookup_pending)
                : QString();
            const QJsonObject sent_per_msg = peer.value(QStringLiteral("bytessent_per_msg")).toObject();
            for (auto it = sent_per_msg.constBegin(); it != sent_per_msg.constEnd(); ++it) {
                sent_message_bytes[it.key()] += it.value().toVariant().toLongLong();
            }
            const QJsonObject recv_per_msg = peer.value(QStringLiteral("bytesrecv_per_msg")).toObject();
            for (auto it = recv_per_msg.constBegin(); it != recv_per_msg.constEnd(); ++it) {
                received_message_bytes[it.key()] += it.value().toVariant().toLongLong();
            }

            const QVariantMap peer_meta{
                {QStringLiteral("nodeId"), node_id},
                {QStringLiteral("peerHost"), endpoint.first},
                {QStringLiteral("peerAddress"), raw_addr},
                {QStringLiteral("peerInbound"), peer.value(QStringLiteral("inbound")).toBool()}
            };

            simple_rows.push_back(tableRow({
                node_id,
                direction,
                peerAddressPortDisplay(raw_addr, endpoint),
                transport_methods,
                ping,
                sent,
                received,
                subver
            }, peer_meta));

            QVariantList cell_tooltips;
            for (int i = 0; i < 28; ++i) cell_tooltips << QString();
            if (!lan_tooltip.isEmpty()) cell_tooltips[5] = lan_tooltip;
            cell_tooltips[8] = service_details;

            detailed_rows.push_back(tableRow({
                node_id,
                direction,
                peerIpDisplay(endpoint),
                fallbackDash(endpoint.second),
                reverse_dns,
                source_or_lan_name,
                protocol_version,
                magic,
                services,
                fast_sync_available,
                transport_methods,
                ping,
                min_ping,
                sent,
                received,
                subver,
                peerUnixTimeText(peer, QStringLiteral("conntime")),
                peerNumberText(peer, QStringLiteral("startingheight")),
                peerUnixTimeText(peer, QStringLiteral("lastsend")),
                peerUnixTimeText(peer, QStringLiteral("lastrecv")),
                peerUnixTimeText(peer, QStringLiteral("last_transaction")),
                peerUnixTimeText(peer, QStringLiteral("last_block")),
                peerSyncHeightText(peer, QStringLiteral("synced_headers")),
                peerSyncHeightText(peer, QStringLiteral("synced_blocks")),
                fallbackDash(peer.value(QStringLiteral("connection_type")).toString()),
                fallbackDash(peer.value(QStringLiteral("network")).toString()),
                peerNumberText(peer, QStringLiteral("addr_processed")),
                peer.value(QStringLiteral("minfeefilter")).isDouble()
                    ? formatAmount(peer.value(QStringLiteral("minfeefilter"))) + QStringLiteral(" DFC/kB")
                    : QStringLiteral("-")
            }, {
                {QStringLiteral("nodeId"), node_id},
                {QStringLiteral("peerHost"), endpoint.first},
                {QStringLiteral("peerAddress"), raw_addr},
                {QStringLiteral("peerInbound"), peer.value(QStringLiteral("inbound")).toBool()},
                {QStringLiteral("reverseDnsSort"), reverseDomainSortNotation(reverse_dns)},
                {QStringLiteral("knownDnsSort"), (lan_peer ? QStringLiteral("0|") : QStringLiteral("1|")) +
                    (lan_peer ? source_or_lan_name.toLower() : reverseDomainSortNotation(source_or_lan_name))},
                {QStringLiteral("isLanPeer"), lan_peer},
                {QStringLiteral("cellTooltips"), cell_tooltips}
            }));
        }
        m_peer_rows_simple = simple_rows;
        m_peer_rows_detailed = detailed_rows;
        m_peers = detailed_rows;
        m_peer_count = detailed_rows.size();
        const bool udp_peer_set_changed = m_udp_fast_sync_peer_hosts != udp_fast_sync_peer_hosts;
        m_udp_fast_sync_peer_hosts = udp_fast_sync_peer_hosts;
        m_udp_fast_sync_peer_node_ids_by_host = udp_fast_sync_peer_node_ids_by_host;
        for (auto it = udp_fast_sync_peer_tips_by_host.constBegin(); it != udp_fast_sync_peer_tips_by_host.constEnd(); ++it) {
            m_udp_fast_sync_peer_tips_by_host.insert(it.key(), it.value());
        }
        m_udp_fast_sync_peer_inflight_counts_by_host = udp_fast_sync_peer_inflight_counts_by_host;
        m_peer_host_by_node_id = peer_host_by_node_id;
        m_peer_addr_by_node_id = peer_addr_by_node_id;
        m_peer_inbound_by_node_id = peer_inbound_by_node_id;
        if (udp_peer_set_changed ||
            (m_fast_sync_tcp_quota_remaining <= 0 && m_fast_sync_udp_quota_remaining <= 0)) {
            resetFastSyncProtocolWindow();
        }
        m_metric_peer_messages_sent = orderedMessageTypeStats(sent_message_bytes);
        m_metric_peer_messages_received = orderedMessageTypeStats(received_message_bytes);
        rebuildNodeMetrics();
        Q_EMIT peersChanged();
        Q_EMIT stateChanged();
    });
    refreshBannedPeerRows();
}

void NuRpcService::refreshWallet()
{
    if (!m_wallet_selected) {
        return;
    }

    const QString wallet_name = m_wallet_name;
    const int generation = ++m_wallet_refresh_generation;
    rpcCall(QStringLiteral("getwalletinfo"), {}, true, [this, wallet_name, generation](const QJsonValue& result, const QString& error) {
        if (generation != m_wallet_refresh_generation || wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            m_wallet_locked = true;
            Q_EMIT walletChanged();
            return;
        }
        const QJsonObject wallet = result.toObject();
        const double available = wallet.value(QStringLiteral("balance")).toDouble();
        const double pending = wallet.value(QStringLiteral("unconfirmed_balance")).toDouble();
        const double immature = wallet.value(QStringLiteral("immature_balance")).toDouble();
        const double total = available + pending + immature;
        m_available_balance = QString::number(available, 'f', 8);
        m_pending_balance = QString::number(pending, 'f', 8);
        m_immature_balance = QString::number(immature, 'f', 8);
        m_total_balance = QString::number(total, 'f', 8) + QStringLiteral(" DFC");
        m_wallet_transaction_count = wallet.value(QStringLiteral("txcount")).toInt(0);
        const QJsonValue unlocked_until = wallet.value(QStringLiteral("unlocked_until"));
        m_wallet_encrypted = wallet.contains(QStringLiteral("unlocked_until"));
        m_wallet_locked = m_wallet_encrypted ? unlocked_until.toDouble() == 0 : false;
        QVariantMap updates;
        updates.insert(QStringLiteral("total"), m_total_balance);
        updates.insert(QStringLiteral("available"), m_available_balance);
        updates.insert(QStringLiteral("pending"), m_pending_balance);
        updates.insert(QStringLiteral("immature"), m_immature_balance);
        updates.insert(QStringLiteral("transactions"), QString::number(m_wallet_transaction_count));
        updateWalletStatsEntry(wallet_name, updates);
        Q_EMIT walletChanged();
    });

    rpcCall(QStringLiteral("listtransactions"), {QStringLiteral("*"), 25, 0, true}, true, [this, wallet_name, generation](const QJsonValue& result, const QString& error) {
        if (generation != m_wallet_refresh_generation || wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) return;
        QVariantList rows;
        for (const QJsonValue& tx_value : result.toArray()) {
            const QJsonObject tx = tx_value.toObject();
            const qint64 time = tx.value(QStringLiteral("time")).toVariant().toLongLong();
            const QString amount = QString::number(tx.value(QStringLiteral("amount")).toDouble(), 'f', 8) + QStringLiteral(" DFC");
            const QString category = tx.value(QStringLiteral("category")).toString();
            QString display_category = category;
            if (category == QLatin1String("send")) display_category = QStringLiteral("Sent");
            if (category == QLatin1String("receive")) display_category = QStringLiteral("Received");
            if (category == QLatin1String("generate") || category == QLatin1String("immature") || category == QLatin1String("orphan")) {
                display_category = QStringLiteral("Mined");
            }
            const QString txid = tx.value(QStringLiteral("txid")).toString();
            const QString address = tx.value(QStringLiteral("address")).toString();
            QVariantMap meta;
            meta.insert(QStringLiteral("kind"), QStringLiteral("transaction"));
            meta.insert(QStringLiteral("txid"), txid);
            meta.insert(QStringLiteral("address"), address);
            meta.insert(QStringLiteral("category"), category);
            meta.insert(QStringLiteral("confirmations"), tx.value(QStringLiteral("confirmations")).toInt());
            meta.insert(QStringLiteral("time"), time);
            meta.insert(QStringLiteral("amount"), tx.value(QStringLiteral("amount")).toDouble());
            meta.insert(QStringLiteral("label"), tx.value(QStringLiteral("label")).toString());
            rows.push_front(tableRow({
                QString(),
                QDateTime::fromSecsSinceEpoch(time).toString(QStringLiteral("MM/dd/yy HH:mm")),
                display_category,
                tx.value(QStringLiteral("label")).toString(address),
                amount
            }, meta));
        }
        m_recent_transactions = rows;
        Q_EMIT walletChanged();
    });
}

void NuRpcService::refreshAddressBook()
{
    if (!m_wallet_selected) {
        if (!m_address_book.isEmpty()) {
            m_address_book.clear();
            Q_EMIT walletChanged();
        }
        return;
    }

    const QString wallet_name = m_wallet_name;
    const int generation = ++m_address_book_refresh_generation;
    rpcCall(QStringLiteral("listreceivedbyaddress"), {0, true, true}, true, [this, wallet_name, generation](const QJsonValue& result, const QString& error) {
        if (generation != m_address_book_refresh_generation || wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) return;
        QVariantList receive_rows;
        for (const QJsonValue& value : result.toArray()) {
            const QJsonObject item = value.toObject();
            upsertAddressRow(receive_rows, row({
                item.value(QStringLiteral("label")).toString(QStringLiteral("(no label)")),
                item.value(QStringLiteral("address")).toString(),
                normalPurpose(QStringLiteral("receive")),
                QString::number(item.value(QStringLiteral("amount")).toDouble(), 'f', 8) + QStringLiteral(" DFC")
            }));
        }

        rpcCall(QStringLiteral("listlabels"), {QStringLiteral("send")}, true, [this, wallet_name, receive_rows, generation](const QJsonValue& labels, const QString& label_error) {
            if (generation != m_address_book_refresh_generation || wallet_name != m_wallet_name) return;
            auto rows = std::make_shared<QVariantList>(receive_rows);
            auto commit = [this, wallet_name, rows, generation]() {
                if (generation != m_address_book_refresh_generation || wallet_name != m_wallet_name) return;
                int address_count = 0;
                int nonzero_count = 0;
                for (const QVariant& row_value : *rows) {
                    const QVariantList cells = tableRowCells(row_value);
                    if (cells.size() <= 1 || cells.at(1).toString().trimmed().isEmpty()) continue;
                    ++address_count;
                    if (cells.size() > 3) {
                        const QString amount_text = cells.at(3).toString();
                        const double amount = amount_text.left(amount_text.indexOf(QLatin1Char(' ')) >= 0 ? amount_text.indexOf(QLatin1Char(' ')) : amount_text.size()).toDouble();
                        if (std::fabs(amount) > 0.000000005) ++nonzero_count;
                    }
                }
                m_wallet_address_count = address_count;
                m_wallet_nonzero_address_count = nonzero_count;
                QVariantMap updates;
                updates.insert(QStringLiteral("addressCount"), address_count);
                updates.insert(QStringLiteral("nonZeroAddressCount"), nonzero_count);
                updateWalletStatsEntry(wallet_name, updates);
                if (m_address_book == *rows) {
                    Q_EMIT walletChanged();
                    return;
                }
                m_address_book = *rows;
                Q_EMIT walletChanged();
            };

            if (!label_error.isEmpty() || !labels.isArray()) {
                commit();
                return;
            }

            const QJsonArray label_array = labels.toArray();
            if (label_array.isEmpty()) {
                commit();
                return;
            }

            auto pending = std::make_shared<int>(label_array.size());
            for (const QJsonValue& label_value : label_array) {
                const QString label = label_value.toString();
                rpcCall(QStringLiteral("getaddressesbylabel"), {label}, true, [this, wallet_name, label, rows, pending, commit, generation](const QJsonValue& addresses, const QString& address_error) {
                    if (generation != m_address_book_refresh_generation || wallet_name != m_wallet_name) return;
                    if (address_error.isEmpty() && addresses.isObject()) {
                        const QJsonObject address_object = addresses.toObject();
                        for (auto it = address_object.constBegin(); it != address_object.constEnd(); ++it) {
                            const QJsonObject meta = it.value().toObject();
                            upsertAddressRow(*rows, row({
                                label.isEmpty() ? QStringLiteral("(no label)") : label,
                                it.key(),
                                normalPurpose(meta.value(QStringLiteral("purpose")).toString()),
                                QStringLiteral("")
                            }));
                        }
                    }

                    --(*pending);
                    if (*pending == 0) commit();
                });
            }
        });
    });
}

QString NuRpcService::receiveRequestSettingsKey() const
{
    const QString data_dir = QDir(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir).absolutePath();
    const QString wallet_name = m_wallet_name.trimmed().isEmpty() ? QStringLiteral("__default__") : m_wallet_name.trimmed();
    const QString hash = QString::fromLatin1(QCryptographicHash::hash(QStringLiteral("%1|%2").arg(data_dir, wallet_name).toUtf8(), QCryptographicHash::Sha256).toHex().left(32));
    return QStringLiteral("NuReceiveRequests/%1/json").arg(hash);
}

QVariantMap NuRpcService::receiveRequestMeta(const QString& address,
                                             const QString& label,
                                             const QString& amount,
                                             const QString& message,
                                             const QString& uri,
                                             const QString& date,
                                             qint64 created_ms) const
{
    const qint64 timestamp = created_ms > 0 ? created_ms : QDateTime::currentMSecsSinceEpoch();
    const QString display_date = date.trimmed().isEmpty()
        ? QDateTime::fromMSecsSinceEpoch(timestamp).toString(QStringLiteral("MM/dd/yy HH:mm"))
        : date.trimmed();
    const QString clean_address = address.trimmed();
    const QString clean_label = label.trimmed();
    const QString clean_amount = amount.trimmed();
    const QString clean_message = message.trimmed();
    const QString clean_uri = uri.trimmed().isEmpty()
        ? defcoinUri(clean_address, clean_amount, clean_label, clean_message)
        : uri.trimmed();

    QVariantMap meta;
    meta.insert(QStringLiteral("kind"), QStringLiteral("receiveRequest"));
    meta.insert(QStringLiteral("address"), clean_address);
    meta.insert(QStringLiteral("label"), clean_label);
    meta.insert(QStringLiteral("amount"), clean_amount);
    meta.insert(QStringLiteral("message"), clean_message);
    meta.insert(QStringLiteral("uri"), clean_uri);
    meta.insert(QStringLiteral("date"), display_date);
    meta.insert(QStringLiteral("createdMs"), timestamp);
    meta.insert(QStringLiteral("qrSource"), qrSourceForUri(clean_uri));
    return meta;
}

QVariantMap NuRpcService::receiveRequestRow(const QVariantMap& meta) const
{
    const QString label = meta.value(QStringLiteral("label")).toString().trimmed();
    return tableRow({
        QString(),
        meta.value(QStringLiteral("date")).toString(),
        label.isEmpty() ? QStringLiteral("Request") : label,
        meta.value(QStringLiteral("address")).toString(),
        meta.value(QStringLiteral("amount")).toString()
    }, meta);
}

void NuRpcService::loadReceiveRequests()
{
    const QString key = receiveRequestSettingsKey();
    if (m_loaded_receive_request_settings_key == key) return;
    m_loaded_receive_request_settings_key = key;

    QSettings settings;
    const QString raw = settings.value(key).toString();
    QVariantList rows;
    if (!raw.trimmed().isEmpty()) {
        const QJsonDocument doc = QJsonDocument::fromJson(raw.toUtf8());
        if (doc.isArray()) {
            for (const QJsonValue& value : doc.array()) {
                const QJsonObject item = value.toObject();
                const QString address = item.value(QStringLiteral("address")).toString().trimmed();
                if (address.isEmpty()) continue;
                const QVariantMap meta = receiveRequestMeta(address,
                                                            item.value(QStringLiteral("label")).toString(),
                                                            item.value(QStringLiteral("amount")).toString(),
                                                            item.value(QStringLiteral("message")).toString(),
                                                            item.value(QStringLiteral("uri")).toString(),
                                                            item.value(QStringLiteral("date")).toString(),
                                                            item.value(QStringLiteral("createdMs")).toVariant().toLongLong());
                rows.push_back(receiveRequestRow(meta));
            }
        }
    }

    if (m_receive_requests == rows) return;
    m_receive_requests = rows;
    Q_EMIT walletChanged();
}

void NuRpcService::saveReceiveRequests() const
{
    QJsonArray records;
    for (const QVariant& value : m_receive_requests) {
        const QVariantMap meta = value.toMap().value(QStringLiteral("meta")).toMap();
        const QString address = meta.value(QStringLiteral("address")).toString().trimmed();
        if (address.isEmpty()) continue;
        QJsonObject item;
        item.insert(QStringLiteral("address"), address);
        item.insert(QStringLiteral("label"), meta.value(QStringLiteral("label")).toString());
        item.insert(QStringLiteral("amount"), meta.value(QStringLiteral("amount")).toString());
        item.insert(QStringLiteral("message"), meta.value(QStringLiteral("message")).toString());
        item.insert(QStringLiteral("uri"), meta.value(QStringLiteral("uri")).toString());
        item.insert(QStringLiteral("date"), meta.value(QStringLiteral("date")).toString());
        item.insert(QStringLiteral("createdMs"), QJsonValue::fromVariant(meta.value(QStringLiteral("createdMs"))));
        records.push_back(item);
    }

    QSettings settings;
    settings.setValue(receiveRequestSettingsKey(), QString::fromUtf8(QJsonDocument(records).toJson(QJsonDocument::Compact)));
    settings.sync();
}

void NuRpcService::sampleTraffic()
{
    rpcCall(QStringLiteral("getnettotals"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) return;
        const QJsonObject totals = result.toObject();
        const qint64 now_ms = m_uptime.elapsed();
        const qint64 now_wall_ms = QDateTime::currentMSecsSinceEpoch();
        const qint64 recv = totals.value(QStringLiteral("totalbytesrecv")).toVariant().toLongLong();
        const qint64 sent = totals.value(QStringLiteral("totalbytessent")).toVariant().toLongLong();
        m_traffic_received_total = formatBytes(recv);
        m_traffic_sent_total = formatBytes(sent);

        double recv_rate = 0.0;
        double sent_rate = 0.0;
        qint64 recv_delta = 0;
        qint64 sent_delta = 0;
        bool sync_transport_changed = false;
        if (m_last_traffic_ms > 0 && now_ms > m_last_traffic_ms) {
            const double seconds = (now_ms - m_last_traffic_ms) / 1000.0;
            recv_delta = qMax<qint64>(0, recv - m_last_bytes_recv);
            sent_delta = qMax<qint64>(0, sent - m_last_bytes_sent);
            recv_rate = qMax(0.0, recv_delta / seconds);
            sent_rate = qMax(0.0, sent_delta / seconds);
            if (m_syncing && seconds > 0.0 && (recv_delta > 0 || sent_delta > 0)) {
                m_sync_tcp_bytes_received += recv_delta;
                m_sync_tcp_bytes_sent += sent_delta;
                m_sync_tcp_active_seconds += seconds;
                sync_transport_changed = true;
            }
        }

        m_last_traffic_ms = now_ms;
        m_last_bytes_recv = recv;
        m_last_bytes_sent = sent;

        QVariantMap point;
        point.insert(QStringLiteral("seconds"), now_ms / 1000.0);
        point.insert(QStringLiteral("timestampMs"), now_wall_ms);
        point.insert(QStringLiteral("received"), recv_rate);
        point.insert(QStringLiteral("sent"), sent_rate);
        point.insert(QStringLiteral("sampleCount"), 1);

        const qint64 bucket_ms = now_wall_ms - (now_wall_ms % TRAFFIC_CHART_BUCKET_MS);
        if (!m_traffic_samples.isEmpty()) {
            const QVariantMap last_point = m_traffic_samples.constLast().toMap();
            const qint64 last_timestamp_ms = last_point.value(QStringLiteral("timestampMs")).toLongLong();
            const qint64 last_bucket_ms = last_timestamp_ms - (last_timestamp_ms % TRAFFIC_CHART_BUCKET_MS);
            if (last_bucket_ms == bucket_ms) {
                const int sample_count = qMax(1, last_point.value(QStringLiteral("sampleCount")).toInt());
                const int next_count = sample_count + 1;
                point.insert(QStringLiteral("received"), ((last_point.value(QStringLiteral("received")).toDouble() * sample_count) + recv_rate) / next_count);
                point.insert(QStringLiteral("sent"), ((last_point.value(QStringLiteral("sent")).toDouble() * sample_count) + sent_rate) / next_count);
                point.insert(QStringLiteral("sampleCount"), next_count);
                m_traffic_samples.last() = point;
            } else {
                m_traffic_samples.push_back(point);
            }
        } else {
            m_traffic_samples.push_back(point);
        }

        const qint64 cutoff_ms = now_wall_ms - (static_cast<qint64>(TRAFFIC_CHART_MAX_SECONDS) * 1000);
        while (!m_traffic_samples.isEmpty() && m_traffic_samples.constFirst().toMap().value(QStringLiteral("timestampMs")).toLongLong() < cutoff_ms) {
            m_traffic_samples.removeFirst();
        }
        while (m_traffic_samples.size() > TRAFFIC_CHART_MAX_SAMPLES) {
            m_traffic_samples.removeFirst();
        }
        if (sync_transport_changed) {
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
        }
        Q_EMIT trafficChanged();
    });
}

void NuRpcService::ensureLanFastSyncSocket()
{
    if (!m_lan_fast_sync_enabled) {
        stopLanFastSyncSocket();
        return;
    }
    if (m_lan_fast_sync_socket) return;

    m_lan_fast_sync_socket = new QUdpSocket(this);
    connect(m_lan_fast_sync_socket, &QUdpSocket::readyRead, this, &NuRpcService::handleLanFastSyncDatagrams);
    if (!m_lan_fast_sync_socket->bind(QHostAddress::Any,
                                      LAN_FAST_SYNC_PORT,
                                      QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync unavailable: %1").arg(m_lan_fast_sync_socket->errorString());
        m_lan_fast_sync_socket->deleteLater();
        m_lan_fast_sync_socket = nullptr;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    m_lan_fast_sync_socket->setSocketOption(QAbstractSocket::MulticastTtlOption, 1);
    m_lan_fast_sync_status = QStringLiteral("UDP fast sync listening on port %1.").arg(LAN_FAST_SYNC_PORT);
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
}

bool NuRpcService::isLocalInterfaceAddress(const QHostAddress& address) const
{
    if (address.isNull()) return false;
    if (address.isLoopback()) return true;
    const QString normalized = normalizedFastSyncHost(address);
    for (const QNetworkInterface& iface : QNetworkInterface::allInterfaces()) {
        const QNetworkInterface::InterfaceFlags flags = iface.flags();
        if (!(flags & QNetworkInterface::IsUp)) continue;
        for (const QNetworkAddressEntry& entry : iface.addressEntries()) {
            const QHostAddress local = entry.ip();
            if (local.isNull()) continue;
            if (normalizedFastSyncHost(local) == normalized) return true;
        }
    }
    return false;
}

void NuRpcService::sendLanDiscoveryAnnouncement()
{
    if (!m_lan_fast_sync_socket || !m_lan_fast_sync_enabled || !m_lan_node_discovery_enabled) return;

    QSettings settings;
    if (m_lan_discovery_node_id.isEmpty()) {
        m_lan_discovery_node_id = settings.value(QStringLiteral("LanDiscoveryNodeId")).toString();
        if (m_lan_discovery_node_id.isEmpty()) {
            m_lan_discovery_node_id = QUuid::createUuid().toString(QUuid::Id128);
            settings.setValue(QStringLiteral("LanDiscoveryNodeId"), m_lan_discovery_node_id);
        }
    }

    const QString host_name = lanWorkstationNameFromCandidate(QHostInfo::localHostName());
    const QString workstation_name = host_name.isEmpty()
        ? lanWorkstationNameFromCandidate(QSysInfo::machineHostName())
        : host_name;
    if (workstation_name.isEmpty()) return;

    QJsonObject message;
    message.insert(QStringLiteral("type"), QStringLiteral("defcoin-nu-lan-announce"));
    message.insert(QStringLiteral("version"), 1);
    message.insert(QStringLiteral("product"), QStringLiteral("Defcoin Core Nu"));
    message.insert(QStringLiteral("build"), QStringLiteral(DEFCOIN_NU_VERSION));
    message.insert(QStringLiteral("node_id"), m_lan_discovery_node_id);
    message.insert(QStringLiteral("platform"), QSysInfo::prettyProductName());
    message.insert(QStringLiteral("arch"), QSysInfo::currentCpuArchitecture());
    message.insert(QStringLiteral("lan_discovery_protocol"), QStringLiteral("defcoin-nu-lan-announce-v1"));
    message.insert(QStringLiteral("p2p_port"), int(DEFCOIN_DEFAULT_P2P_PORT));
    message.insert(QStringLiteral("fastsync_port"), int(LAN_FAST_SYNC_PORT));
    message.insert(QStringLiteral("host"), workstation_name);
    message.insert(QStringLiteral("workstation_name"), workstation_name);
    message.insert(QStringLiteral("quick_clone_protocol"), QStringLiteral("dcol-manifest-v1"));
    message.insert(QStringLiteral("quick_clone_snapshot_available"), false);
    message.insert(QStringLiteral("quick_clone_export_status"), QStringLiteral("not-prepared"));

    const QByteArray payload = QJsonDocument(message).toJson(QJsonDocument::Compact);
    if (payload.isEmpty() || payload.size() > LAN_DISCOVERY_ANNOUNCE_MAX_BYTES) return;

    QSet<QString> targets;
    auto addTarget = [&targets](const QHostAddress& address) {
        if (address.isNull()) return;
        targets.insert(address.toString());
    };
    addTarget(QHostAddress::Broadcast);

    for (const QNetworkInterface& iface : QNetworkInterface::allInterfaces()) {
        const QNetworkInterface::InterfaceFlags flags = iface.flags();
        if (!(flags & QNetworkInterface::IsUp) ||
            !(flags & QNetworkInterface::CanBroadcast) ||
            (flags & QNetworkInterface::IsLoopBack)) {
            continue;
        }
        for (const QNetworkAddressEntry& entry : iface.addressEntries()) {
            const QHostAddress local = entry.ip();
            if (local.protocol() != QAbstractSocket::IPv4Protocol || isInvalidLanDiscoveryAddress(local)) continue;
            QHostAddress broadcast = entry.broadcast();
            if (broadcast.isNull()) {
                const int prefix = entry.prefixLength();
                if (prefix <= 0 || prefix >= 32) continue;
                const quint32 mask = prefix == 0 ? 0 : (0xffffffffu << (32 - prefix));
                broadcast = QHostAddress((local.toIPv4Address() & mask) | ~mask);
            }
            if (!broadcast.isNull() && !isLocalInterfaceAddress(broadcast)) addTarget(broadcast);
        }
    }

    for (const QString& target_text : std::as_const(targets)) {
        QHostAddress target(target_text);
        if (target.isNull()) continue;
        m_lan_fast_sync_socket->writeDatagram(payload, target, LAN_FAST_SYNC_PORT);
    }
}

void NuRpcService::queueLanDiscoveryAddNode(const QString& host, quint16 p2p_port)
{
    QHostAddress address;
    if (!address.setAddress(host.trimmed()) || isInvalidLanDiscoveryAddress(address) || isLocalInterfaceAddress(address)) return;
    if (!isPrivateOrLocalFastSyncAddress(address) && !isOnLocalInterfaceSubnet(address.toString())) return;

    const QString normalized = normalizedFastSyncHost(address);
    const QString endpoint = address.protocol() == QAbstractSocket::IPv6Protocol
        ? QStringLiteral("[%1]:%2").arg(normalized, QString::number(p2p_port))
        : QStringLiteral("%1:%2").arg(normalized, QString::number(p2p_port));
    const QString endpoint_key = endpoint.toLower();
    if (m_lan_discovery_added_endpoints.contains(endpoint_key) ||
        m_lan_discovery_addnode_pending.contains(endpoint_key) ||
        m_lan_discovery_addnode_inflight.contains(endpoint_key)) {
        return;
    }

    m_lan_discovery_addnode_pending.insert(endpoint_key);
    processQueuedLanDiscoveryAddNodes();
}

void NuRpcService::processQueuedLanDiscoveryAddNodes()
{
    if (!m_rpc_connected || m_lan_discovery_addnode_pending.isEmpty()) return;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (m_lan_discovery_last_addnode_attempt_ms > 0 &&
        now - m_lan_discovery_last_addnode_attempt_ms < 5000) {
        return;
    }
    m_lan_discovery_last_addnode_attempt_ms = now;
    const QList<QString> pending = m_lan_discovery_addnode_pending.values();
    for (const QString& endpoint_key : pending) {
        if (m_lan_discovery_added_endpoints.contains(endpoint_key) ||
            m_lan_discovery_addnode_inflight.contains(endpoint_key)) {
            m_lan_discovery_addnode_pending.remove(endpoint_key);
            continue;
        }
        m_lan_discovery_addnode_pending.remove(endpoint_key);
        m_lan_discovery_addnode_inflight.insert(endpoint_key);
        rpcCall(QStringLiteral("addnode"), {endpoint_key, QStringLiteral("add")}, false, [this, endpoint_key](const QJsonValue&, const QString& error) {
            m_lan_discovery_addnode_inflight.remove(endpoint_key);
            if (error.isEmpty() || error.contains(QStringLiteral("already"), Qt::CaseInsensitive)) {
                m_lan_discovery_added_endpoints.insert(endpoint_key);
                refreshNode();
            } else if (error.contains(QStringLiteral("warmup"), Qt::CaseInsensitive) ||
                       error.contains(QStringLiteral("loading block index"), Qt::CaseInsensitive) ||
                       error.contains(QStringLiteral("rewinding"), Qt::CaseInsensitive) ||
                       error.contains(QStringLiteral("verifying"), Qt::CaseInsensitive)) {
                m_lan_discovery_addnode_pending.insert(endpoint_key);
            } else {
                recordFastSyncUdpDiagnostic(QStringLiteral("LAN discovery addnode failed"), error.left(240));
            }
        });
    }
}

void NuRpcService::handleLanDiscoveryAnnouncement(const QJsonObject& message, const QHostAddress& sender, quint16)
{
    if (message.value(QStringLiteral("type")).toString() != QLatin1String("defcoin-nu-lan-announce")) return;
    if (message.value(QStringLiteral("version")).toInt(0) != 1) return;
    if (message.value(QStringLiteral("product")).toString() != QLatin1String("Defcoin Core Nu")) return;
    if (isInvalidLanDiscoveryAddress(sender) || isLocalInterfaceAddress(sender)) return;
    if (!isPrivateOrLocalFastSyncAddress(sender) && !isOnLocalInterfaceSubnet(sender.toString())) return;

    const QString sender_key = normalizedFastSyncHost(sender);
    if (sender_key.isEmpty()) return;
    m_lan_quick_clone_candidate_hosts.insert(sender_key);
    if (message.value(QStringLiteral("quick_clone_snapshot_available")).toBool(false)) {
        m_quick_clone_snapshot_candidate_hosts.insert(sender_key);
    } else {
        m_quick_clone_snapshot_candidate_hosts.remove(sender_key);
    }
    if (!m_lan_discovery_node_id.isEmpty() &&
        message.value(QStringLiteral("node_id")).toString() == m_lan_discovery_node_id) {
        return;
    }

    const QString announced_name = lanWorkstationNameFromCandidate(
        message.value(QStringLiteral("workstation_name")).toString(
            message.value(QStringLiteral("host")).toString()));
    const quint16 p2p_port = quint16(qBound(1, message.value(QStringLiteral("p2p_port")).toInt(DEFCOIN_DEFAULT_P2P_PORT), 65535));

    bool changed = false;
    if (!announced_name.isEmpty()) {
        if (m_peer_lan_name_by_host.value(sender_key) != announced_name) {
            m_peer_lan_name_by_host.insert(sender_key, announced_name);
            changed = true;
        }
        const QString info = QStringLiteral("Nu LAN beacon | %1").arg(announced_name);
        if (m_peer_lan_info_by_host.value(sender_key) != info) {
            m_peer_lan_info_by_host.insert(sender_key, info);
            changed = true;
        }
        m_peer_lan_lookup_pending.remove(sender_key);
    } else {
        // Bad or ambiguous announced names are display-only failures. Keep the
        // endpoint usable for normal P2P/Fast Sync and let the older probes try.
        scheduleLanPeerNameLookups(sender.toString());
    }

    queueLanDiscoveryAddNode(sender.toString(), p2p_port);
    evaluateQuickClonePrompt();
    if (changed) refreshNode();
}

void NuRpcService::stopLanFastSyncSocket()
{
    releaseAllLanFastSyncReservations();
    if (m_lan_fast_sync_socket) {
        m_lan_fast_sync_socket->close();
        m_lan_fast_sync_socket->deleteLater();
        m_lan_fast_sync_socket = nullptr;
    }
    m_lan_fast_sync_chunks.clear();
    m_lan_fast_sync_assembled_bytes = 0;
    m_lan_fast_sync_transfers_by_id.clear();
    m_lan_fast_sync_ready_blocks_by_height.clear();
    m_udp_fast_sync_current_target_hosts.clear();
    m_lan_fast_sync_request_in_flight = false;
    m_lan_fast_sync_reserve_in_flight = false;
    m_lan_fast_sync_submit_in_flight = false;
}

QString NuRpcService::lanFastSyncRateSummary() const
{
    const double seconds = m_lan_fast_sync_udp_first_activity_ms > 0 && m_lan_fast_sync_udp_last_activity_ms > m_lan_fast_sync_udp_first_activity_ms
        ? qMax(1.0, double(m_lan_fast_sync_udp_last_activity_ms - m_lan_fast_sync_udp_first_activity_ms) / 1000.0)
        : 1.0;
    const double blocks_per_second = m_lan_fast_sync_blocks_received / seconds;
    const double bytes_per_second = (m_lan_fast_sync_udp_bytes_received + m_lan_fast_sync_udp_bytes_sent) / seconds;
    return QStringLiteral("%1 blocks/s | %2/s")
        .arg(QString::number(blocks_per_second, 'f', blocks_per_second >= 10.0 ? 1 : 2),
             formatBytes(static_cast<qint64>(bytes_per_second)));
}

QString NuRpcService::lanFastSyncMethodSummary() const
{
    QStringList methods;
    if (m_sync_tcp_bytes_received > 0 || m_sync_tcp_bytes_sent > 0) {
        methods.push_back(QStringLiteral("TCP sync"));
    }
    if (m_lan_fast_sync_udp_bytes_received > 0 || m_lan_fast_sync_udp_bytes_sent > 0) {
        methods.push_back(QStringLiteral("UDP fast sync: %1 block%2 accepted, %3 retransmit error%4 (OK)")
            .arg(m_lan_fast_sync_blocks_received)
            .arg(m_lan_fast_sync_blocks_received == 1 ? QString() : QStringLiteral("s"))
            .arg(m_lan_fast_sync_retransmit_errors)
            .arg(m_lan_fast_sync_retransmit_errors == 1 ? QString() : QStringLiteral("s")));
    }
    if (!methods.isEmpty()) return methods.join(QStringLiteral(" + "));
    return m_syncing ? QStringLiteral("No sync transport observed yet") : QStringLiteral("No sync transport observed this session");
}

QString NuRpcService::syncTransportSpeedSummary() const
{
    const qint64 tcp_total = m_sync_tcp_bytes_received + m_sync_tcp_bytes_sent;
    const qint64 udp_total = m_lan_fast_sync_udp_bytes_received + m_lan_fast_sync_udp_bytes_sent;
    const qint64 combined_total = tcp_total + udp_total;
    const int udp_blocks = m_lan_fast_sync_blocks_received;
    const int core_blocks = m_fast_sync_tcp_successes;
    const int block_total = udp_blocks + core_blocks;
    const double tcp_seconds = tcp_total > 0 ? qMax(1.0, m_sync_tcp_active_seconds) : 0.0;
    const double udp_seconds = udp_total > 0
        ? (m_lan_fast_sync_udp_first_activity_ms > 0 && m_lan_fast_sync_udp_last_activity_ms > m_lan_fast_sync_udp_first_activity_ms
            ? qMax(1.0, double(m_lan_fast_sync_udp_last_activity_ms - m_lan_fast_sync_udp_first_activity_ms) / 1000.0)
            : 1.0)
        : 0.0;
    const double combined_seconds = qMax(tcp_seconds, udp_seconds);

    auto volume_rate = [this](qint64 bytes, double seconds) {
        if (bytes <= 0) return QStringLiteral("-");
        const qint64 average_rate = static_cast<qint64>(std::llround(bytes / qMax(1.0, seconds)));
        return QStringLiteral("%1/s avg (%2)").arg(formatBytes(average_rate), formatBytes(bytes));
    };
    auto percent_text = [](int part, int total) {
        if (total <= 0) return QStringLiteral("-");
        const double percent = (100.0 * static_cast<double>(part)) / static_cast<double>(total);
        return QStringLiteral("%1%").arg(QString::number(percent, 'f', percent >= 10.0 ? 0 : 1));
    };

    QStringList parts;
    parts.push_back(QStringLiteral("Blocks: UDP %1/%2 (%3), Core/TCP %4/%2 (%5)")
                        .arg(udp_blocks)
                        .arg(block_total)
                        .arg(percent_text(udp_blocks, block_total))
                        .arg(core_blocks)
                        .arg(percent_text(core_blocks, block_total)));
    parts.push_back(QStringLiteral("Avg data: all %1, TCP/Core %2, UDP %3")
                        .arg(volume_rate(combined_total, combined_seconds),
                             volume_rate(tcp_total, tcp_seconds),
                             volume_rate(udp_total, udp_seconds)));
    parts.push_back(QStringLiteral("UDP failures %1").arg(m_fast_sync_udp_failures));
    return parts.join(QStringLiteral(" | "));
}

QString NuRpcService::coreSyncPathSummary() const
{
    const qint64 total = m_sync_tcp_bytes_received + m_sync_tcp_bytes_sent;
    const double seconds = total > 0 ? qMax(1.0, m_sync_tcp_active_seconds) : 0.0;
    const int udp_blocks = m_lan_fast_sync_blocks_received;
    const int core_blocks = m_fast_sync_tcp_successes;
    const int block_total = udp_blocks + core_blocks;
    const double share = block_total > 0 ? (100.0 * static_cast<double>(core_blocks)) / static_cast<double>(block_total) : -1.0;
    const QString avg = total > 0
        ? QStringLiteral("%1/s data avg over %2s")
              .arg(formatBytes(static_cast<qint64>(std::llround(total / qMax(1.0, seconds)))),
                   QString::number(seconds, 'f', seconds >= 10.0 ? 0 : 1))
        : QStringLiteral("-");
    const QString ewma = m_fast_sync_tcp_ewma_blocks_per_second > 0.0
        ? QStringLiteral("%1 blk/s recent").arg(QString::number(m_fast_sync_tcp_ewma_blocks_per_second, 'f', m_fast_sync_tcp_ewma_blocks_per_second >= 10.0 ? 1 : 2))
        : QStringLiteral("recent waiting");
    return QStringLiteral("Core/TCP path %1/%2 blocks%3 | %4 | %5 | data %6 (in %7, out %8) | fail %9")
        .arg(QString::number(core_blocks),
             QString::number(block_total),
             share >= 0.0 ? QStringLiteral(" (%1%)").arg(QString::number(share, 'f', share >= 10.0 ? 0 : 1)) : QString(),
             avg,
             ewma,
             formatBytes(total),
             formatBytes(m_sync_tcp_bytes_received),
             formatBytes(m_sync_tcp_bytes_sent),
             QString::number(m_fast_sync_tcp_failures));
}

QString NuRpcService::fastSyncUdpSummary() const
{
    const int udp_samples = m_fast_sync_udp_successes + m_fast_sync_udp_failures;
    int probe_misses = 0;
    for (auto it = m_udp_fast_sync_probe_failures_by_host.constBegin(); it != m_udp_fast_sync_probe_failures_by_host.constEnd(); ++it) {
        probe_misses += it.value();
    }
    const int udp_warmup_percent = FAST_SYNC_PROTOCOL_MIN_UDP_PROBES > 0
        ? std::clamp((udp_samples * 100) / FAST_SYNC_PROTOCOL_MIN_UDP_PROBES, 0, 100)
        : 100;
    const qint64 total = m_lan_fast_sync_udp_bytes_received + m_lan_fast_sync_udp_bytes_sent;
    const int udp_blocks = m_lan_fast_sync_blocks_received;
    const int core_blocks = m_fast_sync_tcp_successes;
    const int block_total = udp_blocks + core_blocks;
    const double share = block_total > 0 ? (100.0 * static_cast<double>(udp_blocks)) / static_cast<double>(block_total) : -1.0;
    const double seconds = (m_lan_fast_sync_udp_first_activity_ms > 0 && m_lan_fast_sync_udp_last_activity_ms > m_lan_fast_sync_udp_first_activity_ms)
        ? qMax(1.0, double(m_lan_fast_sync_udp_last_activity_ms - m_lan_fast_sync_udp_first_activity_ms) / 1000.0)
        : (total > 0 || m_fast_sync_udp_failures > 0 ? 1.0 : 0.0);
    const QString avg = total > 0
        ? QStringLiteral("%1/s data avg over %2s")
              .arg(formatBytes(static_cast<qint64>(std::llround(total / qMax(1.0, seconds)))),
                   QString::number(seconds, 'f', seconds >= 10.0 ? 0 : 1))
        : QStringLiteral("-");
    const QString ewma = m_fast_sync_udp_ewma_blocks_per_second > 0.0
        ? QStringLiteral("%1 blk/s recent").arg(QString::number(m_fast_sync_udp_ewma_blocks_per_second, 'f', m_fast_sync_udp_ewma_blocks_per_second >= 10.0 ? 1 : 2))
        : QStringLiteral("recent warming %1/%2 (%3%)")
              .arg(QString::number(udp_samples),
                   QString::number(FAST_SYNC_PROTOCOL_MIN_UDP_PROBES),
                   QString::number(udp_warmup_percent));
    return QStringLiteral("UDP %1/%2 blocks%3 | %4 | %5 | data %6 (in %7, out %8) | pkts %9/%10 | payload fail T/C/B/S %11/%12/%13/%14 | send fail req/probe %15/%16 | probe miss %17 | retry %18")
        .arg(QString::number(udp_blocks),
             QString::number(block_total),
             share >= 0.0 ? QStringLiteral(" (%1%)").arg(QString::number(share, 'f', share >= 10.0 ? 0 : 1)) : QString(),
             avg,
             ewma,
             formatBytes(total),
             formatBytes(m_lan_fast_sync_udp_bytes_received),
             formatBytes(m_lan_fast_sync_udp_bytes_sent),
             QString::number(m_lan_fast_sync_udp_packets_received),
             QString::number(m_lan_fast_sync_udp_packets_sent),
             QString::number(m_fast_sync_udp_request_timeouts),
             QString::number(m_fast_sync_udp_checksum_failures),
             QString::number(m_fast_sync_udp_buffer_failures),
             QString::number(m_fast_sync_udp_submit_failures),
             QString::number(m_fast_sync_udp_request_send_failures),
             QString::number(m_fast_sync_udp_probe_send_failures),
             QString::number(probe_misses),
             QString::number(m_lan_fast_sync_retransmit_errors));
}

QString NuRpcService::syncTransportDecisionSummary() const
{
    const int udp_samples = m_fast_sync_udp_successes + m_fast_sync_udp_failures;
    const int udp_warmup_percent = FAST_SYNC_PROTOCOL_MIN_UDP_PROBES > 0
        ? std::clamp((udp_samples * 100) / FAST_SYNC_PROTOCOL_MIN_UDP_PROBES, 0, 100)
        : 100;
    const QString core_rate = m_fast_sync_tcp_ewma_blocks_per_second > 0.0
        ? QStringLiteral("Core %1 adv/s").arg(QString::number(m_fast_sync_tcp_ewma_blocks_per_second, 'f', m_fast_sync_tcp_ewma_blocks_per_second >= 10.0 ? 1 : 2))
        : QStringLiteral("Core waiting");
    const QString udp_rate = m_fast_sync_udp_ewma_blocks_per_second > 0.0
        ? QStringLiteral("UDP %1 blk/s").arg(QString::number(m_fast_sync_udp_ewma_blocks_per_second, 'f', m_fast_sync_udp_ewma_blocks_per_second >= 10.0 ? 1 : 2))
        : QStringLiteral("UDP warming %1/%2 (%3%)")
              .arg(QString::number(udp_samples),
                   QString::number(FAST_SYNC_PROTOCOL_MIN_UDP_PROBES),
                   QString::number(udp_warmup_percent));
    const QString favor = m_fast_sync_decision_summary.startsWith(QStringLiteral("UDP warmup"))
        ? QStringLiteral("%1 | probing %2:%3")
              .arg(m_fast_sync_decision_summary,
                   QString::number(std::max(0, m_fast_sync_tcp_quota_remaining)),
                   QString::number(std::max(0, m_fast_sync_udp_quota_remaining)))
        : m_fast_sync_decision_summary;
    return QStringLiteral("%1 | %2 | %3")
        .arg(favor,
             core_rate,
             udp_rate);
}

QString NuRpcService::syncTransportProbeSummary() const
{
    const int udp_samples = m_fast_sync_udp_successes + m_fast_sync_udp_failures;
    int probe_misses = 0;
    for (auto it = m_udp_fast_sync_probe_failures_by_host.constBegin(); it != m_udp_fast_sync_probe_failures_by_host.constEnd(); ++it) {
        probe_misses += it.value();
    }
    const int udp_warmup_percent = FAST_SYNC_PROTOCOL_MIN_UDP_PROBES > 0
        ? std::clamp((udp_samples * 100) / FAST_SYNC_PROTOCOL_MIN_UDP_PROBES, 0, 100)
        : 100;
    const QString warmup = udp_samples < FAST_SYNC_PROTOCOL_MIN_UDP_PROBES
        ? QStringLiteral("UDP samples %1/%2 (%3%)")
              .arg(QString::number(udp_samples),
                   QString::number(FAST_SYNC_PROTOCOL_MIN_UDP_PROBES),
                   QString::number(udp_warmup_percent))
        : QStringLiteral("UDP samples %1").arg(QString::number(udp_samples));
    QSet<QString> verified_hosts = m_udp_fast_sync_available_peer_hosts;
    verified_hosts.unite(m_udp_fast_sync_used_peer_hosts);
    const int verified_peers = verified_hosts.size();
    return QStringLiteral("%1 | peers %2 candidates/%3 verified | datagram %4/%5 B | probe miss %6 | block retries %7")
        .arg(warmup,
             QString::number(m_udp_fast_sync_peer_hosts.size()),
             QString::number(verified_peers),
             QString::number(currentFastSyncDatagramSize()),
             QString::number(currentFastSyncChunkSize()),
             QString::number(probe_misses),
             QString::number(m_lan_fast_sync_retransmit_errors));
}

void NuRpcService::recordLanFastSyncUdpTraffic(qint64 sent_bytes, qint64 received_bytes)
{
    if (sent_bytes <= 0 && received_bytes <= 0) return;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (m_lan_fast_sync_udp_first_activity_ms <= 0) {
        m_lan_fast_sync_udp_first_activity_ms = now;
    }
    m_lan_fast_sync_udp_last_activity_ms = now;
    if (sent_bytes > 0) {
        m_lan_fast_sync_udp_bytes_sent += sent_bytes;
        ++m_lan_fast_sync_udp_packets_sent;
    }
    if (received_bytes > 0) {
        m_lan_fast_sync_udp_bytes_received += received_bytes;
        ++m_lan_fast_sync_udp_packets_received;
    }
}

QString NuRpcService::coreSchedulingWaitStatus(const QString& feature, const QString& reason) const
{
    const bool core_tcp_blocks_disabled = m_debug_disable_core_tcp_sync || m_debug_disable_core_sync;
    const QString suffix = core_tcp_blocks_disabled
        ? QStringLiteral("Core TCP block copy is off for this test.")
        : QStringLiteral("Core sync remains active.");
    const bool headers_ahead = m_header_height > m_block_height;
    const bool header_gate =
        reason == QLatin1String("peer-best-block-unknown") ||
        reason == QLatin1String("headers-below-minimum-chain-work") ||
        reason == QLatin1String("peer-chain-not-ahead") ||
        reason == QLatin1String("no-downloadable-block");

    if (header_gate && headers_ahead) {
        return QStringLiteral("%1 waiting for headers: %2 known, %3 accepted. %4")
            .arg(feature,
                 QString::number(m_header_height),
                 QString::number(m_block_height),
                 suffix);
    }
    if (reason == QLatin1String("waiting-for-block-window")) {
        return QStringLiteral("%1 waiting for Core's block window. %2").arg(feature, suffix);
    }
    if (reason == QLatin1String("peer-in-flight-full") ||
        reason == QLatin1String("fast-sync-reservation-already-claimed") ||
        reason == QLatin1String("block-already-in-flight")) {
        return QStringLiteral("%1 waiting for an in-flight Core block to finish. %2").arg(feature, suffix);
    }
    if (reason == QLatin1String("fast-sync-udp-transport-unverified")) {
        return QStringLiteral("%1 waiting for UDP probe acknowledgement. %2").arg(feature, suffix);
    }
    return QStringLiteral("%1 waiting for Core scheduling (%2). %3")
        .arg(feature, reason, suffix);
}

QString NuRpcService::udpFastSyncEndpointText(const QHostAddress& address, quint16 port) const
{
    QString host = normalizedFastSyncHost(address);
    if (host.isEmpty()) host = address.toString();
    if (host.isEmpty()) host = QStringLiteral("unknown");
    if (port == 0) return host;
    return host.contains(QLatin1Char(':'))
        ? QStringLiteral("[%1]:%2").arg(host).arg(port)
        : QStringLiteral("%1:%2").arg(host).arg(port);
}

void NuRpcService::recordFastSyncUdpDiagnostic(const QString& reason, const QString& detail)
{
    const QString key = reason.trimmed().isEmpty() ? QStringLiteral("unspecified UDP Fast Sync issue") : reason.trimmed();
    m_udp_fast_sync_failure_reason_counts.insert(key, m_udp_fast_sync_failure_reason_counts.value(key, 0) + 1);
    if (!detail.trimmed().isEmpty()) {
        m_lan_fast_sync_last_failure_detail = detail.trimmed();
    }

    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const qint64 last = m_udp_fast_sync_last_diagnostic_ms_by_reason.value(key, 0);
    if (last > 0 && now - last < LAN_FAST_SYNC_DIAGNOSTIC_LOG_THROTTLE_MS) {
        m_udp_fast_sync_suppressed_diagnostic_count_by_reason.insert(
            key,
            m_udp_fast_sync_suppressed_diagnostic_count_by_reason.value(key, 0) + 1);
        return;
    }

    m_udp_fast_sync_last_diagnostic_ms_by_reason.insert(key, now);
    const int suppressed = m_udp_fast_sync_suppressed_diagnostic_count_by_reason.take(key);
    const QString line = QStringLiteral("udp fast sync diagnostic: %1%2%3")
        .arg(key,
             detail.trimmed().isEmpty() ? QString() : QStringLiteral(" - %1").arg(detail.trimmed()),
             suppressed > 0 ? QStringLiteral(" (suppressed %1 repeats)").arg(suppressed) : QString());
    const int debug_line = appendDebugLogLineFromNu(line);
    appendLogLine(QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t ")) + line, debug_line);
    trimLogLines();
    rebuildNodeMetrics();
    Q_EMIT logChanged();
    Q_EMIT stateChanged();
}

void NuRpcService::recordFastSyncTransportSuccess(FastSyncTransport transport, int blocks, int height, double seconds)
{
    if (blocks <= 0 || seconds <= 0.0) return;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const double sample = static_cast<double>(blocks) / seconds;
    double& ewma = transport == FastSyncTransport::UdpFastSync
        ? m_fast_sync_udp_ewma_blocks_per_second
        : m_fast_sync_tcp_ewma_blocks_per_second;
    ewma = ewma <= 0.0
        ? sample
        : (FAST_SYNC_PROTOCOL_EWMA_ALPHA * sample) + ((1.0 - FAST_SYNC_PROTOCOL_EWMA_ALPHA) * ewma);

    if (transport == FastSyncTransport::UdpFastSync) {
        if (m_lan_fast_sync_udp_first_activity_ms <= 0) {
            m_lan_fast_sync_udp_first_activity_ms = now;
        }
        m_lan_fast_sync_udp_last_activity_ms = qMax(m_lan_fast_sync_udp_last_activity_ms, now);
        m_fast_sync_udp_successes += blocks;
        m_fast_sync_last_udp_accepted_height = std::max(m_fast_sync_last_udp_accepted_height, height);
    } else {
        m_fast_sync_tcp_successes += blocks;
    }
    if (m_fast_sync_tcp_quota_remaining <= 0 && m_fast_sync_udp_quota_remaining <= 0) {
        resetFastSyncProtocolWindow();
    }
}

void NuRpcService::recordFastSyncTransportFailure(FastSyncTransport transport)
{
    if (transport == FastSyncTransport::UdpFastSync) {
        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        if (m_lan_fast_sync_udp_first_activity_ms <= 0) {
            m_lan_fast_sync_udp_first_activity_ms = now;
        }
        m_lan_fast_sync_udp_last_activity_ms = qMax(m_lan_fast_sync_udp_last_activity_ms, now);
        ++m_fast_sync_udp_failures;
        const int consecutive_penalty = std::min(8, std::max(1, m_fast_sync_udp_failures - m_fast_sync_udp_successes + 1));
        m_fast_sync_udp_cooldown_until_ms = now + (1000LL << consecutive_penalty);
        m_fast_sync_udp_ewma_blocks_per_second *= 0.5;
    } else {
        ++m_fast_sync_tcp_failures;
        m_fast_sync_tcp_ewma_blocks_per_second *= 0.5;
    }
    if (m_fast_sync_tcp_quota_remaining <= 0 && m_fast_sync_udp_quota_remaining <= 0) {
        resetFastSyncProtocolWindow();
    }
}

void NuRpcService::recordFastSyncUdpSuccess(int height, qint64 latency_ms)
{
    recordFastSyncTransportSuccess(FastSyncTransport::UdpFastSync, 1, height, qMax(0.001, double(latency_ms) / 1000.0));
}

void NuRpcService::recordFastSyncUdpFailure(FastSyncUdpFailureKind kind)
{
    switch (kind) {
    case FastSyncUdpFailureKind::ProbeSend:
        ++m_fast_sync_udp_probe_send_failures;
        break;
    case FastSyncUdpFailureKind::RequestSend:
        ++m_fast_sync_udp_request_send_failures;
        break;
    case FastSyncUdpFailureKind::RequestTimeout:
        ++m_fast_sync_udp_request_timeouts;
        break;
    case FastSyncUdpFailureKind::Checksum:
        ++m_fast_sync_udp_checksum_failures;
        break;
    case FastSyncUdpFailureKind::Buffer:
        ++m_fast_sync_udp_buffer_failures;
        break;
    case FastSyncUdpFailureKind::Submit:
        ++m_fast_sync_udp_submit_failures;
        break;
    }
    recordFastSyncTransportFailure(FastSyncTransport::UdpFastSync);
}

void NuRpcService::recordCoreSyncPathProgress(int blocks, double seconds)
{
    recordFastSyncTransportSuccess(FastSyncTransport::TcpCore, blocks, -1, seconds);
}

void NuRpcService::resetFastSyncProtocolWindow()
{
    const bool udp_possible = m_lan_fast_sync_enabled && !m_udp_fast_sync_peer_hosts.isEmpty();
    const bool core_tcp_blocks_disabled = m_debug_disable_core_tcp_sync || m_debug_disable_core_sync;
    if (!udp_possible) {
        m_fast_sync_tcp_quota_remaining = 1;
        m_fast_sync_udp_quota_remaining = 0;
        m_fast_sync_window_size = 2;
        m_fast_sync_decision_summary = QStringLiteral("Core sync only");
        return;
    }

    const int udp_samples = m_fast_sync_udp_successes + m_fast_sync_udp_failures;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const bool udp_in_cooldown = now < m_fast_sync_udp_cooldown_until_ms;
    const bool force_probe = (now - m_fast_sync_last_probe_ms) >= FAST_SYNC_PROTOCOL_PROBE_INTERVAL_MS;

    if (core_tcp_blocks_disabled) {
        m_fast_sync_window_size = std::max(4, std::min(FAST_SYNC_PROTOCOL_MAX_WINDOW, m_fast_sync_window_size));
        m_fast_sync_tcp_quota_remaining = 0;
        if (udp_in_cooldown && !force_probe) {
            m_fast_sync_udp_quota_remaining = 0;
            m_fast_sync_decision_summary = QStringLiteral("UDP test mode; waiting for UDP cooldown");
            return;
        }
        m_fast_sync_udp_quota_remaining = m_fast_sync_window_size;
        m_fast_sync_decision_summary = QStringLiteral("UDP test mode; Core TCP block copy disabled");
        return;
    }

    if (!udp_in_cooldown && udp_samples < FAST_SYNC_PROTOCOL_MIN_UDP_PROBES) {
        m_fast_sync_window_size = std::max(4, std::min(FAST_SYNC_PROTOCOL_MAX_WINDOW, m_fast_sync_window_size));
        m_fast_sync_udp_quota_remaining = 3;
        m_fast_sync_tcp_quota_remaining = 1;
        m_fast_sync_last_probe_ms = now;
        const int udp_warmup_percent = FAST_SYNC_PROTOCOL_MIN_UDP_PROBES > 0
            ? std::clamp((udp_samples * 100) / FAST_SYNC_PROTOCOL_MIN_UDP_PROBES, 0, 100)
            : 100;
        m_fast_sync_decision_summary = QStringLiteral("UDP warmup %1/%2 (%3%)")
            .arg(QString::number(udp_samples),
                 QString::number(FAST_SYNC_PROTOCOL_MIN_UDP_PROBES),
                 QString::number(udp_warmup_percent));
        return;
    }

    const int tcp_cap = std::max(1, std::max(udp_samples, 1) * FAST_SYNC_PROTOCOL_TCP_SAMPLE_CAP_PER_UDP);
    const int effective_tcp_successes = std::min(m_fast_sync_tcp_successes, tcp_cap);
    const int effective_tcp_failures = std::min(m_fast_sync_tcp_failures, std::max(0, tcp_cap - effective_tcp_successes));
    const int effective_tcp_samples = effective_tcp_successes + effective_tcp_failures;
    const int total_samples = std::max(1, effective_tcp_samples + udp_samples);

    auto score = [total_samples](double ewma, int successes, int failures) {
        const int samples = successes + failures;
        const double rate = ewma > 0.0 ? ewma : 0.05;
        const double reliability = static_cast<double>(successes + 1) / static_cast<double>(successes + failures + 2);
        const double exploration = FAST_SYNC_PROTOCOL_EXPLORATION_C
            * std::sqrt(std::log(static_cast<double>(total_samples) + 1.0) / static_cast<double>(samples + 1));
        return rate * reliability + exploration;
    };

    const double tcp_score = score(m_fast_sync_tcp_ewma_blocks_per_second, effective_tcp_successes, effective_tcp_failures);
    const double udp_score_raw = score(m_fast_sync_udp_ewma_blocks_per_second, m_fast_sync_udp_successes, m_fast_sync_udp_failures);
    const double udp_score = udp_in_cooldown && !force_probe ? 0.0 : udp_score_raw;

    if ((tcp_score > udp_score * 1.25 || udp_score > tcp_score * 1.25) && (m_fast_sync_tcp_failures + m_fast_sync_udp_failures) == 0) {
        m_fast_sync_window_size = std::min(FAST_SYNC_PROTOCOL_MAX_WINDOW, std::max(2, m_fast_sync_window_size * 2));
    } else {
        m_fast_sync_window_size = std::max(2, std::min(m_fast_sync_window_size, FAST_SYNC_PROTOCOL_MAX_WINDOW));
    }

    const int window = std::max(2, std::min(FAST_SYNC_PROTOCOL_MAX_WINDOW, m_fast_sync_window_size));
    int udp_quota = 1;
    if (udp_score <= 0.0) {
        udp_quota = force_probe ? 1 : 0;
    } else {
        udp_quota = qBound(1, int(std::llround(window * udp_score / std::max(0.0001, tcp_score + udp_score))), window - 1);
    }
    const int tcp_quota = std::max(1, window - udp_quota);
    m_fast_sync_tcp_quota_remaining = tcp_quota;
    m_fast_sync_udp_quota_remaining = udp_quota;
    if (force_probe && udp_quota > 0) m_fast_sync_last_probe_ms = now;

    const QString favored = udp_quota > tcp_quota
        ? QStringLiteral("UDP favored %1:%2").arg(udp_quota).arg(tcp_quota)
        : (tcp_quota > udp_quota
               ? QStringLiteral("Core path favored %1:%2").arg(tcp_quota).arg(udp_quota)
               : QStringLiteral("Core/UDP balanced 1:1"));
    m_fast_sync_decision_summary = udp_in_cooldown && !force_probe
        ? QStringLiteral("Core path favored; UDP cooling")
        : favored;
}

bool NuRpcService::shouldAttemptUdpFastSync()
{
    if (!m_lan_fast_sync_enabled) return false;
    const bool core_tcp_blocks_disabled = m_debug_disable_core_tcp_sync || m_debug_disable_core_sync;
    if (m_fast_sync_tcp_quota_remaining <= 0 && m_fast_sync_udp_quota_remaining <= 0) {
        resetFastSyncProtocolWindow();
    }
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const bool udp_cooling = now < m_fast_sync_udp_cooldown_until_ms;
    const bool force_probe = (now - m_fast_sync_last_probe_ms) >= FAST_SYNC_PROTOCOL_PROBE_INTERVAL_MS;
    if (core_tcp_blocks_disabled && m_udp_fast_sync_peer_hosts.isEmpty()) {
        m_lan_fast_sync_status = QStringLiteral("UDP test mode waiting for connected Fast Sync peers; Core TCP block copy is disabled.");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return false;
    }
    if (core_tcp_blocks_disabled) {
        m_fast_sync_tcp_quota_remaining = 0;
        m_fast_sync_udp_quota_remaining = std::max(1, m_fast_sync_udp_quota_remaining);
    }
    if (udp_cooling && !force_probe) {
        m_fast_sync_udp_quota_remaining = 0;
    }
    const bool udp_due = (!udp_cooling || force_probe) &&
        !m_udp_fast_sync_peer_hosts.isEmpty() &&
        (m_fast_sync_last_udp_attempt_ms <= 0 ||
         now - m_fast_sync_last_udp_attempt_ms >= FAST_SYNC_PROTOCOL_UDP_KEEPALIVE_MS);
    if (udp_due) {
        m_fast_sync_udp_quota_remaining = std::max(1, m_fast_sync_udp_quota_remaining);
    }
    if (m_fast_sync_udp_quota_remaining > 0) {
        --m_fast_sync_udp_quota_remaining;
        return true;
    }
    if (m_fast_sync_tcp_quota_remaining > 0) {
        --m_fast_sync_tcp_quota_remaining;
    }
    m_lan_fast_sync_status = QStringLiteral("%1. Letting Core's normal sync path continue before another UDP probe.")
        .arg(m_fast_sync_decision_summary);
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
    return false;
}

void NuRpcService::updateLanFastSyncRequestState()
{
    m_lan_fast_sync_request_in_flight = !m_lan_fast_sync_transfers_by_id.isEmpty();
}

void NuRpcService::refreshLanFastSyncCurrentTargetHosts()
{
    m_udp_fast_sync_current_target_hosts.clear();
    for (const LanFastSyncTransfer& transfer : std::as_const(m_lan_fast_sync_transfers_by_id)) {
        if (!transfer.host.isEmpty()) {
            m_udp_fast_sync_current_target_hosts.insert(transfer.host);
        }
    }
}

int NuRpcService::lanFastSyncLocalInflightCount(const QString& host) const
{
    if (host.isEmpty()) return 0;
    int count = 0;
    for (const LanFastSyncTransfer& transfer : m_lan_fast_sync_transfers_by_id) {
        if (transfer.host == host) {
            ++count;
        }
    }
    return count;
}

qint64 NuRpcService::lanFastSyncBufferedBytes() const
{
    qint64 total = 0;
    for (const LanFastSyncTransfer& transfer : m_lan_fast_sync_transfers_by_id) {
        total += transfer.assembled_bytes;
    }
    for (const LanFastSyncReadyBlock& ready : m_lan_fast_sync_ready_blocks_by_height) {
        total += ready.block.size();
    }
    return total;
}

bool NuRpcService::canStartMoreLanFastSyncTransfers() const
{
    return m_lan_fast_sync_transfers_by_id.size() < LAN_FAST_SYNC_MAX_INFLIGHT_BLOCKS &&
        m_lan_fast_sync_ready_blocks_by_height.size() < LAN_FAST_SYNC_MAX_READY_BLOCKS &&
        lanFastSyncBufferedBytes() < LAN_FAST_SYNC_MAX_BUFFER_BYTES;
}

void NuRpcService::releaseLanFastSyncReservationFor(int node_id, const QString& hash)
{
    if (node_id < 0 || hash.isEmpty()) return;
    rpcCall(QStringLiteral("reservefastsyncblock"),
            {QStringLiteral("release"), node_id, hash},
            false,
            [](const QJsonValue&, const QString&) {});
}

void NuRpcService::releaseAllLanFastSyncReservations()
{
    for (const LanFastSyncTransfer& transfer : std::as_const(m_lan_fast_sync_transfers_by_id)) {
        releaseLanFastSyncReservationFor(transfer.node_id, transfer.expected_hash);
    }
    for (const LanFastSyncReadyBlock& ready : std::as_const(m_lan_fast_sync_ready_blocks_by_height)) {
        releaseLanFastSyncReservationFor(ready.node_id, ready.hash);
    }
    releaseLanFastSyncReservation();
}

void NuRpcService::expireLanFastSyncTransfers(qint64 now)
{
    QStringList expired_ids;
    for (auto it = m_lan_fast_sync_transfers_by_id.constBegin(); it != m_lan_fast_sync_transfers_by_id.constEnd(); ++it) {
        const LanFastSyncTransfer& transfer = it.value();
        if (transfer.request_ms > 0 && now - transfer.request_ms > LAN_FAST_SYNC_REQUEST_TIMEOUT_MS) {
            expired_ids.push_back(it.key());
        }
    }

    for (const QString& id : std::as_const(expired_ids)) {
        const LanFastSyncTransfer transfer = m_lan_fast_sync_transfers_by_id.take(id);
        ++m_lan_fast_sync_retransmit_errors;
        recordFastSyncUdpFailure(FastSyncUdpFailureKind::RequestTimeout);
        tuneFastSyncDatagramAfterFailure();
        releaseLanFastSyncReservationFor(transfer.node_id, transfer.expected_hash);
        if (m_lan_quick_clone_enabled) {
            acknowledgeLanQuickCloneSourceOffline(
                transfer.host,
                transfer.height,
                QStringLiteral("LAN source stopped answering"));
            m_lan_quick_clone_status = QStringLiteral("Quick Clone marked %1 offline after missing chunks for block %2; trying another trusted LAN source if available.")
                .arg(transfer.host.isEmpty() ? QStringLiteral("current LAN source") : transfer.host)
                .arg(transfer.height);
            m_lan_fast_sync_status = m_lan_quick_clone_status;
        } else {
            m_lan_fast_sync_status = QStringLiteral("UDP fast sync timed out on block %1 from %2; reserving another Core-selected block.")
                .arg(transfer.height)
                .arg(transfer.host.isEmpty() ? QStringLiteral("peer") : transfer.host);
        }
    }
    if (!expired_ids.isEmpty()) {
        updateLanFastSyncRequestState();
        refreshLanFastSyncCurrentTargetHosts();
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
    }
}

void NuRpcService::submitNextLanFastSyncReadyBlock()
{
    if (m_lan_fast_sync_submit_in_flight) return;

    QList<int> stale_heights;
    for (auto it = m_lan_fast_sync_ready_blocks_by_height.constBegin(); it != m_lan_fast_sync_ready_blocks_by_height.constEnd(); ++it) {
        if (it.key() <= m_block_height) {
            stale_heights.push_back(it.key());
        }
    }
    for (int height : std::as_const(stale_heights)) {
        const LanFastSyncReadyBlock ready = m_lan_fast_sync_ready_blocks_by_height.take(height);
        releaseLanFastSyncReservationFor(ready.node_id, ready.hash);
    }

    const int next_height = m_block_height + 1;
    if (!m_lan_fast_sync_ready_blocks_by_height.contains(next_height)) {
        if (!m_lan_fast_sync_ready_blocks_by_height.isEmpty()) {
            int lowest_ready = std::numeric_limits<int>::max();
            for (auto it = m_lan_fast_sync_ready_blocks_by_height.constBegin(); it != m_lan_fast_sync_ready_blocks_by_height.constEnd(); ++it) {
                lowest_ready = qMin(lowest_ready, it.key());
            }
            m_lan_fast_sync_status = QStringLiteral("UDP fast sync has %1 block%2 staged; waiting for block %3 before submitting block %4.")
                .arg(m_lan_fast_sync_ready_blocks_by_height.size())
                .arg(m_lan_fast_sync_ready_blocks_by_height.size() == 1 ? QString() : QStringLiteral("s"))
                .arg(next_height)
                .arg(lowest_ready);
            if (m_lan_quick_clone_enabled) m_lan_quick_clone_status = m_lan_fast_sync_status;
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
        }
        return;
    }

    const LanFastSyncReadyBlock ready = m_lan_fast_sync_ready_blocks_by_height.take(next_height);
    if (ready.block.isEmpty() || ready.height <= 0) {
        releaseLanFastSyncReservationFor(ready.node_id, ready.hash);
        return;
    }

    m_lan_fast_sync_submit_in_flight = true;
    m_lan_fast_sync_status = QStringLiteral("UDP fast sync validating block %1 through Core (%2 staged behind it).")
        .arg(ready.height)
        .arg(m_lan_fast_sync_ready_blocks_by_height.size());
    if (m_lan_quick_clone_enabled) {
        m_lan_quick_clone_status = m_lan_fast_sync_status;
    }
    rebuildNodeMetrics();
    Q_EMIT stateChanged();

    const QString block_hex = QString::fromLatin1(ready.block.toHex());
    const bool clone_mode = m_lan_quick_clone_enabled;
    rpcCall(QStringLiteral("submitblock"), {block_hex}, false, [this, ready, clone_mode](const QJsonValue& result, const QString& error) {
        const QString submit_result = result.toString();
        const bool accepted = error.isEmpty()
            && (result.isNull() || submit_result.isEmpty()
                || submit_result.compare(QStringLiteral("duplicate"), Qt::CaseInsensitive) == 0
                || submit_result.compare(QStringLiteral("inconclusive"), Qt::CaseInsensitive) == 0);
        releaseLanFastSyncReservationFor(ready.node_id, ready.hash);
        m_lan_fast_sync_submit_in_flight = false;
        if (accepted) {
            const bool duplicate = submit_result.compare(QStringLiteral("duplicate"), Qt::CaseInsensitive) == 0;
            const bool inconclusive = submit_result.compare(QStringLiteral("inconclusive"), Qt::CaseInsensitive) == 0;
            if (!(clone_mode && duplicate)) {
                ++m_lan_fast_sync_blocks_received;
                m_lan_fast_sync_bytes_received += ready.block.size();
                m_lan_fast_sync_last_progress_ms = QDateTime::currentMSecsSinceEpoch();
                recordFastSyncUdpSuccess(
                    ready.height,
                    ready.request_ms > 0 ? m_lan_fast_sync_last_progress_ms - ready.request_ms : 1000);
                tuneFastSyncDatagramAfterSuccess();
            }
            if (!duplicate && !inconclusive && ready.height > m_block_height) {
                m_block_height = ready.height;
            }
            m_lan_fast_sync_status = clone_mode
                ? (duplicate
                      ? QStringLiteral("Quick Clone skipped already-known LAN block %1; continuing with the next missing block.")
                            .arg(ready.height)
                      : QStringLiteral("Quick Clone accepted LAN block %1 through Core (%2 active, %3 staged).")
                            .arg(ready.height)
                            .arg(m_lan_fast_sync_transfers_by_id.size())
                            .arg(m_lan_fast_sync_ready_blocks_by_height.size()))
                : (duplicate
                      ? QStringLiteral("UDP fast sync delivered already-known block %1; continuing with the next Core-selected block.")
                            .arg(ready.height)
                      : QStringLiteral("UDP fast sync accepted block %1 through Core (%2 active, %3 staged).")
                            .arg(ready.height)
                            .arg(m_lan_fast_sync_transfers_by_id.size())
                            .arg(m_lan_fast_sync_ready_blocks_by_height.size()));
            if (clone_mode) {
                m_lan_quick_clone_status = m_lan_fast_sync_status;
            }
            QTimer::singleShot(0, this, &NuRpcService::lanFastSyncTick);
            QTimer::singleShot(0, this, &NuRpcService::refreshNode);
        } else {
            ++m_lan_fast_sync_retransmit_errors;
            recordFastSyncUdpFailure(FastSyncUdpFailureKind::Submit);
            tuneFastSyncDatagramAfterFailure();
            m_lan_fast_sync_status = clone_mode
                ? QStringLiteral("Quick Clone block %1 was not accepted (%2); reserving a replacement.")
                      .arg(ready.height)
                      .arg(error.isEmpty() ? result.toString(QStringLiteral("unknown result")) : error)
                : QStringLiteral("UDP fast sync block %1 was not accepted (%2); normal TCP fallback remains active.")
                      .arg(ready.height)
                      .arg(error.isEmpty() ? result.toString(QStringLiteral("unknown result")) : error);
            if (clone_mode) {
                m_lan_quick_clone_status = m_lan_fast_sync_status;
            }
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
            QTimer::singleShot(0, this, &NuRpcService::lanFastSyncTick);
        }
    });
}

void NuRpcService::resetLanFastSyncTransfer(const QString& status)
{
    releaseAllLanFastSyncReservations();
    m_lan_fast_sync_chunks.clear();
    m_lan_fast_sync_assembled_bytes = 0;
    m_lan_fast_sync_request_id.clear();
    m_lan_fast_sync_current_host.clear();
    m_lan_fast_sync_block_hash.clear();
    m_lan_fast_sync_block_checksum.clear();
    m_lan_fast_sync_current_height = -1;
    m_lan_fast_sync_expected_chunks = 0;
    m_lan_fast_sync_expected_size = 0;
    m_lan_fast_sync_request_ms = 0;
    m_lan_fast_sync_request_in_flight = false;
    m_lan_fast_sync_reserve_in_flight = false;
    m_lan_fast_sync_submit_in_flight = false;
    m_lan_fast_sync_transfers_by_id.clear();
    m_lan_fast_sync_ready_blocks_by_height.clear();
    m_udp_fast_sync_current_target_hosts.clear();
    m_lan_fast_sync_status = status;
    if (m_lan_quick_clone_enabled) m_lan_quick_clone_status = status;
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
}

bool NuRpcService::isUdpFastSyncAllowedPeer(const QHostAddress& address) const
{
    if (address.isNull()) return false;
    return m_udp_fast_sync_peer_hosts.contains(normalizedFastSyncHost(address));
}

bool NuRpcService::isLanQuickCloneAllowedPeer(const QHostAddress& address) const
{
    if (address.isNull() || !m_lan_fast_sync_enabled || !isPrivateOrLocalFastSyncAddress(address)) {
        return false;
    }
    // Quick Clone scaffolding serves only public block data, never wallet material. LAN
    // requesters can be accepted before Core's normal peer state catches up.
    const QString key = normalizedFastSyncHost(address);
    return !key.isEmpty();
}

bool NuRpcService::hasPrivateUdpFastSyncTarget() const
{
    QSet<QString> hosts = m_udp_fast_sync_peer_hosts;
    for (const QString& host : m_udp_fast_sync_available_peer_hosts) hosts.insert(host);
    for (const QString& host : m_udp_fast_sync_used_peer_hosts) hosts.insert(host);
    if (m_lan_quick_clone_enabled) {
        for (const QString& host : m_lan_quick_clone_candidate_hosts) hosts.insert(host);
    }
    for (const QString& host : std::as_const(hosts)) {
        if (isPrivateLocalOrProvenUdpFastSyncTarget(host)) {
            return true;
        }
    }
    return false;
}

int NuRpcService::currentFastSyncDatagramSize() const
{
    const QVector<int> candidates = lanFastSyncDatagramCandidates(hasPrivateUdpFastSyncTarget());
    const int index = qBound(0, m_fast_sync_udp_datagram_index, candidates.size() - 1);
    return candidates.value(index, LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES);
}

int NuRpcService::currentFastSyncChunkSize() const
{
    return lanFastSyncChunkBytesForDatagram(currentFastSyncDatagramSize());
}

void NuRpcService::tuneFastSyncDatagramAfterSuccess()
{
    const QVector<int> candidates = lanFastSyncDatagramCandidates(hasPrivateUdpFastSyncTarget());
    if (m_fast_sync_udp_successes < 4 || m_fast_sync_udp_successes % 4 != 0) {
        return;
    }
    if (m_fast_sync_udp_datagram_index < candidates.size() - 1) {
        ++m_fast_sync_udp_datagram_index;
    }
}

void NuRpcService::tuneFastSyncDatagramAfterFailure()
{
    m_fast_sync_udp_datagram_index = 0;
}

void NuRpcService::lanQuickCloneTick()
{
    if (m_debug_disable_quick_clone) {
        if (m_lan_quick_clone_status != QLatin1String("Quick Clone disabled by debug launch switch.")) {
            m_lan_quick_clone_status = QStringLiteral("Quick Clone disabled by debug launch switch.");
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
        }
        return;
    }
    ensureLanFastSyncSocket();
    if (!m_lan_fast_sync_socket) {
        m_lan_quick_clone_status = QStringLiteral("Quick Clone waiting for UDP socket.");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    if (!m_rpc_connected) {
        m_lan_quick_clone_status = QStringLiteral("Quick Clone waiting for backend RPC.");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }

    processQueuedLanDiscoveryAddNodes();
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    QStringList expired_probe_hosts;
    for (auto it = m_udp_fast_sync_probe_ids_by_host.constBegin(); it != m_udp_fast_sync_probe_ids_by_host.constEnd(); ++it) {
        const QString host = it.key();
        const qint64 sent_ms = m_udp_fast_sync_last_probe_ms_by_host.value(host, 0);
        if (sent_ms > 0 && now - sent_ms > LAN_FAST_SYNC_PROBE_TIMEOUT_MS) {
            expired_probe_hosts.push_back(host);
        }
    }
    for (const QString& host : expired_probe_hosts) {
        recordUdpFastSyncPeerMiss(host, QStringLiteral("Quick Clone UDP probe timed out"));
    }

    expireLanFastSyncTransfers(now);
    submitNextLanFastSyncReadyBlock();
    if (m_lan_fast_sync_submit_in_flight || m_lan_fast_sync_reserve_in_flight) return;
    if (!canStartMoreLanFastSyncTransfers()) return;

    if (m_lan_quick_clone_reservation_backoff_until_ms > now) {
        return;
    }

    int peer_tip = -1;
    int node_id = -1;
    const QString host = selectLanQuickCloneTargetHost(&node_id, &peer_tip);
    if (host.isEmpty()) {
        int probe_node_id = -1;
        const QString probe_host = selectLanQuickCloneProbeHost(&probe_node_id);
        if (!probe_host.isEmpty() && sendUdpFastSyncProbe(probe_host, probe_node_id)) return;

        const int candidate_count = m_lan_quick_clone_candidate_hosts.size() + m_udp_fast_sync_peer_hosts.size();
        m_lan_quick_clone_status = candidate_count > 0
            ? QStringLiteral("Quick Clone waiting for a LAN source to answer UDP.")
            : QStringLiteral("Quick Clone waiting for LAN Nu beacons.");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }

    if (peer_tip >= 0 && m_block_height >= peer_tip) {
        m_lan_quick_clone_status = QStringLiteral("Quick Clone caught up to LAN source %1 at block %2.")
            .arg(host)
            .arg(peer_tip);
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        if (m_quick_clone_auto_validate_after &&
            !m_quick_clone_auto_validate_ran_this_session &&
            m_lan_fast_sync_blocks_received > 0 &&
            !m_quick_clone_validation_running) {
            m_quick_clone_auto_validate_ran_this_session = true;
            QTimer::singleShot(0, this, &NuRpcService::validateExistingBlockchain);
        }
        return;
    }

    if (m_lan_quick_clone_paused_network && !m_applying_pending_network_active) {
        m_lan_quick_clone_paused_network = false;
        m_lan_quick_clone_status = QStringLiteral("Quick Clone listening on LAN; Core P2P sync is resuming.");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        setNetworkActive(true);
        return;
    }

    if (node_id < 0) {
        m_lan_quick_clone_status = QStringLiteral("Quick Clone found LAN source %1; waiting for Core peer selection before requesting blocks.")
            .arg(host);
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }

    m_lan_fast_sync_reserve_in_flight = true;
    if (!m_lan_quick_clone_status.startsWith(QStringLiteral("Quick Clone waiting on Core scheduling"))) {
        m_lan_quick_clone_status = QStringLiteral("Quick Clone checking Core for the next LAN block from %1.")
            .arg(host);
        m_lan_fast_sync_status = m_lan_quick_clone_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
    }
    rpcCall(QStringLiteral("reservefastsyncblock"),
            {QStringLiteral("reserve-next"), node_id},
            false,
            [this, host, node_id](const QJsonValue& result, const QString& error) {
        m_lan_fast_sync_reserve_in_flight = false;
        const QJsonObject obj = result.toObject();
        const bool success = error.isEmpty() && obj.value(QStringLiteral("success")).toBool(false);
        const QString reason = error.isEmpty() ? obj.value(QStringLiteral("reason")).toString(QStringLiteral("unknown")) : error;
        const QString hash = obj.value(QStringLiteral("hash")).toString();
        const int height = obj.value(QStringLiteral("height")).toInt(-1);
        if (!success || hash.size() != 64 || height <= 0) {
            const qint64 callback_now = QDateTime::currentMSecsSinceEpoch();
            m_lan_quick_clone_reservation_backoff_until_ms = callback_now + QUICK_CLONE_RESERVATION_BACKOFF_MS;
            const QString detail = QStringLiteral("block %1 peer %2 headers %3 local-blocks %4: %5")
                .arg(height)
                .arg(node_id)
                .arg(m_header_height)
                .arg(m_block_height)
                .arg(reason);
            recordFastSyncUdpDiagnostic(QStringLiteral("Quick Clone Core reservation deferred"), detail);
            if (reason == QLatin1String("peer-not-connected")) {
                m_udp_fast_sync_peer_node_ids_by_host.remove(host);
                m_lan_quick_clone_status = QStringLiteral("Quick Clone peer reconnected; refreshing peer state before retrying LAN copy.");
                m_lan_fast_sync_status = m_lan_quick_clone_status;
                QTimer::singleShot(0, this, &NuRpcService::refreshNode);
                QTimer::singleShot(QUICK_CLONE_RESERVATION_BACKOFF_MS, this, &NuRpcService::lanFastSyncTick);
            } else {
                const bool should_update_status =
                    reason != m_lan_quick_clone_last_reservation_reason ||
                    callback_now - m_lan_quick_clone_last_reservation_status_ms >= QUICK_CLONE_RESERVATION_BACKOFF_MS;
                m_lan_quick_clone_last_reservation_reason = reason;
                if (should_update_status) {
                    m_lan_quick_clone_last_reservation_status_ms = callback_now;
                    m_lan_quick_clone_status = coreSchedulingWaitStatus(QStringLiteral("Quick Clone"), reason);
                    m_lan_fast_sync_status = m_lan_quick_clone_status;
                } else {
                    return;
                }
            }
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
            return;
        }
        m_lan_quick_clone_reservation_backoff_until_ms = 0;
        m_lan_quick_clone_last_reservation_reason.clear();
        if (height <= m_block_height) {
            m_lan_fast_sync_reserved_node_id = node_id;
            m_lan_fast_sync_reserved_hash = hash;
            releaseLanFastSyncReservation();
            m_lan_quick_clone_status = QStringLiteral("Quick Clone skipped block %1 because Core already has it; reserving the next missing block.")
                .arg(height);
            m_lan_fast_sync_status = m_lan_quick_clone_status;
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
            QTimer::singleShot(0, this, &NuRpcService::lanFastSyncTick);
            return;
        }
        m_lan_fast_sync_reserved_node_id = node_id;
        m_lan_fast_sync_reserved_hash = hash;
        m_lan_quick_clone_status = QStringLiteral("Quick Clone receiving blockchain over LAN: requesting reserved block %1 from %2.")
            .arg(height)
            .arg(host);
        sendLanFastSyncBlockRequest(height, host, node_id, hash);
    });
}

void NuRpcService::lanFastSyncTick()
{
    if (m_debug_disable_fast_sync && !m_lan_quick_clone_enabled) {
        if (m_lan_fast_sync_socket) stopLanFastSyncSocket();
        if (m_lan_fast_sync_status != QLatin1String("UDP fast sync disabled by debug launch switch.")) {
            m_lan_fast_sync_status = QStringLiteral("UDP fast sync disabled by debug launch switch.");
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
        }
        return;
    }
    if (!m_lan_fast_sync_enabled) {
        if (m_lan_fast_sync_socket) stopLanFastSyncSocket();
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync off; normal TCP sync remains active.");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }

    ensureLanFastSyncSocket();
    if (m_lan_fast_sync_socket) {
        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        if (m_lan_discovery_last_announce_ms <= 0 ||
            now - m_lan_discovery_last_announce_ms >= LAN_DISCOVERY_ANNOUNCE_INTERVAL_MS) {
            m_lan_discovery_last_announce_ms = now;
            sendLanDiscoveryAnnouncement();
        }
    }
    if (!m_lan_fast_sync_socket || !m_rpc_connected) return;
    processQueuedLanDiscoveryAddNodes();
    if (m_lan_quick_clone_enabled) {
        lanQuickCloneTick();
        return;
    }
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    expireLanFastSyncTransfers(now);
    submitNextLanFastSyncReadyBlock();
    if (!m_syncing || m_header_height <= 0 || m_block_height >= m_header_height) {
        if (m_lan_fast_sync_transfers_by_id.isEmpty() &&
            m_lan_fast_sync_ready_blocks_by_height.isEmpty() &&
            !m_lan_fast_sync_submit_in_flight &&
            !m_lan_fast_sync_reserve_in_flight) {
            QStringList expired_probe_hosts;
            for (auto it = m_udp_fast_sync_probe_ids_by_host.constBegin(); it != m_udp_fast_sync_probe_ids_by_host.constEnd(); ++it) {
                const QString host = it.key();
                const qint64 sent_ms = m_udp_fast_sync_last_probe_ms_by_host.value(host, 0);
                if (sent_ms > 0 && now - sent_ms > LAN_FAST_SYNC_PROBE_TIMEOUT_MS) {
                    expired_probe_hosts.push_back(host);
                }
            }
            for (const QString& host : expired_probe_hosts) {
                recordUdpFastSyncPeerMiss(host, QStringLiteral("UDP probe timed out"));
            }
            m_fast_sync_current_datagram_bytes = currentFastSyncDatagramSize();
            int probe_node_id = -1;
            const QString probe_host = selectUdpFastSyncTargetHost(&probe_node_id);
            if (!probe_host.isEmpty() && probe_node_id >= 0 && !isUdpFastSyncHostVerified(probe_host)) {
                if (sendUdpFastSyncProbe(probe_host, probe_node_id)) return;
            }
            m_lan_fast_sync_status = QStringLiteral("UDP fast sync idle; normal TCP sync is up to date.");
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
        }
        return;
    }
    if (m_lan_fast_sync_submit_in_flight || m_lan_fast_sync_reserve_in_flight) return;
    if (!canStartMoreLanFastSyncTransfers()) return;

    if (!shouldAttemptUdpFastSync()) return;
    requestLanFastSyncBlock();
}

bool NuRpcService::isUdpFastSyncHostVerified(const QString& host) const
{
    return !host.isEmpty()
        && (m_udp_fast_sync_available_peer_hosts.contains(host) || m_udp_fast_sync_used_peer_hosts.contains(host));
}

bool NuRpcService::isPrivateLocalOrProvenUdpFastSyncTarget(const QString& host) const
{
    QHostAddress address;
    if (!address.setAddress(host)) return false;
    if (isPrivateOrLocalFastSyncAddress(address) || isOnLocalInterfaceSubnet(host)) return true;
    return isUdpFastSyncHostVerified(host);
}

void NuRpcService::setUdpFastSyncPeerTransportVerified(const QString& host, bool verified)
{
    const int node_id = m_udp_fast_sync_peer_node_ids_by_host.value(host, -1);
    if (node_id < 0) return;
    rpcCall(QStringLiteral("reservefastsyncblock"),
            {verified ? QStringLiteral("transport-verified") : QStringLiteral("transport-unverified"), node_id},
            false,
            [](const QJsonValue&, const QString&) {});
}

bool NuRpcService::isUdpFastSyncProbeAllowed(const QString& host, qint64 now) const
{
    if (host.isEmpty()) return false;
    if (isUdpFastSyncHostVerified(host)) return true;
    const qint64 pending_ms = m_udp_fast_sync_last_probe_ms_by_host.value(host, 0);
    if (m_udp_fast_sync_probe_ids_by_host.contains(host) &&
        pending_ms > 0 &&
        now - pending_ms < LAN_FAST_SYNC_PROBE_TIMEOUT_MS) {
        return false;
    }
    QHostAddress address;
    if (!address.setAddress(host)) return false;
    const bool local_target = isPrivateLocalOrProvenUdpFastSyncTarget(host);
    const qint64 min_interval = local_target
        ? qint64(5000)
        : (m_udp_fast_sync_probe_failures_by_host.value(host, 0) >= LAN_FAST_SYNC_PUBLIC_PROBE_FAILURES_BEFORE_COOLDOWN
               ? qint64(LAN_FAST_SYNC_PUBLIC_PROBE_COOLDOWN_MS)
               : qint64(LAN_FAST_SYNC_PUBLIC_PROBE_MIN_INTERVAL_MS));
    return pending_ms <= 0 || now - pending_ms >= min_interval;
}

void NuRpcService::recordUdpFastSyncPeerReply(const QString& host)
{
    if (host.isEmpty()) return;
    m_udp_fast_sync_available_peer_hosts.insert(host);
    m_udp_fast_sync_failed_peer_hosts.remove(host);
    m_udp_fast_sync_probe_failures_by_host.remove(host);
    const QString probe_id = m_udp_fast_sync_probe_ids_by_host.take(host);
    if (!probe_id.isEmpty()) {
        m_udp_fast_sync_probe_hosts_by_id.remove(probe_id);
    }
    m_lan_fast_sync_last_failure_detail.clear();
    setUdpFastSyncPeerTransportVerified(host, true);
}

void NuRpcService::recordUdpFastSyncPeerMiss(const QString& host, const QString& reason)
{
    if (host.isEmpty()) return;
    if (!isUdpFastSyncHostVerified(host)) {
        m_udp_fast_sync_failed_peer_hosts.insert(host);
    }
    const QString probe_id = m_udp_fast_sync_probe_ids_by_host.take(host);
    if (!probe_id.isEmpty()) {
        m_udp_fast_sync_probe_hosts_by_id.remove(probe_id);
    }
    m_udp_fast_sync_probe_failures_by_host.insert(host, m_udp_fast_sync_probe_failures_by_host.value(host, 0) + 1);
    m_udp_fast_sync_last_probe_ms_by_host.insert(host, QDateTime::currentMSecsSinceEpoch());
    setUdpFastSyncPeerTransportVerified(host, false);
    if (!reason.isEmpty()) {
        m_lan_fast_sync_last_failure_detail = QStringLiteral("%1 for %2").arg(reason, host);
        recordFastSyncUdpDiagnostic(reason, host);
    }
}

void NuRpcService::acknowledgeLanQuickCloneSourceOffline(const QString& host, int height, const QString& reason)
{
    const QString clean_host = host.trimmed();
    if (clean_host.isEmpty()) return;

    m_lan_quick_clone_candidate_hosts.remove(clean_host);
    m_quick_clone_snapshot_candidate_hosts.remove(clean_host);
    m_udp_fast_sync_available_peer_hosts.remove(clean_host);
    m_udp_fast_sync_used_peer_hosts.remove(clean_host);
    m_udp_fast_sync_current_target_hosts.remove(clean_host);
    m_udp_fast_sync_failed_peer_hosts.insert(clean_host);
    m_udp_fast_sync_peer_inflight_counts_by_host.remove(clean_host);
    m_udp_fast_sync_last_request_ms_by_host.remove(clean_host);
    setUdpFastSyncPeerTransportVerified(clean_host, false);

    const QString probe_id = m_udp_fast_sync_probe_ids_by_host.take(clean_host);
    if (!probe_id.isEmpty()) {
        m_udp_fast_sync_probe_hosts_by_id.remove(probe_id);
    }

    m_udp_fast_sync_probe_failures_by_host.insert(
        clean_host,
        qMax(1, m_udp_fast_sync_probe_failures_by_host.value(clean_host, 0) + 1));
    m_udp_fast_sync_last_probe_ms_by_host.insert(clean_host, QDateTime::currentMSecsSinceEpoch());

    const QString detail = reason.trimmed().isEmpty()
        ? QStringLiteral("LAN source stopped answering")
        : reason.trimmed();
    m_lan_fast_sync_last_failure_detail = height > 0
        ? QStringLiteral("%1 for %2 near block %3").arg(detail, clean_host).arg(height)
        : QStringLiteral("%1 for %2").arg(detail, clean_host);
    recordFastSyncUdpDiagnostic(QStringLiteral("Quick Clone source offline"), m_lan_fast_sync_last_failure_detail);
}

bool NuRpcService::sendUdpFastSyncProbe(const QString& host, int node_id)
{
    if (!m_lan_fast_sync_socket || host.isEmpty() || (node_id < 0 && !m_lan_quick_clone_enabled)) return false;
    QHostAddress peer_address;
    if (!peer_address.setAddress(host)) {
        recordUdpFastSyncPeerMiss(host, QStringLiteral("invalid UDP probe target address"));
        return false;
    }
    const QString probe_id = QUuid::createUuid().toString(QUuid::Id128);
    const int max_datagram = isPrivateOrLocalFastSyncAddress(peer_address)
        ? qMin(currentFastSyncDatagramSize(), LAN_FAST_SYNC_MAX_DATAGRAM_BYTES)
        : LAN_FAST_SYNC_INTERNET_PROBE_DATAGRAM_BYTES;
    QJsonObject header;
    header.insert(QStringLiteral("type"), QStringLiteral("probe"));
    header.insert(QStringLiteral("version"), 1);
    header.insert(QStringLiteral("capability"), QString::fromLatin1(UDP_FAST_SYNC_CAPABILITY));
    header.insert(QStringLiteral("id"), probe_id);
    header.insert(QStringLiteral("port"), int(LAN_FAST_SYNC_PORT));
    header.insert(QStringLiteral("tip"), m_block_height);
    header.insert(QStringLiteral("node_id"), node_id);
    if (m_lan_quick_clone_enabled && isPrivateOrLocalFastSyncAddress(peer_address)) {
        header.insert(QStringLiteral("clone_mode"), true);
    }
    header.insert(QStringLiteral("max_datagram"), max_datagram);
    header.insert(QStringLiteral("chunk_bytes"), lanFastSyncChunkBytesForDatagram(max_datagram));
    header.insert(QStringLiteral("probe_mode"), isPrivateOrLocalFastSyncAddress(peer_address) ? QStringLiteral("lan") : QStringLiteral("public-safe"));

    const QByteArray datagram = lanFastSyncDatagram(header, QByteArray(), LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES);
    if (datagram.isEmpty()) {
        recordUdpFastSyncPeerMiss(host, QStringLiteral("could not build UDP probe datagram"));
        return false;
    }
    const qint64 written = m_lan_fast_sync_socket->writeDatagram(datagram, peer_address, LAN_FAST_SYNC_PORT);
    if (written <= 0) {
        recordUdpFastSyncPeerMiss(host, QStringLiteral("UDP probe send failed: %1").arg(m_lan_fast_sync_socket->errorString()));
        recordFastSyncUdpFailure(FastSyncUdpFailureKind::ProbeSend);
        return false;
    }

    m_fast_sync_last_udp_attempt_ms = QDateTime::currentMSecsSinceEpoch();
    const QString previous_probe_id = m_udp_fast_sync_probe_ids_by_host.value(host);
    if (!previous_probe_id.isEmpty()) {
        m_udp_fast_sync_probe_hosts_by_id.remove(previous_probe_id);
    }
    m_udp_fast_sync_probe_ids_by_host.insert(host, probe_id);
    m_udp_fast_sync_probe_hosts_by_id.insert(probe_id, host);
    m_udp_fast_sync_last_probe_ms_by_host.insert(host, QDateTime::currentMSecsSinceEpoch());
    m_udp_fast_sync_attempted_peer_hosts.insert(host);
    recordLanFastSyncUdpTraffic(written, 0);
    recordFastSyncUdpDiagnostic(QStringLiteral("sent UDP Fast Sync probe %1").arg(probe_id.left(8)),
        QStringLiteral("peer %1 host %2 id %3").arg(node_id).arg(host, probe_id.left(8)));
    m_lan_fast_sync_status = QStringLiteral("UDP fast sync probing peer %1 on %2 before block requests.")
        .arg(node_id)
        .arg(host);
    if (m_lan_quick_clone_enabled && isPrivateOrLocalFastSyncAddress(peer_address)) {
        m_lan_quick_clone_status = QStringLiteral("Quick Clone probing LAN source %1.").arg(host);
    }
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
    return true;
}

QString NuRpcService::selectUdpFastSyncTargetHost(int* node_id) const
{
    if (node_id) *node_id = -1;
    QString best_host;
    int best_score = std::numeric_limits<int>::min();
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    for (const QString& host : std::as_const(m_udp_fast_sync_peer_hosts)) {
        const int peer_node_id = m_udp_fast_sync_peer_node_ids_by_host.value(host, -1);
        if (peer_node_id < 0) continue;
        const int peer_tip = m_udp_fast_sync_peer_tips_by_host.value(host, -1);
        if (peer_tip <= m_block_height) continue;
        if (m_udp_fast_sync_failed_peer_hosts.contains(host) &&
            !m_udp_fast_sync_available_peer_hosts.contains(host) &&
            !m_udp_fast_sync_used_peer_hosts.contains(host) &&
            !isUdpFastSyncProbeAllowed(host, now)) {
            continue;
        }
        QHostAddress address;
        if (!address.setAddress(host)) continue;
        if (!isUdpFastSyncHostVerified(host) && !isUdpFastSyncProbeAllowed(host, now)) continue;
        const bool local_or_proven = isPrivateLocalOrProvenUdpFastSyncTarget(host);
        const int local_inflight = lanFastSyncLocalInflightCount(host);
        int score = 0;
        if (m_udp_fast_sync_used_peer_hosts.contains(host)) score += 100;
        if (m_udp_fast_sync_available_peer_hosts.contains(host)) score += 50;
        if (local_or_proven) score += 25;
        score += qMin(200, qMax(0, peer_tip - m_block_height) / 1000);
        score -= qMin(48, m_udp_fast_sync_peer_inflight_counts_by_host.value(host, 0) * 3);
        score -= qMin(500, local_inflight * 500);
        if (address.protocol() == QAbstractSocket::IPv4Protocol) score += 10;
        if (!isUdpFastSyncHostVerified(host)) {
            score -= local_or_proven ? 20 : 45;
            score -= qMin(40, m_udp_fast_sync_probe_failures_by_host.value(host, 0) * 20);
        }
        if (score > best_score || (score == best_score && (best_host.isEmpty() || host < best_host))) {
            best_score = score;
            best_host = host;
            if (node_id) *node_id = peer_node_id;
        }
    }
    return best_host;
}

QString NuRpcService::selectLanQuickCloneTargetHost(int* node_id, int* peer_tip) const
{
    if (node_id) *node_id = -1;
    if (peer_tip) *peer_tip = -1;

    QSet<QString> candidates = m_lan_quick_clone_candidate_hosts;
    for (const QString& host : m_udp_fast_sync_peer_hosts) candidates.insert(host);
    for (const QString& host : m_udp_fast_sync_available_peer_hosts) candidates.insert(host);
    for (const QString& host : m_udp_fast_sync_used_peer_hosts) candidates.insert(host);

    QString best_host;
    int best_score = std::numeric_limits<int>::min();
    for (const QString& host : std::as_const(candidates)) {
        QHostAddress address;
        if (!address.setAddress(host) || !isPrivateOrLocalFastSyncAddress(address)) continue;
        if (!isUdpFastSyncHostVerified(host)) continue;
        const int tip = m_udp_fast_sync_peer_tips_by_host.value(host, -1);
        if (tip >= 0 && tip <= m_block_height) continue;
        const int local_inflight = lanFastSyncLocalInflightCount(host);
        int score = tip >= 0 ? tip : m_header_height;
        if (m_udp_fast_sync_used_peer_hosts.contains(host)) score += 1000;
        if (m_udp_fast_sync_available_peer_hosts.contains(host)) score += 500;
        if (address.protocol() == QAbstractSocket::IPv4Protocol) score += 50;
        score -= qMin(2000, local_inflight * 2000);
        score -= qMin(200, m_udp_fast_sync_probe_failures_by_host.value(host, 0) * 50);
        if (score > best_score || (score == best_score && (best_host.isEmpty() || host < best_host))) {
            best_score = score;
            best_host = host;
            if (node_id) *node_id = m_udp_fast_sync_peer_node_ids_by_host.value(host, -1);
            if (peer_tip) *peer_tip = tip;
        }
    }
    return best_host;
}

QString NuRpcService::selectLanQuickCloneProbeHost(int* node_id) const
{
    if (node_id) *node_id = -1;
    QSet<QString> candidates = m_lan_quick_clone_candidate_hosts;
    for (const QString& host : m_udp_fast_sync_peer_hosts) candidates.insert(host);

    QString best_host;
    int best_score = std::numeric_limits<int>::min();
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    for (const QString& host : std::as_const(candidates)) {
        QHostAddress address;
        if (!address.setAddress(host) || !isPrivateOrLocalFastSyncAddress(address)) continue;
        if (isUdpFastSyncHostVerified(host) || !isUdpFastSyncProbeAllowed(host, now)) continue;
        int score = 0;
        if (m_lan_quick_clone_candidate_hosts.contains(host)) score += 100;
        if (m_udp_fast_sync_peer_hosts.contains(host)) score += 50;
        if (address.protocol() == QAbstractSocket::IPv4Protocol) score += 25;
        score -= qMin(80, m_udp_fast_sync_probe_failures_by_host.value(host, 0) * 20);
        if (score > best_score || (score == best_score && (best_host.isEmpty() || host < best_host))) {
            best_score = score;
            best_host = host;
            if (node_id) *node_id = m_udp_fast_sync_peer_node_ids_by_host.value(host, -1);
        }
    }
    return best_host;
}

void NuRpcService::releaseLanFastSyncReservation()
{
    if (m_lan_fast_sync_reserved_node_id < 0 || m_lan_fast_sync_reserved_hash.isEmpty()) return;
    const int node_id = m_lan_fast_sync_reserved_node_id;
    const QString hash = m_lan_fast_sync_reserved_hash;
    m_lan_fast_sync_reserved_node_id = -1;
    m_lan_fast_sync_reserved_hash.clear();
    releaseLanFastSyncReservationFor(node_id, hash);
}

void NuRpcService::sendLanFastSyncBlockRequest(int height, const QString& host, int node_id, const QString& expected_hash)
{
    const bool clone_mode = m_lan_quick_clone_enabled;
    if (!m_lan_fast_sync_socket || height <= 0 || host.isEmpty() || (node_id < 0 && !clone_mode) || (!clone_mode && expected_hash.size() != 64)) {
        releaseLanFastSyncReservation();
        m_lan_fast_sync_status = clone_mode
            ? QStringLiteral("Quick Clone could not start the LAN block request.")
            : QStringLiteral("UDP fast sync could not start a reserved block request; normal TCP fallback remains active.");
        if (clone_mode) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    QHostAddress peer_address;
    if (!peer_address.setAddress(host)) {
        releaseLanFastSyncReservation();
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync target address was invalid; normal TCP fallback remains active.");
        if (clone_mode) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    if (!canStartMoreLanFastSyncTransfers()) {
        releaseLanFastSyncReservation();
        m_lan_fast_sync_status = clone_mode
            ? QStringLiteral("Quick Clone cache is full; waiting to submit staged LAN blocks.")
            : QStringLiteral("UDP fast sync cache is full; waiting to submit staged blocks.");
        if (clone_mode) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    if (m_lan_fast_sync_started_ms <= 0) {
        m_lan_fast_sync_started_ms = QDateTime::currentMSecsSinceEpoch();
    }
    const QString request_id = QUuid::createUuid().toString(QUuid::Id128);
    QString normalized_host = normalizedFastSyncHost(peer_address);
    if (normalized_host.isEmpty()) {
        normalized_host = host.trimmed();
    }
    const qint64 request_ms = QDateTime::currentMSecsSinceEpoch();
    m_lan_fast_sync_request_id = request_id;
    m_lan_fast_sync_current_host = normalized_host;
    m_lan_fast_sync_current_height = height;
    m_lan_fast_sync_expected_chunks = 0;
    m_lan_fast_sync_expected_size = 0;
    m_lan_fast_sync_block_hash = expected_hash;
    m_lan_fast_sync_block_checksum.clear();
    m_lan_fast_sync_request_ms = request_ms;
    m_fast_sync_current_datagram_bytes = currentFastSyncDatagramSize();
    m_fast_sync_current_chunk_bytes = currentFastSyncChunkSize();

    QJsonObject header;
    header.insert(QStringLiteral("type"), QStringLiteral("request-block"));
    header.insert(QStringLiteral("version"), 1);
    header.insert(QStringLiteral("capability"), QString::fromLatin1(UDP_FAST_SYNC_CAPABILITY));
    header.insert(QStringLiteral("id"), request_id);
    header.insert(QStringLiteral("height"), height);
    header.insert(QStringLiteral("tip"), m_block_height);
    header.insert(QStringLiteral("port"), int(LAN_FAST_SYNC_PORT));
    if (clone_mode) header.insert(QStringLiteral("clone_mode"), true);
    header.insert(QStringLiteral("max_datagram"), m_fast_sync_current_datagram_bytes);
    header.insert(QStringLiteral("chunk_bytes"), m_fast_sync_current_chunk_bytes);
    header.insert(QStringLiteral("datagram_mode"), hasPrivateUdpFastSyncTarget() ? QStringLiteral("lan-probe") : QStringLiteral("safe-probe"));
    const QByteArray datagram = lanFastSyncDatagram(header, QByteArray(), LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES);
    if (datagram.isEmpty()) {
        releaseLanFastSyncReservation();
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync could not build a safe request packet; normal TCP fallback remains active.");
        if (clone_mode) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    const qint64 written = m_lan_fast_sync_socket->writeDatagram(datagram, peer_address, LAN_FAST_SYNC_PORT);
    if (written <= 0) {
        const QString key = normalizedFastSyncHost(peer_address);
        if (!key.isEmpty() &&
            !m_udp_fast_sync_available_peer_hosts.contains(key) &&
            !m_udp_fast_sync_used_peer_hosts.contains(key)) {
            m_udp_fast_sync_failed_peer_hosts.insert(key);
        }
        if (clone_mode) {
            acknowledgeLanQuickCloneSourceOffline(
                key.isEmpty() ? host : key,
                height,
                QStringLiteral("LAN source send failed: %1").arg(m_lan_fast_sync_socket ? m_lan_fast_sync_socket->errorString() : QStringLiteral("socket unavailable")));
        }
        ++m_lan_fast_sync_retransmit_errors;
        recordFastSyncUdpFailure(FastSyncUdpFailureKind::RequestSend);
        tuneFastSyncDatagramAfterFailure();
        releaseLanFastSyncReservationFor(node_id, expected_hash);
        m_lan_fast_sync_reserved_node_id = -1;
        m_lan_fast_sync_reserved_hash.clear();
        m_lan_fast_sync_status = clone_mode
            ? QStringLiteral("Quick Clone could not send to LAN source %1 (%2).")
                  .arg(host, m_lan_fast_sync_socket ? m_lan_fast_sync_socket->errorString() : QStringLiteral("socket unavailable"))
            : QStringLiteral("UDP fast sync could not send to peer %1 (%2); normal TCP fallback remains active.")
                  .arg(node_id)
                  .arg(m_lan_fast_sync_socket ? m_lan_fast_sync_socket->errorString() : QStringLiteral("socket unavailable"));
        if (clone_mode) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    LanFastSyncTransfer transfer;
    transfer.request_id = request_id;
    transfer.host = normalized_host;
    transfer.expected_hash = expected_hash;
    transfer.node_id = node_id;
    transfer.height = height;
    transfer.request_ms = request_ms;
    m_lan_fast_sync_transfers_by_id.insert(request_id, transfer);
    m_lan_fast_sync_reserved_node_id = -1;
    m_lan_fast_sync_reserved_hash.clear();
    updateLanFastSyncRequestState();
    refreshLanFastSyncCurrentTargetHosts();
    m_fast_sync_last_udp_attempt_ms = request_ms;
    recordLanFastSyncUdpTraffic(written, 0);
    const QString key = normalizedFastSyncHost(peer_address);
    m_udp_fast_sync_attempted_peer_hosts.insert(key);
    m_lan_fast_sync_status = clone_mode
        ? QStringLiteral("Quick Clone requesting LAN block %1 from %2 at %3-byte datagrams (%4 active, %5 ready).")
              .arg(height)
              .arg(host)
              .arg(m_fast_sync_current_datagram_bytes)
              .arg(m_lan_fast_sync_transfers_by_id.size())
              .arg(m_lan_fast_sync_ready_blocks_by_height.size())
        : QStringLiteral("UDP fast sync requesting reserved block %1 from peer %2 at %3-byte datagrams (%4 active, %5 ready).")
              .arg(height)
              .arg(node_id)
              .arg(m_fast_sync_current_datagram_bytes)
              .arg(m_lan_fast_sync_transfers_by_id.size())
              .arg(m_lan_fast_sync_ready_blocks_by_height.size());
    if (clone_mode) {
        m_lan_quick_clone_status = m_lan_fast_sync_status;
    }
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
    QTimer::singleShot(0, this, &NuRpcService::lanFastSyncTick);
}

void NuRpcService::requestLanFastSyncBlock()
{
    if (!m_lan_fast_sync_socket || m_lan_fast_sync_reserve_in_flight) return;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const bool core_tcp_blocks_disabled = m_debug_disable_core_tcp_sync || m_debug_disable_core_sync;
    const QString fallback_text = core_tcp_blocks_disabled
        ? QStringLiteral("Core TCP block copy is off for this test.")
        : QStringLiteral("normal TCP fallback remains active.");
    QStringList expired_probe_hosts;
    for (auto it = m_udp_fast_sync_probe_ids_by_host.constBegin(); it != m_udp_fast_sync_probe_ids_by_host.constEnd(); ++it) {
        const QString host = it.key();
        const qint64 sent_ms = m_udp_fast_sync_last_probe_ms_by_host.value(host, 0);
        if (sent_ms > 0 && now - sent_ms > LAN_FAST_SYNC_PROBE_TIMEOUT_MS) {
            expired_probe_hosts.push_back(host);
        }
    }
    for (const QString& host : expired_probe_hosts) {
        recordUdpFastSyncPeerMiss(host, QStringLiteral("UDP probe timed out"));
    }
    if (m_udp_fast_sync_peer_hosts.isEmpty()) {
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync waiting for connected Nu peers; %1").arg(fallback_text);
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    m_fast_sync_current_datagram_bytes = currentFastSyncDatagramSize();
    int node_id = -1;
    const QString host = selectUdpFastSyncTargetHost(&node_id);
    if (host.isEmpty() || node_id < 0) {
        recordFastSyncUdpDiagnostic(QStringLiteral("UDP target selection empty"),
            QStringLiteral("peers=%1 verified=%2 used=%3 failed=%4 debug-tcp-off=%5")
                .arg(QString::number(m_udp_fast_sync_peer_hosts.size()),
                     QString::number(m_udp_fast_sync_available_peer_hosts.size()),
                     QString::number(m_udp_fast_sync_used_peer_hosts.size()),
                     QString::number(m_udp_fast_sync_failed_peer_hosts.size()),
                     (m_debug_disable_core_tcp_sync || m_debug_disable_core_sync) ? QStringLiteral("yes") : QStringLiteral("no")));
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync has no eligible Nu peer for the next block; %1").arg(fallback_text);
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    if (!isUdpFastSyncHostVerified(host)) {
        if (!sendUdpFastSyncProbe(host, node_id)) {
            m_lan_fast_sync_status = QStringLiteral("UDP fast sync could not probe peer %1; %2")
                .arg(node_id)
                .arg(fallback_text);
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
        }
        return;
    }
    // Reserve through Core first; UDP only carries the block body selected by
    // the normal downloader and does not create an independent block schedule.
    m_lan_fast_sync_reserve_in_flight = true;
    m_lan_fast_sync_status = QStringLiteral("UDP fast sync asking Core to reserve the next block from peer %1.").arg(node_id);
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
    rpcCall(QStringLiteral("reservefastsyncblock"),
            {QStringLiteral("reserve-next"), node_id},
            false,
            [this, host, node_id](const QJsonValue& result, const QString& error) {
        m_lan_fast_sync_reserve_in_flight = false;
        const QJsonObject obj = result.toObject();
        const bool success = error.isEmpty() && obj.value(QStringLiteral("success")).toBool(false);
        const QString reason = error.isEmpty() ? obj.value(QStringLiteral("reason")).toString(QStringLiteral("unknown")) : error;
        const QString hash = obj.value(QStringLiteral("hash")).toString();
        const int height = obj.value(QStringLiteral("height")).toInt(-1);
        if (!success || hash.size() != 64 || height <= 0) {
            const QString detail = QStringLiteral("block %1 peer %2 headers %3 local-blocks %4: %5")
                .arg(height)
                .arg(node_id)
                .arg(m_header_height)
                .arg(m_block_height)
                .arg(reason);
            recordFastSyncUdpDiagnostic(QStringLiteral("Core reservation deferred"), detail);
            if (reason == QLatin1String("peer-not-connected")) {
                m_udp_fast_sync_peer_node_ids_by_host.remove(host);
                m_lan_fast_sync_status = QStringLiteral("Fast Sync peer reconnected; refreshing peer state before retrying UDP.");
                QTimer::singleShot(0, this, &NuRpcService::refreshNode);
                QTimer::singleShot(1500, this, &NuRpcService::lanFastSyncTick);
            } else {
                m_lan_fast_sync_status = coreSchedulingWaitStatus(QStringLiteral("UDP Fast Sync"), reason);
            }
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
            return;
        }
        if (height <= m_block_height) {
            m_lan_fast_sync_reserved_node_id = node_id;
            m_lan_fast_sync_reserved_hash = hash;
            releaseLanFastSyncReservation();
            m_lan_fast_sync_status = QStringLiteral("UDP fast sync skipped block %1 because Core already advanced.").arg(height);
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
            return;
        }
        m_lan_fast_sync_reserved_node_id = node_id;
        m_lan_fast_sync_reserved_hash = hash;
        sendLanFastSyncBlockRequest(height, host, node_id, hash);
    });
}

void NuRpcService::handleLanFastSyncDatagrams()
{
    if (!m_lan_fast_sync_socket) return;
    int processed = 0;
    while (m_lan_fast_sync_socket->hasPendingDatagrams() && processed < LAN_FAST_SYNC_MAX_DATAGRAMS_PER_READ) {
        ++processed;
        const QNetworkDatagram datagram = m_lan_fast_sync_socket->receiveDatagram();
        if (!datagram.isValid()) continue;
        const int datagram_size = datagram.data().size();
        if (datagram_size <= 0) continue;
        if (datagram_size > LAN_FAST_SYNC_MAX_DATAGRAM_BYTES) continue;
        const QHostAddress sender = datagram.senderAddress();
        if (sender.isNull()) continue;
        const QByteArray data = datagram.data();
        if (data.startsWith('{')) {
            QJsonParseError parse_error;
            const QJsonDocument doc = QJsonDocument::fromJson(data, &parse_error);
            if (parse_error.error == QJsonParseError::NoError && doc.isObject()) {
                handleLanDiscoveryAnnouncement(doc.object(), sender, datagram.senderPort());
            }
            continue;
        }
        QJsonObject header;
        QByteArray payload;
        if (!parseLanFastSyncDatagram(data, &header, &payload)) {
            recordFastSyncUdpDiagnostic(QStringLiteral("dropped malformed UDP Fast Sync datagram"),
                QStringLiteral("%1; bytes=%2").arg(udpFastSyncEndpointText(sender, datagram.senderPort())).arg(datagram_size));
            continue;
        }
        if (header.value(QStringLiteral("version")).toInt(0) != 1) {
            recordFastSyncUdpDiagnostic(QStringLiteral("dropped UDP Fast Sync datagram with unsupported version"),
                udpFastSyncEndpointText(sender, datagram.senderPort()));
            continue;
        }
        if (header.value(QStringLiteral("capability")).toString() != QLatin1String(UDP_FAST_SYNC_CAPABILITY)) {
            recordFastSyncUdpDiagnostic(QStringLiteral("dropped UDP Fast Sync datagram with unsupported capability"),
                udpFastSyncEndpointText(sender, datagram.senderPort()));
            continue;
        }
        recordLanFastSyncUdpTraffic(0, datagram_size);
        const QString type = header.value(QStringLiteral("type")).toString();
        if (type == QLatin1String("probe")) {
            handleLanFastSyncProbe(header, sender, datagram.senderPort());
        } else if (type == QLatin1String("probe-ack")) {
            recordFastSyncUdpDiagnostic(
                QStringLiteral("received UDP Fast Sync probe acknowledgement %1")
                    .arg(header.value(QStringLiteral("id")).toString().left(8)),
                udpFastSyncEndpointText(sender, datagram.senderPort()));
            handleLanFastSyncProbeAck(header, sender, datagram.senderPort());
        } else if (type == QLatin1String("request-block")) {
            const bool clone_request = header.value(QStringLiteral("clone_mode")).toBool(false);
            const bool lan_request = isPrivateOrLocalFastSyncAddress(sender);
            if (!isUdpFastSyncAllowedPeer(sender) && !lan_request && !(clone_request && isLanQuickCloneAllowedPeer(sender))) {
                recordFastSyncUdpDiagnostic(QStringLiteral("dropped UDP Fast Sync block request from non-peer"),
                    udpFastSyncEndpointText(sender, datagram.senderPort()));
                continue;
            }
            handleLanFastSyncRequest(header, sender, datagram.senderPort());
        } else if (type == QLatin1String("block-chunk")) {
            const bool lan_chunk = isPrivateOrLocalFastSyncAddress(sender);
            if (!isUdpFastSyncAllowedPeer(sender) && !lan_chunk && !(m_lan_quick_clone_enabled && isLanQuickCloneAllowedPeer(sender))) {
                recordFastSyncUdpDiagnostic(QStringLiteral("dropped UDP Fast Sync block chunk from non-peer"),
                    udpFastSyncEndpointText(sender, datagram.senderPort()));
                continue;
            }
            handleLanFastSyncChunk(header, payload, sender);
        } else {
            recordFastSyncUdpDiagnostic(QStringLiteral("dropped UDP Fast Sync datagram with unknown type"),
                QStringLiteral("%1; type=%2").arg(udpFastSyncEndpointText(sender, datagram.senderPort()), type.left(80)));
        }
    }
    if (m_lan_fast_sync_socket && m_lan_fast_sync_socket->hasPendingDatagrams()) {
        QTimer::singleShot(0, this, &NuRpcService::handleLanFastSyncDatagrams);
    }
}

void NuRpcService::handleLanFastSyncProbe(const QJsonObject& header, const QHostAddress& sender, quint16 sender_port)
{
    if (!m_rpc_connected || !m_lan_fast_sync_enabled) return;
    bool peer_confirmed = isUdpFastSyncAllowedPeer(sender);
    const QString sender_key = normalizedFastSyncHost(sender);
    const QString request_id = header.value(QStringLiteral("id")).toString();
    static const QRegularExpression request_id_re(QStringLiteral(R"(^[0-9a-f]{32}$)"), QRegularExpression::CaseInsensitiveOption);
    if (!request_id_re.match(request_id).hasMatch()) {
        recordFastSyncUdpDiagnostic(QStringLiteral("ignored UDP probe with invalid transaction id"),
            QStringLiteral("%1; id-len=%2").arg(udpFastSyncEndpointText(sender, sender_port)).arg(request_id.size()));
        return;
    }
    if (!peer_confirmed && !sender_key.isEmpty() && isPrivateOrLocalFastSyncAddress(sender)) {
        const int sender_node_id = header.value(QStringLiteral("node_id")).toInt(-1);
        const int sender_tip = header.value(QStringLiteral("tip")).toInt(-1);
        m_udp_fast_sync_peer_hosts.insert(sender_key);
        m_udp_fast_sync_available_peer_hosts.insert(sender_key);
        m_udp_fast_sync_failed_peer_hosts.remove(sender_key);
        m_udp_fast_sync_probe_failures_by_host.remove(sender_key);
        if (sender_node_id >= 0) {
            m_udp_fast_sync_peer_node_ids_by_host.insert(sender_key, sender_node_id);
        }
        if (sender_tip >= 0) {
            m_udp_fast_sync_peer_tips_by_host.insert(sender_key, sender_tip);
        }
        peer_confirmed = true;
        recordFastSyncUdpDiagnostic(QStringLiteral("accepted LAN UDP Fast Sync probe as provisional peer"),
            QStringLiteral("%1 id %2").arg(udpFastSyncEndpointText(sender, sender_port), request_id.left(8)));
    }
    const int advertised_reply_port = header.value(QStringLiteral("port")).toInt(sender_port);
    const quint16 reply_port = sender_port > 0 ? sender_port : quint16(advertised_reply_port);
    if (reply_port == 0) {
        recordFastSyncUdpDiagnostic(QStringLiteral("ignored UDP probe with no reply port"), udpFastSyncEndpointText(sender, sender_port));
        return;
    }

    const int sender_datagram_cap = isPrivateOrLocalFastSyncAddress(sender)
        ? LAN_FAST_SYNC_MAX_DATAGRAM_BYTES
        : LAN_FAST_SYNC_INTERNET_PROBE_DATAGRAM_BYTES;
    const int peer_max_datagram = qBound(576, header.value(QStringLiteral("max_datagram")).toInt(LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES), sender_datagram_cap);
    const int requested_chunk_bytes = header.value(QStringLiteral("chunk_bytes")).toInt(lanFastSyncChunkBytesForDatagram(peer_max_datagram));
    const int peer_chunk_bytes = qBound(LAN_FAST_SYNC_MIN_CHUNK_BYTES,
                                        qMin(requested_chunk_bytes, lanFastSyncChunkBytesForDatagram(peer_max_datagram)),
                                        LAN_FAST_SYNC_MAX_CHUNK_BYTES);
    QJsonObject ack;
    ack.insert(QStringLiteral("type"), QStringLiteral("probe-ack"));
    ack.insert(QStringLiteral("version"), 1);
    ack.insert(QStringLiteral("capability"), QString::fromLatin1(UDP_FAST_SYNC_CAPABILITY));
    ack.insert(QStringLiteral("id"), request_id);
    ack.insert(QStringLiteral("port"), int(LAN_FAST_SYNC_PORT));
    ack.insert(QStringLiteral("tip"), m_block_height);
    ack.insert(QStringLiteral("max_datagram"), peer_max_datagram);
    ack.insert(QStringLiteral("chunk_bytes"), peer_chunk_bytes);
    ack.insert(QStringLiteral("observed_sender_port"), int(sender_port));
    ack.insert(QStringLiteral("peer_confirmed"), peer_confirmed);
    const QByteArray datagram = lanFastSyncDatagram(ack, QByteArray(), LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES);
    if (datagram.isEmpty()) {
        recordFastSyncUdpDiagnostic(QStringLiteral("could not build UDP probe acknowledgement"), udpFastSyncEndpointText(sender, reply_port));
        return;
    }
    const qint64 written = m_lan_fast_sync_socket->writeDatagram(datagram, sender, reply_port);
    if (written <= 0) {
        recordFastSyncUdpDiagnostic(QStringLiteral("UDP probe acknowledgement send failed"),
            QStringLiteral("%1; %2").arg(udpFastSyncEndpointText(sender, reply_port), m_lan_fast_sync_socket->errorString()));
        return;
    }
    recordLanFastSyncUdpTraffic(written, 0);
    recordFastSyncUdpDiagnostic(QStringLiteral("sent UDP Fast Sync probe acknowledgement %1").arg(request_id.left(8)),
        QStringLiteral("%1 id %2").arg(udpFastSyncEndpointText(sender, reply_port), request_id.left(8)));
    if (peer_confirmed) {
        recordUdpFastSyncPeerReply(sender_key);
        const int sender_tip = header.value(QStringLiteral("tip")).toInt(-1);
        if (sender_tip >= 0) m_udp_fast_sync_peer_tips_by_host.insert(sender_key, sender_tip);
    }
}

void NuRpcService::handleLanFastSyncProbeAck(const QJsonObject& header, const QHostAddress& sender, quint16 sender_port)
{
    if (!m_lan_fast_sync_enabled) return;
    const QString sender_key = normalizedFastSyncHost(sender);
    if (sender_key.isEmpty()) return;
    const QString request_id = header.value(QStringLiteral("id")).toString();
    QString verified_host = m_udp_fast_sync_probe_hosts_by_id.value(request_id);
    if (verified_host.isEmpty() && m_udp_fast_sync_probe_ids_by_host.value(sender_key) == request_id) {
        verified_host = sender_key;
    }
    if (verified_host.isEmpty()) {
        recordFastSyncUdpDiagnostic(QStringLiteral("ignored UDP probe acknowledgement with mismatched transaction id"),
            QStringLiteral("%1; expected=%2 got=%3")
                .arg(udpFastSyncEndpointText(sender, sender_port),
                     m_udp_fast_sync_probe_ids_by_host.value(sender_key).left(8),
                     request_id.left(8)));
        return;
    }
    recordUdpFastSyncPeerReply(verified_host);
    const int verified_node_id = m_udp_fast_sync_peer_node_ids_by_host.value(verified_host, -1);
    const int peer_tip = header.value(QStringLiteral("tip")).toInt(-1);
    if (peer_tip >= 0) m_udp_fast_sync_peer_tips_by_host.insert(verified_host, peer_tip);
    if (sender_key != verified_host) {
        m_udp_fast_sync_peer_hosts.insert(sender_key);
        m_udp_fast_sync_available_peer_hosts.insert(sender_key);
        m_udp_fast_sync_failed_peer_hosts.remove(sender_key);
        m_udp_fast_sync_probe_failures_by_host.remove(sender_key);
        if (verified_node_id >= 0) {
            m_udp_fast_sync_peer_node_ids_by_host.insert(sender_key, verified_node_id);
        }
        if (peer_tip >= 0) m_udp_fast_sync_peer_tips_by_host.insert(sender_key, peer_tip);
        recordFastSyncUdpDiagnostic(QStringLiteral("accepted UDP probe acknowledgement from peer return-path alias"),
            QStringLiteral("reserved host %1 ack source %2 id %3")
                .arg(verified_host, udpFastSyncEndpointText(sender, sender_port), request_id.left(8)));
    }
    const int peer_max_datagram = header.value(QStringLiteral("max_datagram")).toInt(LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES);
    if (peer_max_datagram >= LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES &&
        peer_max_datagram < currentFastSyncDatagramSize()) {
        tuneFastSyncDatagramAfterFailure();
    }
    m_lan_fast_sync_status = QStringLiteral("UDP fast sync verified peer %1; block requests may use UDP without another probe.")
        .arg(verified_host);
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
    QTimer::singleShot(0, this, &NuRpcService::lanFastSyncTick);
}

void NuRpcService::handleLanFastSyncRequest(const QJsonObject& header, const QHostAddress& sender, quint16 sender_port)
{
    if (!m_rpc_connected || !m_lan_fast_sync_enabled) return;
    const bool clone_request = header.value(QStringLiteral("clone_mode")).toBool(false);
    if (!isUdpFastSyncAllowedPeer(sender) && !isPrivateOrLocalFastSyncAddress(sender) && !(clone_request && isLanQuickCloneAllowedPeer(sender))) return;
    const QString request_id = header.value(QStringLiteral("id")).toString();
    static const QRegularExpression request_id_re(QStringLiteral(R"(^[0-9a-f]{32}$)"), QRegularExpression::CaseInsensitiveOption);
    if (!request_id_re.match(request_id).hasMatch()) return;
    const int height = header.value(QStringLiteral("height")).toInt(-1);
    if (request_id.isEmpty() || height <= 0 || height > m_block_height) return;
    const QString sender_key = normalizedFastSyncHost(sender);
    if (!sender_key.isEmpty()) {
        m_udp_fast_sync_available_peer_hosts.insert(sender_key);
        m_udp_fast_sync_failed_peer_hosts.remove(sender_key);
    }
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const qint64 last_request_ms = m_udp_fast_sync_last_request_ms_by_host.value(sender_key, 0);
    if (last_request_ms > 0 && now - last_request_ms < LAN_FAST_SYNC_MIN_REQUEST_INTERVAL_MS) return;
    m_udp_fast_sync_last_request_ms_by_host.insert(sender_key, now);
    if (m_udp_fast_sync_last_request_ms_by_host.size() > 512) {
        for (auto it = m_udp_fast_sync_last_request_ms_by_host.begin(); it != m_udp_fast_sync_last_request_ms_by_host.end();) {
            if (now - it.value() > 5 * 60 * 1000) it = m_udp_fast_sync_last_request_ms_by_host.erase(it);
            else ++it;
        }
    }
    const int advertised_reply_port = header.value(QStringLiteral("port")).toInt(sender_port);
    const quint16 reply_port = sender_port > 0 ? sender_port : quint16(advertised_reply_port);
    if (reply_port == 0) return;
    const int sender_datagram_cap = isPrivateOrLocalFastSyncAddress(sender)
        ? LAN_FAST_SYNC_MAX_DATAGRAM_BYTES
        : LAN_FAST_SYNC_INTERNET_PROBE_DATAGRAM_BYTES;
    const int peer_max_datagram = qBound(576, header.value(QStringLiteral("max_datagram")).toInt(LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES), sender_datagram_cap);
    const int requested_chunk_bytes = header.value(QStringLiteral("chunk_bytes")).toInt(lanFastSyncChunkBytesForDatagram(peer_max_datagram));
    const int peer_chunk_bytes = qBound(LAN_FAST_SYNC_MIN_CHUNK_BYTES,
                                        qMin(requested_chunk_bytes, lanFastSyncChunkBytesForDatagram(peer_max_datagram)),
                                        LAN_FAST_SYNC_MAX_CHUNK_BYTES);
    rpcCall(QStringLiteral("getblockhash"), {height}, false, [this, request_id, height, sender, reply_port, peer_max_datagram, peer_chunk_bytes](const QJsonValue& hash_result, const QString& hash_error) {
        if (!hash_error.isEmpty() || !m_lan_fast_sync_socket) return;
        const QString hash = hash_result.toString();
        if (!isHex256(hash)) return;
        rpcCall(QStringLiteral("getblock"), {hash, 0}, false, [this, request_id, height, sender, reply_port, hash, peer_max_datagram, peer_chunk_bytes](const QJsonValue& block_result, const QString& block_error) {
            if (!block_error.isEmpty() || !m_lan_fast_sync_socket) return;
            const QString raw_hex = block_result.toString();
            if (!isLowerRiskHexText(raw_hex, LAN_FAST_SYNC_MAX_BLOCK_BYTES * 2)) return;
            const QByteArray raw = QByteArray::fromHex(raw_hex.toLatin1());
            if (raw.isEmpty() || raw.size() > LAN_FAST_SYNC_MAX_BLOCK_BYTES) return;
            const int total_chunks = (raw.size() + peer_chunk_bytes - 1) / peer_chunk_bytes;
            if (total_chunks <= 0 || total_chunks > LAN_FAST_SYNC_MAX_CHUNKS_PER_BLOCK) return;
            const QString block_checksum = lanFastSyncChecksum(raw);
            bool sent_any_chunk = false;
            for (int seq = 0; seq < total_chunks; ++seq) {
                const QByteArray chunk = raw.mid(seq * peer_chunk_bytes, peer_chunk_bytes);
                QJsonObject chunk_header;
                chunk_header.insert(QStringLiteral("type"), QStringLiteral("block-chunk"));
                chunk_header.insert(QStringLiteral("version"), 1);
                chunk_header.insert(QStringLiteral("capability"), QString::fromLatin1(UDP_FAST_SYNC_CAPABILITY));
                chunk_header.insert(QStringLiteral("id"), request_id);
                chunk_header.insert(QStringLiteral("height"), height);
                chunk_header.insert(QStringLiteral("hash"), hash);
                chunk_header.insert(QStringLiteral("seq"), seq);
                chunk_header.insert(QStringLiteral("total"), total_chunks);
                chunk_header.insert(QStringLiteral("block_size"), raw.size());
                chunk_header.insert(QStringLiteral("chunk_bytes"), peer_chunk_bytes);
                chunk_header.insert(QStringLiteral("max_datagram"), peer_max_datagram);
                chunk_header.insert(QStringLiteral("block_checksum"), block_checksum);
                chunk_header.insert(QStringLiteral("chunk_checksum"), lanFastSyncChecksum(chunk));
                const QByteArray datagram = lanFastSyncDatagram(chunk_header, chunk, peer_max_datagram);
                if (!datagram.isEmpty() && datagram.size() <= peer_max_datagram) {
                    const qint64 written = m_lan_fast_sync_socket->writeDatagram(datagram, sender, reply_port);
                    if (written > 0) {
                        recordLanFastSyncUdpTraffic(written, 0);
                        sent_any_chunk = true;
                    }
                }
            }
            if (sent_any_chunk) {
                const QString sender_key = normalizedFastSyncHost(sender);
                if (!sender_key.isEmpty()) {
                    m_udp_fast_sync_available_peer_hosts.insert(sender_key);
                    m_udp_fast_sync_failed_peer_hosts.remove(sender_key);
                    m_udp_fast_sync_used_peer_hosts.insert(sender_key);
                    QTimer::singleShot(0, this, &NuRpcService::refreshNode);
                }
            }
        });
    });
}

void NuRpcService::handleLanFastSyncChunk(const QJsonObject& header, const QByteArray& payload, const QHostAddress& sender)
{
    if (m_lan_fast_sync_transfers_by_id.isEmpty()) return;
    if (!isUdpFastSyncAllowedPeer(sender) && !isPrivateOrLocalFastSyncAddress(sender) && !(m_lan_quick_clone_enabled && isLanQuickCloneAllowedPeer(sender))) return;
    const QString sender_key = normalizedFastSyncHost(sender);
    const QString request_id = header.value(QStringLiteral("id")).toString();
    if (!m_lan_fast_sync_transfers_by_id.contains(request_id)) return;
    LanFastSyncTransfer& transfer = m_lan_fast_sync_transfers_by_id[request_id];
    const int height = header.value(QStringLiteral("height")).toInt(-1);
    if (height != transfer.height) return;
    if (height <= m_block_height) {
        releaseLanFastSyncReservationFor(transfer.node_id, transfer.expected_hash);
        m_lan_fast_sync_transfers_by_id.remove(request_id);
        updateLanFastSyncRequestState();
        refreshLanFastSyncCurrentTargetHosts();
        m_lan_fast_sync_status = m_lan_quick_clone_enabled
            ? QStringLiteral("Quick Clone skipped LAN block %1 because Core already has it; trying the next missing block.")
                  .arg(height)
            : QStringLiteral("UDP fast sync skipped block %1 because Core already advanced; normal sync remains active.")
                  .arg(height);
        if (m_lan_quick_clone_enabled) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        QTimer::singleShot(0, this, &NuRpcService::lanFastSyncTick);
        return;
    }
    const int seq = header.value(QStringLiteral("seq")).toInt(-1);
    const int total = header.value(QStringLiteral("total")).toInt(-1);
    const int block_size = header.value(QStringLiteral("block_size")).toInt(-1);
    const int chunk_bytes = header.value(QStringLiteral("chunk_bytes")).toInt(m_fast_sync_current_chunk_bytes);
    const int max_datagram = header.value(QStringLiteral("max_datagram")).toInt(m_fast_sync_current_datagram_bytes);
    const int negotiated_max_datagram = qBound(576, max_datagram, LAN_FAST_SYNC_MAX_DATAGRAM_BYTES);
    if (negotiated_max_datagram < LAN_FAST_SYNC_SAFE_DATAGRAM_BYTES) return;
    const int negotiated_chunk_cap = qBound(LAN_FAST_SYNC_MIN_CHUNK_BYTES,
                                           qMin(chunk_bytes, lanFastSyncChunkBytesForDatagram(negotiated_max_datagram)),
                                           LAN_FAST_SYNC_MAX_CHUNK_BYTES);
    if (payload.isEmpty() || payload.size() > negotiated_chunk_cap) return;
    if (seq < 0 || total <= 0 || total > LAN_FAST_SYNC_MAX_CHUNKS_PER_BLOCK || block_size <= 0 || block_size > LAN_FAST_SYNC_MAX_BLOCK_BYTES) return;
    if (seq >= total) return;
    if (block_size > total * negotiated_chunk_cap) return;
    const QString chunk_checksum = header.value(QStringLiteral("chunk_checksum")).toString();
    if (!isHex256(chunk_checksum)) return;
    if (lanFastSyncChecksum(payload) != chunk_checksum) {
        ++m_lan_fast_sync_retransmit_errors;
        recordFastSyncUdpFailure(FastSyncUdpFailureKind::Checksum);
        tuneFastSyncDatagramAfterFailure();
        releaseLanFastSyncReservationFor(transfer.node_id, transfer.expected_hash);
        m_lan_fast_sync_transfers_by_id.remove(request_id);
        updateLanFastSyncRequestState();
        refreshLanFastSyncCurrentTargetHosts();
        return;
    }
    const QString block_hash = header.value(QStringLiteral("hash")).toString();
    if (!isHex256(block_hash)) return;
    if (!transfer.expected_hash.isEmpty() && block_hash != transfer.expected_hash) return;
    transfer.expected_chunks = total;
    transfer.expected_size = block_size;
    transfer.block_hash = block_hash;
    transfer.block_checksum = header.value(QStringLiteral("block_checksum")).toString();
    if (!isHex256(transfer.block_hash) || !isHex256(transfer.block_checksum)) return;
    if (transfer.chunks.contains(seq)) return;
    if (transfer.assembled_bytes + payload.size() > qMin(block_size, LAN_FAST_SYNC_MAX_BLOCK_BYTES) ||
        lanFastSyncBufferedBytes() + payload.size() > LAN_FAST_SYNC_MAX_BUFFER_BYTES) {
        ++m_lan_fast_sync_retransmit_errors;
        recordFastSyncUdpFailure(FastSyncUdpFailureKind::Buffer);
        tuneFastSyncDatagramAfterFailure();
        releaseLanFastSyncReservationFor(transfer.node_id, transfer.expected_hash);
        m_lan_fast_sync_transfers_by_id.remove(request_id);
        updateLanFastSyncRequestState();
        refreshLanFastSyncCurrentTargetHosts();
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync exceeded the reserved block buffer at block %1; normal TCP fallback remains active.").arg(height);
        if (m_lan_quick_clone_enabled) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    transfer.chunks.insert(seq, payload);
    transfer.assembled_bytes += payload.size();
    m_lan_fast_sync_request_id = request_id;
    m_lan_fast_sync_current_height = height;
    m_lan_fast_sync_current_host = transfer.host;
    m_lan_fast_sync_request_ms = transfer.request_ms;
    m_lan_fast_sync_expected_chunks = transfer.expected_chunks;
    m_lan_fast_sync_expected_size = transfer.expected_size;
    m_lan_fast_sync_block_hash = transfer.block_hash;
    m_lan_fast_sync_block_checksum = transfer.block_checksum;
    if (!sender_key.isEmpty()) {
        m_udp_fast_sync_available_peer_hosts.insert(sender_key);
        m_udp_fast_sync_failed_peer_hosts.remove(sender_key);
        m_udp_fast_sync_used_peer_hosts.insert(sender_key);
    }

    if (transfer.chunks.size() < transfer.expected_chunks) {
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync receiving block %1 from %2 (%3/%4 chunks, %5 active).")
            .arg(height)
            .arg(transfer.host)
            .arg(transfer.chunks.size())
            .arg(transfer.expected_chunks)
            .arg(m_lan_fast_sync_transfers_by_id.size());
        if (m_lan_quick_clone_enabled) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }

    QByteArray block;
    block.reserve(transfer.expected_size);
    for (int i = 0; i < transfer.expected_chunks; ++i) {
        if (!transfer.chunks.contains(i)) return;
        block.append(transfer.chunks.value(i));
    }
    if (block.size() != transfer.expected_size || lanFastSyncChecksum(block) != transfer.block_checksum) {
        ++m_lan_fast_sync_retransmit_errors;
        recordFastSyncUdpFailure(FastSyncUdpFailureKind::Checksum);
        tuneFastSyncDatagramAfterFailure();
        releaseLanFastSyncReservationFor(transfer.node_id, transfer.expected_hash);
        m_lan_fast_sync_transfers_by_id.remove(request_id);
        updateLanFastSyncRequestState();
        refreshLanFastSyncCurrentTargetHosts();
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync checksum mismatch at block %1; normal TCP fallback remains active.").arg(height);
        if (m_lan_quick_clone_enabled) m_lan_quick_clone_status = m_lan_fast_sync_status;
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }

    LanFastSyncReadyBlock ready;
    ready.block = block;
    ready.host = transfer.host;
    ready.hash = transfer.expected_hash.isEmpty() ? transfer.block_hash : transfer.expected_hash;
    ready.node_id = transfer.node_id;
    ready.height = transfer.height;
    ready.request_ms = transfer.request_ms;
    m_lan_fast_sync_ready_blocks_by_height.insert(ready.height, ready);
    m_lan_fast_sync_transfers_by_id.remove(request_id);
    updateLanFastSyncRequestState();
    refreshLanFastSyncCurrentTargetHosts();
    m_lan_fast_sync_status = QStringLiteral("UDP fast sync staged block %1 from %2 (%3 active, %4 staged).")
        .arg(ready.height)
        .arg(ready.host)
        .arg(m_lan_fast_sync_transfers_by_id.size())
        .arg(m_lan_fast_sync_ready_blocks_by_height.size());
    if (m_lan_quick_clone_enabled) m_lan_quick_clone_status = m_lan_fast_sync_status;
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
    submitNextLanFastSyncReadyBlock();
    QTimer::singleShot(0, this, &NuRpcService::lanFastSyncTick);
}

void NuRpcService::refreshFeeEstimate()
{
    rpcCall(QStringLiteral("estimatesmartfee"), {6, QStringLiteral("CONSERVATIVE")}, false, [this](const QJsonValue& result, const QString& error) {
        QString status;
        bool available = false;
        if (!error.isEmpty()) {
            status = QStringLiteral("Fee estimate unavailable: %1").arg(error);
        } else {
            const QJsonObject estimate = result.toObject();
            if (estimate.contains(QStringLiteral("feerate")) && estimate.value(QStringLiteral("feerate")).isDouble()) {
                available = true;
                status = QStringLiteral("Reference estimate, 6-block conservative: %1 DFC/kB").arg(QString::number(estimate.value(QStringLiteral("feerate")).toDouble(), 'f', 8));
            } else {
                QStringList reasons;
                for (const QJsonValue& reason : estimate.value(QStringLiteral("errors")).toArray()) {
                    reasons.push_back(reason.toString());
                }
                status = reasons.isEmpty()
                    ? QStringLiteral("Fee estimate unavailable; the backend will use fallback or minimum relay policy.")
                    : QStringLiteral("Fee estimate unavailable: %1").arg(reasons.join(QStringLiteral("; ")));
            }
        }
        if (m_fee_estimate_available != available || m_fee_estimate_status != status) {
            m_fee_estimate_available = available;
            m_fee_estimate_status = status;
            Q_EMIT feeEstimateChanged();
        }
    });
}

void NuRpcService::refreshDebugLog()
{
    const QString path = debugLogPath();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
    const qint64 size = file.size();
    constexpr qint64 INITIAL_READ_LIMIT = 2 * 1024 * 1024;
    constexpr qint64 INCREMENTAL_READ_LIMIT = 512 * 1024;
    auto count_newlines_before = [&file](qint64 end) {
        const qint64 original_pos = file.pos();
        file.seek(0);
        qint64 remaining = qMax<qint64>(0, end);
        int count = 0;
        while (remaining > 0) {
            const QByteArray chunk = file.read(qMin<qint64>(remaining, 64 * 1024));
            if (chunk.isEmpty()) break;
            count += chunk.count('\n');
            remaining -= chunk.size();
        }
        file.seek(original_pos);
        return count;
    };
    const bool reset_reader = (m_debug_log_path != path || m_debug_log_offset < 0 || m_debug_log_offset > size);
    QByteArray data;
    if (reset_reader) {
        const qint64 start = qMax<qint64>(0, size - INITIAL_READ_LIMIT);
        m_debug_log_next_line_number = count_newlines_before(start) + 1;
        file.seek(start);
        data = file.read(size - start);
        if (start > 0) {
            const int first_newline = data.indexOf('\n');
            if (first_newline >= 0) {
                data.remove(0, first_newline + 1);
                ++m_debug_log_next_line_number;
            }
        }
        m_debug_log_path = path;
        m_debug_log_collecting_continuation = false;
        if (m_log_lines.size() == 1 && m_log_lines.first().startsWith(QStringLiteral("No debug.log lines"))) {
            m_log_lines.clear();
            m_log_line_numbers.clear();
        }
    } else {
        if (size == m_debug_log_offset) return;
        qint64 start = m_debug_log_offset;
        if (size - start > INCREMENTAL_READ_LIMIT) {
            start = size - INCREMENTAL_READ_LIMIT;
            m_debug_log_next_line_number = count_newlines_before(start) + 1;
            m_debug_log_collecting_continuation = false;
            if (m_log_lines.isEmpty() || !m_log_lines.last().startsWith(QStringLiteral("... log gap"))) {
                appendLogLine(QStringLiteral("... log gap omitted from in-app view. Use Open debug.log for the backend log file."));
            }
        }
        file.seek(start);
        data = file.read(size - start);
        if (start != m_debug_log_offset) {
            const int first_newline = data.indexOf('\n');
            if (first_newline >= 0) {
                data.remove(0, first_newline + 1);
                ++m_debug_log_next_line_number;
            }
        }
    }
    m_debug_log_offset = size;
    if (data.isEmpty()) return;

    const QList<QByteArray> lines = data.split('\n');
    const QDateTime launch_floor = m_app_launch_utc.addSecs(-2);
    QStringList new_lines;
    QVariantList new_line_numbers;
    int current_debug_line_number = m_debug_log_next_line_number;
    for (int i = 0; i < lines.size(); ++i) {
        if (i == lines.size() - 1 && lines.at(i).isEmpty()) continue;
        const int source_line_number = current_debug_line_number++;
        const QString line = QString::fromUtf8(lines.at(i)).trimmed();
        if (line.isEmpty()) continue;

        QDateTime utc;
        QString message;
        if (parseDebugLogTimestamp(line, utc, message)) {
            if (message.startsWith(QStringLiteral("Nu startup:"))
                || message.startsWith(QStringLiteral("----- Nu startup diagnostics"))
                || message.startsWith(QStringLiteral("----- Backend debug.log"))) {
                continue;
            }
            m_debug_log_collecting_continuation = utc >= launch_floor;
            if (m_debug_log_collecting_continuation) {
                new_lines.push_back(localLogTimestamp(utc) + QStringLiteral(" ") + message);
                new_line_numbers.push_back(source_line_number);
            }
            continue;
        }

        if (m_debug_log_collecting_continuation) {
            new_lines.push_back(line);
            new_line_numbers.push_back(source_line_number);
        }
    }
    m_debug_log_next_line_number = current_debug_line_number;
    if (new_lines.isEmpty() && m_log_lines.isEmpty()) {
        new_lines.push_back(QStringLiteral("No debug.log lines have been written since this Nu launch yet (%1).")
                                .arg(QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))));
        new_line_numbers.push_back(QVariant());
    }
    if (new_lines.isEmpty()) return;
    if (m_log_lines.size() == 1 && m_log_lines.first().startsWith(QStringLiteral("No debug.log lines"))) {
        m_log_lines.clear();
        m_log_line_numbers.clear();
    }
    beginBackendDebugLogSection(false);
    m_log_lines.append(new_lines);
    m_log_line_numbers.append(new_line_numbers);
    if (m_log_lines.size() > 5000) {
        const int trim_count = m_log_lines.size() - 5000;
        m_log_lines = m_log_lines.mid(m_log_lines.size() - 5000);
        m_log_line_numbers = m_log_line_numbers.mid(qMin(trim_count, m_log_line_numbers.size()));
        m_log_lines.push_front(QStringLiteral("... earlier current-launch log lines omitted from the in-app view. Use Open debug.log for the backend log file."));
        m_log_line_numbers.push_front(QVariant());
    }
    trimLogLines();
    Q_EMIT logChanged();
}

void NuRpcService::requestNewAddress(const QString& label, const QString& amount, const QString& message)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Address request failed"))) return;
    const QString clean_amount = amount.trimmed();
    if (!clean_amount.isEmpty()) {
        bool amount_ok = false;
        const double amount_value = clean_amount.toDouble(&amount_ok);
        if (!amount_ok || amount_value <= 0.0) {
            Q_EMIT userMessage(QStringLiteral("Payment request not created"),
                               QStringLiteral("Enter a positive amount in DFC, or leave the amount blank."));
            return;
        }
    }

    QJsonArray params;
    params.push_back(label);
    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("getnewaddress"), params, true, [this, wallet_name, label, amount, message](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Address request failed"), error);
            return;
        }
        m_receive_address = result.toString();
        m_receive_label = label.trimmed();
        m_receive_amount = amount.trimmed();
        m_receive_message = message.trimmed();
        const QString uri = defcoinUri(m_receive_address, m_receive_amount, m_receive_label, m_receive_message);
        const QVariantMap meta = receiveRequestMeta(m_receive_address,
                                                    m_receive_label,
                                                    m_receive_amount,
                                                    m_receive_message,
                                                    uri,
                                                    QString(),
                                                    QDateTime::currentMSecsSinceEpoch());
        m_receive_requests.push_front(receiveRequestRow(meta));
        saveReceiveRequests();
        updateReceiveQr();
        refreshAddressBook();
        Q_EMIT walletChanged();
    });
}

void NuRpcService::deleteReceiveRequest(const QString& address)
{
    QVariantList addresses;
    addresses.push_back(address);
    deleteReceiveRequests(addresses);
}

void NuRpcService::deleteReceiveRequests(const QVariantList& addresses)
{
    QSet<QString> targets;
    for (const QVariant& value : addresses) {
        const QString address = value.toString().trimmed();
        if (!address.isEmpty()) targets.insert(address);
    }
    if (targets.isEmpty()) return;

    QVariantList kept;
    int removed = 0;
    for (const QVariant& value : m_receive_requests) {
        const QVariantMap meta = value.toMap().value(QStringLiteral("meta")).toMap();
        const QString address = meta.value(QStringLiteral("address")).toString().trimmed();
        if (!address.isEmpty() && targets.contains(address)) {
            ++removed;
            continue;
        }
        kept.push_back(value);
    }
    if (removed == 0) return;

    m_receive_requests = kept;
    saveReceiveRequests();
    Q_EMIT walletChanged();
}

void NuRpcService::sendCoins(const QString& address,
                             const QString& amount,
                             const QString& fee_mode,
                             const QString& fee_target,
                             const QString& custom_fee_rate,
                             bool subtract_fee_from_amount,
                             const QString& label,
                             const QString& custom_change_address)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Payment not sent"))) return;
    QString recipient = address.trimmed();
    QString effective_amount = amount.trimmed();
    QString effective_label = label.trimmed();
    if (recipient.startsWith(QStringLiteral("defcoin:"), Qt::CaseInsensitive)) {
        QUrl uri(recipient);
        recipient = uri.path().isEmpty() ? uri.host() : uri.path();
        QUrlQuery query(uri);
        if (effective_amount.isEmpty() && query.hasQueryItem(QStringLiteral("amount"))) {
            effective_amount = query.queryItemValue(QStringLiteral("amount"));
        }
        if (effective_label.isEmpty() && query.hasQueryItem(QStringLiteral("label"))) {
            effective_label = query.queryItemValue(QStringLiteral("label"));
        }
    }

    bool amount_ok = false;
    const double amount_value = effective_amount.toDouble(&amount_ok);
    if (recipient.isEmpty() || !amount_ok || amount_value <= 0.0) {
        Q_EMIT userMessage(QStringLiteral("Payment not sent"), QStringLiteral("Enter a valid Defcoin address and amount."));
        return;
    }

    QString mode = fee_mode.trimmed().toLower();
    if (mode.contains(QStringLiteral("custom"))) {
        mode = QStringLiteral("custom");
    } else if (mode.contains(QStringLiteral("econom"))) {
        mode = QStringLiteral("economical");
    } else {
        mode = QStringLiteral("conservative");
    }
    bool target_ok = false;
    const int target = fee_target.toInt(&target_ok);
    bool fee_ok = false;
    const double fee_rate = custom_fee_rate.toDouble(&fee_ok);
    if (mode == QLatin1String("custom") && (!fee_ok || fee_rate <= 0.0)) {
        Q_EMIT userMessage(QStringLiteral("Payment not sent"), QStringLiteral("Enter a positive custom fee rate in motes/vB."));
        return;
    }

    const QString change_address = custom_change_address.trimmed();
    const QString wallet_name = m_wallet_name;
    if (!change_address.isEmpty()) {
        QJsonObject outputs;
        outputs.insert(recipient, amount_value);

        QJsonObject options;
        options.insert(QStringLiteral("add_inputs"), true);
        options.insert(QStringLiteral("add_to_wallet"), true);
        options.insert(QStringLiteral("change_address"), change_address);
        if (subtract_fee_from_amount) {
            QJsonArray subtract_outputs;
            subtract_outputs.push_back(0);
            options.insert(QStringLiteral("subtract_fee_from_outputs"), subtract_outputs);
        }
        QJsonArray params;
        params.push_back(outputs);
        params.push_back(mode == QLatin1String("custom") ? QJsonValue(QJsonValue::Null) : QJsonValue(target_ok && target > 0 ? target : 6));
        params.push_back(mode == QLatin1String("economical") ? QStringLiteral("economical") : (mode == QLatin1String("custom") ? QStringLiteral("unset") : QStringLiteral("conservative")));
        params.push_back(mode == QLatin1String("custom") ? QJsonValue(fee_rate) : QJsonValue(QJsonValue::Null));
        params.push_back(options);

        rpcCall(QStringLiteral("send"), params, true, [this, wallet_name, recipient, effective_label](const QJsonValue& result, const QString& error) {
            if (wallet_name != m_wallet_name) return;
            if (!error.isEmpty()) {
                Q_EMIT userMessage(QStringLiteral("Payment failed"), error);
                return;
            }
            if (!effective_label.isEmpty()) {
                setAddressLabel(recipient, effective_label);
            }
            const QString txid = result.toObject().value(QStringLiteral("txid")).toString();
            Q_EMIT userMessage(QStringLiteral("Payment sent"), QStringLiteral("Transaction ID: %1").arg(txid));
            refreshWallet();
        });
        return;
    }

    QJsonArray params;
    params.push_back(recipient);
    params.push_back(amount_value);
    params.push_back(effective_label);
    params.push_back(effective_label);
    params.push_back(subtract_fee_from_amount);
    params.push_back(QJsonValue(QJsonValue::Null));

    if (mode == QLatin1String("custom")) {
        params.push_back(QJsonValue(QJsonValue::Null));
        params.push_back(QStringLiteral("unset"));
    } else {
        params.push_back(target_ok && target > 0 ? QJsonValue(target) : QJsonValue(6));
        params.push_back(mode == QLatin1String("economical") ? QStringLiteral("economical") : QStringLiteral("conservative"));
    }
    params.push_back(QJsonValue(QJsonValue::Null));

    if (mode == QLatin1String("custom")) {
        params.push_back(fee_rate);
    } else {
        params.push_back(QJsonValue(QJsonValue::Null));
    }
    params.push_back(false);

    rpcCall(QStringLiteral("sendtoaddress"), params, true, [this, wallet_name, recipient, effective_label](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Payment failed"), error);
            return;
        }
        if (!effective_label.isEmpty()) {
            setAddressLabel(recipient, effective_label);
        }
        Q_EMIT userMessage(QStringLiteral("Payment sent"), QStringLiteral("Transaction ID: %1").arg(result.toString()));
        refreshWallet();
    });
}

void NuRpcService::createPsbt(const QString& address,
                              const QString& amount,
                              const QString& fee_mode,
                              const QString& fee_target,
                              const QString& custom_fee_rate,
                              bool subtract_fee_from_amount,
                              const QString& label,
                              const QString& custom_change_address)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("PSBT not created"))) return;
    QString recipient = address.trimmed();
    QString effective_amount = amount.trimmed();
    QString effective_label = label.trimmed();
    if (recipient.startsWith(QStringLiteral("defcoin:"), Qt::CaseInsensitive)) {
        QUrl uri(recipient);
        recipient = uri.path().isEmpty() ? uri.host() : uri.path();
        QUrlQuery query(uri);
        if (effective_amount.isEmpty() && query.hasQueryItem(QStringLiteral("amount"))) {
            effective_amount = query.queryItemValue(QStringLiteral("amount"));
        }
        if (effective_label.isEmpty() && query.hasQueryItem(QStringLiteral("label"))) {
            effective_label = query.queryItemValue(QStringLiteral("label"));
        }
    }

    bool amount_ok = false;
    const double amount_value = effective_amount.toDouble(&amount_ok);
    if (recipient.isEmpty() || !amount_ok || amount_value <= 0.0) {
        Q_EMIT userMessage(QStringLiteral("PSBT not created"), QStringLiteral("Enter a valid Defcoin address and amount."));
        return;
    }

    QString mode = fee_mode.trimmed().toLower();
    if (mode.contains(QStringLiteral("custom"))) {
        mode = QStringLiteral("custom");
    } else if (mode.contains(QStringLiteral("econom"))) {
        mode = QStringLiteral("economical");
    } else {
        mode = QStringLiteral("conservative");
    }
    bool target_ok = false;
    const int target = fee_target.toInt(&target_ok);
    bool fee_ok = false;
    const double fee_rate = custom_fee_rate.toDouble(&fee_ok);
    if (mode == QLatin1String("custom") && (!fee_ok || fee_rate <= 0.0)) {
        Q_EMIT userMessage(QStringLiteral("PSBT not created"), QStringLiteral("Enter a positive custom fee rate in motes/vB."));
        return;
    }

    QJsonObject output;
    output.insert(recipient, amount_value);
    QJsonArray outputs;
    outputs.push_back(output);

    QJsonObject options;
    options.insert(QStringLiteral("add_inputs"), true);
    if (mode == QLatin1String("custom")) {
        options.insert(QStringLiteral("fee_rate"), fee_rate);
    } else {
        options.insert(QStringLiteral("conf_target"), target_ok && target > 0 ? target : 6);
        options.insert(QStringLiteral("estimate_mode"), mode == QLatin1String("economical") ? QStringLiteral("economical") : QStringLiteral("conservative"));
    }
    const QString change_address = custom_change_address.trimmed();
    if (!change_address.isEmpty()) options.insert(QStringLiteral("changeAddress"), change_address);
    if (subtract_fee_from_amount) {
        QJsonArray subtract_outputs;
        subtract_outputs.push_back(0);
        options.insert(QStringLiteral("subtractFeeFromOutputs"), subtract_outputs);
    }

    QJsonArray params;
    params.push_back(QJsonArray());
    params.push_back(outputs);
    params.push_back(0);
    params.push_back(options);
    params.push_back(true);

    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("walletcreatefundedpsbt"), params, true, [this, wallet_name, recipient, effective_label](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("PSBT creation failed"), error);
            return;
        }
        const QJsonObject object = result.toObject();
        const QString psbt = object.value(QStringLiteral("psbt")).toString();
        if (psbt.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("PSBT creation failed"), QStringLiteral("The backend did not return PSBT data."));
            return;
        }
        if (!effective_label.isEmpty()) setAddressLabel(recipient, effective_label);
        m_current_psbt = psbt;
        m_current_psbt_final_hex.clear();
        m_current_psbt_summary = QStringLiteral("Created PSBT from Send review.\n\n%1")
            .arg(QString::fromUtf8(QJsonDocument(object).toJson(QJsonDocument::Indented)).trimmed());
        Q_EMIT psbtChanged();
        analyzeCurrentPsbt(QStringLiteral("walletcreatefundedpsbt"));
        Q_EMIT userMessage(QStringLiteral("PSBT created"), QStringLiteral("Review, copy, save, sign, or finalize the PSBT in Send > Advanced send options."));
    });
}

void NuRpcService::setAddressLabel(const QString& address, const QString& label)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Label update failed"))) return;
    if (address.trimmed().isEmpty()) return;
    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("setlabel"), {address.trimmed(), label.trimmed()}, true, [this, wallet_name](const QJsonValue&, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Label update failed"), error);
            return;
        }
        refreshAddressBook();
    });
}

QString NuRpcService::walletDisplayName(const QString& name) const
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty() || trimmed == QLatin1String("wallet.dat")) return QStringLiteral("Default wallet (wallet.dat)");

    QString normalized = trimmed;
    normalized.replace(QLatin1Char('\\'), QLatin1Char('/'));
    if (normalized.startsWith(QStringLiteral("wallets/"))) {
        const QString leaf = normalized.mid(QStringLiteral("wallets/").size());
        if (!leaf.isEmpty() && !leaf.contains(QLatin1Char('/'))) return leaf;
    }

    return trimmed;
}

void NuRpcService::updateWalletStatsEntry(const QString& wallet_name, const QVariantMap& updates)
{
    const QString normalized = normalizedWalletListName(wallet_name);
    bool changed = false;
    for (int i = 0; i < m_wallet_file_stats.size(); ++i) {
        QVariantMap item = m_wallet_file_stats.at(i).toMap();
        if (item.value(QStringLiteral("name")).toString() != normalized) continue;
        for (auto it = updates.constBegin(); it != updates.constEnd(); ++it) {
            if (item.value(it.key()) == it.value()) continue;
            item.insert(it.key(), it.value());
            changed = true;
        }
        m_wallet_file_stats[i] = item;
        if (m_wallet_selected && normalized == m_wallet_name) {
            if (item.contains(QStringLiteral("addressCount"))) {
                m_wallet_address_count = item.value(QStringLiteral("addressCount")).toInt();
            }
            if (item.contains(QStringLiteral("nonZeroAddressCount"))) {
                m_wallet_nonzero_address_count = item.value(QStringLiteral("nonZeroAddressCount")).toInt();
            }
        }
        break;
    }
    if (changed) Q_EMIT walletChanged();
}

void NuRpcService::refreshWalletStats()
{
    QStringList wallets = m_available_wallets;
    for (const QString& wallet : m_loaded_wallets) wallets.push_back(normalizedWalletListName(wallet));
    if (walletDefaultDatExists(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir)) wallets.push_back(QString());
    wallets.removeDuplicates();
    wallets.sort(Qt::CaseInsensitive);

    QVariantList rows;
    for (const QString& raw_name : wallets) {
        const QString name = normalizedWalletListName(raw_name);
        const bool loaded = m_loaded_wallets.contains(name);
        const bool current = m_wallet_selected && name == m_wallet_name;
        const QString storage_type = walletStorageTypeForName(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir, name);
        QVariantMap item;
        item.insert(QStringLiteral("name"), name);
        item.insert(QStringLiteral("display"), walletDisplayName(name));
        item.insert(QStringLiteral("active"), current);
        item.insert(QStringLiteral("loaded"), loaded);
        item.insert(QStringLiteral("state"), current ? QStringLiteral("Current") : (loaded ? QStringLiteral("Loaded") : QStringLiteral("Available")));
        item.insert(QStringLiteral("type"), storage_type);
        item.insert(QStringLiteral("total"), current ? m_total_balance : (loaded ? QStringLiteral("Loading") : QStringLiteral("Load to scan")));
        item.insert(QStringLiteral("available"), current ? m_available_balance : (loaded ? QStringLiteral("Loading") : QStringLiteral("-")));
        item.insert(QStringLiteral("pending"), current ? m_pending_balance : (loaded ? QStringLiteral("Loading") : QStringLiteral("-")));
        item.insert(QStringLiteral("immature"), current ? m_immature_balance : (loaded ? QStringLiteral("Loading") : QStringLiteral("-")));
        item.insert(QStringLiteral("transactions"), current ? QString::number(m_wallet_transaction_count) : (loaded ? QStringLiteral("Loading") : QStringLiteral("-")));
        item.insert(QStringLiteral("addressCount"), current ? m_wallet_address_count : -1);
        item.insert(QStringLiteral("nonZeroAddressCount"), current ? m_wallet_nonzero_address_count : -1);
        rows.push_back(item);
    }
    m_wallet_file_stats = rows;
    Q_EMIT walletChanged();

    for (const QString& raw_name : wallets) {
        const QString name = normalizedWalletListName(raw_name);
        if (!m_loaded_wallets.contains(name)) continue;

        rpcCallForWallet(QStringLiteral("getwalletinfo"), {}, name, [this, name](const QJsonValue& result, const QString& error) {
            QVariantMap updates;
            if (!error.isEmpty() || !result.isObject()) {
                updates.insert(QStringLiteral("state"), QStringLiteral("Unavailable"));
                updateWalletStatsEntry(name, updates);
                return;
            }
            const QJsonObject wallet = result.toObject();
            const double available = wallet.value(QStringLiteral("balance")).toDouble();
            const double pending = wallet.value(QStringLiteral("unconfirmed_balance")).toDouble();
            const double immature = wallet.value(QStringLiteral("immature_balance")).toDouble();
            updates.insert(QStringLiteral("type"), walletStorageTypeFromFormat(wallet.value(QStringLiteral("format")).toString()));
            updates.insert(QStringLiteral("descriptors"), wallet.value(QStringLiteral("descriptors")).toBool(false));
            updates.insert(QStringLiteral("total"), walletAmountText(available + pending + immature, true));
            updates.insert(QStringLiteral("available"), walletAmountText(available));
            updates.insert(QStringLiteral("pending"), walletAmountText(pending));
            updates.insert(QStringLiteral("immature"), walletAmountText(immature));
            updates.insert(QStringLiteral("transactions"), QString::number(wallet.value(QStringLiteral("txcount")).toInt(0)));
            updateWalletStatsEntry(name, updates);
        });

        rpcCallForWallet(QStringLiteral("listreceivedbyaddress"), {0, true, true}, name, [this, name](const QJsonValue& result, const QString& error) {
            if (!error.isEmpty() || !result.isArray()) return;
            int addresses = 0;
            int nonzero = 0;
            for (const QJsonValue& value : result.toArray()) {
                const QJsonObject item = value.toObject();
                const QString address = item.value(QStringLiteral("address")).toString().trimmed();
                if (address.isEmpty()) continue;
                ++addresses;
                if (std::fabs(item.value(QStringLiteral("amount")).toDouble()) > 0.000000005) ++nonzero;
            }
            QVariantMap updates;
            updates.insert(QStringLiteral("addressCount"), addresses);
            updates.insert(QStringLiteral("nonZeroAddressCount"), nonzero);
            updateWalletStatsEntry(name, updates);
        });
    }
}

void NuRpcService::setNetworkActive(bool active)
{
    m_have_pending_network_active = true;
    m_pending_network_active = active;
    rpcCall(QStringLiteral("setnetworkactive"), {active}, false, [this, active](const QJsonValue&, const QString& error) {
        m_applying_pending_network_active = false;
        if (!error.isEmpty()) {
            if (m_connection_status == QLatin1String("Starting backend") ||
                error.startsWith(QStringLiteral("Starting Defcoin backend"))) {
                Q_EMIT userMessage(QStringLiteral("Starting backend"),
                                   QStringLiteral("Defcoin Core Nu is starting the backend and will apply the network setting when RPC is ready."));
                QTimer::singleShot(2500, this, &NuRpcService::refresh);
                return;
            }
            Q_EMIT userMessage(QStringLiteral("Network update failed"), error);
            return;
        }
        m_have_pending_network_active = false;
        m_network_state = active ? QStringLiteral("connected") : QStringLiteral("isolated");
        refreshNode();
    });
}

void NuRpcService::scheduleWitnessBlockRepair(int start_height)
{
    int height = start_height;
    if (height <= 0) height = 903168;

    QSettings settings;
    settings.setValue(QStringLiteral("RepairWitnessFromHeight"), height);
    settings.sync();

    appendLaunchDiagnostic(QStringLiteral("Scheduled one-shot witness block data repair from height %1 for the next Nu-managed backend launch.").arg(height));
    Q_EMIT userMessage(QStringLiteral("Blockchain repair scheduled"),
                       QStringLiteral("Nu will pass -repairwitnessfromheight=%1 the next time it starts its bundled backend. Quit and reopen Defcoin Core Nu to run the repair. This redownloads incomplete block bodies; it is separate from a wallet rescan.").arg(height));
}

void NuRpcService::repairWitnessBlockDataNow(int start_height, bool fix_missing_witness)
{
    int height = start_height;
    if (height <= 0) height = 903168;

    if (m_block_height > 0 && height > m_block_height) {
        m_forensics_witness_repair_running = false;
        m_forensics_witness_repair_start_height = height;
        m_forensics_witness_repair_inspected_blocks = 0;
        m_forensics_witness_repair_first_missing_height = -1;
        m_forensics_witness_repair_status = QStringLiteral("Inspection not started. Requested start height %1 is above the current active-chain height %2, so there are no local blocks in that range to inspect yet.")
            .arg(QString::number(height), QString::number(m_block_height));
        Q_EMIT forensicsChanged();
        Q_EMIT userMessage(QStringLiteral("Blockchain inspection not started"), m_forensics_witness_repair_status);
        return;
    }

    if (m_forensics_witness_repair_running) {
        Q_EMIT userMessage(QStringLiteral("Inspection already running"),
                           QStringLiteral("A witness data inspection is already running. Wait for it to finish before starting another one."));
        return;
    }
    if (m_forensics_witness_capability_known && !m_forensics_witness_inspection_available) {
        const QString message = QStringLiteral("This backend does not support witness inspection. Stop older defcoind instances and launch the bundled Nu backend.");
        m_forensics_witness_repair_status = message;
        Q_EMIT forensicsChanged();
        Q_EMIT userMessage(QStringLiteral("Witness inspection unavailable"), message);
        return;
    }
    if (!m_forensics_witness_capability_known) {
        probeBackendCapabilities();
        Q_EMIT userMessage(QStringLiteral("Checking backend capability"),
                           QStringLiteral("Nu is checking whether the active backend supports witness inspection. Try Inspect again after the check completes."));
        return;
    }

    appendLaunchDiagnostic(QStringLiteral("Live witness block data inspection requested from height %1. Fix missing witness data: %2.")
        .arg(height)
        .arg(fix_missing_witness ? QStringLiteral("yes") : QStringLiteral("no")));
    m_forensics_witness_repair_running = true;
    m_forensics_witness_repair_start_height = height;
    m_forensics_witness_repair_inspected_blocks = 0;
    m_forensics_witness_repair_first_missing_height = -1;
    m_forensics_witness_repair_status = fix_missing_witness
        ? QStringLiteral("Inspecting witness-form block storage from height %1. If missing witness data is found, Nu will rewind from the first affected block and resume normal sync.").arg(height)
        : QStringLiteral("Inspecting witness-form block storage from height %1 without changing stored blocks.").arg(height);
    m_last_error = fix_missing_witness
        ? QStringLiteral("Inspecting witness block data from height %1. Networking pauses only if a rewind is required.").arg(height)
        : QStringLiteral("Inspecting witness block data from height %1 without changing stored blocks.").arg(height);
    m_metric_network_active = QStringLiteral("Inspecting");
    rebuildNodeMetrics();
    Q_EMIT forensicsChanged();
    Q_EMIT stateChanged();

    const int chunk_size = 20000;
    auto total_required_blocks = std::make_shared<int>(0);
    auto total_block_bodies_read = std::make_shared<int>(0);
    auto missing_count = std::make_shared<int>(0);
    auto run_next = std::make_shared<std::function<void(int)>>();
    *run_next = [this, height, fix_missing_witness, chunk_size, total_required_blocks, total_block_bodies_read, missing_count, run_next](int current_height) mutable {
        rpcCall(QStringLiteral("scanwitnessblockdata"), {current_height, -1, chunk_size}, false,
                [this, height, fix_missing_witness, total_required_blocks, total_block_bodies_read, missing_count, run_next](const QJsonValue& result, const QString& error) mutable {
            if (!m_forensics_witness_repair_running) return;
            if (!error.isEmpty()) {
                m_forensics_witness_repair_running = false;
                appendLaunchDiagnostic(QStringLiteral("Live witness block data inspection failed from height %1: %2").arg(height).arg(error));
                const bool method_missing = error.contains(QStringLiteral("Method not found"), Qt::CaseInsensitive)
                    || error.contains(QStringLiteral("scanwitnessblockdata"), Qt::CaseInsensitive);
                if (method_missing) {
                    m_forensics_witness_capability_known = true;
                    m_forensics_witness_inspection_available = false;
                    m_forensics_witness_repair_status = QStringLiteral("This backend does not support witness inspection. Stop older defcoind instances and launch the bundled Nu backend.");
                } else {
                    m_forensics_witness_repair_status = QStringLiteral("Inspection failed from block %1: %2").arg(QString::number(height), error);
                }
                Q_EMIT forensicsChanged();
                Q_EMIT userMessage(QStringLiteral("Blockchain inspection failed"), m_forensics_witness_repair_status);
                refreshNode();
                return;
            }

            const QJsonObject obj = result.toObject();
            const int inspected = obj.value(QStringLiteral("inspected_blocks")).toInt();
            const int required = obj.value(QStringLiteral("witness_required_blocks")).toInt();
            const int bodies_read = obj.value(QStringLiteral("block_bodies_read")).toInt();
            const int worker_threads = obj.value(QStringLiteral("worker_threads")).toInt(1);
            const int next_height = obj.value(QStringLiteral("next_height")).toInt();
            const int end_height = obj.value(QStringLiteral("end_height")).toInt();
            const bool complete = obj.value(QStringLiteral("complete")).toBool();
            const bool missing_found = obj.value(QStringLiteral("missing_witness_found")).toBool();
            const int first_missing = obj.value(QStringLiteral("first_missing_witness_height")).toInt(-1);
            const int chunk_missing = obj.value(QStringLiteral("missing_witness_count")).toInt();

            m_forensics_witness_repair_inspected_blocks += inspected;
            *total_required_blocks += required;
            *total_block_bodies_read += bodies_read;
            *missing_count += chunk_missing;
            if (first_missing > 0 && m_forensics_witness_repair_first_missing_height < 0) {
                m_forensics_witness_repair_first_missing_height = first_missing;
            }
            const double pct = end_height >= height
                ? 100.0 * static_cast<double>(std::min(end_height, std::max(height, next_height) - 1) - height + 1) / static_cast<double>(std::max(1, end_height - height + 1))
                : 100.0;
            m_forensics_witness_repair_status = QStringLiteral("Inspecting witness-form block storage from height %1. Checked through %2 of %3 (%4%). Blocks inspected: %5. Witness-required blocks: %6. Block bodies read: %7. Missing witness blocks found: %8. Workers: %9.")
                .arg(QString::number(height),
                     QString::number(std::max(height, next_height) - 1),
                     QString::number(end_height),
                     QString::number(std::min(100.0, std::max(0.0, pct)), 'f', 2),
                     QString::number(m_forensics_witness_repair_inspected_blocks),
                     QString::number(*total_required_blocks),
                     QString::number(*total_block_bodies_read),
                     QString::number(*missing_count),
                     QString::number(worker_threads));
            Q_EMIT forensicsChanged();

            if (missing_found && fix_missing_witness) {
                m_forensics_witness_repair_status += QStringLiteral("\n\nMissing witness data begins at block %1. Rewinding from that height now so normal sync can redownload clean witness-form blocks.")
                    .arg(QString::number(first_missing));
                Q_EMIT forensicsChanged();
                rpcCall(QStringLiteral("repairwitnessblockdata"), {first_missing, true, true}, false,
                        [this, height, first_missing](const QJsonValue& repair_result, const QString& repair_error) {
                    m_forensics_witness_repair_running = false;
                    if (!repair_error.isEmpty()) {
                        m_forensics_witness_repair_status = QStringLiteral("Repair failed after finding missing witness data at block %1: %2")
                            .arg(QString::number(first_missing), repair_error);
                        Q_EMIT forensicsChanged();
                        Q_EMIT userMessage(QStringLiteral("Blockchain repair failed"), repair_error);
                        refreshNode();
                        return;
                    }
                    const QJsonObject repair = repair_result.toObject();
                    const int before = repair.value(QStringLiteral("height_before")).toInt();
                    const int after = repair.value(QStringLiteral("height_after_rewind")).toInt();
                    const QString next_step = repair.value(QStringLiteral("next_step")).toString();
                    m_forensics_witness_repair_status = QStringLiteral("%1\n\nStart height: %2\nFirst missing witness block: %3\nBlocks inspected before repair: %4\nHeight before: %5\nHeight after rewind: %6")
                        .arg(next_step.isEmpty() ? QStringLiteral("Witness block repair completed.") : next_step,
                             QString::number(height),
                             QString::number(first_missing),
                             QString::number(m_forensics_witness_repair_inspected_blocks),
                             QString::number(before),
                             QString::number(after));
                    Q_EMIT forensicsChanged();
                    Q_EMIT userMessage(QStringLiteral("Blockchain repair complete"), m_forensics_witness_repair_status);
                    refreshNode();
                });
                return;
            }

            if (!complete) {
                QTimer::singleShot(0, this, [run_next, next_height] { (*run_next)(next_height); });
                return;
            }

            m_forensics_witness_repair_running = false;
            const QString finding = m_forensics_witness_repair_first_missing_height > 0
                ? QStringLiteral("Missing witness data was found beginning at block %1. No data was changed because Fix missing witness data was off.")
                      .arg(QString::number(m_forensics_witness_repair_first_missing_height))
                : QStringLiteral("No missing witness block data was found in the selected active-chain range.");
            m_forensics_witness_repair_status = QStringLiteral("%1\n\nStart height: %2\nBlocks inspected: %3\nWitness-required blocks: %4\nBlock bodies read: %5\nMissing witness blocks found: %6")
                .arg(finding,
                     QString::number(height),
                     QString::number(m_forensics_witness_repair_inspected_blocks),
                     QString::number(*total_required_blocks),
                     QString::number(*total_block_bodies_read),
                     QString::number(*missing_count));
            appendLaunchDiagnostic(QStringLiteral("Live witness block data inspection completed from height %1. Inspected: %2. Witness-required: %3. Block bodies read: %4. Missing witness count: %5. First missing witness height: %6.")
                .arg(height)
                .arg(m_forensics_witness_repair_inspected_blocks)
                .arg(*total_required_blocks)
                .arg(*total_block_bodies_read)
                .arg(*missing_count)
                .arg(m_forensics_witness_repair_first_missing_height > 0 ? QString::number(m_forensics_witness_repair_first_missing_height) : QStringLiteral("none")));
            Q_EMIT forensicsChanged();
            Q_EMIT userMessage(QStringLiteral("Blockchain inspection complete"), m_forensics_witness_repair_status);
            refreshNode();
        });
    };
    (*run_next)(height);
}

void NuRpcService::pingPeers()
{
    rpcCall(QStringLiteral("ping"), {}, false, [this](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) Q_EMIT userMessage(QStringLiteral("Ping failed"), error);
    });
}

void NuRpcService::refreshPeer(const QString& node_id)
{
    bool ok = false;
    const int id = node_id.trimmed().toInt(&ok);
    if (!ok || id < 0) {
        Q_EMIT userMessage(QStringLiteral("Refresh peer failed"), QStringLiteral("Select one peer row first."));
        return;
    }
    const QString host = m_peer_host_by_node_id.value(id).trimmed();
    if (host.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Refresh peer failed"), QStringLiteral("Nu does not have a current endpoint for that peer."));
        return;
    }

    QHostAddress address;
    if (address.setAddress(host)) {
        const QString host_key = normalizedFastSyncHost(address);
        m_udp_fast_sync_available_peer_hosts.remove(host_key);
        m_udp_fast_sync_attempted_peer_hosts.remove(host_key);
        m_udp_fast_sync_failed_peer_hosts.remove(host_key);
        m_udp_fast_sync_used_peer_hosts.remove(host_key);
        m_udp_fast_sync_current_target_hosts.remove(host_key);
        m_udp_fast_sync_last_request_ms_by_host.remove(host_key);
        m_udp_fast_sync_last_probe_ms_by_host.remove(host_key);
        const QString probe_id = m_udp_fast_sync_probe_ids_by_host.take(host_key);
        if (!probe_id.isEmpty()) {
            m_udp_fast_sync_probe_hosts_by_id.remove(probe_id);
        }
        m_udp_fast_sync_probe_failures_by_host.remove(host_key);
        m_udp_fast_sync_peer_node_ids_by_host.remove(host_key);
        m_udp_fast_sync_peer_inflight_counts_by_host.remove(host_key);
    }

    QJsonArray disconnect_params;
    disconnect_params.push_back(QString());
    disconnect_params.push_back(id);
    rpcCall(QStringLiteral("disconnectnode"), disconnect_params, false, [this, id, host](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Refresh peer failed"), error);
            return;
        }

        QString target = m_peer_addr_by_node_id.value(id).trimmed();
        if (m_peer_inbound_by_node_id.value(id, false) || target.isEmpty()) {
            QHostAddress address;
            target = address.setAddress(host) && address.protocol() == QAbstractSocket::IPv6Protocol
                ? QStringLiteral("[%1]:%2").arg(host).arg(DEFCOIN_DEFAULT_P2P_PORT)
                : QStringLiteral("%1:%2").arg(host).arg(DEFCOIN_DEFAULT_P2P_PORT);
        }

        rpcCall(QStringLiteral("addnode"), {target, QStringLiteral("onetry")}, false, [this, target](const QJsonValue&, const QString& add_error) {
            if (!add_error.isEmpty()) {
                Q_EMIT userMessage(QStringLiteral("Peer disconnected"),
                                   QStringLiteral("Nu cleared cached Fast Sync state and disconnected the peer. Reconnect attempt to %1 failed: %2")
                                       .arg(target, add_error));
            } else {
                Q_EMIT userMessage(QStringLiteral("Peer refresh started"),
                                   QStringLiteral("Nu cleared cached Fast Sync state and asked Core to reconnect to %1.").arg(target));
            }
            refreshNode();
        });
    });
}

void NuRpcService::banPeer(const QString& node_id)
{
    bool ok = false;
    const int id = node_id.trimmed().toInt(&ok);
    if (!ok || id < 0) {
        Q_EMIT userMessage(QStringLiteral("Ban peer failed"), QStringLiteral("Select one peer row first."));
        return;
    }
    const QString host = m_peer_host_by_node_id.value(id).trimmed();
    if (host.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Ban peer failed"), QStringLiteral("Nu does not have a current endpoint for that peer."));
        return;
    }

    rpcCall(QStringLiteral("setban"), {host, QStringLiteral("add")}, false, [this, id, host](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Ban peer failed"), error);
            return;
        }
        QJsonArray disconnect_params;
        disconnect_params.push_back(QString());
        disconnect_params.push_back(id);
        rpcCall(QStringLiteral("disconnectnode"), disconnect_params, false, [this, host](const QJsonValue&, const QString&) {
            Q_EMIT userMessage(QStringLiteral("Peer banned"), QStringLiteral("%1 was added to Core's ban list.").arg(host));
            refreshBannedPeerRows();
            refreshNode();
        });
    });
}

void NuRpcService::unbanPeer(const QString& address)
{
    const QString clean = address.trimmed();
    if (clean.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Unban failed"), QStringLiteral("Select a banned peer row first."));
        return;
    }
    rpcCall(QStringLiteral("setban"), {clean, QStringLiteral("remove")}, false, [this, clean](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Unban failed"), error);
            return;
        }
        Q_EMIT userMessage(QStringLiteral("Peer unbanned"), QStringLiteral("%1 was removed from Core's ban list.").arg(clean));
        refreshBannedPeerRows();
        refreshNode();
    });
}

void NuRpcService::refreshBannedPeers()
{
    refreshBannedPeerRows();
}

void NuRpcService::refreshBannedPeerRows()
{
    rpcCall(QStringLiteral("listbanned"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) return;
        QVariantList rows;
        for (const QJsonValue& value : result.toArray()) {
            const QJsonObject ban = value.toObject();
            const QString address = ban.value(QStringLiteral("address")).toString();
            const qint64 created = ban.value(QStringLiteral("ban_created")).toVariant().toLongLong();
            const qint64 until = ban.value(QStringLiteral("banned_until")).toVariant().toLongLong();
            const QString reason = ban.value(QStringLiteral("ban_reason")).toString(QStringLiteral("-"));
            const auto time_text = [](qint64 seconds) {
                if (seconds <= 0) return QStringLiteral("-");
                return QDateTime::fromSecsSinceEpoch(seconds).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"));
            };
            rows.push_back(tableRow({
                address,
                reason.isEmpty() ? QStringLiteral("-") : reason,
                time_text(created),
                time_text(until)
            }, {
                {QStringLiteral("address"), address}
            }));
        }
        m_banned_peer_rows = rows;
        Q_EMIT peersChanged();
    });
}

void NuRpcService::runRpcCommand(const QString& method, const QString& params_json, bool wallet_scoped)
{
    QString clean_method = method.trimmed();
    QString clean_params = params_json.trimmed();
    constexpr int max_console_command_chars = 32768;
    if (clean_method.size() + clean_params.size() > max_console_command_chars) {
        m_console_output += QStringLiteral("\n\n> [large paste omitted]\nConsole input is too large. Keep command input under %1 characters.")
            .arg(QString::number(max_console_command_chars));
        Q_EMIT consoleChanged();
        return;
    }

    QString batch_error;
    const QStringList command_texts = clean_params.isEmpty()
        ? splitConsolePasteCommands(clean_method, &batch_error)
        : QStringList{clean_method};
    if (!batch_error.isEmpty()) {
        m_console_output += QStringLiteral("\n\n> %1\n%2")
            .arg(singleLineLimited(clean_method, 120), batch_error);
        Q_EMIT consoleChanged();
        return;
    }

    auto parsed_commands = std::make_shared<QVector<ParsedConsoleCommand>>();
    parsed_commands->reserve(command_texts.size());
    for (const QString& command_text : command_texts) {
        ParsedConsoleCommand parsed;
        QString parse_error;
        if (!parseConsoleCommandForRpc(command_text, command_texts.size() == 1 ? clean_params : QString(), &parsed, &parse_error)) {
            m_console_output += QStringLiteral("\n\n> %1\n%2")
                .arg(singleLineLimited(command_text, 120), parse_error);
            Q_EMIT consoleChanged();
            return;
        }
        parsed_commands->push_back(parsed);
    }

    if (parsed_commands->isEmpty()) {
        m_console_output += QStringLiteral("\n\n> \nEnter an RPC method name.");
        Q_EMIT consoleChanged();
        return;
    }

    if (parsed_commands->size() > 1) {
        if (m_console_output.startsWith(QStringLiteral("Enter an RPC method"))) {
            m_console_output.clear();
        }
        m_console_output += QStringLiteral("%1> [pasted batch]\nRunning %2 RPC commands.")
            .arg(m_console_output.isEmpty() ? QString() : QStringLiteral("\n\n"),
                 QString::number(parsed_commands->size()));
        Q_EMIT consoleChanged();
    }

    auto run_next = std::make_shared<std::function<void(int)>>();
    *run_next = [this, parsed_commands, wallet_scoped, run_next](int index) {
        if (index >= parsed_commands->size()) return;
        const ParsedConsoleCommand command = parsed_commands->at(index);
        rpcCall(command.method, command.params, wallet_scoped, [this, command, run_next, index](const QJsonValue& result, const QString& error) {
        QString rendered;
        if (!error.isEmpty()) {
            rendered = QStringLiteral("%1 failed:\n%2").arg(command.method, error);
        } else {
            QJsonDocument out_doc;
            if (result.isObject()) {
                out_doc = QJsonDocument(result.toObject());
            } else if (result.isArray()) {
                out_doc = QJsonDocument(result.toArray());
            }
            if (!out_doc.isNull()) {
                rendered = QString::fromUtf8(out_doc.toJson(QJsonDocument::Indented));
            } else if (result.isString()) {
                rendered = result.toString();
            } else if (result.isBool()) {
                rendered = result.toBool() ? QStringLiteral("true") : QStringLiteral("false");
            } else if (result.isDouble()) {
                rendered = QString::number(result.toDouble(), 'f', 8);
            } else if (result.isNull()) {
                rendered = QStringLiteral("null");
            } else {
                rendered = QStringLiteral("(empty result)");
            }
        }
        if (m_console_output.startsWith(QStringLiteral("Enter an RPC method"))) {
            m_console_output.clear();
        }
        m_console_output += QStringLiteral("%1> %2\n%3").arg(m_console_output.isEmpty() ? QString() : QStringLiteral("\n\n"), command.prompt, rendered.trimmed());
        constexpr int max_console_chars = 80000;
        if (m_console_output.size() > max_console_chars) {
            m_console_output = m_console_output.right(max_console_chars);
        }
        Q_EMIT consoleChanged();
            (*run_next)(index + 1);
        });
    };
    (*run_next)(0);
}

void NuRpcService::runRpcConsoleCommand(const QString& command_text, const QString& wallet_name)
{
    QString clean_command = command_text.trimmed();
    constexpr int max_console_command_chars = 32768;
    if (clean_command.size() > max_console_command_chars) {
        m_console_output += QStringLiteral("\n\n! [large paste omitted]\nConsole input is too large. Keep command input under %1 characters.")
            .arg(QString::number(max_console_command_chars));
        Q_EMIT consoleChanged();
        return;
    }

    QString batch_error;
    const QStringList command_texts = splitConsolePasteCommands(clean_command, &batch_error);
    if (!batch_error.isEmpty()) {
        m_console_output += QStringLiteral("\n\n> %1\n! %2")
            .arg(singleLineLimited(clean_command, 120), batch_error);
        Q_EMIT consoleChanged();
        return;
    }

    auto parsed_commands = std::make_shared<QVector<ParsedConsoleCommand>>();
    parsed_commands->reserve(command_texts.size());
    for (const QString& command : command_texts) {
        QString method = command.trimmed();
        QString params_json;
        const int first_space = method.indexOf(QRegularExpression(QStringLiteral("\\s")));
        if (first_space > 0) {
            const QString maybe_params = method.mid(first_space + 1).trimmed();
            if (maybe_params.startsWith(QLatin1Char('['))) {
                params_json = maybe_params;
                method = method.left(first_space).trimmed();
            }
        }

        ParsedConsoleCommand parsed;
        QString parse_error;
        if (!parseConsoleCommandForRpc(method, params_json, &parsed, &parse_error)) {
            m_console_output += QStringLiteral("\n\n> %1\n! %2")
                .arg(singleLineLimited(command, 120), parse_error);
            Q_EMIT consoleChanged();
            return;
        }
        parsed_commands->push_back(parsed);
    }

    if (parsed_commands->isEmpty()) {
        m_console_output += QStringLiteral("\n\n> \n! Enter an RPC command.");
        Q_EMIT consoleChanged();
        return;
    }

    const QString wallet = wallet_name.trimmed();
    const bool wallet_scoped = !wallet.isEmpty() && wallet != QLatin1String("__node__");
    const QString target_label = wallet_scoped ? walletDisplayName(wallet) : QStringLiteral("Node");

    if (parsed_commands->size() > 1) {
        if (m_console_output.startsWith(QStringLiteral("Welcome to the Defcoin Core Nu RPC console."))) {
            m_console_output.clear();
        }
        m_console_output += QStringLiteral("%1%2  > [pasted batch]\n%3  < Running %4 RPC commands against %5.")
            .arg(m_console_output.isEmpty() ? QString() : QStringLiteral("\n\n"),
                 QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss")),
                 QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss")),
                 QString::number(parsed_commands->size()),
                 target_label);
        Q_EMIT consoleChanged();
    }

    auto run_next = std::make_shared<std::function<void(int)>>();
    *run_next = [this, parsed_commands, wallet_scoped, wallet, target_label, run_next](int index) {
        if (index >= parsed_commands->size()) return;
        const ParsedConsoleCommand command = parsed_commands->at(index);
        const auto callback = [this, command, run_next, index](const QJsonValue& result, const QString& error) {
            QString rendered;
            const QString icon = error.isEmpty() ? QStringLiteral("<") : QStringLiteral("!");
            if (!error.isEmpty()) {
                rendered = QStringLiteral("%1 failed:\n%2").arg(command.method, error);
            } else {
                QJsonDocument out_doc;
                if (result.isObject()) {
                    out_doc = QJsonDocument(result.toObject());
                } else if (result.isArray()) {
                    out_doc = QJsonDocument(result.toArray());
                }
                if (!out_doc.isNull()) {
                    rendered = QString::fromUtf8(out_doc.toJson(QJsonDocument::Indented));
                } else if (result.isString()) {
                    rendered = result.toString();
                } else if (result.isBool()) {
                    rendered = result.toBool() ? QStringLiteral("true") : QStringLiteral("false");
                } else if (result.isDouble()) {
                    rendered = QString::number(result.toDouble(), 'f', 8);
                } else if (result.isNull()) {
                    rendered = QStringLiteral("null");
                } else {
                    rendered = QStringLiteral("(empty result)");
                }
            }
            if (m_console_output.startsWith(QStringLiteral("Welcome to the Defcoin Core Nu RPC console."))) {
                m_console_output.clear();
            }
            const QString now = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));
            m_console_output += QStringLiteral("%1%2  > %3\n%4  %5 %6")
                .arg(m_console_output.isEmpty() ? QString() : QStringLiteral("\n\n"),
                     now,
                     command.prompt,
                     now,
                     icon,
                     rendered.trimmed());
            constexpr int max_console_chars = 120000;
            if (m_console_output.size() > max_console_chars) {
                m_console_output = m_console_output.right(max_console_chars);
            }
            Q_EMIT consoleChanged();
            (*run_next)(index + 1);
        };

        if (wallet_scoped) {
            rpcCallForWallet(command.method, command.params, wallet, callback);
        } else {
            rpcCall(command.method, command.params, false, callback);
        }
    };
    (*run_next)(0);
}

void NuRpcService::clearConsoleOutput()
{
    m_console_output = QStringLiteral("Welcome to the Defcoin Core Nu RPC console.\nUse the command line below for standard Core commands, for example getblockchaininfo or listtransactions \"*\" 5.\nJSON parameter arrays are still accepted after the method name when needed.\n\nWARNING: Do not paste commands from strangers into this console.");
    Q_EMIT consoleChanged();
}

void NuRpcService::generatePaperWallet(bool import_public_address, const QString& label)
{
    if (!m_rpc_connected) {
        Q_EMIT userMessage(QStringLiteral("Paper wallet not generated"),
                           QStringLiteral("Connect to the local backend before generating a paper wallet."));
        return;
    }

    QByteArray secret(32, char(0));
    do {
        for (int i = 0; i < secret.size(); ++i) {
            secret[i] = char(QRandomGenerator::system()->generate() & 0xff);
        }
    } while (!isValidSecp256k1Secret(secret));

    QByteArray wif_payload;
    wif_payload.append(char(DEFCOIN_CURRENT_WIF_PREFIX));
    wif_payload.append(secret);
    wif_payload.append(char(1)); // compressed key marker
    const QString wif = encodeBase58Check(wif_payload);
    secret.fill(0);
    wif_payload.fill(0);

    m_paper_wallet_address.clear();
    m_paper_wallet_wif = wif;
    m_paper_wallet_status = QStringLiteral("Generated private key; deriving Defcoin address through Core descriptor code.");
    Q_EMIT walletChanged();

    const QString descriptor = QStringLiteral("pkh(%1)").arg(wif);
    rpcCall(QStringLiteral("getdescriptorinfo"), {descriptor}, false, [this, wif, import_public_address, label](const QJsonValue& descriptor_result, const QString& descriptor_error) {
        if (!descriptor_error.isEmpty()) {
            m_paper_wallet_status = QStringLiteral("Paper wallet address derivation failed: %1").arg(descriptor_error);
            Q_EMIT walletChanged();
            Q_EMIT userMessage(QStringLiteral("Paper wallet address not derived"), m_paper_wallet_status);
            return;
        }
        const QString checked_descriptor = descriptor_result.toObject().value(QStringLiteral("descriptor")).toString();
        if (checked_descriptor.isEmpty()) {
            m_paper_wallet_status = QStringLiteral("Paper wallet address derivation failed: Core returned no descriptor.");
            Q_EMIT walletChanged();
            Q_EMIT userMessage(QStringLiteral("Paper wallet address not derived"), m_paper_wallet_status);
            return;
        }
        rpcCall(QStringLiteral("deriveaddresses"), {checked_descriptor}, false, [this, wif, import_public_address, label](const QJsonValue& result, const QString& error) {
            if (!error.isEmpty() || !result.isArray() || result.toArray().isEmpty()) {
                m_paper_wallet_status = QStringLiteral("Paper wallet address derivation failed: %1")
                    .arg(error.isEmpty() ? QStringLiteral("Core returned no address.") : error);
                Q_EMIT walletChanged();
                Q_EMIT userMessage(QStringLiteral("Paper wallet address not derived"), m_paper_wallet_status);
                return;
            }
            const QString address = result.toArray().at(0).toString().trimmed();
            if (!isLikelyBase58AddressText(address)) {
                m_paper_wallet_status = QStringLiteral("Paper wallet address derivation failed: Core returned an unexpected address.");
                Q_EMIT walletChanged();
                Q_EMIT userMessage(QStringLiteral("Paper wallet address not derived"), m_paper_wallet_status);
                return;
            }
            m_paper_wallet_wif = wif;
            m_paper_wallet_address = address;
            m_paper_wallet_status = QStringLiteral("Paper wallet generated. Print or record the private key offline; Nu has not imported the private key.");
            Q_EMIT walletChanged();
            if (import_public_address) {
                importWatchOnlyAddress(address,
                                       label.trimmed().isEmpty() ? QStringLiteral("Paper wallet public address") : label,
                                       false,
                                       -1);
            }
        });
    });
}

void NuRpcService::importWatchOnlyAddress(const QString& address, const QString& label, bool rescan, int start_height)
{
    const QString clean_address = address.trimmed();
    if (!m_wallet_selected) {
        Q_EMIT userMessage(QStringLiteral("Watch-only address not imported"),
                           QStringLiteral("Select or load a wallet before importing a watch-only address."));
        return;
    }
    if (!isLikelyBase58AddressText(clean_address)) {
        Q_EMIT userMessage(QStringLiteral("Watch-only address not imported"),
                           QStringLiteral("Enter a valid Defcoin Base58 address."));
        return;
    }
    const QString clean_label = label.trimmed().isEmpty() ? QStringLiteral("Watch-only") : label.trimmed();
    rpcCall(QStringLiteral("importaddress"), {clean_address, clean_label, false}, true, [this, clean_address, clean_label, rescan, start_height](const QJsonValue&, const QString& import_error) {
        if (!import_error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Watch-only address not imported"), import_error);
            return;
        }
        setAddressLabel(clean_address, clean_label);
        refreshWalletStats();
        if (!rescan) {
            Q_EMIT userMessage(QStringLiteral("Watch-only address imported"),
                               QStringLiteral("The public address was imported without a blockchain rescan. It cannot spend funds."));
            return;
        }
        const int bounded_start = start_height >= 0 ? start_height : 0;
        rpcCall(QStringLiteral("rescanblockchain"), {bounded_start}, true, [this](const QJsonValue&, const QString& rescan_error) {
            if (!rescan_error.isEmpty()) {
                Q_EMIT userMessage(QStringLiteral("Watch-only address imported"), QStringLiteral("Import succeeded, but rescan failed: %1").arg(rescan_error));
                return;
            }
            refreshWalletStats();
            Q_EMIT userMessage(QStringLiteral("Watch-only address imported"),
                               QStringLiteral("The public address was imported and the wallet rescan was requested. It cannot spend funds."));
        });
    });
}

bool NuRpcService::quickCloneMissingChainThresholdReached() const
{
    if (m_header_height <= 0 || m_block_height < 0 || m_block_height >= m_header_height) return false;
    const int missing = m_header_height - m_block_height;
    return double(missing) / double(m_header_height) > 0.05;
}

bool NuRpcService::hasQuickCloneLanCandidate() const
{
    auto is_candidate = [this](const QString& host) {
        QHostAddress address;
        return address.setAddress(host) && isPrivateOrLocalFastSyncAddress(address);
    };
    for (const QString& host : m_lan_quick_clone_candidate_hosts) {
        if (is_candidate(host)) return true;
    }
    for (const QString& host : m_quick_clone_snapshot_candidate_hosts) {
        if (is_candidate(host)) return true;
    }
    return false;
}

QString NuRpcService::quickClonePromptText() const
{
    const int missing = std::max(0, m_header_height - m_block_height);
    QString estimate = QStringLiteral("Unknown");
    if (m_sync_last_sample_ms > 0 && m_sync_last_block_height >= 0 && m_block_height > m_sync_last_block_height) {
        const double seconds = double(QDateTime::currentMSecsSinceEpoch() - m_sync_last_sample_ms) / 1000.0;
        const double blocks_per_second = seconds > 0.0 ? double(m_block_height - m_sync_last_block_height) / seconds : 0.0;
        if (blocks_per_second > 0.0) {
            estimate = formatSyncEtaSeconds(qint64(std::ceil(missing / blocks_per_second)));
        }
    }
    return QStringLiteral(
        "One or more Defcoin Core Nu nodes were detected on this LAN while this wallet is more than 5% behind.\n\n"
        "Quick Clone is for machines you own and trust on the same local network. It copies public blockchain data only; it never copies wallets, private keys, passphrases, configuration, peers, bans, address books, or RPC cookies.\n\n"
        "Normal sync remains the safest default. Quick Clone may be faster, but it trusts the LAN source's already-validated chain snapshot and should only be used with your own nodes. A partial clone is not usable chain state; Nu must finish the staged copy, verify the source manifest and streaming checksums, briefly stop the receiver backend for the final folder swap, then restart and confirm the expected best block hash.\n\n"
        "Current progress: block %1 of %2 headers (%3 blocks missing). Normal sync estimate: %4.\n\n"
        "Yes enables Quick Clone discovery and trusted-LAN copy scaffolding. No keeps normal sync and will not ask again during this missing-chain cycle.")
        .arg(m_block_height)
        .arg(m_header_height)
        .arg(missing)
        .arg(estimate);
}

void NuRpcService::evaluateQuickClonePrompt()
{
    if (m_debug_disable_quick_clone) return;
    const bool missing_cycle = quickCloneMissingChainThresholdReached();
    if (!missing_cycle) {
        m_quick_clone_missing_cycle_active = false;
        m_quick_clone_prompt_declined_for_cycle = false;
        m_quick_clone_prompt_shown_for_cycle = false;
        return;
    }
    if (!m_quick_clone_missing_cycle_active) {
        m_quick_clone_missing_cycle_active = true;
        m_quick_clone_prompt_declined_for_cycle = false;
        m_quick_clone_prompt_shown_for_cycle = false;
    }
    if (!m_lan_node_discovery_enabled ||
        m_lan_quick_clone_enabled ||
        m_quick_clone_prompt_declined_for_cycle ||
        m_quick_clone_prompt_shown_for_cycle ||
        !hasQuickCloneLanCandidate()) {
        return;
    }

    m_quick_clone_prompt_shown_for_cycle = true;
    Q_EMIT quickClonePromptRequested(QStringLiteral("Quick Clone available"), quickClonePromptText());
}

void NuRpcService::syncUsingQuickCloneNow()
{
    if (m_debug_disable_quick_clone) {
        m_lan_quick_clone_status = QStringLiteral("Quick Clone disabled by debug launch switch.");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }
    setLanQuickCloneEnabled(true);
    ensureLanFastSyncSocket();
    sendLanDiscoveryAnnouncement();
    m_lan_quick_clone_status = QStringLiteral("Quick Clone requested; waiting for a trusted LAN source.");
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
}

void NuRpcService::acceptQuickClonePrompt()
{
    m_quick_clone_prompt_declined_for_cycle = false;
    setLanQuickCloneEnabled(true);
}

void NuRpcService::declineQuickClonePrompt()
{
    if (quickCloneMissingChainThresholdReached()) {
        m_quick_clone_prompt_declined_for_cycle = true;
    }
    Q_EMIT stateChanged();
}

void NuRpcService::validateExistingBlockchain()
{
    if (m_quick_clone_validation_running) {
        Q_EMIT userMessage(QStringLiteral("Validation already running"), m_quick_clone_validation_status);
        return;
    }
    if (!m_rpc_connected) {
        Q_EMIT userMessage(QStringLiteral("Validation not started"), QStringLiteral("Connect to the local backend before running blockchain validation."));
        return;
    }

    m_quick_clone_validation_running = true;
    m_quick_clone_validation_status = QStringLiteral("Running Core verifychain over all available blocks. Wallet operation may feel slower until it finishes.");
    rebuildNodeMetrics();
    Q_EMIT stateChanged();

    rpcCall(QStringLiteral("verifychain"), {4, 0}, false, [this](const QJsonValue& result, const QString& error) {
        m_quick_clone_validation_running = false;
        if (!error.isEmpty()) {
            m_quick_clone_validation_status = QStringLiteral("Blockchain validation failed or is unavailable: %1").arg(error);
            Q_EMIT userMessage(QStringLiteral("Blockchain validation failed"), m_quick_clone_validation_status);
        } else if (result.toBool(false)) {
            m_quick_clone_validation_status = QStringLiteral("Blockchain validation complete. Core verifychain reported success.");
            Q_EMIT userMessage(QStringLiteral("Blockchain validation complete"), m_quick_clone_validation_status);
        } else {
            m_quick_clone_validation_status = QStringLiteral("Blockchain validation complete. Core verifychain reported a problem.");
            Q_EMIT userMessage(QStringLiteral("Blockchain validation problem"), m_quick_clone_validation_status);
        }
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
    });
}

void NuRpcService::rebuildNodeMetrics()
{
    const QString sync_value = QStringLiteral("%1% | %2 | %3")
        .arg(m_sync_progress_percent)
        .arg(m_sync_state)
        .arg(lanFastSyncMethodSummary());
    m_node_metrics = {
        metricRow(QStringLiteral("Syncing"), sync_value,
                  QStringLiteral("Blockchain sync progress, current sync state, and only the transport methods that have actually carried sync traffic during this Nu session.")),
        metricRow(QStringLiteral("Traffic"), m_metric_traffic,
                  QStringLiteral("Total backend P2P network traffic reported by getnettotals, independent of the sync-only speed rows.")),
        metricRow(QStringLiteral("Sync overview"), syncTransportSpeedSummary(),
                  QStringLiteral("Combined session-average sync throughput. UDP timing includes failed attempts and cooldown/retry time so failed probes reduce the average instead of being ignored.")),
        metricRow(QStringLiteral("Core Sync (TCP)"), coreSyncPathSummary(),
                  QStringLiteral("Normal Core P2P sync and validation path. Chain advances here are active-chain height increases not attributed to UDP fast sync; they can include validation of locally available block data.")),
        metricRow(QStringLiteral("Fast Sync (UDP)"), fastSyncUdpSummary(),
                  QStringLiteral("UDP Fast Sync totals for this Nu session. Average speed includes failed UDP attempts, checksum failures, timeouts, and retries so the protocol comparison is not inflated by ignoring failures.")),
        metricRow(QStringLiteral("Fast Sync (UDP) decision"), syncTransportDecisionSummary(),
                  QStringLiteral("Adaptive TCP/UDP block-transfer preference. Nu uses recent accepted-block timing, reliability, and occasional probes so a slower protocol can recover if conditions change.")),
        metricRow(QStringLiteral("Fast Sync (UDP) probe"), syncTransportProbeSummary(),
                  QStringLiteral("Fast Sync service-bit candidates, UDP-verified peers, and current datagram/chunk target. Nu probes a peer once per verification window, then reuses verified UDP peers without probing every block.")),
        metricRow(QStringLiteral("Quick Clone (LAN UDP)"), m_lan_quick_clone_status,
                  QStringLiteral("Trusted-LAN public-chain copy status. Quick Clone/DCOL never copies wallets, keys, settings, peers, bans, or RPC cookies; snapshot replacement is gated by manifest verification.")),
        metricRow(QStringLiteral("Quick Clone (LAN UDP) validation"), m_quick_clone_validation_status,
                  QStringLiteral("Core verifychain status for validating existing public blockchain data after a Quick Clone or on demand.")),
        metricRow(QStringLiteral("Network active"), m_metric_network_active,
                  QStringLiteral("Whether the backend currently allows peer network activity.")),
        metricRow(QStringLiteral("Connections"), QStringLiteral("Total: %1 | In: %2 | Out: %3")
                  .arg(m_metric_connections, m_metric_inbound, m_metric_outbound),
                  QStringLiteral("Peer connection count using Litecoin/Core convention. In means a remote peer opened the connection into this node; Out means this node opened the connection to a peer.")),
        metricRow(QStringLiteral("Version"), m_metric_version,
                  QStringLiteral("Local backend user agent string advertised to peers.")),
        metricRow(QStringLiteral("Blocks"), m_metric_blocks,
                  QStringLiteral("Current fully validated active-chain block height.")),
        metricRow(QStringLiteral("Headers"), m_metric_headers,
                  QStringLiteral("Highest header height known by the backend. Headers can be ahead of fully downloaded blocks during sync.")),
        metricRow(QStringLiteral("Verification"), m_metric_verification,
                  QStringLiteral("Backend verification progress estimate across the active chain.")),
        metricRow(QStringLiteral("Difficulty"), m_metric_difficulty,
                  QStringLiteral("Current active-chain proof-of-work difficulty. It can change at retarget boundaries.")),
        metricRow(QStringLiteral("Network hashrate (120 blocks)"), m_metric_network_hashrate,
                  QStringLiteral("Estimated recent network hashrate from getnetworkhashps over the last 120 blocks.")),
        metricRow(QStringLiteral("Average block time (120 blocks)"), m_metric_average_block_time,
                  QStringLiteral("Recent active-chain block spacing sampled from RPC block headers, with the Explorer index used as fallback.")),
        metricRow(QStringLiteral("Chain tips"), m_metric_chain_tips,
                  QStringLiteral("Summary of active and known stale/header-only chain tips reported by the backend.")),
        metricRow(QStringLiteral("Top sent P2P messages"), m_metric_peer_messages_sent,
                  QStringLiteral("Largest P2P message categories sent to peers, aggregated from getpeerinfo byte counters.")),
        metricRow(QStringLiteral("Top rec'd P2P messages"), m_metric_peer_messages_received,
                  QStringLiteral("Largest P2P message categories received from peers, aggregated from getpeerinfo byte counters."))
    };
}

void NuRpcService::setOnlyDefcoinUserAgents(bool enabled)
{
    if (m_only_defcoin_user_agents == enabled) return;
    m_only_defcoin_user_agents = enabled;
    QSettings(QStringLiteral("Defcoin"), QStringLiteral("Defcoin-Qt")).setValue(QStringLiteral("OnlyDefcoinUserAgents"), enabled);
    Q_EMIT settingsChanged();
    QTimer::singleShot(0, this, &NuRpcService::refreshNode);
    rpcCall(QStringLiteral("setonlydefcoinuseragents"), {enabled}, false, [this](const QJsonValue&, const QString&) {
        refreshNode();
    });
}

void NuRpcService::setOnlyDefcoinMagicBytes(bool enabled)
{
    if (m_only_defcoin_magic_bytes == enabled) return;
    m_only_defcoin_magic_bytes = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("OnlyDefcoinMagicBytes"), enabled);
    Q_EMIT settingsChanged();
    if (!m_rpc_connected) return;
    rpcCall(QStringLiteral("setacceptlegacymagic"), {!enabled}, false, [this, enabled](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Network setting not applied"),
                               QStringLiteral("The setting was saved, but the running backend did not accept the live magic-byte update: %1").arg(error));
            return;
        }
        m_only_defcoin_magic_bytes = enabled;
        Q_EMIT settingsChanged();
    });
}

void NuRpcService::setSwitchToDefcoinOnlyMagicStartingJuly2026(bool enabled)
{
    if (m_switch_to_defcoin_only_magic_starting_july_2026 == enabled) return;
    m_switch_to_defcoin_only_magic_starting_july_2026 = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("SwitchToDefcoinOnlyMagicStarting20260701"), enabled);
    if (enabled && QDate::currentDate() >= QDate(2026, 7, 1) && !m_only_defcoin_magic_bytes) {
        m_only_defcoin_magic_bytes = true;
        settings.setValue(QStringLiteral("OnlyDefcoinMagicBytes"), true);
        if (!m_rpc_connected) {
            Q_EMIT settingsChanged();
            return;
        }
        rpcCall(QStringLiteral("setacceptlegacymagic"), {false}, false, [this](const QJsonValue&, const QString& error) {
            if (!error.isEmpty()) {
                Q_EMIT userMessage(QStringLiteral("Network setting not applied"),
                                   QStringLiteral("The scheduled setting was saved, but the running backend did not accept the live magic-byte update: %1").arg(error));
            }
        });
    }
    Q_EMIT settingsChanged();
}

void NuRpcService::setDisallowLanNodeDiscovery(bool enabled)
{
    setLanNodeDiscoveryEnabled(!enabled);
}

void NuRpcService::setLanNodeDiscoveryEnabled(bool enabled)
{
    if (m_lan_node_discovery_enabled == enabled) return;
    m_lan_node_discovery_enabled = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("LanNodeDiscoveryEnabled"), enabled);
    if (!enabled) {
        m_peer_lan_name_by_host.clear();
        m_peer_lan_info_by_host.clear();
        m_peer_lan_lookup_pending.clear();
        m_peer_lan_lookup_attempted.clear();
        m_peer_lan_lookup_last_attempt_ms.clear();
    } else {
        m_peer_lan_lookup_attempted.clear();
        m_peer_lan_lookup_last_attempt_ms.clear();
        ensureLanFastSyncSocket();
        evaluateQuickClonePrompt();
    }
    Q_EMIT settingsChanged();
    if (!m_rpc_connected) return;
    rpcCall(QStringLiteral("setallowlannodediscovery"), {enabled}, false, [this, enabled](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Network setting not applied"),
                               QStringLiteral("The setting was saved, but the running backend did not accept the live LAN discovery update: %1").arg(error));
            return;
        }
        m_lan_node_discovery_enabled = enabled;
        Q_EMIT settingsChanged();
        refreshNode();
    });
}

void NuRpcService::setLanFastSyncEnabled(bool enabled)
{
    if (m_debug_disable_fast_sync && enabled) {
        m_lan_fast_sync_enabled = false;
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync disabled by debug launch switch.");
        rebuildNodeMetrics();
        Q_EMIT settingsChanged();
        Q_EMIT stateChanged();
        return;
    }
    if (m_lan_fast_sync_enabled == enabled) return;
    m_lan_fast_sync_enabled = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("LanFastSyncEnabled"), enabled);
    if (!enabled) {
        stopLanFastSyncSocket();
        m_lan_fast_sync_status = QStringLiteral("UDP fast sync off; normal TCP sync remains active.");
    } else {
        ensureLanFastSyncSocket();
    }
    rebuildNodeMetrics();
    Q_EMIT settingsChanged();
    Q_EMIT stateChanged();
}

void NuRpcService::setLanQuickCloneEnabled(bool enabled)
{
    if (m_debug_disable_quick_clone && enabled) {
        m_lan_quick_clone_enabled = false;
        m_lan_quick_clone_status = QStringLiteral("Quick Clone disabled by debug launch switch.");
        rebuildNodeMetrics();
        Q_EMIT settingsChanged();
        Q_EMIT stateChanged();
        return;
    }
    if (m_lan_quick_clone_enabled == enabled) return;
    m_lan_quick_clone_enabled = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("LanQuickCloneEnabled"), false);

    if (enabled) {
        m_quick_clone_auto_validate_ran_this_session = false;
        if (!m_lan_fast_sync_enabled && !m_debug_disable_fast_sync) setLanFastSyncEnabled(true);
        if (!m_lan_node_discovery_enabled) setLanNodeDiscoveryEnabled(true);
        ensureLanFastSyncSocket();
        m_lan_quick_clone_status = QStringLiteral("Quick Clone requested. Nu will use trusted LAN sources only; wallet data is never copied.");
        appendLaunchDiagnostic(QStringLiteral("Quick Clone requested for this session. Wallet data is not copied; trusted-LAN public-chain copy remains guarded by Core block acceptance."));
    } else {
        resetLanFastSyncTransfer(QStringLiteral("UDP fast sync idle."));
        m_lan_quick_clone_status = QStringLiteral("Quick Clone off.");
        if (m_lan_quick_clone_paused_network && m_rpc_connected) {
            m_lan_quick_clone_paused_network = false;
            setNetworkActive(true);
        }
        appendLaunchDiagnostic(QStringLiteral("Quick Clone disabled."));
    }

    rebuildNodeMetrics();
    Q_EMIT settingsChanged();
    Q_EMIT stateChanged();
}

void NuRpcService::setQuickCloneAutoValidateAfter(bool enabled)
{
    if (m_quick_clone_auto_validate_after == enabled) return;
    m_quick_clone_auto_validate_after = enabled;
    QSettings().setValue(QStringLiteral("QuickCloneAutoValidateAfter"), enabled);
    Q_EMIT settingsChanged();
    Q_EMIT stateChanged();
}

void NuRpcService::setAdvancedToolsVisible(bool enabled)
{
    if (m_advanced_tools_visible == enabled) return;
    m_advanced_tools_visible = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("AdvancedToolsVisible"), enabled);
    Q_EMIT settingsChanged();
}

void NuRpcService::setExplorerTop100FocusedIndexing(bool enabled)
{
    if (m_explorer_top100_focused_indexing == enabled) return;
    m_explorer_top100_focused_indexing = enabled;
    QSettings().setValue(QStringLiteral("ExplorerTop100FocusedIndexing"), enabled);
    const bool priority_changed = trySetProcessNiceForIndexing(enabled);
    if (m_explorer_top100_scanning || m_explorer_indexing) {
        const QString priority_note = priority_changed
            ? QStringLiteral(" Process priority adjusted.")
            : (enabled ? QStringLiteral(" Process priority change was not permitted by the OS.") : QString());
        const QString mode_note = enabled
            ? QStringLiteral("High intensity indexing enabled. Nu will use larger SQLite batches, bigger cache settings, and fewer UI refreshes.")
            : QStringLiteral("High intensity indexing disabled. Nu will return to cooperative batch sizing and lighter UI cadence.");
        if (m_explorer_top100_scanning) {
            m_explorer_top100_status = mode_note + priority_note;
        }
        if (m_explorer_indexing) {
            m_explorer_index_status = mode_note + priority_note;
        }
        Q_EMIT explorerChanged();
    }
    Q_EMIT settingsChanged();
}

void NuRpcService::setUpnpConnectionsEnabled(bool enabled)
{
    if (m_upnp_connections_enabled == enabled) return;
    m_upnp_connections_enabled = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("UpnpConnectionsEnabled"), enabled);
    Q_EMIT settingsChanged();
    if (!m_rpc_connected) return;
    rpcCall(QStringLiteral("setupnpportmapping"), {enabled}, false, [this, enabled](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Network setting not applied"),
                               QStringLiteral("The setting was saved, but the running backend did not accept the live UPnP update: %1").arg(error));
            return;
        }
        m_upnp_connections_enabled = enabled;
        Q_EMIT settingsChanged();
    });
}

void NuRpcService::acknowledgeLanNodeDiscoveryNotice()
{
    if (m_lan_node_discovery_notice_acknowledged) return;
    m_lan_node_discovery_notice_acknowledged = true;
    QSettings().setValue(QStringLiteral("LanNodeDiscoveryNoticeAcknowledged"), true);
    Q_EMIT settingsChanged();
}

void NuRpcService::setAutomaticUpdateChecksEnabled(bool enabled)
{
    if (m_automatic_update_checks_enabled == enabled) return;
    m_automatic_update_checks_enabled = enabled;
    QSettings().setValue(QStringLiteral("AutomaticUpdateChecksEnabled"), enabled);
    Q_EMIT settingsChanged();
}

void NuRpcService::setTableCopyDelimiterStyle(const QString& style)
{
    const QString normalized = style.toLower();
    const QString value = QStringList{QStringLiteral("csv"), QStringLiteral("tsv"), QStringLiteral("pipe"), QStringLiteral("semicolon"), QStringLiteral("custom")}.contains(normalized)
        ? normalized
        : QStringLiteral("tsv");
    if (m_table_copy_delimiter_style == value) return;
    m_table_copy_delimiter_style = value;
    QSettings().setValue(QStringLiteral("TableCopyDelimiterStyle"), value);
    Q_EMIT settingsChanged();
}

void NuRpcService::setTableCopyCustomDelimiter(const QString& delimiter)
{
    const QString value = delimiter.isEmpty() ? QStringLiteral("|") : delimiter.left(15);
    if (m_table_copy_custom_delimiter == value) return;
    m_table_copy_custom_delimiter = value;
    QSettings().setValue(QStringLiteral("TableCopyCustomDelimiter"), value);
    Q_EMIT settingsChanged();
}

void NuRpcService::setLogVerbosity(int verbosity)
{
    const int value = std::clamp(verbosity, 0, 3);
    if (m_log_verbosity == value) return;
    m_log_verbosity = value;
    QSettings().setValue(QStringLiteral("LogVerbosity"), value);
    Q_EMIT settingsChanged();
}

void NuRpcService::setLogSearchPattern(const QString& pattern)
{
    const QString value = pattern.left(160);
    if (m_log_search_pattern == value) return;
    m_log_search_pattern = value;
    QSettings settings;
    settings.remove(QStringLiteral("LogSearchPattern"));
    if (!value.trimmed().isEmpty()) {
        m_log_last_search_pattern = value;
        settings.setValue(QStringLiteral("LogLastSearchPattern"), value);
    }
    Q_EMIT settingsChanged();
}

void NuRpcService::setLogRemovePattern(const QString& pattern)
{
    const QString value = pattern.left(160);
    if (m_log_remove_pattern == value) return;
    m_log_remove_pattern = value;
    QSettings().remove(QStringLiteral("LogRemovePattern"));
    Q_EMIT settingsChanged();
}

void NuRpcService::setForensicsAcceptBip141AsRegular(bool enabled)
{
    if (m_forensics_accept_bip141_as_regular == enabled) return;
    m_forensics_accept_bip141_as_regular = enabled;
    QSettings().setValue(QStringLiteral("ForensicsAcceptBip141AsRegular"), enabled);
    Q_EMIT settingsChanged();
}

void NuRpcService::setBackgroundCloseEnabled(bool enabled)
{
    if (m_background_close_enabled == enabled) return;
    m_background_close_enabled = enabled;
    QSettings().setValue(QStringLiteral("KeepRunningWhenClosedEnabled"), enabled);
    Q_EMIT settingsChanged();
}

QString NuRpcService::currentNuVersion() const
{
    return QStringLiteral(DEFCOIN_NU_VERSION);
}

QString NuRpcService::nuResourceRoot() const
{
    const QString app_dir = QCoreApplication::applicationDirPath();
#if defined(Q_OS_MACOS)
    return QDir(app_dir).filePath(QStringLiteral("../Resources/nu"));
#else
    return QDir(app_dir).filePath(QStringLiteral("nu"));
#endif
}

void NuRpcService::loadDefcoinTimeline()
{
    if (m_defcoin_timeline_loaded) return;

    m_defcoin_timeline_rows.clear();
    m_defcoin_timeline_summary.clear();
    m_defcoin_timeline_criteria = QStringLiteral("Timeline not loaded yet.");
    m_defcoin_timeline_status = QStringLiteral("Loading /r/Defcoin timeline.");

    const QString relative_path = QStringLiteral("assets/data/defcoin_reddit_timeline.json");
    QStringList candidates;
    candidates << QDir(nuResourceRoot()).filePath(relative_path)
               << QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("nu/%1").arg(relative_path))
               << QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("../Resources/nu/%1").arg(relative_path))
               << QStringLiteral(":/nu/assets/data/defcoin_reddit_timeline.json");

    QFile file;
    QString opened_path;
    for (const QString& candidate : candidates) {
        file.setFileName(candidate);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            opened_path = candidate;
            break;
        }
    }
    if (!file.isOpen()) {
        m_defcoin_timeline_status = QStringLiteral("Could not load bundled /r/Defcoin timeline data.");
        m_defcoin_timeline_loaded = true;
        return;
    }

    QJsonParseError parse_error;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parse_error);
    if (parse_error.error != QJsonParseError::NoError || !doc.isObject()) {
        m_defcoin_timeline_status = QStringLiteral("/r/Defcoin timeline JSON parse error: %1").arg(parse_error.errorString());
        m_defcoin_timeline_loaded = true;
        return;
    }

    const QJsonObject object = doc.object();
    const int schema_version = object.value(QStringLiteral("schemaVersion")).toInt();
    if (schema_version != DEFCOIN_REDDIT_TIMELINE_SCHEMA_VERSION) {
        m_defcoin_timeline_status = QStringLiteral("/r/Defcoin timeline schema %1 is not supported by this build.")
            .arg(schema_version);
        m_defcoin_timeline_loaded = true;
        return;
    }

    const QJsonObject summary_object = object.value(QStringLiteral("summary")).toObject();
    m_defcoin_timeline_summary = summary_object.toVariantMap();
    m_defcoin_timeline_summary.insert(QStringLiteral("dataPath"), opened_path);
    const QJsonArray rows = object.value(QStringLiteral("rows")).toArray();
    for (const QJsonValue& value : rows) {
        if (value.isObject()) m_defcoin_timeline_rows.push_back(value.toObject().toVariantMap());
    }

    QString criteria = summary_object.value(QStringLiteral("criteriaText")).toString();
    if (criteria.isEmpty()) {
        const QJsonObject criteria_object = object.value(QStringLiteral("criteria")).toObject();
        QStringList parts;
        for (const QJsonValue& value : criteria_object.value(QStringLiteral("included")).toArray())
            parts.push_back(value.toString());
        for (const QJsonValue& value : criteria_object.value(QStringLiteral("removed")).toArray())
            parts.push_back(value.toString());
        criteria = parts.join(QStringLiteral(" "));
    }
    m_defcoin_timeline_criteria = criteria.isEmpty()
        ? QStringLiteral("Timeline criteria are bundled with the generated data file.")
        : criteria;
    m_defcoin_timeline_status = QStringLiteral("Loaded /r/Defcoin timeline: %1 included events, %2 subreddit rows, %3 DEF CON anchors, %4 removed as noise or duplicates.")
        .arg(QString::number(m_defcoin_timeline_rows.size()),
             QString::number(m_defcoin_timeline_summary.value(QStringLiteral("includedSubredditRows")).toInt()),
             QString::number(m_defcoin_timeline_summary.value(QStringLiteral("includedHistoryRows")).toInt()),
             QString::number(m_defcoin_timeline_summary.value(QStringLiteral("removedRows")).toInt()));
    m_defcoin_timeline_loaded = true;
}

void NuRpcService::refreshDefcoinTimeline()
{
    loadDefcoinTimeline();
    Q_EMIT explorerChanged();
}

void NuRpcService::refreshNetworkPulseHistory(int window_blocks)
{
    QString error;
    const QVariantMap analysis = networkPulseHistoryFromDb(window_blocks, &error);
    if (!error.isEmpty()) {
        m_network_pulse_summary = QVariantMap{{QStringLiteral("windowBlocks"), qBound(10, window_blocks, 20160)}};
        m_network_pulse_history_rows.clear();
        m_network_pulse_status = error;
    } else {
        m_network_pulse_summary = analysis.value(QStringLiteral("summary")).toMap();
        m_network_pulse_history_rows = analysis.value(QStringLiteral("rows")).toList();
        m_network_pulse_status = analysis.value(QStringLiteral("status")).toString();
        if (m_network_pulse_status.isEmpty())
            m_network_pulse_status = QStringLiteral("Network Pulse history loaded.");
        const QString average_block_time = m_network_pulse_summary.value(QStringLiteral("currentAvgBlockTime")).toString();
        if (!average_block_time.isEmpty() && average_block_time != QLatin1String("-")) {
            m_metric_average_block_time = average_block_time;
            rebuildNodeMetrics();
            Q_EMIT stateChanged();
        }
    }
    Q_EMIT explorerChanged();
}

QStringList NuRpcService::loadBip39Words() const
{
    if (!m_bip39_words.isEmpty()) return m_bip39_words;

    QFile file(QDir(nuResourceRoot()).filePath(QStringLiteral("assets/bip39/english.txt")));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QFile source_fallback(QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("../assets/bip39/english.txt")));
        if (!source_fallback.open(QIODevice::ReadOnly | QIODevice::Text)) return {};
        QTextStream stream(&source_fallback);
        while (!stream.atEnd()) {
            const QString word = stream.readLine().trimmed();
            if (!word.isEmpty()) m_bip39_words.push_back(word);
        }
    } else {
        QTextStream stream(&file);
        while (!stream.atEnd()) {
            const QString word = stream.readLine().trimmed();
            if (!word.isEmpty()) m_bip39_words.push_back(word);
        }
    }

    m_bip39_word_index.clear();
    for (int i = 0; i < m_bip39_words.size(); ++i) {
        m_bip39_word_index.insert(m_bip39_words.at(i), i);
    }
    return m_bip39_words;
}

QStringList NuRpcService::bip39EnglishWords() const
{
    return loadBip39Words();
}

bool NuRpcService::validateMnemonic(const QString& phrase, QString* normalized, QString* error) const
{
    const QStringList words = loadBip39Words();
    if (words.size() != 2048) {
        if (error) *error = QStringLiteral("The BIP39 English word list is not available in this build.");
        return false;
    }

    const QString cleaned = phrase.toLower().simplified();
    const QStringList parts = cleaned.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    if (!isValidBip39WordCount(parts.size())) {
        if (error) *error = QStringLiteral("Enter 12, 15, 18, 21, or 24 BIP39 English words.");
        return false;
    }

    const int entropy_bits = bip39EntropyBitsForWordCount(parts.size());
    const int checksum_bits = parts.size() * 11 - entropy_bits;
    QVector<bool> bits;
    bits.reserve(parts.size() * 11);
    for (const QString& word : parts) {
        const auto it = m_bip39_word_index.constFind(word);
        if (it == m_bip39_word_index.constEnd()) {
            if (error) *error = QStringLiteral("\"%1\" is not in the BIP39 English word list.").arg(word);
            return false;
        }
        const int index = it.value();
        for (int bit = 10; bit >= 0; --bit) bits.push_back((index >> bit) & 1);
    }

    QByteArray entropy(entropy_bits / 8, char(0));
    for (int i = 0; i < entropy_bits; ++i) {
        if (bits.at(i)) entropy[i / 8] = char(static_cast<unsigned char>(entropy.at(i / 8)) | (1 << (7 - (i % 8))));
    }
    const QByteArray checksum = sha256Bytes(entropy);
    for (int i = 0; i < checksum_bits; ++i) {
        if (bits.at(entropy_bits + i) != bitAt(checksum, i)) {
            if (error) *error = QStringLiteral("The words are in the BIP39 list, but the checksum does not match.");
            entropy.fill(0);
            return false;
        }
    }

    if (normalized) *normalized = parts.join(QLatin1Char(' '));
    entropy.fill(0);
    return true;
}

QVariantMap NuRpcService::validateRecoveryPhrase(const QString& phrase) const
{
    QString normalized;
    QString error;
    const bool valid = validateMnemonic(phrase, &normalized, &error);
    QVariantMap result;
    result.insert(QStringLiteral("valid"), valid);
    result.insert(QStringLiteral("normalized"), normalized);
    result.insert(QStringLiteral("message"), valid ? QStringLiteral("Recovery phrase checksum is valid.") : error);
    return result;
}

bool NuRpcService::looksLikeRecoveryPhraseText(const QString& text) const
{
    const QString cleaned = text.toLower().simplified();
    const QStringList parts = cleaned.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    if (!isValidBip39WordCount(parts.size())) return false;

    const QStringList words = loadBip39Words();
    if (words.size() != 2048) return false;

    int bip39_words = 0;
    for (const QString& word : parts) {
        if (m_bip39_word_index.contains(word)) ++bip39_words;
    }

    return bip39_words >= parts.size() - 1;
}

QString NuRpcService::generateRecoveryPhrase()
{
    const QStringList words = loadBip39Words();
    if (words.size() != 2048) return QString();

    QByteArray entropy(16, char(0));
    for (int i = 0; i < entropy.size(); ++i) entropy[i] = char(QRandomGenerator::system()->generate() & 0xff);
    const QByteArray checksum = sha256Bytes(entropy);

    QVector<bool> bits;
    bits.reserve(132);
    for (int i = 0; i < 128; ++i) bits.push_back(bitAt(entropy, i));
    for (int i = 0; i < 4; ++i) bits.push_back(bitAt(checksum, i));

    QStringList phrase;
    for (int word = 0; word < 12; ++word) {
        int index = 0;
        for (int bit = 0; bit < 11; ++bit) {
            index = (index << 1) | (bits.at(word * 11 + bit) ? 1 : 0);
        }
        phrase.push_back(words.at(index));
    }
    entropy.fill(0);
    return phrase.join(QLatin1Char(' '));
}

bool NuRpcService::mnemonicMaterial(const QString& phrase, const QString& wif_mode, QString* wif, QString* xprv, QString* error) const
{
    QString normalized;
    if (!validateMnemonic(phrase, &normalized, error)) return false;

    QByteArray seed = pbkdf2HmacSha512(normalized.toUtf8(), QByteArrayLiteral("mnemonic"), 2048, 64);
    QByteArray master = hmacSha512(QByteArrayLiteral("Bitcoin seed"), seed);
    QByteArray secret = master.left(32);
    const QByteArray chain_code = master.mid(32, 32);
    if (!isValidSecp256k1Secret(secret)) {
        if (error) *error = QStringLiteral("The recovery phrase produced an invalid BIP32 master key.");
        master.fill(0);
        seed.fill(0);
        secret.fill(0);
        return false;
    }

    QByteArray wif_payload;
    if (wif) {
        wif_payload.append(char(recoveryWifPrefix(wif_mode)));
        wif_payload.append(secret);
        wif_payload.append(char(1)); // compressed key marker
        *wif = encodeBase58Check(wif_payload);
    }

    QByteArray xprv_payload;
    xprv_payload.append(QByteArray::fromHex("0488ade4")); // Defcoin currently uses the Bitcoin/Litecoin xprv prefix.
    xprv_payload.append(char(0)); // depth
    xprv_payload.append(QByteArray(4, char(0))); // parent fingerprint
    xprv_payload.append(QByteArray(4, char(0))); // child number
    xprv_payload.append(chain_code);
    xprv_payload.append(char(0));
    xprv_payload.append(secret);
    if (xprv) *xprv = encodeBase58Check(xprv_payload);

    if (!wif_payload.isEmpty()) wif_payload.fill(0);
    xprv_payload.fill(0);
    master.fill(0);
    seed.fill(0);
    secret.fill(0);
    return true;
}

QString NuRpcService::descriptorForRecoveryPath(const QString& xprv, const QString& derivation_path, QString* error) const
{
    QString path = derivation_path.trimmed();
    if (path.isEmpty()) path = QStringLiteral("m/44'/0'/0'/0/*");
    if (!path.startsWith(QStringLiteral("m/"))) {
        if (error) *error = QStringLiteral("Derivation paths must start with m/.");
        return QString();
    }
    if (!path.endsWith(QStringLiteral("/*"))) {
        if (error) *error = QStringLiteral("Use a ranged derivation path ending in /*.");
        return QString();
    }
    static const QRegularExpression allowed_path(QStringLiteral(R"(^m(/[0-9]+(['hH])?)*(/\*)$)"));
    if (!allowed_path.match(path).hasMatch()) {
        if (error) *error = QStringLiteral("Use numeric BIP32 path segments, for example m/44'/2'/0'/0/*.");
        return QString();
    }

    QString suffix = path.mid(1); // keep the slash after m.
    suffix.replace(QLatin1Char('\''), QLatin1Char('h'));
    suffix.replace(QLatin1Char('H'), QLatin1Char('h'));
    return QStringLiteral("pkh(%1%2)").arg(xprv, suffix);
}

bool NuRpcService::requireLocalRecoveryRpc(const QString& operation)
{
    if (!loadRpcSettings()) {
        Q_EMIT userMessage(operation, m_last_error);
        return false;
    }

    const QString host = m_rpc_host.trimmed();
    QHostAddress address;
    const bool loopback_address = address.setAddress(host) && address.isLoopback();
    const bool loopback_name = host.compare(QStringLiteral("localhost"), Qt::CaseInsensitive) == 0;
    if (loopback_address || loopback_name) return true;

    Q_EMIT userMessage(operation,
                       QStringLiteral("Recovery phrase operations are allowed only with a local Defcoin backend RPC connection. Current RPC host is '%1'. Switch back to localhost before previewing or restoring from a phrase.")
                           .arg(host.isEmpty() ? QStringLiteral("(empty)") : host));
    return false;
}

bool NuRpcService::minerRunning() const
{
    return m_miner_process && m_miner_process->state() != QProcess::NotRunning;
}

QString NuRpcService::miningStateText() const
{
    return minerRunning() ? QStringLiteral("Running via CPU") : QStringLiteral("Stopped");
}

QString NuRpcService::miningMethodText() const
{
    return QStringLiteral("CPU");
}

QString NuRpcService::minerSummaryText() const
{
    if (!minerRunning()) return QString();
    return QStringLiteral("%1 | %2 | A: %3 | R: %4")
        .arg(miningStateText(),
             m_miner_hashrate_text.isEmpty() ? QStringLiteral("-") : m_miner_hashrate_text,
             QString::number(m_miner_accepted_shares),
             QString::number(m_miner_rejected_shares));
}

QString NuRpcService::walletMiningPayoutAddress() const
{
    if (!m_receive_address.trimmed().isEmpty()) return m_receive_address.trimmed();
    for (const QVariant& row_value : m_address_book) {
        const QVariantList cells = tableRowCells(row_value);
        if (cells.size() < 3) continue;
        const QString address = cells.at(1).toString().trimmed();
        const QString purpose = cells.at(2).toString();
        if (!address.isEmpty() && purpose.contains(QStringLiteral("receive"), Qt::CaseInsensitive)) {
            return address;
        }
    }
    return QString();
}

void NuRpcService::resetMinerRuntimeStats()
{
    m_miner_hashrate_text = QStringLiteral("-");
    m_miner_accepted_shares = 0;
    m_miner_rejected_shares = 0;
    m_miner_parse_buffer.clear();
}

void NuRpcService::parseMinerLogChunk(const QString& text)
{
    const QString clean = stripAnsiControlSequences(text);
    static const QRegularExpression hashrate_re(
        QStringLiteral(R"(\bHash rate\s+([0-9]+(?:\.[0-9]+)?)\s*([KMGT]?H/s)\b)"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression ttf_hashrate_re(
        QStringLiteral(R"(\bTTF\s*@\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGT]?H/s)\b)"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression accepted_re(
        QStringLiteral(R"(\bAccepted\s+(\d+)\s+S\d+\s+R(\d+)\s+B\d+\b)"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression rejected_re(
        QStringLiteral(R"(\bA(\d+)\s+S\d+\s+Rejected\s+(\d+)\s+B\d+\b)"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression periodic_accepted_re(
        QStringLiteral(R"(^Accepted\s+\d+\s+(\d+)\b)"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression periodic_rejected_re(
        QStringLiteral(R"(^Rejected\s+\d+\s+(\d+)\b)"),
        QRegularExpression::CaseInsensitiveOption);

    QString combined = m_miner_parse_buffer + clean;
    combined.replace(QStringLiteral("\r\n"), QStringLiteral("\n"));
    combined.replace(QLatin1Char('\r'), QLatin1Char('\n'));
    QStringList lines = combined.split(QLatin1Char('\n'));
    if (!combined.endsWith(QLatin1Char('\n'))) {
        m_miner_parse_buffer = lines.takeLast();
        if (m_miner_parse_buffer.size() > 4096) m_miner_parse_buffer.clear();
    } else {
        m_miner_parse_buffer.clear();
    }

    for (const QString& raw_line : lines) {
        const QString line = raw_line.trimmed();
        if (line.isEmpty()) continue;

        const QRegularExpressionMatch hashrate_match = hashrate_re.match(line);
        if (hashrate_match.hasMatch()) {
            m_miner_hashrate_text = formatMinerHashrateText(hashrate_match.captured(1), hashrate_match.captured(2));
        }

        const QRegularExpressionMatch ttf_hashrate_match = ttf_hashrate_re.match(line);
        if (ttf_hashrate_match.hasMatch()) {
            m_miner_hashrate_text = formatMinerHashrateText(ttf_hashrate_match.captured(1), ttf_hashrate_match.captured(2));
        }

        const QRegularExpressionMatch accepted_match = accepted_re.match(line);
        if (accepted_match.hasMatch()) {
            m_miner_accepted_shares = std::max(m_miner_accepted_shares, accepted_match.captured(1).toInt());
            m_miner_rejected_shares = std::max(m_miner_rejected_shares, accepted_match.captured(2).toInt());
            continue;
        }

        const QRegularExpressionMatch rejected_match = rejected_re.match(line);
        if (rejected_match.hasMatch()) {
            m_miner_accepted_shares = std::max(m_miner_accepted_shares, rejected_match.captured(1).toInt());
            m_miner_rejected_shares = std::max(m_miner_rejected_shares, rejected_match.captured(2).toInt());
            continue;
        }

        const QRegularExpressionMatch periodic_accepted_match = periodic_accepted_re.match(line);
        if (periodic_accepted_match.hasMatch()) {
            m_miner_accepted_shares = std::max(m_miner_accepted_shares, periodic_accepted_match.captured(1).toInt());
            continue;
        }

        const QRegularExpressionMatch periodic_rejected_match = periodic_rejected_re.match(line);
        if (periodic_rejected_match.hasMatch()) {
            m_miner_rejected_shares = std::max(m_miner_rejected_shares, periodic_rejected_match.captured(1).toInt());
        }
    }
}

void NuRpcService::appendMinerLog(const QString& line)
{
    if (line.trimmed().isEmpty()) return;
    const QString clean = stripAnsiControlSequences(line);
    parseMinerLogChunk(clean);
    m_miner_log += clean;
    if (!m_miner_log.endsWith(QLatin1Char('\n'))) m_miner_log += QLatin1Char('\n');
    constexpr int max_chars = 2 * 1024 * 1024;
    if (m_miner_log.size() > max_chars) m_miner_log = m_miner_log.right(max_chars);
    Q_EMIT minerChanged();
}

void NuRpcService::setRecoveryState(bool active, const QString& status, int progress)
{
    const int clean_progress = progress < 0 ? -1 : std::clamp(progress, 0, 100);
    const bool starting = active && !m_recovery_active;
    const bool finished = !active && clean_progress >= 100;
    if (starting) {
        m_recovery_timer.restart();
        m_recovery_cancel_requested = false;
        m_recovery_cancelable = true;
        m_recovery_poll_scheduled = false;
        m_recovery_finished = false;
        m_recovery_found_amount = QStringLiteral("Checking after the chain rescan completes.");
        m_recovery_found_address_count = 0;
        m_recovery_recent_found_address = QStringLiteral("No address hits reported yet.");
        m_recovery_detected_method = QStringLiteral("Checking recovery options.");
        m_recovery_current_method = QStringLiteral("Starting recovery.");
        m_recovery_elapsed = QStringLiteral("0s");
        m_recovery_eta = QStringLiteral("Estimating after the first scan step.");
    }
    if (active) {
        m_recovery_finished = false;
        updateRecoveryTiming();
        scheduleRecoveryScanPoll();
    } else {
        m_recovery_cancelable = false;
        m_recovery_poll_scheduled = false;
        if (m_recovery_timer.isValid()) m_recovery_elapsed = formatDurationFromSeconds(m_recovery_timer.elapsed() / 1000);
        if (finished) m_recovery_eta = QStringLiteral("Complete");
    }
    if (m_recovery_active == active &&
        m_recovery_finished == finished &&
        m_recovery_status == status &&
        m_recovery_progress == clean_progress) {
        if (!active) lockRecoveryWalletIfNeeded();
        return;
    }
    m_recovery_active = active;
    m_recovery_finished = finished;
    m_recovery_status = status;
    m_recovery_progress = clean_progress;
    Q_EMIT recoveryChanged();
    if (!active) lockRecoveryWalletIfNeeded();
}

void NuRpcService::setRecoveryCurrentMethod(const QString& method)
{
    if (m_recovery_current_method == method) return;
    m_recovery_current_method = method;
    updateRecoveryTiming();
    Q_EMIT recoveryChanged();
}

void NuRpcService::updateRecoveryTiming(int completed_work, int estimated_total_work)
{
    if (!m_recovery_timer.isValid()) {
        m_recovery_elapsed = QStringLiteral("Not running");
        m_recovery_eta = QStringLiteral("Unknown");
        return;
    }

    const qint64 elapsed_seconds = std::max<qint64>(0, m_recovery_timer.elapsed() / 1000);
    m_recovery_elapsed = formatDurationFromSeconds(elapsed_seconds);
    if (completed_work > 0 && estimated_total_work > completed_work) {
        const double seconds_per_unit = static_cast<double>(elapsed_seconds) / static_cast<double>(completed_work);
        const qint64 remaining = std::max<qint64>(0, std::llround(seconds_per_unit * static_cast<double>(estimated_total_work - completed_work)));
        m_recovery_eta = formatDurationFromSeconds(remaining);
    } else if (m_recovery_progress >= 0 && m_recovery_progress < 100 && m_recovery_progress > 0) {
        const qint64 remaining = std::max<qint64>(0, std::llround(static_cast<double>(elapsed_seconds) * (100.0 - m_recovery_progress) / std::max(1, m_recovery_progress)));
        m_recovery_eta = formatDurationFromSeconds(remaining);
    } else if (m_recovery_active) {
        m_recovery_eta = QStringLiteral("Estimating from scan progress.");
    }
}

void NuRpcService::scheduleRecoveryScanPoll()
{
    if (!m_recovery_active || m_recovery_poll_scheduled) return;
    m_recovery_poll_scheduled = true;
    QTimer::singleShot(2500, this, [this] {
        m_recovery_poll_scheduled = false;
        if (!m_recovery_active) return;

        rpcCall(QStringLiteral("getwalletinfo"), {}, true, [this](const QJsonValue& result, const QString&) {
            if (!m_recovery_active) return;
            if (result.isObject()) {
                const QJsonValue scanning_value = result.toObject().value(QStringLiteral("scanning"));
                if (scanning_value.isObject()) {
                    const QJsonObject scanning = scanning_value.toObject();
                    const double scan_progress = scanning.value(QStringLiteral("progress")).toDouble(-1.0);
                    if (scan_progress >= 0.0) {
                        m_recovery_progress = std::clamp(40 + static_cast<int>(std::llround(scan_progress * 50.0)), 40, 90);
                    }
                    const int duration = scanning.value(QStringLiteral("duration")).toInt(-1);
                    if (duration >= 0) {
                        m_recovery_elapsed = formatDurationFromSeconds(duration);
                    } else {
                        updateRecoveryTiming();
                    }
                    const double clamped = std::clamp(scan_progress, 0.0, 0.999);
                    if (clamped > 0.0 && duration > 0) {
                        const qint64 eta = std::max<qint64>(0, std::llround(static_cast<double>(duration) * (1.0 - clamped) / clamped));
                        m_recovery_eta = formatDurationFromSeconds(eta);
                    }
                    Q_EMIT recoveryChanged();
                } else {
                    updateRecoveryTiming();
                    Q_EMIT recoveryChanged();
                }
            }
            scheduleRecoveryScanPoll();
        });
    });
}

void NuRpcService::cancelRecovery()
{
    if (!m_recovery_active) return;
    m_recovery_cancel_requested = true;
    setRecoveryCurrentMethod(QStringLiteral("Cancel requested."));
    setRecoveryState(true, QStringLiteral("Cancel requested. Asking the backend to abort the active rescan..."), -1);
    rpcCall(QStringLiteral("abortrescan"), {}, true, [this](const QJsonValue&, const QString& error) {
        if (!error.isEmpty() && !error.contains(QStringLiteral("not currently rescanning"), Qt::CaseInsensitive)) {
            appendLaunchDiagnostic(QStringLiteral("Recovery cancel: abortrescan returned: %1").arg(error));
        }
    });
}

void NuRpcService::lockRecoveryWalletIfNeeded()
{
    if (!m_recovery_lock_after_restore) return;
    m_recovery_lock_after_restore = false;
    if (!m_wallet_selected) return;
    rpcCall(QStringLiteral("walletlock"), {}, true, [this](const QJsonValue&, const QString& error) {
        if (!error.isEmpty() && !error.contains(QStringLiteral("unencrypted wallet"), Qt::CaseInsensitive)) {
            appendLaunchDiagnostic(QStringLiteral("Recovery wallet lock: walletlock returned: %1").arg(error));
        }
    });
}

void NuRpcService::importRecoveryDescriptorsWithRescan(const QVector<QPair<QString, QString>>& descriptors, int range)
{
    const int import_range = std::clamp(range, 1, 1000);
    if (descriptors.isEmpty()) {
        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
        Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                           QStringLiteral("No recovery descriptors were available to import."));
        return;
    }

    setRecoveryState(true,
                     descriptors.size() == 1
                         ? QStringLiteral("Preparing address import and chain rescan...")
                         : QStringLiteral("Preparing auto recovery across %1 common derivation options...").arg(descriptors.size()),
                     35);
    setRecoveryCurrentMethod(descriptors.size() == 1 ? descriptors.first().first : QStringLiteral("Fixed scan across %1 methods").arg(descriptors.size()));

    auto pending = std::make_shared<int>(descriptors.size());
    auto requests = std::make_shared<QJsonArray>();
    auto labels = std::make_shared<QStringList>();
    auto errors = std::make_shared<QStringList>();

    for (const auto& descriptor_item : descriptors) {
        const QString label = descriptor_item.first;
        const QString descriptor = descriptor_item.second;
        rpcCall(QStringLiteral("getdescriptorinfo"), {descriptor}, false, [this, import_range, label, descriptor, pending, requests, labels, errors](const QJsonValue& result, const QString& descriptor_error) {
            if (m_recovery_cancel_requested) {
                --(*pending);
                if (*pending == 0) setRecoveryState(false, QStringLiteral("Recovery canceled before import."), 0);
                return;
            }
            if (!descriptor_error.isEmpty() || !result.isObject()) {
                errors->push_back(descriptor_error.isEmpty()
                                      ? QStringLiteral("%1: backend did not return descriptor details").arg(label)
                                      : QStringLiteral("%1: %2").arg(label, descriptor_error));
            } else {
                const QString checksum = result.toObject().value(QStringLiteral("checksum")).toString();
                if (checksum.isEmpty()) {
                    errors->push_back(QStringLiteral("%1: backend did not return a descriptor checksum").arg(label));
                } else {
                    const QString checked_descriptor = descriptor.section(QLatin1Char('#'), 0, 0) + QStringLiteral("#") + checksum;
                    QJsonObject request;
                    request.insert(QStringLiteral("desc"), checked_descriptor);
                    request.insert(QStringLiteral("timestamp"), 0);
                    request.insert(QStringLiteral("label"), label);
                    QJsonArray request_range;
                    request_range << 0 << (import_range - 1);
                    request.insert(QStringLiteral("range"), request_range);
                    requests->append(request);
                    labels->push_back(label);
                }
            }

            --(*pending);
            if (*pending > 0) return;

            if (requests->isEmpty()) {
                setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                                   errors->isEmpty() ? QStringLiteral("No recovery descriptor could be prepared.") : errors->join(QStringLiteral("\n")));
                return;
            }

            QJsonObject options;
            options.insert(QStringLiteral("rescan"), true);
            setRecoveryState(true,
                             labels->size() == 1
                                 ? QStringLiteral("Recovering %1 external addresses and rescanning the chain. This can take several minutes.").arg(import_range)
                                 : QStringLiteral("Auto recovery is scanning %1 common methods with %2 addresses each. This can take several minutes.").arg(labels->size()).arg(import_range),
                             -1);
            QJsonArray params;
            params << *requests << options;
            rpcCall(QStringLiteral("importmulti"), params, true, [this, import_range, labels](const QJsonValue&, const QString& import_error) {
                if (m_recovery_cancel_requested) {
                    setRecoveryState(false, QStringLiteral("Recovery canceled. Partial imports may remain in the new wallet."), 0);
                    Q_EMIT userMessage(QStringLiteral("Recovery canceled"),
                                       QStringLiteral("The active rescan was canceled. Some derived addresses may already have been imported into the new wallet."));
                    return;
                }
                if (!import_error.isEmpty()) {
                    setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                    Q_EMIT userMessage(QStringLiteral("Wallet not restored"), import_error);
                    return;
                }
                summarizeCompletedRecoveryImport(import_range, *labels);
            });
        });
    }
}

void NuRpcService::importRecoveryDescriptorsUntilEmpty(const QVector<QPair<QString, QString>>& descriptors, int empty_gap)
{
    struct RecoveryGapMethod {
        QString label;
        QString checked_descriptor;
        int next_index = 0;
        int max_found_index = -1;
        int imported_end = -1;
        bool active = true;
    };

    const int gap_limit = std::clamp(empty_gap, 20, 1024);
    if (descriptors.isEmpty()) {
        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
        Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                           QStringLiteral("No recovery descriptors were available to import."));
        return;
    }

    setRecoveryState(true,
                     QStringLiteral("Preparing auto-until-empty recovery. Each method stops after %1 empty addresses in a row.").arg(gap_limit),
                     35);
    setRecoveryCurrentMethod(QStringLiteral("Preparing %1 recovery methods.").arg(descriptors.size()));

    auto states = std::make_shared<QVector<RecoveryGapMethod>>();
    auto pending = std::make_shared<int>(descriptors.size());
    auto errors = std::make_shared<QStringList>();
    auto completed_batches = std::make_shared<int>(0);
    auto cumulative_amount = std::make_shared<double>(0.0);
    auto cumulative_funded_addresses = std::make_shared<int>(0);
    auto amount_by_label = std::make_shared<QHash<QString, double>>();
    auto run_batch = std::make_shared<std::function<void()>>();

    *run_batch = [this,
                  states,
                  errors,
                  completed_batches,
                  cumulative_amount,
                  cumulative_funded_addresses,
                  amount_by_label,
                  run_batch,
                  gap_limit]() {
        if (m_recovery_cancel_requested) {
            setRecoveryState(false, QStringLiteral("Recovery canceled. Partial imports may remain in the new wallet."), 0);
            Q_EMIT userMessage(QStringLiteral("Recovery canceled"),
                               QStringLiteral("Recovery was canceled. Some derived addresses may already have been imported into the new wallet."));
            return;
        }

        QVector<int> active_indices;
        int max_imported = 0;
        QStringList labels;
        for (int i = 0; i < states->size(); ++i) {
            RecoveryGapMethod& state = (*states)[i];
            labels.push_back(state.label);
            max_imported = std::max(max_imported, state.imported_end + 1);
            if (state.active) active_indices.push_back(i);
        }

        if (active_indices.isEmpty()) {
            setRecoveryCurrentMethod(QStringLiteral("All methods reached the %1-empty-address stop rule.").arg(gap_limit));
            summarizeCompletedRecoveryImport(std::max(1, max_imported), labels);
            return;
        }

        auto request_array = std::make_shared<QJsonArray>();
        auto address_lookup = std::make_shared<QHash<QString, QPair<int, int>>>();
        auto derive_pending = std::make_shared<int>(active_indices.size());
        auto derive_errors = std::make_shared<QStringList>();

        const int first_state = active_indices.first();
        const int first_start = (*states)[first_state].next_index;
        const int first_end = std::min(first_start + RECOVERY_GAP_SCAN_BATCH_SIZE - 1, RECOVERY_GAP_SCAN_HARD_MAX_ADDRESSES - 1);
        setRecoveryCurrentMethod(QStringLiteral("Auto-until-empty batch %1-%2 across %3 active methods.").arg(first_start).arg(first_end).arg(active_indices.size()));
        setRecoveryState(true,
                         QStringLiteral("Auto recovery is importing the next address batch, then rescanning. A method stops only after %1 consecutive empty derived addresses.").arg(gap_limit),
                         -1);

        for (const int state_index : active_indices) {
            const RecoveryGapMethod& state = (*states)[state_index];
            const int start = state.next_index;
            const int end = std::min(start + RECOVERY_GAP_SCAN_BATCH_SIZE - 1, RECOVERY_GAP_SCAN_HARD_MAX_ADDRESSES - 1);
            QJsonArray range;
            range << start << end;
            rpcCall(QStringLiteral("deriveaddresses"), {state.checked_descriptor, range}, false, [this, states, state_index, start, end, address_lookup, request_array, derive_pending, derive_errors, completed_batches, cumulative_amount, cumulative_funded_addresses, amount_by_label, run_batch, gap_limit](const QJsonValue& result, const QString& error) {
                if (!error.isEmpty() || !result.isArray()) {
                    derive_errors->push_back(error.isEmpty()
                                                 ? QStringLiteral("%1: backend did not derive addresses").arg((*states)[state_index].label)
                                                 : QStringLiteral("%1: %2").arg((*states)[state_index].label, error));
                    (*states)[state_index].active = false;
                } else {
                    int index = start;
                    for (const QJsonValue& address_value : result.toArray()) {
                        const QString address = address_value.toString();
                        if (!address.isEmpty()) address_lookup->insert(address, qMakePair(state_index, index));
                        ++index;
                    }
                    QJsonObject request;
                    request.insert(QStringLiteral("desc"), (*states)[state_index].checked_descriptor);
                    request.insert(QStringLiteral("timestamp"), 0);
                    request.insert(QStringLiteral("label"), (*states)[state_index].label);
                    QJsonArray import_range;
                    import_range << start << end;
                    request.insert(QStringLiteral("range"), import_range);
                    request_array->append(request);
                }

                --(*derive_pending);
                if (*derive_pending > 0) return;

                if (m_recovery_cancel_requested) {
                    setRecoveryState(false, QStringLiteral("Recovery canceled before the next import batch."), 0);
                    return;
                }
                if (request_array->isEmpty()) {
                    setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                    Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                                       derive_errors->isEmpty() ? QStringLiteral("No recovery address batch could be derived.") : derive_errors->join(QStringLiteral("\n")));
                    return;
                }

                QJsonObject options;
                options.insert(QStringLiteral("rescan"), true);
                QJsonArray params;
                params << *request_array << options;
                rpcCall(QStringLiteral("importmulti"), params, true, [this, states, address_lookup, completed_batches, cumulative_amount, cumulative_funded_addresses, amount_by_label, run_batch, gap_limit](const QJsonValue&, const QString& import_error) {
                    if (m_recovery_cancel_requested) {
                        setRecoveryState(false, QStringLiteral("Recovery canceled. Partial imports may remain in the new wallet."), 0);
                        Q_EMIT userMessage(QStringLiteral("Recovery canceled"),
                                           QStringLiteral("The active rescan was canceled. Some derived addresses may already have been imported into the new wallet."));
                        return;
                    }
                    if (!import_error.isEmpty()) {
                        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                        Q_EMIT userMessage(QStringLiteral("Wallet not restored"), import_error);
                        return;
                    }

                    rpcCall(QStringLiteral("listreceivedbyaddress"), {0, true, true}, true, [this, states, address_lookup, completed_batches, cumulative_amount, cumulative_funded_addresses, amount_by_label, run_batch, gap_limit](const QJsonValue& received_result, const QString&) {
                        int batch_hits = 0;
                        double batch_amount = 0.0;
                        QString recent_hit = m_recovery_recent_found_address.isEmpty()
                            ? QStringLiteral("No address hits reported yet.")
                            : m_recovery_recent_found_address;

                        if (received_result.isArray()) {
                            for (const QJsonValue& value : received_result.toArray()) {
                                const QJsonObject item = value.toObject();
                                const double amount = item.value(QStringLiteral("amount")).toDouble();
                                if (amount <= 0.0) continue;
                                const QString address = item.value(QStringLiteral("address")).toString();
                                const auto found = address_lookup->constFind(address);
                                if (found == address_lookup->constEnd()) continue;
                                const int state_index = found.value().first;
                                const int derived_index = found.value().second;
                                if (state_index < 0 || state_index >= states->size()) continue;
                                RecoveryGapMethod& state = (*states)[state_index];
                                if (derived_index > state.max_found_index) state.max_found_index = derived_index;
                                ++batch_hits;
                                batch_amount += amount;
                                (*amount_by_label)[state.label] += amount;
                                recent_hit = QStringLiteral("%1 index %2 received %3 DFC")
                                    .arg(address)
                                    .arg(derived_index)
                                    .arg(QString::number(amount, 'f', 8));
                            }
                        }

                        for (RecoveryGapMethod& state : *states) {
                            if (!state.active) continue;
                            const int end = std::min(state.next_index + RECOVERY_GAP_SCAN_BATCH_SIZE - 1, RECOVERY_GAP_SCAN_HARD_MAX_ADDRESSES - 1);
                            state.imported_end = end;
                            state.next_index = end + 1;
                            const int empty_after_last_hit = state.max_found_index < 0 ? state.next_index : state.imported_end - state.max_found_index;
                            if (empty_after_last_hit >= gap_limit || state.next_index >= RECOVERY_GAP_SCAN_HARD_MAX_ADDRESSES) {
                                state.active = false;
                            }
                        }

                        ++(*completed_batches);
                        if (batch_hits > 0) {
                            *cumulative_amount += batch_amount;
                            *cumulative_funded_addresses += batch_hits;
                            m_recovery_found_amount = QStringLiteral("%1 DFC received in discovered addresses so far")
                                .arg(QString::number(*cumulative_amount, 'f', 8));
                            m_recovery_found_address_count = *cumulative_funded_addresses;
                            m_recovery_recent_found_address = recent_hit;
                            double best_amount = -1.0;
                            QString best_label;
                            for (auto it = amount_by_label->constBegin(); it != amount_by_label->constEnd(); ++it) {
                                if (it.value() > best_amount) {
                                    best_amount = it.value();
                                    best_label = it.key();
                                }
                            }
                            if (!best_label.isEmpty()) m_recovery_detected_method = best_label;
                        }

                        updateRecoveryTiming(*completed_batches, *completed_batches + 1);
                        if (m_recovery_active && !m_recovery_eta.startsWith(QStringLiteral("at least"), Qt::CaseInsensitive)) {
                            m_recovery_eta = QStringLiteral("at least %1").arg(m_recovery_eta);
                        }
                        Q_EMIT recoveryChanged();
                        QTimer::singleShot(0, this, [run_batch] { (*run_batch)(); });
                    });
                });
            });
        }
    };

    for (const auto& descriptor_item : descriptors) {
        const QString label = descriptor_item.first;
        const QString descriptor = descriptor_item.second;
        rpcCall(QStringLiteral("getdescriptorinfo"), {descriptor}, false, [this, label, descriptor, pending, states, errors, run_batch](const QJsonValue& result, const QString& descriptor_error) {
            if (!descriptor_error.isEmpty() || !result.isObject()) {
                errors->push_back(descriptor_error.isEmpty()
                                      ? QStringLiteral("%1: backend did not return descriptor details").arg(label)
                                      : QStringLiteral("%1: %2").arg(label, descriptor_error));
            } else {
                const QString checksum = result.toObject().value(QStringLiteral("checksum")).toString();
                if (checksum.isEmpty()) {
                    errors->push_back(QStringLiteral("%1: backend did not return a descriptor checksum").arg(label));
                } else {
                    RecoveryGapMethod state;
                    state.label = label;
                    state.checked_descriptor = descriptor.section(QLatin1Char('#'), 0, 0) + QStringLiteral("#") + checksum;
                    states->push_back(state);
                }
            }

            --(*pending);
            if (*pending > 0) return;

            if (states->isEmpty()) {
                setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                                   errors->isEmpty() ? QStringLiteral("No recovery descriptor could be prepared.") : errors->join(QStringLiteral("\n")));
                return;
            }
            QTimer::singleShot(0, this, [run_batch] { (*run_batch)(); });
        });
    }
}

void NuRpcService::summarizeCompletedRecoveryImport(int import_range, const QStringList& tried_methods)
{
    setRecoveryState(true, QStringLiteral("Rescan complete. Checking recovered wallet balance and matching addresses..."), 92);

    rpcCall(QStringLiteral("listreceivedbyaddress"), {0, true, true}, true, [this, import_range, tried_methods](const QJsonValue& received_result, const QString&) {
        int funded_addresses = 0;
        double total_received = 0.0;
        QString recent_hit = QStringLiteral("No received coins found in the imported range.");
        QString detected_method = tried_methods.size() > 1
            ? QStringLiteral("No matching method found yet.")
            : (tried_methods.isEmpty() ? QStringLiteral("Manual recovery scan.") : tried_methods.first());
        QHash<QString, double> amount_by_label;

        if (received_result.isArray()) {
            for (const QJsonValue& value : received_result.toArray()) {
                const QJsonObject item = value.toObject();
                const double amount = item.value(QStringLiteral("amount")).toDouble();
                if (amount <= 0.0) continue;
                ++funded_addresses;
                total_received += amount;
                const QString label = item.value(QStringLiteral("label")).toString();
                if (!label.isEmpty()) amount_by_label[label] += amount;
                recent_hit = QStringLiteral("%1 received %2 DFC")
                    .arg(item.value(QStringLiteral("address")).toString(),
                         QString::number(amount, 'f', 8));
            }
        }

        if (!amount_by_label.isEmpty()) {
            double best_amount = -1.0;
            for (auto it = amount_by_label.constBegin(); it != amount_by_label.constEnd(); ++it) {
                if (it.value() > best_amount) {
                    best_amount = it.value();
                    detected_method = it.key();
                }
            }
        } else if (!tried_methods.isEmpty()) {
            detected_method = tried_methods.size() == 1
                ? QStringLiteral("%1 (no received coins found)").arg(tried_methods.first())
                : QStringLiteral("No received coins found in the %1 methods tried.").arg(tried_methods.size());
        }

        rpcCall(QStringLiteral("getwalletinfo"), {}, true, [this, import_range, funded_addresses, total_received, recent_hit, detected_method](const QJsonValue& wallet_result, const QString&) {
            QString balance_text = QStringLiteral("No spendable balance found yet.");
            if (wallet_result.isObject()) {
                const QJsonObject wallet = wallet_result.toObject();
                const double available = wallet.value(QStringLiteral("balance")).toDouble();
                const double pending = wallet.value(QStringLiteral("unconfirmed_balance")).toDouble();
                const double immature = wallet.value(QStringLiteral("immature_balance")).toDouble();
                const double total = available + pending + immature;
                balance_text = QStringLiteral("%1 DFC").arg(QString::number(total, 'f', 8));
                if (pending > 0.0 || immature > 0.0) {
                    balance_text += QStringLiteral(" (%1 available, %2 pending, %3 immature)")
                        .arg(QString::number(available, 'f', 8),
                             QString::number(pending, 'f', 8),
                             QString::number(immature, 'f', 8));
                }
            } else if (total_received > 0.0) {
                balance_text = QStringLiteral("%1 DFC received on imported addresses").arg(QString::number(total_received, 'f', 8));
            }

            m_recovery_found_amount = balance_text;
            m_recovery_found_address_count = funded_addresses;
            m_recovery_recent_found_address = recent_hit;
            m_recovery_detected_method = detected_method;
            refresh();
            setRecoveryState(false,
                             QStringLiteral("Recovery complete. Imported up to %1 addresses per method and completed the chain rescan. No extra rescan action is needed.").arg(import_range),
                             100);
            Q_EMIT userMessage(QStringLiteral("Wallet restored"),
                               QStringLiteral("The wallet was created, up to %1 external recovery addresses were imported per method, and the chain rescan completed. Detected method: %2. No extra recovery action is required; review the wallet balance, Transactions, and Wallet > Addresses.")
                                   .arg(import_range)
                                   .arg(detected_method));
        });
    });
}

void NuRpcService::chooseMinerExecutable()
{
    const QString selected = QFileDialog::getOpenFileName(nullptr,
        QStringLiteral("Select miner executable"),
        m_miner_executable.isEmpty() ? QDir::homePath() : QFileInfo(m_miner_executable).absolutePath());
    if (selected.isEmpty()) return;
    m_miner_executable = selected;
    QSettings().setValue(QStringLiteral("MinerExecutable"), selected);
    m_miner_status = QStringLiteral("Miner executable selected.");
    Q_EMIT minerChanged();
}

void NuRpcService::useWalletReceiveAddressForMining()
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Mining payout address unavailable"))) return;

    const QString existing = walletMiningPayoutAddress();
    if (!existing.isEmpty()) {
        m_miner_payout_address = existing;
        QSettings().setValue(QStringLiteral("MinerPayoutAddress"), m_miner_payout_address);
        m_miner_status = QStringLiteral("Using wallet receive address for mining payout.");
        Q_EMIT minerChanged();
        return;
    }

    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("getnewaddress"), {QStringLiteral("Mining payout")}, true, [this, wallet_name](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Mining payout address unavailable"), error);
            return;
        }
        m_receive_address = result.toString().trimmed();
        m_receive_label = QStringLiteral("Mining payout");
        m_receive_amount.clear();
        m_receive_message.clear();
        m_miner_payout_address = m_receive_address;
        QSettings().setValue(QStringLiteral("MinerPayoutAddress"), m_miner_payout_address);
        updateReceiveQr();
        refreshAddressBook();
        m_miner_status = QStringLiteral("Generated wallet receive address for mining payout.");
        Q_EMIT minerChanged();
        Q_EMIT walletChanged();
    });
}

void NuRpcService::saveMinerConfiguration(const QString& pool_url,
                                          const QString& payout_address,
                                          const QString& password,
                                          int threads,
                                          int nice_level)
{
    const QString clean_pool_url = singleLineLimited(pool_url, 512);
    const QString clean_payout_address = singleLineLimited(payout_address, 128);
    const QString clean_password = singleLineLimited(password, 128);
    if (!isValidStratumUrl(clean_pool_url)) {
        Q_EMIT userMessage(QStringLiteral("Mining configuration not saved"),
                           QStringLiteral("Pool URL must be a stratum+tcp:// or stratum+ssl:// URL with a valid host and optional port."));
        return;
    }
    if (!isLikelyBase58AddressText(clean_payout_address)) {
        Q_EMIT userMessage(QStringLiteral("Mining configuration not saved"),
                           QStringLiteral("Enter a Defcoin payout address before saving the mining configuration."));
        return;
    }

    m_miner_pool_url = clean_pool_url;
    m_miner_payout_address = clean_payout_address;
    m_miner_password = clean_password.isEmpty() ? QStringLiteral("x") : clean_password;
    m_miner_threads = std::clamp(threads, 1, 256);
    m_miner_nice_level = std::clamp(nice_level, 0, 20);
    QSettings settings;
    settings.setValue(QStringLiteral("MinerPoolUrl"), m_miner_pool_url);
    settings.setValue(QStringLiteral("MinerPayoutAddress"), m_miner_payout_address);
    settings.setValue(QStringLiteral("MinerPassword"), m_miner_password);
    settings.setValue(QStringLiteral("MinerThreads"), m_miner_threads);
    settings.setValue(QStringLiteral("MinerNiceLevel"), m_miner_nice_level);
    m_miner_status = QStringLiteral("Mining configuration saved.");
    Q_EMIT minerChanged();
}

void NuRpcService::startConfiguredMiner()
{
    if (minerRunning()) return;
    if (m_miner_executable.isEmpty() || !QFileInfo(m_miner_executable).isExecutable()) {
        Q_EMIT userMessage(QStringLiteral("Miner not started"), QStringLiteral("Select a miner executable before starting local mining."));
        return;
    }
    if (m_miner_pool_url.trimmed().isEmpty() || m_miner_payout_address.trimmed().isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Miner not started"), QStringLiteral("Enter a stratum pool URL and payout address before starting local mining."));
        return;
    }
    if (!isValidStratumUrl(singleLineLimited(m_miner_pool_url, 512))) {
        Q_EMIT userMessage(QStringLiteral("Miner not started"),
                           QStringLiteral("Pool URL must be a stratum+tcp:// or stratum+ssl:// URL with a valid host and optional port."));
        return;
    }
    if (!isLikelyBase58AddressText(singleLineLimited(m_miner_payout_address, 128))) {
        Q_EMIT userMessage(QStringLiteral("Miner not started"),
                           QStringLiteral("Enter a valid Defcoin payout address before starting local mining."));
        return;
    }

    QString wrapper_note;
    const QString miner_program = resolvedCpuminerExecutable(m_miner_executable, &wrapper_note);
    if (QFileInfo(miner_program).suffix().compare(QStringLiteral("sh"), Qt::CaseInsensitive) == 0) {
        Q_EMIT userMessage(QStringLiteral("Miner not started"), wrapper_note);
        return;
    }
    if (!QFileInfo(miner_program).isExecutable()) {
        Q_EMIT userMessage(QStringLiteral("Miner not started"),
                           QStringLiteral("Nu could not find an executable cpuminer binary at:\n%1").arg(QDir::toNativeSeparators(miner_program)));
        return;
    }

    QStringList miner_args{
        QStringLiteral("-a"), QStringLiteral("scrypt"),
        QStringLiteral("-o"), m_miner_pool_url,
        QStringLiteral("-u"), m_miner_payout_address,
        QStringLiteral("-p"), m_miner_password.isEmpty() ? QStringLiteral("x") : m_miner_password,
        QStringLiteral("-t"), QString::number(m_miner_threads)
    };
    QString program = miner_program;
    QStringList process_args = miner_args;
#if defined(Q_OS_MACOS)
    if (m_miner_nice_level > 0 && QFileInfo::exists(QStringLiteral("/usr/bin/taskpolicy"))) {
        program = QStringLiteral("/usr/bin/taskpolicy");
        process_args = {QStringLiteral("-b"), QStringLiteral("nice"), QStringLiteral("-n"), QString::number(m_miner_nice_level), miner_program};
        process_args.append(miner_args);
    }
#elif !defined(Q_OS_WIN)
    if (m_miner_nice_level > 0 && QFileInfo::exists(QStringLiteral("/usr/bin/nice"))) {
        program = QStringLiteral("/usr/bin/nice");
        process_args = {QStringLiteral("-n"), QString::number(m_miner_nice_level), miner_program};
        process_args.append(miner_args);
    }
#endif

    m_miner_process = new QProcess(this);
    m_miner_process->setProgram(program);
    m_miner_process->setWorkingDirectory(QFileInfo(miner_program).absolutePath());
    m_miner_process->setArguments(process_args);
    connect(m_miner_process, &QProcess::readyReadStandardOutput, this, [this] {
        appendMinerLog(QString::fromLocal8Bit(m_miner_process->readAllStandardOutput()));
    });
    connect(m_miner_process, &QProcess::readyReadStandardError, this, [this] {
        appendMinerLog(QString::fromLocal8Bit(m_miner_process->readAllStandardError()));
    });
    connect(m_miner_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this, [this](int exit_code, QProcess::ExitStatus) {
        m_miner_status = QStringLiteral("Miner stopped with exit code %1.").arg(exit_code);
        m_miner_process->deleteLater();
        m_miner_process = nullptr;
        Q_EMIT minerChanged();
    });
    resetMinerRuntimeStats();
    m_miner_log.clear();
    if (!wrapper_note.isEmpty()) appendMinerLog(wrapper_note);
    appendMinerLog(QStringLiteral("Nu launch command: %1").arg(processCommandForDisplayRedacted(program, process_args)));
    m_miner_status = QStringLiteral("Starting miner...");
    Q_EMIT minerChanged();
    m_miner_process->start();
    if (!m_miner_process->waitForStarted(2500)) {
        const QString start_error = m_miner_process->errorString();
        m_miner_process->deleteLater();
        m_miner_process = nullptr;
        m_miner_status = QStringLiteral("Miner failed to start.");
        Q_EMIT minerChanged();
        Q_EMIT userMessage(QStringLiteral("Miner not started"), start_error);
        return;
    }
    m_miner_status = QStringLiteral("Miner running.");
    Q_EMIT minerChanged();
}

void NuRpcService::stopMiner()
{
    if (!m_miner_process) return;
    m_miner_process->terminate();
    if (!m_miner_process->waitForFinished(3000)) m_miner_process->kill();
}

void NuRpcService::clearMinerLog()
{
    m_miner_log.clear();
    Q_EMIT minerChanged();
}

QString NuRpcService::normalizedVersionString(QString version)
{
    version = version.trimmed();
    if (version.startsWith(QLatin1Char('v'), Qt::CaseInsensitive)) version.remove(0, 1);
    const QRegularExpression version_re(QStringLiteral(R"((\d+(?:\.\d+)+))"));
    const QRegularExpressionMatch match = version_re.match(version);
    return match.hasMatch() ? match.captured(1) : version;
}

bool NuRpcService::isVersionNewer(const QString& candidate, const QString& current)
{
    const QVersionNumber candidate_version = QVersionNumber::fromString(normalizedVersionString(candidate));
    const QVersionNumber current_version = QVersionNumber::fromString(normalizedVersionString(current));
    if (!candidate_version.isNull() && !current_version.isNull()) {
        return QVersionNumber::compare(candidate_version, current_version) > 0;
    }
    return normalizedVersionString(candidate) > normalizedVersionString(current);
}

QString NuRpcService::selectedUpdateAssetNeedle() const
{
#if defined(Q_OS_MACOS)
    const QString architecture = QSysInfo::currentCpuArchitecture().toLower();
    return architecture.contains(QStringLiteral("arm")) || architecture.contains(QStringLiteral("aarch64"))
        ? QStringLiteral("osx-arm64-setup.pkg")
        : QStringLiteral("osx-x64-setup.pkg");
#elif defined(Q_OS_WIN)
    return QStringLiteral("win-x64-setup.exe");
#else
    return QString();
#endif
}

QString NuRpcService::updateDownloadDirectory() const
{
    QString downloads = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (downloads.isEmpty()) downloads = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir dir(downloads);
    if (!dir.exists(QStringLiteral("Defcoin Core Nu Updates"))) {
        dir.mkpath(QStringLiteral("Defcoin Core Nu Updates"));
    }
    return dir.filePath(QStringLiteral("Defcoin Core Nu Updates"));
}

void NuRpcService::setUpdateStatus(const QString& status, int progress)
{
    bool changed = false;
    if (m_update_status != status) {
        m_update_status = status;
        changed = true;
    }
    if (progress >= 0 && m_update_download_progress != progress) {
        m_update_download_progress = progress;
        changed = true;
    }
    if (changed) Q_EMIT updateStatusChanged();
}

void NuRpcService::clearPendingUpdateDownload()
{
    if (!m_update_download_file) return;
    if (m_update_download_file->isOpen()) m_update_download_file->close();
    m_update_download_file->deleteLater();
    m_update_download_file = nullptr;
}

void NuRpcService::checkForUpdates(bool manual)
{
    if (m_update_check_in_progress) {
        if (manual) Q_EMIT userMessage(QStringLiteral("Update check already running"), QStringLiteral("Defcoin Core Nu is already checking for updates."));
        return;
    }

    m_update_check_in_progress = true;
    setUpdateStatus(QStringLiteral("Checking for Defcoin Core Nu updates..."), 0);

    QString velopack_error;
    if (m_velopack_updater) {
        NuVelopackUpdateDetails velopack_details;
        const NuVelopackUpdater::CheckState velopack_state = m_velopack_updater->checkForUpdates(velopack_details);
        if (velopack_state == NuVelopackUpdater::CheckState::UpdateAvailable) {
            m_update_check_in_progress = false;
            m_pending_update = PendingUpdate{};
            m_pending_update.version = velopack_details.version;
            m_pending_update.assetName = velopack_details.packageName.isEmpty() ? QStringLiteral("Velopack package") : velopack_details.packageName;
            m_pending_update.assetSize = qint64(velopack_details.size);
            m_pending_update.velopackManaged = true;
            const QString size = m_pending_update.assetSize > 0 ? formatBytes(m_pending_update.assetSize) : QStringLiteral("managed by Velopack");
            const QString action = velopack_details.pendingRestart ? QStringLiteral("Apply this update now?") : QStringLiteral("Download this update now?");
            const QString message = QStringLiteral("Defcoin Core Nu %1 is available through Velopack.\n\nCurrent version: %2\nPackage: %3 (%4)\n\n%5")
                .arg(m_pending_update.version, currentNuVersion(), m_pending_update.assetName, size, action);
            setUpdateStatus(QStringLiteral("Defcoin Core Nu %1 is available through Velopack.").arg(m_pending_update.version), 0);
            Q_EMIT updateAvailable(m_pending_update.version, message);
            return;
        }
        if (velopack_state == NuVelopackUpdater::CheckState::NoUpdate) {
            m_update_check_in_progress = false;
            const QString message = QStringLiteral("Defcoin Core Nu is up to date. Current version: %1.").arg(currentNuVersion());
            setUpdateStatus(message, 0);
            if (manual) Q_EMIT userMessage(QStringLiteral("No update available"), message);
            return;
        }
        if (velopack_state == NuVelopackUpdater::CheckState::Error && m_velopack_updater->isManagerAvailable()) {
            velopack_error = QStringLiteral("Velopack could not check for updates: %1").arg(m_velopack_updater->lastError());
            setUpdateStatus(QStringLiteral("Velopack update feed unavailable; checking GitHub releases..."), 0);
        }
    }

    setUpdateStatus(QStringLiteral("Checking GitHub for Defcoin Core Nu updates..."), 0);

    QNetworkRequest request(QUrl(QStringLiteral("https://api.github.com/repos/defcoincore/Defcoin-Core-Nu/releases/latest")));
    request.setRawHeader("Accept", "application/vnd.github+json");
    request.setRawHeader("User-Agent", "DefcoinCoreNu/" DEFCOIN_NU_VERSION);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply* reply = m_update_network->get(request);
    reply->setProperty("manual", manual);
    reply->setProperty("velopackError", velopack_error);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        handleUpdateReleaseReply(reply);
    });
}

void NuRpcService::handleUpdateReleaseReply(QNetworkReply* reply)
{
    const bool manual = reply->property("manual").toBool();
    const QString velopack_error = reply->property("velopackError").toString();
    m_update_check_in_progress = false;

    const auto finish = [reply] {
        reply->deleteLater();
    };

    if (reply->error() != QNetworkReply::NoError) {
        QString message = QStringLiteral("Could not check GitHub releases: %1").arg(reply->errorString());
        if (!velopack_error.isEmpty()) {
            message = QStringLiteral("%1\n\n%2").arg(velopack_error, message);
        }
        setUpdateStatus(message);
        if (manual) Q_EMIT userMessage(QStringLiteral("Update check failed"), message);
        finish();
        return;
    }

    const QJsonDocument document = QJsonDocument::fromJson(reply->readAll());
    const QJsonObject release = document.object();
    const QString tag = release.value(QStringLiteral("tag_name")).toString();
    const QString latest_version = normalizedVersionString(tag);
    const QString release_url = release.value(QStringLiteral("html_url")).toString(QStringLiteral("https://github.com/defcoincore/Defcoin-Core-Nu/releases/latest"));

    if (latest_version.isEmpty()) {
        const QString message = QStringLiteral("GitHub did not return a usable Defcoin Core Nu release tag.");
        setUpdateStatus(message);
        if (manual) Q_EMIT userMessage(QStringLiteral("Update check failed"), message);
        finish();
        return;
    }

    if (!isVersionNewer(latest_version, currentNuVersion())) {
        const QString message = QStringLiteral("Defcoin Core Nu is up to date. Current version: %1. Latest release: %2.")
            .arg(currentNuVersion(), latest_version);
        setUpdateStatus(message, 0);
        if (manual) Q_EMIT userMessage(QStringLiteral("No update available"), message);
        finish();
        return;
    }

    const QString asset_needle = selectedUpdateAssetNeedle();
    if (asset_needle.isEmpty()) {
        const QString message = QStringLiteral("Defcoin Core Nu %1 is available, but automatic package selection is not supported on this platform. Open %2 to download it manually.")
            .arg(latest_version, release_url);
        setUpdateStatus(message);
        if (manual) Q_EMIT userMessage(QStringLiteral("Update available"), message);
        finish();
        return;
    }

    QString checksum_url;
    QJsonObject selected_asset;
    const QJsonArray assets = release.value(QStringLiteral("assets")).toArray();
    for (const QJsonValue& value : assets) {
        const QJsonObject asset = value.toObject();
        const QString name = asset.value(QStringLiteral("name")).toString();
        if (name.compare(QStringLiteral("SHA256SUMS.txt"), Qt::CaseInsensitive) == 0) {
            checksum_url = asset.value(QStringLiteral("browser_download_url")).toString();
        }
        if (name.toLower().contains(asset_needle)) {
            selected_asset = asset;
        }
    }

    if (selected_asset.isEmpty()) {
        const QString message = QStringLiteral("Defcoin Core Nu %1 is available, but no matching package was found for this computer. Open %2 to download it manually.")
            .arg(latest_version, release_url);
        setUpdateStatus(message);
        if (manual) Q_EMIT userMessage(QStringLiteral("Update available"), message);
        finish();
        return;
    }

    m_pending_update = PendingUpdate{};
    m_pending_update.version = latest_version;
    m_pending_update.tag = tag;
    m_pending_update.releaseUrl = release_url;
    m_pending_update.assetName = selected_asset.value(QStringLiteral("name")).toString();
    m_pending_update.assetUrl = selected_asset.value(QStringLiteral("browser_download_url")).toString();
    m_pending_update.assetSize = selected_asset.value(QStringLiteral("size")).toVariant().toLongLong();
    m_pending_update.checksumUrl = checksum_url;

    const QString size = m_pending_update.assetSize > 0 ? formatBytes(m_pending_update.assetSize) : QStringLiteral("unknown size");
    const QString message = QStringLiteral("Defcoin Core Nu %1 is available.\n\nCurrent version: %2\nPackage: %3 (%4)\n\nDownload and verify this update now?")
        .arg(m_pending_update.version, currentNuVersion(), m_pending_update.assetName, size);
    setUpdateStatus(QStringLiteral("Defcoin Core Nu %1 is available.").arg(m_pending_update.version), 0);
    Q_EMIT updateAvailable(m_pending_update.version, message);
    finish();
}

void NuRpcService::downloadPendingUpdate()
{
    if (m_pending_update.assetUrl.isEmpty() || m_pending_update.assetName.isEmpty()) {
        if (!m_pending_update.velopackManaged) {
            Q_EMIT userMessage(QStringLiteral("No update selected"), QStringLiteral("Check for updates before downloading an installer."));
            return;
        }
    }
    if (m_update_download_in_progress) {
        Q_EMIT userMessage(QStringLiteral("Download already running"), QStringLiteral("Defcoin Core Nu is already downloading an update."));
        return;
    }
    if (m_pending_update.velopackManaged) {
        m_update_download_in_progress = true;
        setUpdateStatus(QStringLiteral("Downloading Velopack update..."), 0);
        QThread* thread = QThread::create([this] {
            const bool ok = m_velopack_updater && m_velopack_updater->downloadPendingUpdate([this](int progress) {
                QMetaObject::invokeMethod(this, [this, progress] {
                    setUpdateStatus(QStringLiteral("Downloading Velopack update..."), progress);
                }, Qt::QueuedConnection);
            });
            const QString error = m_velopack_updater ? m_velopack_updater->lastError() : QStringLiteral("Velopack is not available.");
            QMetaObject::invokeMethod(this, [this, ok, error] {
                m_update_download_in_progress = false;
                if (!ok) {
                    setUpdateStatus(error, 0);
                    Q_EMIT userMessage(QStringLiteral("Download failed"), error);
                    return;
                }
                const QString message = QStringLiteral("Defcoin Core Nu %1 was downloaded and prepared by Velopack.\n\nClose Defcoin Core Nu and apply the update now?")
                    .arg(m_pending_update.version);
                setUpdateStatus(QStringLiteral("Defcoin Core Nu %1 downloaded and ready to apply.").arg(m_pending_update.version), 100);
                Q_EMIT updateDownloaded(m_pending_update.version, QStringLiteral("Velopack managed update"), message);
            }, Qt::QueuedConnection);
        });
        connect(thread, &QThread::finished, thread, &QObject::deleteLater);
        thread->start();
        return;
    }
    if (m_pending_update.checksumUrl.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Update cannot be verified"),
                           QStringLiteral("The GitHub release does not include SHA256SUMS.txt, so Nu will not auto-install it. Download from GitHub manually instead."));
        return;
    }

    QDir dir(updateDownloadDirectory());
    if (!dir.exists()) dir.mkpath(QStringLiteral("."));
    const QString target_path = dir.filePath(m_pending_update.assetName);
    if (QFileInfo::exists(target_path)) QFile::remove(target_path);

    clearPendingUpdateDownload();
    m_update_download_file = new QFile(target_path, this);
    if (!m_update_download_file->open(QIODevice::WriteOnly)) {
        const QString message = QStringLiteral("Could not write update package to %1.").arg(target_path);
        clearPendingUpdateDownload();
        Q_EMIT userMessage(QStringLiteral("Download failed"), message);
        setUpdateStatus(message);
        return;
    }

    m_pending_update.filePath = target_path;
    m_update_download_in_progress = true;
    setUpdateStatus(QStringLiteral("Downloading %1...").arg(m_pending_update.assetName), 0);

    QNetworkRequest request(QUrl(m_pending_update.assetUrl));
    request.setRawHeader("User-Agent", "DefcoinCoreNu/" DEFCOIN_NU_VERSION);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply* reply = m_update_network->get(request);
    connect(reply, &QNetworkReply::readyRead, this, [this, reply] {
        if (m_update_download_file) m_update_download_file->write(reply->readAll());
    });
    connect(reply, &QNetworkReply::downloadProgress, this, [this](qint64 received, qint64 total) {
        const int progress = total > 0 ? qBound(0, int((received * 100) / total), 100) : 0;
        setUpdateStatus(QStringLiteral("Downloading %1...").arg(m_pending_update.assetName), progress);
    });
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        handleUpdateAssetReply(reply);
    });
}

void NuRpcService::handleUpdateAssetReply(QNetworkReply* reply)
{
    if (m_update_download_file) {
        m_update_download_file->write(reply->readAll());
        m_update_download_file->flush();
        m_update_download_file->close();
    }

    if (reply->error() != QNetworkReply::NoError) {
        const QString message = QStringLiteral("Could not download update: %1").arg(reply->errorString());
        QFile::remove(m_pending_update.filePath);
        clearPendingUpdateDownload();
        m_update_download_in_progress = false;
        setUpdateStatus(message, 0);
        Q_EMIT userMessage(QStringLiteral("Download failed"), message);
        reply->deleteLater();
        return;
    }

    clearPendingUpdateDownload();
    setUpdateStatus(QStringLiteral("Verifying update checksum..."), 100);

    QNetworkRequest request(QUrl(m_pending_update.checksumUrl));
    request.setRawHeader("User-Agent", "DefcoinCoreNu/" DEFCOIN_NU_VERSION);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply* checksum_reply = m_update_network->get(request);
    connect(checksum_reply, &QNetworkReply::finished, this, [this, checksum_reply] {
        handleUpdateChecksumReply(checksum_reply);
    });
    reply->deleteLater();
}

bool NuRpcService::verifyDownloadedUpdate(const QByteArray& checksum_file, QString& error)
{
    QFile file(m_pending_update.filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        error = QStringLiteral("Could not reopen downloaded update package for verification.");
        return false;
    }
    QCryptographicHash hasher(QCryptographicHash::Sha256);
    while (!file.atEnd()) {
        hasher.addData(file.read(1024 * 1024));
    }
    const QByteArray actual_hash = hasher.result().toHex();

    const QString checksums = QString::fromUtf8(checksum_file);
    const QStringList lines = checksums.split(QLatin1Char('\n'));
    const QRegularExpression line_re(QStringLiteral(R"(^\s*([A-Fa-f0-9]{64})\s+\*?(.+?)\s*$)"));
    QString expected_hash;
    for (const QString& line : lines) {
        const QRegularExpressionMatch match = line_re.match(line);
        if (!match.hasMatch()) continue;
        const QString file_name = QFileInfo(match.captured(2).trimmed()).fileName();
        if (file_name == m_pending_update.assetName) {
            expected_hash = match.captured(1).toLower();
            break;
        }
    }

    if (expected_hash.isEmpty()) {
        error = QStringLiteral("SHA256SUMS.txt does not include %1.").arg(m_pending_update.assetName);
        return false;
    }
    if (actual_hash != expected_hash.toUtf8()) {
        error = QStringLiteral("Downloaded update checksum did not match SHA256SUMS.txt.");
        return false;
    }
    return true;
}

void NuRpcService::handleUpdateChecksumReply(QNetworkReply* reply)
{
    m_update_download_in_progress = false;

    if (reply->error() != QNetworkReply::NoError) {
        const QString message = QStringLiteral("Could not download SHA256SUMS.txt: %1").arg(reply->errorString());
        QFile::remove(m_pending_update.filePath);
        setUpdateStatus(message, 0);
        Q_EMIT userMessage(QStringLiteral("Verification failed"), message);
        reply->deleteLater();
        return;
    }

    QString error;
    if (!verifyDownloadedUpdate(reply->readAll(), error)) {
        QFile::remove(m_pending_update.filePath);
        setUpdateStatus(error, 0);
        Q_EMIT userMessage(QStringLiteral("Verification failed"), error);
        reply->deleteLater();
        return;
    }

    const QString message = QStringLiteral("Defcoin Core Nu %1 was downloaded and verified.\n\nPackage: %2\n\nClose Defcoin Core Nu and start the installer now?")
        .arg(m_pending_update.version, m_pending_update.filePath);
    setUpdateStatus(QStringLiteral("Defcoin Core Nu %1 downloaded and verified.").arg(m_pending_update.version), 100);
    Q_EMIT updateDownloaded(m_pending_update.version, m_pending_update.filePath, message);
    reply->deleteLater();
}

void NuRpcService::installDownloadedUpdate()
{
    if (m_pending_update.velopackManaged) {
        if (!m_velopack_updater || !m_velopack_updater->applyPendingUpdate(true)) {
            const QString error = m_velopack_updater ? m_velopack_updater->lastError() : QStringLiteral("Velopack is not available.");
            Q_EMIT userMessage(QStringLiteral("Update failed"), error);
            setUpdateStatus(error, 0);
            return;
        }
        setUpdateStatus(QStringLiteral("Velopack updater launched. Quitting Defcoin Core Nu..."), 100);
        QTimer::singleShot(700, [] {
            QCoreApplication::quit();
        });
        return;
    }

    if (m_pending_update.filePath.isEmpty() || !QFileInfo::exists(m_pending_update.filePath)) {
        Q_EMIT userMessage(QStringLiteral("Installer not found"), QStringLiteral("The downloaded update package could not be found. Check for updates again."));
        return;
    }

#if defined(Q_OS_WIN)
    const bool launched = QProcess::startDetached(m_pending_update.filePath, {});
#else
    const bool launched = QDesktopServices::openUrl(QUrl::fromLocalFile(m_pending_update.filePath));
#endif
    if (!launched) {
        Q_EMIT userMessage(QStringLiteral("Installer launch failed"), QStringLiteral("Nu could not open the downloaded update package. Open it manually from:\n%1").arg(m_pending_update.filePath));
        return;
    }

    setUpdateStatus(QStringLiteral("Update installer launched. Quitting Defcoin Core Nu..."), 100);
    QTimer::singleShot(700, [] {
        QCoreApplication::quit();
    });
}

void NuRpcService::setMaskBalances(bool enabled)
{
    if (m_mask_balances == enabled) return;
    m_mask_balances = enabled;
    QSettings().setValue(QStringLiteral("MaskBalances"), enabled);
    Q_EMIT settingsChanged();
    Q_EMIT walletChanged();
}

void NuRpcService::setThirdPartyTxUrlsEnabled(bool enabled)
{
    if (m_third_party_tx_urls_enabled == enabled) return;
    m_third_party_tx_urls_enabled = enabled;
    if (!enabled && m_explorer_mode != QLatin1String("internal")) {
        m_explorer_mode = QStringLiteral("internal");
        QSettings().setValue(QStringLiteral("ExplorerMode"), m_explorer_mode);
    }
    QSettings settings;
    settings.setValue(QStringLiteral("ThirdPartyTxUrlsEnabled"), enabled);
    QSettings(QStringLiteral("Defcoin"), QStringLiteral("Defcoin-Qt")).setValue(QStringLiteral("ThirdPartyTxUrlsEnabled"), enabled);
    Q_EMIT settingsChanged();
}

void NuRpcService::setThirdPartyTxUrl(const QString& url)
{
    const QString normalized = normalizedExplorerUrl(url);
    if (!url.trimmed().isEmpty() && normalized.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Explorer URL not saved"),
                           QStringLiteral("Explorer URL must be a valid http:// or https:// template with one %s placeholder and no embedded credentials."));
        return;
    }
    if (m_third_party_tx_url == normalized) return;
    m_third_party_tx_url = normalized;
    QSettings settings;
    settings.setValue(QStringLiteral("ThirdPartyTxUrl"), normalized);
    QSettings(QStringLiteral("Defcoin"), QStringLiteral("Defcoin-Qt")).setValue(QStringLiteral("strThirdPartyTxUrls"), normalized);
    Q_EMIT settingsChanged();
}

void NuRpcService::setExplorerMode(const QString& mode)
{
    QString clean = mode.trimmed().toLower();
    if (!QStringList{QStringLiteral("internal"), QStringLiteral("dc903"), QStringLiteral("legacy"), QStringLiteral("custom")}.contains(clean)) {
        clean = QStringLiteral("internal");
    }
    if (clean == QLatin1String("custom") && normalizedExplorerUrl(m_third_party_tx_url).isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Explorer URL required"),
                           QStringLiteral("Enter a valid http:// or https:// explorer URL template with one %s placeholder before switching to Custom."));
        clean = QStringLiteral("internal");
    }
    if (m_explorer_mode == clean) return;
    m_explorer_mode = clean;
    if (clean == QLatin1String("internal")) {
        m_third_party_tx_urls_enabled = false;
    } else {
        m_third_party_tx_urls_enabled = true;
        if (clean == QLatin1String("dc903")) m_third_party_tx_url = explorerPresetUrl(1);
        if (clean == QLatin1String("legacy")) m_third_party_tx_url = explorerPresetUrl(2);
    }
    QSettings settings;
    settings.setValue(QStringLiteral("ExplorerMode"), m_explorer_mode);
    settings.setValue(QStringLiteral("ThirdPartyTxUrlsEnabled"), m_third_party_tx_urls_enabled);
    if (clean != QLatin1String("custom")) settings.setValue(QStringLiteral("ThirdPartyTxUrl"), m_third_party_tx_url);
    Q_EMIT settingsChanged();
}

bool NuRpcService::usingInternalExplorer() const
{
    return m_explorer_mode == QLatin1String("internal");
}

QString NuRpcService::normalizedExplorerUrl(const QString& url) const
{
    QString clean = singleLineLimited(url, 1024);
    if (clean.isEmpty()) return QString();
    if (clean.count(QStringLiteral("%s")) != 1) return QString();
    if (!clean.startsWith(QStringLiteral("http://"), Qt::CaseInsensitive) &&
        !clean.startsWith(QStringLiteral("https://"), Qt::CaseInsensitive)) {
        clean.prepend(QStringLiteral("https://"));
    }
    QString parse_text = clean;
    parse_text.replace(QStringLiteral("%s"), QStringLiteral("defcoin-placeholder"));
    if (!isSafeHttpUrl(QUrl(parse_text, QUrl::StrictMode))) return QString();
    return clean;
}

QString NuRpcService::explorerPresetUrl(int index) const
{
    if (index == 1) return QStringLiteral("https://defcoin.dc903.org/explorer/tx/%s");
    if (index == 2) return QStringLiteral("https://defcoin.dc903.org/legacyexplorer/tx/%s");
    return QString();
}

QString NuRpcService::explorerAddressUrlTemplate(const QString& url) const
{
    QString out = url;
    out.replace(QStringLiteral("/tx/%s"), QStringLiteral("/address/%s"), Qt::CaseInsensitive);
    out.replace(QStringLiteral("/transaction/%s"), QStringLiteral("/address/%s"), Qt::CaseInsensitive);
    return out;
}

QString NuRpcService::explorerDatabasePath() const
{
    const QDir data_dir(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir);
    return data_dir.filePath(QStringLiteral("nu-explorer/explorer.sqlite"));
}

QString NuRpcService::droidTrailsDatabasePath() const
{
    const QDir data_dir(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir);
    return data_dir.filePath(QStringLiteral("nu-explorer/droidtails.sqlite"));
}

bool NuRpcService::ensureDroidTrailsDatabase(QString* error) const
{
    const QFileInfo db_info(droidTrailsDatabasePath());
    if (!QDir().mkpath(db_info.absolutePath())) {
        if (error) *error = QStringLiteral("Could not create Droid Trails cache directory:\n%1").arg(db_info.absolutePath());
        return false;
    }

    const QString connection_name = QStringLiteral("nu_droidtails_init_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(db_info.absoluteFilePath());
        ok = db.open();
        if (!ok) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
            query.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
            ok = query.exec(QStringLiteral(
                "CREATE TABLE IF NOT EXISTS droidtails_meta ("
                "key TEXT PRIMARY KEY,"
                "value TEXT NOT NULL)"));
            if (!ok) local_error = query.lastError().text();
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS droidtails_cache ("
                    "cache_key TEXT PRIMARY KEY,"
                    "schema_version INTEGER NOT NULL,"
                    "source_height INTEGER NOT NULL,"
                    "source_outputs INTEGER NOT NULL,"
                    "payload_json TEXT NOT NULL,"
                    "cached_at INTEGER NOT NULL)"));
                if (!ok) local_error = query.lastError().text();
            }
            QString saved_version;
            if (ok) {
                QSqlQuery version_query(db);
                if (version_query.exec(QStringLiteral("SELECT value FROM droidtails_meta WHERE key='schema_version'")) && version_query.next())
                    saved_version = version_query.value(0).toString();
                if (saved_version != QString::number(DROIDTRAILS_CACHE_SCHEMA_VERSION)) {
                    if (!query.exec(QStringLiteral("DELETE FROM droidtails_cache"))) {
                        ok = false;
                        local_error = query.lastError().text();
                    }
                }
            }
            if (ok) {
                QSqlQuery upsert(db);
                upsert.prepare(QStringLiteral("INSERT OR REPLACE INTO droidtails_meta(key,value) VALUES('schema_version',?)"));
                upsert.addBindValue(QString::number(DROIDTRAILS_CACHE_SCHEMA_VERSION));
                ok = upsert.exec();
                if (!ok) local_error = upsert.lastError().text();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok && error) *error = QStringLiteral("SQLite Droid Trails cache unavailable: %1").arg(local_error);
    return ok;
}

bool NuRpcService::ensureExplorerDatabase(QString* error) const
{
    const QFileInfo db_info(explorerDatabasePath());
    if (!QDir().mkpath(db_info.absolutePath())) {
        if (error) *error = QStringLiteral("Could not create explorer index directory:\n%1").arg(db_info.absolutePath());
        return false;
    }

    const QString connection_name = QStringLiteral("nu_explorer_init_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(db_info.absoluteFilePath());
        ok = db.open();
        if (!ok) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
            query.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
            query.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));
            ok = query.exec(QStringLiteral(
                "CREATE TABLE IF NOT EXISTS explorer_lookups ("
                "type TEXT NOT NULL,"
                "id TEXT NOT NULL,"
                "title TEXT NOT NULL,"
                "summary TEXT NOT NULL,"
                "raw_json TEXT NOT NULL,"
                "cached_at INTEGER NOT NULL,"
                "PRIMARY KEY(type, id))"));
            if (!ok) local_error = query.lastError().text();
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_lookups_cached_at ON explorer_lookups(cached_at DESC)"));
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_meta ("
                    "key TEXT PRIMARY KEY,"
                    "value TEXT NOT NULL)"));
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_blocks ("
                    "height INTEGER PRIMARY KEY,"
                    "hash TEXT NOT NULL UNIQUE,"
                    "time INTEGER NOT NULL,"
                    "tx_count INTEGER NOT NULL,"
                    "raw_json TEXT NOT NULL,"
                    "indexed_at INTEGER NOT NULL)"));
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_block_transactions ("
                    "block_height INTEGER NOT NULL,"
                    "tx_index INTEGER NOT NULL,"
                    "txid TEXT NOT NULL,"
                    "PRIMARY KEY(block_height, tx_index))"));
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_block_transactions_txid ON explorer_block_transactions(txid)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_block_transactions_txid_block ON explorer_block_transactions(txid, block_height, tx_index)"));
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_tx_outputs ("
                    "txid TEXT NOT NULL,"
                    "vout INTEGER NOT NULL,"
                    "block_height INTEGER NOT NULL,"
                    "address TEXT NOT NULL,"
                    "value_sats INTEGER NOT NULL,"
                    "value_text TEXT NOT NULL,"
                    "script_type TEXT,"
                    "spent_by_txid TEXT,"
                    "spent_in_height INTEGER,"
                    "spent_vin INTEGER,"
                    "PRIMARY KEY(txid, vout, address))"));
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_tx_outputs_address ON explorer_tx_outputs(address, block_height DESC)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_tx_outputs_block ON explorer_tx_outputs(block_height)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_tx_outputs_block_txid ON explorer_tx_outputs(block_height, txid)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_tx_outputs_block_value_address ON explorer_tx_outputs(block_height, value_sats, address)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_tx_outputs_spent_by ON explorer_tx_outputs(spent_by_txid)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_tx_outputs_unspent_address_value ON explorer_tx_outputs(address, value_sats) WHERE spent_by_txid IS NULL"));
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_op_returns ("
                    "txid TEXT NOT NULL,"
                    "vout INTEGER NOT NULL,"
                    "block_height INTEGER NOT NULL,"
                    "value_sats INTEGER NOT NULL,"
                    "script_hex TEXT NOT NULL,"
                    "payload_hex TEXT NOT NULL,"
                    "payload_text TEXT NOT NULL,"
                    "PRIMARY KEY(txid, vout))"));
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_op_returns_block ON explorer_op_returns(block_height)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_op_returns_payload ON explorer_op_returns(payload_hex)"));
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_balance_deltas ("
                    "height INTEGER NOT NULL,"
                    "address TEXT NOT NULL,"
                    "delta_sats INTEGER NOT NULL,"
                    "PRIMARY KEY(height, address))"));
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_balance_deltas_address ON explorer_balance_deltas(address, height)"));
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_top100_events ("
                    "height INTEGER NOT NULL,"
                    "time INTEGER NOT NULL,"
                    "rank INTEGER NOT NULL,"
                    "address TEXT NOT NULL,"
                    "percent_whole INTEGER NOT NULL,"
                    "color_index INTEGER NOT NULL,"
                    "is_anchor INTEGER NOT NULL,"
                    "PRIMARY KEY(height, rank))"));
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_top100_events_height ON explorer_top100_events(height)"));
            if (ok) query.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS explorer_top100_events_rank_height ON explorer_top100_events(rank, height DESC)"));
            if (ok) {
                ok = query.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS explorer_top100_ranges ("
                    "start_height INTEGER NOT NULL,"
                    "end_height INTEGER NOT NULL,"
                    "status TEXT NOT NULL,"
                    "started_at INTEGER NOT NULL,"
                    "completed_at INTEGER,"
                    "PRIMARY KEY(start_height, end_height))"));
                if (!ok) local_error = query.lastError().text();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok && error) *error = QStringLiteral("SQLite explorer index unavailable: %1").arg(local_error);
    return ok;
}

void NuRpcService::refreshRecentAverageBlockTimeFromRpc(int tip_height)
{
    if (tip_height <= 1) {
        refreshRecentAverageBlockTimeFromIndex();
        return;
    }

    const int window_blocks = std::min(120, tip_height);
    const int start_height = tip_height - window_blocks;
    rpcCall(QStringLiteral("getblockhash"), {tip_height}, false, [this, tip_height, start_height, window_blocks](const QJsonValue& tip_result, const QString& tip_error) {
        if (!tip_error.isEmpty() || !tip_result.isString()) {
            refreshRecentAverageBlockTimeFromIndex();
            return;
        }
        const QString tip_hash = tip_result.toString();
        rpcCall(QStringLiteral("getblockheader"), {tip_hash}, false, [this, start_height, window_blocks](const QJsonValue& tip_header_result, const QString& tip_header_error) {
            if (!tip_header_error.isEmpty() || !tip_header_result.isObject()) {
                refreshRecentAverageBlockTimeFromIndex();
                return;
            }
            const qint64 tip_time = tip_header_result.toObject().value(QStringLiteral("time")).toVariant().toLongLong();
            rpcCall(QStringLiteral("getblockhash"), {start_height}, false, [this, tip_time, window_blocks](const QJsonValue& start_result, const QString& start_error) {
                if (!start_error.isEmpty() || !start_result.isString()) {
                    refreshRecentAverageBlockTimeFromIndex();
                    return;
                }
                rpcCall(QStringLiteral("getblockheader"), {start_result.toString()}, false, [this, tip_time, window_blocks](const QJsonValue& start_header_result, const QString& start_header_error) {
                    if (!start_header_error.isEmpty() || !start_header_result.isObject()) {
                        refreshRecentAverageBlockTimeFromIndex();
                        return;
                    }
                    const qint64 start_time = start_header_result.toObject().value(QStringLiteral("time")).toVariant().toLongLong();
                    if (tip_time <= start_time || window_blocks <= 0) {
                        refreshRecentAverageBlockTimeFromIndex();
                        return;
                    }
                    m_metric_average_block_time = formatBlockSpacingMetric(double(tip_time - start_time) / double(window_blocks));
                    rebuildNodeMetrics();
                    Q_EMIT stateChanged();
                });
            });
        });
    });
}

void NuRpcService::refreshRecentAverageBlockTimeFromIndex()
{
#if DEFCOIN_NU_EXPLORE_APP
    QString error;
    if (!ensureExplorerDatabase(&error)) {
        m_metric_average_block_time = QStringLiteral("Unknown");
        rebuildNodeMetrics();
        Q_EMIT stateChanged();
        return;
    }

    QString local_value = QStringLiteral("Index warming");
    const QString connection_name = QStringLiteral("nu_explorer_block_time_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            if (query.exec(QStringLiteral("SELECT height, time FROM explorer_blocks ORDER BY height DESC LIMIT 121"))) {
                int newest_height = -1;
                int oldest_height = -1;
                qint64 newest_time = 0;
                qint64 oldest_time = 0;
                int row_count = 0;
                while (query.next()) {
                    const int height = query.value(0).toInt();
                    const qint64 block_time = query.value(1).toLongLong();
                    if (row_count == 0) {
                        newest_height = height;
                        newest_time = block_time;
                    }
                    oldest_height = height;
                    oldest_time = block_time;
                    ++row_count;
                }
                const int span_blocks = newest_height - oldest_height;
                const qint64 span_seconds = newest_time - oldest_time;
                if (row_count >= 2 && span_blocks > 0 && span_seconds > 0)
                    local_value = formatBlockSpacingMetric(double(span_seconds) / double(span_blocks));
            }
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connection_name);
    m_metric_average_block_time = local_value;
#else
    m_metric_average_block_time = QStringLiteral("Explore only");
#endif
    rebuildNodeMetrics();
    Q_EMIT stateChanged();
}

QVariantMap NuRpcService::networkPulseHistoryFromDb(int window_blocks, QString* error) const
{
    QVariantMap analysis;
    QVariantList rows;
    QVariantMap summary;
#if !DEFCOIN_NU_EXPLORE_APP
    if (error) *error = QStringLiteral("Network Pulse history is only available in Defcoin Core Nu Explore.");
    return analysis;
#else
    QString db_error;
    if (!ensureExplorerDatabase(&db_error)) {
        if (error) *error = db_error;
        return analysis;
    }

    const int clean_window = qBound(10, window_blocks, 20160);
    const QString connection_name = QStringLiteral("nu_network_pulse_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    QString local_error;
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        ok = db.open();
        if (!ok) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));
            ok = query.exec(QStringLiteral("SELECT MIN(height), MAX(height), COUNT(*) FROM explorer_blocks"));
            if (!ok || !query.next()) {
                local_error = ok ? QStringLiteral("Explorer block table is not readable.") : query.lastError().text();
                ok = false;
            } else {
                const int min_height = query.value(0).toInt();
                const int max_height = query.value(1).toInt();
                const int block_count = query.value(2).toInt();
                if (block_count < 2 || max_height <= min_height) {
                    local_error = QStringLiteral("Explorer index needs at least two cached blocks before Network Pulse can chart history.");
                    ok = false;
                } else {
                    const int target_samples = 360;
                    const int chain_span = std::max(1, max_height - min_height);
                    const int stride = std::max(clean_window, std::max(1, chain_span / target_samples));
                    QSqlQuery sample(db);
                    sample.prepare(QStringLiteral(
                        "SELECT height, hash, time, tx_count, raw_json "
                        "FROM explorer_blocks "
                        "WHERE height = ? OR height = ? OR ((height - ?) % ?) = 0 "
                        "ORDER BY height ASC "
                        "LIMIT 720"));
                    sample.addBindValue(min_height);
                    sample.addBindValue(max_height);
                    sample.addBindValue(min_height);
                    sample.addBindValue(stride);
                    ok = sample.exec();
                    if (!ok) {
                        local_error = sample.lastError().text();
                    } else {
                        int previous_height = -1;
                        qint64 previous_time = 0;
                        int first_row_height = -1;
                        int last_row_height = -1;
                        qint64 first_row_time = 0;
                        qint64 last_row_time = 0;
                        double last_spacing = 0.0;
                        double last_difficulty = 0.0;
                        double last_hashrate = 0.0;
                        while (sample.next()) {
                            const int height = sample.value(0).toInt();
                            const QString hash = sample.value(1).toString();
                            const qint64 block_time = sample.value(2).toLongLong();
                            const int tx_count = sample.value(3).toInt();
                            const QString raw_json = sample.value(4).toString();
                            double difficulty = 0.0;
                            const QJsonDocument raw_doc = QJsonDocument::fromJson(raw_json.toUtf8());
                            if (raw_doc.isObject())
                                difficulty = raw_doc.object().value(QStringLiteral("difficulty")).toDouble();
                            if (previous_height >= 0 && height > previous_height && block_time > previous_time) {
                                const int span_blocks = height - previous_height;
                                const qint64 span_seconds = block_time - previous_time;
                                const double average_spacing = double(span_seconds) / double(span_blocks);
                                const double estimated_hashrate = difficulty > 0.0 && average_spacing > 0.0
                                    ? difficulty * 4294967296.0 / average_spacing
                                    : 0.0;
                                const QString date_text = QDateTime::fromSecsSinceEpoch(block_time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm"));
                                QVariantMap meta{
                                    {QStringLiteral("type"), QStringLiteral("block")},
                                    {QStringLiteral("id"), hash},
                                    {QStringLiteral("height"), height},
                                    {QStringLiteral("time"), block_time},
                                    {QStringLiteral("avgSpacingSeconds"), average_spacing},
                                    {QStringLiteral("difficulty"), difficulty},
                                    {QStringLiteral("hashrate"), estimated_hashrate},
                                    {QStringLiteral("spanBlocks"), span_blocks},
                                    {QStringLiteral("spanSeconds"), span_seconds},
                                    {QStringLiteral("txCount"), tx_count}
                                };
                                rows.push_back(tableRow({
                                    QString::number(height),
                                    date_text,
                                    formatBlockSpacingMetric(average_spacing),
                                    formatCompactDifficulty(difficulty),
                                    formatHashrateMetric(estimated_hashrate),
                                    QStringLiteral("%1 blocks").arg(QString::number(span_blocks)),
                                    QString::number(tx_count)
                                }, meta));
                                if (first_row_height < 0) {
                                    first_row_height = height;
                                    first_row_time = block_time;
                                }
                                last_row_height = height;
                                last_row_time = block_time;
                                last_spacing = average_spacing;
                                last_difficulty = difficulty;
                                last_hashrate = estimated_hashrate;
                            }
                            previous_height = height;
                            previous_time = block_time;
                        }
                        if (rows.isEmpty()) {
                            local_error = QStringLiteral("Explorer index has block rows, but sampled timestamps were not usable.");
                            ok = false;
                        } else {
                            summary.insert(QStringLiteral("windowBlocks"), clean_window);
                            summary.insert(QStringLiteral("strideBlocks"), stride);
                            summary.insert(QStringLiteral("sampleRows"), rows.size());
                            summary.insert(QStringLiteral("indexedBlocks"), block_count);
                            summary.insert(QStringLiteral("firstHeight"), first_row_height);
                            summary.insert(QStringLiteral("lastHeight"), last_row_height);
                            summary.insert(QStringLiteral("firstDate"), first_row_time > 0 ? QDateTime::fromSecsSinceEpoch(first_row_time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd")) : QStringLiteral("-"));
                            summary.insert(QStringLiteral("lastDate"), last_row_time > 0 ? QDateTime::fromSecsSinceEpoch(last_row_time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd")) : QStringLiteral("-"));
                            summary.insert(QStringLiteral("currentAvgBlockTime"), formatBlockSpacingMetric(last_spacing));
                            summary.insert(QStringLiteral("currentDifficulty"), formatCompactDifficulty(last_difficulty));
                            summary.insert(QStringLiteral("currentHashrate"), formatHashrateMetric(last_hashrate));
                            summary.insert(QStringLiteral("currentAvgBlockSeconds"), last_spacing);
                            summary.insert(QStringLiteral("currentHashrateRaw"), last_hashrate);
                            summary.insert(QStringLiteral("currentDifficultyRaw"), last_difficulty);
                            analysis.insert(QStringLiteral("rows"), rows);
                            analysis.insert(QStringLiteral("summary"), summary);
                            analysis.insert(QStringLiteral("status"), QStringLiteral("Network Pulse chart sampled %1 indexed block intervals from %2 cached blocks. Window target: %3 blocks; sampled stride: %4 blocks.")
                                            .arg(QString::number(rows.size()),
                                                 QString::number(block_count),
                                                 QString::number(clean_window),
                                                 QString::number(stride)));
                        }
                    }
                }
            }
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok && error) *error = QStringLiteral("Network Pulse history unavailable: %1").arg(local_error);
    return analysis;
#endif
}

bool NuRpcService::acquireExplorerWriterLock(QString* error)
{
    if (m_explorer_writer_lock && m_explorer_writer_lock->isLocked()) return true;
    const QFileInfo db_info(explorerDatabasePath());
    if (!QDir().mkpath(db_info.absolutePath())) {
        if (error) *error = QStringLiteral("Could not create explorer index directory:\n%1").arg(db_info.absolutePath());
        return false;
    }
    m_explorer_writer_lock = std::make_unique<QLockFile>(db_info.absoluteFilePath() + QStringLiteral(".writer.lock"));
    m_explorer_writer_lock->setStaleLockTime(30000);
    if (m_explorer_writer_lock->tryLock(100)) return true;
    if (error) {
        *error = QStringLiteral("Another Defcoin Core Nu window is writing the explorer index. Pause indexing there or close the other window before starting this operation.");
    }
    m_explorer_writer_lock.reset();
    return false;
}

void NuRpcService::releaseExplorerWriterLock()
{
    if (m_explorer_writer_lock) {
        if (m_explorer_writer_lock->isLocked()) m_explorer_writer_lock->unlock();
        m_explorer_writer_lock.reset();
    }
}

bool NuRpcService::ensureExplorerBalanceDeltas(QString* error)
{
    QString db_error;
    if (!ensureExplorerDatabase(&db_error)) {
        if (error) *error = db_error;
        return false;
    }

    const int highest = explorerHighestIndexedBlock();
    const QString connection_name = QStringLiteral("nu_explorer_delta_rebuild_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    bool rebuild = highest >= 0;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery pragma(db);
            pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
            pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
            pragma.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));
            pragma.exec(QStringLiteral("PRAGMA cache_size=-131072"));

            QSqlQuery meta(db);
            meta.prepare(QStringLiteral("SELECT value FROM explorer_meta WHERE key = 'balance_deltas_height'"));
            if (meta.exec() && meta.next()) {
                rebuild = meta.value(0).toInt() < highest;
            }
            QSqlQuery count_query(db);
            count_query.prepare(QStringLiteral("SELECT value FROM explorer_meta WHERE key = 'indexed_output_count'"));
            qint64 indexed_output_count = -1;
            if (count_query.exec() && count_query.next()) {
                indexed_output_count = count_query.value(0).toLongLong();
            }
            if (indexed_output_count < 0 &&
                count_query.exec(QStringLiteral("SELECT COUNT(*) FROM explorer_tx_outputs")) &&
                count_query.next()) {
                indexed_output_count = count_query.value(0).toLongLong();
            }
            rebuild = rebuild && indexed_output_count > 0;

            ok = true;
            if (rebuild) {
                ok = db.transaction();
                if (!ok) local_error = db.lastError().text();
                QSqlQuery query(db);
                if (ok && !query.exec(QStringLiteral("DELETE FROM explorer_balance_deltas"))) {
                    ok = false;
                    local_error = query.lastError().text();
                }
                if (ok && !query.exec(QStringLiteral(
                        "INSERT INTO explorer_balance_deltas(height, address, delta_sats) "
                        "SELECT block_height, address, SUM(value_sats) "
                        "FROM explorer_tx_outputs "
                        "GROUP BY block_height, address "
                        "HAVING SUM(value_sats) != 0"))) {
                    ok = false;
                    local_error = query.lastError().text();
                }
                if (ok && !query.exec(QStringLiteral(
                        "INSERT INTO explorer_balance_deltas(height, address, delta_sats) "
                        "SELECT spent_in_height, address, -SUM(value_sats) "
                        "FROM explorer_tx_outputs "
                        "WHERE spent_in_height IS NOT NULL "
                        "GROUP BY spent_in_height, address "
                        "HAVING SUM(value_sats) != 0 "
                        "ON CONFLICT(height, address) DO UPDATE SET delta_sats = delta_sats + excluded.delta_sats"))) {
                    ok = false;
                    local_error = query.lastError().text();
                }
                if (ok) {
                    QSqlQuery meta_write(db);
                    meta_write.prepare(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('balance_deltas_height', ?)"));
                    meta_write.addBindValue(QString::number(highest));
                    if (!meta_write.exec()) {
                        ok = false;
                        local_error = meta_write.lastError().text();
                    }
                }
                if (ok) {
                    ok = db.commit();
                    if (!ok) local_error = db.lastError().text();
                } else {
                    db.rollback();
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok && error) *error = local_error;
    return ok;
}

void NuRpcService::cacheExplorerLookup(const QString& type,
                                       const QString& id,
                                       const QString& title,
                                       const QString& summary,
                                       const QJsonValue& raw_json)
{
    QString error;
    if (!ensureExplorerDatabase(&error)) {
        appendLaunchDiagnostic(error);
        return;
    }
    const QString connection_name = QStringLiteral("nu_explorer_write_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        ok = db.open();
        if (ok) {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "INSERT INTO explorer_lookups(type, id, title, summary, raw_json, cached_at) "
                "VALUES(?, ?, ?, ?, ?, ?) "
                "ON CONFLICT(type, id) DO UPDATE SET "
                "title=excluded.title, summary=excluded.summary, raw_json=excluded.raw_json, cached_at=excluded.cached_at"));
            query.addBindValue(type);
            query.addBindValue(id);
            query.addBindValue(title);
            query.addBindValue(summary);
            query.addBindValue(QString::fromUtf8(QJsonDocument(raw_json.toObject()).toJson(QJsonDocument::Compact)));
            query.addBindValue(QDateTime::currentSecsSinceEpoch());
            ok = query.exec();
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (ok) loadExplorerRecentLookups();
}

void NuRpcService::loadExplorerRecentLookups()
{
    QVariantList rows;
    QString error;
    if (ensureExplorerDatabase(&error)) {
        const QString connection_name = QStringLiteral("nu_explorer_read_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
        {
            QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
            db.setDatabaseName(explorerDatabasePath());
            if (db.open()) {
                QSqlQuery query(db);
                if (query.exec(QStringLiteral("SELECT type, id, title, summary, cached_at FROM explorer_lookups ORDER BY cached_at DESC LIMIT 50"))) {
                    while (query.next()) {
                        const QDateTime cached_at = QDateTime::fromSecsSinceEpoch(query.value(4).toLongLong()).toLocalTime();
                        rows.push_back(QVariantMap{
                            {QStringLiteral("type"), query.value(0).toString()},
                            {QStringLiteral("id"), query.value(1).toString()},
                            {QStringLiteral("title"), query.value(2).toString()},
                            {QStringLiteral("summary"), query.value(3).toString()},
                            {QStringLiteral("cached"), cached_at.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))},
                            {QStringLiteral("cells"), QVariantList{
                                query.value(0).toString(),
                                query.value(1).toString(),
                                query.value(2).toString(),
                                cached_at.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))}},
                            {QStringLiteral("meta"), QVariantMap{{QStringLiteral("type"), query.value(0).toString()}, {QStringLiteral("id"), query.value(1).toString()}}}
                        });
                    }
                }
            }
            db.close();
        }
        QSqlDatabase::removeDatabase(connection_name);
    }
    m_explorer_recent_lookups = rows;
    Q_EMIT explorerChanged();
}

void NuRpcService::refreshExplorerRecentLookups()
{
    loadExplorerRecentLookups();
    m_explorer_indexed_block_count = explorerIndexedBlockCountFromDb();
    m_explorer_indexed_output_count = explorerIndexedOutputCountFromDb();
    if (!m_explorer_indexing) {
        const int highest = explorerHighestIndexedBlock();
        m_explorer_index_height = highest < 0 ? 0 : highest + 1;
        if (m_explorer_indexed_block_count > 0) {
            m_explorer_index_status = QStringLiteral("Index paused at block %1 with %2 blocks cached.")
                .arg(QString::number(highest), QString::number(m_explorer_indexed_block_count));
        }
    }
    Q_EMIT explorerChanged();
}

int NuRpcService::explorerHighestIndexedBlock() const
{
    QString error;
    if (!ensureExplorerDatabase(&error)) return -1;
    int highest = -1;
    const QString connection_name = QStringLiteral("nu_explorer_highest_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            if (query.exec(QStringLiteral("SELECT MAX(height) FROM explorer_blocks")) && query.next() && !query.value(0).isNull()) {
                highest = query.value(0).toInt();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    return highest;
}

qint64 NuRpcService::explorerMetaInteger(const QString& key, qint64 fallback) const
{
    if (key.isEmpty()) return fallback;
    QString error;
    if (!ensureExplorerDatabase(&error)) return fallback;
    qint64 value = fallback;
    const QString connection_name = QStringLiteral("nu_explorer_meta_int_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            query.prepare(QStringLiteral("SELECT value FROM explorer_meta WHERE key = ?"));
            query.addBindValue(key);
            if (query.exec() && query.next()) value = query.value(0).toLongLong();
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    return value;
}

int NuRpcService::explorerIndexedBlockCountFromDb() const
{
    const qint64 cached = explorerMetaInteger(QStringLiteral("indexed_block_count"), -1);
    if (cached >= 0) return static_cast<int>(std::min<qint64>(cached, std::numeric_limits<int>::max()));

    QString error;
    if (!ensureExplorerDatabase(&error)) return 0;
    int count = 0;
    const QString connection_name = QStringLiteral("nu_explorer_count_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            if (query.exec(QStringLiteral("SELECT COUNT(*) FROM explorer_blocks")) && query.next()) {
                count = query.value(0).toInt();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    return count;
}

int NuRpcService::explorerIndexedOutputCountFromDb() const
{
    const qint64 cached = explorerMetaInteger(QStringLiteral("indexed_output_count"), -1);
    if (cached >= 0) return static_cast<int>(std::min<qint64>(cached, std::numeric_limits<int>::max()));

    QString error;
    if (!ensureExplorerDatabase(&error)) return 0;
    int count = 0;
    const QString connection_name = QStringLiteral("nu_explorer_output_count_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            if (query.exec(QStringLiteral("SELECT COUNT(*) FROM explorer_tx_outputs")) && query.next()) {
                count = query.value(0).toInt();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    return count;
}

QVariantList NuRpcService::explorerRichListFromDb(QString* error) const
{
    QVariantList rows;
    QString db_error;
    if (!ensureExplorerDatabase(&db_error)) {
        if (error) *error = db_error;
        return rows;
    }

    qint64 total_unspent_sats = 0;
    int total_address_count = 0;
    const QString connection_name = QStringLiteral("nu_explorer_rich_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery total_query(db);
            if (total_query.exec(QStringLiteral(
                    "SELECT COALESCE(SUM(CASE WHEN spent_by_txid IS NULL THEN value_sats ELSE 0 END), 0) "
                    "FROM explorer_tx_outputs")) && total_query.next()) {
                total_unspent_sats = total_query.value(0).toLongLong();
            }

            QSqlQuery address_count_query(db);
            if (address_count_query.exec(QStringLiteral(
                    "SELECT COUNT(DISTINCT address) FROM explorer_tx_outputs WHERE address != ''")) &&
                address_count_query.next()) {
                total_address_count = address_count_query.value(0).toInt();
            }

            QSqlQuery query(db);
            if (!query.exec(QStringLiteral(
                    "SELECT address, "
                    "COALESCE(SUM(CASE WHEN spent_by_txid IS NULL THEN value_sats ELSE 0 END), 0) AS balance_sats, "
                    "COALESCE(SUM(value_sats), 0) AS received_sats, "
                    "COUNT(DISTINCT txid) AS tx_count, "
                    "COALESCE(SUM(CASE WHEN spent_by_txid IS NULL THEN 1 ELSE 0 END), 0) AS unspent_outputs "
                    "FROM explorer_tx_outputs "
                    "GROUP BY address "
                    "HAVING COALESCE(SUM(CASE WHEN spent_by_txid IS NULL THEN value_sats ELSE 0 END), 0) > 0 "
                    "ORDER BY balance_sats DESC, address ASC "
                    "LIMIT 100"))) {
                local_error = query.lastError().text();
            } else {
                int rank = 1;
                while (query.next()) {
                    const QString address = query.value(0).toString();
                    const qint64 balance_sats = query.value(1).toLongLong();
                    const qint64 received_sats = query.value(2).toLongLong();
                    const int tx_count = query.value(3).toInt();
                    const int unspent_outputs = query.value(4).toInt();
                    const double share = total_unspent_sats > 0
                        ? (100.0 * static_cast<double>(balance_sats) / static_cast<double>(total_unspent_sats))
                        : 0.0;
                    rows.push_back(QVariantMap{
                        {QStringLiteral("cells"), QVariantList{
                            explorerTop100Color(rank),
                            rank,
                            address,
                            explorerAmountText(balance_sats),
                            QString::number(share, 'f', 4) + QStringLiteral("%"),
                            explorerAmountText(received_sats),
                            tx_count,
                            unspent_outputs}},
                        {QStringLiteral("meta"), QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("address")},
                            {QStringLiteral("id"), address},
                            {QStringLiteral("address"), address},
                            {QStringLiteral("rank"), rank},
                            {QStringLiteral("color"), explorerTop100Color(rank)},
                            {QStringLiteral("balanceSats"), QVariant::fromValue<qlonglong>(balance_sats)},
                            {QStringLiteral("receivedSats"), QVariant::fromValue<qlonglong>(received_sats)},
                            {QStringLiteral("sharePercent"), share},
                            {QStringLiteral("totalUnspentSats"), QVariant::fromValue<qlonglong>(total_unspent_sats)},
                            {QStringLiteral("totalAddressCount"), total_address_count}}}
                    });
                    ++rank;
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!local_error.isEmpty() && error) *error = local_error;
    return rows;
}

QVariantList NuRpcService::explorerMovementsFromDb(qint64 threshold_sats, QString* error) const
{
    QVariantList rows;
    QString db_error;
    if (!ensureExplorerDatabase(&db_error)) {
        if (error) *error = db_error;
        return rows;
    }

    const qint64 bounded_threshold = std::max<qint64>(0, threshold_sats);
    const QString connection_name = QStringLiteral("nu_explorer_movements_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "SELECT o.txid, o.vout, o.block_height, b.time, o.value_sats, o.address "
                "FROM explorer_tx_outputs o INDEXED BY explorer_tx_outputs_block_value_address "
                "JOIN explorer_blocks b ON b.height = o.block_height "
                "JOIN explorer_block_transactions t ON t.txid = o.txid AND t.block_height = o.block_height "
                "WHERE t.tx_index > 0 AND o.value_sats >= ? AND o.address != '' "
                "ORDER BY o.block_height DESC "
                "LIMIT 5000"));
            query.addBindValue(QVariant::fromValue<qlonglong>(bounded_threshold));
            if (!query.exec()) {
                local_error = query.lastError().text();
            } else {
                QVector<QPair<qint64, int>> largest_candidates;
                QVector<int> newest_candidates;
                constexpr int graph_endpoint_cushion = 56;
                while (query.next()) {
                    const QString txid = query.value(0).toString();
                    const int vout = query.value(1).toInt();
                    const int height = query.value(2).toInt();
                    const qint64 time = query.value(3).toLongLong();
                    const qint64 amount_sats = query.value(4).toLongLong();
                    const QString target_address = query.value(5).toString();
                    QVariantList target_addresses;
                    if (!target_address.isEmpty())
                        target_addresses.push_back(target_address);
                    const QString timestamp = QDateTime::fromSecsSinceEpoch(time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"));
                    const int row_index = rows.size();
                    rows.push_back(QVariantMap{
                        {QStringLiteral("cells"), QVariantList{
                            txid,
	                            explorerAmountText(amount_sats),
	                            timestamp,
	                            height,
	                            1,
	                            1}},
	                        {QStringLiteral("meta"), QVariantMap{
	                            {QStringLiteral("type"), QStringLiteral("transaction")},
	                            {QStringLiteral("id"), txid},
	                            {QStringLiteral("txid"), txid},
	                            {QStringLiteral("vout"), vout},
	                            {QStringLiteral("height"), height},
	                            {QStringLiteral("time"), QVariant::fromValue<qlonglong>(time)},
	                            {QStringLiteral("amountSats"), QVariant::fromValue<qlonglong>(amount_sats)},
                            {QStringLiteral("sourceAddresses"), QVariantList{}},
                            {QStringLiteral("targetAddresses"), target_addresses}}}
                    });
                    if (newest_candidates.size() < graph_endpoint_cushion) newest_candidates.push_back(row_index);
                    largest_candidates.push_back(qMakePair(amount_sats, row_index));
                }
                query.finish();

                std::sort(largest_candidates.begin(), largest_candidates.end(), [](const QPair<qint64, int>& a, const QPair<qint64, int>& b) {
                    if (a.first != b.first) return a.first > b.first;
                    return a.second < b.second;
                });
                QVector<int> endpoint_rows;
                auto add_endpoint_row = [&endpoint_rows](int row_index) {
                    if (row_index < 0 || endpoint_rows.contains(row_index)) return;
                    endpoint_rows.push_back(row_index);
                };
                for (int i = 0; i < newest_candidates.size(); ++i)
                    add_endpoint_row(newest_candidates.at(i));
                const int largest_endpoint_count = std::min(graph_endpoint_cushion, static_cast<int>(largest_candidates.size()));
                for (int i = 0; i < largest_endpoint_count; ++i)
                    add_endpoint_row(largest_candidates.at(i).second);

                QSqlQuery source_query(db);
                const bool source_ok = source_query.prepare(QStringLiteral(
                    "SELECT address FROM explorer_tx_outputs "
                    "WHERE spent_by_txid = ? AND address != '' "
                    "GROUP BY address ORDER BY MAX(value_sats) DESC LIMIT 12"));
                if (!source_ok) {
                    local_error = source_query.lastError().text();
                } else {
                    for (int endpoint_index = 0; endpoint_index < endpoint_rows.size(); ++endpoint_index) {
                        const int row_index = endpoint_rows.at(endpoint_index);
                        if (row_index < 0 || row_index >= rows.size()) continue;
                        QVariantMap row = rows.at(row_index).toMap();
                        QVariantMap meta = row.value(QStringLiteral("meta")).toMap();
                        const QString txid = meta.value(QStringLiteral("txid")).toString();
                        if (txid.isEmpty()) continue;

                        QVariantList source_addresses;
                        source_query.bindValue(0, txid);
                        if (!source_query.exec()) {
                            local_error = source_query.lastError().text();
                            break;
                        }
                        while (source_query.next())
                            source_addresses.push_back(source_query.value(0).toString());
                        source_query.finish();

                        meta.insert(QStringLiteral("sourceAddresses"), source_addresses);
                        row.insert(QStringLiteral("meta"), meta);
                        rows[row_index] = row;
                    }
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!local_error.isEmpty() && error) *error = local_error;
    return rows;
}

QVariantMap NuRpcService::coindroidsAnalyticsFromCache(QString* error) const
{
    QVariantMap result;
    QString db_error;
    if (!ensureDroidTrailsDatabase(&db_error)) {
        if (error) *error = db_error;
        return result;
    }

    const int source_height = explorerHighestIndexedBlock();
    const int source_outputs = explorerIndexedOutputCountFromDb();
    const QString connection_name = QStringLiteral("nu_droidtails_read_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(droidTrailsDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "SELECT schema_version,source_height,source_outputs,payload_json "
                "FROM droidtails_cache WHERE cache_key='coindroids-analytics'"));
            if (!query.exec()) {
                local_error = query.lastError().text();
            } else if (query.next()) {
                const int schema_version = query.value(0).toInt();
                const int cached_height = query.value(1).toInt();
                const int cached_outputs = query.value(2).toInt();
                const QString payload = query.value(3).toString();
                if (schema_version == DROIDTRAILS_CACHE_SCHEMA_VERSION) {
                    QJsonParseError parse_error;
                    const QJsonDocument doc = QJsonDocument::fromJson(payload.toUtf8(), &parse_error);
                    if (parse_error.error != QJsonParseError::NoError || !doc.isObject()) {
                        local_error = QStringLiteral("Droid Trails cache JSON parse error: %1").arg(parse_error.errorString());
                    } else {
                        result = doc.object().toVariantMap();
                        QVariantMap summary = result.value(QStringLiteral("summary")).toMap();
                        summary.insert(QStringLiteral("droidTrailsCacheStatus"), QStringLiteral("hit"));
                        summary.insert(QStringLiteral("droidTrailsCacheVersion"), DROIDTRAILS_CACHE_SCHEMA_VERSION);
                        summary.insert(QStringLiteral("droidTrailsCachePath"), droidTrailsDatabasePath());
                        summary.insert(QStringLiteral("droidTrailsSourceHeight"), cached_height);
                        summary.insert(QStringLiteral("droidTrailsSourceOutputs"), cached_outputs);
                        summary.insert(QStringLiteral("droidTrailsCurrentSourceHeight"), source_height);
                        summary.insert(QStringLiteral("droidTrailsCurrentSourceOutputs"), source_outputs);
                        result.insert(QStringLiteral("summary"), summary);
                    }
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!result.isEmpty()) return result;
    if (!local_error.isEmpty() && error) *error = local_error;
    return {};
}

void NuRpcService::saveCoindroidsAnalyticsCache(const QVariantMap& analysis, QString* error) const
{
    if (analysis.isEmpty()) return;
    QString db_error;
    if (!ensureDroidTrailsDatabase(&db_error)) {
        if (error) *error = db_error;
        return;
    }

    const int source_height = explorerHighestIndexedBlock();
    const int source_outputs = explorerIndexedOutputCountFromDb();
    const QJsonDocument doc(QJsonObject::fromVariantMap(analysis));
    const QString connection_name = QStringLiteral("nu_droidtails_write_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    QString local_error;
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(droidTrailsDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "INSERT OR REPLACE INTO droidtails_cache("
                "cache_key,schema_version,source_height,source_outputs,payload_json,cached_at"
                ") VALUES('coindroids-analytics',?,?,?,?,?)"));
            query.addBindValue(DROIDTRAILS_CACHE_SCHEMA_VERSION);
            query.addBindValue(source_height);
            query.addBindValue(source_outputs);
            query.addBindValue(QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
            query.addBindValue(QDateTime::currentSecsSinceEpoch());
            ok = query.exec();
            if (!ok) local_error = query.lastError().text();
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok && error) *error = QStringLiteral("Could not save Droid Trails cache: %1").arg(local_error);
}

QVariantMap NuRpcService::coindroidsAnalyticsFromDb(QString* error) const
{
    QVariantMap result;
    QVariantMap summary;
    QVariantList window_rows;
    QVariantList endpoint_rows;
    QVariantList winner_rows;
    QVariantList phase_rows;
    QVariantList published_rows;
    QVariantList vanity_rows;
    QVariantList op_return_rows;
    QVariantList bot_rows;
    QVariantList payout_rows;
    QVariantList attack_address_rows;
    QVariantList qr_seed_rows;
    QVariantList source_ammo_rows;
    QVariantList olo_rows;
    QVariantList game_address_rows;
    QVariantList evidence_rows;
    QVariantMap dc25_chain_summary;
    QString db_error;
    if (!ensureExplorerDatabase(&db_error)) {
        if (error) *error = db_error;
        return result;
    }
    const QVariantMap cached = coindroidsAnalyticsFromCache();
    if (!cached.isEmpty()) return cached;

    auto row_for = [](const QVariantList& cells, const QVariantMap& meta = QVariantMap()) {
        QVariantMap row;
        row.insert(QStringLiteral("cells"), cells);
        row.insert(QStringLiteral("meta"), meta);
        return row;
    };
    auto add_game_address_lead = [&game_address_rows, &row_for](const QString& role,
                                                                const QString& name,
                                                                const QString& address,
                                                                const QString& amount,
                                                                int score,
                                                                const QString& confidence,
                                                                const QString& evidence,
                                                                const QVariantMap& extra_meta = QVariantMap()) {
        if (address.trimmed().isEmpty()) return;
        for (const QVariant& value : game_address_rows) {
            const QVariantMap row = value.toMap();
            const QVariantMap meta = row.value(QStringLiteral("meta")).toMap();
            if (meta.value(QStringLiteral("address")).toString() == address &&
                meta.value(QStringLiteral("role")).toString() == role &&
                meta.value(QStringLiteral("name")).toString() == name) {
                return;
            }
        }
        QVariantMap meta = extra_meta;
        meta.insert(QStringLiteral("type"), QStringLiteral("address"));
        meta.insert(QStringLiteral("id"), address);
        meta.insert(QStringLiteral("address"), address);
        meta.insert(QStringLiteral("role"), role);
        meta.insert(QStringLiteral("name"), name);
        meta.insert(QStringLiteral("score"), score);
        meta.insert(QStringLiteral("confidence"), confidence);
        meta.insert(QStringLiteral("contactName"),
                    QStringLiteral("Coindroids %1 %2 [%3]")
                        .arg(role, name.isEmpty() ? address.left(10) : name, confidence));
        game_address_rows.push_back(row_for(QVariantList{
            role,
            name,
            address,
            amount,
            score,
            confidence,
            evidence
        }, meta));
    };

    auto decimal_dfc_text = [](const QVariant& value, int decimals = 4) {
        const double amount = value.toDouble();
        QString text = QString::number(amount, 'f', decimals);
        while (text.contains(QLatin1Char('.')) && text.endsWith(QLatin1Char('0'))) text.chop(1);
        if (text.endsWith(QLatin1Char('.'))) text.chop(1);
        return text + QStringLiteral(" DFC");
    };
    auto decimal_text = [](const QVariant& value, int decimals = 3) {
        QString text = QString::number(value.toDouble(), 'f', decimals);
        while (text.contains(QLatin1Char('.')) && text.endsWith(QLatin1Char('0'))) text.chop(1);
        if (text.endsWith(QLatin1Char('.'))) text.chop(1);
        return text;
    };

    {
        const QString relative_path = QStringLiteral("assets/data/coindroids_dc25_chain_forensics.json");
        QStringList candidates;
        candidates << QDir(nuResourceRoot()).filePath(relative_path)
                   << QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("nu/%1").arg(relative_path))
                   << QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("../Resources/nu/%1").arg(relative_path))
                   << QStringLiteral(":/nu/assets/data/coindroids_dc25_chain_forensics.json");

        QFile file;
        for (const QString& candidate : candidates) {
            file.setFileName(candidate);
            if (file.open(QIODevice::ReadOnly | QIODevice::Text))
                break;
        }

        if (file.isOpen()) {
            QJsonParseError parse_error;
            const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parse_error);
            if (parse_error.error == QJsonParseError::NoError && doc.isObject()) {
                const QJsonObject object = doc.object();
                dc25_chain_summary = object.value(QStringLiteral("summary")).toObject().toVariantMap();
                dc25_chain_summary.insert(QStringLiteral("dc25ChainForensicsStatus"), QStringLiteral("loaded"));

                const QJsonArray qr_array = object.value(QStringLiteral("qrSeeds")).toArray();
                for (const QJsonValue& value : qr_array) {
                    const QVariantMap source = value.toObject().toVariantMap();
                    const QString name = source.value(QStringLiteral("droid_name")).toString();
                    const QString legacy = source.value(QStringLiteral("legacy_3_p2sh")).toString();
                    const QString current = source.value(QStringLiteral("current_m_p2sh")).toString();
                    const int dc25_outputs = source.value(QStringLiteral("dc25_outputs")).toInt();
                    const int photo_outputs = source.value(QStringLiteral("photo_window_outputs")).toInt();
                    const QString evidence = QStringLiteral("QR card seed converted from legacy P2SH %1; %2 DC25 outputs and %3 photo-window outputs.")
                        .arg(legacy, QString::number(dc25_outputs), QString::number(photo_outputs));
                    qr_seed_rows.push_back(row_for(QVariantList{
                        name,
                        legacy,
                        current,
                        dc25_outputs,
                        decimal_dfc_text(source.value(QStringLiteral("dc25_dfc")), 8),
                        photo_outputs,
                        decimal_dfc_text(source.value(QStringLiteral("photo_window_dfc")), 8),
                        QStringLiteral("%1-%2").arg(source.value(QStringLiteral("dc25_first_height")).toString(),
                                                    source.value(QStringLiteral("dc25_last_height")).toString()),
                        QStringLiteral("%1 - %2").arg(source.value(QStringLiteral("dc25_first_utc")).toString(),
                                                      source.value(QStringLiteral("dc25_last_utc")).toString())
                    }, QVariantMap{
                        {QStringLiteral("type"), QStringLiteral("address")},
                        {QStringLiteral("id"), current},
                        {QStringLiteral("address"), current},
                        {QStringLiteral("legacyP2sh"), legacy},
                        {QStringLiteral("name"), name},
                        {QStringLiteral("dc25Outputs"), dc25_outputs},
                        {QStringLiteral("photoWindowOutputs"), photo_outputs},
                        {QStringLiteral("dc25Dfc"), source.value(QStringLiteral("dc25_dfc"))},
                        {QStringLiteral("confidence"), QStringLiteral("Seed-confirmed")}}));
                    add_game_address_lead(QStringLiteral("DC25 QR-confirmed attack address"), name, current,
                                          decimal_dfc_text(source.value(QStringLiteral("dc25_dfc")), 4),
                                          92, QStringLiteral("Seed-confirmed"), evidence,
                                          QVariantMap{
                                              {QStringLiteral("source"), QStringLiteral("dc25-qr-seed-converted")},
                                              {QStringLiteral("legacyP2sh"), legacy},
                                              {QStringLiteral("dc25Outputs"), dc25_outputs},
                                              {QStringLiteral("photoWindowOutputs"), photo_outputs}});
                }

                const QJsonArray attack_array = object.value(QStringLiteral("attackAddresses")).toArray();
                for (const QJsonValue& value : attack_array) {
                    const QVariantMap source = value.toObject().toVariantMap();
                    const QString name = source.value(QStringLiteral("known_droid_name")).toString();
                    const QString legacy = source.value(QStringLiteral("legacy_3_p2sh")).toString();
                    const QString current = source.value(QStringLiteral("current_m_p2sh")).toString();
                    const int dc25_outputs = source.value(QStringLiteral("dc25_outputs")).toInt();
                    const int signature_outputs = source.value(QStringLiteral("signature_outputs")).toInt();
                    const double signature_ratio = source.value(QStringLiteral("signature_ratio")).toDouble();
                    const QString confidence = source.value(QStringLiteral("confidence")).toString();
                    const QString role = confidence.contains(QStringLiteral("Broad"))
                        ? QStringLiteral("DC25 broad attack cohort")
                        : (confidence.contains(QStringLiteral("Seed"))
                               ? QStringLiteral("DC25 QR-confirmed attack address")
                               : QStringLiteral("DC25 attack candidate"));
                    int score = 45 + std::min(34, static_cast<int>(signature_ratio * 34.0)) + std::min(15, dc25_outputs / 70);
                    if (confidence.contains(QStringLiteral("Seed"))) score += 10;
                    if (confidence.contains(QStringLiteral("Broad"))) score -= 8;
                    score = std::max(20, std::min(99, score));
                    const QString display_name = name.isEmpty() ? QStringLiteral("candidate %1").arg(current.left(8)) : name;
                    const QString evidence = QStringLiteral("%1 DC25 outputs, %2 signature outputs, ratio %3; legacy QR/P2SH form %4.")
                        .arg(QString::number(dc25_outputs),
                             QString::number(signature_outputs),
                             decimal_text(source.value(QStringLiteral("signature_ratio")), 3),
                             legacy);
                    attack_address_rows.push_back(row_for(QVariantList{
                        display_name,
                        legacy,
                        current,
                        dc25_outputs,
                        decimal_dfc_text(source.value(QStringLiteral("dc25_dfc")), 8),
                        signature_outputs,
                        decimal_text(source.value(QStringLiteral("signature_ratio")), 3),
                        QStringLiteral("%1-%2").arg(source.value(QStringLiteral("first_height")).toString(),
                                                    source.value(QStringLiteral("last_height")).toString()),
                        confidence
                    }, QVariantMap{
                        {QStringLiteral("type"), QStringLiteral("address")},
                        {QStringLiteral("id"), current},
                        {QStringLiteral("address"), current},
                        {QStringLiteral("legacyP2sh"), legacy},
                        {QStringLiteral("name"), display_name},
                        {QStringLiteral("knownName"), name},
                        {QStringLiteral("dc25Outputs"), dc25_outputs},
                        {QStringLiteral("dc25Dfc"), source.value(QStringLiteral("dc25_dfc"))},
                        {QStringLiteral("signatureOutputs"), signature_outputs},
                        {QStringLiteral("signatureDfc"), source.value(QStringLiteral("signature_dfc"))},
                        {QStringLiteral("signatureRatio"), signature_ratio},
                        {QStringLiteral("minDfc"), source.value(QStringLiteral("min_dfc"))},
                        {QStringLiteral("avgDfc"), source.value(QStringLiteral("avg_dfc"))},
                        {QStringLiteral("maxDfc"), source.value(QStringLiteral("max_dfc"))},
                        {QStringLiteral("firstHeight"), source.value(QStringLiteral("first_height"))},
                        {QStringLiteral("lastHeight"), source.value(QStringLiteral("last_height"))},
                        {QStringLiteral("confidence"), confidence},
                        {QStringLiteral("score"), score}}));
                    add_game_address_lead(role, display_name, current,
                                          decimal_dfc_text(source.value(QStringLiteral("dc25_dfc")), 4),
                                          score, confidence, evidence,
                                          QVariantMap{
                                              {QStringLiteral("source"), QStringLiteral("dc25-attack-address-csv")},
                                              {QStringLiteral("legacyP2sh"), legacy},
                                              {QStringLiteral("dc25Outputs"), dc25_outputs},
                                              {QStringLiteral("signatureOutputs"), signature_outputs},
                                              {QStringLiteral("signatureRatio"), signature_ratio}});
                }

                const QJsonArray source_array = object.value(QStringLiteral("sourceAmmo")).toArray();
                for (const QJsonValue& value : source_array) {
                    const QVariantMap source = value.toObject().toVariantMap();
                    const QString address = source.value(QStringLiteral("source_address")).toString();
                    const int attack_txs = source.value(QStringLiteral("attack_txs")).toInt();
                    const int input_utxos = source.value(QStringLiteral("input_utxos")).toInt();
                    const int targets = source.value(QStringLiteral("distinct_targets")).toInt();
                    int score = 34 + std::min(35, attack_txs / 20) + std::min(25, targets);
                    if (attack_txs >= 50) score += 8;
                    score = std::max(20, std::min(99, score));
                    const QString evidence = QStringLiteral("%1 attack txs, %2 input UTXOs, %3 distinct attack targets; source blocks %4-%5.")
                        .arg(QString::number(attack_txs),
                             QString::number(input_utxos),
                             QString::number(targets),
                             source.value(QStringLiteral("first_source_output_height")).toString(),
                             source.value(QStringLiteral("last_source_output_height")).toString());
                    source_ammo_rows.push_back(row_for(QVariantList{
                        address,
                        attack_txs,
                        input_utxos,
                        targets,
                        decimal_dfc_text(source.value(QStringLiteral("input_dfc")), 8),
                        QStringLiteral("%1-%2").arg(source.value(QStringLiteral("first_source_output_height")).toString(),
                                                    source.value(QStringLiteral("last_source_output_height")).toString()),
                        score
                    }, QVariantMap{
                        {QStringLiteral("type"), QStringLiteral("address")},
                        {QStringLiteral("id"), address},
                        {QStringLiteral("address"), address},
                        {QStringLiteral("attackTxs"), attack_txs},
                        {QStringLiteral("inputUtxos"), input_utxos},
                        {QStringLiteral("distinctTargets"), targets},
                        {QStringLiteral("inputDfc"), source.value(QStringLiteral("input_dfc"))},
                        {QStringLiteral("firstHeight"), source.value(QStringLiteral("first_source_output_height"))},
                        {QStringLiteral("lastHeight"), source.value(QStringLiteral("last_source_output_height"))},
                        {QStringLiteral("score"), score},
                        {QStringLiteral("confidence"), attack_txs >= 50 ? QStringLiteral("High source lead") : QStringLiteral("Source lead")}}));
                    add_game_address_lead(QStringLiteral("DC25 source/ammo clip"), QStringLiteral("source %1").arg(address.left(8)), address,
                                          decimal_dfc_text(source.value(QStringLiteral("input_dfc")), 2),
                                          score, attack_txs >= 50 ? QStringLiteral("High source lead") : QStringLiteral("Source lead"),
                                          evidence,
                                          QVariantMap{
                                              {QStringLiteral("source"), QStringLiteral("dc25-source-ammo-csv")},
                                              {QStringLiteral("attackTxs"), attack_txs},
                                              {QStringLiteral("inputUtxos"), input_utxos},
                                              {QStringLiteral("distinctTargets"), targets}});
                }

                const QJsonArray olo_array = object.value(QStringLiteral("oloCandidates")).toArray();
                for (const QJsonValue& value : olo_array) {
                    const QVariantMap source = value.toObject().toVariantMap();
                    const QString legacy = source.value(QStringLiteral("legacy_3_p2sh")).toString();
                    const QString current = source.value(QStringLiteral("current_m_p2sh")).toString();
                    const QString evidence = source.value(QStringLiteral("evidence_type")).toString();
                    olo_rows.push_back(row_for(QVariantList{
                        QStringLiteral("Olo"),
                        legacy,
                        current,
                        source.value(QStringLiteral("dc25_outputs")).toInt(),
                        decimal_dfc_text(source.value(QStringLiteral("dc25_dfc")), 8),
                        source.value(QStringLiteral("signature_outputs")).toInt(),
                        decimal_text(source.value(QStringLiteral("signature_ratio")), 3),
                        source.value(QStringLiteral("status")).toString().isEmpty()
                            ? QStringLiteral("Accepted DC25 lead")
                            : source.value(QStringLiteral("status")).toString(),
                        source.value(QStringLiteral("notes")).toString()
                    }, QVariantMap{
                        {QStringLiteral("type"), QStringLiteral("address")},
                        {QStringLiteral("id"), current},
                        {QStringLiteral("address"), current},
                        {QStringLiteral("legacyP2sh"), legacy},
                        {QStringLiteral("name"), QStringLiteral("Olo")},
                        {QStringLiteral("dc25Outputs"), source.value(QStringLiteral("dc25_outputs")).toInt()},
                        {QStringLiteral("dc25Dfc"), source.value(QStringLiteral("dc25_dfc"))},
                        {QStringLiteral("signatureOutputs"), source.value(QStringLiteral("signature_outputs")).toInt()},
                        {QStringLiteral("signatureRatio"), source.value(QStringLiteral("signature_ratio")).toDouble()},
                        {QStringLiteral("evidence"), evidence},
                        {QStringLiteral("confidence"), QStringLiteral("Accepted DC25 lead")}}));
                    add_game_address_lead(QStringLiteral("DC25 Olo lead"), QStringLiteral("Olo"), current,
                                          decimal_dfc_text(source.value(QStringLiteral("dc25_dfc")), 4),
                                          84, QStringLiteral("Accepted DC25 lead"),
                                          evidence,
                                          QVariantMap{
                                              {QStringLiteral("source"), QStringLiteral("dc25-olo-image-assisted")},
                                              {QStringLiteral("legacyP2sh"), legacy}});
                }
            } else {
                dc25_chain_summary.insert(QStringLiteral("dc25ChainForensicsStatus"),
                                          QStringLiteral("parse error: %1").arg(parse_error.errorString()));
            }
        } else {
            dc25_chain_summary.insert(QStringLiteral("dc25ChainForensicsStatus"), QStringLiteral("bundled data unavailable"));
        }
    }

    phase_rows.push_back(row_for(QVariantList{
        QStringLiteral("2014 on-chain response era"),
        QStringLiteral("2014-08-12"),
        QStringLiteral("DEF CON 22 launch"),
        QStringLiteral("0.01 DFC registration returns and cosmetic battle-response outputs encoded visible game stats."),
        QStringLiteral("High: vanity response detector")
    }, QVariantMap{
        {QStringLiteral("phase"), QStringLiteral("2014-response")},
        {QStringLiteral("date"), QStringLiteral("2014-08-12")},
        {QStringLiteral("sourceUrl"), QStringLiteral("https://blog.coindroids.com/introducing-coindroids-2014/")}}));
    phase_rows.push_back(row_for(QVariantList{
        QStringLiteral("Dust to OP_RETURN / mempool shift"),
        QStringLiteral("2017-07-25"),
        QStringLiteral("Mempool endpoint and later metadata model"),
        QStringLiteral("Early blocks need exact fractional output analysis; later blocks must preserve OP_RETURN payloads because semantic action data can move out of the DFC amount."),
        QStringLiteral("Pivot: amount first, payload later")
    }, QVariantMap{
        {QStringLiteral("phase"), QStringLiteral("2017-mempool")},
        {QStringLiteral("date"), QStringLiteral("2017-07-25")},
        {QStringLiteral("sourceUrl"), QStringLiteral("https://blog.coindroids.com/defcoin-mempool-support-added/")}}));
    phase_rows.push_back(row_for(QVariantList{
        QStringLiteral("Purse renamed to Bounty"),
        QStringLiteral("2017-08-11"),
        QStringLiteral("Terminology / API transition"),
        QStringLiteral("Published status showed backend, API, frontend, documentation, and guides moving at different speeds through the 2017-10-01 update."),
        QStringLiteral("Normalize terms, preserve raw labels")
    }, QVariantMap{
        {QStringLiteral("phase"), QStringLiteral("2017-bounty")},
        {QStringLiteral("date"), QStringLiteral("2017-08-11")},
        {QStringLiteral("sourceUrl"), QStringLiteral("https://blog.coindroids.com/upcoming-change-purse-to-bounty/")}}));
    phase_rows.push_back(row_for(QVariantList{
        QStringLiteral("docker-droid automation era"),
        QStringLiteral("2019-08-18"),
        QStringLiteral("DEF CON 27 recap"),
        QStringLiteral("Coindroids documented docker-droid, a bootstrapped Defcoin client with bot tooling, making automation an explicit part of the culture."),
        QStringLiteral("Bot/reload candidates are neutral labels")
    }, QVariantMap{
        {QStringLiteral("phase"), QStringLiteral("2019-automation")},
        {QStringLiteral("date"), QStringLiteral("2019-08-18")},
        {QStringLiteral("sourceUrl"), QStringLiteral("https://blog.coindroids.com/coindroids-defcon-27/")}}));

    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("DEF CON 25 network share"),
        QStringLiteral("2017-08-08 recap"),
        QStringLiteral("71%"),
        QStringLiteral("Published share of all Defcoin network transactions during DEF CON 25.")
    }));
    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("DEF CON 25 attacks"),
        QStringLiteral("2017-08-08 recap"),
        QStringLiteral("3,233 attacks / 126.664 DFC"),
        QStringLiteral("Published action count and attack volume for the Defcoin realm.")
    }));
    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("DEF CON 25 item purchases"),
        QStringLiteral("2017-08-08 recap"),
        QStringLiteral("521 purchases / 0.803 DFC"),
        QStringLiteral("High count, low total value; health packs dominated purchase volume.")
    }));
    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("DEF CON 25 payouts"),
        QStringLiteral("2017-08-08 recap"),
        QStringLiteral("227.046 DFC"),
        QStringLiteral("Published total paid back out to players, including pre-existing bounty/purse value.")
    }));
    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("Published largest payout winner"),
        QStringLiteral("DEF CON 25"),
        QStringLiteral("ModemBot1138 - 100.0605 DFC"),
        QStringLiteral("Operator-published recap value; separate from the local launch-swarm recipient table.")
    }));
    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("Top Droid prize winner"),
        QStringLiteral("DEF CON 25"),
        QStringLiteral("Bob"),
        QStringLiteral("Won by largest final purse/bounty at the cutoff, not by largest total payout.")
    }));
    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("DEF CON 27 network share"),
        QStringLiteral("2019-08-18 recap"),
        QStringLiteral("74%"),
        QStringLiteral("Published share of the Defcoin network in the docker-droid automation era.")
    }));
    published_rows.push_back(row_for(QVariantList{
        QStringLiteral("DEF CON 27 winner"),
        QStringLiteral("2019-08-18 recap"),
        QStringLiteral("Ballhair"),
        QStringLiteral("Published event winner; DETH-MASHENE was an honorable mention and bot-code catalyst.")
    }));

    add_game_address_lead(QStringLiteral("DC25 QR seed"), QStringLiteral("an0n"),
                          QStringLiteral("MSL4CPocyHsDBwn1qoEzq5ESEusNXyjps5"),
                          QStringLiteral("Human card"), 35, QStringLiteral("Seed"),
                          QStringLiteral("Decoded from the public DC25 Human droid card image; legacy 3... P2SH form converted to the indexed M... address."),
                          QVariantMap{{QStringLiteral("legacyP2sh"), QStringLiteral("3L7utWPf2B1nPSW7jvFf1Rz2vDGvVcp2y1")}});
    add_game_address_lead(QStringLiteral("DC25 QR seed"), QStringLiteral("jklol_b0t"),
                          QStringLiteral("MMvkAH6WRx2QCDyMCaqTUNcY2bbfB8oakY"),
                          QStringLiteral("Human card"), 35, QStringLiteral("Seed"),
                          QStringLiteral("Decoded from the public DC25 Human droid card image; legacy 3... P2SH form converted to the indexed M... address."),
                          QVariantMap{{QStringLiteral("legacyP2sh"), QStringLiteral("3FibrPgYUqAyPihT6hr7ejN8hu1DEvYDT1")}});
    add_game_address_lead(QStringLiteral("DC25 QR seed"), QStringLiteral("Ax0n"),
                          QStringLiteral("MHscJrLV2LbobKNfRgFNZywKcFLfyaMtMH"),
                          QStringLiteral("Human card"), 35, QStringLiteral("Seed"),
                          QStringLiteral("Decoded from the public DC25 Human droid card image; legacy 3... P2SH form converted to the indexed M... address."),
                          QVariantMap{{QStringLiteral("legacyP2sh"), QStringLiteral("3BfTzxvX5DkNnp6mKoG2kLgvHYkE2Mec8T")}});
    add_game_address_lead(QStringLiteral("DC25 QR seed"), QStringLiteral("xan"),
                          QStringLiteral("MCMWstrBmosLWiS9Em4hV5jYviBFaKvrrg"),
                          QStringLiteral("Human card"), 35, QStringLiteral("Seed"),
                          QStringLiteral("Decoded from the public DC25 Human droid card image; legacy 3... P2SH form converted to the indexed M... address."),
                          QVariantMap{{QStringLiteral("legacyP2sh"), QStringLiteral("369Na1SDph1uiDAF8t5MfSV9c1aobbdt3Q")}});
    add_game_address_lead(QStringLiteral("DC25 QR seed"), QStringLiteral("Def-crunch"),
                          QStringLiteral("MTeggkYKzmwts4tuGfMRZQx7Rk842gcKsL"),
                          QStringLiteral("Human card"), 35, QStringLiteral("Seed"),
                          QStringLiteral("Decoded from the public DC25 Human droid card image; legacy 3... P2SH form converted to the indexed M... address."),
                          QVariantMap{{QStringLiteral("legacyP2sh"), QStringLiteral("3MSYNs8N3f6U4Zd1AnN5jmhi73Xc52etzd")}});
    add_game_address_lead(QStringLiteral("DC25 QR seed"), QStringLiteral("nekodroid"),
                          QStringLiteral("MLcZtx8smqFWJ83PKh5XJ19KBbjWHGZaoP"),
                          QStringLiteral("Human card"), 35, QStringLiteral("Seed"),
                          QStringLiteral("Decoded from the public DC25 Human droid card image; legacy 3... P2SH form converted to the indexed M... address."),
                          QVariantMap{{QStringLiteral("legacyP2sh"), QStringLiteral("3EQRb4iupiQ5VcmVDp6BUMturu94Me87us")}});
    add_game_address_lead(QStringLiteral("DC25 QR seed"), QStringLiteral("Slick-Willy1"),
                          QStringLiteral("MJNT1e2PviEyxYytTE8zRciMResD4RHiUL"),
                          QStringLiteral("Human card"), 35, QStringLiteral("Seed"),
                          QStringLiteral("Decoded from the public DC25 Human droid card image; legacy 3... P2SH form converted to the indexed M... address."),
                          QVariantMap{{QStringLiteral("legacyP2sh"), QStringLiteral("3CAJhkcRybPZA3hzMM9ebyTx6xGm3fG67Z")}});

    auto classify_endpoint = [](qint64 value_sats, int outputs) {
        if (value_sats == 1000000) {
            return outputs >= 50
                ? QStringLiteral("0.01 DFC action hub")
                : QStringLiteral("0.01 DFC action candidate");
        }
        if (value_sats == 13370000) return QStringLiteral("0.1337 DFC payout/spillage recipient");
        if (value_sats == 100000000) return QStringLiteral("1.00 DFC battle/purse endpoint");
        if (value_sats == 23000000 || value_sats == 46000000) return QStringLiteral("repeated item/action amount");
        return QStringLiteral("action-range endpoint");
    };

    const QString windows_cte = QString::fromLatin1(R"SQL(
WITH windows(label,short_label,start_h,end_h,sort_order) AS (
  VALUES
    ('DEF CON 22 launch [Rio Hotel & Casino]','DC22',109943,111441,1),
    ('DEF CON 23 [Paris Hotel and Bally''s Hotel]','DC23',299028,301643,2),
    ('DEF CON 24 [Paris Hotel and Bally''s Hotel]','DC24',538696,541310,3),
    ('DEF CON 25 return [Caesars Palace]','DC25',736611,739117,4),
    ('DEF CON 26 return [Caesars Palace]','DC26',901949,904119,5),
    ('DEF CON 27 return [Paris, Ballys, Flamingo & Planet Hollywood hotels]','DC27',1115166,1117682,6),
    ('DEF CON 28 Safe Mode [Virtual Event]','DC28',1281336,1282012,7)
)
)SQL");

    QString local_error;
    qint64 total_action_outputs = 0;
    qint64 total_action_txs = 0;
    qint64 total_action_addresses = 0;
    qint64 total_action_sats = 0;
    qint64 launch_001_outputs = 0;
    qint64 launch_1337_outputs = 0;
    qint64 launch_1337_sats = 0;
    qint64 launch_1337_recipients = 0;
    QString largest_winner_address;
    qint64 largest_winner_sats = 0;
    int largest_winner_ties = 0;
    QString strongest_window_label;
    qint64 strongest_window_sats = 0;
    qint64 strongest_window_outputs = 0;

    const QString connection_name = QStringLiteral("nu_coindroids_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery pragma(db);
            pragma.exec(QStringLiteral("PRAGMA query_only=ON"));
            pragma.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));

            QSqlQuery window_query(db);
            if (!window_query.exec(windows_cte + QString::fromLatin1(R"SQL(
, rows AS (
  SELECT w.label,w.short_label,w.start_h,w.end_h,w.sort_order,o.txid,o.address,o.value_sats
  FROM windows w
  JOIN explorer_tx_outputs o ON o.block_height BETWEEN w.start_h AND w.end_h AND o.address != ''
), action_range AS (
  SELECT label,short_label,sort_order,start_h,end_h,COUNT(*) outputs,COUNT(DISTINCT txid) txs,
         COUNT(DISTINCT address) addresses,COALESCE(SUM(value_sats),0) sats
  FROM rows
  WHERE value_sats BETWEEN 100000 AND 314159265
  GROUP BY label,short_label,sort_order,start_h,end_h
), exact001 AS (
  SELECT label,COUNT(*) outputs,COUNT(DISTINCT address) addresses
  FROM rows WHERE value_sats=1000000 GROUP BY label
), exact1337 AS (
  SELECT label,COUNT(*) outputs,COUNT(DISTINCT address) addresses,COALESCE(SUM(value_sats),0) sats
  FROM rows WHERE value_sats=13370000 GROUP BY label
)
SELECT w.label,w.short_label,w.start_h,w.end_h,COALESCE(sb.time,0),COALESCE(eb.time,0),
       COALESCE(a.outputs,0),COALESCE(a.txs,0),COALESCE(a.addresses,0),COALESCE(a.sats,0),
       COALESCE(e.outputs,0),COALESCE(e.addresses,0),
       COALESCE(s.outputs,0),COALESCE(s.addresses,0),COALESCE(s.sats,0)
FROM windows w
LEFT JOIN action_range a ON a.label=w.label
LEFT JOIN exact001 e ON e.label=w.label
LEFT JOIN exact1337 s ON s.label=w.label
LEFT JOIN explorer_blocks sb ON sb.height=w.start_h
LEFT JOIN explorer_blocks eb ON eb.height=w.end_h
ORDER BY w.sort_order
)SQL"))) {
                local_error = window_query.lastError().text();
            } else {
                while (window_query.next()) {
                    const QString label = window_query.value(0).toString();
                    const QString short_label = window_query.value(1).toString();
                    const int start_height = window_query.value(2).toInt();
                    const int end_height = window_query.value(3).toInt();
                    const qint64 start_time = window_query.value(4).toLongLong();
                    const qint64 end_time = window_query.value(5).toLongLong();
                    const qint64 action_outputs = window_query.value(6).toLongLong();
                    const qint64 action_txs = window_query.value(7).toLongLong();
                    const qint64 action_addresses = window_query.value(8).toLongLong();
                    const qint64 action_sats = window_query.value(9).toLongLong();
                    const qint64 exact001_outputs = window_query.value(10).toLongLong();
                    const qint64 exact001_addresses = window_query.value(11).toLongLong();
                    const qint64 exact1337_outputs = window_query.value(12).toLongLong();
                    const qint64 exact1337_addresses = window_query.value(13).toLongLong();
                    const qint64 exact1337_sats = window_query.value(14).toLongLong();
                    const QString date_range = explorerDateRangeText(start_time, end_time);
                    total_action_outputs += action_outputs;
                    total_action_txs += action_txs;
                    total_action_addresses += action_addresses;
                    total_action_sats += action_sats;
                    if (short_label == QLatin1String("DC22")) {
                        launch_001_outputs = exact001_outputs;
                        launch_1337_outputs = exact1337_outputs;
                        launch_1337_sats = exact1337_sats;
                        launch_1337_recipients = exact1337_addresses;
                    }
                    if (action_sats > strongest_window_sats) {
                        strongest_window_sats = action_sats;
                        strongest_window_outputs = action_outputs;
                        strongest_window_label = label;
                    }
                    const QString signal = exact1337_outputs > 0
                        ? QStringLiteral("strong payout swarm")
                        : (exact001_outputs >= 40 ? QStringLiteral("0.01 action cluster") : QStringLiteral("background candidates"));
                    window_rows.push_back(row_for(QVariantList{
                        label,
                        QStringLiteral("%1-%2").arg(QString::number(start_height), QString::number(end_height)),
                        date_range,
                        QVariant::fromValue<qlonglong>(action_outputs),
                        QVariant::fromValue<qlonglong>(action_txs),
                        QVariant::fromValue<qlonglong>(action_addresses),
                        roundedExplorerAmountText(action_sats),
                        QVariant::fromValue<qlonglong>(exact001_outputs),
                        QVariant::fromValue<qlonglong>(exact1337_outputs),
                        signal
                    }, QVariantMap{
                        {QStringLiteral("label"), label},
                        {QStringLiteral("shortLabel"), short_label},
                        {QStringLiteral("startHeight"), start_height},
                        {QStringLiteral("endHeight"), end_height},
                        {QStringLiteral("startTime"), QVariant::fromValue<qlonglong>(start_time)},
                        {QStringLiteral("endTime"), QVariant::fromValue<qlonglong>(end_time)},
                        {QStringLiteral("dateRange"), date_range},
                        {QStringLiteral("actionOutputs"), QVariant::fromValue<qlonglong>(action_outputs)},
                        {QStringLiteral("actionTransactions"), QVariant::fromValue<qlonglong>(action_txs)},
                        {QStringLiteral("actionAddresses"), QVariant::fromValue<qlonglong>(action_addresses)},
                        {QStringLiteral("actionSats"), QVariant::fromValue<qlonglong>(action_sats)},
                        {QStringLiteral("exact001Outputs"), QVariant::fromValue<qlonglong>(exact001_outputs)},
                        {QStringLiteral("exact001Addresses"), QVariant::fromValue<qlonglong>(exact001_addresses)},
                        {QStringLiteral("exact1337Outputs"), QVariant::fromValue<qlonglong>(exact1337_outputs)},
                        {QStringLiteral("exact1337Addresses"), QVariant::fromValue<qlonglong>(exact1337_addresses)},
                        {QStringLiteral("exact1337Sats"), QVariant::fromValue<qlonglong>(exact1337_sats)}}));
                }
            }

            if (local_error.isEmpty()) {
                QSqlQuery endpoint_query(db);
                if (!endpoint_query.exec(windows_cte + QString::fromLatin1(R"SQL(
, endpoint_hits AS (
  SELECT w.label,w.sort_order,o.address,o.value_sats,COUNT(*) outputs,COUNT(DISTINCT o.txid) txs,
         MIN(o.block_height) first_h,MAX(o.block_height) last_h,COALESCE(SUM(o.value_sats),0) sats
  FROM windows w
  JOIN explorer_tx_outputs o ON o.block_height BETWEEN w.start_h AND w.end_h AND o.address != ''
  WHERE o.value_sats BETWEEN 100000 AND 314159265
  GROUP BY w.label,w.sort_order,o.address,o.value_sats
)
SELECT label,address,value_sats,outputs,txs,sats,first_h,last_h
FROM endpoint_hits
WHERE outputs >= 25 OR (sort_order=1 AND value_sats IN (1000000,13370000,23000000,46000000,100000000) AND outputs >= 5)
ORDER BY sort_order,outputs DESC,sats DESC,address ASC
LIMIT 200
)SQL"))) {
                    local_error = endpoint_query.lastError().text();
                } else {
                    while (endpoint_query.next()) {
                        const QString label = endpoint_query.value(0).toString();
                        const QString address = endpoint_query.value(1).toString();
                        const qint64 value_sats = endpoint_query.value(2).toLongLong();
                        const int outputs = endpoint_query.value(3).toInt();
                        const int txs = endpoint_query.value(4).toInt();
                        const qint64 sats = endpoint_query.value(5).toLongLong();
                        const int first_height = endpoint_query.value(6).toInt();
                        const int last_height = endpoint_query.value(7).toInt();
                        const QString kind = classify_endpoint(value_sats, outputs);
                        endpoint_rows.push_back(row_for(QVariantList{
                            kind,
                            label,
                            address,
                            roundedExplorerAmountText(value_sats),
                            outputs,
                            txs,
                            roundedExplorerAmountText(sats),
                            QStringLiteral("%1-%2").arg(QString::number(first_height), QString::number(last_height))
                        }, QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("address")},
                            {QStringLiteral("id"), address},
                            {QStringLiteral("kind"), kind},
                            {QStringLiteral("label"), label},
                            {QStringLiteral("address"), address},
                            {QStringLiteral("valueSats"), QVariant::fromValue<qlonglong>(value_sats)},
                            {QStringLiteral("outputs"), outputs},
                            {QStringLiteral("transactions"), txs},
                            {QStringLiteral("sats"), QVariant::fromValue<qlonglong>(sats)},
                            {QStringLiteral("firstHeight"), first_height},
                            {QStringLiteral("lastHeight"), last_height}}));
                        if ((outputs >= 100 || txs >= 50) && bot_rows.size() < 100) {
                            bot_rows.push_back(row_for(QVariantList{
                                QStringLiteral("Repeated endpoint / cadence candidate"),
                                address,
                                label,
                                roundedExplorerAmountText(value_sats),
                                outputs,
                                txs,
                                roundedExplorerAmountText(sats),
                                QStringLiteral("Same address and amount repeated across %1 blocks; could be attack target, item endpoint, or scripted play.")
                                    .arg(QString::number(std::max(1, last_height - first_height + 1)))
                            }, QVariantMap{
                                {QStringLiteral("type"), QStringLiteral("address")},
                                {QStringLiteral("id"), address},
                                {QStringLiteral("address"), address},
                                {QStringLiteral("label"), label},
                                {QStringLiteral("signal"), QStringLiteral("repeated-endpoint")},
                                {QStringLiteral("valueSats"), QVariant::fromValue<qlonglong>(value_sats)},
                                {QStringLiteral("outputs"), outputs},
                                {QStringLiteral("transactions"), txs},
                                {QStringLiteral("sats"), QVariant::fromValue<qlonglong>(sats)},
                                {QStringLiteral("firstHeight"), first_height},
                                {QStringLiteral("lastHeight"), last_height}}));
                        }
                    }
                }
            }

            if (local_error.isEmpty()) {
                QSqlQuery vanity_query(db);
                if (!vanity_query.exec(QString::fromLatin1(R"SQL(
WITH vanity(address,role,sort_order) AS (
  VALUES
    ('DAtkLvJg7ZoECzqhnv6yRLETsH3PTfoW1E','Atk level',1),
    ('DAtkHPuBm9TmAK3HGmz3LJaSgCSzjcemKY','Atk HP',2),
    ('DDfndLvCygu9jyv9eKF1tUQcAok5uMwoC2','Def level',3),
    ('DDfndHPWv9k3m2btAat9GQa74VUeQfaRui','Def HP',4),
    ('DAMAGEYxp2xwJkginsmiRvhQ8Jesu6dpKU','Damage',5),
    ('DCDAMGTzeNNLD8Gn5q9Ghdc3F1uyp21d8Z','Counter',6)
), hits AS (
  SELECT o.txid,o.block_height,b.time,v.role,v.sort_order,o.value_sats,o.value_text
  FROM explorer_tx_outputs o
  JOIN vanity v ON v.address=o.address
  LEFT JOIN explorer_blocks b ON b.height=o.block_height
)
SELECT txid,block_height,COALESCE(time,0),COUNT(DISTINCT role) roles,
       COUNT(*) outputs,COALESCE(SUM(value_sats),0) stat_sats,
       GROUP_CONCAT(role || '=' || value_sats, ' | ') decoded
FROM hits
GROUP BY txid,block_height,time
HAVING COUNT(DISTINCT role) >= 3
ORDER BY block_height ASC, roles DESC, outputs DESC
LIMIT 100
)SQL"))) {
                    local_error = vanity_query.lastError().text();
                } else {
                    while (vanity_query.next()) {
                        const QString txid = vanity_query.value(0).toString();
                        const int height = vanity_query.value(1).toInt();
                        const qint64 time = vanity_query.value(2).toLongLong();
                        const int roles = vanity_query.value(3).toInt();
                        const int outputs = vanity_query.value(4).toInt();
                        const qint64 stat_sats = vanity_query.value(5).toLongLong();
                        const QString decoded = vanity_query.value(6).toString();
                        const QString timestamp = time > 0
                            ? QDateTime::fromSecsSinceEpoch(time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
                            : QStringLiteral("date unavailable");
                        vanity_rows.push_back(row_for(QVariantList{
                            txid,
                            height,
                            timestamp,
                            roles,
                            outputs,
                            decoded,
                            roundedExplorerAmountText(stat_sats)
                        }, QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("transaction")},
                            {QStringLiteral("id"), txid},
                            {QStringLiteral("txid"), txid},
                            {QStringLiteral("height"), height},
                            {QStringLiteral("time"), QVariant::fromValue<qlonglong>(time)},
                            {QStringLiteral("roles"), roles},
                            {QStringLiteral("outputs"), outputs},
                            {QStringLiteral("statSats"), QVariant::fromValue<qlonglong>(stat_sats)},
                            {QStringLiteral("decoded"), decoded}}));
                    }
                }
            }

            if (local_error.isEmpty()) {
                QSqlQuery fanout_query(db);
                if (!fanout_query.exec(windows_cte + QString::fromLatin1(R"SQL(
, fanout_hits AS (
  SELECT w.label,o.txid,o.block_height,COALESCE(b.time,0) time,o.value_sats,
       COUNT(*) outputs,COUNT(DISTINCT o.address) addresses,COALESCE(SUM(o.value_sats),0) sats
  FROM windows w
  JOIN explorer_tx_outputs o ON o.block_height BETWEEN w.start_h AND w.end_h
  LEFT JOIN explorer_blocks b ON b.height=o.block_height
  WHERE o.address != '' AND o.value_sats BETWEEN 1 AND 314159265
  GROUP BY w.label,o.txid,o.block_height,b.time,o.value_sats
  HAVING outputs >= 25 AND addresses >= 10
)
SELECT label,txid,block_height,time,value_sats,outputs,addresses,sats
FROM fanout_hits
ORDER BY outputs DESC,sats DESC,block_height ASC
LIMIT 120
)SQL"))) {
                    local_error = fanout_query.lastError().text();
                } else {
                    while (fanout_query.next() && bot_rows.size() < 180) {
                        const QString label = fanout_query.value(0).toString();
                        const QString txid = fanout_query.value(1).toString();
                        const int height = fanout_query.value(2).toInt();
                        const qint64 time = fanout_query.value(3).toLongLong();
                        const qint64 value_sats = fanout_query.value(4).toLongLong();
                        const int outputs = fanout_query.value(5).toInt();
                        const int addresses = fanout_query.value(6).toInt();
                        const qint64 sats = fanout_query.value(7).toLongLong();
                        const QString timestamp = time > 0
                            ? QDateTime::fromSecsSinceEpoch(time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
                            : QStringLiteral("date unavailable");
                        bot_rows.push_back(row_for(QVariantList{
                            QStringLiteral("Fan-out / reload candidate"),
                            txid,
                            QStringLiteral("%1 block %2").arg(label, QString::number(height)),
                            roundedExplorerAmountText(value_sats),
                            outputs,
                            addresses,
                            roundedExplorerAmountText(sats),
                            QStringLiteral("%1 identical outputs in one transaction on %2.")
                                .arg(QString::number(outputs), timestamp)
                        }, QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("transaction")},
                            {QStringLiteral("id"), txid},
                            {QStringLiteral("txid"), txid},
                            {QStringLiteral("height"), height},
                            {QStringLiteral("time"), QVariant::fromValue<qlonglong>(time)},
                            {QStringLiteral("signal"), QStringLiteral("fanout-reload")},
                            {QStringLiteral("valueSats"), QVariant::fromValue<qlonglong>(value_sats)},
                            {QStringLiteral("outputs"), outputs},
                            {QStringLiteral("addresses"), addresses},
                            {QStringLiteral("sats"), QVariant::fromValue<qlonglong>(sats)}}));
                    }
                }
            }

            if (local_error.isEmpty()) {
                QSqlQuery op_return_query(db);
                if (!op_return_query.exec(QString::fromLatin1(R"SQL(
WITH windows(label,start_h,end_h,sort_order) AS (
  VALUES
    ('Post-pivot sample',736611,1117682,1),
    ('DEF CON 25 return [Caesars Palace]',736611,739117,2),
    ('DEF CON 26 return [Caesars Palace]',901949,904119,3),
    ('DEF CON 27 return [Paris, Ballys, Flamingo & Planet Hollywood hotels]',1115166,1117682,4)
)
SELECT o.txid,o.vout,o.block_height,COALESCE(b.time,0),w.label,o.value_sats,
       o.payload_hex,o.payload_text,LENGTH(o.payload_hex)/2 AS payload_bytes
FROM explorer_op_returns o
LEFT JOIN explorer_blocks b ON b.height=o.block_height
LEFT JOIN windows w ON o.block_height BETWEEN w.start_h AND w.end_h
WHERE o.block_height >= 736611
ORDER BY o.block_height ASC,o.txid ASC,o.vout ASC
LIMIT 160
)SQL"))) {
                    local_error = op_return_query.lastError().text();
                } else {
                    while (op_return_query.next()) {
                        const QString txid = op_return_query.value(0).toString();
                        const int vout = op_return_query.value(1).toInt();
                        const int height = op_return_query.value(2).toInt();
                        const qint64 time = op_return_query.value(3).toLongLong();
                        const QString label = op_return_query.value(4).toString().trimmed().isEmpty()
                            ? QStringLiteral("Post-pivot")
                            : op_return_query.value(4).toString();
                        const qint64 value_sats = op_return_query.value(5).toLongLong();
                        const QString payload_hex = op_return_query.value(6).toString();
                        const QString payload_text = op_return_query.value(7).toString();
                        const int payload_bytes = op_return_query.value(8).toInt();
                        const QString timestamp = time > 0
                            ? QDateTime::fromSecsSinceEpoch(time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
                            : QStringLiteral("date unavailable");
                        const QString preview = payload_text.isEmpty()
                            ? QStringLiteral("hex ") + payload_hex.left(96)
                            : payload_text;
                        op_return_rows.push_back(row_for(QVariantList{
                            txid,
                            vout,
                            height,
                            timestamp,
                            label,
                            payload_bytes,
                            roundedExplorerAmountText(value_sats),
                            preview
                        }, QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("transaction")},
                            {QStringLiteral("id"), txid},
                            {QStringLiteral("txid"), txid},
                            {QStringLiteral("vout"), vout},
                            {QStringLiteral("height"), height},
                            {QStringLiteral("time"), QVariant::fromValue<qlonglong>(time)},
                            {QStringLiteral("label"), label},
                            {QStringLiteral("payloadBytes"), payload_bytes},
                            {QStringLiteral("valueSats"), QVariant::fromValue<qlonglong>(value_sats)},
                            {QStringLiteral("payloadHex"), payload_hex},
                            {QStringLiteral("payloadText"), payload_text}}));
                    }
                }
            }

            if (local_error.isEmpty()) {
                QSqlQuery payout_query(db);
                if (!payout_query.exec(QString::fromLatin1(R"SQL(
WITH targets(name,target_sats,published_dfc,sort_order) AS (
  VALUES
    ('ModemBot1138',10006050000,'100.0605 DFC',1),
    ('LuckyBot',6011600000,'60.116 DFC',2),
    ('xan',1166000000,'11.660 DFC',3),
    ('DETH-MASHENE',781800000,'7.818 DFC',4),
    ('BadIdea',499900000,'4.999 DFC',5),
    ('Luca-B0T',452600000,'4.526 DFC',6),
    ('Droidazon_Prime',354300000,'3.543 DFC',7),
    ('Nesa',304100000,'3.041 DFC',8),
    ('Mabuhay',270900000,'2.709 DFC',9),
    ('Satya',231200000,'2.312 DFC',10),
    ('BldyFrg',165500000,'1.655 DFC',11),
    ('10u_b07',157700000,'1.577 DFC',12),
    ('FUBrandon',117400000,'1.174 DFC',13),
    ('bob',101400000,'1.014 DFC',14)
), active AS (
  SELECT address
  FROM explorer_tx_outputs
  WHERE block_height BETWEEN 736611 AND 739756 AND address != ''
  UNION
  SELECT address
  FROM explorer_balance_deltas
  WHERE height BETWEEN 736611 AND 739756 AND address != ''
), ordered AS (
  SELECT d.address,d.height,d.delta_sats
  FROM explorer_balance_deltas d
  JOIN active a ON a.address=d.address
  WHERE d.height <= 739756
), balances AS (
  SELECT address,height,
         SUM(delta_sats) OVER (
           PARTITION BY address ORDER BY height
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
         ) AS balance_sats
  FROM ordered
), candidate_balances AS (
  SELECT t.name,t.target_sats,t.published_dfc,t.sort_order,b.address,b.height,b.balance_sats,
         ABS(b.balance_sats - t.target_sats) AS diff_sats
  FROM balances b
  JOIN targets t
  WHERE b.height BETWEEN 736611 AND 739756
    AND ABS(b.balance_sats - t.target_sats) <= 500000
), per_address_best AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY name,address
           ORDER BY diff_sats ASC,height DESC
         ) AS address_rank
  FROM candidate_balances
), address_stats AS (
  SELECT address,
         COUNT(*) AS outputs,
         COUNT(DISTINCT txid) AS txs,
         COALESCE(SUM(value_sats),0) AS incoming_sats,
         MIN(block_height) AS first_h,
         MAX(block_height) AS last_h,
         SUM(CASE WHEN value_sats BETWEEN 100000 AND 314159265 THEN 1 ELSE 0 END) AS action_outputs
  FROM explorer_tx_outputs
  WHERE block_height BETWEEN 736611 AND 739756 AND address != ''
  GROUP BY address
), direct_hits AS (
  SELECT o.address,t.target_sats,COUNT(*) AS direct_outputs,MIN(o.block_height) AS direct_first_h,
         GROUP_CONCAT(SUBSTR(o.txid,1,12), ' ') AS tx_preview
  FROM explorer_tx_outputs o
  JOIN targets t ON t.target_sats=o.value_sats
  WHERE o.block_height BETWEEN 736611 AND 739756 AND o.address != ''
  GROUP BY o.address,t.target_sats
), exact_counts AS (
  SELECT name,COUNT(DISTINCT address) AS exact_candidates
  FROM per_address_best
  WHERE address_rank=1 AND diff_sats=0
  GROUP BY name
), ranked AS (
  SELECT b.name,b.target_sats,b.published_dfc,b.sort_order,b.address,b.height,b.balance_sats,b.diff_sats,
         COALESCE(s.outputs,0) AS outputs,
         COALESCE(s.txs,0) AS txs,
         COALESCE(s.incoming_sats,0) AS incoming_sats,
         COALESCE(s.first_h,0) AS first_h,
         COALESCE(s.last_h,0) AS last_h,
         COALESCE(s.action_outputs,0) AS action_outputs,
         COALESCE(d.direct_outputs,0) AS direct_outputs,
         COALESCE(d.direct_first_h,0) AS direct_first_h,
         COALESCE(d.tx_preview,'') AS tx_preview,
         COALESCE(e.exact_candidates,0) AS exact_candidates,
         ROW_NUMBER() OVER (
           PARTITION BY b.name
           ORDER BY b.diff_sats ASC,COALESCE(s.action_outputs,0) DESC,COALESCE(s.outputs,0) DESC,b.height DESC,b.address ASC
         ) AS target_rank
  FROM per_address_best b
  LEFT JOIN address_stats s ON s.address=b.address
  LEFT JOIN direct_hits d ON d.address=b.address AND d.target_sats=b.target_sats
  LEFT JOIN exact_counts e ON e.name=b.name
  WHERE b.address_rank=1
)
SELECT r.name,r.published_dfc,r.target_sats,r.address,r.height,COALESCE(bl.time,0),
       r.balance_sats,r.diff_sats,r.outputs,r.txs,r.incoming_sats,r.first_h,r.last_h,
       r.action_outputs,r.direct_outputs,r.direct_first_h,r.tx_preview,r.exact_candidates,r.target_rank
FROM ranked r
LEFT JOIN explorer_blocks bl ON bl.height=r.height
WHERE r.target_rank <= 8 OR r.diff_sats=0
ORDER BY r.sort_order,r.target_rank,r.address
)SQL"))) {
                    local_error = payout_query.lastError().text();
                } else {
                    while (payout_query.next()) {
                        const QString name = payout_query.value(0).toString();
                        const QString published = payout_query.value(1).toString();
                        const qint64 target_sats = payout_query.value(2).toLongLong();
                        const QString address = payout_query.value(3).toString();
                        const int height = payout_query.value(4).toInt();
                        const qint64 time = payout_query.value(5).toLongLong();
                        const qint64 balance_sats = payout_query.value(6).toLongLong();
                        const qint64 diff_sats = payout_query.value(7).toLongLong();
                        const int outputs = payout_query.value(8).toInt();
                        const int txs = payout_query.value(9).toInt();
                        const qint64 incoming_sats = payout_query.value(10).toLongLong();
                        const int first_height = payout_query.value(11).toInt();
                        const int last_height = payout_query.value(12).toInt();
                        const int action_outputs = payout_query.value(13).toInt();
                        const int direct_outputs = payout_query.value(14).toInt();
                        const int direct_first_height = payout_query.value(15).toInt();
                        const QString tx_preview = payout_query.value(16).toString();
                        const int exact_candidates = payout_query.value(17).toInt();
                        const int target_rank = payout_query.value(18).toInt();
                        int score = diff_sats == 0 ? 70 : std::max(20, 62 - static_cast<int>(diff_sats / 10000));
                        if (direct_outputs > 0) score += 12;
                        if (action_outputs >= 25) score += 12;
                        else if (action_outputs >= 5) score += 6;
                        if (outputs >= 5) score += 4;
                        score = std::min(score, 99);
                        const QString confidence = diff_sats == 0
                            ? (exact_candidates > 1 ? QStringLiteral("Ambiguous") : QStringLiteral("High"))
                            : (diff_sats <= 10000 ? QStringLiteral("Medium") : QStringLiteral("Low"));
                        const QString match_type = diff_sats == 0
                            ? QStringLiteral("point_balance_exact")
                            : QStringLiteral("point_balance_near");
                        const QString timestamp = time > 0
                            ? QDateTime::fromSecsSinceEpoch(time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
                            : QStringLiteral("date unavailable");
                        QStringList evidence;
                        evidence.push_back(diff_sats == 0
                            ? QStringLiteral("historical balance exactly reached the published amount")
                            : QStringLiteral("historical balance came within %1 of the published amount").arg(explorerAmountText(diff_sats)));
                        if (direct_outputs > 0) {
                            evidence.push_back(QStringLiteral("%1 exact payout-size output%2 in settlement window")
                                .arg(QString::number(direct_outputs), direct_outputs == 1 ? QString() : QStringLiteral("s")));
                        }
                        if (action_outputs > 0) {
                            evidence.push_back(QStringLiteral("%1 action-range output%2 in DC25 window")
                                .arg(QString::number(action_outputs), action_outputs == 1 ? QString() : QStringLiteral("s")));
                        }
                        if (exact_candidates > 1 && diff_sats == 0) {
                            evidence.push_back(QStringLiteral("%1 exact amount-matched addresses; identity remains unresolved")
                                .arg(QString::number(exact_candidates)));
                        }
                        payout_rows.push_back(row_for(QVariantList{
                            name,
                            published,
                            address,
                            explorerAmountText(balance_sats),
                            QStringLiteral("%1 / %2").arg(QString::number(height), timestamp),
                            diff_sats == 0 ? QStringLiteral("exact") : explorerAmountText(diff_sats),
                            confidence,
                            evidence.join(QStringLiteral("; "))
                        }, QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("address")},
                            {QStringLiteral("id"), address},
                            {QStringLiteral("address"), address},
                            {QStringLiteral("droidName"), name},
                            {QStringLiteral("published"), published},
                            {QStringLiteral("targetSats"), QVariant::fromValue<qlonglong>(target_sats)},
                            {QStringLiteral("balanceSats"), QVariant::fromValue<qlonglong>(balance_sats)},
                            {QStringLiteral("differenceSats"), QVariant::fromValue<qlonglong>(diff_sats)},
                            {QStringLiteral("height"), height},
                            {QStringLiteral("time"), QVariant::fromValue<qlonglong>(time)},
                            {QStringLiteral("outputs"), outputs},
                            {QStringLiteral("transactions"), txs},
                            {QStringLiteral("incomingSats"), QVariant::fromValue<qlonglong>(incoming_sats)},
                            {QStringLiteral("firstHeight"), first_height},
                            {QStringLiteral("lastHeight"), last_height},
                            {QStringLiteral("actionOutputs"), action_outputs},
                            {QStringLiteral("directOutputs"), direct_outputs},
                            {QStringLiteral("directFirstHeight"), direct_first_height},
                            {QStringLiteral("txPreview"), tx_preview},
                            {QStringLiteral("exactCandidates"), exact_candidates},
                            {QStringLiteral("targetRank"), target_rank},
                            {QStringLiteral("score"), score},
                            {QStringLiteral("confidence"), confidence},
                            {QStringLiteral("matchType"), match_type}}));
                        if (confidence != QLatin1String("Low") || action_outputs >= 25 || direct_outputs > 0) {
                            add_game_address_lead(QStringLiteral("DC25 payout lead"), name, address,
                                                  explorerAmountText(balance_sats), score, confidence,
                                                  evidence.join(QStringLiteral("; ")),
                                                  QVariantMap{
                                                      {QStringLiteral("source"), QStringLiteral("dc25-payout-hunt")},
                                                      {QStringLiteral("droidName"), name},
                                                      {QStringLiteral("height"), height},
                                                      {QStringLiteral("targetSats"), QVariant::fromValue<qlonglong>(target_sats)},
                                                      {QStringLiteral("balanceSats"), QVariant::fromValue<qlonglong>(balance_sats)},
                                                      {QStringLiteral("differenceSats"), QVariant::fromValue<qlonglong>(diff_sats)}});
                        }
                    }
                }
            }

            if (local_error.isEmpty()) {
                QSqlQuery game_lead_query(db);
                if (!game_lead_query.exec(QString::fromLatin1(R"SQL(
SELECT address,
       COUNT(*) AS outputs,
       COUNT(DISTINCT txid) AS txs,
       COALESCE(SUM(value_sats),0) AS sats,
       MIN(block_height) AS first_h,
       MAX(block_height) AS last_h,
       SUM(CASE WHEN value_sats BETWEEN 100000 AND 314159265 THEN 1 ELSE 0 END) AS action_outputs,
       SUM(CASE WHEN value_sats=1000000 THEN 1 ELSE 0 END) AS exact001_outputs,
       SUM(CASE WHEN value_sats IN (1620000,3210000,1190000,2524000,540000) THEN 1 ELSE 0 END) AS repeated_amount_outputs
FROM explorer_tx_outputs
WHERE block_height BETWEEN 736611 AND 739756 AND address != ''
GROUP BY address
HAVING action_outputs >= 40 OR exact001_outputs >= 10 OR repeated_amount_outputs >= 40
ORDER BY action_outputs DESC,sats DESC,address ASC
LIMIT 80
)SQL"))) {
                    local_error = game_lead_query.lastError().text();
                } else {
                    while (game_lead_query.next()) {
                        const QString address = game_lead_query.value(0).toString();
                        const int outputs = game_lead_query.value(1).toInt();
                        const int txs = game_lead_query.value(2).toInt();
                        const qint64 sats = game_lead_query.value(3).toLongLong();
                        const int first_height = game_lead_query.value(4).toInt();
                        const int last_height = game_lead_query.value(5).toInt();
                        const int action_outputs = game_lead_query.value(6).toInt();
                        const int exact001_outputs = game_lead_query.value(7).toInt();
                        const int repeated_amount_outputs = game_lead_query.value(8).toInt();
                        int score = 40 + std::min(35, action_outputs / 8);
                        if (exact001_outputs >= 10) score += 8;
                        if (repeated_amount_outputs >= 40) score += 8;
                        score = std::min(score, 95);
                        const QString role = action_outputs >= 100
                            ? QStringLiteral("DC25 high-cadence endpoint")
                            : QStringLiteral("DC25 action endpoint");
                        const QString confidence = action_outputs >= 100
                            ? QStringLiteral("Medium")
                            : QStringLiteral("Candidate");
                        const QString evidence = QStringLiteral("%1 action-range outputs, %2 exact 0.01 sends, %3 repeated-cost outputs across blocks %4-%5.")
                            .arg(QString::number(action_outputs),
                                 QString::number(exact001_outputs),
                                 QString::number(repeated_amount_outputs),
                                 QString::number(first_height),
                                 QString::number(last_height));
                        add_game_address_lead(role, QStringLiteral("address %1").arg(address.left(8)), address,
                                              roundedExplorerAmountText(sats), score, confidence, evidence,
                                              QVariantMap{
                                                  {QStringLiteral("source"), QStringLiteral("dc25-action-pattern")},
                                                  {QStringLiteral("outputs"), outputs},
                                                  {QStringLiteral("transactions"), txs},
                                                  {QStringLiteral("actionOutputs"), action_outputs},
                                                  {QStringLiteral("exact001Outputs"), exact001_outputs},
                                                  {QStringLiteral("repeatedAmountOutputs"), repeated_amount_outputs},
                                                  {QStringLiteral("sats"), QVariant::fromValue<qlonglong>(sats)},
                                                  {QStringLiteral("firstHeight"), first_height},
                                                  {QStringLiteral("lastHeight"), last_height}});
                    }
                }
            }

            if (local_error.isEmpty()) {
                QSqlQuery winner_query(db);
                if (!winner_query.exec(QString::fromLatin1(R"SQL(
SELECT address,COUNT(*) outputs,COUNT(DISTINCT txid) txs,COALESCE(SUM(value_sats),0) sats,
       MAX(value_sats) largest_sats,MIN(block_height) first_h,MAX(block_height) last_h,COUNT(DISTINCT block_height) blocks
FROM explorer_tx_outputs
WHERE block_height BETWEEN 109943 AND 111441 AND address != '' AND value_sats=13370000
GROUP BY address
ORDER BY sats DESC,outputs DESC,address ASC
LIMIT 100
)SQL"))) {
                    local_error = winner_query.lastError().text();
                } else {
                    while (winner_query.next()) {
                        const QString address = winner_query.value(0).toString();
                        const int outputs = winner_query.value(1).toInt();
                        const int txs = winner_query.value(2).toInt();
                        const qint64 sats = winner_query.value(3).toLongLong();
                        const qint64 largest_sats = winner_query.value(4).toLongLong();
                        const int first_height = winner_query.value(5).toInt();
                        const int last_height = winner_query.value(6).toInt();
                        const int blocks = winner_query.value(7).toInt();
                        if (largest_winner_sats == 0) {
                            largest_winner_sats = sats;
                            largest_winner_address = address;
                        }
                        if (sats == largest_winner_sats) ++largest_winner_ties;
                        winner_rows.push_back(row_for(QVariantList{
                            address,
                            roundedExplorerAmountText(sats),
                            outputs,
                            txs,
                            roundedExplorerAmountText(largest_sats),
                            blocks,
                            QStringLiteral("%1-%2").arg(QString::number(first_height), QString::number(last_height))
                        }, QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("address")},
                            {QStringLiteral("id"), address},
                            {QStringLiteral("address"), address},
                            {QStringLiteral("sats"), QVariant::fromValue<qlonglong>(sats)},
                            {QStringLiteral("outputs"), outputs},
                            {QStringLiteral("transactions"), txs},
                            {QStringLiteral("largestSats"), QVariant::fromValue<qlonglong>(largest_sats)},
                            {QStringLiteral("blocks"), blocks},
                            {QStringLiteral("firstHeight"), first_height},
                            {QStringLiteral("lastHeight"), last_height}}));
                    }
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);

    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("Registration / sync"),
        QStringLiteral("Small player sends to a per-droid registration or sync address, then a near-return or later recognized action."),
        QStringLiteral("candidate without live API")
    }, QVariantMap{{QStringLiteral("confidence"), QStringLiteral("medium")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("Attack sends"),
        QStringLiteral("Registered-player source spends into a droid attack address; repeated fan-in marks likely droid targets."),
        QStringLiteral("candidate from fan-in")
    }, QVariantMap{{QStringLiteral("confidence"), QStringLiteral("medium")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("Shield / cover"),
        QStringLiteral("Repeated exact-cost sends to global defense endpoints; Defcoin launch data shows many 0.01 DFC action-cost candidates."),
        QStringLiteral("candidate from cost hubs")
    }, QVariantMap{{QStringLiteral("confidence"), QStringLiteral("medium")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("Payout / spillage swarm"),
        QStringLiteral("Many equal 0.13370000 DFC outputs to the same 64 recipients in the launch window."),
        QStringLiteral("high")
    }, QVariantMap{{QStringLiteral("confidence"), QStringLiteral("high")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("DC25 point-balance payout hunt"),
        QStringLiteral("Published leaderboard amounts are matched against historical balances reached during the DC25 game and settlement window; later spends do not disqualify a candidate."),
        payout_rows.isEmpty() ? QStringLiteral("waiting for indexed matches") : QStringLiteral("candidate rows")
    }, QVariantMap{{QStringLiteral("confidence"), payout_rows.isEmpty() ? QStringLiteral("candidate") : QStringLiteral("medium")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("2014 vanity battle response"),
        QStringLiteral("A tx with three or more known cosmetic response addresses decodes output satoshis into attacker/defender level, HP, damage, and counter-damage."),
        vanity_rows.isEmpty() ? QStringLiteral("available after matching outputs") : QStringLiteral("high")
    }, QVariantMap{{QStringLiteral("confidence"), vanity_rows.isEmpty() ? QStringLiteral("candidate") : QStringLiteral("high")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("25 Jul 2017 processing shift"),
        QStringLiteral("Defcoin mempool support exposed pending action estimates, but state changes, inventory changes, and payouts still required confirmed blocks."),
        QStringLiteral("source-backed")
    }, QVariantMap{{QStringLiteral("confidence"), QStringLiteral("source-backed")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("Dust to OP_RETURN pivot"),
        QStringLiteral("Early blocks score exact fractional DFC outputs; later blocks scan indexed OP_RETURN payload hex/text because action semantics can move into transaction metadata."),
        op_return_rows.isEmpty() ? QStringLiteral("indexed, waiting for matches") : QStringLiteral("payloads indexed")
    }, QVariantMap{{QStringLiteral("confidence"), op_return_rows.isEmpty() ? QStringLiteral("candidate") : QStringLiteral("medium")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("Known API metadata"),
        QStringLiteral("The Coindroids API documented currencies, attack addresses, ammunition clips, mempool actions, and payouts, but the live API did not answer during this build."),
        QStringLiteral("exact when available")
    }, QVariantMap{{QStringLiteral("confidence"), QStringLiteral("external")}}));
    evidence_rows.push_back(row_for(QVariantList{
        QStringLiteral("DC25 attack-address chain forensics"),
        dc25_chain_summary.value(QStringLiteral("cohortNote")).toString().isEmpty()
            ? QStringLiteral("The bundled DC25 chain-forensics data separates eight named DC25 leads including Olo, high-confidence attack-address candidates, broad cohort candidates, and source/ammo clips.")
            : dc25_chain_summary.value(QStringLiteral("cohortNote")).toString(),
        dc25_chain_summary.value(QStringLiteral("dc25ChainForensicsStatus")).toString().isEmpty()
            ? QStringLiteral("loaded")
            : dc25_chain_summary.value(QStringLiteral("dc25ChainForensicsStatus")).toString()
    }, QVariantMap{{QStringLiteral("confidence"), QStringLiteral("source-backed")}}));

    summary.insert(QStringLiteral("actionOutputs"), QVariant::fromValue<qlonglong>(total_action_outputs));
    summary.insert(QStringLiteral("actionTransactions"), QVariant::fromValue<qlonglong>(total_action_txs));
    summary.insert(QStringLiteral("actionAddresses"), QVariant::fromValue<qlonglong>(total_action_addresses));
    summary.insert(QStringLiteral("actionAmount"), explorerAmountText(total_action_sats));
    summary.insert(QStringLiteral("actionAmountRounded"), roundedExplorerAmountText(total_action_sats));
    summary.insert(QStringLiteral("windowCount"), window_rows.size());
    summary.insert(QStringLiteral("strongestWindowLabel"), strongest_window_label);
    summary.insert(QStringLiteral("strongestWindowAmount"), roundedExplorerAmountText(strongest_window_sats));
    summary.insert(QStringLiteral("strongestWindowOutputs"), QVariant::fromValue<qlonglong>(strongest_window_outputs));
    summary.insert(QStringLiteral("launch001Outputs"), QVariant::fromValue<qlonglong>(launch_001_outputs));
    summary.insert(QStringLiteral("launch1337Outputs"), QVariant::fromValue<qlonglong>(launch_1337_outputs));
    summary.insert(QStringLiteral("launch1337Amount"), explorerAmountText(launch_1337_sats));
    summary.insert(QStringLiteral("launch1337AmountRounded"), roundedExplorerAmountText(launch_1337_sats));
    summary.insert(QStringLiteral("launch1337Recipients"), QVariant::fromValue<qlonglong>(launch_1337_recipients));
    summary.insert(QStringLiteral("largestWinnerAddress"), largest_winner_address);
    summary.insert(QStringLiteral("largestWinnerAmount"), explorerAmountText(largest_winner_sats));
    summary.insert(QStringLiteral("largestWinnerAmountRounded"), roundedExplorerAmountText(largest_winner_sats));
    summary.insert(QStringLiteral("largestWinnerTies"), largest_winner_ties);
    summary.insert(QStringLiteral("endpointCount"), endpoint_rows.size());
    summary.insert(QStringLiteral("winnerCount"), winner_rows.size());
    summary.insert(QStringLiteral("phaseCount"), phase_rows.size());
    summary.insert(QStringLiteral("publishedAnchorCount"), published_rows.size());
    summary.insert(QStringLiteral("vanityResponseCount"), vanity_rows.size());
    summary.insert(QStringLiteral("opReturnCandidateCount"), op_return_rows.size());
    summary.insert(QStringLiteral("botCandidateCount"), bot_rows.size());
    summary.insert(QStringLiteral("payoutCandidateCount"), payout_rows.size());
    summary.insert(QStringLiteral("gameAddressLeadCount"), game_address_rows.size());
    for (auto it = dc25_chain_summary.constBegin(); it != dc25_chain_summary.constEnd(); ++it)
        summary.insert(it.key(), it.value());
    summary.insert(QStringLiteral("dc25AttackAddressRowCount"), attack_address_rows.size());
    summary.insert(QStringLiteral("dc25QrSeedRowCount"), qr_seed_rows.size());
    summary.insert(QStringLiteral("dc25NamedLeadCount"), qr_seed_rows.size() + olo_rows.size());
    summary.insert(QStringLiteral("dc25SourceAmmoRowCount"), source_ammo_rows.size());
    summary.insert(QStringLiteral("dc25OloCandidateRowCount"), olo_rows.size());
    summary.insert(QStringLiteral("dc25PublishedTopPayoutTotal"), QStringLiteral("206.2045 DFC"));
    summary.insert(QStringLiteral("dc25PublishedOverallPayoutTotal"), QStringLiteral("227.046 DFC"));
    summary.insert(QStringLiteral("dc25PayoutHuntNote"),
                   QStringLiteral("Published DC25 payout values are treated as point-in-time contest/payout measurements. The scanner looks for historical balances reached during the DC25 settlement window, not final or current wallet balances."));
    summary.insert(QStringLiteral("transitionDate"), QStringLiteral("2017-07-25"));
    summary.insert(QStringLiteral("transitionLabel"), QStringLiteral("Defcoin mempool support added"));
    summary.insert(QStringLiteral("bountyTerminologyDate"), QStringLiteral("2017-08-11"));
    summary.insert(QStringLiteral("publishedLargestWinner"), QStringLiteral("ModemBot1138"));
    summary.insert(QStringLiteral("publishedLargestWinnerAmount"), QStringLiteral("100.0605 DFC"));
    summary.insert(QStringLiteral("analysisNote"),
                   QStringLiteral("Offline chain heuristics based on the documented transaction-driven Coindroids protocol and local Defcoin explorer index."));
    summary.insert(QStringLiteral("droidTrailsCacheStatus"), QStringLiteral("rebuilt"));
    summary.insert(QStringLiteral("droidTrailsCacheVersion"), DROIDTRAILS_CACHE_SCHEMA_VERSION);
    summary.insert(QStringLiteral("droidTrailsCachePath"), droidTrailsDatabasePath());
    summary.insert(QStringLiteral("droidTrailsSourceHeight"), explorerHighestIndexedBlock());
    summary.insert(QStringLiteral("droidTrailsSourceOutputs"), explorerIndexedOutputCountFromDb());

    result.insert(QStringLiteral("summary"), summary);
    result.insert(QStringLiteral("windows"), window_rows);
    result.insert(QStringLiteral("endpoints"), endpoint_rows);
    result.insert(QStringLiteral("winners"), winner_rows);
    result.insert(QStringLiteral("phases"), phase_rows);
    result.insert(QStringLiteral("published"), published_rows);
    result.insert(QStringLiteral("vanity"), vanity_rows);
    result.insert(QStringLiteral("opReturns"), op_return_rows);
    result.insert(QStringLiteral("bots"), bot_rows);
    result.insert(QStringLiteral("payouts"), payout_rows);
    result.insert(QStringLiteral("attackAddresses"), attack_address_rows);
    result.insert(QStringLiteral("qrSeeds"), qr_seed_rows);
    result.insert(QStringLiteral("sourceAmmo"), source_ammo_rows);
    result.insert(QStringLiteral("oloCandidates"), olo_rows);
    result.insert(QStringLiteral("gameAddresses"), game_address_rows);
    result.insert(QStringLiteral("evidence"), evidence_rows);
    if (local_error.isEmpty()) saveCoindroidsAnalyticsCache(result);
    if (!local_error.isEmpty() && error) *error = local_error;
    return result;
}

QVariantList NuRpcService::explorerContactsFromJsonArray(const QJsonArray& raw_contacts) const
{
    QVariantList contacts;
    for (const QJsonValue& value : raw_contacts) {
        const QJsonObject object = value.toObject();
        const QString username = singleLineLimited(object.value(QStringLiteral("username")).toString(), 96).trimmed();
        const QJsonArray raw_addresses = object.value(QStringLiteral("addresses")).toArray();
        QVariantList addresses;
        QStringList address_strings;
        QSet<QString> seen;
        for (const QJsonValue& address_value : raw_addresses) {
            const QString address = singleLineLimited(address_value.toString(), 128).trimmed();
            if (address.isEmpty() || seen.contains(address)) continue;
            seen.insert(address);
            addresses.push_back(address);
            address_strings.push_back(address);
        }
        if (!username.isEmpty() && !addresses.isEmpty()) {
            contacts.push_back(QVariantMap{
                {QStringLiteral("username"), username},
                {QStringLiteral("addresses"), addresses},
                {QStringLiteral("addressText"), address_strings.join(QStringLiteral(", "))}});
        }
    }
    return contacts;
}

QJsonArray NuRpcService::explorerContactsToJsonArray(const QVariantList& contacts) const
{
    QJsonArray out;
    for (const QVariant& value : contacts) {
        const QVariantMap contact = value.toMap();
        const QString username = singleLineLimited(contact.value(QStringLiteral("username")).toString(), 96).trimmed();
        QJsonArray addresses;
        QSet<QString> seen;
        for (const QVariant& address_value : contact.value(QStringLiteral("addresses")).toList()) {
            const QString address = singleLineLimited(address_value.toString(), 128).trimmed();
            if (address.isEmpty() || seen.contains(address)) continue;
            seen.insert(address);
            addresses.push_back(address);
        }
        if (username.isEmpty() || addresses.isEmpty()) continue;
        QJsonObject object;
        object.insert(QStringLiteral("username"), username);
        object.insert(QStringLiteral("addresses"), addresses);
        out.push_back(object);
    }
    return out;
}

QVariantMap NuRpcService::explorerContactSetRow(const QString& name, const QVariantList& contacts, qint64 updated_at) const
{
    int address_count = 0;
    for (const QVariant& value : contacts) {
        address_count += value.toMap().value(QStringLiteral("addresses")).toList().size();
    }
    const QString clean_name = singleLineLimited(name, 96).trimmed();
    const QString updated_text = updated_at > 0
        ? QDateTime::fromSecsSinceEpoch(updated_at).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t"))
        : QStringLiteral("not saved");
    return QVariantMap{
        {QStringLiteral("cells"), QVariantList{
            clean_name,
            contacts.size(),
            address_count,
            updated_text
        }},
        {QStringLiteral("meta"), QVariantMap{
            {QStringLiteral("name"), clean_name},
            {QStringLiteral("contacts"), contacts},
            {QStringLiteral("contactCount"), contacts.size()},
            {QStringLiteral("addressCount"), address_count},
            {QStringLiteral("updatedAt"), QVariant::fromValue<qlonglong>(updated_at)}}}
    };
}

int NuRpcService::explorerContactSetIndex(const QString& name) const
{
    const QString clean_name = singleLineLimited(name, 96).trimmed();
    if (clean_name.isEmpty()) return -1;
    for (int i = 0; i < m_explorer_contact_sets.size(); ++i) {
        const QVariantMap meta = m_explorer_contact_sets.at(i).toMap().value(QStringLiteral("meta")).toMap();
        if (meta.value(QStringLiteral("name")).toString().compare(clean_name, Qt::CaseInsensitive) == 0) return i;
    }
    return -1;
}

void NuRpcService::upsertExplorerContactSet(const QString& name, const QVariantList& contacts, qint64 updated_at)
{
    const QString clean_name = singleLineLimited(name, 96).trimmed().isEmpty()
        ? QStringLiteral("Default")
        : singleLineLimited(name, 96).trimmed();
    const int index = explorerContactSetIndex(clean_name);
    const QVariantMap row = explorerContactSetRow(clean_name, contacts, updated_at);
    if (index >= 0) {
        m_explorer_contact_sets[index] = row;
    } else {
        m_explorer_contact_sets.push_back(row);
    }
}

void NuRpcService::persistExplorerContactSets()
{
    QJsonArray sets;
    for (const QVariant& value : m_explorer_contact_sets) {
        const QVariantMap row = value.toMap();
        const QVariantMap meta = row.value(QStringLiteral("meta")).toMap();
        const QString name = singleLineLimited(meta.value(QStringLiteral("name")).toString(), 96).trimmed();
        if (name.isEmpty()) continue;
        QJsonObject object;
        object.insert(QStringLiteral("name"), name);
        object.insert(QStringLiteral("updatedAt"), static_cast<qint64>(meta.value(QStringLiteral("updatedAt")).toLongLong()));
        object.insert(QStringLiteral("contacts"), explorerContactsToJsonArray(meta.value(QStringLiteral("contacts")).toList()));
        sets.push_back(object);
    }
    QSettings settings;
    settings.setValue(QStringLiteral("ExplorerContactSetsJson"), QJsonDocument(sets).toJson(QJsonDocument::Compact));
    settings.setValue(QStringLiteral("ExplorerActiveContactSetName"), m_current_explorer_contact_set_name);
    settings.setValue(QStringLiteral("ExplorerContactsJson"), QJsonDocument(explorerContactsToJsonArray(m_explorer_contacts)).toJson(QJsonDocument::Compact));
}

void NuRpcService::loadExplorerContacts()
{
    m_explorer_contacts.clear();
    m_explorer_contact_sets.clear();
    QSettings settings;
    const QByteArray raw_sets = settings.value(QStringLiteral("ExplorerContactSetsJson"), QByteArray()).toByteArray();
    if (!raw_sets.isEmpty()) {
        const QJsonDocument doc = QJsonDocument::fromJson(raw_sets);
        if (doc.isArray()) {
            for (const QJsonValue& value : doc.array()) {
                const QJsonObject object = value.toObject();
                const QString name = singleLineLimited(object.value(QStringLiteral("name")).toString(), 96).trimmed();
                if (name.isEmpty()) continue;
                upsertExplorerContactSet(name,
                                         explorerContactsFromJsonArray(object.value(QStringLiteral("contacts")).toArray()),
                                         static_cast<qint64>(object.value(QStringLiteral("updatedAt")).toDouble()));
            }
        }
    }

    if (m_explorer_contact_sets.isEmpty()) {
        const QByteArray raw = settings.value(QStringLiteral("ExplorerContactsJson"), QByteArray()).toByteArray();
        QVariantList migrated_contacts;
        if (!raw.isEmpty()) {
            const QJsonDocument doc = QJsonDocument::fromJson(raw);
            if (doc.isArray()) migrated_contacts = explorerContactsFromJsonArray(doc.array());
        }
        upsertExplorerContactSet(QStringLiteral("Default"), migrated_contacts, QDateTime::currentSecsSinceEpoch());
    }

    QString active_name = singleLineLimited(settings.value(QStringLiteral("ExplorerActiveContactSetName"), QString()).toString(), 96).trimmed();
    int active_index = explorerContactSetIndex(active_name);
    if (active_index < 0 && !m_explorer_contact_sets.isEmpty()) {
        active_index = 0;
        active_name = m_explorer_contact_sets.first().toMap().value(QStringLiteral("meta")).toMap().value(QStringLiteral("name")).toString();
    }
    m_current_explorer_contact_set_name = active_name.isEmpty() ? QStringLiteral("Default") : active_name;
    if (active_index >= 0) {
        m_explorer_contacts = m_explorer_contact_sets.at(active_index).toMap().value(QStringLiteral("meta")).toMap().value(QStringLiteral("contacts")).toList();
    }
    persistExplorerContactSets();
    refreshExplorerContactRelationships();
}

void NuRpcService::persistExplorerContacts()
{
    if (m_current_explorer_contact_set_name.trimmed().isEmpty())
        m_current_explorer_contact_set_name = QStringLiteral("Default");
    upsertExplorerContactSet(m_current_explorer_contact_set_name, m_explorer_contacts, QDateTime::currentSecsSinceEpoch());
    persistExplorerContactSets();
}

void NuRpcService::createExplorerContactSet(const QString& name)
{
    const QString clean_name = singleLineLimited(name, 96).trimmed();
    if (clean_name.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Contact set not created"), QStringLiteral("Enter a contact set name."));
        return;
    }
    if (explorerContactSetIndex(clean_name) >= 0) {
        Q_EMIT userMessage(QStringLiteral("Contact set already exists"),
                           QStringLiteral("Load or rename the existing \"%1\" set instead.").arg(clean_name));
        return;
    }
    m_current_explorer_contact_set_name = clean_name;
    m_explorer_contacts.clear();
    upsertExplorerContactSet(clean_name, m_explorer_contacts, QDateTime::currentSecsSinceEpoch());
    persistExplorerContactSets();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Contact set created"),
                       QStringLiteral("\"%1\" is now the active empty contact set.").arg(clean_name));
}

void NuRpcService::saveExplorerContactSet(const QString& name)
{
    const QString clean_name = singleLineLimited(name, 96).trimmed().isEmpty()
        ? m_current_explorer_contact_set_name
        : singleLineLimited(name, 96).trimmed();
    if (clean_name.trimmed().isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Contact set not saved"), QStringLiteral("Enter a contact set name."));
        return;
    }
    m_current_explorer_contact_set_name = clean_name;
    upsertExplorerContactSet(clean_name, m_explorer_contacts, QDateTime::currentSecsSinceEpoch());
    persistExplorerContactSets();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Contact set saved"),
                       QStringLiteral("\"%1\" now contains %2 contact%3.")
                           .arg(clean_name,
                                QString::number(m_explorer_contacts.size()),
                                m_explorer_contacts.size() == 1 ? QString() : QStringLiteral("s")));
}

void NuRpcService::loadExplorerContactSet(const QString& name)
{
    const QString clean_name = singleLineLimited(name, 96).trimmed();
    const int index = explorerContactSetIndex(clean_name);
    if (index < 0) {
        Q_EMIT userMessage(QStringLiteral("Contact set not loaded"),
                           QStringLiteral("No saved contact set named \"%1\" was found.").arg(clean_name));
        return;
    }
    const QVariantMap meta = m_explorer_contact_sets.at(index).toMap().value(QStringLiteral("meta")).toMap();
    m_current_explorer_contact_set_name = meta.value(QStringLiteral("name")).toString();
    m_explorer_contacts = meta.value(QStringLiteral("contacts")).toList();
    persistExplorerContactSets();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Contact set loaded"),
                       QStringLiteral("\"%1\" is active for relationship graphing.").arg(m_current_explorer_contact_set_name));
}

void NuRpcService::renameExplorerContactSet(const QString& old_name, const QString& new_name)
{
    const QString clean_old = singleLineLimited(old_name, 96).trimmed().isEmpty()
        ? m_current_explorer_contact_set_name
        : singleLineLimited(old_name, 96).trimmed();
    const QString clean_new = singleLineLimited(new_name, 96).trimmed();
    if (clean_old.isEmpty() || clean_new.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Contact set not renamed"),
                           QStringLiteral("Choose an existing set and enter the new name."));
        return;
    }
    const int index = explorerContactSetIndex(clean_old);
    if (index < 0) {
        Q_EMIT userMessage(QStringLiteral("Contact set not renamed"),
                           QStringLiteral("No saved contact set named \"%1\" was found.").arg(clean_old));
        return;
    }
    const int duplicate_index = explorerContactSetIndex(clean_new);
    if (duplicate_index >= 0 && duplicate_index != index) {
        Q_EMIT userMessage(QStringLiteral("Contact set not renamed"),
                           QStringLiteral("\"%1\" already exists.").arg(clean_new));
        return;
    }
    const QVariantMap old_meta = m_explorer_contact_sets.at(index).toMap().value(QStringLiteral("meta")).toMap();
    const QVariantList contacts = old_meta.value(QStringLiteral("contacts")).toList();
    const qint64 updated_at = old_meta.value(QStringLiteral("updatedAt")).toLongLong();
    m_explorer_contact_sets[index] = explorerContactSetRow(clean_new, contacts, updated_at > 0 ? updated_at : QDateTime::currentSecsSinceEpoch());
    if (m_current_explorer_contact_set_name.compare(clean_old, Qt::CaseInsensitive) == 0)
        m_current_explorer_contact_set_name = clean_new;
    persistExplorerContactSets();
    Q_EMIT explorerChanged();
    Q_EMIT userMessage(QStringLiteral("Contact set renamed"),
                       QStringLiteral("\"%1\" is now \"%2\".").arg(clean_old, clean_new));
}

void NuRpcService::deleteExplorerContactSet(const QString& name)
{
    const QString clean_name = singleLineLimited(name, 96).trimmed();
    const int index = explorerContactSetIndex(clean_name);
    if (index < 0) {
        Q_EMIT userMessage(QStringLiteral("Contact set not deleted"),
                           QStringLiteral("No saved contact set named \"%1\" was found.").arg(clean_name));
        return;
    }
    const bool deleted_active = m_current_explorer_contact_set_name.compare(clean_name, Qt::CaseInsensitive) == 0;
    m_explorer_contact_sets.removeAt(index);
    if (m_explorer_contact_sets.isEmpty()) {
        m_current_explorer_contact_set_name = QStringLiteral("Default");
        m_explorer_contacts.clear();
        upsertExplorerContactSet(m_current_explorer_contact_set_name, m_explorer_contacts, QDateTime::currentSecsSinceEpoch());
    } else if (deleted_active) {
        const QVariantMap meta = m_explorer_contact_sets.first().toMap().value(QStringLiteral("meta")).toMap();
        m_current_explorer_contact_set_name = meta.value(QStringLiteral("name")).toString();
        m_explorer_contacts = meta.value(QStringLiteral("contacts")).toList();
    }
    persistExplorerContactSets();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Contact set deleted"),
                       deleted_active
                           ? QStringLiteral("\"%1\" was deleted. \"%2\" is now active.").arg(clean_name, m_current_explorer_contact_set_name)
                           : QStringLiteral("\"%1\" was deleted.").arg(clean_name));
}

void NuRpcService::saveExplorerContact(const QString& username, const QString& addresses, int edit_index)
{
    const QString clean_name = singleLineLimited(username, 96).trimmed();
    QStringList address_candidates = addresses.split(QRegularExpression(QStringLiteral("[,\\n\\r\\t ;]+")), Qt::SkipEmptyParts);
    QStringList clean_addresses = recognizedExplorerAddresses(address_candidates);
    clean_addresses.removeDuplicates();
    if (clean_name.isEmpty() || clean_addresses.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Contact not saved"),
                           QStringLiteral("Enter a username and at least one valid Defcoin address."));
        return;
    }

    QVariantMap contact;
    QVariantList address_list;
    for (const QString& address : clean_addresses) address_list.push_back(address);
    contact.insert(QStringLiteral("username"), clean_name);
    contact.insert(QStringLiteral("addresses"), address_list);
    contact.insert(QStringLiteral("addressText"), clean_addresses.join(QStringLiteral(", ")));

    if (edit_index >= 0 && edit_index < m_explorer_contacts.size()) {
        m_explorer_contacts[edit_index] = contact;
    } else {
        m_explorer_contacts.push_back(contact);
    }
    persistExplorerContacts();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Contact saved"),
                       QStringLiteral("%1 is linked to %2 address%3.")
                           .arg(clean_name)
                           .arg(clean_addresses.size())
                           .arg(clean_addresses.size() == 1 ? QString() : QStringLiteral("es")));
}

void NuRpcService::deleteExplorerContact(int index)
{
    if (index < 0 || index >= m_explorer_contacts.size()) {
        Q_EMIT userMessage(QStringLiteral("Contact not deleted"), QStringLiteral("Select a contact row to delete."));
        return;
    }
    m_explorer_contacts.removeAt(index);
    persistExplorerContacts();
    refreshExplorerContactRelationships();
}

void NuRpcService::refreshExplorerContactRelationships()
{
    m_explorer_contact_relationships.clear();
    QHash<QString, QString> owner_by_address;
    QHash<QString, QStringList> addresses_by_owner;
    QHash<QString, qint64> balance_by_owner;
    QHash<QString, qint64> received_by_owner;
    QHash<QString, int> tx_count_by_owner;
    for (const QVariant& value : m_explorer_contacts) {
        const QVariantMap contact = value.toMap();
        const QString username = contact.value(QStringLiteral("username")).toString().trimmed();
        if (username.isEmpty()) continue;
        balance_by_owner.insert(username, 0);
        received_by_owner.insert(username, 0);
        tx_count_by_owner.insert(username, 0);
        for (const QVariant& address_value : contact.value(QStringLiteral("addresses")).toList()) {
            const QString address = address_value.toString().trimmed();
            if (address.isEmpty()) continue;
            owner_by_address.insert(address, username);
            addresses_by_owner[username].push_back(address);
        }
    }

    QString error;
    if (!owner_by_address.isEmpty() && ensureExplorerDatabase(&error)) {
        const QString connection_name = QStringLiteral("nu_explorer_contacts_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QStringList placeholders;
            QStringList addresses = owner_by_address.keys();
            for (int i = 0; i < addresses.size(); ++i) placeholders.push_back(QStringLiteral("?"));
            {
                QSqlQuery balance_query(db);
                balance_query.prepare(QStringLiteral(
                    "SELECT address, "
                    "COALESCE(SUM(CASE WHEN spent_by_txid IS NULL THEN value_sats ELSE 0 END), 0) AS balance_sats, "
                    "COALESCE(SUM(value_sats), 0) AS received_sats, "
                    "COUNT(DISTINCT txid) AS tx_count "
                    "FROM explorer_tx_outputs "
                    "WHERE address IN (%1) "
                    "GROUP BY address").arg(placeholders.join(QStringLiteral(","))));
                for (const QString& address : addresses) balance_query.addBindValue(address);
                if (balance_query.exec()) {
                    while (balance_query.next()) {
                        const QString owner = owner_by_address.value(balance_query.value(0).toString());
                        if (owner.isEmpty()) continue;
                        balance_by_owner[owner] += balance_query.value(1).toLongLong();
                        received_by_owner[owner] += balance_query.value(2).toLongLong();
                        tx_count_by_owner[owner] += balance_query.value(3).toInt();
                    }
                }
            }
            if (owner_by_address.size() >= 2) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral(
                    "SELECT spent.address AS source_address, received.address AS target_address, "
                    "COUNT(DISTINCT received.txid) AS tx_count, COALESCE(SUM(received.value_sats), 0) AS sent_sats "
                    "FROM explorer_tx_outputs spent "
                    "JOIN explorer_tx_outputs received ON spent.spent_by_txid = received.txid "
                    "WHERE spent.address IN (%1) AND received.address IN (%1) AND spent.address != received.address "
                    "GROUP BY spent.address, received.address "
                    "ORDER BY sent_sats DESC, tx_count DESC").arg(placeholders.join(QStringLiteral(","))));
                for (const QString& address : addresses) query.addBindValue(address);
                for (const QString& address : addresses) query.addBindValue(address);
                if (query.exec()) {
                    QHash<QString, QPair<qint64, int>> aggregate;
                    while (query.next()) {
                        const QString source_owner = owner_by_address.value(query.value(0).toString());
                        const QString target_owner = owner_by_address.value(query.value(1).toString());
                        if (source_owner.isEmpty() || target_owner.isEmpty() || source_owner == target_owner) continue;
                        const QString key = source_owner + QStringLiteral("\n") + target_owner;
                        auto current = aggregate.value(key, qMakePair<qint64, int>(0, 0));
                        current.first += query.value(3).toLongLong();
                        current.second += query.value(2).toInt();
                        aggregate.insert(key, current);
                    }
                    for (auto it = aggregate.constBegin(); it != aggregate.constEnd(); ++it) {
                        const QStringList parts = it.key().split(QLatin1Char('\n'));
                        if (parts.size() != 2) continue;
                        m_explorer_contact_relationships.push_back(QVariantMap{
                            {QStringLiteral("cells"), QVariantList{parts.at(0), parts.at(1), explorerAmountText(it.value().first), it.value().second}},
                            {QStringLiteral("meta"), QVariantMap{
                                {QStringLiteral("source"), parts.at(0)},
	                            {QStringLiteral("target"), parts.at(1)},
	                            {QStringLiteral("amountSats"), QVariant::fromValue<qlonglong>(it.value().first)},
	                            {QStringLiteral("txCount"), it.value().second}}}
	                        });
	                    }
	                }
	            }
        }
        db.close();
        db = QSqlDatabase();
        QSqlDatabase::removeDatabase(connection_name);
    }

    for (int i = 0; i < m_explorer_contacts.size(); ++i) {
        QVariantMap contact = m_explorer_contacts.at(i).toMap();
        const QString username = contact.value(QStringLiteral("username")).toString().trimmed();
        const qint64 balance_sats = balance_by_owner.value(username, 0);
        const qint64 received_sats = received_by_owner.value(username, 0);
        contact.insert(QStringLiteral("balanceSats"), QVariant::fromValue<qlonglong>(balance_sats));
        contact.insert(QStringLiteral("receivedSats"), QVariant::fromValue<qlonglong>(received_sats));
        contact.insert(QStringLiteral("txCount"), tx_count_by_owner.value(username, 0));
        contact.insert(QStringLiteral("balanceText"), explorerAmountText(balance_sats));
        contact.insert(QStringLiteral("receivedText"), explorerAmountText(received_sats));
        m_explorer_contacts[i] = contact;
    }

    if (m_explorer_contact_relationships.isEmpty() && owner_by_address.size() >= 2) {
        m_explorer_contact_relationships.push_back(QVariantMap{
            {QStringLiteral("cells"), QVariantList{QStringLiteral("No indexed flow"), QStringLiteral("No match"), QStringLiteral("0.00000000 DFC"), 0}},
            {QStringLiteral("meta"), QVariantMap{{QStringLiteral("note"), QStringLiteral("No direct indexed spend flow between saved contacts yet.")}}}
        });
    }
    Q_EMIT explorerChanged();
}

void NuRpcService::loadExplorerContactRows(const QString& name, const QVariantList& rows)
{
    const QString clean_name = singleLineLimited(name, 96).trimmed().isEmpty()
        ? QStringLiteral("Ad-hoc Relationship Set")
        : singleLineLimited(name, 96).trimmed();
    QVariantList contacts;
    QSet<QString> seen_addresses;

    auto add_candidates = [&seen_addresses](QStringList& target, const QString& raw_text) {
        QString clean = raw_text.trimmed();
        if (clean.isEmpty()) return;
        clean.replace(QRegularExpression(QStringLiteral("[<>\\[\\]\\(\\)\\\",;|]")), QStringLiteral(" "));
        clean.replace(QRegularExpression(QStringLiteral(R"(\s+)")), QStringLiteral(" "));
        const QStringList parts = clean.split(QRegularExpression(QStringLiteral(R"(\s+)")), Qt::SkipEmptyParts);
        const QStringList recognized = recognizedExplorerAddresses(parts);
        for (const QString& address : recognized) {
            if (seen_addresses.contains(address)) continue;
            seen_addresses.insert(address);
            target.push_back(address);
        }
    };

    auto display_name_for_row = [](const QVariantMap& row, const QVariantMap& meta) {
        const QStringList keys{
            QStringLiteral("name"),
            QStringLiteral("knownName"),
            QStringLiteral("role"),
            QStringLiteral("label"),
            QStringLiteral("droid")
        };
        for (const QString& key : keys) {
            const QString value = meta.value(key).toString().trimmed();
            if (!value.isEmpty()) return value;
        }
        const QVariantList cells = row.value(QStringLiteral("cells")).toList();
        for (const QVariant& cell : cells) {
            const QString value = cell.toString().trimmed();
            if (value.isEmpty()) continue;
            if (isLikelyBase58AddressText(value)) continue;
            if (value.size() > 96) continue;
            return value;
        }
        return QString();
    };

    for (const QVariant& value : rows) {
        const QVariantMap row = value.toMap();
        const QVariantMap meta = row.value(QStringLiteral("meta")).toMap();
        QStringList addresses;
        const QStringList preferred_meta_keys{
            QStringLiteral("address"),
            QStringLiteral("legacyP2sh"),
            QStringLiteral("indexedP2sh"),
            QStringLiteral("sourceAddress"),
            QStringLiteral("targetAddress"),
            QStringLiteral("id")
        };
        for (const QString& key : preferred_meta_keys) {
            add_candidates(addresses, meta.value(key).toString());
        }
        const QVariantList cells = row.value(QStringLiteral("cells")).toList();
        for (const QVariant& cell : cells) {
            add_candidates(addresses, cell.toString());
        }
        addresses.removeDuplicates();
        if (addresses.isEmpty()) continue;

        const QString label = singleLineLimited(display_name_for_row(row, meta).trimmed(), 96);
        contacts.push_back(QVariantMap{
            {QStringLiteral("username"), label.isEmpty() ? QStringLiteral("Contact %1").arg(addresses.first().left(10)) : label},
            {QStringLiteral("addresses"), [&addresses]() {
                 QVariantList list;
                 for (const QString& address : addresses) list.push_back(address);
                 return list;
             }()},
            {QStringLiteral("addressText"), addresses.join(QStringLiteral(", "))}});
    }

    if (contacts.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No relationship contacts loaded"),
                           QStringLiteral("This table does not contain recognized Defcoin addresses."));
        return;
    }

    m_current_explorer_contact_set_name = clean_name;
    m_explorer_contacts = contacts;
    upsertExplorerContactSet(clean_name, contacts, QDateTime::currentSecsSinceEpoch());
    persistExplorerContactSets();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Relationship contacts loaded"),
                       QStringLiteral("Loaded %1 contact%2 from %3.")
                           .arg(QString::number(contacts.size()),
                                contacts.size() == 1 ? QString() : QStringLiteral("s"),
                                clean_name));
}

QString NuRpcService::coindroidsContactSetName(const QString& key) const
{
    const QString normalized = key.trimmed().toLower();
    if (normalized == QLatin1String("dc25-qr-seeds"))
        return QStringLiteral("Coindroids DC25 Eight Leads");
    if (normalized == QLatin1String("dc25-attack-cohort"))
        return QStringLiteral("Coindroids DC25 Attack Cohort");
    if (normalized == QLatin1String("dc25-source-ammo"))
        return QStringLiteral("Coindroids DC25 Source Ammo");
    if (normalized == QLatin1String("dc25-olo"))
        return QStringLiteral("Coindroids DC25 Olo");
    if (normalized == QLatin1String("dc25-investigation"))
        return QStringLiteral("Coindroids DC25 Investigation");
    return QString();
}

QVariantList NuRpcService::coindroidsContactsForSetKey(const QString& key) const
{
    const QString normalized = key.trimmed().toLower();
    QVariantList contacts;
    QSet<QString> seen_addresses;

    auto add_contact = [&contacts, &seen_addresses, this](const QString& raw_name, const QString& raw_address) {
        const QStringList clean_addresses = recognizedExplorerAddresses(QStringList{raw_address.trimmed()});
        if (clean_addresses.isEmpty()) return;
        const QString address = clean_addresses.first();
        if (seen_addresses.contains(address)) return;
        seen_addresses.insert(address);
        const QString fallback_name = QStringLiteral("Coindroids %1").arg(address.left(10));
        const QString name = singleLineLimited(raw_name.trimmed().isEmpty() ? fallback_name : raw_name, 96).trimmed();
        if (name.isEmpty()) return;
        contacts.push_back(QVariantMap{
            {QStringLiteral("username"), name},
            {QStringLiteral("addresses"), QVariantList{address}},
            {QStringLiteral("addressText"), address}});
    };

    auto add_rows = [&add_contact](const QVariantList& rows, const QString& prefix) {
        for (const QVariant& value : rows) {
            const QVariantMap row = value.toMap();
            const QVariantMap meta = row.value(QStringLiteral("meta")).toMap();
            const QString address = meta.value(QStringLiteral("address")).toString();
            const QString name = meta.value(QStringLiteral("name")).toString();
            add_contact(prefix + (name.isEmpty() ? address.left(10) : name), address);
        }
    };

    if (normalized == QLatin1String("dc25-qr-seeds")) {
        add_rows(m_coindroids_qr_seed_rows, QStringLiteral("Coindroids QR "));
        add_rows(m_coindroids_olo_rows, QStringLiteral("Coindroids "));
    } else if (normalized == QLatin1String("dc25-attack-cohort")) {
        add_rows(m_coindroids_attack_address_rows, QStringLiteral("Coindroids attack "));
    } else if (normalized == QLatin1String("dc25-source-ammo")) {
        add_rows(m_coindroids_source_ammo_rows, QStringLiteral("Coindroids source "));
    } else if (normalized == QLatin1String("dc25-olo")) {
        add_rows(m_coindroids_olo_rows, QStringLiteral("Coindroids "));
    } else if (normalized == QLatin1String("dc25-investigation")) {
        add_rows(m_coindroids_qr_seed_rows, QStringLiteral("Coindroids QR "));
        add_rows(m_coindroids_attack_address_rows, QStringLiteral("Coindroids attack "));
        add_rows(m_coindroids_source_ammo_rows, QStringLiteral("Coindroids source "));
        add_rows(m_coindroids_olo_rows, QStringLiteral("Coindroids "));
    }

    return contacts;
}

void NuRpcService::ensureCoindroidsPrebuiltContactSets(bool emit_signal)
{
    const QStringList keys{
        QStringLiteral("dc25-qr-seeds"),
        QStringLiteral("dc25-attack-cohort"),
        QStringLiteral("dc25-source-ammo"),
        QStringLiteral("dc25-olo"),
        QStringLiteral("dc25-investigation")
    };
    bool changed = false;
    const qint64 now = QDateTime::currentSecsSinceEpoch();
    for (const QString& key : keys) {
        const QString name = coindroidsContactSetName(key);
        const QVariantList contacts = coindroidsContactsForSetKey(key);
        if (name.isEmpty() || contacts.isEmpty()) continue;
        upsertExplorerContactSet(name, contacts, now);
        changed = true;
    }
    if (!changed) return;
    persistExplorerContactSets();
    if (emit_signal) Q_EMIT explorerChanged();
}

void NuRpcService::loadCoindroidsContactSet(const QString& key)
{
    if (m_coindroids_attack_address_rows.isEmpty() &&
        m_coindroids_qr_seed_rows.isEmpty() &&
        m_coindroids_source_ammo_rows.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Coindroids contact set not ready"),
                           QStringLiteral("Refresh Droid Trails first so Nu Explore can build the prebuilt Coindroids contact sets."));
        return;
    }
    const QString name = coindroidsContactSetName(key);
    const QVariantList contacts = coindroidsContactsForSetKey(key);
    if (name.isEmpty() || contacts.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Coindroids contact set not ready"),
                           QStringLiteral("That Coindroids relationship set has no addresses in the loaded analysis."));
        return;
    }

    const qint64 now = QDateTime::currentSecsSinceEpoch();
    upsertExplorerContactSet(name, contacts, now);
    m_current_explorer_contact_set_name = name;
    m_explorer_contacts = contacts;
    persistExplorerContactSets();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Coindroids contact set loaded"),
                       QStringLiteral("Loaded %1 addresses into %2 for relationship graphing.")
                           .arg(QString::number(contacts.size()), name));
    Q_EMIT explorerChanged();
}

void NuRpcService::importCoindroidsGameContacts()
{
    if (m_coindroids_game_address_rows.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No Coindroids contacts imported"),
                           QStringLiteral("Refresh Droid Trails first so the DC25 payout hunt and game-address leads are loaded."));
        return;
    }

    QSet<QString> existing_addresses;
    QHash<QString, int> index_by_name;
    for (int i = 0; i < m_explorer_contacts.size(); ++i) {
        const QVariantMap contact = m_explorer_contacts.at(i).toMap();
        const QString username = contact.value(QStringLiteral("username")).toString().trimmed();
        if (!username.isEmpty()) index_by_name.insert(username, i);
        for (const QVariant& address_value : contact.value(QStringLiteral("addresses")).toList()) {
            const QString address = address_value.toString().trimmed();
            if (!address.isEmpty()) existing_addresses.insert(address);
        }
    }

    int added = 0;
    int updated = 0;
    int skipped = 0;
    for (const QVariant& row_value : m_coindroids_game_address_rows) {
        const QVariantMap row = row_value.toMap();
        const QVariantMap meta = row.value(QStringLiteral("meta")).toMap();
        const QString address = meta.value(QStringLiteral("address")).toString().trimmed();
        const QStringList clean_addresses = recognizedExplorerAddresses(QStringList{address});
        if (clean_addresses.isEmpty()) {
            ++skipped;
            continue;
        }
        const QString clean_address = clean_addresses.first();
        if (existing_addresses.contains(clean_address)) {
            ++skipped;
            continue;
        }
        const QString contact_name = singleLineLimited(
            meta.value(QStringLiteral("contactName")).toString().trimmed().isEmpty()
                ? QStringLiteral("Coindroids lead %1").arg(clean_address.left(10))
                : meta.value(QStringLiteral("contactName")).toString(),
            96).trimmed();
        if (contact_name.isEmpty()) {
            ++skipped;
            continue;
        }

        const int existing_index = index_by_name.value(contact_name, -1);
        if (existing_index >= 0 && existing_index < m_explorer_contacts.size()) {
            QVariantMap contact = m_explorer_contacts.at(existing_index).toMap();
            QVariantList addresses = contact.value(QStringLiteral("addresses")).toList();
            QStringList address_strings;
            for (const QVariant& value : addresses) address_strings.push_back(value.toString());
            address_strings.push_back(clean_address);
            address_strings.removeDuplicates();
            addresses.clear();
            for (const QString& value : address_strings) addresses.push_back(value);
            contact.insert(QStringLiteral("addresses"), addresses);
            contact.insert(QStringLiteral("addressText"), address_strings.join(QStringLiteral(", ")));
            m_explorer_contacts[existing_index] = contact;
            ++updated;
        } else {
            QVariantList addresses;
            addresses.push_back(clean_address);
            m_explorer_contacts.push_back(QVariantMap{
                {QStringLiteral("username"), contact_name},
                {QStringLiteral("addresses"), addresses},
                {QStringLiteral("addressText"), clean_address}});
            index_by_name.insert(contact_name, m_explorer_contacts.size() - 1);
            ++added;
        }
        existing_addresses.insert(clean_address);
    }

    if (added == 0 && updated == 0) {
        Q_EMIT userMessage(QStringLiteral("No Coindroids contacts imported"),
                           QStringLiteral("All loaded Coindroids game-address leads were already present or were not valid Defcoin addresses."));
        return;
    }

    persistExplorerContacts();
    refreshExplorerContactRelationships();
    Q_EMIT userMessage(QStringLiteral("Coindroids contacts imported"),
                       QStringLiteral("Added %1 contact%2, updated %3, skipped %4 existing or invalid address%5.")
                           .arg(QString::number(added),
                                added == 1 ? QString() : QStringLiteral("s"),
                                QString::number(updated),
                                QString::number(skipped),
                                skipped == 1 ? QString() : QStringLiteral("es")));
}

void NuRpcService::refreshCoindroidsAnalytics()
{
    const qint64 now_ms = QDateTime::currentMSecsSinceEpoch();
    if (m_coindroids_scanning) {
        m_coindroids_status = QStringLiteral("Coindroids analysis is already reading the local explorer index.");
        Q_EMIT explorerChanged();
        return;
    }
    if (!m_coindroids_window_rows.isEmpty() && m_coindroids_last_refresh_ms > 0 &&
        now_ms - m_coindroids_last_refresh_ms < 30000) {
        return;
    }

    const int generation = ++m_coindroids_generation;
    m_coindroids_scanning = true;
    m_coindroids_status = QStringLiteral("Coindroids analysis loading: scanning launch windows, action-cost endpoints, and payout swarms.");
    Q_EMIT explorerChanged();

    QPointer<NuRpcService> guard(this);
    QThread* thread = QThread::create([guard, generation] {
        if (!guard) return;
        QString error;
        QVariantMap analysis = guard->coindroidsAnalyticsFromDb(&error);
        QMetaObject::invokeMethod(guard, [guard, generation, analysis = std::move(analysis), error]() mutable {
            if (!guard || generation != guard->m_coindroids_generation) return;
            guard->m_coindroids_scanning = false;
            guard->m_coindroids_last_refresh_ms = QDateTime::currentMSecsSinceEpoch();
            if (!error.isEmpty()) {
                guard->m_coindroids_status = QStringLiteral("Coindroids analysis could not load: %1").arg(error);
            } else {
                guard->m_coindroids_summary = analysis.value(QStringLiteral("summary")).toMap();
                guard->m_coindroids_window_rows = analysis.value(QStringLiteral("windows")).toList();
                guard->m_coindroids_endpoint_rows = analysis.value(QStringLiteral("endpoints")).toList();
                guard->m_coindroids_winner_rows = analysis.value(QStringLiteral("winners")).toList();
                guard->m_coindroids_phase_rows = analysis.value(QStringLiteral("phases")).toList();
                guard->m_coindroids_published_rows = analysis.value(QStringLiteral("published")).toList();
                guard->m_coindroids_vanity_rows = analysis.value(QStringLiteral("vanity")).toList();
                guard->m_coindroids_op_return_rows = analysis.value(QStringLiteral("opReturns")).toList();
                guard->m_coindroids_bot_rows = analysis.value(QStringLiteral("bots")).toList();
                guard->m_coindroids_payout_rows = analysis.value(QStringLiteral("payouts")).toList();
                guard->m_coindroids_attack_address_rows = analysis.value(QStringLiteral("attackAddresses")).toList();
                guard->m_coindroids_qr_seed_rows = analysis.value(QStringLiteral("qrSeeds")).toList();
                guard->m_coindroids_source_ammo_rows = analysis.value(QStringLiteral("sourceAmmo")).toList();
                guard->m_coindroids_olo_rows = analysis.value(QStringLiteral("oloCandidates")).toList();
                guard->m_coindroids_game_address_rows = analysis.value(QStringLiteral("gameAddresses")).toList();
                guard->m_coindroids_evidence_rows = analysis.value(QStringLiteral("evidence")).toList();
                guard->ensureCoindroidsPrebuiltContactSets(false);
                const QString cache_status = guard->m_coindroids_summary.value(QStringLiteral("droidTrailsCacheStatus")).toString();
                const QString cache_label = cache_status == QLatin1String("hit")
                    ? QStringLiteral("Loaded saved Droid Trails DB")
                    : QStringLiteral("Rebuilt Droid Trails DB");
                guard->m_coindroids_status = QStringLiteral("%1 v%2: %3 candidate endpoint clusters, %4 payout recipients, %5 DC25 point-balance payout leads, %6 game-address leads, %7 launch-window 0.1337 DFC swarm outputs, %8 vanity-response candidates, %9 OP_RETURN payload candidates, %10 bot/reload candidates, %11 DC25 attack-address rows, %12 source/ammo clips. Published DC25 payouts are treated as point-in-time measurements, not final balances. Major processing shift: 2017-07-25 dust/amount era toward mempool and payload-aware processing.")
                    .arg(cache_label,
                         guard->m_coindroids_summary.value(QStringLiteral("droidTrailsCacheVersion")).toString(),
                         QString::number(guard->m_coindroids_endpoint_rows.size()),
                         QString::number(guard->m_coindroids_winner_rows.size()),
                         QString::number(guard->m_coindroids_payout_rows.size()),
                         QString::number(guard->m_coindroids_game_address_rows.size()),
                         guard->m_coindroids_summary.value(QStringLiteral("launch1337Outputs")).toString(),
                         QString::number(guard->m_coindroids_vanity_rows.size()),
                         QString::number(guard->m_coindroids_op_return_rows.size()),
                         QString::number(guard->m_coindroids_bot_rows.size()),
                         QString::number(guard->m_coindroids_attack_address_rows.size()),
                         QString::number(guard->m_coindroids_source_ammo_rows.size()));
            }
            Q_EMIT guard->explorerChanged();
        }, Qt::QueuedConnection);
    });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    thread->start(QThread::LowPriority);
}

void NuRpcService::refreshExplorerAnalytics(int movement_threshold_coins, const QString& scope)
{
    const int bounded_coins = std::max(0, movement_threshold_coins);
    const qint64 threshold_sats = static_cast<qint64>(bounded_coins) * 100000000LL;
    QString normalized_scope = scope.trimmed().toLower();
    if (normalized_scope != QLatin1String("rich") &&
        normalized_scope != QLatin1String("movements") &&
        normalized_scope != QLatin1String("all")) {
        normalized_scope = QStringLiteral("all");
    }
    const bool load_rich = normalized_scope == QLatin1String("rich") || normalized_scope == QLatin1String("all");
    const bool load_movements = normalized_scope == QLatin1String("movements") || normalized_scope == QLatin1String("all");

    const qint64 now_ms = QDateTime::currentMSecsSinceEpoch();
    if (m_explorer_analytics_refreshing) {
        m_explorer_analytics_status = QStringLiteral("Explorer analytics are loading in the background.");
        Q_EMIT explorerChanged();
        return;
    }
    if (m_explorer_analytics_last_threshold_coins == bounded_coins &&
        m_explorer_analytics_last_scope == normalized_scope &&
        m_explorer_analytics_last_refresh_ms > 0 &&
        now_ms - m_explorer_analytics_last_refresh_ms < 30000 &&
        ((load_rich && !m_explorer_rich_list.isEmpty()) ||
         (load_movements && !m_explorer_movements.isEmpty()))) {
        return;
    }

    const int generation = ++m_explorer_analytics_generation;
    m_explorer_analytics_refreshing = true;
    const int total_steps = (load_rich ? 1 : 0) + (load_movements ? 1 : 0);
    m_explorer_analytics_status = QStringLiteral("Explorer analytics loading: 0% complete. Starting %1%2.")
        .arg(load_rich ? QStringLiteral("Holder Atlas") : QString())
        .arg(load_rich && load_movements ? QStringLiteral(" and Movements") : (load_movements ? QStringLiteral("Movements") : QString()));
    Q_EMIT explorerChanged();

    QPointer<NuRpcService> guard(this);
    QThread* thread = QThread::create([guard, bounded_coins, threshold_sats, generation, normalized_scope, load_rich, load_movements, total_steps] {
        if (!guard) return;
        QString rich_error;
        QString movement_error;
        QVariantList rich_list;
        QVariantList movements;
        int completed_steps = 0;
        const qint64 started_ms = QDateTime::currentMSecsSinceEpoch();
        auto publish_progress = [guard, generation, total_steps, started_ms](int completed, const QString& label) {
            QMetaObject::invokeMethod(guard, [guard, generation, total_steps, started_ms, completed, label] {
                if (!guard || generation != guard->m_explorer_analytics_generation || !guard->m_explorer_analytics_refreshing) return;
                const int percent = total_steps > 0 ? std::clamp((completed * 100) / total_steps, 0, 99) : 0;
                QString eta_text = QStringLiteral("ETA estimating");
                if (completed > 0 && completed < total_steps) {
                    const qint64 elapsed_ms = std::max<qint64>(1, QDateTime::currentMSecsSinceEpoch() - started_ms);
                    const qint64 eta_ms = (elapsed_ms * (total_steps - completed)) / completed;
                    eta_text = QStringLiteral("ETA %1").arg(formatDurationFromSeconds(eta_ms / 1000));
                } else if (completed >= total_steps) {
                    eta_text = QStringLiteral("ETA done");
                }
                guard->m_explorer_analytics_status = QStringLiteral("Explorer analytics loading: %1% complete. %2 %3.")
                    .arg(QString::number(percent), label, eta_text);
                Q_EMIT guard->explorerChanged();
            }, Qt::QueuedConnection);
        };
        if (load_rich) {
            publish_progress(completed_steps, QStringLiteral("Reading largest-holder balances from the local SQLite index."));
            rich_list = guard->explorerRichListFromDb(&rich_error);
            publish_progress(++completed_steps, QStringLiteral("Holder Atlas loaded; continuing analytics."));
        }
        if (load_movements) {
            publish_progress(completed_steps, QStringLiteral("Reading movement rows from the local SQLite index."));
            movements = guard->explorerMovementsFromDb(threshold_sats, &movement_error);
            publish_progress(++completed_steps, QStringLiteral("Movement rows loaded; finalizing."));
        }
        QMetaObject::invokeMethod(guard, [guard, generation, bounded_coins, normalized_scope, load_rich, load_movements, rich_list = std::move(rich_list), movements = std::move(movements), rich_error, movement_error]() mutable {
            if (!guard || generation != guard->m_explorer_analytics_generation) return;
            guard->m_explorer_analytics_refreshing = false;
            guard->m_explorer_analytics_last_threshold_coins = bounded_coins;
            guard->m_explorer_analytics_last_scope = normalized_scope;
            guard->m_explorer_analytics_last_refresh_ms = QDateTime::currentMSecsSinceEpoch();
            if (load_rich) guard->m_explorer_rich_list = std::move(rich_list);
            if (load_movements) guard->m_explorer_movements = std::move(movements);
            guard->refreshExplorerTop100TimelineStats();
            if (!rich_error.isEmpty() || !movement_error.isEmpty()) {
                QStringList details;
                if (!rich_error.isEmpty()) details.push_back(QStringLiteral("Holder Atlas: %1").arg(rich_error));
                if (!movement_error.isEmpty()) details.push_back(QStringLiteral("Movements: %1").arg(movement_error));
                guard->m_explorer_analytics_status = QStringLiteral("Explorer analytics could not fully load. %1").arg(details.join(QStringLiteral(" ")));
            } else if (load_rich && load_movements) {
                guard->m_explorer_analytics_status = QStringLiteral("Loaded Holder Atlas and %1 movement rows at %2+ DFC from the local SQLite index.")
                    .arg(QString::number(guard->m_explorer_movements.size()), QString::number(bounded_coins));
            } else if (load_rich) {
                guard->m_explorer_analytics_status = QStringLiteral("Loaded Holder Atlas from the local SQLite index.");
            } else if (load_movements) {
                guard->m_explorer_analytics_status = QStringLiteral("Loaded %1 movement rows at %2+ DFC from the local SQLite index.")
                    .arg(QString::number(guard->m_explorer_movements.size()), QString::number(bounded_coins));
            } else {
                guard->m_explorer_analytics_status = QStringLiteral("Explorer analytics are current.");
            }
            Q_EMIT guard->explorerChanged();
        }, Qt::QueuedConnection);
    });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    thread->start(QThread::LowPriority);
}

QString NuRpcService::explorerBlockHashAtHeight(int height) const
{
    if (height < 0) return QString();
    QString error;
    if (!ensureExplorerDatabase(&error)) return QString();
    QString hash;
    const QString connection_name = QStringLiteral("nu_explorer_height_hash_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            query.prepare(QStringLiteral("SELECT hash FROM explorer_blocks WHERE height = ?"));
            query.addBindValue(height);
            if (query.exec() && query.next()) hash = query.value(0).toString();
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    return hash;
}

QString NuRpcService::explorerBlockHashForTransaction(const QString& txid) const
{
    const QString clean_txid = txid.trimmed();
    if (clean_txid.isEmpty()) return QString();
    QString error;
    if (!ensureExplorerDatabase(&error)) return QString();
    QString block_hash;
    const QString connection_name = QStringLiteral("nu_explorer_txblock_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "SELECT b.hash FROM explorer_blocks b "
                "JOIN explorer_block_transactions t ON t.block_height = b.height "
                "WHERE t.txid = ? ORDER BY b.height DESC LIMIT 1"));
            query.addBindValue(clean_txid);
            if (query.exec() && query.next()) {
                block_hash = query.value(0).toString();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    return block_hash;
}

QString NuRpcService::explorerCachedBlockHtml(const QString& block_id, QJsonObject* raw_json, bool* found) const
{
    if (found) *found = false;
    if (raw_json) *raw_json = QJsonObject();
    const QString clean = block_id.trimmed();
    if (clean.isEmpty()) return QString();
    QString error;
    if (!ensureExplorerDatabase(&error)) return QString();

    bool is_height = false;
    const int requested_height = clean.toInt(&is_height);
    int height = -1;
    QString hash;
    qint64 block_time = 0;
    int tx_count = 0;
    QJsonObject raw;
    QString tx_rows;

    const QString connection_name = QStringLiteral("nu_explorer_cached_block_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery block_query(db);
            block_query.prepare(is_height
                ? QStringLiteral("SELECT height, hash, time, tx_count, raw_json FROM explorer_blocks WHERE height = ?")
                : QStringLiteral("SELECT height, hash, time, tx_count, raw_json FROM explorer_blocks WHERE hash = ?"));
            block_query.addBindValue(is_height ? QVariant(requested_height) : QVariant(clean));
            if (block_query.exec() && block_query.next()) {
                height = block_query.value(0).toInt();
                hash = block_query.value(1).toString();
                block_time = block_query.value(2).toLongLong();
                tx_count = block_query.value(3).toInt();
                raw = QJsonDocument::fromJson(block_query.value(4).toString().toUtf8()).object();
            }

            if (height >= 0) {
                QSqlQuery tx_query(db);
                tx_query.prepare(QStringLiteral("SELECT tx_index, txid FROM explorer_block_transactions WHERE block_height = ? ORDER BY tx_index ASC LIMIT 25"));
                tx_query.addBindValue(height);
                if (tx_query.exec()) {
                    while (tx_query.next()) {
                        const QString txid = tx_query.value(1).toString();
                        tx_rows += QStringLiteral("<tr><td>%1</td><td><a href=\"nu://transaction/%2\">%3</a></td></tr>")
                            .arg(QString::number(tx_query.value(0).toInt()).toHtmlEscaped(),
                                 QString::fromLatin1(QUrl::toPercentEncoding(txid)).toHtmlEscaped(),
                                 txid.toHtmlEscaped());
                    }
                }
            }
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connection_name);

    if (height < 0) return QString();
    if (found) *found = true;
    if (raw_json) *raw_json = raw;
    if (tx_rows.isEmpty()) tx_rows = QStringLiteral("<tr><td colspan=\"2\">No indexed transactions available.</td></tr>");
    if (tx_count > 25) {
        tx_rows += QStringLiteral("<tr><td colspan=\"2\">%1 more transactions omitted from the compact cached view.</td></tr>")
            .arg(QString::number(tx_count - 25).toHtmlEscaped());
    }

    return QStringLiteral(
        "<table>"
        "<tr><th>Height</th><td>%1</td></tr>"
        "<tr><th>Hash</th><td>%2</td></tr>"
        "<tr><th>Time</th><td>%3</td></tr>"
        "<tr><th>Transactions</th><td>%4</td></tr>"
        "<tr><th>Source</th><td>Local SQLite explorer index</td></tr>"
        "</table>"
        "<h3>Indexed transactions</h3><table><tr><th>N</th><th>Transaction ID</th></tr>%5</table>")
        .arg(QString::number(height).toHtmlEscaped(),
             hash.toHtmlEscaped(),
             QDateTime::fromSecsSinceEpoch(block_time).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t")).toHtmlEscaped(),
             QString::number(tx_count).toHtmlEscaped(),
             tx_rows);
}

QString NuRpcService::explorerIndexedTransactionHtml(const QString& txid, QJsonObject* raw_json, bool* found) const
{
    if (found) *found = false;
    if (raw_json) *raw_json = QJsonObject();
    const QString clean_txid = txid.trimmed();
    if (clean_txid.isEmpty()) return QString();
    QString error;
    if (!ensureExplorerDatabase(&error)) return QString();

    int height = -1;
    int tx_index = -1;
    QString block_hash;
    QString output_rows;
    qint64 output_total_sats = 0;
    int output_count = 0;

    const QString connection_name = QStringLiteral("nu_explorer_indexed_tx_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery tx_query(db);
            tx_query.prepare(QStringLiteral(
                "SELECT t.block_height, t.tx_index, b.hash "
                "FROM explorer_block_transactions t JOIN explorer_blocks b ON b.height = t.block_height "
                "WHERE t.txid = ? ORDER BY t.block_height DESC LIMIT 1"));
            tx_query.addBindValue(clean_txid);
            if (tx_query.exec() && tx_query.next()) {
                height = tx_query.value(0).toInt();
                tx_index = tx_query.value(1).toInt();
                block_hash = tx_query.value(2).toString();
            }

            if (height >= 0) {
                QSqlQuery out_query(db);
                out_query.prepare(QStringLiteral(
                    "SELECT vout, address, value_sats, spent_by_txid "
                    "FROM explorer_tx_outputs WHERE txid = ? "
                    "ORDER BY vout ASC, address ASC LIMIT 200"));
                out_query.addBindValue(clean_txid);
                if (out_query.exec()) {
                    while (out_query.next()) {
                        const QString address = out_query.value(1).toString();
                        const qint64 value_sats = out_query.value(2).toLongLong();
                        const QString spent_by = out_query.value(3).toString();
                        ++output_count;
                        output_total_sats += value_sats;
                        output_rows += QStringLiteral("<tr><td>%1</td><td>%2</td><td><a href=\"nu://address/%3\">%4</a></td><td>%5</td></tr>")
                            .arg(QString::number(out_query.value(0).toInt()).toHtmlEscaped(),
                                 explorerAmountText(value_sats).toHtmlEscaped(),
                                 QString::fromLatin1(QUrl::toPercentEncoding(address)).toHtmlEscaped(),
                                 address.toHtmlEscaped(),
                                 spent_by.isEmpty()
                                    ? QStringLiteral("Unspent").toHtmlEscaped()
                                    : QStringLiteral("<a href=\"nu://transaction/%1\">Spent</a>").arg(QString::fromLatin1(QUrl::toPercentEncoding(spent_by)).toHtmlEscaped()));
                    }
                }
            }
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connection_name);

    if (height < 0) return QString();
    if (found) *found = true;
    QJsonObject raw;
    raw.insert(QStringLiteral("txid"), clean_txid);
    raw.insert(QStringLiteral("source"), QStringLiteral("local SQLite explorer index"));
    raw.insert(QStringLiteral("blockHeight"), height);
    raw.insert(QStringLiteral("blockHash"), block_hash);
    raw.insert(QStringLiteral("txIndex"), tx_index);
    if (raw_json) *raw_json = raw;
    if (output_rows.isEmpty()) output_rows = QStringLiteral("<tr><td colspan=\"4\">No standard address outputs indexed for this transaction.</td></tr>");

    const QString block_link = QStringLiteral("<a href=\"nu://block/%1\">%2</a>")
        .arg(QString::fromLatin1(QUrl::toPercentEncoding(block_hash)).toHtmlEscaped(), block_hash.toHtmlEscaped());
    return QStringLiteral(
        "<table>"
        "<tr><th>Transaction ID</th><td>%1</td></tr>"
        "<tr><th>Block</th><td>%2</td></tr>"
        "<tr><th>Block height</th><td>%3</td></tr>"
        "<tr><th>Block tx index</th><td>%4</td></tr>"
        "<tr><th>Indexed output total</th><td>%5</td></tr>"
        "<tr><th>Source</th><td>Local SQLite explorer index</td></tr>"
        "</table>"
        "<p>This cached view is compact. Connect the backend for full raw transaction JSON and input details.</p>"
        "<h3>Indexed outputs</h3><table><tr><th>N</th><th>Value</th><th>Address</th><th>Status</th></tr>%6</table>")
        .arg(clean_txid.toHtmlEscaped(),
             block_link,
             QString::number(height).toHtmlEscaped(),
             QString::number(tx_index).toHtmlEscaped(),
             explorerAmountText(output_total_sats).toHtmlEscaped(),
             output_rows);
}

QString NuRpcService::explorerIndexedAddressHtml(const QString& address, bool* found) const
{
    if (found) *found = false;
    const QString clean_address = address.trimmed();
    if (clean_address.isEmpty()) return QString();
    QString error;
    if (!ensureExplorerDatabase(&error)) return QString();

    qint64 received_sats = 0;
    qint64 spent_sats = 0;
    int output_count = 0;
    int spent_output_count = 0;
    int tx_count = 0;
    int first_height = -1;
    int last_height = -1;
    QString rows;

    const QString connection_name = QStringLiteral("nu_explorer_address_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery summary(db);
            summary.prepare(QStringLiteral(
                "SELECT COUNT(*), COUNT(DISTINCT txid), "
                "COALESCE(SUM(value_sats), 0), "
                "COALESCE(SUM(CASE WHEN spent_by_txid IS NOT NULL THEN value_sats ELSE 0 END), 0), "
                "COALESCE(SUM(CASE WHEN spent_by_txid IS NOT NULL THEN 1 ELSE 0 END), 0), "
                "MIN(block_height), MAX(block_height) "
                "FROM explorer_tx_outputs WHERE address = ?"));
            summary.addBindValue(clean_address);
            if (summary.exec() && summary.next()) {
                output_count = summary.value(0).toInt();
                tx_count = summary.value(1).toInt();
                received_sats = summary.value(2).toLongLong();
                spent_sats = summary.value(3).toLongLong();
                spent_output_count = summary.value(4).toInt();
                if (!summary.value(5).isNull()) first_height = summary.value(5).toInt();
                if (!summary.value(6).isNull()) last_height = summary.value(6).toInt();
            }

            if (output_count > 0) {
                QSqlQuery detail(db);
                detail.prepare(QStringLiteral(
                    "SELECT block_height, txid, vout, value_sats, spent_by_txid "
                    "FROM explorer_tx_outputs WHERE address = ? "
                    "ORDER BY block_height DESC, txid DESC, vout ASC LIMIT 200"));
                detail.addBindValue(clean_address);
                if (detail.exec()) {
                    while (detail.next()) {
                        const QString txid = detail.value(1).toString();
                        const QString spent_by = detail.value(4).toString();
                        rows += QStringLiteral("<tr><td>%1</td><td><a href=\"nu://transaction/%2\">%3</a></td><td>%4</td><td>%5</td><td>%6</td></tr>")
                            .arg(QString::number(detail.value(0).toInt()).toHtmlEscaped(),
                                 QString::fromLatin1(QUrl::toPercentEncoding(txid)).toHtmlEscaped(),
                                 txid.toHtmlEscaped(),
                                 QString::number(detail.value(2).toInt()).toHtmlEscaped(),
                                 explorerAmountText(detail.value(3).toLongLong()).toHtmlEscaped(),
                                 spent_by.isEmpty()
                                    ? QStringLiteral("Unspent").toHtmlEscaped()
                                    : QStringLiteral("<a href=\"nu://transaction/%1\">Spent</a>").arg(QString::fromLatin1(QUrl::toPercentEncoding(spent_by)).toHtmlEscaped()));
                    }
                }
            }
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connection_name);

    if (output_count <= 0) return QString();
    if (found) *found = true;

    const qint64 balance_sats = received_sats - spent_sats;
    QString coverage = QStringLiteral("Indexed outputs from block %1 to %2.")
        .arg(QString::number(first_height), QString::number(last_height));
    const int highest = explorerHighestIndexedBlock();
    if (highest >= 0) {
        coverage += QStringLiteral(" Local index currently reaches block %1.").arg(QString::number(highest));
    }
    if (rows.isEmpty()) rows = QStringLiteral("<tr><td colspan=\"5\">No recent outputs available.</td></tr>");

    return QStringLiteral(
        "<table>"
        "<tr><th>Address</th><td>%1</td></tr>"
        "<tr><th>Total received</th><td>%2</td></tr>"
        "<tr><th>Spent outputs</th><td>%3 across %4 outputs</td></tr>"
        "<tr><th>Indexed balance</th><td>%5</td></tr>"
        "<tr><th>Transactions</th><td>%6 indexed txs / %7 outputs</td></tr>"
        "<tr><th>Coverage</th><td>%8</td></tr>"
        "</table>"
        "<p>This is chain-index data from the local SQLite cache. It is complete only through the indexed block height shown above.</p>"
        "<h3>Recent indexed outputs</h3>"
        "<table><tr><th>Height</th><th>Transaction ID</th><th>Vout</th><th>Value</th><th>Status</th></tr>%9</table>")
        .arg(clean_address.toHtmlEscaped(),
             explorerAmountText(received_sats).toHtmlEscaped(),
             explorerAmountText(spent_sats).toHtmlEscaped(),
             QString::number(spent_output_count).toHtmlEscaped(),
             explorerAmountText(balance_sats).toHtmlEscaped(),
             QString::number(tx_count).toHtmlEscaped(),
             QString::number(output_count).toHtmlEscaped(),
             coverage.toHtmlEscaped(),
             rows);
}

bool NuRpcService::explorerPruneFromHeight(int height, QString* error)
{
    const int prune_height = std::max(0, height);
    QString db_error;
    if (!ensureExplorerDatabase(&db_error)) {
        if (error) *error = db_error;
        return false;
    }

    const QString connection_name = QStringLiteral("nu_explorer_prune_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        ok = db.open();
        if (!ok) {
            local_error = db.lastError().text();
        } else {
            ok = db.transaction();
            if (!ok) local_error = db.lastError().text();
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("UPDATE explorer_tx_outputs SET spent_by_txid = NULL, spent_in_height = NULL, spent_vin = NULL WHERE spent_in_height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_tx_outputs WHERE block_height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_op_returns WHERE block_height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_block_transactions WHERE block_height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_blocks WHERE height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_balance_deltas WHERE height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_top100_events WHERE height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_top100_ranges WHERE end_height >= ?"));
                query.addBindValue(prune_height);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('last_indexed_height', ?)"));
                query.addBindValue(QString::number(prune_height - 1));
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('balance_deltas_height', ?)"));
                query.addBindValue(QString::number(prune_height - 1));
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            qint64 output_count_after_prune = 0;
            if (ok) {
                QSqlQuery query(db);
                if (query.exec(QStringLiteral("SELECT COUNT(*) FROM explorer_tx_outputs")) && query.next()) {
                    output_count_after_prune = query.value(0).toLongLong();
                } else {
                    ok = false;
                    local_error = query.lastError().text();
                }
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('indexed_block_count', ?)"));
                query.addBindValue(QString::number(std::max(0, prune_height)));
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('indexed_output_count', ?)"));
                query.addBindValue(QString::number(output_count_after_prune));
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                ok = db.commit();
                if (!ok) local_error = db.lastError().text();
            } else {
                db.rollback();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok && error) *error = local_error;
    return ok;
}

bool NuRpcService::storeExplorerBlock(const QJsonObject& block, QString* error)
{
    return storeExplorerBlocks(QVector<QJsonObject>{block}, nullptr, error);
}

bool NuRpcService::storeExplorerBlocks(const QVector<QJsonObject>& blocks, int* output_rows_written, QString* error)
{
    if (output_rows_written) *output_rows_written = 0;
    if (blocks.isEmpty()) return true;

    QString db_error;
    if (!ensureExplorerDatabase(&db_error)) {
        if (error) *error = db_error;
        return false;
    }
    const QString connection_name = QStringLiteral("nu_explorer_block_write_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        ok = db.open();
        if (!ok) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery pragma(db);
            pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
            pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
            pragma.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));
            if (m_explorer_top100_focused_indexing) {
                pragma.exec(QStringLiteral("PRAGMA cache_size=-262144"));
                pragma.exec(QStringLiteral("PRAGMA mmap_size=268435456"));
            } else {
                pragma.exec(QStringLiteral("PRAGMA cache_size=-65536"));
            }
            qint64 starting_output_count = -1;
            {
                QSqlQuery count_query(db);
                count_query.prepare(QStringLiteral("SELECT value FROM explorer_meta WHERE key = 'indexed_output_count'"));
                if (count_query.exec() && count_query.next()) {
                    starting_output_count = count_query.value(0).toLongLong();
                }
                if (starting_output_count < 0 &&
                    count_query.exec(QStringLiteral("SELECT COUNT(*) FROM explorer_tx_outputs")) &&
                    count_query.next()) {
                    starting_output_count = count_query.value(0).toLongLong();
                }
                if (starting_output_count < 0) starting_output_count = 0;
            }
            ok = db.transaction();
            if (!ok) local_error = db.lastError().text();

            QSqlQuery block_query(db);
            QSqlQuery delete_tx_query(db);
            QSqlQuery delete_out_query(db);
            QSqlQuery delete_op_return_query(db);
            QSqlQuery delete_delta_query(db);
            QSqlQuery previous_output_count_query(db);
            QSqlQuery tx_query(db);
            QSqlQuery output_query(db);
            QSqlQuery op_return_query(db);
            QSqlQuery spend_lookup_query(db);
            QSqlQuery spend_query(db);
            QSqlQuery delta_query(db);
            QSqlQuery meta_query(db);
            if (ok) ok = block_query.prepare(QStringLiteral(
                "INSERT INTO explorer_blocks(height, hash, time, tx_count, raw_json, indexed_at) "
                "VALUES(?, ?, ?, ?, ?, ?) "
                "ON CONFLICT(height) DO UPDATE SET "
                "hash=excluded.hash, time=excluded.time, tx_count=excluded.tx_count, raw_json=excluded.raw_json, indexed_at=excluded.indexed_at"));
            if (ok) ok = previous_output_count_query.prepare(QStringLiteral("SELECT COUNT(*) FROM explorer_tx_outputs WHERE block_height = ?"));
            if (ok) ok = delete_tx_query.prepare(QStringLiteral("DELETE FROM explorer_block_transactions WHERE block_height = ?"));
            if (ok) ok = delete_out_query.prepare(QStringLiteral("DELETE FROM explorer_tx_outputs WHERE block_height = ?"));
            if (ok) ok = delete_op_return_query.prepare(QStringLiteral("DELETE FROM explorer_op_returns WHERE block_height = ?"));
            if (ok) ok = delete_delta_query.prepare(QStringLiteral("DELETE FROM explorer_balance_deltas WHERE height = ?"));
            if (ok) ok = tx_query.prepare(QStringLiteral("INSERT INTO explorer_block_transactions(block_height, tx_index, txid) VALUES(?, ?, ?)"));
            if (ok) ok = output_query.prepare(QStringLiteral(
                "INSERT OR REPLACE INTO explorer_tx_outputs("
                "txid, vout, block_height, address, value_sats, value_text, script_type, spent_by_txid, spent_in_height, spent_vin) "
                "VALUES(?, ?, ?, ?, ?, ?, ?, NULL, NULL, NULL)"));
            if (ok) ok = op_return_query.prepare(QStringLiteral(
                "INSERT OR REPLACE INTO explorer_op_returns("
                "txid, vout, block_height, value_sats, script_hex, payload_hex, payload_text) "
                "VALUES(?, ?, ?, ?, ?, ?, ?)"));
            if (ok) ok = spend_lookup_query.prepare(QStringLiteral(
                "SELECT address, value_sats FROM explorer_tx_outputs WHERE txid = ? AND vout = ?"));
            if (ok) ok = spend_query.prepare(QStringLiteral(
                "UPDATE explorer_tx_outputs "
                "SET spent_by_txid = ?, spent_in_height = ?, spent_vin = ? "
                "WHERE txid = ? AND vout = ?"));
            if (ok) ok = delta_query.prepare(QStringLiteral(
                "INSERT INTO explorer_balance_deltas(height, address, delta_sats) "
                "VALUES(?, ?, ?) "
                "ON CONFLICT(height, address) DO UPDATE SET delta_sats = delta_sats + excluded.delta_sats"));
            if (ok) ok = meta_query.prepare(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES(?, ?)"));
            if (!ok) local_error = db.lastError().text();

            int last_height = -1;
            int local_output_rows = 0;
            int local_removed_output_rows = 0;
            const qint64 indexed_at = QDateTime::currentSecsSinceEpoch();
            for (const QJsonObject& block : blocks) {
                if (!ok) break;
                const int height = block.value(QStringLiteral("height")).toInt(-1);
                const QString hash = block.value(QStringLiteral("hash")).toString();
                const QJsonArray txs = block.value(QStringLiteral("tx")).toArray();
                if (height < 0 || hash.isEmpty()) {
                    ok = false;
                    local_error = QStringLiteral("Block JSON did not include a height and hash.");
                    break;
                }
                last_height = height;

                QJsonArray compact_txs;
                for (const QJsonValue& value : txs) {
                    QString txid = value.toString();
                    if (txid.isEmpty()) txid = value.toObject().value(QStringLiteral("txid")).toString();
                    if (!txid.isEmpty()) compact_txs.append(txid);
                }
                QJsonObject compact_block = block;
                compact_block.insert(QStringLiteral("tx"), compact_txs);

                block_query.bindValue(0, height);
                block_query.bindValue(1, hash);
                block_query.bindValue(2, block.value(QStringLiteral("time")).toVariant().toLongLong());
                block_query.bindValue(3, static_cast<int>(compact_txs.size()));
                block_query.bindValue(4, QString::fromUtf8(QJsonDocument(compact_block).toJson(QJsonDocument::Compact)));
                block_query.bindValue(5, indexed_at);
                ok = block_query.exec();
                if (!ok) {
                    local_error = block_query.lastError().text();
                    break;
                }

                previous_output_count_query.bindValue(0, height);
                ok = previous_output_count_query.exec();
                if (!ok) {
                    local_error = previous_output_count_query.lastError().text();
                    break;
                }
                if (previous_output_count_query.next()) {
                    local_removed_output_rows += previous_output_count_query.value(0).toInt();
                }
                previous_output_count_query.finish();

                delete_tx_query.bindValue(0, height);
                ok = delete_tx_query.exec();
                if (!ok) {
                    local_error = delete_tx_query.lastError().text();
                    break;
                }
                delete_out_query.bindValue(0, height);
                ok = delete_out_query.exec();
                if (!ok) {
                    local_error = delete_out_query.lastError().text();
                    break;
                }
                delete_op_return_query.bindValue(0, height);
                ok = delete_op_return_query.exec();
                if (!ok) {
                    local_error = delete_op_return_query.lastError().text();
                    break;
                }
                delete_delta_query.bindValue(0, height);
                ok = delete_delta_query.exec();
                if (!ok) {
                    local_error = delete_delta_query.lastError().text();
                    break;
                }

                QHash<QString, qint64> block_deltas;
                const auto add_delta = [&block_deltas](const QString& address, qint64 delta) {
                    if (address.isEmpty() || delta == 0) return;
                    block_deltas.insert(address, block_deltas.value(address, 0) + delta);
                };

                for (int i = 0; i < txs.size(); ++i) {
                    QString txid = txs.at(i).toString();
                    if (txid.isEmpty()) txid = txs.at(i).toObject().value(QStringLiteral("txid")).toString();
                    if (txid.isEmpty()) continue;
                    tx_query.bindValue(0, height);
                    tx_query.bindValue(1, i);
                    tx_query.bindValue(2, txid);
                    ok = tx_query.exec();
                    if (!ok) {
                        local_error = tx_query.lastError().text();
                        break;
                    }
                }
                if (!ok) break;

                for (int tx_index = 0; tx_index < txs.size(); ++tx_index) {
                    const QJsonObject tx = txs.at(tx_index).toObject();
                    const QString txid = tx.value(QStringLiteral("txid")).toString();
                    if (txid.isEmpty()) continue;

                    const QJsonArray vout = tx.value(QStringLiteral("vout")).toArray();
                    for (const QJsonValue& out_value : vout) {
                        const QJsonObject out = out_value.toObject();
                        const int n = out.value(QStringLiteral("n")).toInt(-1);
                        if (n < 0) continue;
                        const qint64 value_sats = explorerAmountSats(out.value(QStringLiteral("value")));
                        const QString value_text = explorerAmountText(value_sats, false);
                        const QJsonObject script = out.value(QStringLiteral("scriptPubKey")).toObject();
                        const QString script_type = script.value(QStringLiteral("type")).toString();
                        const QString script_hex = script.value(QStringLiteral("hex")).toString();
                        if (script_type == QLatin1String("nulldata") || script_hex.startsWith(QStringLiteral("6a"), Qt::CaseInsensitive)) {
                            const QByteArray payload = explorerOpReturnPayloadBytes(script_hex);
                            op_return_query.bindValue(0, txid);
                            op_return_query.bindValue(1, n);
                            op_return_query.bindValue(2, height);
                            op_return_query.bindValue(3, value_sats);
                            op_return_query.bindValue(4, script_hex);
                            op_return_query.bindValue(5, QString::fromLatin1(payload.toHex()));
                            op_return_query.bindValue(6, explorerPrintablePayloadText(payload));
                            ok = op_return_query.exec();
                            if (!ok) {
                                local_error = op_return_query.lastError().text();
                                break;
                            }
                        }
                        const QStringList addresses = explorerOutputAddresses(script);
                        for (const QString& address : addresses) {
                            output_query.bindValue(0, txid);
                            output_query.bindValue(1, n);
                            output_query.bindValue(2, height);
                            output_query.bindValue(3, address);
                            output_query.bindValue(4, value_sats);
                            output_query.bindValue(5, value_text);
                            output_query.bindValue(6, script_type);
                            ok = output_query.exec();
                            if (!ok) {
                                local_error = output_query.lastError().text();
                                break;
                            }
                            add_delta(address, value_sats);
                            ++local_output_rows;
                        }
                        if (!ok) break;
                    }
                    if (!ok) break;

                    const QJsonArray vin = tx.value(QStringLiteral("vin")).toArray();
                    for (int vin_index = 0; vin_index < vin.size(); ++vin_index) {
                        const QJsonObject in = vin.at(vin_index).toObject();
                        const QString prev_txid = in.value(QStringLiteral("txid")).toString();
                        const int prev_vout = in.value(QStringLiteral("vout")).toInt(-1);
                        if (prev_txid.isEmpty() || prev_vout < 0) continue;
                        spend_lookup_query.bindValue(0, prev_txid);
                        spend_lookup_query.bindValue(1, prev_vout);
                        ok = spend_lookup_query.exec();
                        if (!ok) {
                            local_error = spend_lookup_query.lastError().text();
                            break;
                        }
                        while (spend_lookup_query.next()) {
                            add_delta(spend_lookup_query.value(0).toString(), -spend_lookup_query.value(1).toLongLong());
                        }
                        spend_lookup_query.finish();
                        spend_query.bindValue(0, txid);
                        spend_query.bindValue(1, height);
                        spend_query.bindValue(2, vin_index);
                        spend_query.bindValue(3, prev_txid);
                        spend_query.bindValue(4, prev_vout);
                        ok = spend_query.exec();
                        if (!ok) {
                            local_error = spend_query.lastError().text();
                            break;
                        }
                    }
                    if (!ok) break;
                }
                if (!ok) break;

                for (auto it = block_deltas.constBegin(); it != block_deltas.constEnd(); ++it) {
                    if (it.value() == 0) continue;
                    delta_query.bindValue(0, height);
                    delta_query.bindValue(1, it.key());
                    delta_query.bindValue(2, QVariant::fromValue<qlonglong>(it.value()));
                    ok = delta_query.exec();
                    if (!ok) {
                        local_error = delta_query.lastError().text();
                        break;
                    }
                }
                if (!ok) break;
            }

            if (ok && last_height >= 0) {
                meta_query.bindValue(0, QStringLiteral("last_indexed_height"));
                meta_query.bindValue(1, QString::number(last_height));
                ok = meta_query.exec();
                if (!ok) local_error = meta_query.lastError().text();
            }
            if (ok && last_height >= 0) {
                meta_query.bindValue(0, QStringLiteral("balance_deltas_height"));
                meta_query.bindValue(1, QString::number(last_height));
                ok = meta_query.exec();
                if (!ok) local_error = meta_query.lastError().text();
            }
            if (ok && last_height >= 0) {
                meta_query.bindValue(0, QStringLiteral("indexed_block_count"));
                meta_query.bindValue(1, QString::number(last_height + 1));
                ok = meta_query.exec();
                if (!ok) local_error = meta_query.lastError().text();
            }
            if (ok && last_height >= 0) {
                const qint64 indexed_output_count = std::max<qint64>(0, starting_output_count - local_removed_output_rows + local_output_rows);
                meta_query.bindValue(0, QStringLiteral("indexed_output_count"));
                meta_query.bindValue(1, QString::number(indexed_output_count));
                ok = meta_query.exec();
                if (!ok) local_error = meta_query.lastError().text();
            }
            if (ok) {
                ok = db.commit();
                if (!ok) local_error = db.lastError().text();
                else if (output_rows_written) *output_rows_written = local_output_rows;
            } else {
                db.rollback();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok && error) *error = local_error;
    return ok;
}

void NuRpcService::startExplorerIndexing()
{
    if (m_explorer_indexing) return;
    m_explorer_index_paused_by_user = false;
    if (!m_rpc_connected) {
        Q_EMIT userMessage(QStringLiteral("Explorer index not started"),
                           QStringLiteral("Connect to the local Defcoin backend before building the internal explorer index."));
        return;
    }
    QString error;
    if (!ensureExplorerDatabase(&error)) {
        Q_EMIT userMessage(QStringLiteral("Explorer index unavailable"), error);
        return;
    }
    if (!acquireExplorerWriterLock(&error)) {
        Q_EMIT userMessage(QStringLiteral("Explorer index already active"), error);
        return;
    }

    m_explorer_indexing = true;
    m_explorer_index_request_in_flight = false;
    m_explorer_indexed_block_count = explorerIndexedBlockCountFromDb();
    m_explorer_indexed_output_count = explorerIndexedOutputCountFromDb();
    m_explorer_index_started_ms = QDateTime::currentMSecsSinceEpoch();
    m_explorer_index_started_block_count = m_explorer_indexed_block_count;
    m_explorer_index_last_ui_update_ms = 0;
    m_explorer_index_status = QStringLiteral("Loading index 0%: reading current chain height...");
    if (m_explorer_top100_focused_indexing) {
        trySetProcessNiceForIndexing(true);
    }
    emitExplorerChangedThrottled(true);

    rpcCall(QStringLiteral("getblockcount"), {}, false, [this](const QJsonValue& result, const QString& error) {
        if (!m_explorer_indexing) return;
        if (!error.isEmpty()) {
            m_explorer_indexing = false;
            releaseExplorerWriterLock();
            m_explorer_index_status = QStringLiteral("Index stopped: %1").arg(error);
            Q_EMIT explorerChanged();
            return;
        }
        m_explorer_index_tip = result.toInt();
        const int highest = explorerHighestIndexedBlock();
        if (highest < 0) {
            m_explorer_index_height = 0;
            scheduleExplorerIndexStep(0);
            return;
        }
        rpcCall(QStringLiteral("getblockhash"), {highest}, false, [this, highest](const QJsonValue& hash_result, const QString& hash_error) {
            if (!m_explorer_indexing) return;
            const QString cached_hash = explorerBlockHashAtHeight(highest);
            if (!hash_error.isEmpty() || cached_hash.isEmpty() || hash_result.toString() != cached_hash) {
                QString prune_error;
                if (!explorerPruneFromHeight(highest, &prune_error)) {
                    m_explorer_indexing = false;
                    releaseExplorerWriterLock();
                    m_explorer_index_status = QStringLiteral("Index repair failed at block %1: %2")
                        .arg(QString::number(highest), prune_error);
                    Q_EMIT explorerChanged();
                    return;
                }
                m_explorer_index_height = highest;
                m_explorer_indexed_block_count = explorerIndexedBlockCountFromDb();
                m_explorer_indexed_output_count = explorerIndexedOutputCountFromDb();
                const double repair_pct = m_explorer_index_tip > 0
                    ? std::clamp(100.0 * static_cast<double>(std::max(0, highest - 1)) / static_cast<double>(m_explorer_index_tip), 0.0, 100.0)
                    : 0.0;
                m_explorer_index_status = QStringLiteral("Loading index %1%: detected stale indexed tip, pruned back to block %2, and resumed.")
                    .arg(QString::number(repair_pct, 'f', 2),
                         QString::number(std::max(0, highest - 1)));
                emitExplorerChangedThrottled(true);
                scheduleExplorerIndexStep(0);
                return;
            }
            m_explorer_index_height = highest + 1;
            if (m_explorer_index_height > m_explorer_index_tip) {
                m_explorer_indexing = false;
                releaseExplorerWriterLock();
                m_explorer_index_status = QStringLiteral("Index is current at block %1.").arg(QString::number(m_explorer_index_tip));
                Q_EMIT explorerChanged();
                return;
            }
            scheduleExplorerIndexStep(0);
        });
    });
}

void NuRpcService::stopExplorerIndexing()
{
    if (!m_explorer_indexing) return;
    m_explorer_index_paused_by_user = true;
    m_explorer_indexing = false;
    m_explorer_index_request_in_flight = false;
    m_explorer_index_status = QStringLiteral("Index paused at block %1 with %2 blocks cached.")
        .arg(QString::number(std::max(0, m_explorer_index_height - 1)),
             QString::number(m_explorer_indexed_block_count));
    if (!m_explorer_top100_scanning) releaseExplorerWriterLock();
    if (!m_explorer_top100_scanning) trySetProcessNiceForIndexing(false);
    Q_EMIT explorerChanged();
}

void NuRpcService::resetExplorerIndex()
{
    stopExplorerIndexing();
    stopExplorerTop100Timeline();
    QString error;
    if (!ensureExplorerDatabase(&error)) {
        Q_EMIT userMessage(QStringLiteral("Explorer index unavailable"), error);
        return;
    }
    if (!acquireExplorerWriterLock(&error)) {
        Q_EMIT userMessage(QStringLiteral("Explorer index reset blocked"), error);
        return;
    }
    const QString connection_name = QStringLiteral("nu_explorer_reset_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        ok = db.open();
        if (ok) {
            QSqlQuery query(db);
            ok = query.exec(QStringLiteral("DELETE FROM explorer_tx_outputs"));
            if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_block_transactions"));
            if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_blocks"));
            if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_balance_deltas"));
            if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_top100_events"));
            if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_top100_ranges"));
            if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_meta WHERE key IN ('last_indexed_height', 'tip_height', 'balance_deltas_height', 'indexed_block_count', 'indexed_output_count')"));
            if (ok) ok = query.exec(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('indexed_block_count', '0')"));
            if (ok) ok = query.exec(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('indexed_output_count', '0')"));
            if (!ok) local_error = query.lastError().text();
        } else {
            local_error = db.lastError().text();
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    releaseExplorerWriterLock();
    if (!ok) {
        Q_EMIT userMessage(QStringLiteral("Explorer index reset failed"), local_error);
        return;
    }
    m_explorer_index_height = 0;
    m_explorer_index_tip = 0;
    m_explorer_indexed_block_count = 0;
    m_explorer_indexed_output_count = 0;
    m_explorer_rich_list.clear();
    m_explorer_movements.clear();
    refreshExplorerTop100TimelineStats();
    m_explorer_analytics_status = QStringLiteral("Explorer analytics cleared with the local block index.");
    m_explorer_index_status = QStringLiteral("Index reset. Cached lookups were kept; block index tables were cleared.");
    Q_EMIT explorerChanged();
}

void NuRpcService::emitExplorerChangedThrottled(bool force)
{
    const qint64 now_ms = QDateTime::currentMSecsSinceEpoch();
    if (!force && m_explorer_index_last_ui_update_ms > 0 && now_ms - m_explorer_index_last_ui_update_ms < 2000) {
        return;
    }
    m_explorer_index_last_ui_update_ms = now_ms;
    Q_EMIT explorerChanged();
}

void NuRpcService::scheduleExplorerIndexStep(int delay_ms)
{
    if (!m_explorer_indexing || m_explorer_index_request_in_flight) return;
    QTimer::singleShot(std::max(0, delay_ms), this, [this] {
        explorerIndexStep();
    });
}

void NuRpcService::explorerIndexStep()
{
    if (!m_explorer_indexing || m_explorer_index_request_in_flight) return;
    if (m_explorer_index_height > m_explorer_index_tip) {
        m_explorer_indexing = false;
        releaseExplorerWriterLock();
        m_explorer_index_status = QStringLiteral("Index is current at block %1 with %2 blocks cached.")
            .arg(QString::number(m_explorer_index_tip), QString::number(m_explorer_indexed_block_count));
        Q_EMIT explorerChanged();
        return;
    }

    const int start_height = m_explorer_index_height;
    const int index_batch_blocks = m_explorer_top100_focused_indexing ? EXPLORER_INDEX_FOCUSED_BATCH_BLOCKS : EXPLORER_INDEX_BATCH_BLOCKS;
    const int end_height = std::min(m_explorer_index_tip, start_height + index_batch_blocks - 1);
    const int batch_count = end_height - start_height + 1;
    m_explorer_index_request_in_flight = true;
    const double pct = m_explorer_index_tip > 0 ? (100.0 * static_cast<double>(start_height) / static_cast<double>(m_explorer_index_tip)) : 0.0;
    m_explorer_index_status = QStringLiteral("Indexing blocks %1-%2 of %3 (%4%).")
        .arg(QString::number(start_height),
             QString::number(end_height),
             QString::number(m_explorer_index_tip),
             QString::number(pct, 'f', 2));
    emitExplorerChangedThrottled(false);

    QVector<QPair<QString, QJsonArray>> hash_calls;
    hash_calls.reserve(batch_count);
    for (int height = start_height; height <= end_height; ++height) {
        hash_calls.push_back({QStringLiteral("getblockhash"), QJsonArray{height}});
    }

    rpcBatchCall(hash_calls, false, [this, start_height, end_height](const QVector<QJsonValue>& hash_results,
                                                                     const QStringList& hash_errors,
                                                                     const QString& batch_error) {
        if (!m_explorer_indexing) {
            m_explorer_index_request_in_flight = false;
            return;
        }
        if (!batch_error.isEmpty()) {
            m_explorer_indexing = false;
            m_explorer_index_request_in_flight = false;
            releaseExplorerWriterLock();
            m_explorer_index_status = QStringLiteral("Index stopped near block %1: %2")
                .arg(QString::number(start_height), batch_error);
            Q_EMIT explorerChanged();
            return;
        }

        QVector<QPair<QString, QJsonArray>> block_calls;
        block_calls.reserve(hash_results.size());
        for (int i = 0; i < hash_results.size(); ++i) {
            const int height = start_height + i;
            if (i < hash_errors.size() && !hash_errors.at(i).isEmpty()) {
                m_explorer_indexing = false;
                m_explorer_index_request_in_flight = false;
                releaseExplorerWriterLock();
                m_explorer_index_status = QStringLiteral("Index stopped at block %1: %2")
                    .arg(QString::number(height), hash_errors.at(i));
                Q_EMIT explorerChanged();
                return;
            }
            const QString hash = hash_results.at(i).toString();
            if (hash.isEmpty()) {
                m_explorer_indexing = false;
                m_explorer_index_request_in_flight = false;
                releaseExplorerWriterLock();
                m_explorer_index_status = QStringLiteral("Index stopped at block %1: empty block hash response.")
                    .arg(QString::number(height));
                Q_EMIT explorerChanged();
                return;
            }
            block_calls.push_back({QStringLiteral("getblock"), QJsonArray{hash, 2}});
        }

        rpcBatchCall(block_calls, false, [this, start_height, end_height](const QVector<QJsonValue>& block_results,
                                                                          const QStringList& block_errors,
                                                                          const QString& block_batch_error) {
            m_explorer_index_request_in_flight = false;
            if (!m_explorer_indexing) return;
            if (!block_batch_error.isEmpty()) {
                m_explorer_indexing = false;
                releaseExplorerWriterLock();
                m_explorer_index_status = QStringLiteral("Index stopped near block %1: %2")
                    .arg(QString::number(start_height), block_batch_error);
                Q_EMIT explorerChanged();
                return;
            }

            QVector<QJsonObject> blocks;
            blocks.reserve(block_results.size());
            QString expected_previous_hash = start_height > 0 ? explorerBlockHashAtHeight(start_height - 1) : QString();
            for (int i = 0; i < block_results.size(); ++i) {
                const int height = start_height + i;
                if (i < block_errors.size() && !block_errors.at(i).isEmpty()) {
                    m_explorer_indexing = false;
                    releaseExplorerWriterLock();
                    m_explorer_index_status = QStringLiteral("Index stopped at block %1: %2")
                        .arg(QString::number(height), block_errors.at(i));
                    Q_EMIT explorerChanged();
                    return;
                }
                const QJsonObject block = block_results.at(i).toObject();
                const QString hash = block.value(QStringLiteral("hash")).toString();
                const int block_height = block.value(QStringLiteral("height")).toInt(-1);
                if (hash.isEmpty() || block_height != height) {
                    m_explorer_indexing = false;
                    releaseExplorerWriterLock();
                    m_explorer_index_status = QStringLiteral("Index stopped at block %1: malformed block response.")
                        .arg(QString::number(height));
                    Q_EMIT explorerChanged();
                    return;
                }
                if (height > 0 && block.value(QStringLiteral("previousblockhash")).toString() != expected_previous_hash) {
                    QString prune_error;
                    if (!explorerPruneFromHeight(height - 1, &prune_error)) {
                        m_explorer_indexing = false;
                        releaseExplorerWriterLock();
                        m_explorer_index_status = QStringLiteral("Index repair failed near block %1: %2")
                            .arg(QString::number(height), prune_error);
                        Q_EMIT explorerChanged();
                        return;
                    }
                    m_explorer_index_height = height - 1;
                    m_explorer_indexed_block_count = explorerIndexedBlockCountFromDb();
                    m_explorer_indexed_output_count = explorerIndexedOutputCountFromDb();
                    m_explorer_index_status = QStringLiteral("Detected a chain reorg near block %1. Pruned one block and will retry.")
                        .arg(QString::number(height));
                    Q_EMIT explorerChanged();
                    scheduleExplorerIndexStep(0);
                    return;
                }
                expected_previous_hash = hash;
                blocks.push_back(block);
            }

            int output_rows_written = 0;
            QString store_error;
            if (!storeExplorerBlocks(blocks, &output_rows_written, &store_error)) {
                m_explorer_indexing = false;
                releaseExplorerWriterLock();
                m_explorer_index_status = QStringLiteral("Index storage failed at blocks %1-%2: %3")
                    .arg(QString::number(start_height), QString::number(end_height), store_error);
                Q_EMIT explorerChanged();
                return;
            }

            m_explorer_index_height = end_height + 1;
            m_explorer_indexed_block_count += blocks.size();
            m_explorer_indexed_output_count += output_rows_written;
            if (end_height % 960 == 0 || m_explorer_index_height > m_explorer_index_tip) {
                m_explorer_indexed_block_count = explorerIndexedBlockCountFromDb();
                m_explorer_indexed_output_count = explorerIndexedOutputCountFromDb();
            }
            const double done_pct = m_explorer_index_tip > 0 ? (100.0 * static_cast<double>(m_explorer_index_height) / static_cast<double>(m_explorer_index_tip)) : 0.0;
            QString rate_text;
            const qint64 elapsed_ms = m_explorer_index_started_ms > 0 ? QDateTime::currentMSecsSinceEpoch() - m_explorer_index_started_ms : 0;
            if (elapsed_ms > 0) {
                const int run_blocks = std::max(1, m_explorer_indexed_block_count - m_explorer_index_started_block_count);
                const double blocks_per_second = 1000.0 * static_cast<double>(run_blocks) / static_cast<double>(elapsed_ms);
                rate_text = QStringLiteral(" %1 blocks/s.")
                    .arg(QString::number(blocks_per_second, 'f', blocks_per_second >= 100.0 ? 0 : 1));
            }
            m_explorer_index_status = QStringLiteral("Indexed through block %1 of %2 (%3%). %4 blocks and %5 standard outputs cached.%6")
                .arg(QString::number(end_height),
                     QString::number(m_explorer_index_tip),
                     QString::number(std::min(100.0, done_pct), 'f', 2),
                     QString::number(m_explorer_indexed_block_count),
                     QString::number(m_explorer_indexed_output_count),
                     rate_text);
            emitExplorerChangedThrottled(false);
            scheduleExplorerIndexStep(explorerIndexNextDelayMs(m_explorer_top100_focused_indexing));
        });
    });
}

void NuRpcService::refreshExplorerTop100TimelineStats()
{
    m_explorer_top100_timeline_start_height = -1;
    m_explorer_top100_timeline_end_height = -1;
    m_explorer_top100_timeline_event_count = 0;

    QString error;
    if (!ensureExplorerDatabase(&error)) return;
    const QString connection_name = QStringLiteral("nu_explorer_top100_stats_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            if (query.exec(QStringLiteral("SELECT MIN(height), MAX(height), COUNT(*) FROM explorer_top100_events")) && query.next()) {
                if (!query.value(0).isNull()) m_explorer_top100_timeline_start_height = query.value(0).toInt();
                if (!query.value(1).isNull()) m_explorer_top100_timeline_end_height = query.value(1).toInt();
                m_explorer_top100_timeline_event_count = query.value(2).toInt();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
}

bool NuRpcService::initializeExplorerTop100Scan(int start_height, int end_height, QString* error)
{
    const int highest = explorerHighestIndexedBlock();
    if (highest < 0) {
        if (error) *error = QStringLiteral("Build the Explorer block index before building the Holder timeline.");
        return false;
    }
    const int start = std::max(0, std::min(start_height, highest));
    const int end = std::max(start, std::min(end_height < 0 ? highest : end_height, highest));

    if (!ensureExplorerBalanceDeltas(error)) return false;

    m_explorer_top100_balances.clear();
    m_explorer_top100_order.clear();
    m_explorer_top100_previous_rows.clear();
    m_explorer_top100_total_sats = 0;
    m_explorer_top100_events_written = 0;
    const int scan_blocks = std::max(1, end - start + 1);
    const int target_checkpoints = scan_blocks >= 500000
        ? EXPLORER_TOP100_LARGE_PLAYBACK_CHECKPOINTS
        : EXPLORER_TOP100_MIN_PLAYBACK_CHECKPOINTS;
    m_explorer_top100_checkpoint_interval_blocks = std::max(1, std::min(EXPLORER_TOP100_MAX_ANCHOR_BLOCKS,
        scan_blocks / std::max(1, target_checkpoints)));
    m_explorer_top100_next_checkpoint_height = start;
    m_explorer_top100_last_rank_count = 0;
    m_explorer_top100_last_ui_update_ms = 0;

    const QString connection_name = QStringLiteral("nu_explorer_top100_init_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery pragma(db);
            pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
            pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
            pragma.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));
            if (m_explorer_top100_focused_indexing) {
                pragma.exec(QStringLiteral("PRAGMA cache_size=-262144"));
                pragma.exec(QStringLiteral("PRAGMA mmap_size=268435456"));
            }
            ok = db.transaction();
            if (!ok) local_error = db.lastError().text();
            if (ok) {
                QSqlQuery query(db);
                QString scale = QString();
                if (query.exec(QStringLiteral("SELECT value FROM explorer_meta WHERE key = 'top100_percent_scale'")) && query.next()) {
                    scale = query.value(0).toString();
                }
                if (scale != QLatin1String("basis_points")) {
                    ok = query.exec(QStringLiteral("DELETE FROM explorer_top100_events"));
                    if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_top100_ranges"));
                    if (ok) ok = query.exec(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('top100_percent_scale', 'basis_points')"));
                    if (!ok) local_error = query.lastError().text();
                }
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_top100_events WHERE height BETWEEN ? AND ?"));
                query.addBindValue(start);
                query.addBindValue(end);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral("DELETE FROM explorer_top100_ranges WHERE NOT(end_height < ? OR start_height > ?)"));
                query.addBindValue(start);
                query.addBindValue(end);
                ok = query.exec();
                if (!ok) local_error = query.lastError().text();
            }
            if (ok) {
                QSqlQuery range_query(db);
                range_query.prepare(QStringLiteral(
                    "INSERT OR REPLACE INTO explorer_top100_ranges(start_height, end_height, status, started_at, completed_at) "
                    "VALUES(?, ?, 'running', ?, NULL)"));
                range_query.addBindValue(start);
                range_query.addBindValue(end);
                range_query.addBindValue(QDateTime::currentSecsSinceEpoch());
                ok = range_query.exec();
                if (!ok) local_error = range_query.lastError().text();
            }
            if (ok && start > 0) {
                QSqlQuery balance_query(db);
                balance_query.prepare(QStringLiteral(
                    "SELECT address, SUM(delta_sats) AS balance_sats "
                    "FROM explorer_balance_deltas "
                    "WHERE height < ? "
                    "GROUP BY address "
                    "HAVING balance_sats > 0"));
                balance_query.addBindValue(start);
                ok = balance_query.exec();
                if (!ok) {
                    local_error = balance_query.lastError().text();
                } else {
                    while (balance_query.next()) {
                        const QString address = balance_query.value(0).toString();
                        const qint64 balance = balance_query.value(1).toLongLong();
                        if (address.isEmpty() || balance <= 0) continue;
                        m_explorer_top100_balances.insert(address, balance);
                        m_explorer_top100_order.insert(ExplorerTop100Entry{balance, address});
                        m_explorer_top100_total_sats += balance;
                    }
                }
            }
            if (ok) {
                ok = db.commit();
                if (!ok) local_error = db.lastError().text();
            } else {
                db.rollback();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok) {
        if (error) *error = local_error;
        return false;
    }

    m_explorer_top100_scan_start_height = start;
    m_explorer_top100_scan_height = start;
    m_explorer_top100_scan_end_height = end;
    m_explorer_top100_started_ms = QDateTime::currentMSecsSinceEpoch();
    m_explorer_top100_status = QStringLiteral("Holder timeline checkpoints scanning blocks %1-%2 from the Explorer index. Playback anchors every ~%3 block%4%5.")
        .arg(QString::number(start),
             QString::number(end),
             QString::number(m_explorer_top100_checkpoint_interval_blocks),
             m_explorer_top100_checkpoint_interval_blocks == 1 ? QString() : QStringLiteral("s"),
             m_explorer_top100_focused_indexing ? QStringLiteral(" High intensity indexing is on.") : QString());
    return true;
}

bool NuRpcService::prepareExplorerTop100EventWrite(int height,
                                                   qint64 block_time,
                                                   bool force_anchor,
                                                   ExplorerTop100EventWrite* event,
                                                   QString* error)
{
    if (!event) {
        if (error) *error = QStringLiteral("Internal Holder timeline event target was not available.");
        return false;
    }

    event->height = height;
    event->time = block_time;
    event->is_anchor = false;
    event->rows.clear();

    QVector<QPair<QString, int>> current_rows;
    current_rows.reserve(100);
    int rank = 1;
    for (auto it = m_explorer_top100_order.crbegin(); it != m_explorer_top100_order.crend() && rank <= 100; ++it, ++rank) {
        const int pct = m_explorer_top100_total_sats > 0
            ? static_cast<int>(std::llround(10000.0 * static_cast<double>(it->balance) / static_cast<double>(m_explorer_top100_total_sats)))
            : 0;
        current_rows.push_back(qMakePair(it->address, pct));
    }

    const int rank_count = current_rows.size();
    bool milestone_anchor = false;
    const int milestones[] = {10, 25, 50, 75, 100};
    for (int threshold : milestones) {
        if (m_explorer_top100_last_rank_count < threshold && rank_count >= threshold) {
            milestone_anchor = true;
            break;
        }
    }
    const bool scheduled_anchor = height >= m_explorer_top100_next_checkpoint_height;
    const bool effective_force_anchor = force_anchor || milestone_anchor || scheduled_anchor;

    if (!effective_force_anchor && current_rows == m_explorer_top100_previous_rows) return true;

    event->is_anchor = effective_force_anchor;
    const int max_rows = std::max(current_rows.size(), m_explorer_top100_previous_rows.size());
    event->rows.reserve(std::min(max_rows, 100));
    for (int i = 0; i < max_rows && i < 100; ++i) {
        const QPair<QString, int> current = i < current_rows.size() ? current_rows.at(i) : qMakePair(QStringLiteral(""), 0);
        const QPair<QString, int> previous = i < m_explorer_top100_previous_rows.size() ? m_explorer_top100_previous_rows.at(i) : qMakePair(QString(), -1);
        if (!effective_force_anchor && current == previous) continue;
        ExplorerTop100EventRow row;
        row.rank = i + 1;
        row.address = current.first.isNull() ? QStringLiteral("") : current.first;
        row.percent = current.second;
        row.color_index = i % EXPLORER_TOP100_COLORS.size();
        event->rows.push_back(row);
    }

    m_explorer_top100_previous_rows = current_rows;
    m_explorer_top100_last_rank_count = std::max(m_explorer_top100_last_rank_count, rank_count);
    if (effective_force_anchor) {
        while (m_explorer_top100_next_checkpoint_height <= height) {
            m_explorer_top100_next_checkpoint_height += std::max(1, m_explorer_top100_checkpoint_interval_blocks);
        }
    }
    return true;
}

bool NuRpcService::writeExplorerTop100EventBatch(const QVector<ExplorerTop100EventWrite>& events, QString* error)
{
    bool has_rows = false;
    for (const ExplorerTop100EventWrite& event : events) {
        if (!event.rows.isEmpty()) {
            has_rows = true;
            break;
        }
    }
    if (!has_rows) return true;

    const QString connection_name = QStringLiteral("nu_explorer_top100_events_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    int rows_written = 0;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery pragma(db);
            pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
            pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
            pragma.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));
            if (m_explorer_top100_focused_indexing) {
                pragma.exec(QStringLiteral("PRAGMA cache_size=-262144"));
                pragma.exec(QStringLiteral("PRAGMA mmap_size=268435456"));
            }
            ok = db.transaction();
            if (!ok) local_error = db.lastError().text();
            QSqlQuery query(db);
            if (ok) {
                ok = query.prepare(QStringLiteral(
                    "INSERT OR REPLACE INTO explorer_top100_events(height, time, rank, address, percent_whole, color_index, is_anchor) "
                    "VALUES(?, ?, ?, ?, ?, ?, ?)"));
                if (!ok) local_error = query.lastError().text();
            }
            for (const ExplorerTop100EventWrite& event : events) {
                for (const ExplorerTop100EventRow& row : event.rows) {
                    if (!ok) break;
                    query.bindValue(0, event.height);
                    query.bindValue(1, QVariant::fromValue<qlonglong>(event.time));
                    query.bindValue(2, row.rank);
                    query.bindValue(3, row.address);
                    query.bindValue(4, row.percent);
                    query.bindValue(5, row.color_index);
                    query.bindValue(6, event.is_anchor ? 1 : 0);
                    ok = query.exec();
                    if (!ok) local_error = query.lastError().text();
                    else ++rows_written;
                }
                if (!ok) break;
            }
            if (ok) {
                QSqlQuery meta_query(db);
                ok = meta_query.exec(QStringLiteral("INSERT OR REPLACE INTO explorer_meta(key, value) VALUES('top100_percent_scale', 'basis_points')"));
                if (!ok) local_error = meta_query.lastError().text();
            }
            if (ok) {
                ok = db.commit();
                if (!ok) local_error = db.lastError().text();
            } else {
                db.rollback();
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    if (!ok) {
        if (error) *error = local_error;
        return false;
    }
    m_explorer_top100_events_written += rows_written;
    return true;
}

bool NuRpcService::writeExplorerTop100Events(int height, qint64 block_time, bool force_anchor, QString* error)
{
    ExplorerTop100EventWrite event;
    if (!prepareExplorerTop100EventWrite(height, block_time, force_anchor, &event, error)) return false;
    if (event.rows.isEmpty()) return true;
    QVector<ExplorerTop100EventWrite> events;
    events.reserve(1);
    events.push_back(event);
    return writeExplorerTop100EventBatch(events, error);
}

bool NuRpcService::finishExplorerTop100Scan(bool completed, QString* error)
{
    const QString connection_name = QStringLiteral("nu_explorer_top100_finish_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "UPDATE explorer_top100_ranges SET status = ?, completed_at = ? "
                "WHERE start_height = ? AND end_height = ?"));
            query.addBindValue(completed ? QStringLiteral("complete") : QStringLiteral("paused"));
            query.addBindValue(completed ? QVariant(QDateTime::currentSecsSinceEpoch()) : QVariant());
            query.addBindValue(m_explorer_top100_scan_start_height);
            query.addBindValue(m_explorer_top100_scan_end_height);
            ok = query.exec();
            if (!ok) local_error = query.lastError().text();
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    refreshExplorerTop100TimelineStats();
    if (!ok && error) *error = local_error;
    return ok;
}

void NuRpcService::scheduleExplorerTop100Step(int delay_ms)
{
    if (!m_explorer_top100_scanning) return;
    QTimer::singleShot(std::max(0, delay_ms), this, [this] {
        explorerTop100Step();
    });
}

void NuRpcService::explorerTop100Step()
{
    if (!m_explorer_top100_scanning) return;
    if (m_explorer_top100_scan_height > m_explorer_top100_scan_end_height) {
        QString finish_error;
        finishExplorerTop100Scan(true, &finish_error);
        m_explorer_top100_scanning = false;
        releaseExplorerWriterLock();
        m_explorer_top100_status = finish_error.isEmpty()
            ? QStringLiteral("Holder timeline complete through block %1 with %2 checkpoint rows.")
                  .arg(QString::number(m_explorer_top100_scan_end_height), QString::number(m_explorer_top100_events_written))
            : QStringLiteral("Holder timeline finished, but range status could not be saved: %1").arg(finish_error);
        refreshExplorerAnalytics(5000, QStringLiteral("rich"));
        Q_EMIT explorerChanged();
        return;
    }

    const int chunk_start = m_explorer_top100_scan_height;
    const int chunk_size = m_explorer_top100_focused_indexing ? EXPLORER_TOP100_FOCUSED_CHUNK_BLOCKS : EXPLORER_TOP100_CHUNK_BLOCKS;
    const int chunk_end = std::min(m_explorer_top100_scan_end_height, chunk_start + chunk_size - 1);
    const QString connection_name = QStringLiteral("nu_explorer_top100_scan_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    int last_height = -1;
    qint64 last_time = 0;
    int rows_read = 0;
    QVector<ExplorerTop100EventWrite> event_writes;
    int event_rows_pending = 0;
    auto append_event_write = [&](const ExplorerTop100EventWrite& event) {
        if (event.rows.isEmpty()) return true;
        event_writes.push_back(event);
        event_rows_pending += event.rows.size();
        if (event_rows_pending < EXPLORER_TOP100_EVENT_WRITE_BATCH_ROWS) return true;
        if (!writeExplorerTop100EventBatch(event_writes, &local_error)) return false;
        event_writes.clear();
        event_rows_pending = 0;
        return true;
    };
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (!db.open()) {
            local_error = db.lastError().text();
        } else {
            QSqlQuery pragma(db);
            pragma.exec(QStringLiteral("PRAGMA temp_store=MEMORY"));
            if (m_explorer_top100_focused_indexing) {
                pragma.exec(QStringLiteral("PRAGMA cache_size=-262144"));
                pragma.exec(QStringLiteral("PRAGMA mmap_size=268435456"));
            }
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "SELECT d.height, COALESCE(b.time, 0), d.address, d.delta_sats "
                "FROM explorer_balance_deltas d LEFT JOIN explorer_blocks b ON b.height = d.height "
                "WHERE d.height BETWEEN ? AND ? "
                "ORDER BY d.height ASC"));
            query.addBindValue(chunk_start);
            query.addBindValue(chunk_end);
            ok = query.exec();
            if (!ok) {
                local_error = query.lastError().text();
            } else {
                while (query.next()) {
                    const int height = query.value(0).toInt();
                    const qint64 block_time = query.value(1).toLongLong();
                    if (last_height >= 0 && height != last_height) {
                        const bool force_anchor = m_explorer_top100_previous_rows.isEmpty()
                            || last_height == m_explorer_top100_scan_start_height
                            || last_height >= m_explorer_top100_scan_end_height;
                        ExplorerTop100EventWrite event;
                        if (!prepareExplorerTop100EventWrite(last_height, last_time, force_anchor, &event, &local_error)) {
                            ok = false;
                            break;
                        }
                        if (!append_event_write(event)) {
                            ok = false;
                            break;
                        }
                    }

                    const QString address = query.value(2).toString();
                    const qint64 delta = query.value(3).toLongLong();
                    const qint64 old_balance = m_explorer_top100_balances.value(address, 0);
                    if (old_balance > 0) m_explorer_top100_order.erase(ExplorerTop100Entry{old_balance, address});
                    const qint64 new_balance = old_balance + delta;
                    m_explorer_top100_total_sats += std::max<qint64>(0, new_balance) - std::max<qint64>(0, old_balance);
                    if (new_balance > 0) {
                        m_explorer_top100_balances.insert(address, new_balance);
                        m_explorer_top100_order.insert(ExplorerTop100Entry{new_balance, address});
                    } else {
                        m_explorer_top100_balances.remove(address);
                    }
                    last_height = height;
                    last_time = block_time;
                    ++rows_read;
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);

    if (ok && last_height >= 0) {
        const bool force_anchor = m_explorer_top100_previous_rows.isEmpty()
            || last_height == m_explorer_top100_scan_start_height
            || chunk_end >= m_explorer_top100_scan_end_height;
        ExplorerTop100EventWrite event;
        ok = prepareExplorerTop100EventWrite(last_height, last_time, force_anchor, &event, &local_error);
        if (ok && !append_event_write(event)) ok = false;
    }

    if (ok && !event_writes.isEmpty()) {
        ok = writeExplorerTop100EventBatch(event_writes, &local_error);
    }

    if (!ok) {
        m_explorer_top100_scanning = false;
        finishExplorerTop100Scan(false, nullptr);
        releaseExplorerWriterLock();
        m_explorer_top100_status = QStringLiteral("Holder timeline stopped near block %1: %2")
            .arg(QString::number(chunk_start), local_error);
        Q_EMIT explorerChanged();
        return;
    }

    m_explorer_top100_scan_height = chunk_end + 1;
    const qint64 elapsed_ms = std::max<qint64>(1, QDateTime::currentMSecsSinceEpoch() - m_explorer_top100_started_ms);
    const int scanned_blocks = std::max(1, m_explorer_top100_scan_height - m_explorer_top100_scan_start_height);
    const double blocks_per_second = 1000.0 * static_cast<double>(scanned_blocks) / static_cast<double>(elapsed_ms);
    const double pct = 100.0 * static_cast<double>(m_explorer_top100_scan_height - m_explorer_top100_scan_start_height)
        / static_cast<double>(std::max(1, m_explorer_top100_scan_end_height - m_explorer_top100_scan_start_height + 1));
    m_explorer_top100_status = QStringLiteral("Holder timeline checkpoints indexed through block %1 of %2 (%3%). %4 checkpoint rows, %5 delta rows in last batch, %6 blocks/s.%7")
        .arg(QString::number(chunk_end),
             QString::number(m_explorer_top100_scan_end_height),
             QString::number(std::min(100.0, pct), 'f', 2),
             QString::number(m_explorer_top100_events_written),
             QString::number(rows_read),
             QString::number(blocks_per_second, 'f', blocks_per_second >= 100.0 ? 0 : 1),
             m_explorer_top100_focused_indexing ? QStringLiteral(" High intensity mode.") : QString());
    const qint64 now_ms = QDateTime::currentMSecsSinceEpoch();
    if (m_explorer_top100_last_ui_update_ms <= 0 || now_ms - m_explorer_top100_last_ui_update_ms >= EXPLORER_TOP100_UI_REFRESH_MS) {
        m_explorer_top100_last_ui_update_ms = now_ms;
        refreshExplorerTop100TimelineStats();
        Q_EMIT explorerChanged();
    }
    scheduleExplorerTop100Step(0);
}

void NuRpcService::startExplorerTop100Timeline(int start_height, int end_height)
{
    if (m_explorer_top100_scanning) return;
    if (m_explorer_indexing) {
        Q_EMIT userMessage(QStringLiteral("Holder timeline not started"),
                           QStringLiteral("Pause the main Explorer index before rebuilding the Holder timeline."));
        return;
    }
    QString error;
    if (!acquireExplorerWriterLock(&error)) {
        Q_EMIT userMessage(QStringLiteral("Holder timeline blocked"), error);
        return;
    }
    if (!initializeExplorerTop100Scan(start_height, end_height, &error)) {
        releaseExplorerWriterLock();
        Q_EMIT userMessage(QStringLiteral("Holder timeline not started"), error);
        return;
    }
    m_explorer_top100_scanning = true;
    m_explorer_top100_paused_by_user = false;
    Q_EMIT explorerChanged();
    scheduleExplorerTop100Step(0);
}

void NuRpcService::stopExplorerTop100Timeline()
{
    if (!m_explorer_top100_scanning) return;
    m_explorer_top100_scanning = false;
    m_explorer_top100_paused_by_user = true;
    finishExplorerTop100Scan(false, nullptr);
    releaseExplorerWriterLock();
    m_explorer_top100_status = QStringLiteral("Holder timeline paused at block %1.")
        .arg(QString::number(m_explorer_top100_scan_height));
    Q_EMIT explorerChanged();
}

void NuRpcService::resetExplorerTop100Timeline()
{
    stopExplorerTop100Timeline();
    QString error;
    if (!ensureExplorerDatabase(&error)) {
        Q_EMIT userMessage(QStringLiteral("Holder timeline unavailable"), error);
        return;
    }
    if (!acquireExplorerWriterLock(&error)) {
        Q_EMIT userMessage(QStringLiteral("Holder timeline reset blocked"), error);
        return;
    }
    const QString connection_name = QStringLiteral("nu_explorer_top100_reset_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    bool ok = false;
    QString local_error;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            ok = query.exec(QStringLiteral("DELETE FROM explorer_top100_events"));
            if (ok) ok = query.exec(QStringLiteral("DELETE FROM explorer_top100_ranges"));
            if (!ok) local_error = query.lastError().text();
        } else {
            local_error = db.lastError().text();
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    releaseExplorerWriterLock();
    if (!ok) {
        Q_EMIT userMessage(QStringLiteral("Holder timeline reset failed"), local_error);
        return;
    }
    refreshExplorerTop100TimelineStats();
    m_explorer_top100_status = QStringLiteral("Holder timeline cleared.");
    Q_EMIT explorerChanged();
}

void NuRpcService::scanRemainingExplorerTop100Timeline()
{
    const int highest = explorerHighestIndexedBlock();
    if (highest < 0) {
        Q_EMIT userMessage(QStringLiteral("Holder timeline not started"),
                           QStringLiteral("Build the Explorer block index before scanning remaining Holder timeline ranges."));
        return;
    }

    int gap_start = 0;
    int gap_end = highest;
    bool found_gap = false;
    QString error;
    if (!ensureExplorerDatabase(&error)) {
        Q_EMIT userMessage(QStringLiteral("Holder timeline unavailable"), error);
        return;
    }
    const QString connection_name = QStringLiteral("nu_explorer_top100_gap_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery query(db);
            if (query.exec(QStringLiteral(
                    "SELECT start_height, end_height FROM explorer_top100_ranges "
                    "WHERE status = 'complete' ORDER BY start_height ASC"))) {
                int cursor = 0;
                while (query.next()) {
                    const int start = query.value(0).toInt();
                    const int end = query.value(1).toInt();
                    if (start > cursor) {
                        gap_start = cursor;
                        gap_end = std::min(highest, start - 1);
                        found_gap = true;
                        break;
                    }
                    cursor = std::max(cursor, end + 1);
                }
                if (!found_gap && cursor <= highest) {
                    gap_start = cursor;
                    gap_end = highest;
                    found_gap = true;
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);

    if (!found_gap) {
        m_explorer_top100_status = QStringLiteral("Holder timeline already covers indexed blocks 0-%1.")
            .arg(QString::number(highest));
        Q_EMIT explorerChanged();
        return;
    }
    startExplorerTop100Timeline(gap_start, gap_end);
}

QVariantMap NuRpcService::explorerTop100Snapshot(int height) const
{
    QVariantMap out;
    QVariantList rows;
    out.insert(QStringLiteral("height"), height);
    out.insert(QStringLiteral("rows"), rows);
    out.insert(QStringLiteral("status"), QStringLiteral("No Holder timeline rows are available yet."));

    QString error;
    if (!ensureExplorerDatabase(&error)) {
        out.insert(QStringLiteral("status"), error);
        return out;
    }
    const QString connection_name = QStringLiteral("nu_explorer_top100_snapshot_%1").arg(QUuid::createUuid().toString(QUuid::Id128));
    int snapshot_height = -1;
    qint64 snapshot_time = 0;
    bool basis_points = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connection_name);
        db.setDatabaseName(explorerDatabasePath());
        if (db.open()) {
            QSqlQuery scale_query(db);
            if (scale_query.exec(QStringLiteral("SELECT value FROM explorer_meta WHERE key = 'top100_percent_scale'")) && scale_query.next()) {
                basis_points = scale_query.value(0).toString() == QLatin1String("basis_points");
            }
            for (int rank = 1; rank <= 100; ++rank) {
                QSqlQuery query(db);
                query.prepare(QStringLiteral(
                    "SELECT height, time, address, percent_whole, color_index "
                    "FROM explorer_top100_events "
                    "WHERE rank = ? AND height <= ? "
                    "ORDER BY height DESC LIMIT 1"));
                query.addBindValue(rank);
                query.addBindValue(height);
                if (query.exec() && query.next()) {
                    const QString address = query.value(2).toString();
                    if (address.isEmpty()) continue;
                    snapshot_height = std::max(snapshot_height, query.value(0).toInt());
                    snapshot_time = std::max<qint64>(snapshot_time, query.value(1).toLongLong());
                    const int pct = query.value(3).toInt();
                    const int pct_basis_points = basis_points ? pct : pct * 100;
                    const double pct_value = static_cast<double>(pct_basis_points) / 100.0;
                    const QString pct_text = pct_value >= 10.0
                        ? QString::number(pct_value, 'f', 1) + QStringLiteral("%")
                        : QString::number(pct_value, 'f', 2) + QStringLiteral("%");
                    rows.push_back(QVariantMap{
                        {QStringLiteral("cells"), QVariantList{
                            explorerTop100Color(rank),
                            rank,
                            address,
                            pct_text}},
                        {QStringLiteral("meta"), QVariantMap{
                            {QStringLiteral("type"), QStringLiteral("address")},
                            {QStringLiteral("id"), address},
                            {QStringLiteral("rank"), rank},
                            {QStringLiteral("address"), address},
                            {QStringLiteral("percentBasisPoints"), pct_basis_points},
                            {QStringLiteral("color"), explorerTop100Color(rank)}}}});
                }
            }
        }
        db.close();
    }
    QSqlDatabase::removeDatabase(connection_name);
    out.insert(QStringLiteral("height"), snapshot_height >= 0 ? snapshot_height : height);
    out.insert(QStringLiteral("time"), QVariant::fromValue<qlonglong>(snapshot_time));
    out.insert(QStringLiteral("rows"), rows);
    out.insert(QStringLiteral("status"), rows.isEmpty()
        ? QStringLiteral("No Holder timeline snapshot exists at or before this block.")
        : QStringLiteral("Snapshot reconstructed from Holder timeline checkpoints."));
    return out;
}

void NuRpcService::refreshForensicsIrregularMessages()
{
    startForensicsIrregularMessages(0);
}

void NuRpcService::startForensicsIrregularMessages(int start_height)
{
    if (!m_rpc_connected) {
        m_forensics_scanning = false;
        m_forensics_request_in_flight = false;
        m_forensics_scan_complete = false;
        m_forensics_scan_status = QStringLiteral("Connect to the local backend before scanning irregular messages.");
        rebuildForensicsScanSummary();
        Q_EMIT forensicsChanged();
        return;
    }

    m_forensics_irregular_messages.clear();
    m_forensics_scanning = true;
    m_forensics_request_in_flight = false;
    m_forensics_scan_complete = false;
    m_forensics_missing_witness_found = false;
    m_forensics_first_missing_witness_height = -1;
    m_forensics_missing_witness_count = 0;
    resetForensicsPrefixCompression();
    m_forensics_scan_start_height = std::max(0, start_height);
    m_forensics_scan_height = m_forensics_scan_start_height;
    m_forensics_scan_tip = std::max(m_forensics_scan_tip, m_block_height);
    m_forensics_scan_status = QStringLiteral("Starting Forensics scan from block %1.").arg(QString::number(m_forensics_scan_height));
    rebuildForensicsScanSummary();
    Q_EMIT forensicsChanged();
    scheduleForensicsScanStep(0);
}

void NuRpcService::stopForensicsScan()
{
    m_forensics_scanning = false;
    m_forensics_request_in_flight = false;
    m_forensics_scan_status = QStringLiteral("Irregular message scan paused at block %1 with %2 flagged rows.")
        .arg(QString::number(std::max(0, m_forensics_scan_height)),
             QString::number(m_forensics_irregular_messages.size()));
    rebuildForensicsScanSummary();
    Q_EMIT forensicsChanged();
}

void NuRpcService::resumeForensicsScan()
{
    if (!m_rpc_connected) {
        m_forensics_scan_status = QStringLiteral("Connect to the local backend before resuming irregular message scan.");
        rebuildForensicsScanSummary();
        Q_EMIT forensicsChanged();
        return;
    }
    if (m_forensics_scan_complete || m_forensics_scan_height <= 0) {
        refreshForensicsIrregularMessages();
        return;
    }
    m_forensics_scanning = true;
    m_forensics_request_in_flight = false;
    m_forensics_scan_status = QStringLiteral("Resuming Forensics scan at block %1.")
        .arg(QString::number(std::max(0, m_forensics_scan_height)));
    rebuildForensicsScanSummary();
    Q_EMIT forensicsChanged();
    scheduleForensicsScanStep(0);
}

void NuRpcService::resetForensicsPrefixCompression()
{
    m_forensics_compress_prefix.clear();
    m_forensics_compress_start_height = -1;
    m_forensics_compress_last_height = -1;
    m_forensics_compress_start_row.clear();
    m_forensics_compress_summary_row.clear();
    m_forensics_compress_end_row.clear();
    m_forensics_compress_start_index = -1;
    m_forensics_compress_summary_index = -1;
    m_forensics_compress_end_index = -1;
    m_forensics_compress_count = 0;
}

void NuRpcService::finalizeForensicsPrefixCompression(QVariantList& rows)
{
    if (m_forensics_compress_count == 1 && m_forensics_compress_start_index >= 0 && m_forensics_compress_start_index < rows.size()) {
        QVariantMap row = rows.at(m_forensics_compress_start_index).toMap();
        QVariantList cells = row.value(QStringLiteral("cells")).toList();
        if (!cells.isEmpty()) cells[0] = m_forensics_compress_start_height;
        row.insert(QStringLiteral("cells"), cells);
        rows[m_forensics_compress_start_index] = row;
    }
    resetForensicsPrefixCompression();
}

bool NuRpcService::appendForensicsDisplayRow(QVariantList& rows, const QVariantMap& display_row)
{
    const QVariantMap meta = display_row.value(QStringLiteral("meta")).toMap();
    const QString prefix = meta.value(QStringLiteral("payloadPrefix4")).toString().toLower();
    const bool compressible_bip141 = prefix == QLatin1String("aa21a9ed");
    if (!compressible_bip141) {
        finalizeForensicsPrefixCompression(rows);
        rows.push_back(display_row);
        return true;
    }

    const QVariant height_value = meta.value(QStringLiteral("height"));
    const int height = height_value.isValid() ? height_value.toInt() : -1;
    const bool same_run = m_forensics_compress_prefix == prefix
        && m_forensics_compress_last_height >= 0
        && height >= m_forensics_compress_last_height;
    if (!same_run) {
        finalizeForensicsPrefixCompression(rows);
        QVariantMap start_row = display_row;
        QVariantList cells = start_row.value(QStringLiteral("cells")).toList();
        if (!cells.isEmpty()) cells[0] = QStringLiteral("%1 -").arg(height, 9, 10, QLatin1Char(' '));
        start_row.insert(QStringLiteral("cells"), cells);
        QVariantMap start_meta = start_row.value(QStringLiteral("meta")).toMap();
        start_meta.insert(QStringLiteral("forensicsRangeRole"), QStringLiteral("start"));
        start_row.insert(QStringLiteral("meta"), start_meta);

        m_forensics_compress_prefix = prefix;
        m_forensics_compress_start_height = height;
        m_forensics_compress_last_height = height;
        m_forensics_compress_start_row = start_row;
        m_forensics_compress_start_index = rows.size();
        m_forensics_compress_count = 1;
        rows.push_back(start_row);
        return true;
    }

    m_forensics_compress_last_height = height;
    ++m_forensics_compress_count;

    QVariantMap end_row = display_row;
    QVariantList end_cells = end_row.value(QStringLiteral("cells")).toList();
    if (!end_cells.isEmpty()) end_cells[0] = QStringLiteral("- %1").arg(height, 9, 10, QLatin1Char(' '));
    end_row.insert(QStringLiteral("cells"), end_cells);
    QVariantMap end_meta = end_row.value(QStringLiteral("meta")).toMap();
    end_meta.insert(QStringLiteral("forensicsRangeRole"), QStringLiteral("end"));
    end_row.insert(QStringLiteral("meta"), end_meta);

    QVariantList summary_cells;
    summary_cells << QStringLiteral("...")
                  << QStringLiteral("[various]")
                  << QStringLiteral("ALL TRANSACTIONS IN THIS RANGE CONTAIN aa21a9ed: BIP141 witness commitment header")
                  << QStringLiteral("—")
                  << QStringLiteral("—")
                  << QStringLiteral("%1 consecutive rows compacted; uncheck regular BIP141 handling only when auditing raw commitment rows.")
                         .arg(QString::number(m_forensics_compress_count));
    QVariantMap summary_meta;
    summary_meta.insert(QStringLiteral("type"), QStringLiteral("range"));
    summary_meta.insert(QStringLiteral("forensicsRangeRole"), QStringLiteral("summary"));
    summary_meta.insert(QStringLiteral("payloadPrefix4"), prefix);
    summary_meta.insert(QStringLiteral("bip141Url"), QStringLiteral("https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki#commitment-structure"));
    QVariantMap summary_row{{QStringLiteral("cells"), summary_cells}, {QStringLiteral("meta"), summary_meta}};

    if (m_forensics_compress_count == 2) {
        m_forensics_compress_summary_index = rows.size();
        rows.push_back(summary_row);
        m_forensics_compress_end_index = rows.size();
        rows.push_back(end_row);
    } else {
        if (m_forensics_compress_summary_index >= 0 && m_forensics_compress_summary_index < rows.size()) rows[m_forensics_compress_summary_index] = summary_row;
        if (m_forensics_compress_end_index >= 0 && m_forensics_compress_end_index < rows.size()) rows[m_forensics_compress_end_index] = end_row;
    }
    return m_forensics_compress_count <= 2;
}

void NuRpcService::rebuildForensicsScanSummary()
{
    const int total_rows = m_forensics_irregular_messages.size();
    if (total_rows == 0) {
        if (m_forensics_scan_complete) {
            m_forensics_scan_summary = QStringLiteral("Scan complete. No irregular message rows were found.");
        } else {
            m_forensics_scan_summary.clear();
        }
        return;
    }

    QSet<int> irregular_blocks;
    QHash<QString, int> prefix_counts;
    int not_op_return_prefix = 0;

    for (const QVariant& item : m_forensics_irregular_messages) {
        const QVariantMap row = item.toMap();
        const QVariantMap meta = row.value(QStringLiteral("meta")).toMap();
        const QVariant height_value = meta.value(QStringLiteral("height"));
        const int height = height_value.isValid() ? height_value.toInt() : -1;
        if (height >= 0) irregular_blocks.insert(height);

        const QString script_prefix = meta.value(QStringLiteral("scriptPrefix4")).toString().toLower();
        if (!script_prefix.startsWith(QStringLiteral("6a"))) ++not_op_return_prefix;

        QString prefix = meta.value(QStringLiteral("payloadPrefix4")).toString().toLower();
        if (prefix.size() < 8) prefix = script_prefix.left(8);
        if (prefix.size() >= 8) ++prefix_counts[prefix.left(8)];
    }

    const int scan_end_height = m_forensics_scan_complete
        ? m_forensics_scan_tip
        : std::max(m_forensics_scan_start_height, m_forensics_scan_height);
    const int scanned_blocks = std::max(1, scan_end_height - m_forensics_scan_start_height + 1);
    const double irregular_block_pct = 100.0 * static_cast<double>(irregular_blocks.size()) / static_cast<double>(scanned_blocks);
    const double not6a_pct = 100.0 * static_cast<double>(not_op_return_prefix) / static_cast<double>(total_rows);

    QList<QPair<QString, int>> prefixes;
    prefixes.reserve(prefix_counts.size());
    for (auto it = prefix_counts.constBegin(); it != prefix_counts.constEnd(); ++it) {
        prefixes.push_back(qMakePair(it.key(), it.value()));
    }
    std::sort(prefixes.begin(), prefixes.end(), [](const auto& a, const auto& b) {
        if (a.second != b.second) return a.second > b.second;
        return a.first < b.first;
    });

    QStringList prefix_parts;
    for (int i = 0; i < prefixes.size() && i < 8; ++i) {
        const double pct = 100.0 * static_cast<double>(prefixes[i].second) / static_cast<double>(total_rows);
        prefix_parts << QStringLiteral("%1: %2 (%3%)")
            .arg(prefixes[i].first.toUpper(),
                 QString::number(prefixes[i].second),
                 QString::number(pct, 'f', 1));
    }
    if (prefixes.size() > 8) {
        prefix_parts << QStringLiteral("%1 more").arg(QString::number(prefixes.size() - 8));
    }

    m_forensics_scan_summary = QStringLiteral("Summary: %1 blocks with irregular rows out of %2 scanned (%3%). Not 6a prefix: %4 rows (%5%). Unique 4-byte prefixes: %6%7")
        .arg(QString::number(irregular_blocks.size()),
             QString::number(scanned_blocks),
             QString::number(irregular_block_pct, 'f', 4),
             QString::number(not_op_return_prefix),
             QString::number(not6a_pct, 'f', 1),
             QString::number(prefix_counts.size()),
             prefix_parts.isEmpty() ? QStringLiteral(".") : QStringLiteral(" | %1.").arg(prefix_parts.join(QStringLiteral("; "))));
}

void NuRpcService::scheduleForensicsScanStep(int delay_ms)
{
    if (!m_forensics_scanning || m_forensics_request_in_flight) return;
    QTimer::singleShot(std::max(0, delay_ms), this, [this] {
        forensicsScanStep();
    });
}

void NuRpcService::forensicsScanStep()
{
    if (!m_forensics_scanning || m_forensics_request_in_flight) return;

    constexpr int chunk_blocks = 25000;
    constexpr int chunk_results = 500;
    constexpr int display_cap = 5000;

    if (m_forensics_irregular_messages.size() >= display_cap) {
        m_forensics_scanning = false;
        m_forensics_scan_complete = false;
        m_forensics_scan_status = QStringLiteral("Scan paused at the %1-row display cap. Enable regular BIP141 handling, export rows, or restart from a narrower height range before continuing.")
            .arg(QString::number(display_cap));
        rebuildForensicsScanSummary();
        Q_EMIT forensicsChanged();
        return;
    }

    const int start_height = std::max(0, m_forensics_scan_height);
    const double pct = m_forensics_scan_tip > 0
        ? (100.0 * static_cast<double>(start_height) / static_cast<double>(m_forensics_scan_tip))
        : 0.0;
    m_forensics_request_in_flight = true;
    m_forensics_scan_status = QStringLiteral("Scanning block %1 of %2 for irregular OP_RETURN messages (%3%).")
        .arg(QString::number(start_height),
             QString::number(std::max(0, m_forensics_scan_tip)),
             QString::number(std::min(100.0, pct), 'f', 2));
    Q_EMIT forensicsChanged();

    rpcCall(QStringLiteral("scanirregularmessages"),
            {start_height, -1, chunk_results, chunk_blocks},
            false,
            [this, start_height](const QJsonValue& result, const QString& error) {
        m_forensics_request_in_flight = false;
        if (!m_forensics_scanning) return;
        if (!error.isEmpty()) {
            m_forensics_scanning = false;
            m_forensics_scan_complete = false;
            m_forensics_scan_status = QStringLiteral("Scan stopped at block %1: %2").arg(QString::number(start_height), error);
            rebuildForensicsScanSummary();
            Q_EMIT forensicsChanged();
            return;
        }

        const QJsonObject obj = result.toObject();
        m_forensics_scan_tip = obj.value(QStringLiteral("tip")).toInt(m_forensics_scan_tip);
        m_forensics_scan_height = obj.value(QStringLiteral("next_height")).toInt(start_height + chunk_blocks);
        const int scanned_blocks = obj.value(QStringLiteral("scanned_blocks")).toInt();
        const QJsonArray results = obj.value(QStringLiteral("results")).toArray();
        const bool missing_witness_found = obj.value(QStringLiteral("missing_witness_found")).toBool(false);
        const int first_missing_witness = obj.value(QStringLiteral("first_missing_witness_height")).toInt(-1);
        const int missing_witness_count = obj.value(QStringLiteral("missing_witness_count")).toInt(0);
        if (missing_witness_found) {
            if (!m_forensics_missing_witness_found || (first_missing_witness > 0 && first_missing_witness < m_forensics_first_missing_witness_height)) {
                m_forensics_first_missing_witness_height = first_missing_witness;
            }
            m_forensics_missing_witness_found = true;
            m_forensics_missing_witness_count += missing_witness_count;
        }

        QVariantList rows = m_forensics_irregular_messages;
        rows.reserve(rows.size() + results.size());
        for (const QJsonValue& value : results) {
            const QJsonObject row = value.toObject();
            const int height = row.value(QStringLiteral("block_height")).toInt();
            const QString txid = row.value(QStringLiteral("txid")).toString();
            const int vout = row.value(QStringLiteral("vout")).toInt();
            const QString burned = row.value(QStringLiteral("burned_text")).toString(QStringLiteral("0.00000000")) + QStringLiteral(" DFC");
            const QString decoded = row.value(QStringLiteral("decoded_text")).toString();
            const QString reason = row.value(QStringLiteral("reason")).toString();
            const QString script_hex = row.value(QStringLiteral("script_hex")).toString().toLower();
            const QString script_prefix4 = row.value(QStringLiteral("script_prefix4")).toString().toLower();
            const QString payload_hex = row.value(QStringLiteral("payload_hex")).toString().toLower();
            const QString payload_prefix4 = row.value(QStringLiteral("payload_prefix4")).toString().toLower();
            QString bip141_definition = QStringLiteral("—");
            QString bip141_url;
            if (payload_hex.startsWith(QStringLiteral("aa21a9ed")) || script_hex.startsWith(QStringLiteral("6a24aa21a9ed"))) {
                bip141_definition = QStringLiteral("BIP141 witness commitment header (aa21a9ed)");
                bip141_url = QStringLiteral("https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki#commitment-structure");
            }
            if (m_forensics_accept_bip141_as_regular && !bip141_url.isEmpty()) {
                continue;
            }
            appendForensicsDisplayRow(rows, QVariantMap{
                {QStringLiteral("cells"), QVariantList{height, txid, bip141_definition, burned, decoded, reason}},
                {QStringLiteral("meta"), QVariantMap{
                    {QStringLiteral("type"), QStringLiteral("transaction")},
                    {QStringLiteral("id"), txid},
                    {QStringLiteral("txid"), txid},
                    {QStringLiteral("height"), height},
                    {QStringLiteral("vout"), vout},
                    {QStringLiteral("reason"), reason},
                    {QStringLiteral("bip141Url"), bip141_url},
                    {QStringLiteral("scriptHex"), script_hex},
                    {QStringLiteral("scriptPrefix4"), script_prefix4},
                    {QStringLiteral("payloadHex"), payload_hex},
                    {QStringLiteral("payloadPrefix4"), payload_prefix4},
                    {QStringLiteral("scriptSize"), row.value(QStringLiteral("script_size")).toInt()}}}
            });
        }
        m_forensics_irregular_messages = rows;
        rebuildForensicsScanSummary();

        const bool complete = obj.value(QStringLiteral("complete")).toBool(false);
        const double pct = m_forensics_scan_tip > 0
            ? (100.0 * static_cast<double>(m_forensics_scan_height) / static_cast<double>(m_forensics_scan_tip))
            : 0.0;
        if (complete) {
            finalizeForensicsPrefixCompression(m_forensics_irregular_messages);
            m_forensics_scanning = false;
            m_forensics_scan_complete = true;
            rebuildForensicsScanSummary();
            m_forensics_scan_status = QStringLiteral("Scan complete through block %1. Found %2 irregular message rows.")
                .arg(QString::number(m_forensics_scan_tip),
                     QString::number(m_forensics_irregular_messages.size()));
            Q_EMIT forensicsChanged();
            return;
        }

        m_forensics_scan_status = QStringLiteral("Scanned %1 blocks in this pass. Found %2 flagged rows so far; next block %3 of %4 (%5%).")
            .arg(QString::number(scanned_blocks),
                 QString::number(m_forensics_irregular_messages.size()),
                 QString::number(m_forensics_scan_height),
                 QString::number(m_forensics_scan_tip),
                 QString::number(std::min(100.0, pct), 'f', 2));
        Q_EMIT forensicsChanged();
        scheduleForensicsScanStep(15);
    });
}

QString NuRpcService::explorerLookupHtml(const QString& title,
                                         const QString& summary_html,
                                         const QJsonValue& raw_json) const
{
    return QStringLiteral("<h2>%1</h2>%2<h3>Source JSON</h3><pre>%3</pre>")
        .arg(title.toHtmlEscaped(),
             summary_html,
             QString::fromUtf8(QJsonDocument(raw_json.toObject()).toJson(QJsonDocument::Indented)).toHtmlEscaped());
}

void NuRpcService::emitExplorerError(const QString& title, const QString& detail)
{
    Q_EMIT explorerWindowRequested(title, QStringLiteral("<h2>%1</h2><p>%2</p>")
        .arg(title.toHtmlEscaped(), detail.toHtmlEscaped()));
}

QString NuRpcService::explorerUrlForTransaction(const QString& txid) const
{
    if (!m_third_party_tx_urls_enabled || txid.trimmed().isEmpty() || !m_third_party_tx_url.contains(QStringLiteral("%s"))) {
        return QString();
    }
    QString out = m_third_party_tx_url;
    out.replace(QStringLiteral("%s"), QString::fromLatin1(QUrl::toPercentEncoding(txid.trimmed())));
    return out;
}

QString NuRpcService::explorerUrlForAddress(const QString& address) const
{
    if (!m_third_party_tx_urls_enabled || address.trimmed().isEmpty() || !m_third_party_tx_url.contains(QStringLiteral("%s"))) {
        return QString();
    }
    QString out = explorerAddressUrlTemplate(m_third_party_tx_url);
    out.replace(QStringLiteral("%s"), QString::fromLatin1(QUrl::toPercentEncoding(address.trimmed())));
    return out;
}

void NuRpcService::openTransactionInExplorer(const QString& txid)
{
    const QString clean_txid = txid.trimmed();
    if (clean_txid.isEmpty()) {
        emitExplorerError(QStringLiteral("Transaction not opened"), QStringLiteral("This item does not include a transaction ID."));
        return;
    }
    if (!isHex256(clean_txid)) {
        emitExplorerError(QStringLiteral("Transaction not opened"), QStringLiteral("Transaction IDs must be 64 hexadecimal characters."));
        return;
    }
#if !DEFCOIN_NU_EXPLORE_APP
    if (usingInternalExplorer() && launchExploreLookup(QStringLiteral("--open-transaction"), clean_txid)) return;
#endif
    if (!usingInternalExplorer()) {
        const QString url = explorerUrlForTransaction(clean_txid);
        if (url.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Explorer link unavailable"),
                               QStringLiteral("Choose a Defcoin explorer URL in Settings before opening external transaction links."));
            return;
        }
        const QUrl external_url(url, QUrl::StrictMode);
        if (!isSafeHttpUrl(external_url)) {
            Q_EMIT userMessage(QStringLiteral("Explorer link blocked"),
                               QStringLiteral("External explorer links must use a valid http:// or https:// URL without embedded credentials."));
            return;
        }
        if (!QDesktopServices::openUrl(external_url)) {
            Q_EMIT userMessage(QStringLiteral("Explorer link failed"),
                               QStringLiteral("Nu could not open the external transaction explorer link."));
        }
        return;
    }
    if (!m_rpc_connected) {
        bool indexed_found = false;
        QJsonObject indexed_raw;
        const QString indexed_summary = explorerIndexedTransactionHtml(clean_txid, &indexed_raw, &indexed_found);
        if (indexed_found) {
            Q_EMIT explorerWindowRequested(QStringLiteral("Transaction %1").arg(clean_txid.left(12)),
                                           explorerLookupHtml(QStringLiteral("Transaction"), indexed_summary, indexed_raw));
            return;
        }
        emitExplorerError(QStringLiteral("Internal explorer unavailable"),
                          QStringLiteral("Connect to the local Defcoin backend before using the internal explorer."));
        return;
    }

    QJsonArray raw_tx_params;
    raw_tx_params.append(clean_txid);
    raw_tx_params.append(true);
    const QString indexed_block_hash = explorerBlockHashForTransaction(clean_txid);
    if (!indexed_block_hash.isEmpty()) raw_tx_params.append(indexed_block_hash);
    rpcCall(QStringLiteral("getrawtransaction"), raw_tx_params, false, [this, clean_txid](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) {
            bool indexed_found = false;
            QJsonObject indexed_raw;
            const QString indexed_summary = explorerIndexedTransactionHtml(clean_txid, &indexed_raw, &indexed_found);
            if (indexed_found) {
                Q_EMIT explorerWindowRequested(QStringLiteral("Transaction %1").arg(clean_txid.left(12)),
                                               explorerLookupHtml(QStringLiteral("Transaction"), indexed_summary, indexed_raw));
                return;
            }
            rpcCall(QStringLiteral("gettransaction"), {clean_txid, true}, true, [this, clean_txid](const QJsonValue& wallet_result, const QString& wallet_error) {
                if (!wallet_error.isEmpty()) {
                    emitExplorerError(QStringLiteral("Transaction not found"),
                                      QStringLiteral("The internal explorer could not retrieve this transaction from the node or the active wallet:\n%1").arg(wallet_error));
                    return;
                }
                const QJsonObject tx = wallet_result.toObject();
                const QString summary = QStringLiteral("<table><tr><th>Transaction ID</th><td>%1</td></tr><tr><th>Confirmations</th><td>%2</td></tr><tr><th>Amount</th><td>%3 DFC</td></tr></table>")
                    .arg(clean_txid.toHtmlEscaped(),
                         QString::number(tx.value(QStringLiteral("confirmations")).toInt()).toHtmlEscaped(),
                         QString::number(tx.value(QStringLiteral("amount")).toDouble(), 'f', 8).toHtmlEscaped());
                cacheExplorerLookup(QStringLiteral("transaction"), clean_txid, QStringLiteral("Transaction"), clean_txid, wallet_result);
                Q_EMIT explorerWindowRequested(QStringLiteral("Transaction %1").arg(clean_txid.left(12)), explorerLookupHtml(QStringLiteral("Transaction"), summary, wallet_result));
            });
            return;
        }
        const QJsonObject tx = result.toObject();
        const QJsonArray vin = tx.value(QStringLiteral("vin")).toArray();
        const QJsonArray vout = tx.value(QStringLiteral("vout")).toArray();
        QString output_rows;
        for (const QJsonValue& value : vout) {
            const QJsonObject out = value.toObject();
            const QJsonObject script = out.value(QStringLiteral("scriptPubKey")).toObject();
            const QStringList addresses = recognizedExplorerAddresses(explorerOutputAddresses(script));
            const QString address_html = explorerAddressLinksHtml(addresses);
            output_rows += QStringLiteral("<tr><td>%1</td><td>%2 DFC</td><td>%3</td></tr>")
                .arg(QString::number(out.value(QStringLiteral("n")).toInt()).toHtmlEscaped(),
                     QString::number(out.value(QStringLiteral("value")).toDouble(), 'f', 8).toHtmlEscaped(),
                     address_html.isEmpty()
                         ? QStringLiteral("Unknown or nonstandard").toHtmlEscaped()
                         : address_html);
        }
        const QString blockhash = tx.value(QStringLiteral("blockhash")).toString();
        const QString block_link = blockhash.isEmpty()
            ? QStringLiteral("Unconfirmed")
            : QStringLiteral("<a href=\"nu://block/%1\">%2</a>").arg(QString::fromLatin1(QUrl::toPercentEncoding(blockhash)).toHtmlEscaped(), blockhash.toHtmlEscaped());
        const QString summary = QStringLiteral(
            "<table>"
            "<tr><th>Transaction ID</th><td>%1</td></tr>"
            "<tr><th>Confirmations</th><td>%2</td></tr>"
            "<tr><th>Block</th><td>%3</td></tr>"
            "<tr><th>Inputs</th><td>%4</td></tr>"
            "<tr><th>Outputs</th><td>%5</td></tr>"
            "<tr><th>Size</th><td>%6 bytes</td></tr>"
            "</table>"
            "<h3>Outputs</h3><table><tr><th>N</th><th>Value</th><th>Address</th></tr>%7</table>")
            .arg(clean_txid.toHtmlEscaped(),
                 QString::number(tx.value(QStringLiteral("confirmations")).toInt()).toHtmlEscaped(),
                 block_link,
                 QString::number(vin.size()).toHtmlEscaped(),
                 QString::number(vout.size()).toHtmlEscaped(),
                 QString::number(tx.value(QStringLiteral("size")).toInt()).toHtmlEscaped(),
                 output_rows);
        cacheExplorerLookup(QStringLiteral("transaction"), clean_txid, QStringLiteral("Transaction"), clean_txid, result);
        Q_EMIT explorerWindowRequested(QStringLiteral("Transaction %1").arg(clean_txid.left(12)), explorerLookupHtml(QStringLiteral("Transaction"), summary, result));
    });
}

void NuRpcService::openAddressInExplorer(const QString& address)
{
    const QString clean_address = address.trimmed();
    if (clean_address.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Address not opened"),
                           QStringLiteral("This row does not include an address to inspect."));
        return;
    }
    if (!isLikelyBase58AddressText(clean_address)) {
        Q_EMIT userMessage(QStringLiteral("Address not opened"),
                           QStringLiteral("Enter a valid Defcoin Base58 address, such as D..., M..., legacy 3..., or compatibility 9.../A... before opening explorer details."));
        return;
    }

#if !DEFCOIN_NU_EXPLORE_APP
    if (usingInternalExplorer() && launchExploreLookup(QStringLiteral("--open-address"), clean_address)) return;
#endif

    if (usingInternalExplorer()) {
        bool indexed_found = false;
        const QString indexed_summary = explorerIndexedAddressHtml(clean_address, &indexed_found);
        if (indexed_found) {
            QJsonObject raw;
            raw.insert(QStringLiteral("address"), clean_address);
            raw.insert(QStringLiteral("source"), QStringLiteral("local SQLite explorer index"));
            raw.insert(QStringLiteral("indexedThroughBlock"), explorerHighestIndexedBlock());
            cacheExplorerLookup(QStringLiteral("address"), clean_address, QStringLiteral("Address"), clean_address, raw);
            Q_EMIT explorerWindowRequested(QStringLiteral("Address %1").arg(clean_address.left(12)),
                                           explorerLookupHtml(QStringLiteral("Address"), indexed_summary, raw));
            return;
        }

        if (!m_rpc_connected) {
            emitExplorerError(QStringLiteral("Internal explorer unavailable"),
                              QStringLiteral("This address is not in the local explorer index yet. Connect to the local Defcoin backend, build the Explorer index, or switch Settings to an external explorer."));
            return;
        }
        rpcCall(QStringLiteral("getaddressinfo"), {clean_address}, true, [this, clean_address](const QJsonValue& result, const QString& error) {
            if (!error.isEmpty()) {
                emitExplorerError(QStringLiteral("Address not found"),
                                  QStringLiteral("The internal explorer could not retrieve this address from the active wallet:\n%1").arg(error));
                return;
            }
            const QJsonObject info = result.toObject();
            QString summary = QStringLiteral(
                "<table>"
                "<tr><th>Address</th><td>%1</td></tr>"
                "<tr><th>Known to active wallet</th><td>%2</td></tr>"
                "<tr><th>Mine</th><td>%3</td></tr>"
                "<tr><th>Watch only</th><td>%4</td></tr>"
                "<tr><th>Solvable</th><td>%5</td></tr>"
                "<tr><th>Label</th><td>%6</td></tr>"
                "</table>")
                .arg(clean_address.toHtmlEscaped(),
                     info.value(QStringLiteral("isvalid")).toBool() ? QStringLiteral("Yes") : QStringLiteral("No"),
                     info.value(QStringLiteral("ismine")).toBool() ? QStringLiteral("Yes") : QStringLiteral("No"),
                     info.value(QStringLiteral("iswatchonly")).toBool() ? QStringLiteral("Yes") : QStringLiteral("No"),
                     info.value(QStringLiteral("solvable")).toBool() ? QStringLiteral("Yes") : QStringLiteral("No"),
                     info.value(QStringLiteral("label")).toString().toHtmlEscaped());
            summary += QStringLiteral("<p>This address was not found in the chain index yet, so Nu is showing active-wallet metadata. Build the Explorer background index to enable chain-wide received/spent summaries.</p>");
            cacheExplorerLookup(QStringLiteral("address"), clean_address, QStringLiteral("Address"), clean_address, result);
            Q_EMIT explorerWindowRequested(QStringLiteral("Address %1").arg(clean_address.left(12)), explorerLookupHtml(QStringLiteral("Address"), summary, result));
        });
        return;
    }

    const QString url = explorerUrlForAddress(clean_address);
    if (url.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Explorer link unavailable"),
                           QStringLiteral("Choose a Defcoin explorer URL in Settings before opening external address links."));
        return;
    }

    const QUrl external_url(url, QUrl::StrictMode);
    if (!isSafeHttpUrl(external_url)) {
        Q_EMIT userMessage(QStringLiteral("Explorer link blocked"),
                           QStringLiteral("External explorer links must use a valid http:// or https:// URL without embedded credentials."));
        return;
    }
    if (!QDesktopServices::openUrl(external_url)) {
        Q_EMIT userMessage(QStringLiteral("Explorer link failed"),
                           QStringLiteral("Nu could not open the external address explorer link."));
    }
}

void NuRpcService::openBlockInExplorer(const QString& block_id)
{
    const QString clean = block_id.trimmed();
    if (clean.isEmpty()) {
        emitExplorerError(QStringLiteral("Block not opened"), QStringLiteral("Enter a block height or block hash."));
        return;
    }
    if (!isNonNegativeBlockHeight(clean) && !isHex256(clean)) {
        emitExplorerError(QStringLiteral("Block not opened"), QStringLiteral("Block lookups must use a non-negative height or a 64-character hexadecimal block hash."));
        return;
    }
#if !DEFCOIN_NU_EXPLORE_APP
    if (usingInternalExplorer() && launchExploreLookup(QStringLiteral("--open-block"), clean)) return;
#endif
    if (!usingInternalExplorer()) {
        Q_EMIT userMessage(QStringLiteral("External block links unavailable"),
                           QStringLiteral("This explorer setting only defines transaction and address URL templates. Switch to the internal explorer for block lookups."));
        return;
    }
    if (!m_rpc_connected) {
        bool cached_found = false;
        QJsonObject cached_raw;
        const QString cached_summary = explorerCachedBlockHtml(clean, &cached_raw, &cached_found);
        if (cached_found) {
            Q_EMIT explorerWindowRequested(QStringLiteral("Block %1").arg(cached_raw.value(QStringLiteral("height")).toInt()),
                                           explorerLookupHtml(QStringLiteral("Block"), cached_summary, cached_raw));
            return;
        }
        emitExplorerError(QStringLiteral("Internal explorer unavailable"),
                          QStringLiteral("Connect to the local Defcoin backend before using the internal explorer."));
        return;
    }

    auto fetch_block = [this](const QString& hash_or_height, const QString& hash) {
        rpcCall(QStringLiteral("getblock"), {hash, 2}, false, [this, hash_or_height, hash](const QJsonValue& result, const QString& error) {
            if (!error.isEmpty()) {
                bool cached_found = false;
                QJsonObject cached_raw;
                QString cached_summary = explorerCachedBlockHtml(hash_or_height, &cached_raw, &cached_found);
                if (!cached_found) cached_summary = explorerCachedBlockHtml(hash, &cached_raw, &cached_found);
                if (cached_found) {
                    Q_EMIT explorerWindowRequested(QStringLiteral("Block %1").arg(cached_raw.value(QStringLiteral("height")).toInt()),
                                                   explorerLookupHtml(QStringLiteral("Block"), cached_summary, cached_raw));
                    return;
                }
                emitExplorerError(QStringLiteral("Block not found"), error);
                return;
            }
            const QJsonObject block = result.toObject();
            const QJsonArray tx = block.value(QStringLiteral("tx")).toArray();
            QString tx_rows;
            const int tx_limit = std::min(static_cast<int>(tx.size()), 25);
            for (int i = 0; i < tx_limit; ++i) {
                QString txid = tx.at(i).toObject().value(QStringLiteral("txid")).toString();
                if (txid.isEmpty()) txid = tx.at(i).toString();
                tx_rows += QStringLiteral("<tr><td>%1</td><td><a href=\"nu://transaction/%2\">%3</a></td></tr>")
                    .arg(QString::number(i).toHtmlEscaped(),
                         QString::fromLatin1(QUrl::toPercentEncoding(txid)).toHtmlEscaped(),
                         txid.toHtmlEscaped());
            }
            if (tx.size() > tx_limit) {
                tx_rows += QStringLiteral("<tr><td colspan=\"2\">%1 more transactions omitted from the compact view.</td></tr>")
                    .arg(QString::number(tx.size() - tx_limit).toHtmlEscaped());
            }
            const QString summary = QStringLiteral(
                "<table>"
                "<tr><th>Height</th><td>%1</td></tr>"
                "<tr><th>Hash</th><td>%2</td></tr>"
                "<tr><th>Confirmations</th><td>%3</td></tr>"
                "<tr><th>Time</th><td>%4</td></tr>"
                "<tr><th>Transactions</th><td>%5</td></tr>"
                "<tr><th>Difficulty</th><td>%6</td></tr>"
                "</table>"
                "<h3>Transactions</h3><table><tr><th>N</th><th>Transaction ID</th></tr>%7</table>")
                .arg(QString::number(block.value(QStringLiteral("height")).toInt()).toHtmlEscaped(),
                     hash.toHtmlEscaped(),
                     QString::number(block.value(QStringLiteral("confirmations")).toInt()).toHtmlEscaped(),
                     QDateTime::fromSecsSinceEpoch(block.value(QStringLiteral("time")).toVariant().toLongLong()).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t")).toHtmlEscaped(),
                     QString::number(tx.size()).toHtmlEscaped(),
                     QString::number(block.value(QStringLiteral("difficulty")).toDouble(), 'f', 8).toHtmlEscaped(),
                     tx_rows);
            cacheExplorerLookup(QStringLiteral("block"), hash_or_height, QStringLiteral("Block"), hash, result);
            Q_EMIT explorerWindowRequested(QStringLiteral("Block %1").arg(block.value(QStringLiteral("height")).toInt()), explorerLookupHtml(QStringLiteral("Block"), summary, result));
        });
    };

    bool is_height = false;
    const int height = clean.toInt(&is_height);
    if (is_height && height >= 0) {
        rpcCall(QStringLiteral("getblockhash"), {height}, false, [this, clean, fetch_block](const QJsonValue& result, const QString& error) {
            if (!error.isEmpty()) {
                emitExplorerError(QStringLiteral("Block not found"), error);
                return;
            }
            fetch_block(clean, result.toString());
        });
    } else {
        fetch_block(clean, clean);
    }
}

void NuRpcService::searchExplorer(const QString& query)
{
    const QString clean = query.trimmed();
    if (clean.isEmpty()) {
        emitExplorerError(QStringLiteral("Explorer search"), QStringLiteral("Enter a block height, block hash, transaction ID, or wallet address."));
        return;
    }
    if (clean.size() > 128) {
        emitExplorerError(QStringLiteral("Explorer search"), QStringLiteral("Search input is too long. Enter a block height, 64-character hash, or Defcoin address."));
        return;
    }
#if !DEFCOIN_NU_EXPLORE_APP
    if (usingInternalExplorer() && launchExploreLookup(QStringLiteral("--search"), clean)) return;
#endif
    bool is_height = false;
    clean.toInt(&is_height);
    if (is_height && !isNonNegativeBlockHeight(clean)) {
        emitExplorerError(QStringLiteral("Explorer search"), QStringLiteral("Block height must be a non-negative whole number."));
        return;
    }
    if (clean.size() == 64 && !isHex256(clean)) {
        emitExplorerError(QStringLiteral("Explorer search"), QStringLiteral("64-character lookups must be hexadecimal block or transaction hashes."));
        return;
    }
    if (is_height || clean.size() == 64) {
        if (clean.size() == 64) {
            if (usingInternalExplorer() && !m_rpc_connected) {
                bool cached_block_found = false;
                QJsonObject cached_block_raw;
                const QString cached_block_summary = explorerCachedBlockHtml(clean, &cached_block_raw, &cached_block_found);
                if (cached_block_found) {
                    Q_EMIT explorerWindowRequested(QStringLiteral("Block %1").arg(cached_block_raw.value(QStringLiteral("height")).toInt()),
                                                   explorerLookupHtml(QStringLiteral("Block"), cached_block_summary, cached_block_raw));
                    return;
                }
                openTransactionInExplorer(clean);
                return;
            }
            rpcCall(QStringLiteral("getblock"), {clean, 0}, false, [this, clean](const QJsonValue&, const QString& error) {
                if (error.isEmpty()) openBlockInExplorer(clean);
                else openTransactionInExplorer(clean);
            });
        } else {
            openBlockInExplorer(clean);
        }
        return;
    }
    if (!isLikelyBase58AddressText(clean)) {
        emitExplorerError(QStringLiteral("Explorer search"), QStringLiteral("Search input is not a recognized block height, block hash, transaction ID, or Defcoin Base58 address."));
        return;
    }
    openAddressInExplorer(clean);
}

void NuRpcService::openExplorerLink(const QString& link)
{
    const QString clean_link = singleLineLimited(link, 2048);
    const QUrl url(clean_link, QUrl::StrictMode);
    if (url.scheme() != QLatin1String("nu")) {
        if (!isSafeHttpUrl(url)) {
            Q_EMIT userMessage(QStringLiteral("Explorer link blocked"),
                               QStringLiteral("Nu blocked an explorer link that was not a valid http://, https://, or internal nu:// link."));
            return;
        }
        if (!QDesktopServices::openUrl(url)) {
            Q_EMIT userMessage(QStringLiteral("Explorer link failed"),
                               QStringLiteral("Nu could not open that explorer link."));
        }
        return;
    }
    const QString kind = url.host();
    const QString value = QUrl::fromPercentEncoding(url.path().mid(1).toUtf8());
    if (kind == QLatin1String("transaction") || kind == QLatin1String("tx")) {
        openTransactionInExplorer(value);
    } else if (kind == QLatin1String("address")) {
        openAddressInExplorer(value);
    } else if (kind == QLatin1String("block")) {
        openBlockInExplorer(value);
    } else {
        Q_EMIT userMessage(QStringLiteral("Explorer link blocked"),
                           QStringLiteral("Nu did not recognize this internal explorer link type."));
    }
}

void NuRpcService::copyText(const QString& text)
{
    if (looksLikeRecoveryPhraseText(text)) {
        Q_EMIT userMessage(QStringLiteral("Clipboard copy blocked"),
                           QStringLiteral("This text looks like a recovery phrase. Use the recovery phrase copy control and acknowledge the clipboard warning before copying phrase text."));
        return;
    }
    QApplication::clipboard()->setText(text);
}

void NuRpcService::copySensitiveTextAfterWarning(const QString& text)
{
    const QString clean_text = text.trimmed();
    if (clean_text.isEmpty() || clean_text.size() > SENSITIVE_CLIPBOARD_MAX_CHARS) {
        Q_EMIT userMessage(QStringLiteral("Clipboard copy blocked"),
                           QStringLiteral("Sensitive clipboard text is empty or too large to copy safely from Nu."));
        return;
    }
    QApplication::clipboard()->setText(clean_text);
}

void NuRpcService::openExternalUrl(const QString& url)
{
    const QUrl clean_url(singleLineLimited(url, 2048), QUrl::StrictMode);
    if (!isSafeHttpUrl(clean_url)) {
        Q_EMIT userMessage(QStringLiteral("Link blocked"),
                           QStringLiteral("Nu blocked a link that was not a valid http:// or https:// URL without embedded credentials."));
        return;
    }
    if (!QDesktopServices::openUrl(clean_url)) {
        Q_EMIT userMessage(QStringLiteral("Link failed"),
                           QStringLiteral("Nu could not open that link."));
    }
}

void NuRpcService::openCoindroidsReportPdf()
{
    const QString relative_path = QStringLiteral("assets/docs/coindroids_defcoin_forensics_story_report_v6.pdf");
    const QStringList candidates{
        QDir(nuResourceRoot()).filePath(relative_path),
        QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("nu/%1").arg(relative_path)),
        QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("../Resources/nu/%1").arg(relative_path)),
        QStringLiteral("/Volumes/TB5_4TB/d/Downloads/coindroids_defcoin_forensics_story_report_v6.pdf")
    };
    for (const QString& candidate : candidates) {
        const QFileInfo info(candidate);
        if (!info.exists() || !info.isFile()) continue;
        if (!QDesktopServices::openUrl(QUrl::fromLocalFile(info.absoluteFilePath()))) {
            Q_EMIT userMessage(QStringLiteral("PDF failed"),
                               QStringLiteral("Nu could not open the Coindroids PDF report."));
        }
        return;
    }
    Q_EMIT userMessage(QStringLiteral("PDF not found"),
                       QStringLiteral("The bundled Coindroids story report placeholder is missing from this build."));
}

void NuRpcService::backupWallet()
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Wallet backup failed"))) return;
    const QString path = QFileDialog::getSaveFileName(nullptr, QStringLiteral("Backup Wallet"), QDir(realHomePath()).filePath(QStringLiteral("wallet.dat")));
    if (path.isEmpty()) return;
    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("backupwallet"), {path}, true, [this, wallet_name](const QJsonValue&, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        Q_EMIT userMessage(error.isEmpty() ? QStringLiteral("Wallet backup complete") : QStringLiteral("Wallet backup failed"),
                           error.isEmpty() ? QStringLiteral("The wallet backup was written successfully.") : error);
    });
}

void NuRpcService::createWallet(const QString& name,
                                bool encrypt,
                                const QString& passphrase,
                                bool disable_private_keys,
                                bool blank,
                                bool descriptor_sql)
{
    const QString wallet_name = name.trimmed();
    if (wallet_name.size() > 128) {
        Q_EMIT userMessage(QStringLiteral("Wallet not created"),
                           QStringLiteral("Wallet names can be up to 128 characters. Shorten this name before creating the wallet."));
        return;
    }
    if (!isLikelyCreatableWalletMenuName(wallet_name)) {
        Q_EMIT userMessage(QStringLiteral("Wallet not created"),
                           QStringLiteral("Enter a wallet directory name without slashes, colons, control characters, path segments, backup suffixes, or copy labels."));
        return;
    }
    const QString clean_passphrase = passphrase;
    if (encrypt && clean_passphrase.size() < 8) {
        Q_EMIT userMessage(QStringLiteral("Wallet not created"),
                           QStringLiteral("Enter a wallet encryption passphrase of at least 8 characters, or turn off Encrypt Wallet."));
        return;
    }
    if (disable_private_keys && encrypt) {
        Q_EMIT userMessage(QStringLiteral("Wallet not created"),
                           QStringLiteral("A watch-only wallet with private keys disabled cannot be encrypted because it will not contain private keys."));
        return;
    }

    QJsonArray params;
    params << wallet_name
           << disable_private_keys
           << blank
           << (encrypt ? QJsonValue(clean_passphrase) : QJsonValue())
           << false
           << descriptor_sql
           << true;

    rpcCall(QStringLiteral("createwallet"), params, false, [this, wallet_name, descriptor_sql](const QJsonValue&, const QString& error) {
        if (error.isEmpty()) {
            setCurrentWalletInternal(wallet_name);
            refresh();
        }
        Q_EMIT userMessage(error.isEmpty() ? QStringLiteral("Wallet created") : QStringLiteral("Wallet not created"),
                           error.isEmpty()
                               ? QStringLiteral("The %1 wallet was created and loaded. Wallet data is stored in the shared Defcoin data directory.")
                                     .arg(descriptor_sql ? QStringLiteral("SQL descriptor") : QStringLiteral("BDB legacy"))
                               : error);
    });
}

void NuRpcService::createWalletWithRecoveryPhrase(const QString& wallet_name,
                                                  const QString& phrase,
                                                  bool encrypt,
                                                  const QString& passphrase)
{
    restoreWalletFromRecoveryPhrase(wallet_name, phrase, QStringLiteral("core"), QString(), QStringLiteral("current"), 0, encrypt, passphrase);
}

void NuRpcService::previewRecoveryPhraseAddresses(const QString& phrase,
                                                  const QString& derivation_path,
                                                  const QString& wif_mode,
                                                  int count)
{
    QVariantMap preview;
    if (!requireLocalRecoveryRpc(QStringLiteral("Recovery preview blocked"))) {
        Q_EMIT recoveryPhrasePreviewReady(preview, QStringLiteral("Recovery phrase preview requires a local backend RPC connection."));
        return;
    }

    count = std::clamp(count, 1, 50);
    QString xprv;
    QString error;
    QString normalized_phrase;
    if (!validateMnemonic(phrase, &normalized_phrase, &error)) {
        Q_EMIT recoveryPhrasePreviewReady(preview, error);
        return;
    }
    if (!mnemonicMaterial(normalized_phrase, wif_mode, nullptr, &xprv, &error)) {
        Q_EMIT recoveryPhrasePreviewReady(preview, error);
        return;
    }

    const QString descriptor = descriptorForRecoveryPath(xprv, derivation_path, &error);
    xprv.clear();
    if (descriptor.isEmpty()) {
        Q_EMIT recoveryPhrasePreviewReady(preview, error);
        return;
    }

    const QString effective_path = derivation_path.trimmed().isEmpty() ? QStringLiteral("m/44'/0'/0'/0/*") : derivation_path.trimmed();
    const int word_count = normalized_phrase.split(QLatin1Char(' '), Qt::SkipEmptyParts).size();
    const int entropy_bits = bip39EntropyBitsForWordCount(word_count);
    const QString wif_label = recoveryWifLabel(wif_mode);

    rpcCall(QStringLiteral("getdescriptorinfo"), {descriptor}, false, [this, descriptor, count, effective_path, word_count, entropy_bits, wif_label](const QJsonValue& result, const QString& error) {
        QVariantMap preview;
        if (!error.isEmpty() || !result.isObject()) {
            Q_EMIT recoveryPhrasePreviewReady(preview, error.isEmpty() ? QStringLiteral("The backend did not return descriptor details.") : error);
            return;
        }
        const QJsonObject descriptor_info = result.toObject();
        const QString checksum = descriptor_info.value(QStringLiteral("checksum")).toString();
        if (checksum.isEmpty()) {
            Q_EMIT recoveryPhrasePreviewReady(preview, QStringLiteral("The backend did not return a descriptor checksum."));
            return;
        }
        const QString checked_descriptor = descriptor.section(QLatin1Char('#'), 0, 0) + QStringLiteral("#") + checksum;
        const QString public_descriptor = descriptor_info.value(QStringLiteral("descriptor")).toString();
        const QString descriptor_hash = QString::fromLatin1(QCryptographicHash::hash(checked_descriptor.toUtf8(), QCryptographicHash::Sha256).toHex());

        QVariantList details;
        details.push_back(tableRow({QStringLiteral("BIP39 words"), QStringLiteral("%1 words, %2-bit entropy, checksum valid").arg(word_count).arg(entropy_bits)}, {}));
        details.push_back(tableRow({QStringLiteral("Derivation path"), effective_path}, {}));
        details.push_back(tableRow({QStringLiteral("WIF reference"), wif_label}, {}));
        details.push_back(tableRow({QStringLiteral("Address script"), QStringLiteral("P2PKH / pkh(...) Defcoin addresses")}, {}));
        details.push_back(tableRow({QStringLiteral("Descriptor checksum"), checksum}, {}));
        details.push_back(tableRow({QStringLiteral("Descriptor fingerprint"), descriptor_hash.left(24)}, {}));
        details.push_back(tableRow({QStringLiteral("Public descriptor"), public_descriptor.isEmpty() ? QStringLiteral("Backend did not return a public descriptor.") : public_descriptor}, {}));
        details.push_back(tableRow({QStringLiteral("Private material"), QStringLiteral("Hidden. Nu uses it locally only for preview/import and does not display the phrase, xprv, or private keys here.")}, {}));

        preview.insert(QStringLiteral("details"), details);
        preview.insert(QStringLiteral("path"), effective_path);
        preview.insert(QStringLiteral("count"), count);
        QJsonArray range;
        range << 0 << (count - 1);
        rpcCall(QStringLiteral("deriveaddresses"), {checked_descriptor, range}, false, [this, preview](const QJsonValue& result, const QString& error) mutable {
            QVariantList rows;
            if (!error.isEmpty()) {
                preview.insert(QStringLiteral("addresses"), rows);
                Q_EMIT recoveryPhrasePreviewReady(preview, error);
                return;
            }
            int index = 0;
            for (const QJsonValue& value : result.toArray()) {
                QVariantMap row;
                row.insert(QStringLiteral("index"), index++);
                row.insert(QStringLiteral("address"), value.toString());
                rows.push_back(row);
            }
            preview.insert(QStringLiteral("addresses"), rows);
            Q_EMIT recoveryPhrasePreviewReady(preview, rows.isEmpty() ? QStringLiteral("No preview addresses were derived.") : QStringLiteral("Preview addresses derived. Verify these before importing."));
        });
    });
}

void NuRpcService::restoreWalletFromRecoveryPhrase(const QString& wallet_name,
                                                   const QString& phrase,
                                                   const QString& mode,
                                                   const QString& derivation_path,
                                                   const QString& wif_mode,
                                                   int range,
                                                   bool encrypt,
                                                   const QString& passphrase)
{
    if (!requireLocalRecoveryRpc(QStringLiteral("Wallet not restored"))) return;

    const QString clean_wallet_name = wallet_name.trimmed();
    if (clean_wallet_name.size() > 128) {
        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
        Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                           QStringLiteral("Wallet names can be up to 128 characters. Shorten this name before restoring the wallet."));
        return;
    }
    if (!isLikelyCreatableWalletMenuName(clean_wallet_name)) {
        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
        Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                           QStringLiteral("Enter a new wallet directory name without slashes, colons, control characters, path segments, backup suffixes, or copy labels."));
        return;
    }
    if (m_available_wallets.contains(clean_wallet_name) || m_loaded_wallets.contains(clean_wallet_name)) {
        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
        Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                           QStringLiteral("Choose a new wallet name. Recovery never overwrites an existing wallet."));
        return;
    }
    if (encrypt && passphrase.size() < 8) {
        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
        Q_EMIT userMessage(QStringLiteral("Wallet not restored"),
                           QStringLiteral("Enter a wallet encryption passphrase of at least 8 characters, or turn off Encrypt recovered wallet."));
        return;
    }

    const bool auto_mode = mode.compare(QStringLiteral("auto"), Qt::CaseInsensitive) == 0;
    const bool external_mode = mode.compare(QStringLiteral("external"), Qt::CaseInsensitive) == 0;
    const bool descriptor_scan_mode = auto_mode || external_mode;
    const bool gap_scan_mode = descriptor_scan_mode && range < 0;
    setRecoveryState(true,
                     auto_mode ? QStringLiteral("Validating recovery phrase for auto scan...")
                               : (external_mode ? QStringLiteral("Validating external recovery phrase...") : QStringLiteral("Validating recovery phrase...")),
                     5);
    QString wif;
    QString xprv;
    QString error;
    const QString effective_wif_mode = external_mode ? wif_mode : QStringLiteral("current");
    if (!mnemonicMaterial(phrase, effective_wif_mode, descriptor_scan_mode ? nullptr : &wif, descriptor_scan_mode ? &xprv : nullptr, &error)) {
        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
        Q_EMIT userMessage(QStringLiteral("Wallet not restored"), error);
        return;
    }

    QVector<QPair<QString, QString>> descriptors;
    if (descriptor_scan_mode) {
        setRecoveryState(true, auto_mode ? QStringLiteral("Preparing common recovery descriptors...") : QStringLiteral("Preparing external recovery descriptor..."), 15);
        QVector<QPair<QString, QString>> path_labels;
        if (auto_mode) {
            path_labels = {
                {QStringLiteral("Coinomi/Ian Coleman Defcoin BIP44 external m/44'/1337'/0'/0/*"), QStringLiteral("m/44'/1337'/0'/0/*")},
                {QStringLiteral("Coinomi/Ian Coleman Defcoin BIP44 change m/44'/1337'/0'/1/*"), QStringLiteral("m/44'/1337'/0'/1/*")},
                {QStringLiteral("Legacy Bitcoin-family BIP44 external m/44'/0'/0'/0/*"), QStringLiteral("m/44'/0'/0'/0/*")},
                {QStringLiteral("Legacy Bitcoin-family BIP44 change m/44'/0'/0'/1/*"), QStringLiteral("m/44'/0'/0'/1/*")},
                {QStringLiteral("Litecoin-family BIP44 external m/44'/2'/0'/0/*"), QStringLiteral("m/44'/2'/0'/0/*")},
                {QStringLiteral("Litecoin-family BIP44 change m/44'/2'/0'/1/*"), QStringLiteral("m/44'/2'/0'/1/*")},
                {QStringLiteral("Legacy BIP32 external chain m/0/*"), QStringLiteral("m/0/*")}
            };
        } else {
            path_labels = {{QStringLiteral("Manual external scan %1").arg(derivation_path.trimmed().isEmpty() ? QStringLiteral("m/44'/1337'/0'/0/*") : derivation_path.trimmed()),
                            derivation_path}};
        }

        for (const auto& item : path_labels) {
            const QString descriptor = descriptorForRecoveryPath(xprv, item.second, &error);
            if (descriptor.isEmpty()) {
                xprv.clear();
                setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                Q_EMIT userMessage(QStringLiteral("Wallet not restored"), error);
                return;
            }
            descriptors.push_back({QStringLiteral("BIP39 recovery: %1").arg(item.first), descriptor});
        }
        xprv.clear();
        if (descriptors.isEmpty()) {
            setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
            Q_EMIT userMessage(QStringLiteral("Wallet not restored"), QStringLiteral("No recovery descriptors were prepared."));
            return;
        }
    }

    QJsonArray create_params;
    create_params << clean_wallet_name
                  << false
                  << true
                  << (encrypt ? QJsonValue(passphrase) : QJsonValue())
                  << false
                  << false
                  << true;

    setRecoveryState(true, QStringLiteral("Creating recovery wallet..."), 25);
    rpcCall(QStringLiteral("createwallet"), create_params, false, [this, clean_wallet_name, wif, descriptors, descriptor_scan_mode, gap_scan_mode, range, encrypt, passphrase](const QJsonValue&, const QString& error) {
        if (!error.isEmpty()) {
            setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
            Q_EMIT userMessage(QStringLiteral("Wallet not restored"), error);
            return;
        }
        m_recovery_lock_after_restore = encrypt;

        const auto continue_restore = [this, clean_wallet_name, wif, descriptors, descriptor_scan_mode, gap_scan_mode, range]() {
            setCurrentWalletInternal(clean_wallet_name);
            if (!descriptor_scan_mode) {
                setRecoveryState(true, QStringLiteral("Setting wallet HD seed from recovery phrase..."), 55);
                rpcCall(QStringLiteral("sethdseed"), {true, wif}, true, [this, clean_wallet_name](const QJsonValue&, const QString& seed_error) {
                    if (!seed_error.isEmpty()) {
                        setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                        Q_EMIT userMessage(QStringLiteral("Wallet not restored"), seed_error);
                        return;
                    }
                    refresh();
                    setRecoveryState(false, QStringLiteral("Recovery complete."), 100);
                    Q_EMIT userMessage(QStringLiteral("Wallet restored"),
                                       QStringLiteral("The wallet was created from the recovery phrase and loaded. Back up the wallet and keep the phrase offline."));
                });
                return;
            }

            if (gap_scan_mode) {
                importRecoveryDescriptorsUntilEmpty(descriptors, std::abs(range));
            } else {
                importRecoveryDescriptorsWithRescan(descriptors, range);
            }
        };

        const auto load_recovery_wallet = [this, clean_wallet_name, continue_restore, encrypt, passphrase]() {
            setRecoveryState(true, QStringLiteral("Loading recovery wallet..."), 30);
            rpcCall(QStringLiteral("loadwallet"), {clean_wallet_name, true}, false, [this, clean_wallet_name, continue_restore, encrypt, passphrase](const QJsonValue&, const QString& load_error) {
                if (load_error.isEmpty() || load_error.contains(QStringLiteral("already loaded"), Qt::CaseInsensitive)) {
                    setCurrentWalletInternal(clean_wallet_name);
                    if (!encrypt) {
                        continue_restore();
                        return;
                    }
                    setRecoveryState(true, QStringLiteral("Unlocking encrypted recovery wallet for import..."), 35);
                    rpcCall(QStringLiteral("walletpassphrase"), {passphrase, 86400}, true, [this, continue_restore](const QJsonValue&, const QString& unlock_error) {
                        if (!unlock_error.isEmpty()) {
                            setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                            Q_EMIT userMessage(QStringLiteral("Wallet not restored"), unlock_error);
                            return;
                        }
                        continue_restore();
                    });
                    return;
                }
                setRecoveryState(false, QStringLiteral("Recovery stopped."), 0);
                Q_EMIT userMessage(QStringLiteral("Wallet not restored"), load_error);
            });
        };

        load_recovery_wallet();
    });
}

QVariantMap NuRpcService::convertCompatibilityEncoding(const QString& text) const
{
    QVariantMap result;
    const QString trimmed = text.trimmed();
    if (trimmed.isEmpty()) {
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("error"), QStringLiteral("Paste an xpub/xprv, dfcp/dfcv, or P2SH address to convert."));
        return result;
    }

    QByteArray payload;
    if (!decodeBase58CheckPayload(trimmed, &payload)) {
        result.insert(QStringLiteral("ok"), false);
        result.insert(QStringLiteral("error"), QStringLiteral("This is not a valid Base58Check Defcoin extended key or P2SH address."));
        return result;
    }

    const QByteArray xpub = bytes({0x04, 0x88, 0xB2, 0x1E});
    const QByteArray xprv = bytes({0x04, 0x88, 0xAD, 0xE4});
    const QByteArray dfcp = bytes({0x02, 0xFA, 0x54, 0xD7});
    const QByteArray dfcv = bytes({0x02, 0xFA, 0x54, 0xAD});

    if (payload.size() == 78 && (hasPrefix(payload, xpub) || hasPrefix(payload, dfcp))) {
        const QByteArray key_body = payload.mid(4);
        result.insert(QStringLiteral("ok"), true);
        result.insert(QStringLiteral("kind"), QStringLiteral("Extended public key"));
        result.insert(QStringLiteral("current"), encodeBase58CheckPayload(xpub + key_body));
        result.insert(QStringLiteral("defcoin"), encodeBase58CheckPayload(dfcp + key_body));
        result.insert(QStringLiteral("note"), QStringLiteral("Nu accepts both xpub and dfcp. dfcp is an alternate Defcoin display/export form."));
        return result;
    }
    if (payload.size() == 78 && (hasPrefix(payload, xprv) || hasPrefix(payload, dfcv))) {
        const QByteArray key_body = payload.mid(4);
        result.insert(QStringLiteral("ok"), true);
        result.insert(QStringLiteral("kind"), QStringLiteral("Extended private key"));
        result.insert(QStringLiteral("current"), encodeBase58CheckPayload(xprv + key_body));
        result.insert(QStringLiteral("defcoin"), encodeBase58CheckPayload(dfcv + key_body));
        result.insert(QStringLiteral("note"), QStringLiteral("Keep private keys secret. Nu accepts both xprv and dfcv; dfcv is an alternate Defcoin display/export form."));
        return result;
    }

    if (payload.size() == 21) {
        const unsigned char version = static_cast<unsigned char>(payload.at(0));
        if (version == 50 || version == 5 || version == 22) {
            const QByteArray hash = payload.mid(1);
            result.insert(QStringLiteral("ok"), true);
            result.insert(QStringLiteral("kind"), QStringLiteral("P2SH address"));
            result.insert(QStringLiteral("canonical"), encodeBase58CheckPayload(bytes({50}) + hash));
            result.insert(QStringLiteral("legacy3"), encodeBase58CheckPayload(bytes({5}) + hash));
            result.insert(QStringLiteral("tool"), encodeBase58CheckPayload(bytes({22}) + hash));
            result.insert(QStringLiteral("note"), version == 50
                ? QStringLiteral("This is already Nu's canonical M... P2SH form. Nu also accepts old 3... and tool 9/A... encodings.")
                : QStringLiteral("Nu accepts this legacy/tool P2SH encoding and shows the canonical M... equivalent for new use."));
            return result;
        }
    }

    result.insert(QStringLiteral("ok"), false);
    result.insert(QStringLiteral("error"), QStringLiteral("Recognized Base58Check data, but it is not an xpub/xprv, dfcp/dfcv, or supported Defcoin P2SH encoding."));
    return result;
}

void NuRpcService::setCurrentWallet(const QString& name)
{
    const QString wallet_name = normalizedWalletListName(name);
    if (!isLikelyLoadableWalletMenuName(wallet_name)) {
        Q_EMIT userMessage(QStringLiteral("Wallet not selected"),
                           QStringLiteral("Choose a wallet directory created by Defcoin Core Nu. Backup .dat copies are intentionally hidden to avoid opening duplicate Berkeley DB files."));
        return;
    }

    if (!m_loaded_wallets.contains(wallet_name)) {
        loadWallet(wallet_name);
        return;
    }

    if (setCurrentWalletInternal(wallet_name)) {
        refreshWallet();
        refreshAddressBook();
    }
}

void NuRpcService::loadWallet(const QString& name)
{
    const QString wallet_name = normalizedWalletListName(name);
    if (!isLikelyLoadableWalletMenuName(wallet_name)) {
        Q_EMIT userMessage(QStringLiteral("Wallet not opened"),
                           QStringLiteral("Choose a wallet directory created by Defcoin Core Nu. Backup .dat copies are intentionally hidden to avoid opening duplicate Berkeley DB files."));
        return;
    }
    if (m_loaded_wallets.contains(wallet_name)) {
        setCurrentWallet(wallet_name);
        return;
    }
    rpcCall(QStringLiteral("loadwallet"), {walletLoadNameFor(wallet_name), true}, false, [this, wallet_name](const QJsonValue&, const QString& error) {
        const bool already_loaded = error.contains(QStringLiteral("already loaded"), Qt::CaseInsensitive);
        if (error.isEmpty()) {
            setCurrentWalletInternal(wallet_name);
            refresh();
        } else if (already_loaded) {
            setCurrentWalletInternal(wallet_name);
            refresh();
        }
        Q_EMIT userMessage(error.isEmpty() || already_loaded ? QStringLiteral("Wallet opened") : QStringLiteral("Wallet not opened"),
                           error.isEmpty() || already_loaded ? QStringLiteral("The wallet is loaded and selected. Existing wallet data was not deleted.")
                                                             : error);
    });
}

void NuRpcService::openWallets(const QVariantList& names)
{
    QStringList queue;
    QString final_wallet;
    for (const QVariant& value : names) {
        const QString wallet_name = normalizedWalletListName(value.toString());
        if (!isLikelyLoadableWalletMenuName(wallet_name)) continue;
        if (!queue.contains(wallet_name)) queue.push_back(wallet_name);
        final_wallet = wallet_name;
    }

    if (queue.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No wallets selected"), QStringLiteral("Select one or more wallet entries first."));
        return;
    }

    if (m_wallet_open_queue_active) {
        for (const QString& wallet_name : queue) {
            if (!m_wallet_open_queue.contains(wallet_name)) m_wallet_open_queue.push_back(wallet_name);
        }
        m_wallet_open_queue_final_wallet = final_wallet;
        Q_EMIT userMessage(QStringLiteral("Wallets queued"), QStringLiteral("The selected wallets were added to the current open queue."));
        return;
    }

    m_wallet_open_queue = queue;
    m_wallet_open_queue_final_wallet = final_wallet;
    m_wallet_open_queue_active = true;
    continueWalletOpenQueue();
}

void NuRpcService::continueWalletOpenQueue()
{
    if (m_wallet_open_queue.isEmpty()) {
        const QString final_wallet = m_wallet_open_queue_final_wallet;
        m_wallet_open_queue_final_wallet.clear();
        m_wallet_open_queue_active = false;
        if (m_loaded_wallets.contains(final_wallet)) {
            setCurrentWalletInternal(final_wallet);
        }
        refresh();
        Q_EMIT userMessage(QStringLiteral("Wallets opened"), QStringLiteral("Selected wallets were opened. The last selected wallet is active."));
        return;
    }

    const QString wallet_name = m_wallet_open_queue.takeFirst();
    if (m_loaded_wallets.contains(wallet_name)) {
        setCurrentWalletInternal(wallet_name);
        QTimer::singleShot(0, this, &NuRpcService::continueWalletOpenQueue);
        return;
    }

    rpcCall(QStringLiteral("loadwallet"), {walletLoadNameFor(wallet_name), true}, false, [this, wallet_name](const QJsonValue&, const QString& error) {
        const bool already_loaded = error.contains(QStringLiteral("already loaded"), Qt::CaseInsensitive);
        if (error.isEmpty() || already_loaded) {
            if (!m_loaded_wallets.contains(wallet_name)) m_loaded_wallets.push_back(wallet_name);
            setCurrentWalletInternal(wallet_name);
            QTimer::singleShot(0, this, &NuRpcService::continueWalletOpenQueue);
            return;
        }

        m_wallet_open_queue.clear();
        m_wallet_open_queue_final_wallet.clear();
        m_wallet_open_queue_active = false;
        refreshWalletList();
        Q_EMIT userMessage(QStringLiteral("Wallet not opened"),
                           QStringLiteral("%1 could not be opened:\n%2").arg(walletDisplayName(wallet_name), error));
    });
}

void NuRpcService::closeWallet(const QString& name)
{
    const QString wallet_name = name.trimmed().isEmpty() ? m_wallet_name : name.trimmed();
    if (!m_wallet_selected && wallet_name.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No wallet loaded"), QStringLiteral("There is no loaded wallet to close."));
        return;
    }
    rpcCall(QStringLiteral("unloadwallet"), {wallet_name, false}, false, [this, wallet_name](const QJsonValue&, const QString& error) {
        if (error.isEmpty()) {
            QStringList remaining = m_loaded_wallets;
            remaining.removeAll(wallet_name);
            m_loaded_wallets = remaining;
            if (m_wallet_selected && m_wallet_name == wallet_name) {
                if (remaining.isEmpty()) {
                    setCurrentWalletInternal(QString(), false);
                } else {
                    setCurrentWalletInternal(remaining.first());
                }
            }
            refresh();
        }
        Q_EMIT userMessage(error.isEmpty() ? QStringLiteral("Wallet closed") : QStringLiteral("Wallet not closed"),
                           error.isEmpty() ? QStringLiteral("The wallet was unloaded from this session. Wallet files and funds were not deleted.") : error);
    });
}

void NuRpcService::closeAllWallets()
{
    if (m_loaded_wallets.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No wallets loaded"), QStringLiteral("There are no loaded wallets to close."));
        return;
    }

    auto remaining = std::make_shared<int>(m_loaded_wallets.size());
    auto errors = std::make_shared<QStringList>();
    const QStringList wallets = m_loaded_wallets;
    for (const QString& wallet_name : wallets) {
        rpcCall(QStringLiteral("unloadwallet"), {wallet_name, false}, false, [this, remaining, errors](const QJsonValue&, const QString& error) {
            if (!error.isEmpty()) errors->push_back(error);
            --(*remaining);
            if (*remaining == 0) {
                m_loaded_wallets.clear();
                setCurrentWalletInternal(QString(), false);
                refresh();
                Q_EMIT userMessage(errors->isEmpty() ? QStringLiteral("Wallets closed") : QStringLiteral("Some wallets were not closed"),
                                   errors->isEmpty() ? QStringLiteral("All loaded wallets were unloaded from this session. Wallet files and funds were not deleted.")
                                                     : errors->join(QStringLiteral("\n")));
            }
        });
    }
}

void NuRpcService::renameWallet(const QString& old_name, const QString& new_name)
{
    const QString wallet_name = old_name.trimmed();
    const QString new_wallet_name = new_name.trimmed();
    if (wallet_name.isEmpty() || wallet_name == QLatin1String("wallet.dat")) {
        Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                           QStringLiteral("Nu does not rename the legacy default wallet.dat from this screen. Back it up and move it manually only if you know exactly why you need to."));
        return;
    }
    if (!isLikelyLoadableWalletMenuName(wallet_name)) {
        Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                           QStringLiteral("Choose a wallet directory created by Defcoin Core Nu. Backup .dat copies and suspicious names are intentionally hidden."));
        return;
    }
    if (new_wallet_name.size() > 128) {
        Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                           QStringLiteral("Wallet names can be up to 128 characters. Shorten the new name before renaming the wallet."));
        return;
    }
    if (!isLikelyCreatableWalletMenuName(new_wallet_name) || new_wallet_name == QLatin1String("wallet.dat")) {
        Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                           QStringLiteral("Enter a new wallet directory name without slashes, colons, control characters, path segments, backup suffixes, copy labels, or .dat filenames."));
        return;
    }

    QString wallet_leaf = wallet_name;
    wallet_leaf.replace(QLatin1Char('\\'), QLatin1Char('/'));
    if (wallet_leaf.startsWith(QStringLiteral("wallets/"))) {
        wallet_leaf = wallet_leaf.mid(QStringLiteral("wallets/").size());
    }
    if (wallet_leaf == new_wallet_name) {
        Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                           QStringLiteral("Enter a different wallet name before renaming."));
        return;
    }
    if (m_available_wallets.contains(new_wallet_name) || m_loaded_wallets.contains(new_wallet_name)) {
        Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                           QStringLiteral("A wallet with that name already exists. Choose a unique wallet name."));
        return;
    }

    const bool was_loaded = m_loaded_wallets.contains(wallet_name);
    const bool was_selected = m_wallet_selected && m_wallet_name == wallet_name;

    auto move_wallet = [this, wallet_name, new_wallet_name, was_loaded, was_selected]() {
        const QDir data_dir(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir);
        QString normalized = wallet_name;
        normalized.replace(QLatin1Char('\\'), QLatin1Char('/'));
        const QString leaf = normalized.startsWith(QStringLiteral("wallets/"))
            ? normalized.mid(QStringLiteral("wallets/").size())
            : normalized;

        QStringList candidates;
        candidates << data_dir.filePath(normalized);
        if (!normalized.startsWith(QStringLiteral("wallets/"))) {
            candidates << data_dir.filePath(QStringLiteral("wallets/") + leaf);
        }

        QString source_path;
        for (const QString& candidate : candidates) {
            if (QFileInfo::exists(candidate)) {
                source_path = QFileInfo(candidate).absoluteFilePath();
                break;
            }
        }
        if (source_path.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                               QStringLiteral("Nu could not find the wallet files for '%1'. Refresh the wallet list and check the Defcoin data directory.").arg(walletDisplayName(wallet_name)));
            refresh();
            return;
        }

        const QFileInfo source_info(source_path);
        const QString destination = QDir(source_info.absolutePath()).filePath(new_wallet_name);
        if (QFileInfo::exists(destination)) {
            Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                               QStringLiteral("A file or folder named '%1' already exists beside the selected wallet. Choose a unique wallet name.").arg(new_wallet_name));
            return;
        }

        bool moved = false;
        if (source_info.isDir()) {
            moved = QDir().rename(source_path, destination);
        } else {
            moved = QFile::rename(source_path, destination);
        }
        if (!moved) {
            Q_EMIT userMessage(QStringLiteral("Wallet not renamed"),
                               QStringLiteral("Nu could not rename '%1'. Check file permissions and make sure the wallet is closed.").arg(walletDisplayName(wallet_name)));
            return;
        }

        pruneCoreWalletAutoloadSettings({wallet_name});
        m_loaded_wallets.removeAll(wallet_name);
        m_available_wallets.removeAll(wallet_name);
        if (was_selected) setCurrentWalletInternal(QString(), false);

        if (was_loaded || was_selected) {
            rpcCall(QStringLiteral("loadwallet"), {new_wallet_name, true}, false, [this, wallet_name, new_wallet_name](const QJsonValue&, const QString& load_error) {
                const bool already_loaded = load_error.contains(QStringLiteral("already loaded"), Qt::CaseInsensitive);
                if (load_error.isEmpty() || already_loaded) {
                    setCurrentWalletInternal(new_wallet_name);
                    refresh();
                    Q_EMIT userMessage(QStringLiteral("Wallet renamed"),
                                       QStringLiteral("'%1' was renamed to '%2' and loaded.").arg(walletDisplayName(wallet_name), walletDisplayName(new_wallet_name)));
                    return;
                }
                refresh();
                Q_EMIT userMessage(QStringLiteral("Wallet renamed but not loaded"),
                                   QStringLiteral("'%1' was renamed to '%2', but Nu could not reload it automatically:\n%3").arg(walletDisplayName(wallet_name), walletDisplayName(new_wallet_name), load_error));
            });
            return;
        }

        refresh();
        Q_EMIT userMessage(QStringLiteral("Wallet renamed"),
                           QStringLiteral("'%1' was renamed to '%2'.").arg(walletDisplayName(wallet_name), walletDisplayName(new_wallet_name)));
    };

    if (was_loaded) {
        rpcCall(QStringLiteral("unloadwallet"), {wallet_name, false}, false, [this, wallet_name, move_wallet](const QJsonValue&, const QString& error) {
            if (!error.isEmpty() && !error.contains(QStringLiteral("not loaded"), Qt::CaseInsensitive)) {
                Q_EMIT userMessage(QStringLiteral("Wallet not renamed"), error);
                return;
            }
            m_loaded_wallets.removeAll(wallet_name);
            if (m_wallet_selected && m_wallet_name == wallet_name) setCurrentWalletInternal(QString(), false);
            move_wallet();
        });
        return;
    }

    move_wallet();
}

void NuRpcService::deleteWallet(const QString& name)
{
    const QString wallet_name = name.trimmed();
    if (wallet_name.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Wallet not deleted"),
                           QStringLiteral("Nu does not delete the legacy default wallet.dat from this screen. Back it up first and remove it manually from the Defcoin data directory if you really intend to retire it."));
        return;
    }
    if (!isLikelyLoadableWalletMenuName(wallet_name)) {
        Q_EMIT userMessage(QStringLiteral("Wallet not deleted"),
                           QStringLiteral("Choose a wallet directory created by Defcoin Core Nu. Backup .dat copies and suspicious names are intentionally hidden."));
        return;
    }

    auto move_wallet = [this, wallet_name]() {
        const QDir data_dir(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir);
        QString normalized = wallet_name;
        normalized.replace(QLatin1Char('\\'), QLatin1Char('/'));
        const QString leaf = normalized.startsWith(QStringLiteral("wallets/"))
            ? normalized.mid(QStringLiteral("wallets/").size())
            : normalized;

        QStringList candidates;
        candidates << data_dir.filePath(normalized);
        if (!normalized.startsWith(QStringLiteral("wallets/"))) {
            candidates << data_dir.filePath(QStringLiteral("wallets/") + leaf);
        }

        QString source_path;
        for (const QString& candidate : candidates) {
            if (QFileInfo::exists(candidate)) {
                source_path = QFileInfo(candidate).absoluteFilePath();
                break;
            }
        }
        if (source_path.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Wallet not deleted"),
                               QStringLiteral("Nu could not find the wallet files for '%1'. Refresh the wallet list and check the Defcoin data directory.").arg(walletDisplayName(wallet_name)));
            refresh();
            return;
        }

        const QString deleted_root = data_dir.filePath(QStringLiteral("Deleted Wallets"));
        QDir().mkpath(deleted_root);
        QString safe_leaf = leaf;
        safe_leaf.replace(QRegularExpression(QStringLiteral(R"([^A-Za-z0-9._ -])")), QStringLiteral("_"));
        if (safe_leaf.trimmed().isEmpty()) safe_leaf = QStringLiteral("wallet");
        const QString stamp = QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyyMMdd-HHmmss"));
        QString destination = QDir(deleted_root).filePath(QStringLiteral("%1-deleted-%2").arg(safe_leaf, stamp));
        int suffix = 2;
        while (QFileInfo::exists(destination)) {
            destination = QDir(deleted_root).filePath(QStringLiteral("%1-deleted-%2-%3").arg(safe_leaf, stamp).arg(suffix++));
        }

        bool moved = false;
        const QFileInfo source_info(source_path);
        if (source_info.isDir()) {
            moved = QDir().rename(source_path, destination);
        } else {
            moved = QFile::rename(source_path, destination);
        }
        if (!moved) {
            Q_EMIT userMessage(QStringLiteral("Wallet not deleted"),
                               QStringLiteral("Nu could not move '%1' into Deleted Wallets. Check file permissions and make sure the wallet is closed.").arg(walletDisplayName(wallet_name)));
            return;
        }

        pruneCoreWalletAutoloadSettings({wallet_name});
        m_loaded_wallets.removeAll(wallet_name);
        m_available_wallets.removeAll(wallet_name);
        if (m_wallet_selected && m_wallet_name == wallet_name) {
            setCurrentWalletInternal(m_loaded_wallets.isEmpty() ? QString() : m_loaded_wallets.first(), !m_loaded_wallets.isEmpty());
        }
        refresh();
        Q_EMIT userMessage(QStringLiteral("Wallet moved to Deleted Wallets"),
                           QStringLiteral("'%1' was closed if needed and moved to:\n%2\n\nThis is a reversible cleanup move, not a secure wipe.").arg(walletDisplayName(wallet_name), QDir::toNativeSeparators(destination)));
    };

    if (m_loaded_wallets.contains(wallet_name)) {
        rpcCall(QStringLiteral("unloadwallet"), {wallet_name, false}, false, [this, wallet_name, move_wallet](const QJsonValue&, const QString& error) {
            if (!error.isEmpty() && !error.contains(QStringLiteral("not loaded"), Qt::CaseInsensitive)) {
                Q_EMIT userMessage(QStringLiteral("Wallet not deleted"), error);
                return;
            }
            m_loaded_wallets.removeAll(wallet_name);
            if (m_wallet_selected && m_wallet_name == wallet_name) setCurrentWalletInternal(QString(), false);
            move_wallet();
        });
        return;
    }

    move_wallet();
}

void NuRpcService::encryptWallet(const QString& passphrase)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Wallet not encrypted"))) return;
    if (m_wallet_encrypted) {
        Q_EMIT userMessage(QStringLiteral("Wallet already encrypted"),
                           QStringLiteral("This wallet already has a passphrase. Use Change passphrase to update it."));
        return;
    }
    if (passphrase.length() < 8) {
        Q_EMIT userMessage(QStringLiteral("Wallet not encrypted"), QStringLiteral("Enter a passphrase of at least 8 characters."));
        return;
    }
    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("encryptwallet"), {passphrase}, true, [this, wallet_name](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        Q_EMIT userMessage(error.isEmpty() ? QStringLiteral("Wallet encrypted") : QStringLiteral("Wallet encryption failed"),
                           error.isEmpty() ? result.toString(QStringLiteral("Wallet encrypted. Close and reopen the backend before spending.")) : error);
        refreshWallet();
    });
}

void NuRpcService::changeWalletPassphrase(const QString& old_passphrase, const QString& new_passphrase)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Passphrase not changed"))) return;
    if (!m_wallet_encrypted) {
        Q_EMIT userMessage(QStringLiteral("Passphrase not changed"),
                           QStringLiteral("This wallet is not encrypted yet. Use Encrypt wallet to create the first wallet passphrase."));
        return;
    }
    if (old_passphrase.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Passphrase not changed"), QStringLiteral("Enter the current wallet passphrase."));
        return;
    }
    if (new_passphrase.length() < 8) {
        Q_EMIT userMessage(QStringLiteral("Passphrase not changed"), QStringLiteral("Enter a new passphrase of at least 8 characters."));
        return;
    }
    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("walletpassphrasechange"), {old_passphrase, new_passphrase}, true, [this, wallet_name](const QJsonValue&, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        QString message = error;
        if (message.contains(QStringLiteral("unencrypted wallet"), Qt::CaseInsensitive)) {
            message = QStringLiteral("This wallet is not encrypted yet. Use Encrypt wallet to create the first wallet passphrase.");
        }
        Q_EMIT userMessage(error.isEmpty() ? QStringLiteral("Passphrase changed") : QStringLiteral("Passphrase change failed"),
                           error.isEmpty() ? QStringLiteral("The wallet passphrase was changed.") : message);
    });
}

void NuRpcService::signMessage(const QString& address, const QString& message)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Message not signed"))) return;
    if (address.trimmed().isEmpty() || message.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Message not signed"), QStringLiteral("Enter an address and message."));
        return;
    }
    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("signmessage"), {address.trimmed(), message}, true, [this, wallet_name](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Message signing failed"), error);
            return;
        }
        const QString signature = result.toString();
        copyText(signature);
        Q_EMIT userMessage(QStringLiteral("Message signed"), QStringLiteral("Signature copied to clipboard:\n%1").arg(signature));
    });
}

void NuRpcService::verifyMessage(const QString& address, const QString& signature, const QString& message)
{
    if (address.trimmed().isEmpty() || signature.trimmed().isEmpty() || message.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Message not verified"), QStringLiteral("Enter an address, signature, and message."));
        return;
    }
    rpcCall(QStringLiteral("verifymessage"), {address.trimmed(), signature.trimmed(), message}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Message verification failed"), error);
            return;
        }
        Q_EMIT userMessage(QStringLiteral("Message verification"), result.toBool() ? QStringLiteral("Signature is valid.") : QStringLiteral("Signature is not valid."));
    });
}

void NuRpcService::openDebugLog()
{
    const QString path = debugLogPath();
    if (!QFileInfo::exists(path)) {
        Q_EMIT userMessage(QStringLiteral("Debug log not found"),
                           QStringLiteral("No debug.log file was found at:\n%1").arg(path));
        return;
    }
    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(path))) {
        Q_EMIT userMessage(QStringLiteral("Debug log not opened"),
                           QStringLiteral("The operating system did not open:\n%1").arg(path));
    }
}

void NuRpcService::saveLaunchLog(const QString& text)
{
    const QString clean = text.left(4 * 1024 * 1024);
    if (clean.trimmed().isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Launch log not saved"), QStringLiteral("There are no visible launch log lines to save."));
        return;
    }

    QString dir_path = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (dir_path.isEmpty()) dir_path = QDir::homePath();
    QDir dir(dir_path);
    const QString file_name = QStringLiteral("Defcoin-Core-Nu-launch-log-%1.txt")
        .arg(QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss")));
    const QString path = dir.filePath(file_name);
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        Q_EMIT userMessage(QStringLiteral("Launch log not saved"), file.errorString());
        return;
    }
    QTextStream out(&file);
    out << "Shown line\tdebug.log line\tMessage\n";
    const QRegularExpression numbered_line(QStringLiteral(R"(^\s*(\d+)\s+\x{2502}\s+([-\d]+)\s+\x{2502}\s?(.*)$)"));
    const QStringList lines = clean.split(QLatin1Char('\n'));
    for (const QString& line : lines) {
        if (line.isEmpty()) continue;
        const QRegularExpressionMatch match = numbered_line.match(line);
        if (match.hasMatch()) {
            QString message = match.captured(3);
            message.replace(QLatin1Char('\t'), QStringLiteral("    "));
            out << match.captured(1) << '\t' << match.captured(2) << '\t' << message << '\n';
        } else {
            QString message = line;
            message.replace(QLatin1Char('\t'), QStringLiteral("    "));
            out << '\t' << '\t' << message << '\n';
        }
    }
    if (!file.commit()) {
        Q_EMIT userMessage(QStringLiteral("Launch log not saved"), file.errorString());
        return;
    }
    Q_EMIT userMessage(QStringLiteral("Launch log saved"), QStringLiteral("Saved to:\n%1").arg(path));
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void NuRpcService::requestTransactionDetails(const QString& txid)
{
    if (!ensureCurrentWalletSelected(QStringLiteral("Transaction details unavailable"))) return;
    const QString clean_txid = txid.trimmed();
    if (clean_txid.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("Transaction details unavailable"), QStringLiteral("This row does not include a transaction ID."));
        return;
    }

    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("gettransaction"), {clean_txid, true}, true, [this, wallet_name, clean_txid](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Transaction details unavailable"), error);
            return;
        }
        const QJsonObject tx = result.toObject();
        const QJsonArray details = tx.value(QStringLiteral("details")).toArray();
        QStringList addresses;
        QString label;
        QString category;
        for (const QJsonValue& value : details) {
            const QJsonObject detail = value.toObject();
            if (label.isEmpty()) label = detail.value(QStringLiteral("label")).toString();
            if (category.isEmpty()) category = detail.value(QStringLiteral("category")).toString();
            const QString candidate = detail.value(QStringLiteral("address")).toString().trimmed();
            if (isLikelyBase58AddressText(candidate) && !addresses.contains(candidate)) addresses.push_back(candidate);
        }
        const QJsonObject decoded = tx.value(QStringLiteral("decoded")).toObject();
        const QJsonArray decoded_vout = decoded.value(QStringLiteral("vout")).toArray();
        for (const QJsonValue& value : decoded_vout) {
            const QJsonObject out = value.toObject();
            const QStringList output_addresses = recognizedExplorerAddresses(explorerOutputAddresses(out.value(QStringLiteral("scriptPubKey")).toObject()));
            for (const QString& candidate : output_addresses) {
                if (!addresses.contains(candidate)) addresses.push_back(candidate);
            }
        }

        auto localTime = [](const QJsonValue& value) {
            const qint64 seconds = value.toVariant().toLongLong();
            return seconds > 0 ? QDateTime::fromSecsSinceEpoch(seconds).toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss t")) : QStringLiteral("N/A");
        };
        auto rowHtml = [](const QString& key, const QString& value) {
            return QStringLiteral("<tr><th>%1</th><td>%2</td></tr>")
                .arg(key.toHtmlEscaped(), value.toHtmlEscaped());
        };
        auto rowHtmlRaw = [](const QString& key, const QString& value_html) {
            return QStringLiteral("<tr><th>%1</th><td>%2</td></tr>")
                .arg(key.toHtmlEscaped(), value_html);
        };

        QString html = QStringLiteral("<h2>Transaction details</h2><table>");
        html += rowHtml(QStringLiteral("Status"), tx.value(QStringLiteral("confirmations")).toInt() > 0 ? QStringLiteral("Confirmed") : QStringLiteral("Unconfirmed"));
        html += rowHtml(QStringLiteral("Confirmations"), QString::number(tx.value(QStringLiteral("confirmations")).toInt()));
        html += rowHtml(QStringLiteral("Date"), localTime(tx.value(QStringLiteral("time"))));
        html += rowHtml(QStringLiteral("Received by node"), localTime(tx.value(QStringLiteral("timereceived"))));
        if (!category.isEmpty()) html += rowHtml(QStringLiteral("Type"), category.left(1).toUpper() + category.mid(1));
        if (!label.isEmpty()) html += rowHtml(QStringLiteral("Label"), label);
        if (!addresses.isEmpty()) html += rowHtmlRaw(addresses.size() == 1 ? QStringLiteral("Address") : QStringLiteral("Addresses"), explorerAddressLinksHtml(addresses));
        html += rowHtml(QStringLiteral("Amount"), QString::number(tx.value(QStringLiteral("amount")).toDouble(), 'f', 8) + QStringLiteral(" DFC"));
        if (tx.contains(QStringLiteral("fee"))) {
            html += rowHtml(QStringLiteral("Fee"), QString::number(tx.value(QStringLiteral("fee")).toDouble(), 'f', 8) + QStringLiteral(" DFC"));
        }
        html += rowHtml(QStringLiteral("Transaction ID"), clean_txid);
        if (tx.contains(QStringLiteral("blockhash"))) html += rowHtml(QStringLiteral("Block hash"), tx.value(QStringLiteral("blockhash")).toString());
        html += QStringLiteral("</table>");

        if (usingInternalExplorer()) {
            html += QStringLiteral("<h3>Internal explorer</h3><p>Open cached SQLite-backed explorer views for:</p><ul>");
            html += QStringLiteral("<li>Transaction ID: <a href=\"nu://transaction/%1\" title=\"Open internal explorer window\">%2</a></li>")
                .arg(QString::fromLatin1(QUrl::toPercentEncoding(clean_txid)).toHtmlEscaped(), clean_txid.toHtmlEscaped());
            for (const QString& address : addresses) {
                html += QStringLiteral("<li>Wallet address: <a href=\"nu://address/%1\" title=\"Open internal explorer window\">%2</a></li>")
                    .arg(QString::fromLatin1(QUrl::toPercentEncoding(address)).toHtmlEscaped(), address.toHtmlEscaped());
            }
            html += QStringLiteral("</ul>");
        }

        const QString tx_url = explorerUrlForTransaction(clean_txid);
        QList<QPair<QString, QString>> address_links;
        for (const QString& address : addresses) {
            const QString address_url = explorerUrlForAddress(address);
            if (!address_url.isEmpty()) address_links.push_back(qMakePair(address_url, address));
        }
        if (!tx_url.isEmpty() || !address_links.isEmpty()) {
            const QString host = QUrl(m_third_party_tx_url, QUrl::StrictMode).host();
            html += QStringLiteral("<h3>Explorer links</h3><p>Use %1 block explorer to open:</p><ul>").arg(host.toHtmlEscaped());
            if (!tx_url.isEmpty()) {
                html += QStringLiteral("<li>Transaction ID: <a href=\"%1\" title=\"Open %1\">%2</a></li>")
                    .arg(tx_url.toHtmlEscaped(), clean_txid.toHtmlEscaped());
            }
            for (const QPair<QString, QString>& link : address_links) {
                html += QStringLiteral("<li>Wallet address: <a href=\"%1\" title=\"Open %1\">%2</a></li>")
                    .arg(link.first.toHtmlEscaped(), link.second.toHtmlEscaped());
            }
            html += QStringLiteral("</ul>");
        }

        html += QStringLiteral("<h3>Backend JSON</h3><pre>%1</pre>")
            .arg(QString::fromUtf8(QJsonDocument(tx).toJson(QJsonDocument::Indented)).toHtmlEscaped());
        Q_EMIT transactionDetailsReady(QStringLiteral("Transaction details"), html);
    });
}

QString NuRpcService::debugLogPath() const
{
    const QDir data_dir(m_data_dir.isEmpty() ? defaultDataDir() : m_data_dir);
    return data_dir.filePath(QStringLiteral("debug.log"));
}

void NuRpcService::stopHelperProcesses()
{
    m_stopping_helper_processes = true;

    const QList<int> lookup_ids = m_host_lookup_ids.values();
    for (int lookup_id : lookup_ids) {
        QHostInfo::abortHostLookup(lookup_id);
    }
    m_host_lookup_ids.clear();

    QSet<QProcess*> process_set = m_helper_processes;
    const QList<QProcess*> child_processes = findChildren<QProcess*>();
    for (QProcess* process : child_processes) process_set.insert(process);
    const QList<QProcess*> processes = process_set.values();
    for (QProcess* process : processes) {
        if (!process || process == m_backend_process || process == m_miner_process) continue;
        if (process->state() == QProcess::NotRunning) continue;
        process->terminate();
        if (!process->waitForFinished(150)) {
            process->kill();
            process->waitForFinished(500);
        }
    }
    m_helper_processes.clear();
}

void NuRpcService::stopOwnedBackend()
{
    if (!m_backend_started_by_nu || !qEnvironmentVariableIsEmpty("DEFCOIN_NU_KEEP_BACKEND_RUNNING")) {
        return;
    }

    bool stop_requested = false;
    if (m_data_dir.isEmpty()) m_data_dir = defaultDataDir();
    readDefcoinConf(QDir(m_data_dir).filePath(QStringLiteral("defcoin.conf")));
    if ((!m_rpc_user.isEmpty() && !m_rpc_password.isEmpty()) || readCookie()) {
        QNetworkAccessManager manager;
        QNetworkRequest request(rpcUrl(false));
        request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
        const QByteArray auth = QStringLiteral("%1:%2").arg(m_rpc_user, m_rpc_password).toUtf8().toBase64();
        request.setRawHeader("Authorization", "Basic " + auth);

        QJsonObject request_obj;
        request_obj.insert(QStringLiteral("jsonrpc"), QStringLiteral("1.0"));
        request_obj.insert(QStringLiteral("id"), QStringLiteral("nu-shutdown"));
        request_obj.insert(QStringLiteral("method"), QStringLiteral("stop"));
        request_obj.insert(QStringLiteral("params"), QJsonArray());

        QEventLoop loop;
        QTimer timeout;
        timeout.setSingleShot(true);
        QNetworkReply* reply = manager.post(request, QJsonDocument(request_obj).toJson(QJsonDocument::Compact));
        QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
        QObject::connect(&timeout, &QTimer::timeout, &loop, &QEventLoop::quit);
        timeout.start(2500);
        loop.exec();
        stop_requested = reply->isFinished() && reply->error() == QNetworkReply::NoError;
        reply->deleteLater();
    }

    if (m_backend_process && m_backend_process->state() != QProcess::NotRunning) {
        if (!stop_requested) m_backend_process->terminate();
        if (!m_backend_process->waitForFinished(BACKEND_GRACEFUL_SHUTDOWN_MS)) {
            appendDebugLogLineFromNu(QStringLiteral("Nu shutdown: backend did not exit after %1 seconds; forcing process termination.")
                .arg(BACKEND_GRACEFUL_SHUTDOWN_MS / 1000));
            m_backend_process->kill();
            m_backend_process->waitForFinished(3000);
        }
    }

    m_backend_started_by_nu = false;
    m_backend_pid = 0;
}

QString NuRpcService::helpManualPath(const QString& page) const
{
    QString clean_page = QFileInfo(page.trimmed().isEmpty() ? QStringLiteral("index.html") : page.trimmed()).fileName();
    if (clean_page.isEmpty()) clean_page = QStringLiteral("index.html");

#if defined(Q_OS_MACOS)
    return QDir(QCoreApplication::applicationDirPath()).filePath(
        QStringLiteral("../Resources/DefcoinCoreNu.help/Contents/Resources/en.lproj/%1").arg(clean_page));
#else
    return QDir(QCoreApplication::applicationDirPath()).filePath(
        QStringLiteral("nu/help/DefcoinCoreNu.help/Contents/Resources/en.lproj/%1").arg(clean_page));
#endif
}

QString NuRpcService::helpManualHtml(const QString& page) const
{
    const QString path = helpManualPath(page);
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QStringLiteral("<h1>Help not found</h1><p>The Defcoin Core Nu help file was not found at:<br><code>%1</code></p>")
            .arg(path.toHtmlEscaped());
    }
    QString html = QString::fromUtf8(file.readAll());
#if defined(Q_OS_WIN)
    // Qt Quick TextEdit supports a useful but limited HTML subset and may ignore
    // some stylesheet paragraph margins. Keep the shipped HTML standards-based,
    // then add conservative explicit spacing for the in-app Windows reader.
    html.replace(QRegularExpression(QStringLiteral("(<h2\\b)")),
                 QStringLiteral("<br><br>\\1"));
    html.replace(QRegularExpression(QStringLiteral("(<h3\\b)")),
                 QStringLiteral("<br>\\1"));
    html.replace(QRegularExpression(QStringLiteral("</p>")),
                 QStringLiteral("</p><br>"));
    html.replace(QRegularExpression(QStringLiteral("</ul>")),
                 QStringLiteral("</ul><br>"));
    html.replace(QRegularExpression(QStringLiteral("</ol>")),
                 QStringLiteral("</ol><br>"));
#endif
    return html;
}

void NuRpcService::openHelpManual(const QString& page)
{
    const QString path = helpManualPath(page);
    if (!QFileInfo::exists(path)) {
        Q_EMIT userMessage(QStringLiteral("Help not found"),
                           QStringLiteral("The Defcoin Core Nu help file was not found at:\n%1").arg(path));
        return;
    }

#if defined(Q_OS_MACOS)
    const QString help_book = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("../Resources/DefcoinCoreNu.help"));
    if (QFileInfo::exists(help_book) && OpenDefcoinNuHelpBook(page)) {
        return;
    }
#elif defined(Q_OS_WIN)
    Q_EMIT userMessage(QStringLiteral("Open Help"),
                       QStringLiteral("Use the in-app Help window from the Help menu. The Windows build ships help files with the app instead of using CHM."));
    return;
#endif

    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(path))) {
        Q_EMIT userMessage(QStringLiteral("Help not opened"),
                           QStringLiteral("The operating system did not open:\n%1").arg(path));
    }
}

void NuRpcService::exportTransactionsCsv()
{
    const QString path = QFileDialog::getSaveFileName(nullptr, QStringLiteral("Export Transactions"), QDir(realHomePath()).filePath(QStringLiteral("defcoin-transactions.csv")), QStringLiteral("CSV files (*.csv)"));
    if (path.isEmpty()) return;

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        Q_EMIT userMessage(QStringLiteral("Export failed"), file.errorString());
        return;
    }
    QTextStream out(&file);
    out << "Date,Type,Label,Amount\n";
    for (const QVariant& row_value : m_recent_transactions) {
        QVariantList fields = tableRowCells(row_value);
        if (!fields.isEmpty() && fields.first().toString().isEmpty()) fields.removeFirst();
        QStringList escaped;
        for (const QVariant& field : fields) {
            QString text = field.toString();
            text.replace("\"", "\"\"");
            escaped.push_back("\"" + text + "\"");
        }
        out << escaped.join(',') << '\n';
    }
    Q_EMIT userMessage(QStringLiteral("Export complete"), QStringLiteral("The transaction CSV was written successfully."));
}

void NuRpcService::exportTrafficCsv()
{
    const QString path = QFileDialog::getSaveFileName(nullptr, QStringLiteral("Export Network Traffic"), QDir(realHomePath()).filePath(QStringLiteral("defcoin-network-traffic.csv")), QStringLiteral("CSV files (*.csv)"));
    if (path.isEmpty()) return;

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        Q_EMIT userMessage(QStringLiteral("Export failed"), file.errorString());
        return;
    }
    QTextStream out(&file);
    out << "Seconds,Local Time,Average received bytes per second,Average sent bytes per second\n";
    for (const QVariant& point_value : m_traffic_samples) {
        const QVariantMap point = point_value.toMap();
        out << point.value(QStringLiteral("seconds")).toDouble() << ','
            << '"' << QDateTime::fromMSecsSinceEpoch(point.value(QStringLiteral("timestampMs")).toLongLong()).toLocalTime().toString(Qt::ISODate) << '"' << ','
            << point.value(QStringLiteral("received")).toDouble() << ','
            << point.value(QStringLiteral("sent")).toDouble() << '\n';
    }
    Q_EMIT userMessage(QStringLiteral("Export complete"), QStringLiteral("The network traffic CSV was written successfully."));
}

void NuRpcService::exportForensicsIrregularMessagesCsv()
{
    const QString path = QFileDialog::getSaveFileName(nullptr,
        QStringLiteral("Export Irregular Messages"),
        QDir(realHomePath()).filePath(QStringLiteral("defcoin-irregular-messages.csv")),
        QStringLiteral("CSV files (*.csv)"));
    if (path.isEmpty()) return;

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        Q_EMIT userMessage(QStringLiteral("Export failed"), file.errorString());
        return;
    }

    auto csv_escape = [](QString text) {
        text.replace(QLatin1Char('"'), QStringLiteral("\"\""));
        return QStringLiteral("\"%1\"").arg(text);
    };

    QTextStream out(&file);
    out << "Block Height,Transaction ID,BIP141 Definition,Burned Defcoin Amount,Decoded Text Message,Flag,Script Prefix 4,Payload Prefix 4,Script Hex,Payload Hex\n";
    for (const QVariant& row_value : m_forensics_irregular_messages) {
        const QVariantList cells = tableRowCells(row_value);
        const QVariantMap meta = row_value.toMap().value(QStringLiteral("meta")).toMap();
        QStringList escaped;
        for (int i = 0; i < 6; ++i) {
            escaped << csv_escape(i < cells.size() ? cells.at(i).toString() : QString());
        }
        escaped << csv_escape(meta.value(QStringLiteral("scriptPrefix4")).toString())
                << csv_escape(meta.value(QStringLiteral("payloadPrefix4")).toString())
                << csv_escape(meta.value(QStringLiteral("scriptHex")).toString())
                << csv_escape(meta.value(QStringLiteral("payloadHex")).toString());
        out << escaped.join(QLatin1Char(',')) << '\n';
    }
    Q_EMIT userMessage(QStringLiteral("Export complete"), QStringLiteral("The irregular messages CSV was written successfully."));
}

void NuRpcService::loadPsbtPayload(const QByteArray& payload, const QString& source)
{
    QByteArray trimmed = payload.trimmed();
    if (trimmed.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("PSBT not loaded"), QStringLiteral("No PSBT data was found in %1.").arg(source));
        return;
    }

    const QString text = QString::fromLatin1(trimmed);
    const bool text_looks_base64 = QRegularExpression(QStringLiteral(R"(^[A-Za-z0-9+/=\r\n\t ]+$)")).match(text).hasMatch();
    QString psbt = text_looks_base64 ? text : QString::fromLatin1(trimmed.toBase64());
    psbt.remove(QRegularExpression(QStringLiteral(R"(\s+)")));
    if (psbt.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("PSBT not loaded"), QStringLiteral("The PSBT data from %1 could not be normalized.").arg(source));
        return;
    }

    m_current_psbt = psbt;
    m_current_psbt_final_hex.clear();
    m_current_psbt_summary = QStringLiteral("Loaded PSBT from %1. Analyzing...").arg(source);
    Q_EMIT psbtChanged();
    analyzeCurrentPsbt(source);
}

void NuRpcService::analyzeCurrentPsbt(const QString& source)
{
    if (m_current_psbt.isEmpty()) return;
    rpcCall(QStringLiteral("analyzepsbt"), {m_current_psbt}, false, [this, source](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) {
            m_current_psbt_summary = QStringLiteral("Loaded PSBT from %1, but analyzepsbt failed:\n%2").arg(source, error);
            Q_EMIT psbtChanged();
            Q_EMIT userMessage(QStringLiteral("PSBT loaded with warning"), m_current_psbt_summary);
            return;
        }
        const QString json = QString::fromUtf8(QJsonDocument(result.toObject()).toJson(QJsonDocument::Indented)).trimmed();
        m_current_psbt_summary = QStringLiteral("Loaded PSBT from %1.\n\n%2").arg(source, json);
        Q_EMIT psbtChanged();
        Q_EMIT userMessage(QStringLiteral("PSBT loaded"), QStringLiteral("Review the PSBT summary in Send > Advanced send options."));
    });
}

void NuRpcService::loadPsbtFromFile()
{
    const QString path = QFileDialog::getOpenFileName(nullptr,
                                                      QStringLiteral("Load PSBT"),
                                                      realHomePath(),
                                                      QStringLiteral("PSBT files (*.psbt *.txt);;All files (*)"));
    if (path.isEmpty()) return;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        Q_EMIT userMessage(QStringLiteral("PSBT not loaded"), file.errorString());
        return;
    }
    loadPsbtPayload(file.readAll(), QFileInfo(path).fileName());
}

void NuRpcService::loadPsbtFromClipboard()
{
    const QString text = QApplication::clipboard()->text().trimmed();
    if (text.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("PSBT not loaded"), QStringLiteral("The clipboard does not contain text PSBT data."));
        return;
    }
    loadPsbtPayload(text.toLatin1(), QStringLiteral("clipboard"));
}

void NuRpcService::signCurrentPsbt()
{
    if (m_current_psbt.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No PSBT loaded"), QStringLiteral("Load a PSBT before signing."));
        return;
    }
    if (!ensureCurrentWalletSelected(QStringLiteral("PSBT signing failed"))) return;
    const QString wallet_name = m_wallet_name;
    rpcCall(QStringLiteral("walletprocesspsbt"), {m_current_psbt, true}, true, [this, wallet_name](const QJsonValue& result, const QString& error) {
        if (wallet_name != m_wallet_name) return;
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("PSBT signing failed"), error);
            return;
        }
        const QJsonObject object = result.toObject();
        const QString processed = object.value(QStringLiteral("psbt")).toString();
        if (!processed.isEmpty()) m_current_psbt = processed;
        m_current_psbt_final_hex.clear();
        const bool complete = object.value(QStringLiteral("complete")).toBool();
        m_current_psbt_summary = QStringLiteral("Wallet processed PSBT. Complete: %1\n\n%2")
            .arg(complete ? QStringLiteral("yes") : QStringLiteral("no"),
                 QString::fromUtf8(QJsonDocument(object).toJson(QJsonDocument::Indented)).trimmed());
        Q_EMIT psbtChanged();
        analyzeCurrentPsbt(QStringLiteral("walletprocesspsbt"));
    });
}

void NuRpcService::finalizeCurrentPsbt()
{
    if (m_current_psbt.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No PSBT loaded"), QStringLiteral("Load a PSBT before finalizing."));
        return;
    }
    rpcCall(QStringLiteral("finalizepsbt"), {m_current_psbt}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("PSBT finalization failed"), error);
            return;
        }
        const QJsonObject object = result.toObject();
        const bool complete = object.value(QStringLiteral("complete")).toBool();
        m_current_psbt_final_hex = object.value(QStringLiteral("hex")).toString();
        const QString updated_psbt = object.value(QStringLiteral("psbt")).toString();
        if (!updated_psbt.isEmpty()) m_current_psbt = updated_psbt;
        m_current_psbt_summary = QStringLiteral("Finalize PSBT result. Complete: %1\n\n%2")
            .arg(complete ? QStringLiteral("yes") : QStringLiteral("no"),
                 QString::fromUtf8(QJsonDocument(object).toJson(QJsonDocument::Indented)).trimmed());
        Q_EMIT psbtChanged();
        Q_EMIT userMessage(complete ? QStringLiteral("PSBT finalized") : QStringLiteral("PSBT incomplete"),
                           complete ? QStringLiteral("The finalized transaction is ready to broadcast.") : QStringLiteral("The PSBT still needs more signatures or data."));
    });
}

void NuRpcService::broadcastFinalizedPsbt()
{
    if (m_current_psbt_final_hex.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("PSBT not finalized"), QStringLiteral("Finalize the PSBT before broadcasting."));
        return;
    }
    rpcCall(QStringLiteral("sendrawtransaction"), {m_current_psbt_final_hex}, false, [this](const QJsonValue& result, const QString& error) {
        if (!error.isEmpty()) {
            Q_EMIT userMessage(QStringLiteral("Broadcast failed"), error);
            return;
        }
        Q_EMIT userMessage(QStringLiteral("Transaction broadcast"), QStringLiteral("Transaction ID: %1").arg(result.toString()));
        clearCurrentPsbt();
        refreshWallet();
    });
}

void NuRpcService::copyCurrentPsbt()
{
    if (m_current_psbt.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No PSBT loaded"), QStringLiteral("Load a PSBT before copying."));
        return;
    }
    copyText(m_current_psbt);
    Q_EMIT userMessage(QStringLiteral("PSBT copied"), QStringLiteral("The current PSBT was copied to the clipboard."));
}

void NuRpcService::saveCurrentPsbt()
{
    if (m_current_psbt.isEmpty()) {
        Q_EMIT userMessage(QStringLiteral("No PSBT loaded"), QStringLiteral("Load a PSBT before saving."));
        return;
    }
    const QString path = QFileDialog::getSaveFileName(nullptr,
                                                      QStringLiteral("Save PSBT"),
                                                      QDir(realHomePath()).filePath(QStringLiteral("defcoin.psbt")),
                                                      QStringLiteral("PSBT files (*.psbt);;Text files (*.txt);;All files (*)"));
    if (path.isEmpty()) return;
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        Q_EMIT userMessage(QStringLiteral("PSBT not saved"), file.errorString());
        return;
    }
    file.write(m_current_psbt.toLatin1());
    file.write("\n");
    Q_EMIT userMessage(QStringLiteral("PSBT saved"), QStringLiteral("The current PSBT was saved."));
}

void NuRpcService::clearCurrentPsbt()
{
    m_current_psbt.clear();
    m_current_psbt_final_hex.clear();
    m_current_psbt_summary = QStringLiteral("No PSBT loaded.");
    Q_EMIT psbtChanged();
}

QVariantList NuRpcService::tableColumnWidths(const QString& table_id, const QVariantList& default_widths) const
{
    if (table_id.trimmed().isEmpty()) return default_widths;
    const QStringList parts = QSettings().value(QStringLiteral("NuTables/%1/columnWidths").arg(table_id)).toStringList();
    if (parts.size() != default_widths.size()) return default_widths;
    QVariantList out;
    for (const QString& part : parts) {
        bool ok = false;
        const double value = part.toDouble(&ok);
        if (!ok || value < 24.0) return default_widths;
        out.push_back(value);
    }
    return out;
}

QVariantList NuRpcService::suggestedTableColumnWidths(const QVariantList& columns,
                                                       const QVariantList& rows,
                                                       const QVariantList& column_types,
                                                       const QVariantList& column_weights,
                                                       const QVariantList& column_minimums,
                                                       const QVariantList& column_maximums,
                                                       int available_width,
                                                       int font_pixel_size,
                                                       bool compact) const
{
    QVariantList out;
    if (columns.isEmpty()) return out;
    Q_UNUSED(column_weights);
    Q_UNUSED(available_width);

    QFont font = QApplication::font();
    QFont mono_font = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    if (font_pixel_size > 0) {
        font.setPixelSize(font_pixel_size);
        mono_font.setPixelSize(font_pixel_size);
    }
    QFont header_font = font;
    header_font.setBold(true);
    QFont mono_header_font = mono_font;
    mono_header_font.setBold(true);
    QFontMetrics metrics(font);
    QFontMetrics mono_metrics(mono_font);
    QFontMetrics header_metrics(header_font);
    QFontMetrics mono_header_metrics(mono_header_font);

    const int padding = compact ? 16 : 22;

    QVector<double> widths;
    widths.reserve(columns.size());
    for (int c = 0; c < columns.size(); ++c) {
        const QString type = variantColumnType(column_types, columns, c);
        const double minimum = qMax(36.0, variantAt(column_minimums, c, defaultColumnMinimum(type)));
        const double maximum = qMax(minimum, variantAt(column_maximums, c, defaultColumnMaximum(type)));
        const QString title = columns.at(c).toString();
        const bool mono = monoColumnType(type, title);
        const QFontMetrics& cell_metrics = mono ? mono_metrics : metrics;
        const QFontMetrics& title_metrics = mono ? mono_header_metrics : header_metrics;
        double wanted = minimum;
        double data_wanted = minimum;
        for (const QVariant& row_value : rows) {
            const QVariantList row = tableRowCells(row_value);
            if (row.size() <= c) continue;
            QString cell_text = row.at(c).toString();
            int extra_padding = 0;
            if (type == QLatin1String("seedLanSource")) {
                const QVariantMap meta = row_value.toMap().value(QStringLiteral("meta")).toMap();
                if (meta.value(QStringLiteral("isLanPeer")).toBool()) {
                    extra_padding = compact ? 28 : 32;
                }
            }
            data_wanted = qMax(data_wanted, double(cell_metrics.horizontalAdvance(cell_text) + padding + extra_padding));
        }
        double header_wanted = double(title_metrics.horizontalAdvance(title) + padding);
        if (title.contains(QRegularExpression(QStringLiteral("\\s")))) {
            double longest_word = minimum;
            const QStringList words = title.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
            for (const QString& word : words) {
                longest_word = qMax(longest_word, double(title_metrics.horizontalAdvance(word) + padding));
            }
            if (data_wanted + padding < header_wanted) header_wanted = longest_word;
        }
        wanted = qMax(data_wanted, header_wanted);
        const double effective_maximum = (type == QLatin1String("action") || type == QLatin1String("delete"))
            ? maximum
            : qMax(maximum, wanted);
        widths.push_back(qBound(minimum, std::ceil(wanted), effective_maximum));
    }

    for (double width : widths) out.push_back(std::ceil(width));
    return out;
}

void NuRpcService::saveTableColumnWidths(const QString& table_id, const QVariantList& widths)
{
    if (table_id.trimmed().isEmpty() || widths.isEmpty()) return;
    QStringList parts;
    for (const QVariant& value : widths) parts.push_back(QString::number(value.toDouble(), 'f', 2));
    QSettings().setValue(QStringLiteral("NuTables/%1/columnWidths").arg(table_id), parts);
}

void NuRpcService::resetTableColumnWidths(const QString& table_id)
{
    QSettings settings;
    if (table_id.trimmed().isEmpty()) {
        settings.beginGroup(QStringLiteral("NuTables"));
        settings.remove(QString());
        settings.endGroup();
    } else {
        settings.remove(QStringLiteral("NuTables/%1").arg(table_id));
    }
    settings.sync();
    Q_EMIT tableSettingsChanged();
    Q_EMIT userMessage(QStringLiteral("Table columns reset"),
                       table_id.trimmed().isEmpty()
                           ? QStringLiteral("Saved column widths were cleared for all Nu tables. Table sorting was also restored to first-launch defaults.")
                           : QStringLiteral("Saved column widths were cleared for this table. Table sorting was also restored to first-launch defaults."));
}

void NuRpcService::updateReceiveQr()
{
    if (m_receive_address.isEmpty()) return;
    const QString uri = defcoinUri(m_receive_address, m_receive_amount, m_receive_label, m_receive_message);
    m_receive_qr_source = qrSourceForUri(uri);
}

QString NuRpcService::defcoinUri(const QString& address, const QString& amount, const QString& label, const QString& message) const
{
    QUrlQuery query;
    if (!amount.trimmed().isEmpty()) query.addQueryItem(QStringLiteral("amount"), amount.trimmed());
    if (!label.trimmed().isEmpty()) query.addQueryItem(QStringLiteral("label"), label.trimmed());
    if (!message.trimmed().isEmpty()) query.addQueryItem(QStringLiteral("message"), message.trimmed());
    QString uri = QStringLiteral("defcoin:%1").arg(address.trimmed());
    const QString query_string = query.toString(QUrl::FullyEncoded);
    if (!query_string.isEmpty()) uri += QStringLiteral("?") + query_string;
    return uri;
}

QString NuRpcService::qrSourceForUri(const QString& uri) const
{
    if (uri.trimmed().isEmpty()) return QString();
    QRcode* code = QRcode_encodeString(uri.toUtf8().constData(), 0, QR_ECLEVEL_L, QR_MODE_8, 1);
    if (!code) return QString();

    QImage qr(code->width + 8, code->width + 8, QImage::Format_RGB32);
    qr.fill(Qt::white);
    unsigned char* p = code->data;
    for (int y = 0; y < code->width; ++y) {
        for (int x = 0; x < code->width; ++x) {
            qr.setPixel(x + 4, y + 4, ((*p & 1) ? 0x000000 : 0xffffff));
            ++p;
        }
    }
    QRcode_free(code);

    QImage out(QR_IMAGE_SIZE, QR_IMAGE_SIZE, QImage::Format_RGB32);
    out.fill(Qt::white);
    {
        QPainter painter(&out);
        painter.drawImage(out.rect().adjusted(24, 24, -24, -24), qr);
    }
    const QString hash = QString::fromLatin1(QCryptographicHash::hash(uri.toUtf8(), QCryptographicHash::Sha1).toHex().left(16));
    const QString qr_path = QDir::temp().filePath(QStringLiteral("defcoin-core-nu-qr-%1.png").arg(hash));
    out.save(qr_path);
    return QUrl::fromLocalFile(qr_path).toString();
}

QString NuRpcService::receiveRequestQrSource(const QString& uri) const
{
    return qrSourceForUri(uri);
}

QString NuRpcService::formatAmount(const QJsonValue& value)
{
    return QString::number(value.toDouble(), 'f', 8);
}

QString NuRpcService::formatBytes(qint64 bytes)
{
    static const QStringList units{QStringLiteral("B"), QStringLiteral("KB"), QStringLiteral("MB"), QStringLiteral("GB")};
    double value = bytes;
    int unit = 0;
    while (value >= 1024.0 && unit + 1 < units.size()) {
        value /= 1024.0;
        ++unit;
    }
    return QStringLiteral("%1 %2").arg(value, 0, unit == 0 ? 'f' : 'f', unit == 0 ? 0 : 1).arg(units.at(unit));
}

QString NuRpcService::formatPing(const QJsonValue& seconds)
{
    if (!seconds.isDouble()) return QStringLiteral("N/A");
    return QStringLiteral("%1 ms").arg(qRound(seconds.toDouble() * 1000.0));
}

QString NuRpcService::formatServices(const QString& services_hex)
{
    bool ok = false;
    const qulonglong services = services_hex.trimmed().toULongLong(&ok, 16);
    if (!ok || services == 0) return QStringLiteral("-");

    QStringList codes;
    if (services & (1ULL << 0)) codes << QStringLiteral("N");
    if (services & (1ULL << 1)) codes << QStringLiteral("G");
    if (services & (1ULL << 2)) codes << QStringLiteral("B");
    if (services & (1ULL << 3)) codes << QStringLiteral("W");
    if (services & (1ULL << 6)) codes << QStringLiteral("CF");
    if (services & (1ULL << 10)) codes << QStringLiteral("NL");
    if (services & (1ULL << 23)) codes << QStringLiteral("MLC");
    if (services & (1ULL << 24)) codes << QStringLiteral("M");
    if (services & (1ULL << 29)) codes << QStringLiteral("FS");
    return codes.isEmpty() ? services_hex : codes.join(QLatin1Char(' '));
}

QString NuRpcService::formatServiceDetails(const QString& services_hex)
{
    bool ok = false;
    const qulonglong services = services_hex.trimmed().toULongLong(&ok, 16);
    if (!ok) return QStringLiteral("Service bits could not be parsed from this peer.");
    if (services == 0) return QStringLiteral("No service bits advertised.");

    QStringList names;
    auto append = [&names, services](int bit, const QString& name, const QString& meaning) {
        if (services & (1ULL << bit)) {
            names << QStringLiteral("bit %1: %2 - %3").arg(bit).arg(name, meaning);
        }
    };
    append(0, QStringLiteral("NODE_NETWORK"), QStringLiteral("serves the full block chain"));
    append(1, QStringLiteral("NODE_GETUTXO"), QStringLiteral("supports the historical getutxo service bit"));
    append(2, QStringLiteral("NODE_BLOOM"), QStringLiteral("supports BIP37 bloom-filter client requests"));
    append(3, QStringLiteral("NODE_WITNESS"), QStringLiteral("can serve witness-serialized blocks and transactions"));
    append(6, QStringLiteral("NODE_COMPACT_FILTERS"), QStringLiteral("can serve BIP157/158 compact block filters"));
    append(10, QStringLiteral("NODE_NETWORK_LIMITED"), QStringLiteral("serves at least the recent block history"));
    append(23, QStringLiteral("NODE_MWEB_LIGHT_CLIENT"), QStringLiteral("Litecoin MWEB light-client service bit"));
    append(24, QStringLiteral("NODE_MWEB"), QStringLiteral("Litecoin MWEB service bit"));
    append(29, QStringLiteral("NODE_DEFCOIN_FASTSYNC"), QStringLiteral("Defcoin Nu UDP fast-sync capable"));

    qulonglong known = 0;
    for (int bit : {0, 1, 2, 3, 6, 10, 23, 24, 29}) {
        known |= (1ULL << bit);
    }
    const qulonglong unknown = services & ~known;
    if (unknown != 0) {
        names << QStringLiteral("unknown bits: 0x%1").arg(QString::number(unknown, 16));
    }
    return names.join(QStringLiteral("\n"));
}

QString NuRpcService::trimUserAgent(QString subver)
{
    subver = subver.trimmed();
    while (subver.startsWith(QLatin1Char('/'))) subver.remove(0, 1);
    while (subver.endsWith(QLatin1Char('/'))) subver.chop(1);
    return subver;
}

bool NuRpcService::isDefcoinUserAgent(QString subver)
{
    subver = trimUserAgent(subver);
    return subver.startsWith(QStringLiteral("Defcoin"), Qt::CaseInsensitive);
}

bool NuRpcService::isDefcoinCoreNuUserAgent(QString subver)
{
    subver = trimUserAgent(subver);
    return subver.startsWith(QStringLiteral("DefcoinCoreNu:"), Qt::CaseInsensitive) ||
           subver.startsWith(QStringLiteral("DefcoinCoreNu/"), Qt::CaseInsensitive) ||
           subver.compare(QStringLiteral("DefcoinCoreNu"), Qt::CaseInsensitive) == 0;
}
